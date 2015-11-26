function isValid = hasFrequencyPeakAtHR(f,P,heartFreq)

isValid = false;

if isempty(f) || isempty(P),  return, end

[pks,locs] = findpeaks(P);

fpks = f(locs);

msk = (fpks > 0.5 * heartFreq) & (fpks < 3 * heartFreq);

fpks = fpks(msk);
pks  = pks(msk);

if isempty(pks), return, end

[~, ix] = max(pks);

freqDist = abs(fpks(ix) - heartFreq);

isValid = freqDist < 0.1 * heartFreq;

end