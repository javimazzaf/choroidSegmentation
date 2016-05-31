function choroidMap(varargin)

dirlist = adaptToHMRpath(varargin{1});

for iter=1:length(dirlist)
    directory=dirlist{iter};
    
    disp(logit(directory,['Starting ChoroidMap:' directory]));
    
    try
    
    load(fullfile(directory,'Results','FirstProcessData.mat'));
    load(fullfile(directory,'Data Files','RegisteredImages.mat'));
    load(fullfile(directory,'Data Files','ImageList.mat'))
    
    
    %% Fundus Info
    if isfield(ImageList,'fundusfileName')
        fundus=ImageList(1).fundusfileName;
        fwidth=ImageList(1).fwidth;
        fheight=ImageList(1).fheight;
        fscaleX=ImageList(1).fscaleX;
        fscaleY=ImageList(1).fscaleY;
    else
        x=dir([directory,'\Raw Images\*.xml']);
        
        fileID=fopen(fullfile(directory,'Raw Images',x.name));
        while ~feof(fileID)
            line=fgetl(fileID);
            if strcmp(line,'<Type>LOCALIZER</Type>')
                for i=1:18
                    line=fgetl(fileID);
                    if strncmp(line,'<Width>',7)
                        [e,s]=regexp(line,{'<Width>','</Width>'},'start','end');
                        fwidth=str2double((line(s{1}+1:e{2}-1)));
                    elseif strncmp(line,'<Height>',8)
                        [e,s]=regexp(line,{'<Height>','</Height>'},'start','end');
                        fheight=str2double((line(s{1}+1:e{2}-1)));
                    elseif strncmp(line,'<ScaleX>',7)
                        [e,s]=regexp(line,{'<ScaleX>','</ScaleX>'},'start','end');
                        fscaleX=str2double((line(s{1}+1:e{2}-1)));
                    elseif strncmp(line,'<ScaleY>',7)
                        [e,s]=regexp(line,{'<ScaleY>','</ScaleY>'},'start','end');
                        fscaleY=str2double((line(s{1}+1:e{2}-1)));
                    elseif strncmp(line,'<ExamURL>',9)
                        fundus=line;
                        ind1=regexp(fundus,'\');
                        ind2=regexp(fundus,'.tif');
                        fundus=fundus(ind1(end)+1:ind2+3);
                    end
                end
                break
            end
        end
        fclose(fileID);
    end
    
    k = fundim(:,:,1);
    % k=imadjust(k,[min(k(:)) max(k(:))],[0 1],.5);
    k     = intrans(k,'stretch',mean2(im2double(k)),2);
    Rfund = imref2d(size(fundim),[0 fwidth*fscaleX],[0 fheight*fscaleY]);
    fxvec = linspace(Rfund.XWorldLimits(1),Rfund.XWorldLimits(end),Rfund.ImageSize(1));
    fyvec = linspace(Rfund.YWorldLimits(1),Rfund.YWorldLimits(end),Rfund.ImageSize(2));
    
    %% BScan Info
%     scaleX = ImageList(1).scaleX;
%     scaleY = ImageList(1).scaleY;
    width  = ImageList(1).width;
%     height = ImageList(1).height;
    
    fileID     = fopen(fullfile(directory,'Data Files','TrimInfo.txt'));
    trimvalues = fscanf(fileID,'%d');
    CutLeft    = trimvalues(1);
    CutRight   = trimvalues(2);
    fclose(fileID);
    
    xvec = linspace(ImageList(start).startX+ (CutLeft-1)      * ImageList(start).scaleX,...
                    ImageList(start).endX  - (width-CutRight) * ImageList(start).scaleX,...
                    size(bscanstore{1},2)); %length(traces(start).CSI));
                
    yvec = [ImageList.startY];
    
%     Rbscan = imref2d([length(xvec) length(xvec)],[xvec(1) xvec(end)],[yvec(end) yvec(1)]);
    
    [gridx,gridy] = meshgrid(xvec,yvec);
    
    gridC = NaN(numel(yvec), numel(xvec));
    gridW = NaN(numel(yvec), numel(xvec)); % Weights
    
    for q = start:length(traces)
        
        if isempty(traces(q).BM) || isempty(traces(q).CSI), continue, end
        
        CSI = traces(q).CSI;
        
        xCSI = [];
        yCSI = [];
        wCSI = []; % Weight of segmentation
        
        for c = 1:numel(CSI)
            if ~CSI(c).keep, continue, end
            
            xCSI = [xCSI; CSI(c).x];
            yCSI = [yCSI; CSI(c).y];
            wCSI = [wCSI; CSI(c).weight];  
        end
        
        [xCSI, ix] = sort(xCSI);
        yCSI = yCSI(ix);
        wCSI = wCSI(ix);
        
        [xCSI,ixa,~] = unique(xCSI);
        yCSI = yCSI(ixa);
        wCSI = wCSI(ixa);
