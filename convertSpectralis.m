function convertSpectralis(varargin)

% dirlist = adaptToHMRpath(varargin{1});

dirlist = varargin{1};

for k = 1:numel(dirlist)
    
    folder = dirlist{k};

    disp(logit(folder,'Initiating convertSpectralis'))
    
    % Move raw images and xml spectralis file to RawImages
    if ~exist(fullfile(folder,'Raw Images'), 'dir')
        mkdir(fullfile(folder,'Raw Images'));
        movefile(fullfile(folder,'*.tif'),fullfile(folder,'Raw Images'),'f')
        movefile(fullfile(folder,'*.xml'),fullfile(folder,'Raw Images'),'f')
    end
    
    try
        
        % Create images target directory
        if ~exist(fullfile(folder,'ProcessedImages'),'dir')
            mkdir(fullfile(folder,'ProcessedImages'));
        end
        
        % Create data target directory
        if ~exist(fullfile(folder,'DataFiles'),'dir')
            mkdir(fullfile(folder,'DataFiles'));
        end
        
        xmlFile = dir(fullfile(folder,'Raw Images','*.xml'));

        [~,ImageList] = analyzeSpectralisXML(fullfile(folder,'Raw Images',xmlFile.name));

        for q = 1:size(ImageList,1)
            
            imtif = imread(fullfile(folder,'Raw Images',char(ImageList{q,'fileName'})));
            
            imout = rgb2gray(imtif);
            
            imwrite(imout,fullfile(folder,'ProcessedImages',[num2str(q-1,'%5.5d'),'.png']))
            
        end
        
        fundusIm = imread(fullfile(folder,'Raw Images',char(ImageList{1,'fundusfileName'})));
        
        save(fullfile(folder,'DataFiles','ImageList.mat'),'ImageList','fundusIm');
        
    catch exception
        
        errorString = ['Error in convertSpectralis. Message:' exception.message buildCallStack(exception)];
        disp(logit(folder,errorString));
        continue
        
    end
    
    disp(logit(folder,'Done convertSpectralis'))

end