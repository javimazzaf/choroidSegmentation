function [messedup,error] = ChoroidMapFirstProcess(varargin)
% This function segments the retina interface, RPE, Bruchs membrane and the
% coroid-sclera interface, in each frame in the array bscanstore in the
% file RegisteredImages.mat for each directory in varargin{1}.

% The current version is more robust to irregularities in the upper layers.

if ispc
    dirlist = fullfile([filesep filesep 'HMR-BRAIN'],varargin{1});
    workersAvailable = Inf; %Uses parallel computing
elseif ismac
    dirlist = fullfile([filesep 'Volumes'],varargin{1});
    workersAvailable = 0; %Uses 1 worker computing
else
    dirlist = fullfile(filesep,'srv','samba',varargin{1});
    workersAvailable = 0; %Uses 1 worker computing
end


%Close parallel pool when the process exits the scope of this function
if workersAvailable > 0
   finishup = onCleanup(@() delete(gcp('nocreate'))); 
end

messedup  = [];
error     =  cell(length(dirlist),1);

% Iterate over subjects
for iter = 1:numel(dirlist)
    try
        directory = dirlist{iter};
        
        savedir   = fullfile(directory,'Results');
        if ~exist(savedir,'dir'), mkdir(savedir), end
        
        disp(['Starting ChoroidFirstProcess: ' directory])
        
        % Load registered images for current subject
        load(fullfile(directory,'Data Files','RegisteredImages.mat'));
        load(fullfile(directory,'Data Files','ImageList.mat'))
        
        numframes = numel(bscanstore);
        
        %Initialize Variables
        nodes      = cell(numframes,1);
        EndHeights = nan(numframes,2);
        
        traces     = struct('RET',[],'RPE',[],'BM',[],'CSI',[],'nCSI',[],'usedCSI',[]);
        traces(numframes).CSI = [];
        
        other      = struct('colshifts',[],'shiftsize',[],'smallsize',[],'bigsize',[]);
        other(numframes).colshifts = [];
        
        indToProcess = setdiff(start:numframes,skippedind);
        
%       Computes RPE on each frame, flattens the images with respecto to it,
%       registers them to the same RPE, and averages neightbors.

        % Get the sampling of BScans to decide the type of averaging to do.
        DeltaX = ImageList(start).scaleX;
        DeltaY = - diff([ImageList([start,start + 1]).startY]);
        
        AVERAGING_SIZE   = getParameter('AVERAGING_SIZE');
        SigmaFilterScans = max(1,ceil(AVERAGING_SIZE * DeltaX / DeltaY));
        
        interScansFilter = exp(-(-SigmaFilterScans:SigmaFilterScans).^2 / 2 / SigmaFilterScans^2);
        interScansFilter = interScansFilter / sum(interScansFilter);
        
        shiftedScans = NaN([size(bscanstore{1}), numframes]);
        
        posRPE   = round(size(bscanstore{1},1) / 3);
        
        absMinShift = Inf;
        absMaxShift = -Inf;
%         parfor (frame = indToProcess, workersAvailable)
        for frame = indToProcess
            try
                
                bscan = double(bscanstore{frame});
                
                [yRet,yTop] = getRetinaAndRPE(bscan,8);
                
                %-% Flattening of Image According to BM
                
                colShifts = posRPE - yTop;
                maxShift  = double(max(abs(colShifts)));
                
%                 thisShiftSize = 2 * maxShift + size(bscan,1);
                
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
        
        RPEheight = posRPE - absMaxShift;
        
        shiftedScans = shiftedScans(absMaxShift:end+absMinShift,:,:);
        avgScans     = NaN(size(shiftedScans));
        
        for frame = indToProcess
            try        
             
                startFrame = max(1,frame-SigmaFilterScans);
                lastFrame  = min(numframes,frame+SigmaFilterScans);
                
                auxSum = zeros(size(shiftedScans,1),size(shiftedScans,2));
                
                % Make additions for average
                for avgFrame = startFrame:lastFrame
                    aux = shiftedScans(:,:,avgFrame) * interScansFilter(avgFrame - frame + SigmaFilterScans + 1);
                    auxSum = nansum(cat(3,auxSum,aux),3); 
                end
                
                % Compute weighted average
                avgScans(:,:,frame) = auxSum / sum(interScansFilter((startFrame:lastFrame) - frame + SigmaFilterScans + 1));
                disp(frame)
            catch
                disp(logit(savedir,['Error frame:' num2str(frame)]));   
            end
        end        
                
        %-% Iterate over frames of current subject
%         parfor (frame = indToProcess, workersAvailable)
        for frame = indToProcess
            try
                
                bscan = avgScans(:,:,frame);
                
                yCSI = getCSI(bscan,RPEheight);
                
                if isempty(yCSI), continue, end
                
                EndHeights(frame,:) = [NaN NaN];
                
                %-% Store Other Relevant Variables
%                 traces(frame).RET = yRet;
%                 traces(frame).RPE = [];
%                 traces(frame).BM  = yTop;
                traces(frame).CSI = yCSI;
                
                other(frame).colshifts = colShifts;
                other(frame).shiftsize = maxShift;
                other(frame).smallsize = size(bscan);
                other(frame).bigsize   = size(shiftedBscan);
                
                disp(logit(savedir,['Succeeded frame:' num2str(frame)]));
                
            catch
                disp(logit(savedir,['Error frame:' num2str(frame)]));   
            end
        end
        
        %         if ~exist(fullfile(directory,'Data Files','OrientedGradient.mat'),'file')
        %             save(fullfile(directory,'Data Files','OrientedGradient.mat'),'OG')
        %         end
        
        %-% Save Data
        save(fullfile(savedir,'FirstProcessData.mat'),'nodes','traces','other','EndHeights');
        
        % Log & Display
        disp(logit(savedir,['Done ChoroidMapFirstProcess(iter=' num2str(iter) '): ' directory]));
        
    catch exception
        error{iter} = exception;
        
        % Log & Display
        disp(logit(savedir,['Skipped ' exception.stack.name ' (iter=' num2str(iter) '): ' exception.message ' in line ' num2str(exception.stack.line)]));
        
        messedup = [messedup;iter];
        
        continue
    end
end

end

