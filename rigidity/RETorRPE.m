function [x,y] = RETorRPE(aC,bC,aIm,bIm,imind,num,edges,bscan)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
bscan=mat2gray(double(bscan));
[m,n]=size(bscan);

startedge=edges(:,1);
endedge=edges(:,2);
startlength=length(find(startedge));
endlength=length(find(endedge));

DL=imfilter(bscan,[-1;1],'symmetric');
DL(DL<0)=0;
DL=mat2gray(DL);


s=zeros(size(aC));
s(aC~=1 & bC~=num) = 2 - (DL(aIm) + DL(bIm));
s(1:startlength)=1;
s(length(s)-endlength+1:length(s))=1;
% Each element in s correspond to a graph edge
C=sparse(aC,bC,s,num,num);
[~,path,~]=graphshortestpath(C,1,num); %path is the index in the nodes array
[y,x]=ind2sub([m,n],imind(path(2:end-1)-1));

check=[[x;0] [0;x]];
check=(check(:,1)==check(:,2));
check=find(check);
y=y(setdiff(1:length(x),check));
x=x(setdiff(1:length(x),check));

end

