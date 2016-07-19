function [ret,bm] = getRetinaAndBM(im, bits)

im = im / (2^bits-1);

imF = imfilter(im,fspecial('gaussian',[1 10],5));

imStep    = imfilter(imF, heaviside(-11:11)' - 0.5);
imStepInv = - imStep;

imStepInv(imStepInv < 0) = 0;
imStepInv([1:22,end-22:end],:) = 0;

% Reduce smoothing to get better precision
imStepPrecise = - imfilter(imF, heaviside(-2:2)' - 0.5);
imStepPrecise(imStepPrecise < 0) = 0;
imStepPrecise([1:22,end-22:end],:) = 0;

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
    
    
%     [pks,locs] = findpeaks(imStepPrecise(:,k),'SortStr','descend','MinPeakDistance',11);
    [pks,locs] = findpeaks(imStepInv(:,k),'SortStr','descend','MinPeakDistance',11);
    
    ix = find(locs > ySecond(k),1,'first');
    if isempty(ix), continue, end
    
    yThird(k) = locs(ix);
    wThird(k) = pks(ix);

end

% Remove outliers
yFirst  = eliminateJumps(yFirst,wFirst);

% Refine RPE
RPEthickness = yThird - ySecond;
medianRPEthickness = nanmedian(RPEthickness);
stdRPEthickness = nanstd(RPEthickness);
rpeMskWrong = RPEthickness > (medianRPEthickness + 3 * stdRPEthickness) |...
              RPEthickness < (medianRPEthickness - 3 * stdRPEthickness); 
         
ySecond(rpeMskWrong) = NaN; 
wSecond(rpeMskWrong) = NaN; 
 
yThird(rpeMskWrong)  = NaN;
wThird(rpeMskWrong) = NaN;

ySecond = eliminateJumps(ySecond,wSecond);
yThird  = eliminateJumps(yThird,wThird);

[xBM,yBM] = findRPEbottom(imF,imStepPrecise,ySecond, yThird);

% % Use graph-based segmentation to trace the RPE
% [rpeMask,rpeWeigth] = makeRPEmask(imF, imF, ySecond, yThird, yFirst);
% % [rpeMask,rpeWeigth] = makeRPEmask(imF, ySecond, yThird, yFirst);
% [aC,bC,aIm,bIm,imind,edges,num] = ConnectivityMatrix(rpeMask,8);
% [xRPE,yRPE] = traceGraph(aC,bC,aIm,bIm,imind,num,edges,rpeWeigth);
% 
% % Use graph-based segmentation to trace the RPE bottom limit with higher
% % precision
% [rpeBotMask,rpeBotWeigth] = makeRPEmask(imF, imStepPrecise, ySecond, yThird, yFirst);
% % [rpeMask,rpeWeigth] = makeRPEmask(imF, ySecond, yThird, yFirst);
% [aC,bC,aIm,bIm,imind,edges,num] = ConnectivityMatrix(rpeBotMask,8);
% [xBotRPE,yBotRPE] = traceGraph(aC,bC,aIm,bIm,imind,num,edges,rpeBotWeigth);
% 
% % Eliminate points that are too far apart from the RPE
% dev = abs(yBotRPE - yRPE);
% mskValid = dev <= max(nanmedian(dev) * 3,1);
% xBotRPE = xBotRPE(mskValid);
% yBotRPE = yBotRPE(mskValid);


% Compute a convex-hull below the RPE bottom limit to estimate the Bruch's
% membrane
DT = DelaunayTri(xBM(:),yBM(:));
CH = convexHull(DT);
CHpts = flipud([DT.X(CH,1) DT.X(CH,2)]);
last = find(CHpts(:,1) < circshift(CHpts(:,1),1),1,'first') - 1;
CHcurve = fit(CHpts(1:last,1),CHpts(1:last,2),'linear');
CHcurve = round(CHcurve(1:size(imStep,2)));

% Set results
ret = yFirst;  % First retina layer
bm  = CHcurve; % Estimation of Bruch's membrane
% 
% hf = figure;
% imshow(im,[]), hold on
% % plot(xBM,yBM);
% plot(bm)
% close(hf)

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

function [msk,outWeigth] = makeRPEmask(imOri,inWeigth,top, bottom, retina)

% Creates a mask with foreground pixels in a strip between "top" and
% "bottom" traces. It fills up the columns that do not have data for the
% traces with the nearest column information

sz = size(inWeigth);

msk = zeros(sz);

outWeigth = inWeigth;

% Find the start and end of all the traces together
start = find(~isnan(top) & ~isnan(bottom) & ~isnan(retina),1,'first');
fin   = find(~isnan(top) & ~isnan(bottom) & ~isnan(retina),1,'last');

rpeThickness = nanmedian(bottom - top);

% Computes the absolut top limit of the region (halfway between retina and RPE)
% gapTop = nanmedian(top - retina) / 2;
% topLim = round(min(top, retina + gapTop));
topLim = NaN(size(top));

for k = start:fin
      topLim(k) = round(sum(imOri(top(k):bottom(k),k) .* (top(k):bottom(k))') / sum(imOri(top(k):bottom(k),k)));
end

% Computes the absolut bottom limit of the region (halfway between RPE and bottom of image)
% gapBot = nanmedian(sz(1) - bottom) / 2;
% botLim = round(max(sz(1) - gapBot, bottom));
botLim = round(min(sz(1), bottom + rpeThickness / 2));

for k = start:fin
      msk(topLim(k):botLim(k),k) = true;
%     msk(topLim(k):botLim(k),k) = true;
%     outWeigth([1:top(k),bottom(k):end],k) = 0.1 * outWeigth([1:top(k),bottom(k):end],k);
end

% Fill up gaps at start and end
if start ~= 1
    msk(topLim(start):botLim(start),1  :start) = true; 
    
%     rng = [1:top(start),bottom(start):sz(1)];
%     outWeigth(rng,1:start) = 0.1 * outWeigth(rng,1:start);
end


if fin ~= sz(2)
    msk(topLim(fin):botLim(fin),fin:end)   = true; 
    
%     rng = [1:top(fin),bottom(fin):sz(1)];
%     outWeigth(rng,fin:end) = 0.1 * outWeigth(rng,fin:end);
    
end

outWeigth(~msk) = 0.1 * outWeigth(~msk); 

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
traceOut = interp1(x,traceIn,1:len,'linear','extrap');

traceOut = round(traceOut);

end

function [xOut,traceOut] = findRPEbottom(imOri,invGrad,top, bottom)

sz = size(invGrad);

msk = false(sz);

% Find the start and end of all the traces together
start = find(~isnan(top) & ~isnan(bottom),1,'first');
fin   = find(~isnan(top) & ~isnan(bottom),1,'last');

top(1:start) = top(start);
top(fin:end) = top(fin);
bottom(1:start) = bottom(start);
bottom(fin:end) = bottom(fin);
% Computes RPE msk

for k = 1:numel(top)
      msk(top(k):bottom(k),k) = true;
end

wInt = imOri(msk);
wInt = (wInt - min(wInt)) / (max(wInt) - min(wInt)); 

wMatrix = zeros(size(msk));
wMatrix(msk) = wInt;

[aC,bC,aIm,bIm,imind,edges,num] = ConnectivityMatrix(msk,8);
[xRPE,yRPE] = traceGraph(aC,bC,aIm,bIm,imind,num,edges,wMatrix);

xRPE = round(xRPE);
yRPE = round(yRPE);

ix = sub2ind(size(imOri),yRPE,xRPE);
wRPE = imOri(ix);

% Refine BM
yRPE = eliminateJumps(yRPE, wRPE);

% Estimates the bottom edge of the RPE
rpeThickness = nanmedian(bottom - top);

botLim = round(min(sz(1), yRPE + rpeThickness));
msk(:) = false;

for k = 1:numel(yRPE)
      msk(yRPE(k):botLim(k),k) = true;
end

wGrad = invGrad(msk);
wGrad = (wGrad - min(wGrad)) / (max(wGrad) - min(wGrad)); 

wMatrix = zeros(size(msk));
wMatrix(msk) = wGrad;

[aC,bC,aIm,bIm,imind,edges,num] = ConnectivityMatrix(msk,8);
[xBot,yBot] = traceGraph(aC,bC,aIm,bIm,imind,num,edges,wMatrix);

% Estimated distance to BM

estDistBM = nanmedian(yBot' - yRPE(xBot));
xOut = 1:numel(yRPE);
traceOut = yRPE + estDistBM;

% [x,y] = meshgrid(1:sz(2),1:sz(1));
% x = x(msk);
% y = y(msk);
% 
% d = NaN(size(x));
% 
% for k = 1:numel(x)
%     d(k) = y(k) - expTrace(x(k));    
% end
% 
% 
% wDist = gaussmf(d,[rpeThickness/2,0]);
% fact = 0.75;
% weight = fact * wGrad + (1 - fact) * wDist;
% 
% wMatrix(msk) = weight;
% [xBM,yBM] = traceGraph(aC,bC,aIm,bIm,imind,num,edges,wMatrix);




end