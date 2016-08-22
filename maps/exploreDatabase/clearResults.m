function clearResults(dirlist)

%Removes all files from the Results folder in each directory in dirlist

if ispc
    dirlist = fullfile([filesep filesep 'HMR-BRAIN'],dirlist);
elseif ismac
    dirlist = fullfile([filesep 'Volumes'],dirlist);
else
    dirlist = fullfile(filesep,'srv','samba',dirlist);
end

for k = 1:numel(dirlist)
    if exist(fullfile(dirlist{k},'Results'),'dir')
        try
            if ~exist(fullfile(dirlist{k},'Results'),'dir')
                disp(['Skipping: ' fullfile(dirlist{k},'Results')])
            end
            
            rmdir(fullfile(dirlist{k},'Results'),'s')
            disp(['Removing: ' fullfile(dirlist{k},'Results')])
        catch
            disp('skipped')
        end
    end
end


end