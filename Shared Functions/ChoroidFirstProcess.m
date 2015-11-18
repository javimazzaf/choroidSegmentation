function [messedup,error,runtime] = ChoroidFirstProcess(varargin)
% This function segments the retina interface, RPE, Bruchs membrane and the
% coroid-sclera interface, in each frame in the array bscanstore in the
% file RegisteredImages.mat for each directory in varargin{1}.


% if length(varargin)==1
%     if ispc
%         dirlist = fullfile([filesep filesep 'HMR-BRAIN'],varargin{1});
%     elseif ismac
%         dirlist = fullfile([filesep 'Volumes'],varargin{1});
%     else
%         dirlist = fullfile(filesep,'srv','samba',varargin{1});
%     end
% else
%     if ispc
%         load(fullfile([filesep filesep 'HMR-BRAIN'],'Share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
%         dirlist=fullfile([filesep filesep 'HMR-BRAIN'],dirlist);
%     else
%         load(fullfile(filesep,'srv','samba','Share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
%         dirlist=fullfile(filesep,'srv','samba',strrep(dirlist,'\','/'));
%     end
%     [missdata,missraw,missprocessim,missregims,missresults]=CheckDirContents(dirlist);
%     dirlist=dirlist(~missregims);
%     if isempty(dirlist)
%         errordlg('No diretories prerequisite data. Run required registration program first')
%         return
%     end
% end

if nargin >=1
    if ispc,       dataBaseDir = [filesep filesep 'HMR-BRAIN'];
     elseif ismac, dataBaseDir = [filesep 'Volumes'];
     else          dataBaseDir = [filesep 'srv' filesep 'samba'];
    end
    
    dirlist    = fullfile(dataBaseDir,varargin{1});
    resDirlist = dirlist;
else
    throw(MException('ChoroidFirstProcess:NotEnoughArguments','Not enough arguments.'))
end

% If second parameter is set, it is used as the base path for the results.
% Otherwise, the results are stored in the same dir as the input data.
if nargin >=2
    resDirlist = fullfile(varargin{2},varargin{1});
end


% c = parcluster('local');

finishup = onCleanup(@() delete(gcp('nocreate'))); %Close parallel pool when function returns or error


startTime = tic;
messedup  = [];
error     =  cell(length(dirlist),1);

% Iterate over subjects
for iter = 1:numel(dirlist)
    try
        directory    = dirlist{iter};
        resDirectory = resDirlist{iter};
        
        disp(['Starting ChoroidFirstProcess: ' directory])
        
        % Load registered images for current subject       
        load(fullfile(directory,'Data Files','RegisteredImages.mat'),'bscanstore','skippedind','start');
        
        numframes = numel(bscanstore);
        
        % Load Oriented gradient if already computed
        if exist(fullfile(directory,'Data Files','OrientedGradient.mat'),'file')
            load(fullfile(directory,'Data Files','OrientedGradient.mat'))
        else
            OG = cell(numframes,1);
        end
        
        %Initialize Variables
        nodes      = cell(numframes,1);
        EndHeights = nan(numframes,2);
        
        traces     = struct('RET',[],'RPE',[],'BM',[],'CSI',[],'nCSI',[],'usedCSI',[]);
        traces(numframes).CSI=[];
        
        other      = struct('colshifts',[],'shiftsize',[],'smallsize',[],'bigsize',[]);
        other(numframes).colshifts=[];
        
        toSkip = skippedind;
        
        %-% Iterate over frames of current subject 
        parfor frame = start:numframes
%         for frame = indToProcess

            try
                if ismember(frame,toSkip), continue, end
                    
                bscan = bscanstore{frame};
                
%                 [yret,~,yRPE,yBM] = FindAllMembranes(bscan,directory);
                [yret,~,yRPE,yBM] = FindAllMembranes(bscan,resDirectory);
                
                traces(frame).RET = yret;
                traces(frame).RPE = yRPE;
                traces(frame).BM  = yBM;
                
                %-% Flattening of Image According to BM
                meanBM    = round(mean(yBM));
                colShifts = meanBM - yBM;
                maxShift  = double(max(abs(colShifts)));
                
                shiftedBscan = BMImageShift(bscan,colShifts,maxShift,'Pad');
                
                %-% Edge Probability
                if isempty(OG{frame})
                    scalesize = [10 15 20];
                    angles    = [-20 0 20];
                    [~,padPb] = EdgeProbability(shiftedBscan,scalesize,angles,meanBM,maxShift);
                    OG{frame} = padPb;
                end
                
                %-% Inflection Points
                Infl2 = zeros(size(shiftedBscan));
                filteredBscan = imfilter(shiftedBscan,OrientedGaussian([3 3],0));
                colspacing    = 2;
                
                nCols = size(filteredBscan,2);
                
                for j = 1:nCols
                    filteredAscan = smooth(double(filteredBscan(:,j)),10);
                    
                    grad  = gradient(filteredAscan); 
                    grad2 = del2(    filteredAscan); 
%                     z     = (grad2 < 1E-16) & (grad > 0.7);
                    z     = (abs(grad2) < 1E-2) & (grad > 0.7); %[JM] 
                    z(1:meanBM + maxShift + 15) = 0;
                    
                    Infl2(z,j) = 1; 
                end
                
%                 % START **** ALTERNATIVE INFLEXION POINT SEARCH ****
%                 smoothedBscan = filter2(fspecial('disk',5),filteredBscan,'same');
%                 [gradX,gradY]  = gradient(smoothedBscan);
%                 gradM   = sqrt(gradX.^2 + gradY.^2);
%                 gradAng = atan2(gradY,gradX);
%                 
%                 laplac = del2(smoothedBscan);
%                 %       #zero of laplac#  &  #big slope#  &         #downward Yslope#
%                 z  = (abs(laplac) < 5E-2) & (gradM > 0.7) & (sin(gradAng) > sin(pi/4));
%                 z(1:meanBM + maxShift + 15,:) = 0;
%                 Infl2 = z; 
%                 % END **** ALTERNATIVE INFLEXION POINT SEARCH ****
                
                Infl2 = bwmorph(Infl2,'clean');
                Infl2 = imfill(Infl2,'holes');
                Infl2 = bwmorph(Infl2,'skel','inf');
                
                Infl2(:,setdiff((1:nCols),(1:colspacing:nCols))) = 0;
                
                Infl2 = bwmorph(Infl2,'shrink','inf');
                g     = imextendedmin(filteredBscan,10);
                
                % Not sure about this. Check how it works with one example
                Infl2(Infl2 & g) = 0;             
 
                nodes{frame} = Infl2;
                
                %-% Find CSI
%                 [yCSI, usedNodes] = FindCSI(nodes{frame},OG{frame},maxShift,colShifts);
               yCSI = FindCSI(nodes{frame},OG{frame},maxShift,colShifts);
                
                if isempty(yCSI), continue, end

                EndHeights(frame,:) = [yCSI(1) - yBM(1) , yCSI(end) - yBM(end)];
                
                %-% Store Other Relevant Variables
                traces(frame).CSI=yCSI;
                other(frame).colshifts=colShifts;
                other(frame).shiftsize=maxShift;
                other(frame).smallsize = size(bscan);
                other(frame).bigsize = size(shiftedBscan);
                
%                 disp(logit(directory,['Correct segmentation (frame' num2str(frame) ')']))
                disp(logit(resDirectory,['Correct segmentation (frame' num2str(frame) ')']))
                
                
            catch exc
                
%                 disp(logit(directory,['Error ChoroidFirstProcess(iter=' num2str(iter) ')(frame' num2str(frame) '): ' exc.message]))
                disp(logit(resDirectory,['Error ChoroidFirstProcess(iter=' num2str(iter) ')(frame' num2str(frame) '): ' exc.message]))
               
            end
        end
        
%         if ~exist(fullfile(directory,'Data Files','OrientedGradient.mat'),'file')
%             save(fullfile(directory,'Data Files','OrientedGradient.mat'),'OG')
%         end
        if ~exist(fullfile(resDirectory,'Data Files','OrientedGradient.mat'),'file')
            save(fullfile(resDirectory,'Data Files','OrientedGradient.mat'),'OG')
        end
        
        %-% Save Data
        
%         savedir = fullfile(directory,'Results');
        savedir = fullfile(resDirectory,'Results');
        
        mkdir(savedir)
        save(fullfile(savedir,'FirstProcessData.mat'),'nodes','traces','other','EndHeights');
        
%         disp(logit(directory,['Done ChoroidFirstProcess(iter=' num2str(iter) '): ' directory]))
        disp(logit(resDirectory,['Done ChoroidFirstProcess(iter=' num2str(iter) '): ' resDirectory]))

    catch exception
%         disp(directory)
        disp(resDirectory)
        error{iter}=exception;
%         disp(logit(directory,['Skipped ChoroidFirstProcess(iter=' num2str(iter) '): ' exception.message]))
        disp(logit(resDirectory,['Skipped ChoroidFirstProcess(iter=' num2str(iter) '): ' exception.message]))
        messedup=[messedup;iter];

        continue
    end
end

runtime = toc(startTime);

end

