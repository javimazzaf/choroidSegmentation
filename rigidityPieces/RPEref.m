function [x,y] = RPEref(aC,bC,aIm,bIm,imind,num,edges,bscan)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
bscan=mat2gray(double(bscan));
[m,n]=size(bscan);

startedge=edges(:,1);
endedge=edges(:,2);
startlength=length(find(startedge));
endlength=length(find(endedge));

LD=imfilter(bscan,[1;-1],'symmetric');
LD(LD<0)=0;
LD=-LD;
LD=mat2gray(LD);

DL=imfilter(bscan,[-1;1],'symmetric');
DL(DL<0)=0;
DL=0.5*mat2gray(DL);

int=-bscan;
int=mat2gray(int);

% edge=PixelHist(bscan,3,25,0,0);

[row,col]=ind2sub(size(bscan),imind);
Pb=PixelHist(bscan(min(row):max(row),:),5,25,[-45 0 45 90],0);
Pb=[ones(min(row)-1,n);Pb;ones(m-max(row),n)];

s=zeros(size(aC));
s(aC~=1 & bC~=num)=(int(aIm)+int(bIm))+(DL(aIm)+DL(bIm))+(Pb(aIm)+Pb(bIm));
s(1:startlength)=int(imind(1:startlength))+DL(imind(1:startlength))+(Pb(imind(1:startlength)));
s(length(s)-endlength+1:length(s))=int(imind(end-endlength+1:end))...
                                   +DL(imind(end-endlength+1:end))...
                                   +(Pb(imind(end-endlength+1:end)));

C=sparse(aC,bC,s,num,num);
[~,path,~]=graphshortestpath(C,1,num);
[y,x]=ind2sub([m,n],imind(path(2:end-1)-1));

check=[[x;0] [0;x]];
check=(check(:,1)==check(:,2));
check=find(check);
y=y(setdiff(1:length(x),check));
x=x(setdiff(1:length(x),check));

end

