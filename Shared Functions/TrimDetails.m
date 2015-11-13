function TrimDetails(varargin)

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
    dirlist=dirlist(missraw&~missprocessim);
end

for iter=1:length(dirlist)
    directory=dirlist{iter};
    
    try
    
    fileID = fopen(fullfile(directory,'Data Files','TrimInfo.txt'));
    if fileID==-1
        numframes=length(dir(fullfile(directory,'Processed Images','*.png')));
        
        load(fullfile(directory,'Data Files','ImageList.mat'));
        
        imlist=dir(fullfile(directory,'Processed Images','*.png'));
        numAvg=vertcat(ImageList.numAvg);
        quality=vertcat(ImageList.quality);
        
        bscanstore=cell(numframes,1);
        skippedind=nan(numframes,1);
        
        start=find(quality>20 & numAvg > 1,1,'first');
        frame=round(numframes/2);
        while frame<=numframes && quality(frame)<20
            frame=frame+1;
        end
        
        frame = min(frame,numframes);
        
        octImage=imread(fullfile(directory,'Processed Images',imlist(frame).name));
        [bscan,cropsize]=Crop2(octImage);
        happy='Redo';
        
        while strcmp(happy,'Redo')
            imshow(bscan)
            title('Please Select Left and Right Columns To Trim Off Entire Movie')
            trim=questdlg('Do you want to trim the image series?','Trim Dialog','Yes','No','Cancel','Yes');
            if strcmp('Yes',trim)
                [col,row]=ginput(2);
                hold on
                plot(repmat(col(1),size(bscan,1),1),1:size(bscan,1),'g')
                plot(repmat(col(2),size(bscan,1),1),1:size(bscan,1),'g')
                hold off
                happy=questdlg('Accept or Redo?','Check','Accept','Redo','Accept');
            elseif strcmp('No',trim)
                happy='Accept';
                col=[1;size(bscan,2)];
            else
                fclose(fileID);
                delete(fullfile(directory,'Data Files','TrimInfo.txt'))
                return
            end
        end
        
        close gcf
        col = round(sort(col));
        col(1) = max(1,col(1));
        col(2) = min(col(2),size(bscan,2));
        
        dlmwrite(fullfile(directory,'Data Files','TrimInfo.txt'),col,'precision','%.0f','newline','pc')
    else
        fclose(fileID);
    end
    
    catch exc
        disp(logit(directory,['Error in ' directory ' : ' exc.message]))
        continue
    end
    
    disp(logit(directory,'Done TrimDetails'))
    
end
end