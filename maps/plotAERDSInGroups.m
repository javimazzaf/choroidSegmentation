function plotAERDSInGroups(dr)

load(fullfile(dr,'mapData.mat'),'descriptors')

allConditions = unique(descriptors.Group(:));

populations = cellfun(@(x) sum(strcmp(descriptors.Group(:),x)), allConditions);

mskCond   = (populations > 10) & ~ismember(allConditions,'Other/No Group');
conditions  = allConditions(mskCond);

mskData = ismember(descriptors.Group(:),conditions) & ~ismember(descriptors.Group(:),'Other/No Group');

data = descriptors(mskData,:);

minAge = min(data.Age(:));
ageCorrection = zeros(size(data.Age(:)));
% ageCorrection = (data.Age(:) - minAge) * 1.462;

minN = 20;

% AREDS_D1 thickness
hf = figure;
msk = data.AREDS_D1N(:) >= minN;
boxplot(data.AREDS_D1Mean(msk) + ageCorrection(msk),data.Group(msk),'notch','on','labels',conditions,'labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('AREDS_D1 Mean [\mum]')
print(hf,fullfile(dr,'AREDS_D1Mean.png'),'-dpng')
% print(hf,fullfile(dr,'corrAREDS_D1Mean.png'),'-dpng')
% print(hf,fullfile(dr,'corrConfAREDS_D1Mean.png'),'-dpng')

% AREDS_D3nasal thickness
hf = figure;
msk = data.AREDS_D3nasalN(:) >= minN;
boxplot(data.AREDS_D3nasalMean(msk) + ageCorrection(msk),data.Group(msk),'notch','on','labels',conditions,'labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('AREDS_D3nasal Mean [\mum]')
print(hf,fullfile(dr,'AREDS_D3nasalMean.png'),'-dpng')
% print(hf,fullfile(dr,'corrAREDS_D3nasalMean.png'),'-dpng')
% print(hf,fullfile(dr,'corrConfAREDS_D3nasalMean.png'),'-dpng')

% AREDS_D3inferiorMean thickness
hf = figure;
msk = data.AREDS_D3inferiorN(:) >= minN;
boxplot(data.AREDS_D3inferiorMean(msk) + ageCorrection(msk),data.Group(msk),'notch','on','labels',conditions,'labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('AREDS_D3inferior Mean [\mum]')
print(hf,fullfile(dr,'AREDS_D3inferiorMean.png'),'-dpng')
% print(hf,fullfile(dr,'corrAREDS_D3inferiorMean.png'),'-dpng')
% print(hf,fullfile(dr,'corrConfAREDS_D3inferiorMean.png'),'-dpng')

% AREDS_D3temporalMean thickness
hf = figure;
msk = data.AREDS_D3temporalN(:) >= minN;
boxplot(data.AREDS_D3temporalMean(msk) + ageCorrection(msk),data.Group(msk),'notch','on','labels',conditions,'labelorientation', 'inline')
% boxplot(data.AREDS_D3temporalMean(:) + ageCorrection,data.Group(:),'notch','on','labels',conditions,'labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('AREDS_D3temporal Mean [\mum]')
print(hf,fullfile(dr,'AREDS_D3temporalMean.png'),'-dpng')
% print(hf,fullfile(dr,'corrAREDS_D3temporalMean.png'),'-dpng')
% print(hf,fullfile(dr,'corrConfAREDS_D3temporalMean.png'),'-dpng')

% AREDS_D3superiorMean thickness
hf = figure;
msk = data.AREDS_D3superiorN(:) >= minN;
boxplot(data.AREDS_D3superiorMean(msk) + ageCorrection(msk),data.Group(msk),'notch','on','labels',conditions,'labelorientation', 'inline')
% boxplot(data.AREDS_D3superiorMean(:) + ageCorrection,data.Group(:),'notch','on','labels',conditions,'labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('AREDS_D3superior Mean [\mum]')
print(hf,fullfile(dr,'AREDS_D3superiorMean.png'),'-dpng')
% print(hf,fullfile(dr,'corrAREDS_D3superiorMean.png'),'-dpng')
% print(hf,fullfile(dr,'corrConfAREDS_D3superiorMean.png'),'-dpng')

% AREDS_D6nasalMean thickness
hf = figure;
msk = data.AREDS_D6nasalN(:) >= minN;
boxplot(data.AREDS_D6nasalMean(msk) + ageCorrection(msk),data.Group(msk),'notch','on','labels',conditions,'labelorientation', 'inline')
% boxplot(data.AREDS_D6nasalMean(:) + ageCorrection,data.Group(:),'notch','on','labels',conditions,'labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('AREDS_D6nasal Mean [\mum]')
print(hf,fullfile(dr,'AREDS_D6nasalMean.png'),'-dpng')
% print(hf,fullfile(dr,'corrAREDS_D6nasalMean.png'),'-dpng')
% print(hf,fullfile(dr,'corrConfAREDS_D6nasalMean.png'),'-dpng')

% AREDS_D6inferiorMean thickness
hf = figure;
msk = data.AREDS_D6inferiorN(:) >= minN;
boxplot(data.AREDS_D6inferiorMean(msk) + ageCorrection(msk),data.Group(msk),'notch','on','labels',conditions,'labelorientation', 'inline')
% boxplot(data.AREDS_D6inferiorMean(:) + ageCorrection,data.Group(:),'notch','on','labels',conditions,'labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('AREDS_D6inferior Mean [\mum]')
print(hf,fullfile(dr,'AREDS_D6inferiorMean.png'),'-dpng')
% print(hf,fullfile(dr,'corrAREDS_D6inferiorMean.png'),'-dpng')
% print(hf,fullfile(dr,'corrConfAREDS_D6inferiorMean.png'),'-dpng')

% AREDS_D6temporalMean thickness
hf = figure;
msk = data.AREDS_D6temporalN(:) >= minN;
boxplot(data.AREDS_D6temporalMean(msk) + ageCorrection(msk),data.Group(msk),'notch','on','labels',conditions,'labelorientation', 'inline')
% boxplot(data.AREDS_D6temporalMean(:) + ageCorrection,data.Group(:),'notch','on','labels',conditions,'labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('AREDS_D6temporal Mean [\mum]')
print(hf,fullfile(dr,'AREDS_D6temporalMean.png'),'-dpng')
% print(hf,fullfile(dr,'corrAREDS_D6temporalMean.png'),'-dpng')
% print(hf,fullfile(dr,'corrConfAREDS_D6temporalMean.png'),'-dpng')

% AREDS_D6superiorMean thickness
hf = figure;
msk = data.AREDS_D6superiorN(:) >= minN;
boxplot(data.AREDS_D6superiorMean(msk) + ageCorrection(msk),data.Group(msk),'notch','on','labels',conditions,'labelorientation', 'inline')
% boxplot(data.AREDS_D6superiorMean(:) + ageCorrection,data.Group(:),'notch','on','labels',conditions,'labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('AREDS_D6superior Mean [\mum]')
print(hf,fullfile(dr,'AREDS_D6superiorMean.png'),'-dpng')
% print(hf,fullfile(dr,'corrAREDS_D6superiorMean.png'),'-dpng')
% print(hf,fullfile(dr,'corrConfAREDS_D6superiorMean.png'),'-dpng')

end