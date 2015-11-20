function ChoroidMakeFigures(varargin)

% Creates figures from the segmentation results.
% Arguments:
%  - relativePathData: cell array of strings with the path of all
%                      patients to make figures
%  - Viz (opt): Flag indicating if it generates a folder containing an image
%               for each frame and the segmentation result overlayed.
%  - Base for data path (opt): String with a base path where to find the 
%                              data. It is for debugging purpose if the 
%                              results of first and post process have been 
%                              stored in a non-default folder. If ommitted
%                              it uses the default path in HMR-Brain:
%                              /srv/samba/share . . . 

viz = false; %Default visualisation = OFF

if nargin == 0
    throw(MException('ChoroidFirstProcess:NotEnoughArguments','Not enough arguments.'))
end

% First argument
if nargin < 3
    if ispc,       dataBaseDir = [filesep filesep 'HMR-BRAIN'];
     elseif ismac, dataBaseDir = [filesep 'Volumes'];
     else          dataBaseDir = [filesep 'srv' filesep 'samba'];
    end
    
    dirlist    = fullfile(dataBaseDir,varargin{1});
end

% Second argument
if nargin >= 2
    viz = varargin{2}; 
end

% Third argument
if nargin >=3
    dirlist    = fullfile(varargin{3},varargin{1});
end

% *** Code starts ***

