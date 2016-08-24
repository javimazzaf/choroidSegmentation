% LIST DIRECTORIES OF PATIENTS WITH SPECIFIC CHARACTERISTICS
% The output can be used as parameters for the processing functions. For
% example:
%    convertSpectralis(todo.convert);

if ~ispc
    if ismac
        topdir = '/Volumes/';
    else
        topdir='/srv/samba/';
    end
else

    error('Set topdir variable. ~Line 14')
%     topdir='??????';
    return

end

%%% FOR A SET OF CONDITIONS
% groups = {'Normal';...
%           'Early AMD';...
%           'Dry AMD';...
%           'Wet AMD';...
%           'Geographic Atrophy';...
%           'Suspect Glaucoma';...
%           'OAG';'Bleb';...
%           'OHT';...
%           'Uveitis';...
%           'Precoce'};

% groups = {'Wet AMD'};

% groups = {'Early AMD';...
%           'Dry AMD';...
%           'Wet AMD'};



%%% FOR INDIVIDUAL CONDITIONS
% groups = {'Normal'};
% groups = {'Early AMD'};
% groups = {'Dry AMD'};
% groups = {'Wet AMD'};
% groups = {'Geographic Atrophy'};
% groups = {'Suspect Glaucoma'};
% groups = {'OAG'};
% groups = {'Bleb'};
% groups = {'OHT'};
% groups = {'Precoce'};
% groups = {'Uveitis'};

groups = [];

%%% FOR A SET OF STUDIES
% studies   = {'Choroidal Mapping';...
%              'Optic Nerve Head';...
%              'Rigidity'};

%%% FOR INDIVIDUAL STUDIES
studies   = {'Choroidal Mapping'}; 
% studies   = {'Rigidity'}; 

reproducibility = '';

[todo, has, numBscans, masks] = getDirectories(topdir,groups,studies,reproducibility);

disp(['Has RawIm:          ' num2str(numel(has.RawIm))])
disp(['Has Imags:          ' num2str(numel(has.Imags))])
disp(['Has Regis:          ' num2str(numel(has.Regis))])
disp(['Has Segmentation:   ' num2str(numel(has.Segmentation))])
disp(['Has Map:            ' num2str(numel(has.Map))])
disp(['Has Mov:            ' num2str(numel(has.Mov))])
disp(['Has Anot:           ' num2str(numel(has.Anot))])
disp(['Has Bscans:         ' num2str(numel(has.bScans))])
disp(['All:                ' num2str(numel(has.All))])

% Describe number of frames per map
num190 = sum(numBscans > 185 & numBscans < 195);
num50  = sum(numBscans > 40 & numBscans < 52);
num0   = sum(numBscans < 40);
total  = numel(numBscans);

disp('Number of bscans: (valid for choroidMaps)')
disp(['  ~190: ' num2str(num190) 9 '(' num2str(num190 * 100 / total,'%2.1f') '%)']);
disp(['  ~50 : ' num2str(num50) 9 '(' num2str(num50 * 100 / total,'%2.1f') '%)']);
disp(['  ~0  : ' num2str(num0) 9 '(' num2str(num0 * 100 / total,'%2.1f') '%)']);
disp('----------------------------------')

disp(['To ConvertSpectralis:      (todo.convert)  '   num2str(numel(todo.convert))])
disp(['To Register:               (todo.register) '   num2str(numel(todo.register))])
disp(['To ChoroidMapFirstProcess: (todo.firstMapNew)' num2str(numel(todo.firstMapNew))]) 
disp(['To ComputeMap:             (todo.compMap)  '   num2str(numel(todo.compMap))])
disp(['To ComputeMov:             (todo.compMov)  '   num2str(numel(todo.compMov))])
disp(['To ComputeAnot:            (todo.compAnot)  '   num2str(numel(todo.compAnot))])
disp(['To ComputeBscans:          (todo.compBscans)  '   num2str(numel(todo.compBscans))])




