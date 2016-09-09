function successAssessment

outDir = '/Users/javimazzaf/Documents/work/proyectos/ophthalmology/manuscript/performanceAssessment/';

if ~exist(fullfile(outDir,'bScanStats.mat'),'file')
    computeSuccessAssessment(outDir)
end

load(fullfile(outDir,'bScanStats.mat'), 'has', 'numBscans', 'masks', 'goodTraces','newDB','msk','skipped','skipCause')

%Eclude nonMacula and badImaging
skipCause(cellfun(@isempty, skipCause)) = repmat({'none'},sum(cellfun(@isempty, skipCause)),1);%Write none where the skipcause is empty
allMapsMask = ~ismember(skipCause,{'badImagingRadio';'notMaculaRadio'});

numBscans  = numBscans(allMapsMask);
goodTraces = goodTraces(allMapsMask);
newDB      = newDB(allMapsMask,:);
msk        = msk(allMapsMask);
skipped    = skipped(allMapsMask);
skipCause  = skipCause(allMapsMask);

skippedBMmask  = ismember(skipCause,{'wrongBMradio'});
skippedCSImask = ismember(skipCause,{'wrongCSIradio'});

% causes = {'wrongBMradio';'wrongCSIradio'};
% casesPerCause = cellfun(@(x) sum(ismember(skipCause,x)), causes);
% 
% figure
% bar(casesPerCause)
% set(gca,'XTickLabels',causes)

valid = ~skipped;

gTraces = goodTraces(valid);
nTraces = numBscans(valid);

percent = gTraces ./ nTraces * 100;

% Regroup conditions to bigger groups: 'Normal';'AMD';'OAG';'Other'};
allGroups = newDB{:,'Group'};

allGroups(ismember(allGroups,'Bleb'))        = repmat({'OAG'},sum(ismember(allGroups,'Bleb')),1);
allGroups(ismember(allGroups,'OAG Precoce')) = repmat({'OAG'},sum(ismember(allGroups,'OAG Precoce')),1);
allGroups(ismember(allGroups,'OAG Suspect')) = repmat({'OAG'},sum(ismember(allGroups,'OAG Suspect')),1);
allGroups(ismember(allGroups,'OHT'))         = repmat({'OAG'},sum(ismember(allGroups,'OHT')),1);

allGroups(ismember(allGroups,'Early AMD')) = repmat({'AMD'},sum(ismember(allGroups,'Early AMD')),1);
allGroups(ismember(allGroups,'Wet AMD'))   = repmat({'AMD'},sum(ismember(allGroups,'Wet AMD')),1);

allGroups(ismember(allGroups,'Uveitis'))            = repmat({'Other'},sum(ismember(allGroups,'Uveitis')),1);
allGroups(ismember(allGroups,'Geographic Atrophy')) = repmat({'Other'},sum(ismember(allGroups,'Geographic Atrophy')),1);
allGroups(ismember(allGroups,'Other/No Group'))     = repmat({'Other'},sum(ismember(allGroups,'Other/No Group')),1);

% Resort data
violinGroups = allGroups(valid);
violinData   = percent;

mskNormal = ismember(violinGroups,'Normal');
mskAMD    = ismember(violinGroups,'AMD');
mskOAG    = ismember(violinGroups,'OAG');
mskOther  = ismember(violinGroups,'Other');

violinGroups = [violinGroups(mskNormal);violinGroups(mskAMD);violinGroups(mskOAG);violinGroups(mskOther)];
violinData   = [violinData(mskNormal);violinData(mskAMD);violinData(mskOAG);violinData(mskOther)];

clMap = winter;
fg1 = figure;
distributionPlot(violinData,'histOpt',1,'divFactor',3, 'groups', violinGroups,...
     'colormap',clMap(20:55,:),'showMM', 0);

ylim([70 110])
view(-90, 90)
set(gca,'FontSize',16,'yTick',60:10:100)
print(fg1, fullfile(outDir,'violin.pdf'),'-dpdf')

