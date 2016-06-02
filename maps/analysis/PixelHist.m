function [Pb] = PixelHist(I,scalesize,nbins,angles,sign)

[combo1,combo2] = meshgrid(scalesize,angles);
% combo1          = reshape(combo1,1,numel(combo1));
% combo2          = reshape(combo2,1,numel(combo2));
combo1 = combo1(:)';
combo2 = combo2(:)';

P = cell(length(combo1),1);

for im = 1:length(combo1)
    radius = combo1(im);
    angle  = combo2(im);
    
    if ~rem(radius,2)
        radius=radius+1;
    elseif radius <3
        error('R must be greater than 2')
    end
    
    offset = ceil(radius/2)-1;
    
    
    %% Image Preprocessing
    Ipad=padarray(I,[offset offset],'both','symmetric');
    %% Image Rotation
    if angle~=0
        tform=affine2d([cos(-angle) -sin(-angle) 0;sin(-angle) cos(-angle) 0;0 0 1]);
        invtform=affine2d([cos(angle) -sin(angle) 0;sin(angle) cos(angle) 0;0 0 1]);
        R1=imref2d(size(Ipad));
        [Irot,R2]=imwarp(Ipad,tform,'fillvalues',NaN);
    else
        Irot=Ipad;
    end
    
    % tform = maketform('affine',[cosd(angle) -sind(angle) 0; sind(angle) cosd(angle) 0; 0 0 1]);
    % invtform = maketform('affine',[cosd(-angle) -sind(-angle) 0; sind(-angle) cosd(-angle) 0; 0 0 1]);
    %
    % bounds=(size(I)-1)/2
    % a=[-bounds(2) bounds(1) ;bounds(2) -bounds(1)]
    % p1=tformfwd(tform,a)
    % p1=sign(p1).*(abs(p1)+0.5-abs(rem(p1,0.5)))
    %
    % p2=tforminv(tform,p1)
    % p2=sign(p2).*(abs(p2)+0.5-abs(rem(p2,0.5)))
    
    % Irot=imwarp(Ipad,tform);
    %% Bin Creation
    y = Irot(:);
    x = nbins;
    
    
    if isvector(y), y = y(:); end
    
    % Cache the vector used to specify how bins are created
    % N = x;
    % JM: In this if case it computs the bins and edges
    if isempty(y),
        if length(x) == 1,
            %        x = 1:double(x);
        end
        %  Set miny, maxy for call to bar below.
        %     miny = [];
        %     maxy = [];
        edges = [-Inf Inf];
    else
