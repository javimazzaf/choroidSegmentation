% Copyright (C) 2017, Javier Mazzaferri, Luke Beaton, Santiago Costantino 
% Hopital Maisonneuve-Rosemont, 
% Centre de Recherche
% www.biophotonics.ca
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

function preProcessFrames(directory)

savedir   = fullfile(directory,'Results');
disp(logit(directory, 'Starting preProcessFrames.'))

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

dispInline('init',logit(directory,'preProcessFrames. Starting flattening'));

% parfor frame = indToProcess
for frame = indToProcess
    try
        
        bscan = double(bscanstore{frame});
        
        [yRet,yTop] = getRetinaAndBM(bscan,8);
        
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
        
        dispInline('update',logit(directory,['preProcessFrames. Flattening Frame: ' num2str(frame)]));
    catch exception
        errString = ['Error preProcessFrames at frame:' num2str(frame) '. Message: ' exception.message] ;
        errString = [errString buildCallStack(exception)];
        dispInline('end',logit(directory,errString));
    end
end

dispInline('end',logit(directory,'preProcessFrames. Done flattening'));

avgScans     = cell(1,size(shiftedScans,3));

dispInline('init',logit(directory,'preProcessFrames. Starting smoothing'));

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
        dispInline('update',logit(directory,['preProcessFrames. Smoothing Frame: ' num2str(frame)]));
    catch
        dispInline('end',logit(directory,['Error preProcessFrames at frame:' num2str(frame)]));
    end
end

dispInline('end',logit(directory,'preProcessFrames. Done smoothing'));

RPEheight = posRPE - safeTopLimit + 1;

save(fullfile(savedir,'segmentationResults.mat'),'nodes','traces','other','EndHeights');
save(fullfile(savedir,'flattenedBscans.mat'),'shiftedScans','avgScans','indToProcess','RPEheight','safeTopLimit','safeBottomLimit');

disp(logit(directory, 'Done preProcessFrames.'));