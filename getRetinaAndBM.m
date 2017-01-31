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

function [ret,bm] = getRetinaAndBM(im, bits)

sz = size(im);

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
    
    [pks,locs] = findpeaks(imStepInv(:,k),'SortStr','descend','MinPeakDistance',11);
    
    ix = find(locs > ySecond(k),1,'first');
    if isempty(ix), continue, end
    
    yThird(k) = locs(ix);
    wThird(k) = pks(ix);

end

% Remove outliers
yFirst  = eliminateJumps(yFirst,wFirst,sz);

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

ySecond = eliminateJumps(ySecond,wSecond,sz);
yThird  = eliminateJumps(yThird,wThird,sz);

[xBM,yBM] = findRPEbottom(imF,imStepPrecise,ySecond, yThird);

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

end

function [x,y] = traceGraph(aC,bC,aIm,bIm,imind,num,edges,bscan)

bscan = mat2gray(double(bscan));
[m,n] = size(bscan);

startedge=edges(:,1);
endedge=edges(:,2);
startlength=length(find(startedge));
endlength=length(find(endedge));

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
topLim = NaN(size(top));

for k = start:fin
      topLim(k) = round(sum(imOri(top(k):bottom(k),k) .* (top(k):bottom(k))') / sum(imOri(top(k):bottom(k),k)));
end

% Computes the absolut bottom limit of the region (halfway between RPE and bottom of image)
botLim = round(min(sz(1), bottom + rpeThickness / 2));

for k = start:fin
      msk(topLim(k):botLim(k),k) = true;
end

% Fill up gaps at start and end
if start ~= 1
    msk(topLim(start):botLim(start),1  :start) = true; 
end


if fin ~= sz(2)
    msk(topLim(fin):botLim(fin),fin:end)   = true; 
end

outWeigth(~msk) = 0.1 * outWeigth(~msk); 

end

function traceOut = eliminateJumps(traceIn, weights,sz)

len = length(traceIn);

msk = ~isnan(traceIn);

x = 1:numel(traceIn);
x = x(msk);
weights = weights(msk);
traceIn = traceIn(msk);

fitOptions = fitoptions('poly5');

fitOptions.Weights = weights / sum(weights);
fitOptions.Normalize = 'on';

fitobject = fit(x(:),traceIn(:),'poly5',fitOptions);

yfit = feval(fitobject,x);

dev = abs(traceIn(:) - yfit(:));

threshold = 5 * median(dev);

valid = abs(traceIn(:) - yfit(:)) < threshold;

x = x(valid);
traceIn = traceIn(valid);

traceOut = interp1(x,traceIn,1:len,'linear');

% Extrapolate using the nearest neighbour
start = find(~isnan(traceOut),1,'first');
fin   = find(~isnan(traceOut),1,'last');

traceOut(1:start) = traceOut(start);
traceOut(fin+1:end) = traceOut(fin);

traceOut = round(traceOut);
traceOut = max(1,min(sz(1),traceOut)); % Coerce to image limits

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
yRPE = eliminateJumps(yRPE, wRPE,sz);

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

end