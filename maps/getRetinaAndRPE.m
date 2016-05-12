function [ret,rpe] = getRetinaAndRPE(im, bits)

im = im / (2^bits-1);

imF = imfilter(im,fspecial('gaussian',[1 10],5));

imStep    = imfilter(imF, heaviside(-11:11)' - 0.5);
imStepInv = - imStep;

imStepInv(imStepInv < 0) = 0;
imStepInv([1:22,end-22:end],:) = 0;

yFirst  = NaN(1,size(imStep,2));
wFirst  = NaN(1,size(imStep,2));
ySecond = NaN(1,size(imStep,2));
wSecond = NaN(1,size(imStep,2));
yThird  = NaN(1,size(imStep,2));
wThird  = NaN(1,size(imStep,2));

for k = 1:size(imStep,2)
    [pks,locs] = findpeaks(imStep(:,k),'SortStr','descend','MinPeakDistance',11);
    if numel(locs) < 2, continue, end
    locs = locs(1:2);
    pks = pks(1:2);
    
    [locs, ix] = sort(locs);
    pks        = pks(ix);
    
    yFirst(k)  = locs(1);
    wFirst(k)  = pks(1);
    ySecond(k) = locs(2);
    wSecond(k) = pks(2);
    
    [pks,locs] = findpeaks(imStepInv(:,k),'SortStr','descend','MinPeakDistance',11);
    
    ix = find(locs > ySecond(k),1,'first');
    if isempty(ix), continue, end
    
    yThird(k) = locs(ix);
    wThird(k) = pks(ix);

end

% Remove outliers
yFirst  = eliminateJumps(yFirst,wFirst);
ySecond = eliminateJumps(ySecond,wSecond);
yThird  = eliminateJumps(yThird,wThird);

% Use graph-based segmentation to trace the RPE
[rpeMask,rpeWeigth] = makeRPEmask(imF, ySecond, yThird, yFirst);
[aC,bC,aIm,bIm,imind,edges,num] = ConnectivityMatrix(rpeMask,8);
[x,y] = traceGraph(aC,bC,aIm,bIm,imind,num,edges,rpeWeigth);

% Compute a convex-hull below the RPE to avoid following the Drusen
DT = DelaunayTri(x,y);
CH = convexHull(DT);
CHpts = flipud([DT.X(CH,1) DT.X(CH,2)]);
last = find(CHpts(:,1) < circshift(CHpts(:,1),1),1,'first') - 1;
CHcurve = fit(CHpts(1:last,1),CHpts(1:last,2),'linear');
CHcurve = round(CHcurve(1:size(imStep,2)));

% Set results
ret = yFirst;  % First retina layer
rpe = CHcurve; % Estimation of bottom RPE

end

function [x,y] = traceGraph(aC,bC,aIm,bIm,imind,num,edges,bscan)

bscan = mat2gray(double(bscan));
[m,n] = size(bscan);

startedge=edges(:,1);
endedge=edges(:,2);
startlength=length(find(startedge));
endlength=length(find(endedge));

% DL = - imfilter(bscan,[-1;1],'symmetric');
DL = bscan;
DL(DL<0)=0;
DL=mat2gray(DL);


s=zeros(size(aC));
s(aC~=1 & bC~=num) = 2 - (DL(aIm) + DL(bIm));
s(1:startlength)=1;
s(length(s)-endlength+1:length(s))=1;
% Each element in s correspond to a graph edge
C=sparse(aC,bC,s,num,num);
[~,path,~]=graphshortestpath(C,1,num); %path is the index in the nodes array
[y,x]=ind2sub([m,n],imind(path(2:end-1)-1));

check=[[x;0] [0;x]];
check=(check(:,1)==check(:,2));
check=find(check);
y=y(setdiff(1:length(x),check));
x=x(setdiff(1:length(x),check));

end

function [msk,outWeigth] = makeRPEmask(inWeigth,top, bottom, retina)

% Creates a mask with foreground pixels in a strip between "top" and
% "bottom" traces. It fills up the columns that do not have data for the
% traces with the nearest column information

sz = size(inWeigth);

msk = zeros(sz);

outWeigth = inWeigth;

% Find the start and end of all the traces together
start = find(~isnan(top) & ~isnan(bottom) & ~isnan(retina),1,'first');
fin   = find(~isnan(top) & ~isnan(bottom) & ~isnan(retina),1,'last');

% Computes the absolut top limit of the region (halfway between retina and RPE)
gapTop = median(top - retina) / 2;
topLim = round(min(top, retina + gapTop));

% Computes the absolut bottom limit of the region (halfway between RPE and bottom of image)
gapBot = median(sz(1) - bottom) / 2;
botLim = round(max(sz(1) - gapBot, bottom));

for k = start:fin
    msk(topLim(k):botLim(k),k) = true;
    outWeigth([1:top(k),bottom(k):end],k) = 0.1 * outWeigth([1:top(k),bottom(k):end],k);
end

% Fill up gaps at start and end
if start ~= 1
    msk(topLim(start):botLim(start),1  :start) = true; 
    
    rng = [1:top(start),bottom(start):sz(1)];
    outWeigth(rng,1:start) = 0.1 * outWeigth(rng,1:start);
end


if fin ~= sz(2)
    msk(topLim(fin):botLim(fin),fin:end)   = true; 
    
    rng = [1:top(fin),bottom(fin):sz(1)];
    outWeigth(rng,fin:end) = 0.1 * outWeigth(rng,fin:end);
    
end

end

function traceOut = eliminateJumps(traceIn, weights)

len = length(traceIn);

msk = ~isnan(traceIn);

% plot(traceIn), hold on

x = 1:numel(traceIn);
x = x(msk);
weights = weights(msk);
traceIn = traceIn(msk);

fitOptions = fitoptions('poly5');

fitOptions.Weights = weights / sum(weights);
fitOptions.Normalize = 'on';

fitobject = fit(x(:),traceIn(:),'poly5',fitOptions);

yfit = feval(fitobject,x);

% plot(yfit)

dev = abs(traceIn(:) - yfit(:));

threshold = 5 * median(dev);

valid = abs(traceIn(:) - yfit(:)) < threshold;

x = x(valid);
traceIn = traceIn(valid);

% traceOut = interp1(x,traceIn,1:numel(msk));
traceOut = interp1(x,traceIn,1:len);

traceOut = round(traceOut);

end