%% ** Compute map-based success rate **
groups = {'Normal';'AMD';'OAG';'Other'};

% Count successful and error Maps
casesGoodPerGroup     = cellfun(@(x) sum(ismember(allGroups(valid),x)), groups);
casesErrorBMPerGroup  = cellfun(@(x) sum(ismember(allGroups(skippedBMmask),x)), groups);
casesErrorCSIPerGroup = cellfun(@(x) sum(ismember(allGroups(skippedCSImask),x)), groups);

% Plot in stacked bars
fg2 = figure;
bar([casesGoodPerGroup,casesErrorBMPerGroup,casesErrorCSIPerGroup],'stacked')
set(gca,'FontSize',16,'XTickLabels',{'Normal';'AMD';'OAG';'Other'})
legend({'Correct';'BM error';'CSI error'})
print(fg2,fullfile(outDir,'successPerCondition.pdf'),'-dpdf')

% Compute percentages and write a text file
casesTotal = sum([casesGoodPerGroup,casesErrorBMPerGroup,casesErrorCSIPerGroup]')';
casesPerc  = [casesGoodPerGroup./casesTotal,casesErrorBMPerGroup./casesTotal,casesErrorCSIPerGroup./casesTotal]' * 100; 
casesPercTable = array2table(casesPerc,'VariableNames',{'Normal';'AMD';'OAG';'Other'},'RowNames',{'Correct';'BM error';'CSI error'});
writetable(casesPercTable,fullfile(outDir,'successPercentages.txt'));

end

function computeSuccessAssessment(outDir)

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

[~, has, numBscans, masks, dbase] = getDirectories(topdir,groups,studies,reproducibility);

patientsFullList = fullfile('/Volumes/share/SpectralisData/Patients',...
                        strcat(dbase.ID,        repmat({' '}, height(dbase),1),...
                               dbase.FamilyName,repmat({', '},height(dbase),1),...
                               dbase.FirstName),...
                        dbase.ExamDate,...
                        dbase.Study,...
                        dbase.Eye);

ix = ismember(has.All,has.Map); 
numBscans = numBscans(ix);
                    
% Chosen list to study
dirList = fullfile(topdir,has.Map);

goodTraces = zeros(size(dirList));
skipped    = logical(zeros(size(dirList)));
skipCause  = cell(size(dirList));

msk = logical(zeros(size(dirList)));

newDB = [];

%Loop through directories
for k = 1:numel(dirList)
    thisFolder = dirList{k};
    
    lastChar = thisFolder(end);
    
    if (lastChar >= '0' & lastChar <= '9')
        %Strip last char from path
        patternStr = thisFolder(1:end-2);
    else
        patternStr = thisFolder;
    end
    
    dbIndex = find(ismember(patientsFullList,patternStr),1,'first');
    
    dbLine = dbase(dbIndex,:);
    
    newDB = [newDB;dbLine];
    
    if ~exist(fullfile(thisFolder,'Results','segmentationResults.mat'),'file'), continue, end
    
    if exist(fullfile(thisFolder,'Results','postProcessingAnnotations.mat'),'file')
        load(fullfile(thisFolder,'Results','postProcessingAnnotations.mat'),'annotations')
        
        if annotations.skip ~= 0
           skipped(k) = true;
           skipCause{k} = annotations.skipCause;
           continue
        end
    end
    
    load(fullfile(thisFolder,'Results','segmentationResults.mat'),'traces');
    
    % Loop through B-Scans
    for q = 1:length(traces)
        
        if isempty(traces(q).CSI), continue, end
        
        CSI = traces(q).CSI;

        if ~any([CSI(:).keep]), continue, end
        
        % Counts the B-scan if it has at least one trace
        goodTraces(k) = goodTraces(k) + 1;
 
    end
    
    msk(k) = true;
    
end

if ~exist(outDir,'dir')
    mkdir(outDir);
end

% newDB = newDB(msk,:);

save(fullfile(outDir,'bScanStats.mat'), 'has', 'numBscans', 'masks', 'goodTraces','newDB','msk','skipped','skipCause')



end