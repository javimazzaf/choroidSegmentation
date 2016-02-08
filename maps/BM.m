function [x,y] = BM(aC,bC,aIm,bIm,imind,num,edges,bscan)
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
DL=-DL;
DL=mat2gray(DL);
DL=imadjust(DL,[0 1],[0 0.2]);

LD=imfilter(bscan,[1;-1],'symmetric');
LD(LD<0)=0;
LD=-LD;
LD=mat2gray(LD)*2+2;

diagup=(bIm==aIm+m-1)*6;
diagdown=(bIm==aIm+m+1)*6;
straight=(~diagup&~diagdown)*2;

[row,col]=ind2sub(size(bscan),imind);
Pb=PixelHist(imcomplement(bscan(min(row):max(row),:)),5,25,[-45 0 45],0);
Pb=[ones(min(row)-1,n);Pb;ones(m-max(row),n)];

s=zeros(size(aC));
s(aC~=1 & bC~=num)=(LD(aIm)+LD(bIm))+(DL(aIm)+DL(bIm))+(diagup+diagdown+straight)+(2-(Pb(aIm)+Pb(bIm)));
s(1:startlength)=LD(imind(1:startlength))+DL(imind(1:startlength))+(1-Pb(imind(1:startlength)));
s(length(s)-endlength+1:length(s))=LD(imind(end-endlength+1:end))...
                                   +DL(imind(end-endlength+1:end))...
                                   +(1-Pb(imind(end-endlength+1:end)));

C=sparse(aC,bC,s,num,num);
[~,path,~]=graphshortestpath(C,1,num);
[y,x]=ind2sub([m,n],imind(path(2:end-1)-1));

check=[[x;0] [0;x]];
check=(check(:,1)==check(:,2));
check=find(check);
y=y(setdiff(1:length(x),check));
x=x(setdiff(1:length(x),check));

end

