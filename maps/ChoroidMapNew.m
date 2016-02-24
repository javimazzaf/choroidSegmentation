function ChoroidMapNew(varargin)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if length(varargin) == 1
    if ispc
        dirlist = fullfile([filesep filesep 'HMR-BRAIN'],varargin{1});
    elseif ismac
        dirlist = fullfile([filesep 'Volumes'],varargin{1});
    else
        dirlist = fullfile(filesep,'srv','samba',varargin{1});
    end
else
    if ispc
        load(fullfile([filesep filesep 'HMR-BRAIN'],'Share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
        dirlist=fullfile([filesep filesep 'HMR-BRAIN'],dirlist);
    else
        load(fullfile(filesep,'srv','samba','Share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
        dirlist=fullfile(filesep,'srv','samba',strrep(dirlist,'\','/'));
    end
    [missdata,missraw,missprocessim,missregims,missresults]=CheckDirContents(dirlist);
    FirstProcess=logical(cellfun(@exist,fullfile(dirlist,'Results','FirstProcessData.mat')));
    Map=~cellfun(@isempty,regexp(dirlist,'Choroidal Mapping','match'));
    dirlist=dirlist(FirstProcess&Map);
    if isempty(dirlist)
        errordlg('No diretories prerequisite data. Run ChoroidFirstProcess.m first')
        return
    end
end

for iter=1:length(dirlist)
    directory=dirlist{iter};
    
    disp(logit(directory,['Starting ChoroidMap:' directory]));
    
    try
    
    load(fullfile(directory,'Results','FirstProcessDataNew.mat'));
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
%         [xiCSI,yiCSI] = interpCSI(xCSI,yCSI, length(traces(q).BM));
        
        yTop  = traces(q).RPEheight;
        
        %Find pixel coordinates
        
%         gridC(q,xiCSI') = (yiCSI' - yBM) * ImageList(q).scaleY * 1000;
        gridC(q,xCSI') = (yCSI' - yTop) * ImageList(q).scaleY * 1000;
        gridW(q,xCSI') = wCSI';
        
        RETthickness = traces(q).RETthickness  * ImageList(q).scaleY * 1000;
        
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
    mapRetina = [gridx(validRETMask), gridy(validRETMask), gridRetina(validRETMask)];
    
    % Compute retina thickness map
    Fret = scatteredInterpolant(mapRetina(:,1),mapRetina(:,2),mapRetina(:,3));
    CretMap = Fret(qx,qy);
    
    newRetbscan  = imref2d(size(CretMap),[qx(1,1) qx(1,end)],[qy(1,1) qy(end,1)]);
    
    CretMapScaled = im2uint8(CretMap/max(CretMap(:)));
    X             = grayslice(CretMapScaled,256);
    CretMapRGB    = ind2rgb(X,jet(256));
    CretMapHSV    = rgb2hsi(CretMapRGB);
    
    fundimRetHSV  = rgb2hsi(fundim);
    
    fundimRetHSV(Yover,Xover,1) = CretMapHSV(:,:,1);
    fundimRetHSV(Yover,Xover,2) = CretMapHSV(:,:,2);
    fundimRetHSV(:,:,3)=k;
    fundimRetFinal=hsi2rgb(fundimRetHSV);
    
    fh = figure('Visible','off');
    subplot(1,2,1);
    imshow(fundimRetFinal,Rfund,colormap('jet'));
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

    saveas(fh,fullfile(directory,'Results','ChoroidMapNewRetina.pdf'),'pdf');
    close(fh)
    
    % Compute choroid map
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
    save(fullfile(directory,'Results','ChoroidMapNew.mat'),'Cmap','Volume','fundim','fundimfinal',...
    'xvec','yvec','gridx','gridy','gridC','fscaleX','fscaleY','fwidth',...
    'fheight','mapInfo','mapRetina');
    
    saveas(fh,fullfile(directory,'Results','ChoroidMapNew.pdf'),'pdf');

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





