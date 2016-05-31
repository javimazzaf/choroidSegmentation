% function pathOut = adaptToHMRpath(pathIn)
% 
% Adapts the path of the patients directory structure, acording to the
% current computer.

% Copyright (C) 2016 Javier Mazzaferri <javier.mazzaferri@gmail.com>
% Hopital Maisonneuve-Rosemont, 
% Centre de Recherche
% www.biophotonics.ca
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.


function pathOut = adaptToHMRpath(pathIn)

if ispc
    pathOut = fullfile([filesep filesep 'HMR-BRAIN'],pathIn);
elseif ismac
    pathOut = fullfile([filesep 'Volumes'],pathIn);
else
    pathOut = fullfile(filesep,'srv','samba',pathIn);
end

end