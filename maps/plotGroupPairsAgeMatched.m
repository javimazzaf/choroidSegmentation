function plotGroupPairsAgeMatched(dr,group1,group2)

rng('default');

load(fullfile(dr,'mapData.mat'),'descriptors')

% allConditions = unique(descriptors.Group(:));

mskGroup1 = ismember(descriptors.Group(:),group1);
mskGroup2 = ismember(descriptors.Group(:),group2);

descriptors1 = descriptors(mskGroup1,:);
descriptors2 = descriptors(mskGroup2,:);

[desc1,desc2, ages] = ageMatch(descriptors1,descriptors2);

% Mean thickness
% makePairedFigure([desc1.meanthick(:);desc2.meanthick(:)],[desc1.Group(:);desc2.Group(:)],group1,group2,'meanThickness','mean Thickness [\mum]',dr)
% title(['N = ' num2str(size(desc1,1)) ' - Age1=' num2str(ages.set1.mean,'%2.0f') '(' num2str(ages.set1.std,'%2.0f') ') - Age2=' num2str(ages.set2.mean,'%2.0f') '(' num2str(ages.set2.std,'%2.0f') ')'])

% Ratio Choroid to retina thickness
% makePairedFigure([desc1.ratioChoroidToRetina(:);desc2.ratioChoroidToRetina(:)],[desc1.Group(:);desc2.Group(:)],group1,group2,'ratioChoroidToRetina','T_{Choroid} / T_{Retina}',dr)
% title(['N = ' num2str(size(desc1,1)) ' - Age1=' num2str(ages.set1.mean,'%2.0f') '(' num2str(ages.set1.std,'%2.0f') ') - Age2=' num2str(ages.set2.mean,'%2.0f') '(' num2str(ages.set2.std,'%2.0f') ')'])

% Std thickness
% makePairedFigure([desc1.stdthick(:);desc2.stdthick(:)],[desc1.Group(:);desc2.Group(:)],group1,group2,'SD','SD [\mum]',dr)
% title(['N = ' num2str(size(desc1,1)) ' - Age1=' num2str(ages.set1.mean,'%2.0f') '(' num2str(ages.set1.std,'%2.0f') ') - Age2=' num2str(ages.set2.mean,'%2.0f') '(' num2str(ages.set2.std,'%2.0f') ')'])

% Q5 thickness
% makePairedFigure([desc1.q5thick(:);desc2.q5thick(:)],[desc1.Group(:);desc2.Group(:)],group1,group2,'q5thick','Q5 [\mum]',dr)
% title(['N = ' num2str(size(desc1,1)) ' - Age1=' num2str(ages.set1.mean,'%2.0f') '(' num2str(ages.set1.std,'%2.0f') ') - Age2=' num2str(ages.set2.mean,'%2.0f') '(' num2str(ages.set2.std,'%2.0f') ')'])

% Q95 thickness
% makePairedFigure([desc1.q95thick(:);desc2.q95thick(:)],[desc1.Group(:);desc2.Group(:)],group1,group2,'Q95','Q95 [\mum]',dr)
% title(['N = ' num2str(size(desc1,1)) ' - Age1=' num2str(ages.set1.mean,'%2.0f') '(' num2str(ages.set1.std,'%2.0f') ') - Age2=' num2str(ages.set2.mean,'%2.0f') '(' num2str(ages.set2.std,'%2.0f') ')'])

% polar angle of plane fit
% makePairedFigure(90 - [desc1.polar(:);desc2.polar(:)],[desc1.Group(:);desc2.Group(:)],group1,group2,'polarAngle','PolarAngle [deg]',dr)
% title(['N = ' num2str(size(desc1,1)) ' - Age1=' num2str(ages.set1.mean,'%2.0f') '(' num2str(ages.set1.std,'%2.0f') ') - Age2=' num2str(ages.set2.mean,'%2.0f') '(' num2str(ages.set2.std,'%2.0f') ')'])



end

function makePairedFigure(values,groups,grName1,grName2,paramName,yLabel,dr)

hf = figure;
boxplot(values,groups,'notch','on','labels',{grName1;grName2},'labelorientation', 'inline')
set(gca,'FontSize',16)
ylabel(yLabel)

print(hf,fullfile(dr,[paramName '_' grName1 '-' grName2 '.png']),'-dpng')

end
