function Affinity = LinePenalty(indx,row,col,connected,points,texture)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


Affinity=zeros(length(connected),1);
[a,b]=size(texture);

[X,Y]=arrayfun(@func_LinePoints,repmat(row(indx),length(connected),1),...
    repmat(col(indx),length(connected),1),...
    row(connected),col(connected),...
    repmat(b,length(connected),1),...
    'uniformoutput',0);

% figure(1)
% imshow(imoverlay(texture,points))
% hold all
% for i=1:length(X)
% plot(Y{i},X{i})
% end


for i=1:length(connected)
    if isempty(X{i}) && col(indx)==0
        Affinity(i)=texture(row(indx),1);
    elseif isempty(X{i}) && col(indx)==b+1
        Affinity(i)=texture(row(indx),b);
    else
    Affinity(i)=mean(texture(sub2ind([a,b],X{i},Y{i})));
    end
end

end

