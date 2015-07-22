function preProcessFrames(directory)

% if ~ispc && ~ismac
%     workersAvailable = Inf; 
% else
%     workersAvailable = 0; 
% end

savedir   = fullfile(directory,'Results');

varStruct = load(fullfile(directory,'Data Files','RegisteredImages.mat'),'bscanstore');
bscanstore = varStruct.bscanstore;

varStruct = load(fullfile(directory,'Data Files','ImageList.mat'),'ImageList');
ImageList = varStruct.ImageList;

numframes = numel(bscanstore);

%Initialize Variables
nodes      = cell(numframes,1);
EndHeights = nan(numframes,2);

traces     = struct('RET',[],'RPE',[],'BM',[],'CSI',[],'nCSI',[],'usedCSI',[]);
traces(numframes).CSI = [];

other      = struct('colshifts',[],'shiftsize',[],'smallsize',[],'bigsize',[]);
other(numframes).colshifts = [];

indToProcess = setdiff(1:numframes,skippedind);

DeltaX = ImageList(start).scaleX;
DeltaY = - diff([ImageList([start,start + 1]).startY]);

SigmaFilterScans = max(1,ceil(getParameter('AVERAGING_SIZE') * DeltaX / DeltaY));

interScansFilter = exp(-(-SigmaFilterScans:SigmaFilterScans).^2 / 2 / SigmaFilterScans^2);
interScansFilter = interScansFilter / sum(interScansFilter);

shiftedScans = NaN([size(bscanstore{1}), numframes]);

posRPE   = round(size(bscanstore{1},1) / 3);

absMinShift = Inf;
absMaxShift = -Inf;
parfor frame = indToProcess
% for frame = indToProcess
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
        
        other(frame).colshifts = colShifts;
        other(frame).shiftsize = maxShift;
        other(frame).smallsize = size(bscan);
        other(frame).bigsize   = size(shiftedScans(:,:,frame));
        
        absMaxShift = max(absMaxShift,double(max(colShifts)));
        absMinShift = min(absMinShift,double(min(colShifts)));
        
        disp(frame)
    catch
        disp(logit(savedir,['Error frame:' num2str(frame)]));
    end
end

safeTopLimit    = max(1,absMaxShift);
safeBottomLimit = min(size(shiftedScans,1),size(shiftedScans,1) + absMinShift);

shiftedScans = shiftedScans(safeTopLimit:safeBottomLimit,:,:);
avgScans     = NaN(size(shiftedScans));

RPEheight = posRPE - safeTopLimit + 1;

for frame = indToProcess
    try
        
        startFrame = max(1,frame-SigmaFilterScans);
        lastFrame  = min(numframes,frame+SigmaFilterScans);
        
        allAux = [];
        
        % Concatenate images to average
        for avgFrame = startFrame:lastFrame
            avgWeight = interScansFilter(avgFrame - frame + SigmaFilterScans + 1);
            allAux = cat(3,allAux,shiftedScans(:,:,avgFrame) * avgWeight);
        end
        
        % Compute weighted average
        avgScans(:,:,frame) = nansum(allAux,3) / sum(interScansFilter((startFrame:lastFrame) - frame + SigmaFilterScans + 1));
        disp(frame)
    catch
        disp(logit(savedir,['Error frame:' num2str(frame)]));
    end
end

save(fullfile(savedir,'FirstProcessDataNew.mat'),'nodes','traces','other','EndHeights');
save(fullfile(savedir,'processedImages.mat'),'shiftedScans','avgScans','indToProcess','RPEheight');