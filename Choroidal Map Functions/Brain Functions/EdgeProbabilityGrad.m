function padPb = EdgeProbabilityGrad(shiftbscan,scalesize,angles,rpeHeight)
% Computes the edge probability

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
CHOROID_MIN_WIDTH = getParameter('CHOROID_MIN_WIDTH');
CHOROID_MAX_WIDTH = getParameter('CHOROID_MAX_WIDTH');
padPb = edg(rpeHeight + CHOROID_MIN_WIDTH:end - CHOROID_MAX_WIDTH,:);  

padPb(1,:) = 0;

padPb = padPb / max(padPb(:));

padPb = padPb.^2;

end
