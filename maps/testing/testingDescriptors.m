load('/Users/javimazzaf/Documents/work/proyectos/ophthalmology/choroidMaps/20160301/mapData.mat','descriptors')

descriptors.meanRetina = descriptors.meanthick(:) ./ descriptors.ratioChoroidToRetina(:);

% plot(descriptors.Age(:),descriptors.meanRetina(:),'ok')

groups = unique(descriptors.Group(:));

% groups = groups([3,4]);

ids = [];
desc = [];

for k = 1:numel(groups)
    
   
   mskGroup = ismember(descriptors.Group(:),groups{k}); 

   theseDesc = descriptors(mskGroup,:);
   
   desc      = [desc;theseDesc];
%    ids = [ids; k * ones(size(theseDesc.Age(:)))];  
   
%    if ~ismember(k,[3,4]), continue, end 
   
%    figure;
%    boxplot(theseDesc.meanRetina(:),'notch','on')
   
 
   
%    plot(theseDesc.Age(:),theseDesc.meanRetina(:),'o'), hold on
   
end

figure;
% boxplot(descriptors.meanRetina(:),descriptors.Group(:),'notch','on','labels',groups,'labelorientation', 'inline')

% descriptors = sortrows(descriptors,'Group');
boxplot(descriptors.meanRetina(:),descriptors.Group(:),'notch','on','labelorientation', 'inline')

figure;
% desc = sortrows(desc,'Group');
boxplot(desc.meanRetina(:),desc.Group(:),'notch','on','labelorientation', 'inline')

% figure;

% boxplot(desc.meanRetina(:),ids,'notch','on')
 
mskGroup1 = ismember(descriptors.Group(:),'Early AMD');
mskGroup2 = ismember(descriptors.Group(:),'Normal');

descriptors1 = descriptors(mskGroup1,:);
descriptors2 = descriptors(mskGroup2,:);

figure;
% plot(descriptors1.Age(:),descriptors1.ratioChoroidToRetina(:),'ok'), hold on
% plot(descriptors2.Age(:),descriptors2.ratioChoroidToRetina(:),'or')

% plot(descriptors1.Age(:),descriptors1.meanthick(:),'ok'), hold on
% plot(descriptors2.Age(:),descriptors2.meanthick(:),'or')


plot(descriptors1.Age(:),descriptors1.meanRetina(:),'ok'), hold on
plot(descriptors2.Age(:),descriptors2.meanRetina(:),'or')

% [desc1,desc2, ages] = ageMatch(descriptors1,descriptors2);

% % Mean thickness
% makePairedFigure([desc1.meanthick(:);desc2.meanthick(:)],[desc1.Group(:);desc2.Group(:)],group1,group2,'meanThickness','mean Thickness [\mum]',dr)
% title(['N = ' num2str(size(desc1,1)) ' - Age1=' num2str(ages.set1.mean,'%2.0f') '(' num2str(ages.set1.std,'%2.0f') ') - Age2=' num2str(ages.set2.mean,'%2.0f') '(' num2str(ages.set2.std,'%2.0f') ')'])

% Ratio Choroid to retina thickness
% makePairedFigure([desc1.ratioChoroidToRetina(:);desc2.ratioChoroidToRetina(:)],[desc1.Group(:);desc2.Group(:)],group1,group2,'ratioChoroidToRetina','T_{Choroid} / T_{Retina}',dr)
% title(['N = ' num2str(size(desc1,1)) ' - Age1=' num2str(ages.set1.mean,'%2.0f') '(' num2str(ages.set1.std,'%2.0f') ') - Age2=' num2str(ages.set2.mean,'%2.0f') '(' num2str(ages.set2.std,'%2.0f') ')'])
