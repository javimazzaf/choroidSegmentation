function CSI = getCSIpiecewise(origShiftedBscan,rpeHeight)

%-% Edge Probability
scalesize = [10 15 20];
angles    = [-20 0 20];

% [~,OG] = EdgeProbability(shiftedBscan,scalesize,angles,meanTop,maxShift);
OG = EdgeProbabilityGrad(origShiftedBscan,scalesize,angles,rpeHeight);

%-% Inflection Points
Infl2 = zeros(size(origShiftedBscan));

shiftedBscan = origShiftedBscan / max(origShiftedBscan(:)) * 255;

filteredBscan = imfilter(shiftedBscan,OrientedGaussian([3 3],0));
colspacing    = 2;

nCols = size(filteredBscan,2);

testGrad = [];
testGrad2 = [];

der1Thresh = getParameter('FIRST_DERIVATIVE_THRESHOLD');
der2Thresh = getParameter('SECOND_DERIVATIVE_THRESHOLD');
RPE_CSI_gap = getParameter('CHOROID_MIN_WIDTH');

for j = 1:nCols
    
    filteredAscan = smooth(double(filteredBscan(:,j)),10);
    
    grad  = gradient(filteredAscan);
    grad2 = del2(    filteredAscan);
    
    testGrad  = [testGrad grad];
    testGrad2 = [testGrad2 grad2];

    z = (abs(grad2) < der2Thresh) & (grad > der1Thresh); %[JM]
    z(1:rpeHeight + RPE_CSI_gap) = 0;
    
    Infl2(z,j) = 1;
end

%                 % START **** ALTERNATIVE INFLEXION POINT SEARCH ****
%                 smoothedBscan = filter2(fspecial('disk',5),filteredBscan,'same');
%                 [gradX,gradY]  = gradient(smoothedBscan);
%                 gradM   = sqrt(gradX.^2 + gradY.^2);
%                 gradAng = atan2(gradY,gradX);
%
%                 laplac = del2(smoothedBscan);
%                 %       #zero of laplac#  &  #big slope#  &         #downward Yslope#
%                 z  = (abs(laplac) < 5E-2) & (gradM > 0.7) & (sin(gradAng) > sin(pi/4));
%                 z(1:meanBM + maxShift + 15,:) = 0;
%                 Infl2 = z;
%                 % END **** ALTERNATIVE INFLEXION POINT SEARCH ****

Infl2 = bwmorph(Infl2,'clean');
Infl2 = imfill(Infl2,'holes');
Infl2 = bwmorph(Infl2,'skel','inf');

Infl2(:,setdiff((1:nCols),(1:colspacing:nCols))) = 0;

Infl2 = bwmorph(Infl2,'shrink','inf');
g     = imextendedmin(filteredBscan,10);

% Not sure about this. Check how it works with one example
Infl2(Infl2 & g) = 0;

nodes = Infl2;

% New edginess based on absolute gradient from unNormalized image
edg = edgeness(origShiftedBscan,scalesize/4,angles+90);

%-% Find CSI
% [CSI, ~] = findCSI(nodes,OG,maxShift,colShifts);
[CSI, ~] = findCSIPiecewise(nodes,OG);

% imshow(bscan,[]), hold on, disp('testing')

% Recompute weights and undo shift from absolute gradient

for k = 1:numel(CSI)

    CSI(k).weight = edg(sub2ind(size(edg),CSI(k).y,CSI(k).x));
%     CSI(k).y = CSI(k).y - colShifts(CSI(k).x) - maxShift;
    
%     errorbar(CSI(k).x,CSI(k).y,normWeight,'.r'), disp('testing')
    
end


end