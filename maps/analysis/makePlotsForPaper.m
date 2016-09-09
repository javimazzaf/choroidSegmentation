function makePlotsForPaper

conds = [];

dr = '/Users/javimazzaf/Documents/work/proyectos/ophthalmology/choroidMaps/20160830/';

load(fullfile(dr,'mapData.mat'),'descriptors')

descriptors = regroupConditions(descriptors);

allConditions = unique(descriptors.Group(:));

populations = cellfun(@(x) sum(ismember(descriptors.Group(:),x)), allConditions);

mskCond     = (populations >= 5);%  & ~ismember(allConditions,'Other/No Group');

if ~isempty(conds)
    mskCond     = mskCond & ismember(allConditions,conds);
end

conditions  = allConditions(mskCond);

mskData = ismember(descriptors.Group(:),conditions);

data = descriptors(mskData,:);
data = sortrows(data,'Group');

% Mean thickness Normal-Uveitis
mskNormUve = ismember(data.Group(:),{'Normal','Uveitis'});
hf = figure;
boxplot(data.meanthick(mskNormUve),data.Group(mskNormUve),'notch','on','labelorientation', 'inline','symbol','')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('mean Thickness [\mum]')
print(hf,fullfile(dr,'meanThicknessNormalUveitis.pdf'),'-dpdf')


%% Quadrant analyzes
Nlim = 100;

ns = data.nasalSuperiorMean(:);
ns(data.nasalSuperiorN(:) < Nlim) = NaN;

ni = data.nasalInferiorMean(:);
ni(data.nasalInferiorN(:) < Nlim) = NaN;

ts = data.temporalSuperiorMean(:);
ts(data.temporalSuperiorN(:) < Nlim) = NaN;

ti = data.temporalInferiorMean(:);
ti(data.temporalInferiorN(:) < Nlim) = NaN;

nasal = data.nasalMean(:);
nasal(data.nasalN(:) < Nlim) = NaN;

temporal = data.temporalMean(:);
temporal(data.temporalN(:) < Nlim) = NaN;

superior = data.superiorMean(:);
superior(data.superiorN(:) < Nlim) = NaN;

inferior = data.inferiorMean(:);
inferior(data.inferiorN(:) < Nlim) = NaN;

% nasal Temporal Contrast
nasalTemporalContrast    = (nasal - temporal)    ./ (nasal + temporal);
msk = ~isnan(nasalTemporalContrast);

hf = figure;
boxplot(nasalTemporalContrast(msk),'symbol','','notch','on')
% hist(nasalTemporalContrast(msk))
set(gca,'FontSize',14)
ylabel('nasalTemporalContrast')
print(hf,fullfile(dr,'nasalTemporalContrast.pdf'),'-dpdf')
close(hf)

% Superior Inferior Contrast
SuperiorInferiorContrast = (superior - inferior) ./ (superior + inferior);
msk = ~isnan(SuperiorInferiorContrast);

hf = figure;
% boxplot(SuperiorInferiorContrast(msk),data.Group(msk),'notch','on','labelorientation', 'inline')
boxplot(SuperiorInferiorContrast(msk),'symbol','','notch','on')
% hist(SuperiorInferiorContrast(msk))
set(gca,'FontSize',14)
ylabel('SuperiorInferiorContrast')
print(hf,fullfile(dr,'SuperiorInferiorContrast.pdf'),'-dpdf')
close(hf)

% NasalSuperior TemporalInferior Contrast
NsTiContrast = (ns - ti) ./ (ns + ti);
msk = ~isnan(NsTiContrast);

hf = figure;
boxplot(NsTiContrast(msk),'symbol','','notch','on')
set(gca,'FontSize',14)
ylabel('NsTiContrast')
view(90,90)
yl = ylim();
print(hf,fullfile(dr,'NsTiContrastBoxPlot.pdf'),'-dpdf')

hf = figure;
hist(NsTiContrast(msk))
set(gca,'FontSize',14)
xlabel('NsTiContrast')
xlim(yl)
print(hf,fullfile(dr,'NsTiContrastHistogram.pdf'),'-dpdf')

% NasalInferior TemporalSuperior Contrast
NiTsContrast = (ni - ts) ./ (ni + ts);
msk = ~isnan(NiTsContrast);

hf = figure;
boxplot(NiTsContrast(msk),'symbol','','notch','on')
set(gca,'FontSize',14)
ylabel('NiTsContrast')
view(90,90)
yl = ylim();
print(hf,fullfile(dr,'NiTsContrastBoxPlot.pdf'),'-dpdf')

hf = figure;
hist(NiTsContrast(msk))
set(gca,'FontSize',14)
xlabel('NiTsContrast')
xlim(yl)
print(hf,fullfile(dr,'NiTsContrastHistogram.pdf'),'-dpdf')


% polar angle of plane fit
hf = figure;
boxplot(90-data.polar(:),'symbol','','notch','on')
ylabel('polar angle [deg]')
view(90,90)
yl = ylim();
title('Polar angle')
print(hf,fullfile(dr,'polarBoxPlot.pdf'),'-dpdf')

hf = figure;
hist(90-data.polar(:))
xlabel('polar angle [deg]')
title('Polar angle')
xlim(yl)
print(hf,fullfile(dr,'polarHistogram.pdf'),'-dpdf')

% Correlation Choroid Thickness and Age
[slope,R2,pVal,hf] = corrFigureMaker(data.Age(:),data.meanthick(:));
print(hf,fullfile(dr,'correlMeanThcknessVsAge.pdf'),'-dpdf')
writetable(array2table([slope,R2,pVal],'VariableNames',{'slope','R2','pVal'}),fullfile(dr,'correlMeanThcknessVsAge.txt'));

% Azimuth angle cumulative histogram
hf = figure;

edges = 0:15:360;
x = [0:30:330, 0];

angs = mod(data.azimuth(:) + 360, 360);

h = histcounts(angs,edges);

h = [h(1)+h(end), h(2:2:end-1) + h(3:2:end-1)];

h = h / sum(h);

hs = [h h(1)];

polar(x/180*pi,hs,'-ob')

set(gca,'FontSize',14)
print(hf,fullfile(dr,'AzimHistPolar.pdf'),'-dpdf')


end

function descriptors = regroupConditions(descriptors)



% Regroup conditions to bigger groups: 'Normal';'AMD';'OAG';'Uveitis';'Other'};
allGroups = descriptors{:,'Group'};

allGroups(ismember(allGroups,'Bleb'))        = repmat({'OAG'},sum(ismember(allGroups,'Bleb')),1);
allGroups(ismember(allGroups,'OAG Precoce')) = repmat({'OAG'},sum(ismember(allGroups,'OAG Precoce')),1);
allGroups(ismember(allGroups,'OAG Suspect')) = repmat({'OAG'},sum(ismember(allGroups,'OAG Suspect')),1);
allGroups(ismember(allGroups,'OHT'))         = repmat({'OAG'},sum(ismember(allGroups,'OHT')),1);

allGroups(ismember(allGroups,'Early AMD')) = repmat({'AMD'},sum(ismember(allGroups,'Early AMD')),1);
allGroups(ismember(allGroups,'Wet AMD'))   = repmat({'AMD'},sum(ismember(allGroups,'Wet AMD')),1);

allGroups(ismember(allGroups,'Geographic Atrophy')) = repmat({'Other/No Group'},sum(ismember(allGroups,'Geographic Atrophy')),1);

descriptors{:,'Group'} = allGroups;

end