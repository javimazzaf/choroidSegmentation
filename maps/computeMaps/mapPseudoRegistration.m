function mapPseudoRegistration(varargin)

% dirlist = adaptToHMRpath(varargin{1});

dirlist = varargin{1};

for k = 1:length(dirlist)
    
    folder = dirlist{k};
    
    disp(logit(folder,'Starting mapPseudoRegistration'))
    
    try
        
        pngList = dir(fullfile(folder,'ProcessedImages','*.png'));
        
        load(fullfile(folder, 'DataFiles','ImageList.mat'), 'ImageList');
        
        numframes  = numel(pngList);
        bscanstore = cell(numframes,1);
        
        cropLimits = dlmread(fullfile(folder, 'DataFiles', 'TrimInfo.txt'));
        
        for frame = 1:numframes
            bscan = imread(fullfile(folder, 'ProcessedImages', pngList(frame).name));
            bscanstore{frame} = bscan(:,cropLimits(1):cropLimits(2));
        end
        
        skippedind = [];
        start      = 1;
        save(fullfile(folder,'DataFiles','RegisteredImages.mat'),'bscanstore','skippedind','start');
        
    catch exception
        
        errorString = ['Error in mapPseudoRegistration. Message:' exception.message buildCallStack(exception)];
        disp(logit(folder,errorString));
        continue
        
    end
    
    disp(logit(folder,'Done mapPseudoRegistration'))
    
end



