function [messedup,error,runtime] = ChoroidMapFirstProcess(varargin)
% This function segments the retina interface, RPE, Bruchs membrane and the
% coroid-sclera interface, in each frame in the array bscanstore in the
% file RegisteredImages.mat for each directory in varargin{1}.

% The current version is more robust to irregularities in the upper layers.

if length(varargin)==1
    if ispc
        dirlist = fullfile([filesep filesep 'HMR-BRAIN'],varargin{1});
    elseif ismac
        dirlist = fullfile([filesep 'Volumes'],varargin{1});
    else
        dirlist = fullfile(filesep,'srv','samba',varargin{1});
    end
else
    if ispc
        load(fullfile([filesep filesep 'HMR-BRAIN'],'Share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
        dirlist=fullfile([filesep filesep 'HMR-BRAIN'],dirlist);
    elseif ismac
        load(fullfile([filesep filesep 'Volumes'],'Share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
        dirlist = fullfile([filesep filesep 'Volumes'],dirlist);
    else
        load(fullfile(filesep,'srv','samba','Share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
        dirlist=fullfile(filesep,'srv','samba',strrep(dirlist,'\','/'));
    end
    
    [missdata,missraw,missprocessim,missregims,missresults] = CheckDirContents(dirlist);
    
    dirlist=dirlist(~missregims);
    
    if isempty(dirlist)
        errordlg('No diretories prerequisite data. Run required registration program first')
        return
    end
end

%Close parallel pool when the process exits the scope of this function
finishup = onCleanup(@() delete(gcp('nocreate'))); 


startTime = tic;
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
        
        numframes = numel(bscanstore);
        
        % Load Oriented gradient if already computed
        %         if exist(fullfile(directory,'Data Files','OrientedGradient.mat'),'file')
        %             load(fullfile(directory,'Data Files','OrientedGradient.mat'))
        %         else
        %             OG = cell(numframes,1);
        %         end
        
        %Initialize Variables
        nodes      = cell(numframes,1);
        EndHeights = nan(numframes,2);
        
        traces     = struct('RET',[],'RPE',[],'BM',[],'CSI',[],'nCSI',[],'usedCSI',[]);
        traces(numframes).CSI = [];
        
        other      =struct('colshifts',[],'shiftsize',[],'smallsize',[],'bigsize',[]);
        other(numframes).colshifts = [];
        
        indToProcess = setdiff(start:numframes,skippedind);
        
        %-% Iterate over frames of current subject
        parfor frame = indToProcess
            %         for frame = indToProcess
            try
                
                %                 if ~ismember(frame,skippedind) , continue, end
                
%                 disp(logit(savedir,'Before bscanstore'));
                
                bscan = double(bscanstore{frame});
                
%                 disp(logit(savedir,'Before GetRetina'));
                
                [yRet,yTop] = getRetinaAndRPE(bscan,8);
                
%                 disp(logit(savedir,'After GetRetina'));
                
                [yCSI,colShifts,maxShift,shiftedBscan] = getCSI(bscan, yTop);
                
%                 disp(logit(savedir,'After getCSI'));
                
                if isempty(yCSI), continue, end
                
                EndHeights(frame,:) = [NaN NaN];
                
                %-% Store Other Relevant Variables
                traces(frame).RET = yRet;
                traces(frame).RPE = [];
                traces(frame).BM  = yTop;
                traces(frame).CSI = yCSI;
                
                
                %                 imshow(bscan,[]), hold on
                %                 errorbar(yCSI.x,yCSI.y,yCSI.weight * 10)
                
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

runtime = toc(startTime);

end

