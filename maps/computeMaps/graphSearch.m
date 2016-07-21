function [PathPts,usedNodes] = graphSearch(nodesMask,edgeness,alpha,wM,delColmax,delRowmax,maxJumpCol,...
    maxJumpRow,on1,on2,on3,on4,grad)

% Previously: mapGraphSearchFirstPass

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
        ConnectionAffinity = linePenalty(indx,rows,cols,connected,edgeness);
    else
        ConnectionAffinity = Inf;
    end
    
    Euclid            = dely.^2 + delx.^2;
    VertJumpPenalty   = wM * (heaviside(dely-maxJumpRow) .* abs((dely-maxJumpRow))) .* sigmf(dely,[alpha,maxJumpRow]);
    HorizJumpPenalty  = wM * (heaviside(delx-maxJumpCol) .* abs((delx-maxJumpCol))) .* sigmf(delx,[alpha,maxJumpCol]);  %was wm/2
    EndTexturePenalty = wM ./ edgeness(sub2ind(size(edgeness),rows(connected),cols(connected)));
    AffinityPenalty   = wM ./ ConnectionAffinity;
    
    Weight = Euclid                  +... % Euclidian Distance Squared
        VertJumpPenalty         +... % Control of Vertical Jump Penalty Magnitude
        on1 * HorizJumpPenalty  +... %Control of Horizontal Jump Penalty Magnitude
        on3 * EndTexturePenalty +...
        on4 * AffinityPenalty;
    
    
    connectMatrix(indx,connected) = Weight;
end

%Test JM
% connectMatrix = connectMatrix';
connectMatrix = tril(connectMatrix + connectMatrix');

connectMatrix(connectMatrix<= 3 * eps(connectMatrix)) = 0;

connectMatrix = sparse(connectMatrix);

% [dist,path,~] = graphshortestpath(connectMatrix,1,numNodes);
% test JM
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
    domains = zeros(numel(paths),size(edgeness,2)); 
    
    for k = 1:numel(paths)
        
        stretch.x = cols(paths(k).ix);
        stretch.y = rows(paths(k).ix);
        
        stretch.weight     = edgeness(sub2ind(size(edgeness),stretch.y,stretch.x));
        stretch.sumWeight  = sum(full(stretch.weight));
        stretch.meanWeight = mean(full(stretch.weight));
        stretch.meanHeight = mean(full(stretch.y));
        stretch.length     = numel(full(stretch.y));
        stretch.keep       = 0;
        
%         % Skip unimportant stretches
%         if stretch.meanWeight < 0.5 || stretch.length < 5
%             stretch.x      = 0;
%             stretch.y      = 0;
%             stretch.weight = 0;
%         else
           %Set ones for each columns where the stretch exists
           domains(k,min(stretch.x):max(stretch.x)) = 1;         
%         end
        
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
          
%           [~,ixWeight] = sort([PathPts(objIx).meanWeight],'ascend');
%           [~,iHeight]  = sort([PathPts(objIx).meanHeight],'descend');
%           [~,iLength]  = sort([PathPts(objIx).length],'ascend');
          
          % Combine the three ordering criteria
%           [~,ixWin] = max(mean([ixWeight;iHeight;iLength]));
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
    PathPts.weight = edgeness(sub2ind(size(edgeness), PathPts.y, PathPts.x));
    PathPts.keep   = 1;
    
%     vals=fit([0;usedNodes.X;nCols+1],[rows(path(2));usedNodes.Y;rows(path(end-1))],'linear');
%     vals=vals(1:nCols);
%     vals=round(smooth(vals,50,'rloess'))'; %0.2
%     PathPts=sub2ind([nRows nCols],vals,1:length(vals));
    
end





end