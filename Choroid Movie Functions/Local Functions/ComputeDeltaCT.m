function ComputeDeltaCT(varargin)

if nargin > 0
    
    if ispc
        dirlist = fullfile([filesep filesep 'HMR-BRAIN'],varargin{1});
    elseif ismac
        dirlist = fullfile([filesep 'Volumes'],varargin{1});
    else
        dirlist = fullfile(filesep,'srv','samba',varargin{1});
    end
    
    if nargin > 1
      updatefigs = varargin{2};
    else
      updatefigs = 0;  
    end
    
else
    
    if ispc
        load(fullfile([filesep filesep 'HMR-BRAIN'],'share','Spectralis','Code','Choroid Code','Directories','directories.mat'))
        dirlist=fullfile([filesep filesep 'HMR-BRAIN'],dirlist);
    else
        load(fullfile(filesep,'srv','samba','Share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
        dirlist=fullfile(filesep,'srv','samba',strrep(dirlist,'\','/'));
    end
    
    [missdata,missraw,missprocessim,missregims,missresults] = CheckDirContents(dirlist);
    PostProcess = logical(cellfun(@exist,fullfile(dirlist,'Results','PostProcessData.mat')));
    Rigidity    = ~cellfun(@isempty,regexp(dirlist,'Rigidity','match'));
    dirlist     = dirlist(PostProcess&Rigidity);
    
    if isempty(dirlist)
        errordlg('No diretories prerequisite data. Run ChoroidMakeFigures.m first')
        return
    end

    updatefigs = 1;
end

for iter=1:length(dirlist)
    close all
    directory=dirlist{iter};
    
    disp(['Processing: ' directory])
    
    numframes=length(dir(fullfile(directory,'Processed Images','*.png')));
    
    savedir=fullfile(directory,'Results');
    
    load(fullfile(directory,'Results','FirstProcessData.mat'));
    load(fullfile(directory,'Results','PostProcessData.mat'));
    load(fullfile(directory,'Data Files','RegisteredImages.mat'));
    load(fullfile(directory,'Data Files','ImageList.mat'))
    
    %% Volume Method 1 (Find d as the mean distance between BM and CSI for each frame)
    for frame=1:numframes
        if ismember(frame,skippedind)
            continue
        end
        d1(frame) = mean(traces(frame).usedCSI-traces(frame).BM).*ImageList(frame).scaleY;
    end
    d1 = d1(inclframelist);
    % d1=d1(setdiff(1:numframes,skippedind));
    [~,~,~,~,deltad1] = WindowedPeaks(d1,mean(d1),...
        round((GetHeartRate(directory)/3/60)/(Output{5}(1,2) - Output{5}(1,1))),0.0039);
    
    %% Volume Method 2 & 3
    
    [deltad2,deltad3,d2,SNR] = LSFilt(Output,d1,2,6,directory,savedir,updatefigs);
    
    %%
    save(fullfile(directory,'Results','DeltaCT.mat'),...
        'd1','d2','deltad1','deltad2','deltad3','SNR');
    
end

