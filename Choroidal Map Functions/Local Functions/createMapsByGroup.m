function createMapsByGroup(dr)

load(fullfile(dr,'mapData.mat'),'descriptors')

allConditions = unique(descriptors.Group(:));

populations = cellfun(@(x) sum(strcmp(descriptors.Group(:),x)), allConditions);

mskCond   = (populations > 10) & ~ismember(allConditions,'Other/No Group');
conditions  = allConditions(mskCond);

mskData = ismember(descriptors.Group(:),conditions) & ~ismember(descriptors.Group(:),'Other/No Group');
data = descriptors(mskData,:);



end