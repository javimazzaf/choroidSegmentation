% Select directories that are ready for each particular step of the
% processing, or that have specific information
function [todoDirs, hasDirs, numBscans, masks, dbase] = getDirectories(topdir,groups,studies,reprod)

databasedir=fullfile(topdir,'share','SpectralisData');

load(fullfile(databasedir,'DatabaseFile.mat'))

%Sort Database by Last Name and Get Unique Patient Entries
dbase = sortrows(dbase,{'FamilyName','ExamDate','Study','Eye'},{'ascend','descend','ascend','ascend'});

patientsFullList = fullfile(databasedir,'Patients',...
                        strcat(dbase.ID,        repmat({' '}, height(dbase),1),...
                               dbase.FamilyName,repmat({', '},height(dbase),1),...
                               dbase.FirstName),...
                        dbase.ExamDate,...
                        dbase.Study);

% Filter By study and Group
msk       = true(size(dbase.Study));

if ~isempty(studies)
   msk = msk & ismember(dbase.Study,studies);
end

if ~isempty(groups)
   msk = msk & ismember(dbase.Group,groups);
end

% Reproducibility
switch reprod
    case 'Yes'
        msk = msk & strcmp(dbase.Reproducibility,'Yes');
    case 'No'
        msk = msk & ~strcmp(dbase.Reproducibility,'Yes');
    %Otherwise does nothing    
end

patientsFilteredList  = cellfun(@genpath,unique(patientsFullList(msk)),'uniformoutput',0)';

catstr=[];
for i=1:length(patientsFilteredList)
    catstr = [catstr patientsFilteredList{i}];
end

%Split long string separated by pathsep, into a cell array of strings
measDirList = regexp(catstr,['[^' pathsep ']*'],'match')';

% Select the bottom directories (just below OS or OD)
% Process differently ONH from the rest of studies
onhMsk      = ~cellfun(@isempty,strfind(measDirList,'Optic Nerve Head'));

