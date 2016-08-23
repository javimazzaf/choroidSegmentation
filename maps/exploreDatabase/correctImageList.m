function correctImageList(varargin)

dirlist = adaptToHMRpath(varargin{1});

% dirlist = varargin{1};

for d = 1:length(dirlist)
    
    folder = dirlist{d};
    
    disp(logit(folder,['Starting correctImageList: ' folder]))
    
    try
        
        if exist(fullfile(folder, 'Data Files'),'dir')
            movefile(fullfile(folder, 'Data Files'),fullfile(folder, 'DataFiles'),'f')
        end
        
        if ~exist(fullfile(folder, 'DataFiles','ImageList.mat'),'file')
            disp(logit(folder,'  - ImageList.mat do not exist: Skipping'))
        end
        
        load(fullfile(folder, 'DataFiles','ImageList.mat'), 'ImageList');
        
        if istable('ImageList')
            disp(logit(folder,'  - ImageList is already a Table: Skipping'))
        end

        
        col = zeros([numel(ImageList),1]);
        colc = cell([numel(ImageList),1]);
        
        timeSeries = table(col,col,col,col,col,colc,col,col,col,col,col,col,col,col,col,col,col,col,col,col,colc,colc,...
            'VariableNames',{'id' 'fwidth' 'fheight' 'fscaleX' 'fscaleY' 'fundusfileName'...
            'hour ' 'minute' 'second' 'UTC' 'width' 'height' 'scaleX'...
            'scaleY' 'numAvg' 'quality' 'startX' 'startY' 'endX' 'endY'...
            'filePath' 'fileName'});
        
        for k = 1:numel(ImageList)
            
            timeSeries{k,'id'}      = ImageList(k).id;
            timeSeries{k,'fwidth'}  = ImageList(k).fwidth;
            timeSeries{k,'fheight'} = ImageList(k).fheight;
            timeSeries{k,'fscaleX'} = ImageList(k).fscaleX;
            timeSeries{k,'fscaleY'} = ImageList(k).fscaleY;
            timeSeries{k,'fundusfileName'} = {ImageList(k).fundusfileName};
            timeSeries{k,'hour'}     = ImageList(k).hour;
            timeSeries{k,'minute'}   = ImageList(k).minute;
            timeSeries{k,'second'}   = ImageList(k).second;
            timeSeries{k,'UTC'}      = ImageList(k).UTC;
            timeSeries{k,'width'}    = ImageList(k).width;
            timeSeries{k,'height'}   = ImageList(k).height;
            timeSeries{k,'scaleX'}   = ImageList(k).scaleX;
            timeSeries{k,'scaleY'}   = ImageList(k).scaleY;
            timeSeries{k,'numAvg'}   = ImageList(k).numAvg;
            timeSeries{k,'quality'}  = ImageList(k).quality;
            timeSeries{k,'startX'}   = ImageList(k).startX;
            timeSeries{k,'startY'}   = ImageList(k).startY;
            timeSeries{k,'endX'}     = ImageList(k).endX;
            timeSeries{k,'endY'}     = ImageList(k).endY;
            timeSeries{k,'filePath'} = {ImageList(k).filePath};
            timeSeries{k,'fileName'} = {ImageList(k).fileName};
            
        end
        
        movefile(fullfile(folder, 'DataFiles','ImageList.mat'),fullfile(folder, 'DataFiles','ImageListOld.mat'),'f');
        
        ImageList = timeSeries;
        save(fullfile(folder, 'DataFiles','ImageList.mat'),'ImageList');
        
        
    catch exception
        
        errorString = ['Error in correctImageList. Message:' exception.message buildCallStack(exception)];
        disp(logit(folder,errorString));
        continue
        
    end
    
    disp(logit(folder,'Done correctImageList'))
    
end



