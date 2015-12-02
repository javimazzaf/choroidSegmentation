function [isValid, faThreshold, f, P] = checkValidSpectrum(t,signal,HR,po)

% Checks if the series "signal", sampled at "t" values has a frequency
% component at HR, that is significant at p = po.
% I uses ideas on the paper: 
% J.Scargle, Studies in astronomical time series analysis. II - Statistical
% aspects of spectral analysis of unevenly spaced data. The astronomical
% journal, 263:835-853, (1982).
% In particular it uses Eq.10 to compute the periodogram, and Eq.19 to
% compute the false alarm probability. 
% It starts by analizing the window function for the sampling given by "t".
% The main peak of the window is used to define the frequency spacing to 
% compute the periodogram of the signal (FWHM / 2), to avoid oversampling.
% In this way the detection efficiency is maximized without reducing the
% probability to loose the peak at the Heart Rate. See section 3.d of the
% paper.

% Since the noise level (sigma0) is unknown, it is estimated from the full spectrum
% of signal by fitting the histogram to an exponential distribution.
% Then the periodogram of the signal is analized only in a small interval
% around the HR, and the maximum peak is compared to the false alarm
% theshold zo to assess if the peak is significant.

% Javier Mazzaferri, 2015DEC01
% javier.mazzaferri@gmail.com

% Set time to start at 0, and remove mean value from signal.
t        = t(:) - t(1);
amplitud = signal(:) - mean(signal);

deltaT   = min(diff(t));      % Minimal time interval
niquistF = 1 / (2 * deltaT);  % Niquist frequency

% Analyze window function
[fmin, fmax, fStep] = getFreqInterval(t,HR);

[f, P] = lsperiodogram(t,amplitud.*hamming(numel(amplitud)),2*pi*(fStep:fStep:niquistF),numel(fStep:fStep:niquistF));

loF = fmin - 2 * fStep;
hiF = fmax + 2 * fStep;

isValid     = false;
faThreshold = inf;

if isempty(f) || isempty(P),  return, end

[pks,locs] = findpeaks(P);
fpks = f(locs);

% Count peaks explored around heartFreq
nFreq = sum((f < hiF) & (f > loF));

% Subset the peaks in the search frequency region
msk = (fpks < hiF) & (fpks > loF);
if ~any(msk), return, end

% Gets the hight of the candidate peak
mxPeak = max(pks(msk));

% Computes the false alarm threshold 
faThreshold = getFalseAlarmThreshold(P,1,po,nFreq);

% Data is valid if the peak is higher than the threshold for the required
% confidence po.

isValid = mxPeak > faThreshold;

end

function [fmin, fmax, fStep] = getFreqInterval(t,f)

% Studies the window function for the time intervals in t, when measuring
% the frequency f. It is used to compute the sampling frequency

% Single harmonic function sampled at the times t
singleHarmonic = cos(2*pi*f*t);

% Raw estimation of the window width.
estimFstep = 1/(range(t));

% Defines a range of frequencies to evaluate the window function
fqs = linspace(f - 10 * estimFstep, f + 10 * estimFstep,1000);

% Computes the window function
[fqs, Fref] = lsperiodogram(t,singleHarmonic.*hamming(numel(singleHarmonic)),2*pi*fqs,numel(fqs));

% Measures the width at half maximum of the peak at f
[mx,mxPos] = max(Fref);
msk        = Fref/mx > 0.5;
lowLim     = find(~msk(1:mxPos),1,'last') + 1;
hiLim      = find(~msk(mxPos:end),1,'first') + mxPos - 2;

fmax = fqs(hiLim);
fmin = fqs(lowLim);

fStep = (fmax - fmin)/2;

end

function [isValid, zo] = hasPeak(f,P,loF,hiF)

isValid = false;
zo = inf;

if isempty(f) || isempty(P),  return, end

[pks,locs] = findpeaks(P);
fpks = f(locs);

% Count peaks explored around heartFreq
nFreq = sum((f < hiF) & (f > loF));

% Subset the peaks in the search frequency region
msk = (fpks < hiF) & (fpks > loF);
if ~any(msk), return, end

% Gets the hight of the candidate peak
mxPeak = max(pks(msk));

% Computes the false alarm threshold 
zo = getFalseAlarmThreshold(P,1,0.05,nFreq);

% Data is valid if the peak is higher than the threshold for the required
% confidence po.

isValid = mxPeak > zo;

end

function [falseAlarmThreshold] = getFalseAlarmThreshold(vals,corrWindow,po,nPks)

% vals : array containing the lomb-scargle periodogram
% corrWindow: estimated width of the peaks
% po: required false alarm probability (ex 0.05)
% nPks: number of frequencies explored to observe the peak of interest

%Estimates noise level from the values of the spectrum. 

%first: Downsample to get rid of correlation between 
uncorrValues = vals(1:corrWindow:end);

%Second: get rid of hight peaks to favor noise to signal
lowValues = uncorrValues(uncorrValues < prctile(uncorrValues,95));

%Compute noise hstogram
[h,x] = hist(lowValues,10);

% Assumming the ditribution is exponential exp(-x / var), get the variance of underlaying
% noise in the signal. Assumes also that the noise of the original signal is
% normal.

logH    = log(h);
errLogH = 1./sqrt(h);

fo = fit(x',logH','poly1','Weights',1./errLogH);
var0 = - 1 / fo.p1;

falseAlarmThreshold = log(nPks/po) * var0;

end