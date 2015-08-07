function plotMapDecriptorsInGroups

load('/Users/javimazzaf/Documents/work/proyectos/ophthalmology/choroidMaps/mapData.mat','descriptors')

allConditions = unique(descriptors.Group(:));

populations = cellfun(@(x) sum(strcmp(descriptors.Group(:),x)), allConditions);

mskCond   = (populations > 10) & ~ismember(allConditions,'Other/No Group');
conditions  = allConditions(mskCond);
% populations = populations(mskCond);

mskData = ismember(descriptors.Group(:),conditions) & ~ismember(descriptors.Group(:),'Other/No Group');

data = descriptors(mskData,:);

% Populations
hf = figure;
bar(populations(mskCond))
set(gca,'XTickLabels',conditions)
ylabel('N patients')
print(hf,'populations.png','-dpng')

% Mean thickness
hf = figure;
boxplot(data.meanthick(:),data.Group(:),'notch','on','labels',conditions,'labelorientation', 'inline')
ylim([0, 400])
ylabel('mean Thickness [\mum]')
print(hf,'meanThickness.png','-dpng')

% Min thickness
hf = figure;
boxplot(data.minthick(:),data.Group(:),'notch','on','labels',conditions,'labelorientation', 'inline')
ylim([0, 150])
ylabel('min Thickness [\mum]')
print(hf,'minThickness.png','-dpng')

% Max thickness
hf = figure;
boxplot(data.maxthick(:),data.Group(:),'notch','on','labels',conditions,'labelorientation', 'inline')
ylim([0, 700])
ylabel('max Thickness [\mum]')
print(hf,'maxThickness.png','-dpng')

% Max thickness
hf = figure;
boxplot(data.stdthick(:),data.Group(:),'notch','on','labels',conditions,'labelorientation', 'inline')
ylim([0, 100])
ylabel('std Thickness [\mum]')
print(hf,'stdThickness.png','-dpng')

% % Polar angle of plane fit
% hf = figure;
% meanAzimuth = cellfun(@(x) atan2d(sum(sind(data.azimuth(ismember(data.Group(:),x)))),...
%                                   sum(cosd(data.azimuth(ismember(data.Group(:),x))))),...
%                       conditions);
% 
% bar(meanAzimuth)
% set(gca,'XTickLabels',conditions)
% ylabel('mean Azimuth')
% print(hf,'meanAzimuth.png','-dpng')

% Azimuth angle of plane fit, in scatter plot
hf = figure;

sym = 'os^*x+v><';
clr     = 'rgbcmk';
for k = 1:numel(conditions)
    msk = ismember(data.Group(:),conditions{k});
    lns = [sym(mod(k,length(sym)) + 1) clr(mod(k,length(clr)) + 1)];
    polar(data.azimuth(msk)/180*pi,pi/2 - data.polar(msk)/180*pi,lns), hold on
end

legend(conditions)
title('Azimuth Scatter')
print(hf,'scatterAzimuth.png','-dpng')

% Histogram of azimuth of plane fit
hf = figure;
clr     = 'rgbcmk';

mxCounts = -Inf;
mxInd    = 1;

for k = 1:numel(conditions)
    msk = ismember(data.Group(:),conditions{k}); 
    [counts, centers] = hist(data.azimuth(msk),[22.5:45:337.5]);

    counts = counts / sum(counts);
    
    thisMax = max(counts);
    
    if thisMax > mxCounts
        mxCounts = thisMax;
        mxInd = k;
    end
end

msk = ismember(data.Group(:),conditions{mxInd});
lns = ['o-' clr(mod(mxInd,length(clr)) + 1)];
[counts, centers] = hist(data.azimuth(msk),[22.5:45:337.5]);
counts = counts / sum(counts);
counts  = [counts counts(1)];
centers = [centers centers(1)];
polar(centers/180*pi,counts,lns), hold on

for k = setdiff(1:numel(conditions),mxInd)
    msk = ismember(data.Group(:),conditions{k});
    lns = ['o-' clr(mod(k,length(clr)) + 1)];
    
    [counts, centers] = hist(data.azimuth(msk),[22.5:45:337.5]);
    
    counts = counts / sum(counts);
    
    counts  = [counts counts(1)];
    centers = [centers centers(1)];
    
    polar(centers/180*pi,counts,lns)
end

legend(conditions)
title('Azimuth Histogram')
print(hf,'histogramAzimuth.png','-dpng')

% polar angle of plane fit
hf = figure;
boxplot(90-data.polar(:),data.Group(:),'notch','on','labels',conditions,'labelorientation', 'inline')
ylim([0, 3])
ylabel('polar angle [deg]')
title('Polar angle')
print(hf,'polar.png','-dpng')

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
% print(hf,'histogramPolar.png','-dpng')

end