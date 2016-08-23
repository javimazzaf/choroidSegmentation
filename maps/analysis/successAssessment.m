function successAssessment

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

[~, has, numBscans, masks] = getDirectories(topdir,groups,studies,reproducibility);

end