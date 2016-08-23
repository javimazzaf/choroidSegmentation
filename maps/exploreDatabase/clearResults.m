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
            rmdir(fullfile(dirlist{k},'Results'),'s')
            disp(['Removing: ' fullfile(dirlist{k},'Results')])
        catch
            disp('skipped')
        end
    end
    
%     if exist(fullfile(dirlist{k},'Data Files','RegisteredImages.mat'),'file')
%         
%     end

end


end