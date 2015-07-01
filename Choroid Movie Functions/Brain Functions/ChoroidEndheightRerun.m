function [newEndHeights,traces] = ChoroidEndheightRerun(EndHeights,error,numframes,skippedind,Set1,Set2,other,traces,meanCSI)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%%
newEndHeights=nan(numframes,2);

parfor frame=1:numframes
    if ismember(frame,skippedind) 
        continue
    elseif ~ismember(frame,error)
        traces(frame).nCSI=traces(frame).CSI;
        newEndHeights(frame,:)=EndHeights(frame,:);
    end
    meanshiftCSI=meanCSI+other(frame).shiftsize+round(mean([other.colshifts],2));
    % Rerun Graph Search
    [traces(frame).nCSI]=FindCSI(Set1{frame},Set2{frame},other(frame).shiftsize,other(frame).colshifts,... %(traces(frame).BM(1)+other(frame).colshifts(1)+other(frame).shiftsize+[commonL commonR])
        meanshiftCSI);
    
    % Error Checking
    if isnan(traces(frame).nCSI)
        continue
    else
        newEndHeights(frame,:)=[traces(frame).nCSI(1)-traces(frame).BM(1),traces(frame).nCSI(end)-traces(frame).BM(end)];
    end
end
end

% numbins=30;
% [nL,cL]=hist(EndHeights(EndHeights(:,1)~=0,1),numbins);
% [nR,cR]=hist(EndHeights(EndHeights(:,2)~=0,2),numbins);
% 
% commonL=cL(nL==max(nL));
% if numel(commonL)>1;
%     binnums=find(ismember(cL,commonL));
%     neighbins=[binnums+1;binnums-1];
%     for i=1:length(binnums)
%         neighbcounts(i)=sum(nL(neighbins(neighbins(:,i)>0 & neighbins(:,i) <numbins,i)));
%     end
%     decider=neighbcounts==max(neighbcounts);
%     if numel(find(decider))>1
%         commonL=round(max(commonL));
%     else
%         commonL=round(commonL(decider));
%     end
% else
%     commonL=round(commonL);
% end
% 
% commonR=cR(nR==max(nR));
% if numel(commonR)>1
%     binnums=find(ismember(cR,commonR));
%     neighbins=[binnums+1;binnums-1];
%     for i=1:length(binnums)
%         neighbcounts(i)=sum(nR(neighbins(neighbins(:,i)>0 & neighbins(:,i) <numbins,i)));
%     end
%     decider=neighbcounts==max(neighbcounts);
%     if numel(find(decider))>1;
%         commonR=round(max(commonR));
%     else
%         commonR=round(commonR(decider));
%     end
% else
%     commonR=round(commonR);
% end