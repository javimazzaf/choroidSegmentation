function choroidMap(varargin)

dirlist = adaptToHMRpath(varargin{1});
% dirlist = varargin{1};

for iter = 1:numel(dirlist)
    
    folder = dirlist{iter};
    
    disp(logit(folder,['Starting ChoroidMap' folder]));
    
    try
        
        load(fullfile(folder,'Results','segmentationResults.mat'));
        load(fullfile(folder,'DataFiles','RegisteredImages.mat'));
        load(fullfile(folder,'DataFiles','ImageList.mat'),'ImageList','fundusIm');
        
        %-% Fundus Info
        fwidth  = ImageList{1,'fwidth'};
        fheight = ImageList{1,'fheight'};
        fscaleX = ImageList{1,'fscaleX'};
        fscaleY = ImageList{1,'fscaleY'};
        
        fundim = fundusIm(:,:,1);
        fundim = intrans(fundim,'stretch',mean2(im2double(fundim)),2);
        Rfund    = imref2d(size(fundim),[0 fwidth*fscaleX],[0 fheight*fscaleY]);
        fxvec    = linspace(Rfund.XWorldLimits(1),Rfund.XWorldLimits(end),Rfund.ImageSize(1));
        fyvec    = linspace(Rfund.YWorldLimits(1),Rfund.YWorldLimits(end),Rfund.ImageSize(2));
        
        %% BScan Info
        width  = ImageList{1, 'width'};
        cropLimits = dlmread(fullfile(folder, 'DataFiles', 'TrimInfo.txt'),',');
        
        xvec = linspace(ImageList{start,'startX'} + (cropLimits(1)-1)     * ImageList{start, 'scaleX'},...
            ImageList{start,'endX'}   - (width-cropLimits(2)) * ImageList{start, 'scaleX'},...
            size(bscanstore{1},2));
        
        yvec = ImageList.startY;
        
        [gridx,gridy] = meshgrid(xvec,yvec);
        
        gridC = NaN(numel(yvec), numel(xvec));
        gridW = NaN(numel(yvec), numel(xvec)); % Weights
        
        gridRetina = NaN(numel(yvec), numel(xvec));
        
        for q = start:length(traces)
            
            if isempty(traces(q).RPEheight) || isempty(traces(q).CSI), continue, end
            
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
            
            yTop  = traces(q).RPEheight;
            
            %Find pixel coordinates
            gridC(q,xCSI') = (yCSI' - yTop) * ImageList{q,'scaleY'} * 1000;
            gridW(q,xCSI') = wCSI';
            
            RETthickness = traces(q).RETthickness  * ImageList{q,'scaleY'} * 1000;
            
            if ~isempty(RETthickness)
                gridRetina(q,:) = RETthickness';
            end
            
        end
        
        validMask = ~isnan(gridC(:));
        
        %% Thickness Map, Expanded in Y and interpolated onto fundus
        
        % Indices In Fundus Image That Correspond To Cmap
        Xover = find( fxvec >= xvec(1) & fxvec <= xvec(end) );
        Yover = find( fyvec <= yvec(1) & fyvec >= yvec(end) );
        
        [qx,qy] = meshgrid(fxvec(Xover), fyvec(Yover));
        
        mapInfo = [gridx(validMask), gridy(validMask), gridC(validMask), gridW(validMask)];
        mapInfo = sortrows(mapInfo,[1,2]);
        
        validRETMask = ~isnan(gridRetina(:));
        mapRetina    = [gridx(validRETMask), gridy(validRETMask), gridRetina(validRETMask)];
        
        % Compute retina thickness map
        Fret = scatteredInterpolant(mapRetina(:,1),mapRetina(:,2),mapRetina(:,3),'natural','nearest');
        CretMap = Fret(qx,qy);
        
        newRetbscan  = imref2d(size(CretMap),[qx(1,1) qx(1,end)],[qy(1,1) qy(end,1)]);
        
        CretMapScaled = im2uint8(CretMap/max(CretMap(:)));
        X             = grayslice(CretMapScaled,256);
        CretMapRGB    = ind2rgb(X,jet(256));
        CretMapHSV    = rgb2hsi(CretMapRGB);
        
        fundimRetHSV  = rgb2hsi(fundusIm);
        
        fundimRetHSV(Yover,Xover,1) = CretMapHSV(:,:,1);
        fundimRetHSV(Yover,Xover,2) = CretMapHSV(:,:,2);
        fundimRetHSV(:,:,3)=fundim;
        fundimRetFinal=hsi2rgb(fundimRetHSV);
        
        fh = figure('Visible','off');
        axes('Visible','off');
        subplot(1,2,1), imshow(fundimRetFinal,Rfund,colormap('jet'));
        xlabel('X [mm]')
        ylabel('Y [mm]')
        title('Retina thickess overlay')
        
        subplot(1,2,2);
        h3 = imshow(CretMap,newRetbscan,colormap('jet'));
        set(h3,'cdatamapping','scaled');
        %     caxis([0 500])
        colorbar;
        
        xlabel('X [mm]')
        ylabel('Y [mm]')
        title('Retina Thickness Map [\mum]')
        
        saveas(fh,fullfile(folder,'Results','ChoroidMapRetina.pdf'),'pdf');
        close(fh)
        
        % Compute choroid map
        F = scatteredInterpolant(mapInfo(:,1),mapInfo(:,2),mapInfo(:,3),'natural','nearest');
        Cmap = F(qx,qy);
        
        newRbscan  = imref2d(size(Cmap),[qx(1,1) qx(1,end)],[qy(1,1) qy(end,1)]);
        
        Cmapscaled = im2uint8(Cmap/max(Cmap(:)));
        X          = grayslice(Cmapscaled,256);
        CmapRGB    = ind2rgb(X,jet(256));
        CmapHSV    = rgb2hsi(CmapRGB);
        
        fundimHSV  = rgb2hsi(fundusIm);
        
        fundimHSV(Yover,Xover,1) = CmapHSV(:,:,1);
        fundimHSV(Yover,Xover,2) = CmapHSV(:,:,2);
        fundimHSV(:,:,3)=fundim;
        fundimfinal=hsi2rgb(fundimHSV);
        
        fh = figure('Visible','off');
        axes('Visible','off');
        subplot(1,2,1);
        imshow(fundimfinal,Rfund,colormap('jet'));

        xlabel('Fundus X Position [mm]')
        ylabel('Fundux Y Position [mm]')
        title('Fundus Cam View')
        
        subplot(1,2,2);
        h3 = imshow(Cmap,newRbscan,colormap('jet'));
        set(h3,'cdatamapping','scaled');
        caxis([0 500])
        %     cbar=colorbar;
        colorbar;
        
        xlabel('Fundus X Position [mm]')
        ylabel('Fundux Y Position [mm]')
        title('Choroidal Thickness Map [\mum]')
        
        save(fullfile(folder,'Results','ChoroidMap.mat'),'Cmap','fundimfinal',...
            'xvec','yvec','gridx','gridy','gridC','fscaleX','fscaleY','fwidth',...
            'fheight','mapInfo','mapRetina');
        
        saveas(fh,fullfile(folder,'Results','ChoroidMap.pdf'),'pdf');
        
    catch exception
        errorString = ['Error ChoroidMap. Message: ' exception.message];
        errorString = [errorString buildCallStack(exception)];
        
        disp(logit(folder,errorString));
        
        continue
    end
    
    close(fh)
    
    disp(logit(folder,['Done ChoroidMap:' folder]));
    
end

close all

end





