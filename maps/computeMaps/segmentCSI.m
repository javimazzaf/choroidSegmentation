function CSI = segmentCSI(origShiftedBscan,rpeHeight)

parameters = loadParameters;

OG = EdgeProbabilityGrad(origShiftedBscan,parameters.scalesize,parameters.angles,rpeHeight);

%-% Inflection Points
Infl2 = zeros(size(origShiftedBscan));

% shiftedBscan = origShiftedBscan / max(origShiftedBscan(:)) * 255;
shiftedBscan = min(255, origShiftedBscan / prctile(origShiftedBscan(:),99) * 255);

% filteredBscan = imfilter(shiftedBscan,OrientedGaussian([3 3],0));
filteredBscan = imfilter(shiftedBscan,OrientedGaussian([parameters.averagingSizeZ, parameters.averagingSizeX],0));
colspacing    = 2;

nCols = size(filteredBscan,2);

LOG = lapofgaus(shiftedBscan,max(parameters.scalesize));

% firstDerThresh = graythresh(OG);
% 
% aux = LOG;
% aux(OG < firstDerThresh) = NaN;
% secondDerThresh = nanmax(nanmin(aux));

for j = 1:nCols
    
%     filteredAscan = smooth(double(filteredBscan(:,j)),10);
%     filteredAscan = double(filteredBscan(:,j));
    
    grad  = OG(:,j);
    grad2 = LOG(:,j);
%     grad  = gradient(filteredAscan); 
%     grad2 = del2(filteredAscan);

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