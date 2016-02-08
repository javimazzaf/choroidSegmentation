function clearResults(dirlist)

if ispc
    dirlist = fullfile([filesep filesep 'HMR-BRAIN'],dirlist);
elseif ismac
    dirlist = fullfile([filesep 'Volumes'],dirlist);
else
    dirlist = fullfile(filesep,'srv','samba',dirlist);
end

delDirs = fullfile(dirlist,'Results');

for k = 1:numel(delDirs)
    folder = delDirs{k};
    
    disp(['Deleting ' folder])
    
    rmdir(folder,'s')
end

end