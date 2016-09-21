function retinaLayersSegmentation(varargin)

% Previously called choroidMapFirstProcess

% This function segments the retina interface, RPE, Bruchs membrane and the
% coroid-sclera interface, in each frame in the array bscanstore in the
% file RegisteredImages.mat for each directory in varargin{1}.


% dirlist = adaptToHMRpath(varargin{1});
dirlist = varargin{1};

if     ispc,  workersAvailable = Inf; %Uses parallel computing
elseif ismac, workersAvailable = 0;   %Uses 1 worker computing
else          workersAvailable = Inf; %Uses 1 worker computing
end

%Close parallel pool when the process exits the scope of this function
if workersAvailable > 0
   finishup = onCleanup(@() delete(gcp('nocreate'))); 
end

% Iterate over subjects
nDirs = numel(dirlist);

for k = 1:nDirs
    try
        folder = dirlist{k};
        
        savedir = fullfile(folder,'Results');
        if ~exist(savedir,'dir'), mkdir(savedir), end
        
        disp(logit(folder,['Starting retinaLayersSegmentation: ' num2str(k) ' of ' num2str(nDirs) ' - ' folder]))
        
        if ~exist(fullfile(savedir,'flattenedBscans.mat'),'file')
            preProcessFrames(folder); 
        end
        
        varStruct    = load(fullfile(savedir,'flattenedBscans.mat'),'avgScans','indToProcess','RPEheight');
        avgScans     = varStruct.avgScans;
        indToProcess = varStruct.indToProcess;
        RPEheight    = varStruct.RPEheight;
        
        if exist(fullfile(savedir,'segmentationResults.mat'),'file')
            varStruct  = load(fullfile(savedir,'segmentationResults.mat'),'traces','other','EndHeights');
            traces     = varStruct.traces; 
            other      = varStruct.other;
            EndHeights = varStruct.EndHeights;
        end

%         parfor (frame = indToProcess, workersAvailable)
        for frame = indToProcess 

            try
                
                bscan = avgScans{frame};
                
                yCSI = segmentCSI(bscan,RPEheight(frame));
                
                if isempty(yCSI), continue, end
                
                EndHeights(frame,:) = [NaN NaN];
                
                traces(frame).RPEheight = RPEheight(frame);
                traces(frame).CSI       = yCSI;
                
                disp(logit(folder,['retinaLayersSegmentation. Frame done: ' num2str(frame)]));
                
            catch localExc
                errString = ['Error frame:' num2str(frame) ' ' localExc.message];
                errString = [errString buildCallStack(localExc)];
                disp(logit(folder,errString));   
            end
        end
        
        save(fullfile(savedir,'segmentationResults.mat'),'traces','other','EndHeights');
        
        disp(logit(folder,['Done retinaLayersSegmentation: ' folder]));
        
    catch exception
        
        errString = ['Error in retinaLayersSegmentation. Message: ' exception.message];
        errString = [errString buildCallStack(exception)];
        disp(logit(folder,errString)); 
        continue
        
    end
end

end

