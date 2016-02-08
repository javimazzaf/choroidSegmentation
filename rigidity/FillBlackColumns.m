function [FixedImage] = FillBlackColumns(Image)
% [JM:20150204] this function counts all-zero columns (BlackR or BlackL) and  
% replaces the last (first) BlackR (BlackL) columns by the previous
% (following) BlackR (BlackL) columns. I think this is to avoid having
% full-zero columns at the start or end of the image, although I'm not sure
% it does the job well. What happens is the empty colums are righ on the
% rectangle we use to replace the ends? This need review, because perhaps
% it is just legacy.
%-------------------------------------------------------------------------%

% HorizDiv=zeros(1,size(Image,2));
% HorizDiv(1:round(end/2))=2;
% HorizDiv(round(end/2)+1:end)=3;
% 
% VertDiv=zeros(size(Image,1),1);
% VertDiv(1:round(end/2))=2;
% VertDiv(round(end/2)+1:end)=3;

    %As each frame is read, VertBars and HorizBars finds all fully zero
    %columns and rows respectively in the uncropped movie;
%     VertBars=~any(Image,2);
    HorizBars=~any(Image);
    %The variables below determine which edge the fully zero columns or 
    %rows belong to, knowing which half of the Div masks were assigned a 
    %value of 2 or 3, and compute their length.
%     BlackBarR=length(find((HorizBars.*HorizDiv)==3));
%     BlackBarL=length(find((HorizBars.*HorizDiv)==2));

%The length of the maximum sized black bar for the whole movie is used to
%crop each edge.

% BlackR=max(BlackBarR);
% BlackL=max(BlackBarL);

BlackR = sum(HorizBars(       1       : round(end/2)));
BlackL = sum(HorizBars(round(end/2)+1 : end));

FixedImage=Image;

% if any(BlackR)
if BlackR ~= 0
    FixedImage(:,end-BlackR+1:end) = fliplr(Image(:,end-(2*BlackR):end-(BlackR+1)));
end
% if any(BlackL)
if BlackL ~= 0
    FixedImage(:,1:BlackL) = fliplr(Image(:,BlackL+1:2*BlackL));
end


end