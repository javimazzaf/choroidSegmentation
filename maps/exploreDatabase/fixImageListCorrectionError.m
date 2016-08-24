function fixImageListCorrectionError(varargin)

% The code correctImageList missed to pass the fundusIm to the
% imageList.mat file. Since we had saved the previous version to
% imageListOld.mat, I cna now run this function to fix the error.

dirlist = adaptToHMRpath(varargin{1});

% dirlist = varargin{1};

count = 0;

for d = 1:length(dirlist)
    
    folder = dirlist{d};
    
    disp(logit(folder,['Starting fixImageListCorrectionError: ' folder]))
    
    try
        
        if ~exist(fullfile(folder, 'DataFiles','ImageListOld.mat'),'file') ||... 
           ~exist(fullfile(folder, 'DataFiles','ImageList.mat'),'file')  
            disp(logit(folder,'  - ImageListOld.mat or ImageList.mat do not exist: Skipping'))
            continue
        end
        
        vars = load(fullfile(folder, 'DataFiles','ImageListOld.mat'));
        
        if isfield(vars,'fundim')
         fundusIm = vars.fundim;   
        end
        
        if isfield(vars,'fundusIm')
         fundusIm = vars.fundusIm;   
        end        
   
        if isfield(vars,'ImageList')
         ImageList = vars.ImageList;   
        end        
        
        %load the Table-version of ImageList
        load(fullfile(folder, 'DataFiles','ImageList.mat'), 'ImageList');
        
        % Correct the ImageList.mat file
        save(fullfile(folder, 'DataFiles','ImageList.mat'),'ImageList','fundusIm');
        
        count = count + 1;
        
    catch exception
        
        errorString = ['Error in fixImageListCorrectionError. Message:' exception.message buildCallStack(exception)];
        disp(logit(folder,errorString));
        continue
        
    end
    
    disp(logit(folder,['Done fixImageListCorrectionError on ' num2str(count) ' directories']))
    
end



