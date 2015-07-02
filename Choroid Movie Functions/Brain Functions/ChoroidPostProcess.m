function [messedup2,error2,runtime2,exception] = ChoroidPostProcess(varargin)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if length(varargin)==1
    if ispc
        dirlist = fullfile([filesep filesep 'HMR-BRAIN'],varargin{1});
    elseif ismac
        dirlist = fullfile([filesep 'Volumes'],varargin{1});
    else
        dirlist = fullfile(filesep,'srv','samba',varargin{1});
    end
else
    if ispc
        load(fullfile([filesep filesep 'HMR-BRAIN'],'share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
        dirlist=fullfile([filesep filesep 'HMR-BRAIN'],dirlist);
    else
        load(fullfile(filesep,'srv','samba','Share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
        dirlist=fullfile(filesep,'srv','samba',strrep(dirlist,'\','/'));
    end
    [missdata,missraw,missprocessim,missregims,missresults]=CheckDirContents(dirlist);
    FirstProcess=logical(cellfun(@exist,fullfile(dirlist,'Results','FirstProcessData.mat')));
    Rigidity=~cellfun(@isempty,regexp(dirlist,'Rigidity','match'));
    if isempty(dirlist)
        errordlg('No diretories prerequisite data. Run ChoroidFirstProcess.m first')
        return
    end
    dirlist=dirlist(FirstProcess&Rigidity);
end

% c=parcluster('local');
% if isempty(gcp('nocreate'))
%     pool=parpool(c,12);
% end

finishup = onCleanup(@() delete(gcp('nocreate'))); %Close parallel pool when function returns or error

clock=tic;
messedup2=[];
error2=cell(length(dirlist),1);
for iter=1:length(dirlist)
    try
        directory=dirlist{iter};
        
        numframes=length(dir(fullfile(directory,'Processed Images','*.png')));
        
        savedir=fullfile(directory,'Results');
        load(fullfile(savedir,'FirstProcessData.mat'));
        load(fullfile(directory,'Data Files','RegisteredImages.mat'));
        smallsize=vertcat(other.smallsize);
        skippedind=skippedind;
        notskipped=setdiff(1:numframes,skippedind);
        traces=traces;
        noCSI=~cell2mat(cellfun(@isempty,cellfun(@find,cellfun(@isnan,cellfun(@min,{traces.CSI},'uniformoutput',0),'uniformoutput',0),'uniformoutput',0),'uniformoutput',0));
        allframes=1:numframes;
        
        %% CALCULATE MEAN CSI & Correllation
        meanCSI=round(mean([traces(~noCSI).CSI],2));
        correl=zeros(numframes,1);
        for i=1:numframes
            if ismember(i,skippedind)
                continue
            end
            correl(i)=max(xcorr(traces(i).CSI,meanCSI,5));
        end
        badcorrel = allframes(correl<mean(correl(correl~=0)));
        
        %% Apply Exclusion Criteria to Determine frames to rerun
        Vframecheck = zeros(numframes,1);
        
        for frame = 1:numframes
            if ismember(frame,skippedind) || ismember(frame,allframes(noCSI))
                continue
            end
            % Choroid Volume Calculation
            Vframecheck(frame) = sum(traces(frame).CSI-traces(frame).BM);
            %                 Vframe{frame} = ChoroidVolumeCalc(traces(frame).usedCSI,traces(frame).BM);
        end
        [~,~,Endcheck,~,Vcheck,~,~]=ChoroidUsableFramesCheck(numframes,Vframecheck,EndHeights,EndHeights,EndHeights,{traces.CSI});
        error=setdiff(unique([badcorrel setdiff(allframes(~Endcheck | ~Vcheck),allframes(noCSI))]),skippedind);
        
        %% Rerun Using Endheight Trends if Required
        Vframe=zeros(numframes,1);
        
        if any(error)%var(EndHeights(~isnan(EndHeights(:,1)),1))>20 || var(EndHeights(~isnan(EndHeights(:,2)),2))>20
            load(fullfile(directory,'Data Files','OrientedGradient.mat'));
            [newEndHeights,traces] = ChoroidEndheightRerun(EndHeights,error,numframes,skippedind,nodes,OG,other,traces,meanCSI);
            correl=zeros(numframes,1);
            for i=1:numframes
                if ismember(i,skippedind)
                    continue
                end
                correl2(i)=max(xcorr(traces(i).nCSI,meanCSI,5));
            end
            usedEndHeights=EndHeights;
            [traces.usedCSI]=traces.CSI;
            for i=1:length(error)
                frame=error(i);
                if correl2(frame)>correl(frame)
                    usedEndHeights(frame)=newEndHeights(frame);
                    traces(frame).usedCSI=traces(frame).nCSI;
                end
            end
            disp(['Done Rerun, Iteration ',num2str(iter)])
        else
            newEndHeights=EndHeights;
            usedEndHeights=EndHeights;
            [traces.usedCSI]=traces.CSI;
            disp(['Done Rerun, Iteration ',num2str(iter)])
        end
        
        for frame=1:numframes
            if ismember(frame,skippedind) || isempty(traces(frame).usedCSI)
                continue
            end
            % Choroid Volume Calculation
            Vframe(frame)=sum(traces(frame).usedCSI-traces(frame).BM);
            %                 Vframe{frame} = ChoroidVolumeCalc(traces(frame).usedCSI,traces(frame).BM);
        end
        
        save(fullfile(savedir,'PostProcessData.mat'),'traces','newEndHeights','usedEndHeights','Vframe');
        
        disp(logit(directory,['Correct ChoroidPostProcess:' savedir]))
        %%
        clearvars -except iter dirlist rerun messedup2 mostrecent clock error2
        
        close all
        
        exception = [];
        
    catch exception
        
        exception.stack(1)
        exception.stack(2)
        exception.stack(3)
        
        disp(logit(directory,['Error ChoroidPostProcess(iter=' num2str(iter) '): ' exception.message ' in ' directory]))
        
        error2{iter} = exception;
        
        messedup2 = [messedup2; iter];
        
        clearvars -except iter dirlist rerun messedup2 mostrecent clock error2
        
        close all
        
%         if iter==length(dirlist) && ~isempty(gcp('nocreate'))
%             delete(pool)
%         end

        continue
    end
end

runtime2 = toc(clock);

% if ~isempty(gcp('nocreate'))
%     delete(gcp('nocreate'))
% end

end

