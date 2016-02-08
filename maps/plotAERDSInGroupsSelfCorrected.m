function plotAERDSInGroupsSelfCorrected(dr)
% Make boxplots of AERDS sectors thickness correcting the age by fitting
% each specific dataset against age.

load(fullfile(dr,'mapData.mat'),'descriptors')

allConditions = unique(descriptors.Group(:));

populations = cellfun(@(x) sum(strcmp(descriptors.Group(:),x)), allConditions);

mskCond   = (populations > 10) & ~ismember(allConditions,'Other/No Group');
conditions  = allConditions(mskCond);

mskData = ismember(descriptors.Group(:),conditions) & ~ismember(descriptors.Group(:),'Other/No Group');

data = descriptors(mskData,:);

minN    = 20;
pThresh = 0.05;
minAge  = min(data.Age(:));

% AREDS_D1 thickness
msk           = data.AREDS_D1N(:) >= minN;
sectorData    = data.AREDS_D1Mean(msk);
ageCorrection = compAgeCorrection(sectorData,data.Age(msk),minAge,pThresh);

hf = figure;
boxplot(sectorData + ageCorrection,data.Group(msk),'notch','on','labels',conditions,'labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('AREDS_D1SelfCorr Mean [\mum]')
print(hf,fullfile(dr,'corrConfSelfAREDS_D1Mean.png'),'-dpng')

% AREDS_D3nasal thickness
msk           = data.AREDS_D3nasalN(:) >= minN;
sectorData    = data.AREDS_D3nasalMean(msk);
ageCorrection = compAgeCorrection(sectorData,data.Age(msk),minAge,pThresh);

hf = figure;
boxplot(sectorData + ageCorrection,data.Group(msk),'notch','on','labels',conditions,'labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('AREDS_D3nasalSelfCorr Mean [\mum]')
print(hf,fullfile(dr,'corrConfSelfAREDS_D3nasalMean.png'),'-dpng')

% AREDS_D3inferiorMean thickness
msk           = data.AREDS_D3inferiorN(:) >= minN;
sectorData    = data.AREDS_D3inferiorMean(msk);
ageCorrection = compAgeCorrection(sectorData,data.Age(msk),minAge,pThresh);

hf = figure;
boxplot(sectorData + ageCorrection,data.Group(msk),'notch','on','labels',conditions,'labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('AREDS_D3inferiorSelfCorr Mean [\mum]')
print(hf,fullfile(dr,'corrConfSelfAREDS_D3inferiorMean.png'),'-dpng')

% AREDS_D3temporalMean thickness
msk           = data.AREDS_D3temporalN(:) >= minN;
sectorData    = data.AREDS_D3temporalMean(msk);
ageCorrection = compAgeCorrection(sectorData,data.Age(msk),minAge,pThresh);

hf = figure;
boxplot(sectorData + ageCorrection,data.Group(msk),'notch','on','labels',conditions,'labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('AREDS_D3temporalSelfCorr Mean [\mum]')
print(hf,fullfile(dr,'corrConfSelfAREDS_D3temporalMean.png'),'-dpng')

% AREDS_D3superiorMean thickness
msk           = data.AREDS_D3superiorN(:) >= minN;
sectorData    = data.AREDS_D3superiorMean(msk);
ageCorrection = compAgeCorrection(sectorData,data.Age(msk),minAge,pThresh);

hf = figure;
boxplot(sectorData + ageCorrection,data.Group(msk),'notch','on','labels',conditions,'labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('AREDS_D3superiorSelfCorr Mean [\mum]')
print(hf,fullfile(dr,'corrConfSelfAREDS_D3superiorMean.png'),'-dpng')

% AREDS_D6nasalMean thickness
msk           = data.AREDS_D6nasalN(:) >= minN;
sectorData    = data.AREDS_D6nasalMean(msk);
ageCorrection = compAgeCorrection(sectorData,data.Age(msk),minAge,pThresh);

hf = figure;
boxplot(sectorData + ageCorrection,data.Group(msk),'notch','on','labels',conditions,'labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('AREDS_D6nasalSelfCorr Mean [\mum]')
print(hf,fullfile(dr,'corrConfSelfAREDS_D6nasalMean.png'),'-dpng')

% AREDS_D6inferiorMean thickness
msk           = data.AREDS_D6inferiorN(:) >= minN;
sectorData    = data.AREDS_D6inferiorMean(msk);
ageCorrection = compAgeCorrection(sectorData,data.Age(msk),minAge,pThresh);

hf = figure;
boxplot(sectorData + ageCorrection,data.Group(msk),'notch','on','labels',conditions,'labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('AREDS_D6inferiorSelfCorr Mean [\mum]')
print(hf,fullfile(dr,'corrConfSelfAREDS_D6inferiorMean.png'),'-dpng')

% AREDS_D6temporalMean thickness
msk           = data.AREDS_D6temporalN(:) >= minN;
sectorData    = data.AREDS_D6temporalMean(msk);
ageCorrection = compAgeCorrection(sectorData,data.Age(msk),minAge,pThresh);

hf = figure;
boxplot(sectorData + ageCorrection,data.Group(msk),'notch','on','labels',conditions,'labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('AREDS_D6temporalSelfCorr Mean [\mum]')
print(hf,fullfile(dr,'corrConfSelfAREDS_D6temporalMean.png'),'-dpng')

% AREDS_D6superiorMean thickness
msk           = data.AREDS_D6superiorN(:) >= minN;
sectorData    = data.AREDS_D6superiorMean(msk);
ageCorrection = compAgeCorrection(sectorData,data.Age(msk),minAge,pThresh);

hf = figure;
boxplot(sectorData + ageCorrection,data.Group(msk),'notch','on','labels',conditions,'labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('AREDS_D6superiorSelfCorr Mean [\mum]')
print(hf,fullfile(dr,'corrConfSelfAREDS_D6superiorMean.png'),'-dpng')

end

% Computes the correction for Age, if there is any
function ageCorrection = compAgeCorrection(thick,Age,minAge,pThresh)

[~, pval] = corr(Age,thick);

if pval <= pThresh
    datafit = fit(Age,thick,'poly1');
    ageCorrection = (Age - minAge) * (-1) * datafit.p1;
else
    ageCorrection = 0;
end

end