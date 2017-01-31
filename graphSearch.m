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

function [PathPts,usedNodes] = graphSearch(nodesMask,edGness,alpha,wM,delColmax,delRowmax,maxJumpCol,...
    maxJumpRow,on1,on2,on3,on4,grad)

% Computes the graph search for the nodes in "nodesMask" with weights
% computed here using "edginess" image, and parameters alpha,wM,delColmax,
% delRowmax,maxJumpCol,maxJumpRow,on1,on2,on3,on4

parameters = loadParameters;

[nRows,nCols] = size(nodesMask);

% Index of nodes
[rows, cols] = find(nodesMask);
% Arrays holding the row and col
rows = [0; rows; 0];
cols = [0;cols;0];
numNodes = numel(find(nodesMask))+2;
connectMatrix = zeros(numNodes,numNodes);

nodesMask = bwlabel(nodesMask);
nodesMask(logical(nodesMask)) = nodesMask(logical(nodesMask)) + 1;

nodesIdx = 1:numNodes;
firstCol   = cols(2);
lastCol    = cols(end-1);

% counts = zeros(1,5);

%% Boundary Conditions
BoundaryColCon = round(delColmax);
LBoundIndx     = nodesIdx(ismember(cols,firstCol:firstCol+BoundaryColCon));
RBoundIndx     = nodesIdx(ismember(cols,lastCol-BoundaryColCon:lastCol));

connectMatrix(1,LBoundIndx) = 1 + on2 * (cols(LBoundIndx).^2+...
    wM  * (heaviside(cols(LBoundIndx)-maxJumpCol)           .*...
    abs((cols(LBoundIndx)-maxJumpCol)))                     .*...
    sigmf(cols(LBoundIndx),[alpha,maxJumpCol])              );

connectMatrix(RBoundIndx,numNodes) = 1 + on2 * ((nCols - cols(RBoundIndx)).^2+...
    wM  * (heaviside((nCols - cols(RBoundIndx)) - maxJumpCol)                .*...
    abs(((nCols - cols(RBoundIndx)) - maxJumpCol)))                          .*...
    sigmf((nCols - cols(RBoundIndx)), [alpha,maxJumpCol])                    );

%% All Other Connections
for indx = 2:numNodes-1
    
    if cols(indx) == max(cols)
        break
    end
    
    connected = nodesIdx(abs(cols(indx)-cols) <= delColmax  &...
                                         cols >  cols(indx) &...
                         abs(rows(indx)-rows) <= delRowmax  &...
                                         cols <= nCols           );
    
    if isempty(connected) && ~any(any(connectMatrix(1:indx-1,indx+1:end)))
        nextcol   = min(cols((cols>cols(indx) & abs(rows(indx)-rows)<=delRowmax)));
        
        if isempty(nextcol), break, end % JM if there are no more colums it stops the loop
        
        connected = nodesIdx(cols==nextcol & abs(rows(indx)-rows)<=delRowmax);
    end
    
    dely=abs(rows(indx)-rows(connected));
    delx=abs(cols(indx)-cols(connected));
    
    if on4
        ConnectionAffinity = linePenalty(indx,rows,cols,connected,edGness);
    else
        ConnectionAffinity = Inf;
    end
    
    Euclid            = dely.^2 + delx.^2;
    VertJumpPenalty   = wM * (heaviside(dely-maxJumpRow) .* abs((dely-maxJumpRow))) .* sigmf(dely,[alpha,maxJumpRow]);
    HorizJumpPenalty  = wM * (heaviside(delx-maxJumpCol) .* abs((delx-maxJumpCol))) .* sigmf(delx,[alpha,maxJumpCol]);  %was wm/2
    EndTexturePenalty = wM ./ edGness(sub2ind(size(edGness),rows(connected),cols(connected)));
    AffinityPenalty   = wM ./ ConnectionAffinity;
    
    Weight = Euclid                  +... % Euclidian Distance Squared
        VertJumpPenalty         +... % Control of Vertical Jump Penalty Magnitude
        on1 * HorizJumpPenalty  +... %Control of Horizontal Jump Penalty Magnitude
        on3 * EndTexturePenalty +...
        on4 * AffinityPenalty;
    
    
    connectMatrix(indx,connected) = Weight;
