function padPb = EdgeProbabilityGrad(shiftbscan,scalesize,angles,rpeHeight)
% Computes the edge probability

parameters = loadParameters;

sigma  = scalesize / 4;
angles = angles + 90;

% [m,n]=sxize(shiftbscan);
% colcount=zeros(1,n);
% for j=30:n-28
%     for i=m:-1:midlevel+shiftsize
%         if shiftbscan(i,j)==0
%             colcount(j)=colcount(j)+1;
%         else
%             break
%         end
%     end
% end
% 
% maxblack = max(colcount(colcount<(m-(midlevel+shiftsize))/3)) + 5;

edg = edgeness(shiftbscan,sigma,angles);

% Keeps only positive gradient
edg(edg < 0) = 0;

% Keeps information within a valid region

padPb = zeros(size(edg));

topRow = max(1, rpeHeight + parameters.choroidMinWidth); 
botRow = min(size(padPb,1), topRow + parameters.choroidMaxWidth - 1); 

padPb(topRow:botRow,:) = edg(topRow:botRow,:);  

padPb(1,:) = 0;

padPb = padPb / max(padPb(:));

padPb = padPb.^2;

padPb(padPb <= parameters.edginessThreshold) = 0; 

end
