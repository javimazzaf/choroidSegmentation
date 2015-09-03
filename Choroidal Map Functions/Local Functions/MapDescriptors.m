function [desc] = MapDescriptors(dirlist,fileName)

if ispc
    dirlist = fullfile([filesep filesep 'HMR-BRAIN'],dirlist);
    databasedir = fullfile('\\HMR-BRAIN','share','SpectralisData');
elseif ismac
    dirlist = fullfile([filesep 'Volumes'],dirlist);
    databasedir = fullfile(filesep,'Volumes','share','SpectralisData');
else
    dirlist = fullfile(filesep,'srv','samba',dirlist);
    databasedir = fullfile(filesep,'srv','samba','share','SpectralisData');
end

load(fullfile(databasedir,'DatabaseFile.mat'))

desc = [];

for i=1:length(dirlist)
    
    directory = dirlist{i};
    
    info = GetStudyInfo(directory, dbase);
    
    if ~exist(fullfile(directory,'Results','ChoroidMapNew.mat'),'file')
        continue
    end
    
    load(fullfile(directory,'Results','ChoroidMapNew.mat'))
    load(fullfile(directory,'Data Files','ImageList.mat'))
    
    rawX          = mapInfo(:,1) * 1000;
    rawY          = mapInfo(:,2) * 1000;
    rawThickness  = mapInfo(:,3);
    rawWeigth     = mapInfo(:,4);

    meanRawThickness = sum(rawThickness .* rawWeigth) / sum(rawWeigth);
    maxRawThickness  = max(rawThickness);
    minRawThickness  = min(rawThickness);
    stdRawThickness  = sqrt(sum(rawThickness.^2 .* rawWeigth) / sum(rawWeigth) - meanRawThickness^2);
    q5RawThickness  = prctile(rawThickness,5);
    q95RawThickness = prctile(rawThickness,95);
    
    [sf, N] = fitPlane(rawX,rawY,rawThickness,rawWeigth);
    
    EyeStr = regexp(dirlist{i},'O[SD]','match');
    
    if strfind(EyeStr{:},'OS')
        N(1) = - N(1);
    end
    
    [azimuth,polar,~] = cart2sph(N(1),N(2),N(3)); 
    azimuth = azimuth * 180 / pi; 
    polar   = polar * 180 / pi;
    
    [aredsT, fh] = getAREDSthickness(rawX,rawY,rawThickness,rawWeigth,EyeStr);
    
    temp = table(meanRawThickness, maxRawThickness, minRawThickness, stdRawThickness, azimuth, polar, q5RawThickness, q95RawThickness, ...
                 aredsT.D1.mean, aredsT.D1.SD, aredsT.D1.N, aredsT.D3.nasal.mean, aredsT.D3.nasal.SD, aredsT.D3.nasal.N, aredsT.D3.inferior.mean, aredsT.D3.inferior.SD, aredsT.D3.inferior.N,...
                 aredsT.D3.temporal.mean, aredsT.D3.temporal.SD, aredsT.D3.temporal.N, aredsT.D3.superior.mean, aredsT.D3.superior.SD, aredsT.D3.superior.N,aredsT.D6.nasal.mean,...
                 aredsT.D6.nasal.SD, aredsT.D6.nasal.N, aredsT.D6.inferior.mean, aredsT.D6.inferior.SD, aredsT.D6.inferior.N, aredsT.D6.temporal.mean, aredsT.D6.temporal.SD, aredsT.D6.temporal.N,...
                 aredsT.D6.superior.mean, aredsT.D6.superior.SD, aredsT.D6.superior.N,...
                 'VariableNames',{'meanthick','maxthick','minthick','stdthick','azimuth','polar','q5thick','q95thick',...
                 'AREDS_D1Mean', 'AREDS_D1SD', 'AREDS_D1N','AREDS_D3nasalMean', 'AREDS_D3nasalSD', 'AREDS_D3nasalN','AREDS_D3inferiorMean', 'AREDS_D3inferiorSD', 'AREDS_D3inferiorN',...
                 'AREDS_D3temporalMean', 'AREDS_D3temporalSD', 'AREDS_D3temporalN', 'AREDS_D3superiorMean', 'AREDS_D3superiorSD', 'AREDS_D3superiorN','AREDS_D6nasalMean',...
                 'AREDS_D6nasalSD', 'AREDS_D6nasalN','AREDS_D6inferiorMean', 'AREDS_D6inferiorSD', 'AREDS_D6inferiorN','AREDS_D6temporalMean', 'AREDS_D6temporalSD', 'AREDS_D6temporalN',...
                 'AREDS_D6superiorMean', 'AREDS_D6superiorSD', 'AREDS_D6superiorN'});
   
    info = [info, temp];
        
    desc = [desc;info];
    
    disp(i)
    
    print(fh, fullfile(directory,'Results','AREDS.png'),'-dpng')
    
    close(fh)

end

descriptors = desc;

save(fileName,'descriptors')

end


