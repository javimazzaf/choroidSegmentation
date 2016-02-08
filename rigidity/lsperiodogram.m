function [frec, Periodogram] = lsperiodogram(t,y,wFun,nW)

% Based on J.Scargle, Studies in astronomical time series analysis. II - Statistical
% aspects of spectral analysis of unevenly spaced data. The astronomical
% journal, 263:835-853, (1982).

% Using Eq.10, for the modified Periodogram. It gives the Power spectrum,
% which is a real positive squared qunatity. No phase is estimated. It is
% not meant to filter and reconstruct the function, but only to check if
% there are specific frequency components.

% Javier Mazzaferri
% 2015DEC01

% These tolerance is set according to Scargle's Fortran code.
tol1 = 1E-4;

% Sort and reshape data to column vectors
[t, ix] = sort(t(:));
y = y(:);
y = y(ix);

N = length(t);

tZero = t(1);

t = t - tZero;

% Set default fundamental frequency
if ~exist('wFun','var')
    % Compute fundamental frequency based on the range of times
    tP = range(t) * N / (N - 1);
    wFun = 2 * pi / tP;
    
    % Recommended for computing correlations (may change later)
    wFun = wFun / 2;
    
    ws = (0:nW-1) * wFun / nW;
end

% Set default number of frequencies
if ~exist('nW','var')
    nW = N;
end

% If only one frequency is asked, it takes the value from wFun
if nW == 1
    frec        = wFun / 2 / pi;
    Periodogram = computeSingleComponent(wFun,t,y,tol1);
    return
end

% Allocates arrays twice as large as nW
Periodogram = zeros(nW,1);

% Periodogram(1) = sum(y) / sqrt(N);

ws = wFun;

% Iteration over frequencies
for k = 1:nW

    if (ws(k) == 0)
        Periodogram(k) = mean(y) ^ 2;
    else
        Periodogram(k) = computeSingleComponent(ws(k),t,y,tol1);
    end
      
end

frec = ws / 2 / pi; 

end

function peak = computeSingleComponent(w,times,signal,tolerance)

    % Compute Tau
    arg = 2 * w * times; %2wt
    
    cosArg = cos(arg);
    sinArg = sin(arg);
    
    cosSum = sum(cosArg);
    sinSum = sum(sinArg);
    
    if abs(sinSum) <= tolerance && abs(cosSum) <= tolerance
        tCosSum = sum(times .* cosArg);
        tSinSum = sum(times .* sinArg);
        wAtan = atan2(- tCosSum,tSinSum); %Use L'Hopital for 0/0 (differentiate respect to w)
    else
        wAtan = atan2(sinSum,cosSum); 
    end
    
    wTau = 0.5 * wAtan;
    wtNew = wTau;
    
    arg = w * times - wtNew;
    cosArg = cos(arg);
    sinArg = sin(arg);
    
    cos2Sum   = sum(cosArg.^2);
    sin2Sum   = sum(sinArg.^2);
    
    realSum = sum(signal .* cosArg);
    imagSum = sum(signal .* sinArg);
    
    peak = 0.5 * (realSum^2 / cos2Sum + imagSum^2 / sin2Sum);

end