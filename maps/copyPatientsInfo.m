function copyPatientsInfo(drs, baseDestDir)

if ispc
    baseSrcdir = [filesep filesep 'HMR-BRAIN'];
elseif ismac
    baseSrcdir = [filesep 'Volumes'];
else
    baseSrcdir = fullfile(filesep,'srv','samba');
end

baseDestDir = fullfile(baseDestDir,'Patients');

if ~exist(baseDestDir,'dir'), mkdir(baseDestDir), end

for k = 1:numel(drs)
    
    sourceDir      = fullfile(baseSrcdir,drs{k},'Results');
    destinationDir = fullfile(baseDestDir,drs{k},'Results');
    
    if ~exist(destinationDir,'dir'), mkdir(destinationDir), end
    
%     copyfile(sourceDir,destinationDir,'f');
    
    eval(['!cp -R ''' sourceDir ''' ''' destinationDir ''''])
    
    disp(sourceDir);

end