%         [xiCSI,yiCSI] = interpCSI(xCSI,yCSI, length(traces(q).BM));
        
        yBM  = traces(q).BM(xCSI);
        
        %Find pixel coordinates
        
%         gridC(q,xiCSI') = (yiCSI' - yBM) * ImageList(q).scaleY * 1000;
        gridC(q,xCSI') = (yCSI' - yBM') * ImageList(q).scaleY * 1000;
        gridW(q,xCSI') = wCSI';
        
    end
    
    validMask = ~isnan(gridC(:));
    
    %% Thickness Map, Expanded in Y and interpolated onto fundus
    
    % Indices In Fundus Image That Correspond To Cmap
    Xover = find( fxvec >= xvec(1) & fxvec <= xvec(end) );
    Yover = find( fyvec <= yvec(1) & fyvec >= yvec(end) );
    
    [qx,qy] = meshgrid(fxvec(Xover), fyvec(Yover));
    
    mapInfo = [gridx(validMask), gridy(validMask), gridC(validMask), gridW(validMask)];
    mapInfo = sortrows(mapInfo,[1,2]);
    
%     Cmap    = interp2(data(:,1),data(:,2),data(:,3),qx,qy,'spline');
%     Cmap    = interp2(gridx,gridy,gridC,qx,qy,'spline');
    
    F = scatteredInterpolant(mapInfo(:,1),mapInfo(:,2),mapInfo(:,3));
    Cmap = F(qx,qy);
    
    Volume     = fscaleX*fscaleY*(sum(Cmap(:))./1000);
    
    newRbscan  = imref2d(size(Cmap),[qx(1,1) qx(1,end)],[qy(1,1) qy(end,1)]);
    
    Cmapscaled = im2uint8(Cmap/max(Cmap(:)));
    X          = grayslice(Cmapscaled,256);
    CmapRGB    = ind2rgb(X,jet(256));
    CmapHSV    = rgb2hsi(CmapRGB);
    
    fundimHSV  = rgb2hsi(fundim);
    
    fundimHSV(Yover,Xover,1) = CmapHSV(:,:,1);
    fundimHSV(Yover,Xover,2) = CmapHSV(:,:,2);
    fundimHSV(:,:,3)=k;
    fundimfinal=hsi2rgb(fundimHSV);
    
    fh = figure('Visible','off');
    subplot(1,2,1);
    imshow(fundimfinal,Rfund,colormap('jet'));
%     image(fundimfinal,Rfund), colormap('jet');
    xlabel('Fundus X Position [mm]')
    ylabel('Fundux Y Position [mm]')
    title('Fundus Cam View')
    
    subplot(1,2,2);
    h3 = imshow(Cmap,newRbscan,colormap('jet'));
    set(h3,'cdatamapping','scaled');
    caxis([0 500])
%     cbar=colorbar;
    colorbar;
    
    % hold on
    % h3=imshow(Cmap,colormap('jet'));
    % set(h3,'cdatamapping','scaled');
    xlabel('Fundus X Position [mm]')
    ylabel('Fundux Y Position [mm]')
    title('Choroidal Thickness Map [\mum]')
%     save(fullfile(directory,'Results','ChoroidMap.mat'),'Cmap','Volume','fundim','fundimfinal',...
%         'xvec','yvec','gridx','gridy','gridC','fscaleX','fscaleY','fwidth',...
%         'fheight','mapInfo');

%     save(fullfile(directory,'Results','Results.mat'),'Cmap','Volume','fundim','fundimfinal',...
%         'xvec','yvec','gridx','gridy','gridC','fscaleX','fscaleY','fwidth',...
%         'fheight');
%     saveas(gcf,fullfile(directory,'Results','ChoroidMap.jpg'),'jpg');
%     saveas(gcf,fullfile(directory,'Results','ChoroidMap.pdf'),'pdf');

    %Testing Gabor
    save(fullfile(directory,'Results','ChoroidMapGabor2.mat'),'Cmap','Volume','fundim','fundimfinal',...
    'xvec','yvec','gridx','gridy','gridC','fscaleX','fscaleY','fwidth',...
    'fheight','mapInfo');
    
    saveas(fh,fullfile(directory,'Results','ChoroidMapGabor2.pdf'),'pdf');

    catch exception
        errorString = ['Error ChoroidMap. Message: ' exception.message ' at: ' directory];
        errorString = [errorString buildCallStack(exception)];
        
        disp(logit(directory,errorString));

        continue
    end 
    
    close(fh)
    
    disp(logit(directory,['Done ChoroidMap:' directory]));
    
end

    close all
end





