function [CroppedImage,CropSize] = Crop2(Image)
%-------------------------------------------------------------------------%



HorizDiv=zeros(1,size(Image,2));
HorizDiv(1:end/2)=2;
HorizDiv(end/2+1:end)=3;

VertDiv=zeros(size(Image,1),1);
VertDiv(1:end/2)=2;
VertDiv(end/2+1:end)=3;

    %As each frame is read, VertBars and HorizBars finds all fully zero
    %columns and rows respectively in the uncropped movie;
    VertBars=~any(Image,2);
    HorizBars=~any(Image);
    %The variables below determine which edge the fully zero columns or 
    %rows belong to, knowing which half of the Div masks were assigned a 
    %value of 2 or 3, and compute their length.
    BlackBarTop=length(find((VertBars.*VertDiv)==2));
    BlackBarBottom=length(find((VertBars.*VertDiv)==3));
    BlackBarR=length(find((HorizBars.*HorizDiv)==3));
    BlackBarL=length(find((HorizBars.*HorizDiv)==2));


%The length of the maximum sized black bar for the whole movie is used to
%crop each edge.
CutTop=max(BlackBarTop);
CutBot=max(BlackBarBottom);
CutR=max(BlackBarR);
CutL=max(BlackBarL);
CropSize=[CutTop CutBot CutR CutL];

CroppedImage=Image(CutTop+1:end-CutBot,CutL+1:end-CutR,:);

end