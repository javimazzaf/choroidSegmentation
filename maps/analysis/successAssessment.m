function successAssessment(outDir)

if ~ispc
    if ismac
        topdir = '/Volumes/';
    else
        topdir='/srv/samba/';
    end
else
    error('Set topdir variable. ~Line 14')
end

groups          = [];
studies         = {'Choroidal Mapping'};
reproducibility = '';

[~, has, numBscans, masks] = getDirectories(topdir,groups,studies,reproducibility);

% Chosen list to study
dirList = fullfile(topdir,has.All);

goodTraces = zeros(size(dirList));

%Loop through directories
for k = 1:numel(dirList)
    thisFolder = dirList{k};
    
    if ~exist(fullfile(thisFolder,'Results','segmentationResults.mat'),'file'), continue, end
    
    load(fullfile(thisFolder,'Results','segmentationResults.mat'),'traces','start');
    
    % Loop through B-Scans
    for q = start:length(traces)
        
        if isempty(traces(q).CSI), continue, end
        
        CSI = traces(q).CSI;

        if ~any([CSI(:).keep]), continue, end
        
        % Counts the B-scan if it has at least one trace
        goodTraces(k) = goodTraces(k) + 1;
 
    end
    
end

if ~exist(outDir,'dir')
    mkdir(outDir);
end

save(fullfile(outDir,'bScanStats.mat'), 'has', 'numBscans', 'masks', 'goodTraces')



end