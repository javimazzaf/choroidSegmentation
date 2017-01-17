function correctProcessedImagesPath(varargin)

dirlist = adaptToHMRpath(varargin{1});

% dirlist = varargin{1};

for d = 1:length(dirlist)
    
    folder = dirlist{d};
    
    disp(logit(folder,['Starting correctProcessedImagesPath: ' folder]))
    
    try
        
        if exist(fullfile(folder, 'Processed Images'),'dir')
            movefile(fullfile(folder, 'Processed Images'),fullfile(folder, 'ProcessedImages'),'f')
        end
        
    catch exception
        
        errorString = ['Error in correctProcessedImagesPath. Message:' exception.message buildCallStack(exception)];
        disp(logit(folder,errorString));
        continue
        
    end
    
    disp(logit(folder,'Done correctProcessedImagesPath'))
    
end