end

connectMatrix = tril(connectMatrix + connectMatrix');

connectMatrix(connectMatrix<= 3 * eps(connectMatrix)) = 0;

connectMatrix = sparse(connectMatrix);

[dist,path,~] = graphshortestpath(connectMatrix,1,numNodes,'directed',false);

% If there is no path it tries to solve in parts.
if isempty(path) || any(isinf(dist))
    paths = getPossiblePath(connectMatrix);
    
    if isempty(paths)
        PathPts   = [];
        usedNodes = [];
        return
    end
    
    PathPts = [];
    
    %Contains the domains for each stretch candidate
    domains = zeros(numel(paths),size(edGness,2)); 
    
    for k = 1:numel(paths)
        
        stretch.x = cols(paths(k).ix);
        stretch.y = rows(paths(k).ix);
        
        stretch.weight     = edGness(sub2ind(size(edGness),stretch.y,stretch.x));
        stretch.sumWeight  = sum(full(stretch.weight));
        stretch.meanWeight = mean(full(stretch.weight));
        stretch.meanHeight = mean(full(stretch.y));
        stretch.length     = numel(full(stretch.y));
        stretch.keep       = 0;
        
        %Set ones for each columns where the stretch exists
        domains(k,min(stretch.x):max(stretch.x)) = 1;         
        
        PathPts = [PathPts stretch];
         
    end
    
    if size(domains,1) > 1
      count = sum(domains);
    else
      count = domains > 0;  
    end
    
    ids   = bi2de(domains')'; % Builds a unique number for each combination of segments
    ix    = setdiff(unique(ids),[0, 2.^(0:size(domains,1)-1)]); % Gets a list of the unique numbers except those representing only one segement
    
    keep = ones(1,size(domains,1));
    
    for k = 1:numel(ix)
          
          objIx = find(de2bi(ix(k),numel(paths))); %List segments that overlap here
          
          objIx = setdiff(objIx,find(keep==0));
          
          sumWeights  = [PathPts(objIx).sumWeight];
          meanWeights = [PathPts(objIx).meanWeight];
          heights     = [PathPts(objIx).meanHeight]; % disfavors segments at the bottom of the scan (originated on noise)
          
          sumWeightRates  = parameters.segmentSelectionSumWeigth  *  sumWeights  / sum(sumWeights);
          meanWeightRates = parameters.segmentSelectionMeanWeigth *  meanWeights / sum(meanWeights);
          heightRates     = parameters.segmentSelectionHeights    ./ heights     / sum(1./heights);
          
          fullRate = sumWeightRates + meanWeightRates + heightRates;
          
          % Combine the three ordering criteria
          [~,ixWin] = max(fullRate);
          
          keep(setdiff(objIx,objIx(ixWin))) = 0; %Discard those not choosen 
          
%        end
    end
     
    % Keep segments that do not overlap and remove unsignificant ones
    for k = 1:numel(PathPts)
        if PathPts(k).meanWeight < parameters.minMeanPathWeight || PathPts(k).length < parameters.minSumPathWeigth
            PathPts(k).keep = 0;
        elseif all(count(logical(domains(k,:))) == 1)
            PathPts(k).keep = 1;
        else
            PathPts(k).keep = keep(k);
        end
    end
    
    usedNodes = [];
    
else
  
    usedNodes.X = cols(path(2:end-1));
    usedNodes.Y = rows(path(2:end-1));
    
    PathPts.x      = usedNodes.X;
    PathPts.y      = usedNodes.Y;
    PathPts.weight = edGness(sub2ind(size(edGness), PathPts.y, PathPts.x));
    PathPts.keep   = 1;
    
end





end