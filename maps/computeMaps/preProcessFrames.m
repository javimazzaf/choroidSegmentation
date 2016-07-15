function preProcessFrames(directory)

savedir   = fullfile(directory,'Results');
disp(logit(savedir, 'Starting preProcessFrames.'));

parameters = loadParameters;

varStruct = load(fullfile(directory,'DataFiles','RegisteredImages.mat'),'bscanstore','skippedind','start');
bscanstore = varStruct.bscanstore;
skippedind = varStruct.skippedind;
start      = varStruct.start;

varStruct = load(fullfile(directory,'DataFiles','ImageList.mat'),'ImageList');
ImageList = varStruct.ImageList;

numframes = numel(bscanstore);

% Initialize Variables
nodes      = cell(numframes,1);
EndHeights = nan(numframes,2);

traces     = struct('RET',[],'RPE',[],'BM',[],'CSI',[],'nCSI',[],'usedCSI',[],'RETthickness',[]);
traces(numframes).CSI = [];

other      = struct('colshifts',[],'shiftsize',[],'smallsize',[],'bigsize',[]);
other(numframes).colshifts = [];

indToProcess = setdiff(start:numframes,skippedind);

DeltaX = ImageList{start, 'scaleX'};
DeltaY = abs(diff([ImageList{[start,start + 1], 'startY'}]));

SigmaFilterScans = max(1,ceil(parameters.averagingSizeX * DeltaX / DeltaY));

interScansFilter = exp(-(-SigmaFilterScans:SigmaFilterScans).^2 / 2 / SigmaFilterScans^2);
interScansFilter = interScansFilter / sum(interScansFilter);

shiftedScans = NaN([size(bscanstore{1}), numframes]);

posRPE   = round(size(bscanstore{1},1) / 3);

safeTopLimit    = NaN(1,max(indToProcess));
safeBottomLimit = NaN(1,max(indToProcess));

% parfor frame = indToProcess
for frame = indToProcess
    try
        
        bscan = double(bscanstore{frame});
        
        [yRet,yTop] = getRetinaAndRPE(bscan,8);
        
        %-% Flattening of Image According to BM
        
        colShifts = posRPE - yTop;
        maxShift  = double(max(abs(colShifts)));
        
        shiftedScans(:,:,frame) = imageFlattening(bscan,colShifts,maxShift);
        
        %-% Store Relevant Variables
        traces(frame).RET = yRet;
        traces(frame).RPE = [];
        traces(frame).BM  = yTop;
        traces(frame).RETthickness = yTop(:) - yRet(:);
        
        other(frame).colshifts = colShifts;
        other(frame).shiftsize = maxShift;
        other(frame).smallsize = size(bscan);
        other(frame).bigsize   = size(shiftedScans(:,:,frame));
        
        safeTopLimit(frame)    = max(1,double(max(colShifts)));
        safeBottomLimit(frame) = min(size(shiftedScans,1),size(shiftedScans,1) + double(min(colShifts)));
        
        disp(frame)
    catch exception
        errString = ['Error preProcessFrames at frame:' num2str(frame) '. Message: ' exception.message] ;
        errString = [errString buildCallStack(exception)];
        disp(logit(savedir,errString));
    end
end

% safeTopLimit    = max(1,absMaxShift);
% safeBottomLimit = min(size(shiftedScans,1),size(shiftedScans,1) + absMinShift);

avgScans     = cell(1,size(shiftedScans,3));

for frame = indToProcess
    try
        
        startFrame = max(1,frame-SigmaFilterScans);
        lastFrame  = min(numframes,frame+SigmaFilterScans);
        
        allAux = [];

        % Get the safe top and bottom limits within the frames to average
        % to have them cropped at the same size.
        
        safeTop = nanmax(safeTopLimit(startFrame:lastFrame));
        safeBottom = nanmin(safeBottomLimit(startFrame:lastFrame));

        % Concatenate images to average
        for avgFrame = startFrame:lastFrame
            avgWeight = interScansFilter(avgFrame - frame + SigmaFilterScans + 1);
            allAux = cat(3,allAux,shiftedScans(safeTop:safeBottom,:,avgFrame) * avgWeight);
        end
        
        % Compute weighted average
        avgScans{frame} = nansum(allAux,3) / sum(interScansFilter((startFrame:lastFrame) - frame + SigmaFilterScans + 1));
        disp(frame)
    catch
        disp(logit(savedir,['Error preProcessFrames at frame:' num2str(frame)]));
    end
end

RPEheight = posRPE - safeTopLimit + 1;

save(fullfile(savedir,'segmentationResults.mat'),'nodes','traces','other','EndHeights');
save(fullfile(savedir,'flattenedBscans.mat'),'shiftedScans','avgScans','indToProcess','RPEheight','safeTopLimit','safeBottomLimit');

disp(logit(savedir, 'Done preProcessFrames.'));