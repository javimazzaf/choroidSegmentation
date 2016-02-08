function tab = makeResultsTable(dirs)

% It generates a table combining visit data and results, for the
% measurments listed in dirs.
% To use it:
%    outputTable = makeResultsTable(has.Valid);
% has.Valid can be replace by any other cell array with directories

% Javier Mazzaferri
% javier.mazzaferri@gmail.com
% 2015DEC03

if ispc       
    dataBaseDir = [filesep filesep 'HMR-BRAIN'];
elseif ismac
    dataBaseDir = [filesep 'Volumes'];
else
    dataBaseDir = [filesep 'srv' filesep 'samba'];
end

dirList    = fullfile(dataBaseDir,dirs);

tab = [];

for k = 1:numel(dirList)
    thisDir = dirList{k};
    
    visitFile = fullfile(thisDir,'Data Files','VisitData.mat');
    resFile   = fullfile(thisDir,'Results','Results.mat');
    
    % If either the visit data or the results are mising, it skips the
    % directory
    if ~exist(visitFile,'file') || ~exist(resFile,'file'), continue, end
    
    load(visitFile,'visitdata');
    
    % Remove "Notes" column
    visitdata.Notes = [];
    
    % Check if the HR is in the table. Otherwise it computs from the heart
    % beat series
    if ~ismember('HR',visitdata.Properties.VariableNames)
       HR = GetHeartRate(thisDir);
       visitdata.HR = HR;
       visitdata = visitdata(:,[1:21,25,22:24]);
    end
    
    % Load Results
    load(resFile,'CT','dCT','dV','OR');
    
    visitdata.CT  = CT;
    visitdata.dCT = dCT;
    visitdata.dV  = dV;
    visitdata.OR  = OR;
    
    % Modifies AP columns to allow concatenation
    AP = visitdata.AP;
    visitdata.APmax = AP(:,1);
    visitdata.APmin = AP(:,2);
    visitdata.AP = [];
    
    % Reorder columns to place APmax and APmin nearby the old position of
    % AP
    visitdata = visitdata(:,[1:10,29,30,11:28]);
    
    % Concatenate data for different patients
    tab = [tab;visitdata];
    
end
    
end
