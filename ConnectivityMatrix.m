function [aC,bC,aIm,bIm,imind,edges,num] = ConnectivityMatrix(region,connectivity)

[m,n]  = size(region);
region = double(region);
old    = 1;

for j = 1:n
    col = find(region(:,j));
    region(col,j) = region(col,j) .* (1:length(col))' + old;
    old = length(col) + old;
end

imind = find(region); %Indices of all foreground pixels in region(mask) 
num   = length(imind) + 2;

if connectivity==4
    
    aimind=repmat(imind,1,3);
    aimind=reshape(aimind',size(aimind,1)*size(aimind,2),1);
    
    right=imind+m;
    up=imind-1;
    down=imind+1;
    imhood=[up right down];
    
    keep=[(rem(imind-1,m)~=0) imind+m<=(m*n) (rem(imind+1,m)~=1)]; %[(n-2)*2] + [(n-1)*(m-2)*3]+[2*2+1*2]+(m-2)*2 %[top,bot]+[middle]+[corners]
    keep=reshape((ismember(imhood,imind)&keep)',size(imind,1)*3,1);
    imhood=reshape(imhood',size(imhood,1)*size(imhood,2),1);
    
elseif connectivity==8
    
    aimind = repmat(imind,1,5);
    aimind = reshape(aimind',numel(aimind),1);
    
    % Index of pixels in positions relative to pixels in imind
    right    = imind + m;
    diagup   = imind + m - 1;
    up       = imind - 1;
    diagdown = imind + m + 1;
    down     = imind + 1;
    
    imhood   = [up diagup right diagdown down]; % Pixels on the right side
    
    
    keep = [(rem(imind - 1,m)      ~= 0),...    % Not in first row
            (rem(imind + m - 1, m) ~= 0),...    % Right-up is not first row
            imind + m              <= (m*n),... % Not in last column 
            (rem(imind + m + 1, m) ~= 1),...    % Right-down pix is not in first row
            (rem(imind + 1, m)     ~=1)];       % Down pix is not first row
        
        %[(n-2)*2] + [(n-1)*(m-2)*3]+[2*2+1*2]+(m-2)*2 %[top,bot]+[middle]+[corners]
    keep   = ismember(imhood,imind) & keep; % Keep only real pixels and kept ones
    keep   = reshape(keep',numel(keep),1);  
    imhood = reshape(imhood',numel(imhood),1);
else
    error('Error In ConnectivityMatrix.mat, Connectivity Must be 4 or 8')
end

aimind = aimind(keep); %Idexes repeated 5 times [1 1 1 1 1 2 2 2 2 2 ...]'
bimind = imhood(keep); %Indexs of neighbour pixels [up1 diagup1 right1 ... up2 diagup2 right2 ...]

aIm    = aimind; %Idexes repeated 5 times [1 1 1 1 1 2 2 2 2 2 ...]'
bIm    = bimind; %Indexs of neighbour pixels [up1 diagup1 right1 ... up2 diagup2 right2 ...]

aC     = region(aimind); %region in aIm 
bC     = region(bimind); %region in bIm

startedge   = region(:,1) > 0; %logical(region(:,1));
startlength = sum(startedge);  %length(find(startedge));

endedge     = region(:,n) > 0; %logical(region(:,n));
endlength   = sum(endedge);    %length(find(endedge));

aC = [ones(startlength,1);aC;region(endedge,n)];
bC = [region(startedge,1);bC;repmat(num,endlength,1)];

edges = [startedge endedge];
% as=unique(aimind);
% for i=1:length(as)
%     ind=find(aimind==as(i));
%     con=bimind(ind);
%     k=zeros(size(region));
%     k(con)=1;
%     j=zeros(size(region));
%     j(as(i))=.5;
%     [row,col]=ind2sub(size(region),as(i));
%     ups=max(1,row-10);
%     downs=min(row+10,m);
%     rights=min(col+10,n);
%     lefts=max(1,col-10);
%     figure(1)
%     h=imshow(imoverlay(imoverlay(region,k,[1 0 0]),j,[0 1 0]));
%     xlim([lefts-0.5 rights]);
%     ylim([ups downs])
% end

end

