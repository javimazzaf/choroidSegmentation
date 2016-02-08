function computeResultsPiecewise(varargin)

% Computes the results of choroid thickness and Ocular Rigidity using the
% piecewise approach.

% Arguments:
%  - relativePathData: cell array of strings with the path of all
%                      patients to compute results from.
%  - Base for data path (opt): String with a base path where to find the
%                              data. It is for debugging purpose if the
%                              results of first and post process have been
%                              stored in a non-default folder. If ommitted
%                              it uses the default path in HMR-Brain:
%                              /srv/samba/share . . .

if nargin == 0
    throw(MException('computeResultsPiecewise:NotEnoughArguments','Not enough arguments.'))
end

if      ispc,   baseDir = [filesep filesep 'HMR-BRAIN'];
 elseif ismac,  baseDir = [filesep 'Volumes'];
 else           baseDir = [filesep 'srv' filesep 'samba'];
end

originDirs = fullfile(baseDir,varargin{1});

if nargin >=2
    dirlist    = fullfile(varargin{2},varargin{1});
else
    dirlist    = originDirs;
end



% *** Code starts ***

for iter=1:length(dirlist)
    try
        oriDir    = originDirs{iter};
        directory = dirlist{iter};
        savedir   = fullfile(directory,'Results');
        
        disp(logit(savedir,['computeResultsPiecewise - Starting: ' savedir]))
        
        load(fullfile(savedir,'FirstProcessData.mat'),'traces');
        
        numframes = numel(traces);
        validCSI = find(cellfun(@(x) isstruct(x) && ~isempty(x),{traces(:).CSI}));
        
        % Build thickness series for each region.
        
        nRegions   = getParameter('PIECEWISE_REGIONS_NUMBER');
        nCols      = numel(traces(validCSI(1)).BM);
        regionStep = floor(double(nCols) / nRegions);
        
        regionsEnd = 0:regionStep:nCols;
        regionsEnd(end) = max(regionsEnd(end),nCols);
        
        thickness = NaN(numframes,numel(regionsEnd)-1);
        
        for frame = 1:numframes
            if ~ismember(frame,validCSI), continue, end
            
            BM   = traces(frame).BM;
            xCSI = [];
            yCSI = [];
            wCSI = [];
            
            for s = 1:numel(traces(frame).CSI)
                segm = traces(frame).CSI(s);
                if ~(segm.keep), continue, end
                
                xCSI = [xCSI; segm.x];
                yCSI = [yCSI; segm.y];
                wCSI = [wCSI; segm.weight];
            end
            
            for r = 2:numel(regionsEnd)
                left = regionsEnd(r-1);
                righ = regionsEnd(r);
                
                msk = (xCSI > left) & (xCSI <= righ);
                
                if sum(msk) == 0, continue, end
                
                thisThickness = yCSI(msk) - BM(round(xCSI(msk)));
                
                thickness(frame,r-1) = sum(thisThickness .* wCSI(msk)) / sum(wCSI(msk));
            end
            
        end
        
        
        % Gets heart-rate
        HR = GetHeartRate(oriDir) / 60;
        
        load(fullfile(oriDir,'Data Files','ImageList.mat'),'ImageList');
        imtime = 60 * [ImageList.minute] + [ImageList.second];
        %         imtime = imtime(validCSI);
        imtime = imtime - imtime(1);
        
        po = getParameter('SPECTRUM_PEAK_P0');
        
        CT  = NaN(numel(regionsEnd)-1, 1);
        dCT = NaN(numel(regionsEnd)-1, 1);
        p   = NaN(numel(regionsEnd)-1, 1);
        
        % Analyze regions
        for r = 1:numel(regionsEnd)-1
            y = thickness(:,r);
            t = imtime(:);
            
            msk = ~isnan(y);
            y = y(msk);
            t = t(msk);
            
            % Checks if the signal has a significant component at HR
            
            [~, faProb, fr, Powers] = checkValidSpectrum(t,y,HR,po);
            
%             plot(fr, Powers), hold on
%             line([1 1] * HR, ylim(), 'Color','r')
%             title(faProb)
%             hold off
            
            p(r) = faProb;
            
            [dCT(r),CT(r)] = measureThickness(t',y,2,6, HR);
            
        end
        
        msk = p <= po;
        
        if any(msk) 
            meanCT = nanmean(CT(msk));
            eCT    = nanstd(CT(msk));
            
            meanDCT = nanmean(dCT(msk));
            eDCT    = nanstd(dCT(msk));
            
            [OR, dV] = computeRigidity(meanDCT, oriDir);
        else
            meanCT = NaN;
            eCT    = NaN;
            
            meanDCT = NaN;
            eDCT    = NaN;
            
            dV      = NaN;
            
            OR      = NaN;
        end
        
        save(fullfile(directory,'Results','Results.mat'),'CT','dCT','p', 'po', 'dV','OR','eCT','eDCT');
        
        disp(logit(savedir,['computeResultsPiecewise - Done: ' savedir]))
        
    catch exception
        errString = ['Error computeResultsPiecewise: ' savedir '. ' exception.message ' - ' buildCallStack(exception)];
        disp(logit(savedir,errString))
        continue
    end
    
end
end

function [OR, dV] = computeRigidity(dCT, directory)

load(fullfile(directory,'Data Files','VisitData.mat'));

IOP = visitdata.PascalIOP{:};
OPA = visitdata.PascalOPA{:};
R   = visitdata.AL{:} / 2;

dV  = (pi * R^2 * dCT);

OR = log((IOP+OPA)/(IOP))/dV; % 1/uL

end

function [meanAmplitud,meanThickness] = measureThickness(sT,sFn,hifac,ofac, fHR)

% FastLomb + Cleaning
[wk1,~,~,~,F] = lspr(sT,(sFn-mean(sFn)).*hamming(numel(sFn)),hifac,ofac);

% Manipulation of the Fourier spectrum F:
Fo = F;
f=(1:length(F)) * (wk1(2) - wk1(1))';
minf=.50*fHR;
maxf=fHR*3.1;
endf=2*f(end);

% Metric of Correlation
Fpeak=max(abs(F(f>(fHR-0.1) & f<(fHR+0.1))));
SNR=Fpeak/std(abs(F(f>minf & f<(endf-0.5))));


% Remove noise
noise_limit = max(abs(F((f>minf & f<maxf) | (f<(endf-minf) & f>(endf-maxf)))))/10;
ind = abs(F) < noise_limit ;
F(ind)=0; F(1)=Fo(1);
F(f<minf | (f>maxf & f<(endf-maxf)) | f>(endf-minf))=0;

% inverse Fourier transform
Fb=ifft(F);
filteredThickness=real(Fb);

%Correct time scale
tf = sT(1)+[0 (1:length(F))/(wk1(2)-wk1(1))/length(F)];
ind = find(tf < sT(end));
tf=tf(ind);
filteredThickness = ((filteredThickness(ind)-mean(filteredThickness(ind)))./(hamming(length(tf))')+mean(sFn))';

[~,~,~,~,meanAmplitud] = WindowedPeaks(filteredThickness,mean(filteredThickness),...
    round((fHR/3)/mode(diff(sT))),0.0039);

meanThickness = mean(filteredThickness);

end


