% function testingScript



load('/Users/javimazzaf/Documents/work/proyectos/ophthalmology/choroidMaps/afterFixingCroping/mapData.mat','descriptors')

allConditions = unique(descriptors.Group(:));

populations = cellfun(@(x) sum(strcmp(descriptors.Group(:),x)), allConditions);

mskCond   = (populations > 10) & ~ismember(allConditions,'Other/No Group');
conditions  = allConditions(mskCond);

mskData = ismember(descriptors.Group(:),conditions) & ~ismember(descriptors.Group(:),'Other/No Group');

data = descriptors(mskData,:);
% clr = 'rgbmck';
% 
% for c = 1:numel(conditions)
%     subdata = data(ismember(data.Group(:),conditions{c}),:);
%     [counts,centers] = hist(subdata.Age(:),30:10:100);
%     plot(centers,counts/sum(counts),['.-' clr(mod(c,6)+1)]), hold on
% end

% plot(data.Age(:),data.meanthick(:),'ok')
% FigureMaker(data.Age(:),data.meanthick(:),'Age [yr]','meanThickness [\mum]','d','poly1',1,[])

% % Age
% hf = figure;
% boxplot(data.Age(:),data.Group(:),'notch','on','labels',conditions,'labelorientation', 'inline')
% legend(conditions)
% set(gca,'FontSize',14)
% ylabel('Age [years]')
% print(hf,fullfile(dr,'age.png'),'-dpng')

