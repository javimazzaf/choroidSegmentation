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
        
        if ~exist(fullfile(savedir,'processedImages.mat'),'file')
            preProcessFrames(directory); 
        end
        
        load(fullfile(savedir,'processedImages.mat'),'shiftedScans','avgScans','indToProcess','RPEheight');
        
        if exist(fullfile(savedir,'FirstProcessDataNew.mat'),'file')
            load(fullfile(savedir,'FirstProcessDataNew.mat'),'traces','other','EndHeights');
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
                traces(frame).RPEheight = RPEheight;
                traces(frame).CSI = yCSI;
                
%                 other(frame).colshifts = colShifts;
%                 other(frame).shiftsize = maxShift;
%                 other(frame).smallsize = size(bscan);
%                 other(frame).bigsize   = size(bscan);
                
                disp(logit(savedir,['Succeeded frame:' num2str(frame)]));
                
            catch localExc
                errString = ['Error frame:' num2str(frame) ' ' localExc.message];
                errString = [errString buildCallStack(localExc)];
                disp(logit(savedir,errString));   
            end
        end
        
        %-% Save Data
        save(fullfile(savedir,'FirstProcessDataNew.mat'),'traces','other','EndHeights');
        
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

