function ComputeOcularRigidity(varargin)
close all

if length(varargin)==1
    if ispc
        dirlist = fullfile([filesep filesep 'HMR-BRAIN'],varargin{1});
    elseif ismac
        dirlist = fullfile([filesep 'Volumes'],varargin{1});
    else
        dirlist = fullfile(filesep,'srv','samba',varargin{1});
    end
else
    if ispc
        load(fullfile([filesep filesep 'HMR-BRAIN'],'share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
        dirlist=fullfile([filesep filesep 'HMR-BRAIN'],dirlist);
    else
        load(fullfile(filesep,'srv','samba','Share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
        dirlist=fullfile(filesep,'srv','samba',strrep(dirlist,'\','/'));
    end
    [missdata,missraw,missprocessim,missregims,missresults]=CheckDirContents(dirlist);
    deltaCT=logical(cellfun(@exist,fullfile(dirlist,'Results','DeltaCT.mat')));
    Rigidity=~cellfun(@isempty,regexp(dirlist,'Rigidity','match'));
    dirlist=dirlist(deltaCT&Rigidity);
    if isempty(dirlist)
        errordlg('No diretories prerequisite data. Run ComputeDeltaCT.m first')
        return
    end
end


for iter=1:length(dirlist)
    directory=dirlist{iter};
    indx=regexp(directory,'/');
    indx=indx(end)+1;
 
    savedir=fullfile(directory,'Results');
    
    %% Patient Data
    
    load(fullfile(dirlist{iter},'Data Files','VisitData.mat'));
    
    IOP=visitdata.PascalIOP{:};
    OPA=visitdata.PascalOPA{:};
    L=visitdata.AL{:};
        
    R=L/2;
    
    % width=[ImageList(inclframelist).scaleX]'.*cellfun(@size,{bscanstore{inclframelist}}',repmat({2},length(inclframelist),1)); % [mm]
    
    %%
    load(fullfile(directory,'Results','DeltaCT.mat'))
    dV=(pi*R^2*deltad1);
    dV2=(pi*R^2*deltad2);
    dV3=(pi*R^2*deltad3);
    
    % dV=0.65*pi*((R*0.95+deltad1)^3-(R*0.95)^3);
    % dV2=0.65*pi*((R*0.95+deltad2)^3-(R*0.95)^3);
    % dV3=0.65*pi*((R*0.95+deltad3)^3-(R*0.95)^3);
    
    k1=log((IOP+OPA)/(IOP))/dV; % 1/uL
    k2=log((IOP+OPA)/(IOP))/dV2; % 1/uL
    k3=log((IOP+OPA)/(IOP))/dV3; % 1/uL
    %%
    CT=mean(d2);
    dCT=deltad2;
    dV=dV2;
    OR=k2;
    save(fullfile(directory,'Results','Results.mat'),'CT','dCT','dV','OR');
    
end

