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

function [paths] = getPossiblePath(connectMatrix)

ix = 1:size(connectMatrix,2);
% Eliminate nodes without incoming and outcoming edges
msk = any(full(connectMatrix) > 0) & any(full(connectMatrix') > 0);

% Keep list of absolute indexes
ix(~msk) = [];

% Reduce matrix to valid nodes
connectMatrix(~msk,:) = [];
connectMatrix(:,~msk) = [];

% Gets the connected graphs
[nGraphs,graphMask] = graphconncomp(connectMatrix,'Directed',false);

graphMeanWeight = zeros(1,nGraphs);

redIx = 1:size(connectMatrix,2);

paths = [];

for k = 1:nGraphs
    
    thisMask = graphMask == k;
    graphSize = sum(thisMask);
    
    thisIx = redIx(thisMask);
    
    thisMatrix = full(connectMatrix);
    thisMatrix(~thisMask,:) = [];
    thisMatrix(:,~thisMask) = [];
    
    thisMatrix = sparse(thisMatrix);
    
    [~,pathWin,~] = graphshortestpath(thisMatrix,1,sum(thisMask),'Directed',false);
    
    if length(pathWin) < 4, continue, end
    
    startNode = pathWin(1:end-1);
    endNode   = pathWin(2:end);
    ixNode = sub2ind(size(thisMatrix),endNode,startNode);
    weightNode = thisMatrix(ixNode); 
    
    path.ix = ix(thisIx(pathWin));
    path.weight = weightNode;
    
    paths = [paths path];
    
end

path = [];     

end