function [newEndHeights,traces] = ChoroidEndheightRerun(EndHeights,error,numframes,skippedind,Set1,Set2,other,traces,meanCSI)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%%
newEndHeights=nan(numframes,2);

meanColShift = round(mean([other.colshifts],2));

if any(isempty(meanColShift)) || any(isnan(meanColShift))
    return
end

allFrames = 1:numframes;

toSkipFrames = ismember(allFrames,skippedind) | logical(cellfun(@isempty,{other.shiftsize}));
errorFreeFrames    = ~ismember(allFrames,error);

parfor frame = allFrames
% for frame = allFrames
    if toSkipFrames(frame), continue, end
    
    if errorFreeFrames(frame)
        traces(frame).nCSI     = traces(frame).CSI;
        newEndHeights(frame,:) = EndHeights(frame,:);
    end
    
    meanshiftCSI = meanCSI + other(frame).shiftsize + meanColShift;
    
    % Rerun Graph Search
    [traces(frame).nCSI] = FindCSI(Set1{frame},Set2{frame},other(frame).shiftsize,other(frame).colshifts,meanshiftCSI);
    
    %     [traces(frame).nCSI] = FindCSI(Set1{frame},Set2{frame},other(frame).shiftsize,other(frame).colshifts,... %(traces(frame).BM(1)+other(frame).colshifts(1)+other(frame).shiftsize+[commonL commonR])
    %         meanshiftCSI);
    
    if ~isnan(traces(frame).nCSI)
        newEndHeights(frame,:) = [traces(frame).nCSI(1)-traces(frame).BM(1),traces(frame).nCSI(end)-traces(frame).BM(end)];
    end
    
end
end

%