function [varargout]=FindAllMembranes(bscan,directory)



try

    bscan=FillBlackColumns(bscan);

    

    [m,n] = size(bscan);

    

    bguess = imfilter(bscan,fspecial('gaussian',[3 3],3)); % Gaussian Smoothing

    bguess = flipud(ImageCompensation(flipud(bguess),1.5,0.3,'Adaptive','CompExp'));

    

    %% Make Initial Cut Mask

    
    %-% <JM> I'm not sure this always improves the result. <\JM>
    for j = 1:n

        bguess(:,j) = bguess(:,j) / max(bguess(:,j));  %%%ADDED ON OCT 7

    end

    

    % Another Gaussian smoothing
    bmask = imfilter(bguess,fspecial('gaussian',[9 9],11));  %% PREVIOUSLY ALL 11

    % Vertical gradient
    bmask = mat2gray(imfilter(bmask,[-1;1]));

    bmask = bmask > 0.5;

    bmask = bwlabel(imopen(bmask,ones(3)));

    % Remove objects smaller than 400 pix
    info  = regionprops(bmask,'Area');

    small = find([info.Area] < 400);

    for i=1:length(small)

        bmask(bmask==small(i))=0;

    end

    % Morphological close with 7pix disk and remove isolated pixels
    bmask = bwmorph(imclose(bmask,strel('disk',7)),'spur','inf');

    % Moprphological close in first and last 15 columns
    bmask(:,1:15)       = imclose(bmask(:,1:15,:),    strel('disk',7));
    bmask(:,end-15:end) = imclose(bmask(:,end-15:end),strel('disk',7));

    region1 = bmask;

    check   = bwlabel(region1);

    checkl  = unique(check(:,1));
    checkr  = unique(check(:,end));

    % If first col does not have two foreground objects, sets all first 50
    % columns to 1
    if length(setdiff(checkl,0)) ~= 2

        region1(:,1:50) = 1;

    end

    % If last col does not have two foreground objects, sets all last 50
    % columns to 1    
    if length(setdiff(checkr,0)) ~= 2

        region1(:,end-50:end) = 1;

    end

    

    %% Make Initial Cut

    [aC,bC,aIm,bIm,imind,edges,num] = ConnectivityMatrix(region1,8); %?

    [col1st,firstCut] = RETorRPE(aC,bC,aIm,bIm,imind,num,edges,bguess);

    

    %% Determine if Initial Cut is RPE or Retina

    list=[];

    for i=1:length(firstCut)

        list=[list;[(1:firstCut(i))' repmat(col1st(i),firstCut(i),1)]];

    end

    list=sub2ind(size(bscan),list(:,1),list(:,2));

    fracbright=length(find(bscan(list)>50))/length(list);

    

    if fracbright > 0.05  %Found the Rough RPE

        roughcol=col1st;

        roughRPE=firstCut;

        regionret=ones(size(bguess));

        for j=1:n

            regionret(firstCut(j)-15:end,j)=0;  %Was 20

        end

        [aC,bC,aIm,bIm,imind,edges,num]=ConnectivityMatrix(regionret,8);

        [~,flatret]=RETorRPE(aC,bC,aIm,bIm,imind,num,edges,bguess);

        yret=flatret;

    else %Found the Retina

        yret=firstCut;

        %     regionRPE=zeros(size(bguess));

        %     for j=1:n

        %         regionRPE(firstCut(j)+35:min(m,firstCut(j)+125),j)=1;

        %     end

        regionRPE=bwlabel(region1);

        if isempty(setdiff(unique(regionRPE),[0,1]))

            for j=1:n

                regionRPE(firstCut(j)+15:end,j)=0;  %Was 20

            end

            regionRPE=logical(regionRPE);

        else

            elim=mode(regionRPE(sub2ind(size(regionRPE),firstCut,col1st)));

            regionRPE(regionRPE==elim)=0;

            regionRPE=logical(regionRPE);

        end

        [aC,bC,aIm,bIm,imind,edges,num]=ConnectivityMatrix(regionRPE,8);

        [roughcol,roughRPE]=RETorRPE(aC,bC,aIm,bIm,imind,num,edges,bguess);

    end

    

    %% Flatten wrt rough RPE

    DT=DelaunayTri(roughcol,roughRPE);

    CH=convexHull(DT);

    CHpts=flipud([DT.X(CH,1) DT.X(CH,2)]);

    last=find(CHpts(:,1)<circshift(CHpts(:,1),1),1,'first')-1;

    CHcurve=fit(CHpts(1:last,1),CHpts(1:last,2),'linear');

    CHcurve=round(CHcurve(1:n));

    

    midlevel=round(mean(CHcurve));

    colshifts=-(CHcurve-midlevel*ones(length(CHcurve),1));

    shiftsize=double(max(abs(colshifts)));

    

    RPEshift=BMImageShift(bguess,colshifts,shiftsize,'nothing');

    

    %% Refine RPE

    regionRPEref=zeros(size(RPEshift));

    for j=1:n

        regionRPEref(roughRPE(j)-5+colshifts(j):CHcurve(j)+colshifts(j)+15,j)=1;

    end

    

    h=zeros(size(bscan));

    angles=[-45 -30 0 30 45];

    for i=1:length(angles)

        g=imfilter(RPEshift,OrientedGaussian([2 1],angles(i)));

        h=max(h,g);

    end

    h=mat2gray(h);

    

    [aC,bC,aIm,bIm,imind,edges,num]=ConnectivityMatrix(regionRPEref,8);

    [colref,refRPE]=RPEref(aC,bC,aIm,bIm,imind,num,edges,h);

    

    %% Find BM

    DT2=DelaunayTri(colref,refRPE);

    CH2=convexHull(DT2);

    CHpts2=flipud([DT2.X(CH2,1) DT2.X(CH2,2)]);

    last=find(CHpts2(:,1)<circshift(CHpts2(:,1),1),1,'first')-1;

    CHcurve2=fit(CHpts2(1:last,1),CHpts2(1:last,2),'linear');

    CHcurve2=round(smooth(CHcurve2(1:n),15,'rlowess'));

    

    

    regionBM=zeros(size(RPEshift));

    for j=1:n

        regionBM(refRPE(j):CHcurve2(j)+5,j)=1;

    end

    

    shiftbscan=BMImageShift(bscan,colshifts,shiftsize,'nothing');

    

    [aC,bC,aIm,bIm,imind,edges,num]=ConnectivityMatrix(regionBM,8);

    [colBM,flatBM]=BM(aC,bC,aIm,bIm,imind,num,edges,shiftbscan);

    %

    %

    % DT2=DelaunayTri(colBM,flatBM);

    % CH2=convexHull(DT2);

    % CHpts2=flipud([DT2.X(CH2,1) DT2.X(CH2,2)]);

    % last=find(CHpts2(:,1)<circshift(CHpts2(:,1),1),1,'first')-1;

    % CHcurve2=fit(CHpts2(1:last,1),CHpts2(1:last,2),'linear');

    % CHcurve2=round(smooth(CHcurve2(1:n),15,'rlowess'));

    

    

    yONL=roughRPE;

    yRPE=refRPE-colshifts;

    yBM=round(smooth(flatBM-colshifts,25,'rloess'));

    

    varargout{1}=yret;

    varargout{2}=yONL;

    varargout{3}=yRPE;

    varargout{4}=yBM;

    

catch err

    if ~exist(fullfile(directory,'Error Folder'),'dir')
        mkdir(fullfile(directory,'Error Folder'));
    end

%     %JM: Save Error Message to text file
%     fid = fopen(fullfile(directory,'Error Folder','errorMessage.txt'));
%     fprintf(fid,'ErrorID:%s\nMessage:%s',err.identifier,err.message);
%     fclose(fid);
    
    disp(err.identifier)
    disp(err.message)
%     dbstack('-completenames')
    
    if ~exist('yret','var') || ~exist('roughRPE','var')

        im1=imfuse(bscan,region1);

        imwrite(im1,fullfile(directory,'Error Folder','FirstCutError.jpg'))

    end

    

    if  exist('regionRPEref','var') && ~exist('refRPE','var')

        im2=imfuse(RPEshift,regionRPEref);

        imwrite(im2,fullfile(directory,'Error Folder','RPERefinementError.jpg'))

    end

    

    if exist('regionBM','var') && ~exist('yBM','var')

        im3=imfuse(RPEshift,regionBM);

        imwrite(im3,fullfile(directory,'Error Folder','BMCutError.jpg'))

    end

end

end





