function [messedup2,error2,runtime2] = ChoroidPostProcess(varargin)

% Uses the whole set of segmented CSI to correct for specific frames with
% very different segmentation traces (possibly errors). It assigns a new
% weight for the graph search, accounting for the distance to the mean CSI
% trace.

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

finishup = onCleanup(@() delete(gcp('nocreate'))); %Close parallel pool when function returns or error

clock=tic;
messedup2=[];
error2=cell(length(dirlist),1);
for iter=1:length(dirlist)
    try
        directory = dirlist{iter};
        
        numframes = length(dir(fullfile(directory,'Processed Images','*.png')));
        
        savedir=fullfile(directory,'Results');
        load(fullfile(savedir,'FirstProcessData.mat'));
        load(fullfile(directory,'Data Files','RegisteredImages.mat'));
        smallsize=vertcat(other.smallsize);
        skippedind = skippedind; % It fixes a bug in parallel mode, where it does not find the variable loaded from file.
        notskipped = setdiff(1:numframes,skippedind);
        traces=traces;
%         hasCSI = cell2mat(cellfun(@isempty,cellfun(@find,cellfun(@isnan,cellfun(@min,{traces.CSI},'uniformoutput',0),'uniformoutput',0),'uniformoutput',0),'uniformoutput',0));

        hasCSI = ~logical(cellfun(@(x) any(isnan(x)),{traces.CSI}));
        
        allframes=1:numframes;
        
        % CALCULATE MEAN CSI & Correlation
        meanCSI = round(mean([traces(hasCSI).CSI],2));
        
        correl = zeros(numframes,1);
        
        for i = 1:numframes
            if ismember(i,skippedind)
                continue
            end
            correl(i) = max(xcorr(traces(i).CSI,meanCSI,5));
        end
        
        meanCorrel = mean(correl(correl~=0));
        
        % List of frames where the correlation is lower than the mean
        badcorrel = allframes(correl < meanCorrel);
        
        % Apply Exclusion Criteria to Determine frames to rerun
        Vframecheck = zeros(numframes,1);
        
        validFrames = hasCSI & ~ismember(allframes,skippedind);
        validFrames = validFrames & ~logical(cellfun(@isempty,{traces.CSI})); 
        
        % Choroid Volume Calculation
        for frame = allframes(validFrames)
            Vframecheck(frame) = sum(traces(frame).CSI - traces(frame).BM);
        end
        
        [~,~,Endcheck,~,Vcheck,~,~] = ChoroidUsableFramesCheck(numframes,Vframecheck,EndHeights,EndHeights,EndHeights,{traces.CSI});
        
        error = setdiff(unique([badcorrel setdiff(allframes(~Endcheck | ~Vcheck),allframes(~hasCSI))]),skippedind);
        
        %% Rerun Using Endheight Trends if Required
        Vframe=zeros(numframes,1);
        
        if any(error)
            load(fullfile(directory,'Data Files','OrientedGradient.mat'));
            [newEndHeights,traces] = ChoroidEndheightRerun(EndHeights,error,numframes,skippedind,nodes,OG,other,traces,meanCSI);
            correl = zeros(numframes,1);
            for i = allframes
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
        else
            newEndHeights=EndHeights;
            usedEndHeights=EndHeights;
            [traces.usedCSI]=traces.CSI;
        end
        
        disp(logit(savedir,['Done Rerun ChoroidPostProcess, Iteration ',num2str(iter)]))
        
        for frame = allframes
            if ismember(frame,skippedind) || isempty(traces(frame).usedCSI)
                continue
            end
            
            % Choroid Volume Calculation
            Vframe(frame) = sum(traces(frame).usedCSI-traces(frame).BM);

        end
        
        save(fullfile(savedir,'PostProcessData.mat'),'traces','newEndHeights','usedEndHeights','Vframe');
        
        disp(logit(directory,['Correct ChoroidPostProcess:' savedir]))
        %%
        clearvars -except iter dirlist rerun messedup2 mostrecent clock error2
        
        close all
        
    catch exception
        
        errorString = ['Error ChoroidPostProcess(iter=' num2str(iter) '): ' exception.message ' in ' directory];
        
        if ismember('stack',fieldnames(exception))
            for s = 1:numel(exception.stack)
                text = ['Function: ' exception.stack(s).name ' (at: ' num2str(exception.stack(s).line) '). '];
                errorString = [errorString, text];
            end
        end
        
        disp(logit(directory,errorString))
        
        error2{iter} = exception;
        
        messedup2 = [messedup2; iter];
        
        clearvars -except iter dirlist rerun messedup2 mostrecent clock error2
        
        close all

        continue
    end
end

runtime2 = toc(clock);

end

