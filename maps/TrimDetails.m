function TrimDetails(varargin)

% dirlist = adaptToHMRpath(varargin{1});
dirlist = varargin{1};

for k = 1:length(dirlist)
    
    folder = dirlist{k};
    
    try
        
        fname = fullfile(folder,'DataFiles','TrimInfo.txt');
        
        if exist(fname,'file'), continue, end
        
        pngList   = dir(fullfile(folder,'ProcessedImages','*.png'));
        numframes = numel(pngList);
        
        load(fullfile(folder,'DataFiles','ImageList.mat'), 'ImageList');
        
        qualityMask = ImageList.quality>=20 & ImageList.numAvg > 1;
        qualityMask(1:round(numframes/2)) = false;
        
        frame = find(qualityMask,1,'first');
        
        if isempty(frame), frame = numframes; end

        octImage = imread(fullfile(folder,'ProcessedImages',pngList(frame).name));
        
        [bscan,cropsize] = Crop2(octImage);
        
        happy = 'Redo';
        fh = figure;
        
        while strcmp(happy,'Redo')
            imshow(bscan)
            title('Please Select Left and Right Columns To Trim Off Entire Movie')
            trim = questdlg('Do you want to trim the image series?','Trim Dialog','Yes','No','Cancel','Yes');
            if strcmp('Yes',trim)
                [col,~] = ginput(2);
                hold on
                plot(repmat(col(1),size(bscan,1),1),1:size(bscan,1),'g')
                plot(repmat(col(2),size(bscan,1),1),1:size(bscan,1),'g')
                hold off
                happy=questdlg('Accept or Redo?','Check','Accept','Redo','Accept');
            elseif strcmp('No',trim)
                happy='Accept';
                col=[1;size(bscan,2)];
            else
                delete(fullfile(folder,'DataFiles','TrimInfo.txt'))
                return
            end
        end
        
        close(fh)
        
        % Sort, check limits, and save to file
        dlmwrite(fullfile(folder,'DataFiles','TrimInfo.txt'),min(max(1,sort(col)),size(bscan,2)),'precision','%g')
        
        
    catch exception
        
        errorString = ['Error in TrimDetails. Message:' exception.message buildCallStack(exception)];
        disp(logit(folder,errorString));
        continue
        
    end
    
    disp(logit(folder,'Done TrimDetails'))
    
end
end