% Copyright (C) 2017, Javier Mazzaferri, Luke Beaton, Santiago Costantino 
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

function parameters = loadParameters

parameters.averagingSizeX  = 5; % in pixels
parameters.averagingSizeZ  = 5; % in pixels
parameters.choroidMinWidth = 15; % in pixels
parameters.choroidMaxWidth = 150; % in pixels
parameters.firstDerivativeThreshold  = 0.7;
parameters.secondDerivativeThreshold = 1e-2;
parameters.edginessThreshold   = 0.1;
parameters.minMeanPathWeight   = 0.1; 
parameters.minSumPathWeigth    = 0.5;
        
% relative weights for choosing among csi segments that overlap.    
parameters.segmentSelectionSumWeigth  = 0.8; 
parameters.segmentSelectionMeanWeigth = 0.1;
parameters.segmentSelectionHeights    = 0.1;

% Edge Probability
parameters.scalesize = [10 15 20];
parameters.angles    = [-20 0 20];

% Graph search
parameters.alpha      = 2;
parameters.wM         = 20000;
parameters.delColmax  = 40;
parameters.delRowmax  = 25;
parameters.maxJumpCol = 10;
parameters.maxJumpRow = 5;
parameters.on1        = 1;
parameters.on2        = 1;
parameters.on3        = 0;
parameters.on4        = 1;

end