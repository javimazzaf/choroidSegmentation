function [messedup,error,time]=ChoroidRegistration(varargin)
%UNTITLED Summary of this function goes here
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
        load(fullfile([filesep filesep 'HMR-BRAIN'],'Share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
        dirlist=fullfile([filesep filesep 'HMR-BRAIN'],dirlist);
    else
        load(fullfile(filesep,'srv','samba','Share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
        dirlist=fullfile(filesep,'srv','samba',strrep(dirlist,'\','/'));
    end
    [missdata,missraw,missprocessim,missregims,missresults]=CheckDirContents(dirlist);
    Rigidity=~cellfun(@isempty,regexp(dirlist,'Rigidity','match'));
    dirlist=dirlist(missregims&~missprocessim&Rigidity);
    if isempty(dirlist)
        errordlg('No diretories prerequisite data. Run convertSpectralis.m first')
        return
    end
end

% finishup = onCleanup(@() delete(gcp('nocreate'))); %Close parallel pool when function returns or error

% c=parcluster('local');
% if isempty(gcp('nocreate'))
%     pool=parpool(c,12);
% end

tic
messedup=[];
error=cell(length(dirlist),1);

for iter=1:length(dirlist)
    try
        directory=dirlist{iter};
        
        disp(['Starting: ' directory])
        
        numframes=length(dir(fullfile(directory,'Processed Images','*.png')));
        
        %%%%%%%%%%%%%%%%%%%%  Registration Process  %%%%%%%%%%%%%%%%%%%%%%%
        load(fullfile(directory,'Data Files','ImageList.mat'));
        
        imlist=dir(fullfile(directory,'Processed Images','*.png'));
        numAvg=vertcat(ImageList.numAvg);
        quality=vertcat(ImageList.quality);
        
        %Initialize Variables
        bscanstore=cell(numframes,1);
        skippedind=nan(numframes,1);
        
        start=find(quality>18 & numAvg > 1,1,'first');
        fileID = fopen(fullfile(directory,'Data Files','TrimInfo.txt'));
        trimvalues=fscanf(fileID,'%d');
        CutLeft=trimvalues(1);
        CutRight=trimvalues(2);
        fclose(fileID);
        
        start = 1;
        
        for frame=1:start
             
            octImage=imread(fullfile(directory,'Processed Images', imlist(frame).name));

            [bscan,cropsize]=Crop2(octImage);
            if frame==start
                break
            end
            
            skippedind(frame)=frame;
            traces(frame).RET=[];
            traces(frame).RPE=[];
            traces(frame).BM=[];
            traces(frame).CSI=[];
            other(frame).colshifts=[];
            other(frame).shiftsize=[];
            other(frame).smallsize=[];
            other(frame).bigsize=[];
            bscanstore{frame}=bscan;
        end
        
        %         G=OrientedGaussian([12 4],0);
        Frame1=bscan;%imfilter(bscan,G,'replicate');
            
        metric=registration.metric.MeanSquares;
        optimizer=registration.optimizer.OnePlusOneEvolutionary;
        optimizer.InitialRadius = 0.001;
        optimizer.GrowthFactor=1.15;
        optimizer.Epsilon=0.1E-6;
        optimizer.MaximumIterations=500;
        %%
        parfor frame=start:numframes
            octImage=imread(fullfile(directory,'Processed Images',imlist(frame).name));
            [bscan,cropsize]=Crop2(octImage);
            
            if quality(frame)<18 || numAvg(frame) == 1
                skippedind(frame)=frame;
                
                traces(frame).RET=[];
                traces(frame).RPE=[];
                traces(frame).BM=[];
                traces(frame).CSI=[];
                other(frame).colshifts=[];
                other(frame).shiftsize=[];
                other(frame).smallsize=[];
                other(frame).bigsize=[];
                bscanstore{frame}=bscan;
                continue
            end
            if frame==start
                bscanstore{frame}=bscan(:,CutLeft:CutRight);
            else
                %                 bscanlogic=imfilter(bscan,G,'replicate');
                Rmoving=imref2d(size(bscan));
                Rfixed=imref2d(size(Frame1));
                tform=imregtform(bscan,Rmoving,Frame1,Rfixed,'rigid',optimizer,metric);
                regbscan=imwarp(bscan,Rmoving,tform,'outputview',Rfixed);
                bscanstore{frame}=regbscan(:,CutLeft:CutRight);
            end
        end
        
        skippedind=skippedind(~isnan(skippedind));
        
        save(fullfile(directory,'Data Files','RegisteredImages.mat'),'bscanstore','skippedind','imlist','start');
        
        disp(logit(directory,['ChoroidRegistration. Done iteration ' num2str(iter) ': ' directory]))
        
        clearvars -except iter dirlist messedup error
       
        
    catch exception
%         if exist('fileID','var')
%             fclose(fileID);
%         end
        disp(logit(directory,['ChoroidRegistration. Skipped folder: ' directory '. Error:' exception.message]))

        error{iter}=exception;
        messedup=[messedup;iter];
        clearvars -except iter dirlist messedup error
%         if iter==length(dirlist) && ~isempty(gcp('nocreate'))
%             delete(pool)
%         end
        continue
    end
end

% if ~isempty(gcp('nocreate'))
%     delete(pool)
% end
time=toc;


