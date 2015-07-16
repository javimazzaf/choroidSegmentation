function [Pb,padPb] = EdgeProbabilityGrad(shiftbscan,scalesize,angles,midlevel,shiftsize)
% Computes the edge probability

[m,n]=size(shiftbscan);
colcount=zeros(1,n);
for j=30:n-28
    for i=m:-1:midlevel+shiftsize
        if shiftbscan(i,j)==0
            colcount(j)=colcount(j)+1;
        else
            break
        end
    end
end

maxblack=max(colcount(colcount<(m-(midlevel+shiftsize))/3))+5;

BMdist=5;

edg = edgeness(shiftbscan,scalesize/4,angles+90); %Testing
edg(edg < 0) = 0;

I = zeros(size(edg));
validRows = midlevel+shiftsize+BMdist:min(midlevel+shiftsize+150,m-maxblack);
I(validRows,:) = edg(validRows,:);  

I(1,:)=0;

padPb = I / max(I(:));
Pb = [];

end
