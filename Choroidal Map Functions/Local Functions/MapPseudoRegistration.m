function MapPseudoRegistration(varargin)
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
    Map=~cellfun(@isempty,regexp(dirlist,'Choroidal Mapping','match'));
    dirlist=dirlist(~missprocessim&missregims&Map);
    if isempty(dirlist)
        errordlg('No diretories prerequisite data. Run convertSpectralis.m first')
        return
    end
end

for i=1:length(dirlist)
    
    directory = dirlist{i};
    
    try
    
    numframes=length(dir(strcat(directory,'/Processed Images/*.png')));
    
    load([directory '/Data Files/ImageList.mat']);
    
    imlist=dir(strcat(directory,'/Processed Images/*.png'));
    numAvg=vertcat(ImageList.numAvg);
    quality=vertcat(ImageList.quality);
    
    %Initialize Variables
    bscanstore=cell(numframes,1);
    skippedind=[];
    
    start=1;
    
    fileID = fopen([directory '/Data Files/TrimInfo.txt']);
    trimvalues=fscanf(fileID,'%d');
    CutLeft=trimvalues(1);
    CutRight=trimvalues(2);
    fclose(fileID);
    
    for frame=1:numframes
        bscan=imread([directory '/Processed Images/' imlist(frame).name]);
        bscanstore{frame}=bscan(:,CutLeft:CutRight);
    end
    save(fullfile(directory,'Data Files','RegisteredImages.mat'),'bscanstore','skippedind','imlist','start');
    
    catch exc  
        disp(logit(directory,['Error in MapPseudoRegistration while processing ' directory ' : ' exc.message]))
        continue         
    end
    
    disp(logit(directory,'Done MapPseudoRegistration'))
    
end