for iter=1:length(dirlist)
   try
    directory=dirlist{iter};
    numframes=length(dir(fullfile(directory,'Processed Images','*.png')));
    
    savedir=fullfile(directory,'Results');
    
    disp(logit(savedir,['ChoroidMakeFigures - Starting: ' savedir]))
    
    load(fullfile(savedir,'FirstProcessData.mat'));
    load(fullfile(savedir,'PostProcessData.mat'));
    load(fullfile(directory,'Data Files','RegisteredImages.mat'));
    
    noCSI   = ~cell2mat(cellfun(@isempty,cellfun(@find,cellfun(@isnan,cellfun(@min,{traces.usedCSI},'uniformoutput',0),'uniformoutput',0),'uniformoutput',0),'uniformoutput',0));
    meanCSI = mean([traces(~noCSI).usedCSI],2);
    
    % load(fullfile(directory,'Data Files','RegisteredImages.mat');
    %% %%%%%%%%%%%%%%%%%%%%%% Analysis %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [Vchecked,inclframelist,Endcheck,CSIcheck,Vcheck,LEndFail,REndFail] = ChoroidUsableFramesCheck(numframes,Vframe,EndHeights,newEndHeights,usedEndHeights,{traces.usedCSI});
    
    [Output] = ChoroidTimeSeries(Vchecked,inclframelist,directory,savedir);
    
    save(fullfile(savedir,'PostProcessData.mat'),'traces','newEndHeights','usedEndHeights','Vframe','Vchecked',...
        'inclframelist','Endcheck','CSIcheck','Vcheck','LEndFail','REndFail','numframes','Output');
    %% Assign Loaded Variables
    Pvt=Output{1};
    fvt=Output{2};
%     Ph=Output{3};
%     fh=Output{4};
%     imtime=Output{5};
    
    %% Visual Check on the Frames Included and Excluded from the Final
    % Timeseries
    allframes   = 1:numframes;
    alignheight = traces(inclframelist(1)).BM(1);
    traceoffset = nan(1,numframes);
    
    for i=1:numframes
        if ismember(i,skippedind) || isempty(traces(i).BM), continue, end
        
        temp=traces(i).BM;
        traceoffset(i) = alignheight - temp(1);
    end
    
    tracelength = length(traces(inclframelist(1)).BM);
    notinclCSI  = allframes(~CSIcheck&~isnan(traceoffset'));
    notinclEND  = allframes(~Endcheck&CSIcheck&~isnan(traceoffset'));
    notinclVOL  = allframes(~Vcheck&CSIcheck&Endcheck&~isnan(traceoffset'));
    
    im = bscanstore{inclframelist(1)};
    inclFh = figure('Visible','off');
    axes('Visible','off');
%     imshow(im)
    image(im,'CDataMapping','scaled')
    colormap(gray)
    axis off
    hold all
    plot([traces(inclframelist).BM]+repmat(traceoffset(inclframelist),tracelength,1))
    plot([traces(inclframelist).usedCSI]+repmat(traceoffset(inclframelist),tracelength,1))
    title('Summary Image, Included Frames')
    saveas(inclFh,fullfile(savedir,'Summary Image Included.png'))
    close(inclFh)
    disp(logit(savedir,'Summary Image Included - saved'))
    
    if ~isempty([traces(notinclEND).BM])
        exclEndFh = figure('Visible','off');
        axes('Visible','off');
%         imshow(im)
        image(im,'CDataMapping','scaled')
        colormap(gray)
        axis off
        hold all
        size([traces(notinclEND).usedCSI])
        size(notinclEND)
        plot([traces(notinclEND).BM]+repmat(traceoffset(notinclEND),tracelength,1))
        plot([traces(notinclEND).usedCSI]+repmat(traceoffset(notinclEND),tracelength,1))
        title('Summary Image, Excluded Frames, Endheight')
        saveas(exclEndFh,fullfile(savedir,'Summary Image Excluded End.png'))
        close(exclEndFh)
        disp(logit(savedir,'Summary Image Excluded End - saved'))
    end
    
    if ~isempty([traces(notinclVOL).BM])
        exclVolFh = figure('Visible','off');
        axes('Visible','off');
%         imshow(im)
        image(im,'CDataMapping','scaled')
        colormap(gray)
        axis off
        hold all
        plot([traces(notinclVOL).BM]+repmat(traceoffset(notinclVOL),tracelength,1))
        plot([traces(notinclVOL).usedCSI]+repmat(traceoffset(notinclVOL),tracelength,1))
        title('Summary Image, Excluded Frames, Volume')
        saveas(exclVolFh,fullfile(savedir,'Summary Image Excluded Volume.png'))
        close(exclVolFh)
        disp(logit(savedir,'Summary Image Excluded Volume - saved'))
    end
    
    load(fullfile(directory,'Data Files','ImageList.mat'));
    
    %Parse Image Time data
    imtime = (60.*[ImageList.minute]+[ImageList.second]);
    imtime = imtime(inclframelist);
    imtime = imtime - min(imtime(1));  
    
    % Plot volume time series
    volChangeFh = figure('Visible','off');
    axes('Visible','off');
    plot(imtime,Vchecked,'o-b');
    xlabel('Time (s)')
    ylabel('Choroid Volume [Pixels]')
    saveas(volChangeFh,fullfile(savedir,'Volume Change.png'));
    close(volChangeFh)
    disp(logit(savedir,'Volume Change Plot - saved'))
    
    % Plot Lomb-Scargle filter results
    LS_Fh = figure('Visible','off');
    axes('Visible','off');
    hold all
    plot(fvt(fvt>.25 & fvt<7),Pvt(fvt>.25 & fvt<7)/max(Pvt(fvt>.25 & fvt<7)),'b-')
    legend('Choroid')
    title('Lomb-Scargle Normalized Periodogram')
    xlabel('f [Hz]')
    ylabel('P(f) [Normalized]')
    xlim([0 7])
    
    %Draw line at heart rate
    HR = GetHeartRate(directory) / 60;
    yl = ylim();
    line([HR HR],yl,'Color','r','LineWidth',1)
    saveas(LS_Fh,fullfile(savedir,'FrequencyCorrelationTotal.png'));
    close(LS_Fh)
    disp(logit(savedir,'Frequency Correlation Total PLOT - saved'))
    
    % DELETE ONCE ROUNDING OF YCSI IN ALL STORED DATA
    usedEndHeights = round(usedEndHeights);
    Vchecked = round(Vchecked);
    for i = 1:length(traces)
        traces(i).usedCSI=round(traces(i).usedCSI);
    end
    
    %% Output Visualization
    if viz
        disp(logit(savedir,'Starting saving visualization of each frame.'))
        EndExclude=text2im('Excluded - EndHeight Check');
        EndExclude=padarray(~EndExclude,[50 50],'pre');
        [Endy,Endx]=size(EndExclude);
        VolExclude=text2im('Excluded - Volume Check');
        VolExclude=padarray(~VolExclude,[50 50],'pre');
        [Voly,Volx]=size(VolExclude);
        CSIExclude=text2im('Excluded - No CSI Path Found');
        CSIExclude=padarray(~CSIExclude,[50 50],'pre');
        [CSIy,CSIx]=size(CSIExclude);
        QualExclude=text2im('Excluded -Image Quality');
        QualExclude=padarray(~QualExclude,[50 50],'pre');
        [Qualy,Qualx]=size(QualExclude);
        
        LeftEndHeights=usedEndHeights(:,1);
        RightEndHeights=usedEndHeights(:,2);
        
        circle = strel('disk',7);
        
        mkdir(fullfile(savedir,'Visualization'));
        for i=1:numframes
            im=bscanstore{i};
            [imy,imx]=size(im);
            
            if ismember(i,skippedind)
                im=imoverlay(im,padarray(QualExclude,[imy-Qualy,imx-Qualx],'post'));
            else
                [m,n]=size(im);
                imRET=zeros(m,n);
                imRPE=zeros(m,n);
                imBM=zeros(m,n);
                imCSI=zeros(m,n);
                
                imRET(sub2ind([m,n],traces(i).RET(1:n),(1:n)'))=1;
                imRPE(sub2ind([m,n],traces(i).RPE(1:n),(1:n)'))=1;
                imBM(sub2ind([m,n],traces(i).BM(1:n),(1:n)'))=1;
                if any(isnan(traces(i).usedCSI))
                    imCSI=zeros(m,n);
                else
                    colinds=(1:n)';
                    inframe=traces(i).usedCSI<=m;
                    imCSI(sub2ind([m,n],traces(i).usedCSI(colinds(inframe(1:n))),colinds(inframe(1:n))))=1;
                end
                
                im=imoverlay(imoverlay(imoverlay(imoverlay(im,imRET,...
                    [1 0 0]),imRPE,[0 1 0]),imBM,[0 0 1]),imCSI,[1 1 0]);
                
                if ~CSIcheck(i)
                    im=imoverlay(im,padarray(CSIExclude,[imy-CSIy,imx-CSIx],'post'),[1 0 0]);
                elseif ~Endcheck(i) && CSIcheck(i)
                    disks=zeros(size(im(:,:,1)));
                    if LEndFail(i)
                        disks(LeftEndHeights(i)+traces(i).BM(1),1)=1;
                    end
                    if REndFail(i)
                        disks(RightEndHeights(i)+traces(i).BM(end),end)=1;
                    end
                    disks=bwmorph(imdilate(disks,circle),'remove');
                    im=imoverlay(imoverlay(im,padarray(EndExclude,[imy-Endy,imx-Endx],'post'),[1 0 0]),disks,[1 0 1]);
                    
                    
                elseif ~Vcheck(i)  && CSIcheck(i)  && Endcheck(i)
                    im=imoverlay(im,padarray(VolExclude,[imy-Voly,imx-Volx],'post'),[1 0 0]);
                else
                    k=numel(find(~Endcheck(1:i)|~CSIcheck(1:i)|~Vcheck(1:i)));
                    ImInclude=text2im(['Choroid Volume =' num2str(Vchecked(i-k)) ' pixels']);
                    ImInclude=padarray(~ImInclude,[50 50],'pre');
                    [Incly,Inclx]=size(ImInclude);
                    
                    im=imoverlay(im,padarray(ImInclude,[imy-Incly,imx-Inclx],'post'),[1 1 1]);
                    
                end
                
            end
            
            name=imlist(i).name;
            stop=find(name(:)=='.',1,'last');
            name=name(1:stop-1);
            imwrite(im,fullfile(savedir,'Visualization',[name '.jpg']),'JPG')
            disp(logit(savedir,['Saving ' name '.jpg']))
        end
    end
    
    disp(logit(savedir,['ChoroidMakeFigures - Done: ' savedir]))
    
   catch exception
       errString = ['Error ChoroidMakeFigures: ' savedir '. ' exception.message ' - ' buildCallStack(exception)];
       disp(logit(savedir,errString))
       continue
    end

end

