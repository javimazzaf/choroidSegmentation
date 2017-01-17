function Affinity = linePenalty(indx,row,col,connected,texture)


Affinity=zeros(length(connected),1);
[a,b]=size(texture);

[X,Y]=arrayfun(@func_LinePoints,repmat(row(indx),length(connected),1),...
    repmat(col(indx),length(connected),1),...
    row(connected),col(connected),...
    repmat(b,length(connected),1),...
    'uniformoutput',0);


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

