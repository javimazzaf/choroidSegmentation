function TrimDetails(varargin)

dirlist = adaptToHMRpath(varargin{1});

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
        col=sort(col);
        if col(1)<1
            col(1)=1;
        end
        if col(2)>size(bscan,2)
            col(2)=size(bscan,2);
        end
        dlmwrite(fullfile(directory,'Data Files','TrimInfo.txt'),[col],'precision','%g','newline','pc')
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