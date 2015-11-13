% Select directories that are ready for each particular step of the
% processing, or that have specific information
function [todoDirs, hasDirs, numBscans] = getDirectories(topdir,groups,studies,reprod)

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

% Get masks for  directories that are on a specific step of the processing
hasRawMsk   = logical(cellfun(@(aux) exist(aux,'dir'), fullfile(bottomdirs,'Raw Images')));
hasRegMsk   = logical(cellfun(@(aux) exist(aux,'file'),fullfile(bottomdirs,'Data Files','RegisteredImages.mat')));
hasFrsMsk   = logical(cellfun(@(aux) exist(aux,'file'),fullfile(bottomdirs,'Results',   'FirstProcessData.mat')));
hasFrsMapNewMsk   = logical(cellfun(@(aux) exist(aux,'file'),fullfile(bottomdirs,'Results',   'FirstProcessDataNew.mat')));
hasPosMsk   = logical(cellfun(@(aux) exist(aux,'file'),fullfile(bottomdirs,'Results',   'PostProcessData.mat')));
hasFigMsk   = logical(cellfun(@(pth) ~isempty(dir(fullfile(pth,'*.fig'))) ,fullfile(bottomdirs,'Results')));
hasDCTMsk   = logical(cellfun(@(aux) exist(aux,'file'),fullfile(bottomdirs,'Results',   'DeltaCT.mat')));
hasORMsk    = logical(cellfun(@(aux) exist(aux,'file'),fullfile(bottomdirs,'Results','Results.mat')));
hasMapMsk   = logical(cellfun(@(aux) exist(aux,'file'),fullfile(bottomdirs,'Results','ChoroidMap.mat')));
hasMovMsk   = logical(cellfun(@(aux) exist(aux,'file'),fullfile(bottomdirs,'Results','MapMovie.gif')));
hasErrMsk   = logical(cellfun(@(aux) exist(aux,'dir') ,fullfile(bottomdirs,'Error Folder')));

numBscans   = cellfun(@(pth) numel(dir(fullfile(pth,'*.png'))) ,fullfile(bottomdirs,'Processed Images'));
hasImsMsk   = logical(numBscans >= 1);

has192Msk   = numBscans > 185 & numBscans < 195;

%Strip out the topdir from the full list
dirlist = cellfun(@(aux) strrep(aux,topdir,''),bottomdirs,'uniformoutput',false);

%Get directores ready to process a specific test
todoDirs.convert   = dirlist(hasRawMsk & ~hasImsMsk);
todoDirs.register  = dirlist(hasImsMsk & ~hasRegMsk);
todoDirs.firstProc = dirlist(hasRegMsk & ~hasFrsMsk);
todoDirs.firstMapNew = dirlist(hasRegMsk & ~hasFrsMapNewMsk);
todoDirs.postProc  = dirlist(hasFrsMsk & ~hasPosMsk);
todoDirs.compFigs  = dirlist(hasPosMsk & ~hasFigMsk);
todoDirs.compDCT   = dirlist(hasFigMsk & ~hasDCTMsk);
todoDirs.compORM   = dirlist(hasDCTMsk & ~hasORMsk);
todoDirs.compMap   = dirlist(hasFrsMsk & ~hasMapMsk);
todoDirs.compMov   = dirlist(hasMapMsk & ~hasMovMsk);

hasDirs.All   = dirlist;
hasDirs.RawIm = dirlist(hasImsMsk);
hasDirs.Imags = dirlist(hasImsMsk);
hasDirs.Regis = dirlist(hasRegMsk);
hasDirs.First = dirlist(hasFrsMsk);
hasDirs.FirstMapNew = dirlist(hasFrsMapNewMsk);
hasDirs.Post  = dirlist(hasPosMsk);
hasDirs.Figs  = dirlist(hasFigMsk);
hasDirs.DCT   = dirlist(hasDCTMsk);
hasDirs.OR    = dirlist(hasORMsk);
hasDirs.Err   = dirlist(hasErrMsk);
hasDirs.Map   = dirlist(hasMapMsk);
hasDirs.Mov   = dirlist(hasMovMsk);
hasDirs.m192  = dirlist(has192Msk);

save(fullfile(topdir,'share','SpectralisData','javier','code','allDirectories.mat'),'dirlist','todoDirs','hasDirs');

end