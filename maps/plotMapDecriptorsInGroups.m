function plotMapDecriptorsInGroups(dr)

load(fullfile(dr,'mapData.mat'),'descriptors')

allConditions = unique(descriptors.Group(:));

populations = cellfun(@(x) sum(strcmp(descriptors.Group(:),x)), allConditions);

% mskCond   = (populations > 10) & ~ismember(allConditions,'Other/No Group');
mskCond     = (populations >= 5) & ~ismember(allConditions,'Other/No Group');
conditions  = allConditions(mskCond);
% populations = populations(mskCond);

mskData = ismember(descriptors.Group(:),conditions) & ~ismember(descriptors.Group(:),'Other/No Group');

data = descriptors(mskData,:);
data = sortrows(data,'Group');

% Populations
hf = figure;
bar(populations(mskCond))
set(gca,'XTickLabels',conditions)
ylabel('N patients')
print(hf,fullfile(dr,'populations.png'),'-dpng')

% Mean thickness
hf = figure;
boxplot(data.meanthick(:),data.Group(:),'notch','on','labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('mean Thickness [\mum]')
print(hf,fullfile(dr,'meanThickness.png'),'-dpng')

% % Mean thickness corrected for age
% hf = figure;
% meanThicknessCorrected = data.meanthick(:) + (data.Age(:) - min(data.Age(:))) * 1.462;
% boxplot(meanThicknessCorrected,data.Group(:),'notch','on','labelorientation', 'inline')
% set(gca,'FontSize',14)
% ylim([0, 400])
% ylabel('mean Thickness corrected for age [\mum]')
% print(hf,fullfile(dr,'meanThicknessCorrected.png'),'-dpng')

% % Min thickness
% hf = figure;
% boxplot(data.minthick(:),data.Group(:),'notch','on','labelorientation', 'inline')
% ylim([0, 150])
% ylabel('min Thickness [\mum]')
% print(hf,fullfile(dr,'minThickness.png'),'-dpng')
% 
% % Max thickness
% hf = figure;
% boxplot(data.maxthick(:),data.Group(:),'notch','on','labelorientation', 'inline')
% ylim([0, 700])
% ylabel('max Thickness [\mum]')
% print(hf,fullfile(dr,'maxThickness.png'),'-dpng')

% Std thickness
hf = figure;
boxplot(data.stdthick(:),data.Group(:),'notch','on','labelorientation', 'inline')
ylim([0, 100])
ylabel('std Thickness [\mum]')
print(hf,fullfile(dr,'stdThickness.png'),'-dpng')

% Q5 thickness
hf = figure;
boxplot(data.q5thick(:),data.Group(:),'notch','on','labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('P5 Thickness [\mum]')
print(hf,fullfile(dr,'P5Thickness.png'),'-dpng')

% Q95 thickness
hf = figure;
boxplot(data.q95thick(:),data.Group(:),'notch','on','labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 700])
ylabel('P95 Thickness [\mum]')
print(hf,fullfile(dr,'P95Thickness.png'),'-dpng')

%% Center Macula values

% Center Mean thickness
hf = figure;
boxplot(data.centerMean(:),data.Group(:),'notch','on','labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('center mean Thickness [\mum]')
print(hf,fullfile(dr,'centerMeanThickness.png'),'-dpng')

% Center Std thickness
hf = figure;
boxplot(data.centerStd(:),data.Group(:),'notch','on','labelorientation', 'inline')
ylim([0, 100])
ylabel('center std Thickness [\mum]')
print(hf,fullfile(dr,'centerStdThickness.png'),'-dpng')

% Center Q5 thickness
hf = figure;
boxplot(data.centerQ5(:),data.Group(:),'notch','on','labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 400])
ylabel('center P5 Thickness [\mum]')
print(hf,fullfile(dr,'centerP5Thickness.png'),'-dpng')

% Center Q95 thickness
hf = figure;
boxplot(data.centerQ95(:),data.Group(:),'notch','on','labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([0, 700])
ylabel('center P95 Thickness [\mum]')
print(hf,fullfile(dr,'centerP95Thickness.png'),'-dpng')

% % Q5 thickness Corrected
% hf = figure;
% q5ThicknessCorrected = data.q5thick(:) + (data.Age(:) - min(data.Age(:))) * 1.462;
% boxplot(q5ThicknessCorrected,data.Group(:),'notch','on','labelorientation', 'inline')
% set(gca,'FontSize',14)
% ylim([0, 400])
% ylabel('P5 Thickness corrected for age [\mum]')
% print(hf,fullfile(dr,'P5ThicknessCorrectedForAge.png'),'-dpng')
% 
% % Q95 thickness Corrected
% hf = figure;
% q95ThicknessCorrected = data.q95thick(:) + (data.Age(:) - min(data.Age(:))) * 1.462;
% boxplot(q95ThicknessCorrected,data.Group(:),'notch','on','labelorientation', 'inline')
% set(gca,'FontSize',14)
% ylim([0, 700])
% ylabel('P95 Thickness corrected for age [\mum]')
% print(hf,fullfile(dr,'P95ThicknessCorrectedForAge.png'),'-dpng')


% Ratio Choroid to retina thickness
hf = figure;
boxplot(data.ratioChoroidToRetina(:),data.Group(:),'notch','on','labelorientation', 'inline')
set(gca,'FontSize',14)
ylim([-0.1, 1.1])
ylabel('T_{Choroid} / T_{Retina}')
print(hf,fullfile(dr,'ratioChoroidToRetina.png'),'-dpng')

% Retina thickness
data.meanRetina = data.meanthick(:) ./ data.ratioChoroidToRetina(:);

hf = figure;
boxplot(data.meanRetina(:),data.Group(:),'notch','on','labelorientation', 'inline')
set(gca,'FontSize',14)
ylabel('mean retina[\mum]')
print(hf,fullfile(dr,'meanRetina.png'),'-dpng')

% % Polar angle of plane fit
% hf = figure;
% meanAzimuth = cellfun(@(x) atan2d(sum(sind(data.azimuth(ismember(data.Group(:),x)))),...
%                                   sum(cosd(data.azimuth(ismember(data.Group(:),x))))),...
%                       conditions);
% 
% bar(meanAzimuth)
% set(gca,'XTickLabels',conditions)
% ylabel('mean Azimuth')
% print(hf,fullfile(dr,'meanAzimuth.png','-dpng'))

% Azimuth angle of plane fit, in scatter plot
hf = figure;

sym = 'os^*x+v><';
clr     = 'rgbcmk';
for k = 1:numel(conditions)
    msk = ismember(data.Group(:),conditions{k});
    lns = [sym(mod(k,length(sym)) + 1) clr(mod(k,length(clr)) + 1)];
    polar(data.azimuth(msk)/180*pi,pi/2 - data.polar(msk)/180*pi,lns), hold on
end

% legend(conditions)
title('Azimuth Scatter')
print(hf,fullfile(dr,'scatterAzimuth.png'),'-dpng')

% % Histogram of azimuth of plane fit
% hf = figure;
% clr     = 'rgbcmk';
% 
% mxCounts = -Inf;
% mxInd    = 1;
% 
% for k = 1:numel(conditions)
%     msk = ismember(data.Group(:),conditions{k}); 
%     [counts, centers] = hist(data.azimuth(msk),[22.5:45:337.5]);
% 
%     counts = counts / sum(counts);
%     
%     thisMax = max(counts);
%     
%     if thisMax > mxCounts
%         mxCounts = thisMax;
%         mxInd = k;
%     end
% end
% 
% msk = ismember(data.Group(:),conditions{mxInd});
% lns = ['o-' clr(mod(mxInd,length(clr)) + 1)];
% [counts, centers] = hist(data.azimuth(msk),[22.5:45:337.5]);
% counts = counts / sum(counts);
% counts  = [counts counts(1)];
% centers = [centers centers(1)];
% polar(centers/180*pi,counts,lns), hold on
% 
% for k = setdiff(1:numel(conditions),mxInd)
%     msk = ismember(data.Group(:),conditions{k});
%     lns = ['o-' clr(mod(k,length(clr)) + 1)];
%     
%     [counts, centers] = hist(data.azimuth(msk),[22.5:45:337.5]);
%     
%     counts = counts / sum(counts);
%     
%     counts  = [counts counts(1)];
%     centers = [centers centers(1)];
%     
%     polar(centers/180*pi,counts,lns)
% end
% 
% legend(conditions)
% title('Azimuth Histogram')
% print(hf,fullfile(dr,'histogramAzimuth.png'),'-dpng')

% polar angle of plane fit
hf = figure;
boxplot(90-data.polar(:),data.Group(:),'notch','on','labelorientation', 'inline')
ylim([0, 3])
ylabel('polar angle [deg]')
title('Polar angle')
print(hf,fullfile(dr,'polar.png'),'-dpng')

% Age
hf = figure;
boxplot(data.Age(:),data.Group(:),'notch','on','labelorientation', 'inline')
legend(conditions)
set(gca,'FontSize',14)
ylabel('Age [years]')
print(hf,fullfile(dr,'age.png'),'-dpng')

% Correlation Choroid Thickness and Age
hf = figure;
FigureMaker(data.Age(:),data.meanthick(:),'Age [yr]','meanThickness [\mum]','d','poly1',false,[])
% print(hf,fullfile(dr,'correlMeanThcknessVsAge.png'),'-dpng')

% Correlation Retina Thickness and Age
hf = figure;
FigureMaker(data.Age(:),data.meanRetina(:),'Age [yr]','meanThickness [\mum]','d','poly1',false,[])

% % Histogram of polar angle of plane fit
% hf = figure;
% 
% clr     = 'rgbcmk';
% for k = 1:numel(conditions)
%     msk = ismember(data.Group(:),conditions{k});
%     lns = ['o-' clr(mod(k,length(clr)) + 1)];
%     
%     [counts, centers] = hist(90 - data.polar(msk),(0:3/10:3-3/10) + 3/20);
%     
%     counts = counts / sum(counts);
%     
%     plot(centers,counts,lns), hold on
% end
% 
% legend(conditions)
% title('Polar Histogram')
% print(hf,fullfile(dr,'histogramPolar.png'),'-dpng')

% Azimuth angle cumulative histogram
hf = figure;

% sym = 'os^*x+v><';
% clr     = 'rgbcmk';

edges = 0:15:360;
x = [0:30:330, 0];

hs = [];

xPs = [];
yPs = [];
rPs = [];

mxIx = 1;
mxIxVector = 1;

for k = 1:numel(conditions)
    msk = ismember(data.Group(:),conditions{k});
    
    angs = mod(data.azimuth(msk) + 360, 360);
    pols = mod(90 - data.polar(msk) + 360, 360);
    
    h = histcounts(angs,edges);
    
    h = [h(1)+h(end), h(2:2:end-1) + h(3:2:end-1)];
    
    h = h / sum(h);
    
    h = [h h(1)];
    
    if max(h) > max(hs(:))
        mxIx = k;
    end
    
    hs = [hs;h];
    
    xProjs = nanmean(pols .* cosd(angs));
    yProjs = nanmean(pols .* sind(angs));
    
    rProjs = norm([xProjs,yProjs]);
    
    xPs = [xPs xProjs];
    yPs = [yPs yProjs];
    
    if rProjs > max(rPs)
        mxIxVector = k;
    end
    
    rPs = [rPs rProjs];
    
end

for k = [mxIx, setdiff(1:numel(conditions),mxIx)]
    
    lns = [sym(mod(k,length(sym)) + 1) '-' clr(mod(k,length(clr)) + 1)];
    
    polar(x/180*pi,hs(k,:),lns), hold on
end

% legend(conditions)
set(gca,'FontSize',14)
print(hf,fullfile(dr,'AzimHistPolar.png'),'-dpng')

hf = figure;

for k = [mxIxVector, setdiff(1:numel(conditions),mxIxVector)]
    
    lns = ['-' clr(mod(k,length(clr)) + 1)];
    
    compass(xPs(k),yPs(k),lns), hold on
end

% legend(conditions)
set(gca,'FontSize',14)
print(hf,fullfile(dr,'AzimResult.png'),'-dpng')

end