%         %  Ignore NaN when computing miny and maxy.
%         ind = ~isnan(y);
%         miny = min(y(ind));
%         maxy = max(y(ind));
%         %  miny, maxy are empty only if all entries in y are NaNs.  In this case,
%         %  max and min would return NaN, thus we set miny and maxy accordingly.
%         if (isempty(miny))
%             miny = NaN;
%             maxy = NaN;
%         end
        
        miny = nanmin(y);
        maxy = nanmax(y);
        
        if length(x) == 1
            if miny == maxy,
                miny = miny - floor(x/2) - 0.5;
                maxy = maxy + ceil(x/2) - 0.5;
            end
            binwidth = (maxy - miny) ./ x;
            xx = miny + binwidth*(0:x);
            xx(length(xx)) = maxy;
            %         x = xx(1:length(xx)-1) + binwidth/2;
        else
            xx = x(:)';
            binwidth = [diff(xx) 0];
            xx = [xx(1)-binwidth(1)/2 xx+binwidth/2];
            xx(1) = min(xx(1),miny);
            xx(end) = max(xx(end),maxy);
        end
        % Shift bins so the interval is ( ] instead of [ ).
        xx = full(real(xx)); %y = full(real(y)); % For compatibility
        bins = xx + eps(xx);
        edges = [-Inf bins];
        edges(2:end) = xx;    % remove shift
        
        % Combine first bin with 2nd bin and last bin with next to last bin
        edges(2) = [];
        edges(end) = Inf;
    end
    %% Hist
    
    [o,p]=deal(size(Irot,1)+1,size(Irot,2)+1); % very confusing way of writing it
    Irotcheck=padarray(Irot,[1 1],NaN,'pre');
    [usedind]=find(~isnan(Irotcheck));
    [col,row]=meshgrid(1:p,1:o);
    col=col(usedind);
    row=row(usedind);
    
    Pt={max(1,row-(offset+1)),max(1,col-(offset+1))}; %Upper-Left corner
    Qt={max(1,row-(offset+1)),min(p,col+(offset))}; %Upper-Right corner
    Rt={row,max(1,col-(offset+1))}; %center-Left corner
    St={row,min(p,col+(offset))}; %center-Right
    
    Pb={max(1,row-1),max(1,col-(offset+1))}; %Upper-Left
    Qb={max(1,row-1),min(p,col+(offset))}; %Upper-Right
    Rb={min(o,row+(offset)),max(1,col-(offset+1))}; %Lower-Left
    Sb={min(o,row+(offset)),min(p,col+(offset))}; %Lower-Right
    
    Pt=sub2ind([o,p],Pt{1},Pt{2});
    Qt=sub2ind([o,p],Qt{1},Qt{2});
    Rt=sub2ind([o,p],Rt{1},Rt{2});
    St=sub2ind([o,p],St{1},St{2});
    
    Pb=sub2ind([o,p],Pb{1},Pb{2});
    Qb=sub2ind([o,p],Qb{1},Qb{2});
    Rb=sub2ind([o,p],Rb{1},Rb{2});
    Sb=sub2ind([o,p],Sb{1},Sb{2});
    
    Xr=0;
    hi=zeros(o*p,1);
    gi=zeros(o*p,1);
    for i=1:nbins
        Ib=integralImage(Irot >= edges(i) & Irot< edges(i+1));    %Image Integral: sum of rows of sum of colums of intensity in bin i
        hi(usedind)=Ib(Pt)-Ib(Qt)-Ib(Rt)+Ib(St); % # of occurences of intensity in bin i in top half of neighbourhood of size radius at each pixel.
        gi(usedind)=Ib(Pb)-Ib(Qb)-Ib(Rb)+Ib(Sb);% # of occurences of intensity in bin i in bottom half of neighbourhood of size radius at each pixel.
        Xi=((gi-hi).^2)./(gi+hi); 
        Xi(isnan(Xi))=0;
        %     figure(1)
        %     imshowpair(Irot,mat2gray(reshape(Xi,o,p)))
        %
        Xr=Xr+Xi;
        %     figure(2)
        %     imshowpair(mat2gray(reshape(Xr,o,p)),mat2gray(reshape(Xi,o,p)));
    end
    Xr=reshape(0.5*Xr,o,p);
    Xr=Xr(2:end,2:end);
    %% Smoothing and Non-maximal Suppression
    Xrs=zeros(size(Xr));
    for j=1:size(Xr,2)
        Xrs(:,j)=smooth(Xr(:,j),radius,'sgolay',2);
    end
    
    % Xlocalmax=NonMaxSuppression(Xrs);
    
    %% Invert Rotation
    if angle~=0
        X=imwarp(Xrs,R2,invtform,'Outputview',R1);
        X=X(offset+1:end-offset,offset+1:end-offset);
    else
        X=Xrs;
        X=X(offset+1:end-offset,offset+1:end-offset);
    end
    
    % JM: I do not get this thing below
    if sign
        filttop=zeros(radius);
        filttop(1:offset+1,:)=1;
        num=length(find(filttop));
        filttop=filttop/num;
        filtbot=flipud(filttop);
        avP=imfilter(I,filtbot,'symmetric')-imfilter(I,filttop,'symmetric');
        X(avP<0)=0;
    end
    P{im}=mat2gray(X);
    
end

P=reshape(P,numel(angles),numel(scalesize));

Pb=zeros(size(I));
Ptheta=repmat({zeros(size(I))},numel(angles),1);

for i=1:numel(angles)
    for j=1:numel(scalesize)
        Ptheta{i}=imadd(Ptheta{i},P{i,j});
    end
end

for i=1:numel(angles)
    Pb=max(Pb,mat2gray(Ptheta{i}));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Local Function Non-Maximal Suppresion
% function localmax=NonMaxSuppression(X)
%
% [m,n]=size(X);
% idx=1:m*n;
%
% localmax=zeros(m,n);
% for i=1:m*n;
%     if mod(i,m)==1
%         if X(i)>=X(i+1)
%             localmax(i)=1;
%         end
%     elseif mod(i,m)==0
%         if X(i)>=X(i-1)
%             localmax(i)=1;
%         end
%     else
%         if X(i)>=X(i-1) && X(i)>=X(i+1)
%             localmax(i)=1;
%         end
%     end
% end
%
