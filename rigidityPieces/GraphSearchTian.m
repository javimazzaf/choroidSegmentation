function PathPts = GraphSearchTian(points,alpha,wM,delColmax,delRowmax,maxJumpRow)
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here

[m, n]=size(points);

[row, col]=find(points);
row=[0; row; 0];
col=[0;col;0];
num=numel(find(points))+2;
C=zeros(num,num);

points=bwlabel(points);
points(logical(points))=points(logical(points))+1;

elementIdx=1:num;
firstcol=col(2);
lastcol=col(end-1);

BoundaryColCon=round(delColmax);
LBoundIndx=elementIdx(ismember(col,firstcol:firstcol+BoundaryColCon));
RBoundIndx=elementIdx(ismember(col,max(col)-BoundaryColCon:max(col)));

C(1,LBoundIndx)=1;
C(RBoundIndx,num)=1;

if num==2
    PathPts=nan;
    return
end

for indx=2:num-1
    if col(indx)==max(col)
        break
    end
    
    connected=elementIdx(abs(col(indx)-col)<=delColmax & col>col(indx) & abs(row(indx)-row)<=delRowmax);
    
    if isempty(connected)
      continue
    end
    
    dely=abs(row(indx)-row(connected));
    delx=abs(col(indx)-col(connected));
    
    Weight=((dely).^2+(delx).^2)+(wM*heaviside(dely-maxJumpRow).*abs((dely-maxJumpRow))).*sigmf(dely,[alpha,maxJumpRow]);%Control of Vertical Jump Penalty Magnitude
    %             on3*wM/10*abs(atand(dely./delx)-thetamean)
    %             wM*5000*heaviside(5-Neighbs)./(1+exp(2.*Neighbs));
    %             2000*wM*1./(mean([ones(length(row(connected)),1)*row(indx) row(connected)],2)-midLevel)
    
    C(indx,connected)=Weight;
end

C=sparse(C);

[dist,path,pred]=graphshortestpath(C,1,num);
% h = view(biograph(C,[]))
% set(h.Nodes(path),'Color',[1 0.4 0.4])
% edges = getedgesbynodeid(h,get(h.Nodes(path),'ID'));
% set(edges,'LineColor',[1 0 0])
% set(edges,'LineWidth',1.5)
if dist==Inf || numel(path)==0
    PathPts=NaN;
else
    %     vals=fit([0;col(path(2:end-1));n+1],[row(path(2));row(path(2:end-1));row(path(end-1))],'smoothingspline',...
    %         'smoothingparam',0.1);
    %     vals=round(vals(1:n))';
    %     vals=round(smooth(interp1([0;col(path(2:end-1));n+1],...
    %                           [row(path(2));row(path(2:end-1));row(path(end-1))]...
    %                           ,1:n,'cubic'),0.1,'rloess'))';
    vals=fit([0;col(path(2:end-1));n+1],...
        [row(path(2));row(path(2:end-1));row(path(end-1))],'linear');
    vals=round(smooth(vals(1:n),.25,'rloess'))';
    PathPts=sub2ind([m n],vals,1:length(vals));
end
end