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
%     
%     
%     notLoopMatrix = connectMatrix;
%     
%     notLoopMatrix(logical(eye(size(notLoopMatrix)))) = 0; %Diag to 0
%     
%     thisWeights = notLoopMatrix(thisMask,thisMask); %Elements of this graph
%     
%     graphMeanWeight(k) = nanmean(thisWeights(:));
    
end

% FALTA ORDERNAR LOS NODOS DE IZQIOERDA A DERECHA EN CADA SUBGRUPO, y ELEGIR LOLS SEGMENTOS CON MAS PESO.

path = [];     

end