function listToolboxDependencies(baseDir)

folders = genpath(baseDir);

folders = regexp(folders,['[^' pathsep ']*'],'match')';

% Get rid of git files
msk = logical(cellfun(@isempty,strfind(folders,'./.git')));
folders = folders(msk);

mfileList = {};

for k=1:numel(folders)
    fls = dir(fullfile(folders{k},'*.m'));
    fnames = fullfile(folders{k},{fls(:).name});
    mfileList = [mfileList fnames];
end

[flist,pList] = matlab.codetools.requiredFilesAndProducts(mfileList);

for k = 1:numel(pList)
    disp(['Product name: ' pList(k).Name ' | Version: ' pList(k).Version ' | Product number: ' num2str(pList(k).ProductNumber)])
end

end
