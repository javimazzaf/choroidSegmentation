function [desc] = MapDescriptors(dirlist)

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
    
    [sf, N] = fitPlane(rawX,rawY,rawThickness,rawWeigth);
    
    EyeStr = regexp(dirlist{i},'O[SD]','match');
    
    if strfind(EyeStr{:},'OS')
        N(1) = - N(1);
    end
    
    [azimuth,polar,~] = cart2sph(N(1),N(2),N(3)); 
    azimuth = azimuth * 180 / pi; 
    polar   = polar * 180 / pi;
    
    temp = table(meanRawThickness, maxRawThickness, minRawThickness, stdRawThickness, azimuth, polar,...
            'VariableNames',{'meanthick','maxthick','minthick','stdthick','azimuth','polar'});
    
    info = [info, temp];
        
    desc = [desc;info];
    
    disp(i)

end


end


