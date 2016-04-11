function creatFundusSet(dirlist, targetDir)

if ispc
    dname = [filesep filesep 'HMR-BRAIN'];
elseif ismac
    dname = [filesep 'Volumes'];
else
    dname = [filesep,'srv',filesep,'samba'];
end

targetDir = fullfile(dname,'share','SpectralisData',targetDir);

if ~exist(targetDir,'dir'), mkdir(targetDir); end

for k = 1:numel(dirlist)
    
    thisDir = dirlist{k};
    
    load(fullfile(dname,thisDir,'Data Files','ImageList.mat'),'fundim');
    
    fname = encodeString(strrep(thisDir,'share/SpectralisData/Patients/',''));
    
    targetName = [targetDir filesep fname '.png'];
%     targetName = [fname '.png'];
    
    imwrite(fundim,targetName);
    
    disp([num2str(k) ' of ' num2str(numel(dirlist))])
    
end

end

function fname = encodeString(fname)
    fname = strrep(fname, filesep, '_');
    fname = strrep(fname, ',', '#');
    fname = strrep(fname, ' ', '%');
end