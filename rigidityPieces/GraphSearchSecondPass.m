function PathPts = GraphSearchSecondPass(points,texture,meanCSI,alpha,wM,delColmax,delRowmax,maxJumpCol,...
    maxJumpRow,on1,on2,on3,on4)
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
[m,n]=size(points);
yEdge=round([meanCSI(1) meanCSI(end)]);
[row, col]=find(points);
row=[yEdge(1); row; yEdge(2)];
col=[0;col;n+1];
num=numel(find(points))+2;
C=zeros(num,num);

points=bwlabel(points);
points(logical(points))=points(logical(points))+1;

elementIdx=1:num;
firstcol=col(2);
lastcol=col(end-1);

% counts=zeros(1,6);

%% Boundary Connections
BoundaryColCon=round(delColmax);
LBoundIndx=elementIdx(ismember(col,firstcol:firstcol+BoundaryColCon));
RBoundIndx=elementIdx(ismember(col,lastcol-BoundaryColCon:lastcol));%abs(row(end)-row)<=delRowmax & 

if on4
    ConnectionAffinityL=LinePenalty(1,row,col,LBoundIndx,points,texture);
    ConnectionAffinityR=LinePenalty(num,row,col,RBoundIndx,points,texture);
else
    ConnectionAffinityL=Inf;
    ConnectionAffinityR=Inf;
end

dely=abs(yEdge(1)-row(LBoundIndx));
delx=col(LBoundIndx);
C(1,LBoundIndx)=((dely).^2+(delx).^2)+... %Euclidian Distance Squared
    (wM*heaviside(dely-maxJumpRow).*abs((dely-maxJumpRow))).*sigmf(dely,[alpha,maxJumpRow])+...%Control of Vertical Jump Penalty Magnitude
    on1*10*wM*(heaviside(delx-maxJumpCol).*abs((delx-maxJumpCol))).*sigmf(delx,[alpha,maxJumpCol])+...%Control of Horizontal Jump Penalty Magnitude
    on3*(wM./texture(sub2ind(size(texture),row(LBoundIndx),col(LBoundIndx))))+...
    on4*wM./ConnectionAffinityL+...
    wM*abs((meanCSI(col(LBoundIndx))-row(LBoundIndx))).*...
                     heaviside((meanCSI(col(LBoundIndx))-row(LBoundIndx))-15).*sigmf((meanCSI(col(LBoundIndx))-row(LBoundIndx)),[alpha,15]);
dely=abs(yEdge(2)-row(RBoundIndx));
delx=col(RBoundIndx);
C(RBoundIndx,num)=((dely).^2+(delx).^2)+... %Euclidian Distance Squared
    (wM*10*heaviside(dely-maxJumpRow).*abs((dely-maxJumpRow))).*sigmf(dely,[alpha,maxJumpRow])+...%Control of Vertical Jump Penalty Magnitude
    on1*wM*(heaviside(delx-maxJumpCol).*abs((delx-maxJumpCol))).*sigmf(delx,[alpha,maxJumpCol])+...%Control of Horizontal Jump Penalty Magnitude
    on3*(wM./texture(sub2ind(size(texture),row(RBoundIndx),col(RBoundIndx))))+...
    on4*wM./ConnectionAffinityR+...
    wM*abs((meanCSI(col(RBoundIndx))-row(RBoundIndx))).*...
                     heaviside((meanCSI(col(RBoundIndx))-row(RBoundIndx))-10).*sigmf((meanCSI(col(RBoundIndx))-row(RBoundIndx)),[alpha,10]);
%% All Other Connections
for indx=2:num-1
    if col(indx)==max(col)
        break
    end
    
    connected=elementIdx(abs(col(indx)-col)<=delColmax & col>col(indx) & abs(row(indx)-row)<=delRowmax & col<=n);
    
    if isempty(connected) && ~any(any(C(1:indx-1,indx+1:end)))
        nextcol = min(col((col>col(indx) & abs(row(indx)-row)<=delRowmax))); % JM: column of nearest connectable node to the right
        
        if isempty(nextcol), continue, end % JM: There aren't any nodes connected to the current one
        
        connected = elementIdx(col==nextcol & abs(row(indx)-row)<=delRowmax);

    end
    
    dely=abs(row(indx)-row(connected));
    delx=abs(col(indx)-col(connected));
    
    if on4
        ConnectionAffinity=LinePenalty(indx,row,col,connected,points,texture);
    else
        ConnectionAffinity=Inf;
    end
    
    Euclid=(dely.^2+delx.^2);
    VertJumpPenalty=(wM*heaviside(dely-maxJumpRow).*abs((dely-maxJumpRow))).*sigmf(dely,[alpha,maxJumpRow]);
    HorizJumpPenalty=(wM/2*(heaviside(delx-maxJumpCol).*abs((delx-maxJumpCol))).*sigmf(delx,[alpha,maxJumpCol]));  %was wm/2
    
    % JM: we skip computing the texture on the virtual "connected" node (very last node) 
    % since texture is not defined for it.
    
    EndTexturePenalty = zeros(size(connected(:))); %JM: Initialize this weight with zeros
    mskColValid = col(connected) <= size(texture,2); % JM: get mask for the connected nodes that are within texture matrix
    EndTexturePenalty(mskColValid)=(wM./texture(sub2ind(size(texture),row(connected(mskColValid)),col(connected(mskColValid))))); % JM: compute weight only for the valid nodes
    
    AffinityPenalty=wM./ConnectionAffinity;
    
    % JM: skip evaluating meanCSI on virtual nodes.
    DeviationPenalty = zeros(size(connected(:))); %JM: Initialize this weight with zeros
    DeviationPenalty(mskColValid) = wM/2*abs((meanCSI(col(connected(mskColValid)))-row(connected(mskColValid)))) .*...
                     heaviside((meanCSI(col(connected(mskColValid)))-row(connected(mskColValid)))-10)            .*...
                     sigmf((meanCSI(col(connected(mskColValid)))-row(connected(mskColValid))),[alpha,10]);
    
    
    Weight=Euclid+... %Euclidian Distance Squared
        +VertJumpPenalty+...%Control of Vertical Jump Penalty Magnitude
        on1*HorizJumpPenalty+...%Control of Horizontal Jump Penalty Magnitude
        on3*EndTexturePenalty+...
        on4*AffinityPenalty+DeviationPenalty;
    
    %             on3*wM/10*abs(atand(dely./delx)-thetamean)
    %             wM*5000*heaviside(5-Neighbs)./(1+exp(2.*Neighbs));
    %             2000*wM*1./(mean([ones(length(row(connected)),1)*row(indx) row(connected)],2)-midLevel)
    
%     governing=[Euclid VertJumpPenalty HorizJumpPenalty EndTexturePenalty AffinityPenalty DeviationPenalty];
%     
%     counts=counts+sum(governing==repmat(max(governing,[],2),1,6));
    
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
    vals=vals(1:n);
    vals=round(smooth(vals,50,'rloess'))';
    PathPts=sub2ind([m n],vals,1:length(vals));
end
end