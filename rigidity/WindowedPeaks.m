function [pks,locs,vals,locs2,delta] = WindowedPeaks(trace,peakcut,spacecut,rescut)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
fluct=mean([(max(trace)-mean(trace)) (mean(trace)-min(trace))]);
fluctcut=0;
[pks,locs]=findpeaks(trace,'minpeakheight',peakcut+fluctcut*fluct*~isempty(peakcut),'minpeakdistance',spacecut);
[vals,locs2]=findpeaks(-trace,'minpeakheight',-peakcut+fluctcut*fluct*~isempty(peakcut),'minpeakdistance',spacecut);
vals=-vals;

rem=[];
pklength=length(pks);
%Remove Consecutive Peaks
for i=1:length(pks)-1
    if ~any(locs2>locs(i) & locs(i+1)>locs2)
        if pks(i+1)>pks(i)
            add=i;
        else
            add=i+1;
        end
        rem=[rem;add];
    end
end

for i=1:length(locs)
    if pks(i)<mean(trace(max(1,locs(i)-round(spacecut/2)):locs(i))) || ...
              pks(i)<mean(trace(locs(i):min(length(trace),locs(i)+round(spacecut/2))))
        rem=[rem;i];
    end
end
pks=pks(setdiff(1:pklength,rem));
locs=locs(setdiff(1:pklength,rem));


rem=[];
vallength=length(vals);
%Remove Consecutive Valleys
for i=1:length(vals)-1
    if ~any(locs>locs2(i) & locs2(i+1)>locs)
         if vals(i+1)>vals(i)
            add=i+1;
        else
            add=i;
        end
        rem=[rem;add];
    end
end

for i=1:length(locs2)
    if vals(i)>mean(trace(max(1,locs2(i)-round(spacecut/2)):locs2(i))) || ...
               vals(i)>mean(trace(locs2(i):min(length(trace),locs2(i)+round(spacecut/2))))
        rem=[rem;i];
    end
end

vals=vals(setdiff(1:vallength,rem));
locs2=locs2(setdiff(1:vallength,rem));


if length(pks)>=length(vals)
    for i=1:length(pks)
        left=max(1,i-5);
        right=min(length(pks),i+5);
        maxdist{i}=max(abs(pks(i)-vals(max(1,left):min(right,length(vals)))));
    end
else
    for i=1:length(vals)
        left=max(1,i-5);
        right=min(length(vals),i+5);
        maxdist{i}=max(abs(vals(i)-pks(max(1,left):min(right,length(pks)))));
    end
end

delta=cell2mat(maxdist);
delta=delta(delta>rescut);
delta=mean(delta);
end

