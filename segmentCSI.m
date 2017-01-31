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

function CSI = segmentCSI(origShiftedBscan,rpeHeight)

parameters = loadParameters;

OG = EdgeProbabilityGrad(origShiftedBscan,parameters.scalesize,parameters.angles,rpeHeight);

%-% Inflection Points
Infl2 = zeros(size(origShiftedBscan));

shiftedBscan = min(255, origShiftedBscan / prctile(origShiftedBscan(:),99) * 255);

filteredBscan = imfilter(shiftedBscan,OrientedGaussian([parameters.averagingSizeZ, parameters.averagingSizeX],0));
colspacing    = 2;

nCols = size(filteredBscan,2);

testGrad = [];
testGrad2 = [];

for j = 1:nCols
    
    filteredAscan = double(filteredBscan(:,j));
    
    grad  = gradient(filteredAscan); 
    grad2 = del2(filteredAscan);

    z = (abs(grad2) < parameters.secondDerivativeThreshold) & (grad > parameters.firstDerivativeThreshold); %[JM]
    z(1:rpeHeight + parameters.choroidMinWidth) = 0;
    
    Infl2(z,j) = 1;
end

Infl2 = bwmorph(Infl2,'clean');
Infl2 = imfill(Infl2,'holes');
Infl2 = bwmorph(Infl2,'skel','inf');

Infl2(:,setdiff((1:nCols),(1:colspacing:nCols))) = 0;

Infl2 = bwmorph(Infl2,'shrink','inf');
g     = imextendedmin(filteredBscan,10);

Infl2(Infl2 & g) = 0;

nodes = Infl2;

% New edginess based on absolute gradient from unNormalized image
edg = edgeness(origShiftedBscan,parameters.scalesize/4,parameters.angles+90);

%-% Find CSI
[CSI, ~] = findCSI(nodes,OG);

if ~isstruct(CSI), return, end

for k = 1:numel(CSI)

    CSI(k).weight = edg(sub2ind(size(edg),CSI(k).y,CSI(k).x));
    
end


end