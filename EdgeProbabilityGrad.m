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

function padPb = EdgeProbabilityGrad(shiftbscan,scalesize,angles,rpeHeight)
% Computes the edge probability

parameters = loadParameters;

sigma  = scalesize / 4;
angles = angles + 90;

edg = edgeness(shiftbscan,sigma,angles);

% Keeps only positive gradient
edg(edg < 0) = 0;

% Keeps information within a valid region
padPb = zeros(size(edg));

topRow = max(1, rpeHeight + parameters.choroidMinWidth); 
botRow = min(size(padPb,1), topRow + parameters.choroidMaxWidth - 1); 

padPb(topRow:botRow,:) = edg(topRow:botRow,:);  

padPb(1,:) = 0;

% assigns the maximal edge probability to the 99.99 percentile of the
% pixels excluding a 15 pixels frame. It saturates the probability over
% this value.

aux = padPb(15:end-15,15:end-15);
topPbValue = prctile(aux(:),99.99);

padPb = min(1,padPb / topPbValue);

padPb = padPb.^2;

padPb(padPb <= parameters.edginessThreshold) = 0; 

end
