function [desc] = MapDescriptors(dirlist)
% function [desc] = MapDescriptors(dirlist,fileName)

fileName = '/Users/javimazzaf/Documents/work/proyectos/ophthalmology/choroidMaps/20160830/mapData.mat';

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
    
    if ~exist(fullfile(directory,'Results','ChoroidMap.mat'),'file')
        disp(['File does not exist: ' fullfile(directory,'Results','ChoroidMap.mat')])
        continue
    end
    
    load(fullfile(directory,'Results','ChoroidMap.mat'))
    load(fullfile(directory,'DataFiles','ImageList.mat'))
    load(fullfile(directory,'Results','postProcessingAnnotations.mat'), 'annotations')
    
    if ~isfield(annotations,'skip') 
        disp(['Skipping: (Skip field)' directory])
        continue
    end
    
    if logical(annotations.skip)  
        disp(['Skipping (Marked as skipped): ' directory])
        continue
    end   
    
    if ~isfield(annotations,'maculaCenter')
        disp(['Skipping(No maculaCenter): ' directory])
        continue
    end      
     
    % Center retinal map on Macula
    mapRetina = centerToMacula(mapRetina, annotations.maculaCenter);
    
    % Compute retinal thickness
    meanRETthickness = nanmean(mapRetina(:,3));
    
    % Center choroid map on Macula
    [mapInfo, mapRadius] = centerToMacula(mapInfo, annotations.maculaCenter); 
    mapInfo(:,[1,2]) = mapInfo(:,[1,2]) * 1000; %Change to microns
    
    % Compute choroid descriptors
    rawThickness  = mapInfo(:,3);
    rawWeigth     = mapInfo(:,4);

    meanThickness = sum(rawThickness .* rawWeigth) / sum(rawWeigth);
    maxThickness  = max(rawThickness);
    minThickness  = min(rawThickness);
    stdThickness  = sqrt(sum(rawThickness.^2 .* rawWeigth) / sum(rawWeigth) - meanThickness^2);
    q5Thickness   = prctile(rawThickness,5);
    q95Thickness  = prctile(rawThickness,95); 
    
    ratioChoroidToRetina = meanThickness / meanRETthickness;
    
    [sf, N] = fitPlane(mapInfo(:,1),mapInfo(:,2),mapInfo(:,3),mapInfo(:,4));
    
    EyeStr = regexp(dirlist{i},'O[SD]','match');
    
    if strfind(EyeStr{:},'OS')
        N(1) = - N(1);
    end
    
    [azimuth,polar,~] = cart2sph(N(1),N(2),N(3)); 
    azimuth = azimuth * 180 / pi; 
    polar   = polar * 180 / pi;
    
    [aredsT, fhAREDS] = getAREDSthickness(mapInfo(:,1),mapInfo(:,2),rawThickness,rawWeigth,EyeStr);
    
    [Quad, fhQuad]    = getQuadrantThickness(mapInfo(:,1),mapInfo(:,2),rawThickness,rawWeigth,EyeStr);
    
    [NTSI, fh]        = getNTSIThickness(mapInfo(:,1),mapInfo(:,2),rawThickness,rawWeigth,EyeStr);
    
    temp = table(mapRadius, meanThickness, maxThickness, minThickness, stdThickness, azimuth, polar, q5Thickness, q95Thickness, ...
                 aredsT.D1.mean, aredsT.D1.SD, aredsT.D1.N, aredsT.D3.nasal.mean, aredsT.D3.nasal.SD, aredsT.D3.nasal.N, aredsT.D3.inferior.mean, aredsT.D3.inferior.SD, aredsT.D3.inferior.N,...
                 aredsT.D3.temporal.mean, aredsT.D3.temporal.SD, aredsT.D3.temporal.N, aredsT.D3.superior.mean, aredsT.D3.superior.SD, aredsT.D3.superior.N,aredsT.D6.nasal.mean,...
                 aredsT.D6.nasal.SD, aredsT.D6.nasal.N, aredsT.D6.inferior.mean, aredsT.D6.inferior.SD, aredsT.D6.inferior.N, aredsT.D6.temporal.mean, aredsT.D6.temporal.SD, aredsT.D6.temporal.N,...
                 aredsT.D6.superior.mean, aredsT.D6.superior.SD, aredsT.D6.superior.N,ratioChoroidToRetina,...
                 Quad.nasalSuperior.mean,    Quad.nasalSuperior.SD,    Quad.nasalSuperior.N,...
                 Quad.nasalInferior.mean,    Quad.nasalInferior.SD,    Quad.nasalInferior.N,...    
                 Quad.temporalSuperior.mean, Quad.temporalSuperior.SD, Quad.temporalSuperior.N,...
                 Quad.temporalInferior.mean, Quad.temporalInferior.SD, Quad.temporalInferior.N,...
                 NTSI.nasal.mean,       NTSI.nasal.SD,       NTSI.nasal.N,...
                 NTSI.temporal.mean,    NTSI.temporal.SD,    NTSI.temporal.N,...
                 NTSI.superior.mean,    NTSI.superior.SD,    NTSI.superior.N,...
                 NTSI.inferior.mean,    NTSI.inferior.SD,    NTSI.inferior.N,...
                 'VariableNames',{'mapRadius','meanthick','maxthick','minthick','stdthick','azimuth','polar','q5thick','q95thick',...
                 'AREDS_D1Mean', 'AREDS_D1SD', 'AREDS_D1N','AREDS_D3nasalMean', 'AREDS_D3nasalSD', 'AREDS_D3nasalN','AREDS_D3inferiorMean', 'AREDS_D3inferiorSD', 'AREDS_D3inferiorN',...
                 'AREDS_D3temporalMean', 'AREDS_D3temporalSD', 'AREDS_D3temporalN', 'AREDS_D3superiorMean', 'AREDS_D3superiorSD', 'AREDS_D3superiorN','AREDS_D6nasalMean',...
                 'AREDS_D6nasalSD', 'AREDS_D6nasalN','AREDS_D6inferiorMean', 'AREDS_D6inferiorSD', 'AREDS_D6inferiorN','AREDS_D6temporalMean', 'AREDS_D6temporalSD', 'AREDS_D6temporalN',...
                 'AREDS_D6superiorMean', 'AREDS_D6superiorSD', 'AREDS_D6superiorN', 'ratioChoroidToRetina',...
                 'nasalSuperiorMean',    'nasalSuperiorSD',    'nasalSuperiorN',... 
                 'nasalInferiorMean',    'nasalInferiorSD',    'nasalInferiorN',...    
                 'temporalSuperiorMean', 'temporalSuperiorSD', 'temporalSuperiorN',... 
                 'temporalInferiorMean', 'temporalInferiorSD', 'temporalInferiorN',...
                 'nasalMean',            'nasalSD',            'nasalN',...
                 'temporalMean',         'temporalSD',         'temporalN',...
                 'superiorMean',         'superiorSD',         'superiorN',...
                 'inferiorMean',         'inferiorSD',         'inferiorN'});
           
             
    info = [info(:,[1:9,27:end]), temp];
        
    desc = [desc;info];
    
    disp(i)
    
    print(fhAREDS, fullfile(directory,'Results','AREDS.png'),'-dpng')
    print(fhQuad,  fullfile(directory,'Results','Quad.png'), '-dpng')
    
    close(fhAREDS)
    close(fhQuad)

end

descriptors = desc;

save(fileName,'descriptors')

end

function [smallMapInfo, optRadius] = centerToMacula(mapInfo, maculaCenter)

    optRadius = min([max(mapInfo(:,1)) - maculaCenter.x  ,...
                     maculaCenter.x - min(mapInfo(:,1))  ,...
                     max(mapInfo(:,2)) - maculaCenter.y  ,...
                     maculaCenter.y - min(mapInfo(:,2))]);

    r2 = (mapInfo(:,1) - maculaCenter.x).^2 + (mapInfo(:,2) - maculaCenter.y).^2;  
    
    msk = r2 <= optRadius^2;
            
    smallMapInfo = mapInfo(msk,:); 
    
    smallMapInfo(:,1) = smallMapInfo(:,1) - maculaCenter.x; 
    smallMapInfo(:,2) = smallMapInfo(:,2) - maculaCenter.y; 

end

    


