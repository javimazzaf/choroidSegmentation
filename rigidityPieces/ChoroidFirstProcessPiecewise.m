function ChoroidFirstProcessPiecewise(varargin)
% This function segments the retina layers in all frames of each movie in
% the directories listed in varargin{1}. If varargin{2} is provided, the results
% are stored there.
% Based on ChoroidFirstProcess. The differences are:
%  - It uses getRetinaAndRPE instead of FindAllMembranes, since it may be
%    more robust (not thoroghly tested though)
%  - Retrieves some nodes of the CSI along with the weights, instead of an
%    interpolated curve.
%  - The idea is to use them in vertical fringes of the B-scans 
%    (groups of neighbouring A-Scans), and analyze the thikness in parts.
%    If the time series of the fringe shows a peak at the heart frequency,
%    it is kept. The final measurments are averaged to give a result of the
%    full movie. Potentially we could retireve an estimated variation of
%    the quantities within a movie.


if nargin >=1
    if ispc,       dataBaseDir = [filesep filesep 'HMR-BRAIN'];
     elseif ismac, dataBaseDir = [filesep 'Volumes'];
     else          dataBaseDir = [filesep 'srv' filesep 'samba'];
    end
    
    dirlist    = fullfile(dataBaseDir,varargin{1});
    resDirlist = dirlist;
else
    throw(MException('ChoroidFirstProcessPiecewise:NotEnoughArguments','Not enough arguments.'))
end

if nargin >=2
    resDirlist = fullfile(varargin{2},varargin{1});
end


c = parcluster('local');

finishup = onCleanup(@() delete(gcp('nocreate'))); %Close parallel pool when function returns or error

% Iterate over Directories
for iter = 1:numel(dirlist)
    try
        directory    = dirlist{iter};
        resDirectory = resDirlist{iter};
        
        if ~exist(resDirectory,'dir')
            mkdir(resDirectory);
        end
        
        disp(['Starting ChoroidFirstProcessPiecewise: ' directory])
        
        % Load registered images for current subject       
        aux = load(fullfile(directory,'Data Files','RegisteredImages.mat'),'bscanstore','skippedind','start');
        bscanstore = aux.bscanstore;
        skippedind = aux.skippedind;
        start      = aux.start;
        
        numframes = numel(bscanstore);
        
        %Initialize Variables
        traces     = struct('RET',[],'RPE',[],'BM',[],'CSI',[],'nCSI',[],'usedCSI',[]);
        traces(numframes).CSI = [];
        
        other      = struct('colshifts',[],'shiftsize',[],'smallsize',[],'bigsize',[]);
        other(numframes).colshifts = [];
        
        %-% Iterate over frames of current subject 
        parfor frame = start:numframes
%          for frame = start:numframes

            try
                if ismember(frame,skippedind), continue, end
                    
                bscan = double(bscanstore{frame});
                
                [yret,yTop] = getRetinaAndRPE(bscan, 8);
                yRPE = yTop;
                yBM  = yTop;
                
                posRPE = round(mean(yBM));
                
                colShifts = posRPE - yTop;
                maxShift  = double(max(abs(colShifts)));
        
                shiftedScan = imageFlattening(bscan,colShifts,maxShift);
               
%                 RPEheight = posRPE - max(1,double(max(colShifts))) + 1;
                
                yCSI = getCSIpiecewise(shiftedScan,posRPE);
                
                traces(frame).CSI=yCSI;
                traces(frame).RET = yret;
                traces(frame).RPE = yRPE;
                traces(frame).BM  = yBM;
                
                other(frame).colshifts=colShifts;
                other(frame).shiftsize=maxShift;
                other(frame).smallsize = size(bscan);
                other(frame).bigsize = size(shiftedScan);
          
                disp(logit(resDirectory,[' - Correct segmentation (frame' num2str(frame) ')']))
                  
            catch exc
                
                disp(logit(resDirectory,['Error ChoroidFirstProcessPiecewise(iter=' num2str(iter) ')(frame' num2str(frame) '): ' exc.message]))
               
            end
        end
        

        savedir = fullfile(resDirectory,'Results');
        
        mkdir(savedir)
        save(fullfile(savedir,'FirstProcessData.mat'),'traces','other');
        
        disp(logit(resDirectory,['Done ChoroidFirstProcessPiecewise(iter=' num2str(iter) '): ' resDirectory]))

    catch exception
        disp(resDirectory)
        disp(logit(resDirectory,['Skipped ChoroidFirstProcessPiecewise(iter=' num2str(iter) '): ' exception.message]))

        continue
    end
end


end

