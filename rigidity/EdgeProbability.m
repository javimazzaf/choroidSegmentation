function [Pb,padPb] = EdgeProbability(shiftbscan,scalesize,angles,midlevel,shiftsize)
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
h=shiftbscan(midlevel+shiftsize+BMdist:min(midlevel+shiftsize+150,m-maxblack),:);
h=imfilter(h,fspecial('gaussian',[5 5],3));
I=ImageCompensation(h,2,0.05,'Adaptive','Comp');

Pb=zeros(size(I));
Ptheta=repmat({zeros(size(I))},numel(angles),1);

P=PixelHist(I,scalesize,25,angles,1);

P=mat2gray(P);
P(1,:)=0;
%         Pbt=NonMaxSuppression(Pb);
padPb=[zeros(midlevel+shiftsize+(BMdist-1),n);P;zeros(size(shiftbscan,1)-(midlevel+shiftsize+(BMdist-1))-size(Pb,1),n)];
%         whatever2=[zeros(midlevel+shiftsize-1,l);Pbt;zeros(maxblack,l)];
end


% 
% [m,n]=size(bscan);
% colcount=zeros(1,n);
% for j=30:n-30
%     for i=m:-1:1
%         if bscan(i,j)==0
%             colcount(j)=colcount(j)+1;
%         else
%             break
%         end
%     end
% end
% 
% maxblack=max(colcount(colcount<(m-150)));
% 
% [combo1,combo2]=meshgrid(scalesize,angles);
% combo1=reshape(combo1,1,numel(combo1));
% combo2=reshape(combo2,1,numel(combo2));
% 
% Pb=zeros(size(bscan));
% P=cell(numel(combo1),1);
% Ptheta=repmat({zeros(size(bscan))},numel(angles),1);
% 
% 
% P=PixelHist(bscan,combo1,25,combo2,0);
% 
% P=reshape(P,numel(angles),numel(scalesize));
% 
% for i=1:numel(angles)
%     for j=1:numel(scalesize)
%         Ptheta{i}=imadd(Ptheta{i},P{i,j});
%     end
% end
% for i=1:numel(angles)
%     Pb=max(Pb,Ptheta{i});
% end
% 
% Pb=mat2gray(Pb);
% Pb(1,:)=0;
% Pb(end-maxblack-5:end,:)=0;
% 
% Pbt=NonMaxSuppression(Pb);
% padPb=[zeros(midlevel+shiftsize+(BMdist-1),n);Pb;zeros(size(bscan,1)-(midlevel+shiftsize+(BMdist-1))-size(Pb,1),n)];
% end
%
% [m,n]=size(shiftbscan);
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
% maxblack=max(colcount(colcount<(m-(midlevel+shiftsize))/3))+5;
%
% BMdist=0;%7;
% h=shiftbscan(midlevel+shiftsize+BMdist:min(midlevel+shiftsize+150,m-maxblack),:);
%
% % I=ImageCompensation(h,2,0.05,'Adaptive','Comp');
%
% [combo1,combo2]=meshgrid(scalesize,angles);
% combo1=reshape(combo1,1,numel(combo1));
% combo2=reshape(combo2,1,numel(combo2));
%
% Pb=zeros(size(I));
% P=cell(numel(combo1),1);
% Ptheta=repmat({zeros(size(I))},numel(angles),1);
%
% P=PixelHist(I,combo1,25,combo2,1);
%
% P=reshape(P,numel(angles),numel(scalesize));
%
% for i=1:numel(angles)
%     for j=1:numel(scalesize)
%         Ptheta{i}=imadd(Ptheta{i},mat2gray(P{i,j}));
%     end
% end
% for i=1:numel(angles)
%     Pb=max(Pb,Ptheta{i});
% end
%
% Pb=mat2gray(Pb);
% Pb(1,:)=0;
% %         Pbt=NonMaxSuppression(Pb);
% padPb=[zeros(midlevel+shiftsize+(BMdist-1),n);Pb;zeros(size(shiftbscan,1)-(midlevel+shiftsize+(BMdist-1))-size(Pb,1),n)];
% %         whatever2=[zeros(midlevel+shiftsize-1,l);Pbt;zeros(maxblack,l)];
% end
%