onhDirs   = measDirList(onhMsk);
onhDirs   = onhDirs(  ~cellfun(@isempty,regexp(onhDirs,  ['.*Optic Nerve Head\' filesep 'O[SD](\s\d+)?\' filesep '\d{2,3}$'],'match')));

otherDirs = measDirList(~onhMsk);
otherDirs = otherDirs(~cellfun(@isempty,regexp(otherDirs,'.*O[SD](\s\d+)?$',                                                 'match')));

% Gather all the measurement directories in one array
bottomdirs=[onhDirs;otherDirs];

% Build exam dates array associated with bottomdirs
% examDates = cellfun(@(x) datetime(x,'InputFormat','dd-MM-yyyy'),regexp(bottomdirs,'\d\d-\d\d-\d\d\d\d', 'match'),'UniformOutput',false);

% Get masks for  directories that are on a specific step of the processing
masks.hasRawMsk   = logical(cellfun(@(aux) exist(aux,'dir'), fullfile(bottomdirs,'Raw Images')));
masks.hasRegMsk   = logical(cellfun(@(aux) exist(aux,'file'),fullfile(bottomdirs,'DataFiles','RegisteredImages.mat')));
masks.hasFrsMsk   = logical(cellfun(@(aux) exist(aux,'file'),fullfile(bottomdirs,'Results',   'FirstProcessData.mat')));
masks.hasSegmentationMsk   = logical(cellfun(@(aux) exist(aux,'file'),fullfile(bottomdirs,'Results',   'segmentationResults.mat')));
masks.hasPosMsk   = logical(cellfun(@(aux) exist(aux,'file'),fullfile(bottomdirs,'Results',   'PostProcessData.mat')));
masks.hasFigMsk   = logical(cellfun(@(pth) ~isempty(dir(fullfile(pth,'*.fig'))) ,fullfile(bottomdirs,'Results')));
masks.hasDCTMsk   = logical(cellfun(@(aux) exist(aux,'file'),fullfile(bottomdirs,'Results',   'DeltaCT.mat')));
masks.hasORMsk    = logical(cellfun(@(aux) exist(aux,'file'),fullfile(bottomdirs,'Results','Results.mat')));
masks.hasMapMsk   = logical(cellfun(@(aux) exist(aux,'file'),fullfile(bottomdirs,'Results','ChoroidMap.mat')));
masks.hasMovMsk   = logical(cellfun(@(aux) exist(aux,'file'),fullfile(bottomdirs,'Results','choroidMovie.gif')));
masks.hasErrMsk   = logical(cellfun(@(aux) exist(aux,'dir') ,fullfile(bottomdirs,'Error Folder')));
masks.hasAnotMsk  = logical(cellfun(@isAnnotated,fullfile(bottomdirs,'Results','postProcessingAnnotations.mat')));
masks.hasSkipMsk  = logical(cellfun(@isSkipped,fullfile(bottomdirs,'Results','postProcessingAnnotations.mat')));
masks.hasbScansMsk= logical(cellfun(@(aux) exist(aux,'file'),fullfile(bottomdirs,'Results','bScans.mat')));


numBscans   = cellfun(@(pth) numel(dir(fullfile(pth,'*.png'))) ,fullfile(bottomdirs,'ProcessedImages'));
masks.hasImsMsk   = logical(numBscans >= 1);

masks.has192Msk   = numBscans > 185 & numBscans < 195;

%Strip out the topdir from the full list
dirlist = cellfun(@(aux) strrep(aux,topdir,''),bottomdirs,'uniformoutput',false);

%Get directores ready to process a specific test
todoDirs.convert     = dirlist(masks.hasRawMsk & ~masks.hasImsMsk);
todoDirs.register    = dirlist(masks.hasImsMsk & ~masks.hasRegMsk);
todoDirs.segment     = dirlist(masks.hasRegMsk & ~masks.hasSegmentationMsk);
todoDirs.postProc    = dirlist(masks.hasFrsMsk & ~masks.hasPosMsk);
todoDirs.compFigs    = dirlist(masks.hasPosMsk & ~masks.hasFigMsk);
todoDirs.compDCT     = dirlist(masks.hasFigMsk & ~masks.hasDCTMsk);
todoDirs.compORM     = dirlist(masks.hasDCTMsk & ~masks.hasORMsk);
todoDirs.compMap     = dirlist(masks.hasSegmentationMsk & ~masks.hasMapMsk);
todoDirs.compMov     = dirlist(masks.hasMapMsk & ~masks.hasMovMsk);
todoDirs.compAnot    = dirlist(masks.hasMovMsk & ~masks.hasAnotMsk);
todoDirs.compBscans  = dirlist(masks.hasMapMsk & ~masks.hasbScansMsk);

hasDirs.All         = dirlist;
hasDirs.RawIm       = dirlist(masks.hasImsMsk);
hasDirs.Imags       = dirlist(masks.hasImsMsk);
hasDirs.Regis       = dirlist(masks.hasRegMsk);
hasDirs.Segmentation = dirlist(masks.hasSegmentationMsk);
hasDirs.Anot        = dirlist(masks.hasAnotMsk);
hasDirs.Skipped     = dirlist(masks.hasSkipMsk);
hasDirs.bScans      = dirlist(masks.hasbScansMsk);

hasDirs.Err         = dirlist(masks.hasErrMsk);
hasDirs.Map         = dirlist(masks.hasMapMsk);
hasDirs.Mov         = dirlist(masks.hasMovMsk);
hasDirs.m192        = dirlist(masks.has192Msk);

% save(fullfile(topdir,'share','SpectralisData','javier','code','allDirectories.mat'),'dirlist','todoDirs','hasDirs');
% save(fullfile(topdir,'share','SpectralisData','javier','code','allDirectories.mat'),'dirlist','todoDirs','hasDirs','examDates');

end

function res = isAnnotated(fname)

res = false;

if ~exist(fname,'file')
    return
end

load(fname,'annotations');

if ~isfield(annotations,'skip')
    return
end

if ~annotations.skip && (~isfield(annotations,'maculaCenter') || ~isfield(annotations,'onhCenter'))
    return
end

res = true;

end

function res = isSkipped(fname)

res = false;

if ~exist(fname,'file')
    return
end

load(fname,'annotations');

if ~isfield(annotations,'skip')
    return
end

res = logical(annotations.skip);

end