function blah=PCA(data,groupcol)

%Takes the input groupcol which groups the observations (rows), and assigns
%them a number corresponding to each unique group in groupcol, for use in
%gscatter.
groups=unique(groupcol);
group=zeros(length(groupcol),1);
for i=1:length(groups)
    group(strcmp(groups(i),groupcol))=i;
end
    

categories=data.Properties.VariableNames;

data=table2array(data);
figure
boxplot(data,'orientation','horizontal','labels',categories)
b=zscore(data);
figure, boxplot(b,'orientation','horizontal','labels',categories)

%Center the Data

%Normalize with the variance
[wcoeff,score,latent,tsquared,explained]=pca(data,'centered','on','VariableWeights','variance');
coefforth=inv(diag(std(data)))*wcoeff;

figure
pareto(explained)
xlabel('Principal Component')
ylabel('Variance Explained (%)')

figure
gscatter(score(:,1),score(:,2),group)
xlabel('1st Principal Component')
ylabel('2nd Principal Component')

figure
biplot(coefforth(:,1:2),'scores',score(:,1:2),'varlabels',categories);


figure
biplot(coefforth(:,1:3),'scores',score(:,1:3));
view([30 40]);

blah=1;

% end
% 
% data=table2array([desc(:,1:10) info(:,2)])
% 
% Normal=strcmp('Normal',info.Group);
% Glauc=~cellfun(@isempty,regexp(info.Group,'(OAG|Bleb)'));
% AMD=~cellfun(@isempty,regexp(info.Group,'AMD'));
% Uveitis=strcmp('Uveitis',info.Group);
% groups=Normal+2*Glauc+3*AMD+4*Uveitis;
% 
% for i=1:size(data,2)
%     figure
%     hold all
%     temp=repmat(data(:,i),1,4);
%     temp(~Normal,1)=nan; 
%     temp(~Glauc,2)=nan;
%     temp(~AMD,3)=nan;
%     temp(~Uveitis,4)=nan;
%     boxplot(temp,'orientation','horizontal','labels',{'Normal','Glauc','AMD','Uveitis'},'notch','on')
%     title(categories{i})
% end