function MapMovieNew(varargin)
% Creates a movie showing the segmentation of individual bscans for every
% position of the map. It is mostly for debbuging purposes.

if length(varargin)==1
    if ispc
        dirlist = fullfile([filesep filesep 'HMR-BRAIN'],varargin{1});
    elseif ismac
        dirlist = fullfile([filesep 'Volumes'],varargin{1});
    else
        dirlist = fullfile(filesep,'srv','samba',varargin{1});
    end
else
    if ispc
        load(fullfile([filesep filesep 'HMR-BRAIN'],'share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
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
    
    disp(logit(directory,['Starting MapMovie:' directory]));
    
    try
        
        load(fullfile(directory,'Results','FirstProcessDataNew.mat')); %Get Traces
%         load(fullfile(directory,'Data Files','RegisteredImages.mat')); %Get Frames
        load(fullfile(directory,'Results','processedImages.mat'),'shiftedScans','safeTopLimit','safeBottomLimit'); %'avgScans'
        
        shiftedScans = uint8(shiftedScans / max(shiftedScans(:)) * 255);
        
%         load(fullfile(directory,'Results','ChoroidMap.mat')); %Get Map
        load(fullfile(directory,'Results','ChoroidMapNew.mat')); %Get Map 
        
        df = figure('Visible','Off');
%         df = figure();
        xlabel('Fundus X Position [mm]')
        ylabel('Fundux Y Position [mm]')
        title('Choroidal Thickness Map [\mum]')
        ax1 = subplot(1,2,2);
        h2 = subimage(fundimfinal);
        hold on
        set(h2,'ydata',get(h2,'ydata')*fscaleY)
        set(h2,'xdata',get(h2,'xdata')*fscaleX)
        xlim([0 fwidth*fscaleX])
        ylim([0 fheight*fscaleY])
        [~,h3] = contourf(gridx,gridy,gridC,50);
        set(h3,'linecolor','none')
        cb = colorbar('eastoutside');
        lims = get(cb,'ylim');
        vals = get(cb,'ytick');
        range=lims(2)-lims(1);
        inc=(vals-lims(1))/range;
        delete(h3);delete(cb);
        
        cb=colorbar('eastoutside');
        lims2=get(cb,'ylim');
        range2=lims2(2)-lims2(1);
        newpts=lims2(1)+range2*inc;
        
        set(cb,'ytick',newpts)
        set(cb,'yticklabel',vals)
        
        hold off
        set(ax1,'visible','off')
        
        ax2=subplot(1,2,1);
        
%         subimage(bscanstore{1});
        
        if ~isnan(safeTopLimit(1)) && ~isnan(safeBottomLimit(1))
           subimage(shiftedScans(safeTopLimit(1):safeBottomLimit(1),:,1));
        else
           subimage(shiftedScans(:,:,1));
        end

        pos1=get(ax1,'position');
        pos2=get(ax2,'position');
        set(ax1,'Position',[pos1(1) pos2(2) pos2(3) pos2(4)])
        
%         filename=fullfile(directory,'Results','MapMovie.gif');
        filename=fullfile(directory,'Results','MapMovieNew.gif');
        
%         df = gcf;
        
        %     if ~exist(fullfile(directory,'Results','singleFrames'),'dir')
        %         mkdir(fullfile(directory,'Results','singleFrames'));
        %     end
        
        % Compute absolute max weight
        maxWeight = -Inf;
        for i=1:length(yvec)
           for k = 1:numel(traces(i).CSI)
               
               thisWeight = max(traces(i).CSI(k).weight(:));
               
               if ~isempty(thisWeight)
                   maxWeight = max(maxWeight,thisWeight);
               end
               
           end
        end

        scansInfo = [];
        
        for i=1:length(yvec)
%             figure(df)
            h4=subplot(1,2,1);
%             subimage(bscanstore{i});
            if ~isnan(safeTopLimit(i)) && ~isnan(safeBottomLimit(i))
              thisBscan = shiftedScans(safeTopLimit(i):safeBottomLimit(i),:,i);
            else
              thisBscan = shiftedScans(:,:,i);
            end
            
            subimage(thisBscan);
            
            thisScanInfo.bscan = thisBscan;
            
            set(h4,'visible','off')
            hold on
            
            allxCSI = [];
            allyCSI = [];
            allwCSI = [];
            
            clr = 'rgymcb';
            for k = 1:numel(traces(i).CSI)
                if ~(traces(i).CSI(k).keep), continue, end
                
                xCSI = traces(i).CSI(k).x(:);
                yCSI = traces(i).CSI(k).y(:);
                wCSI = traces(i).CSI(k).weight(:);
                
                errorbar(xCSI,yCSI,wCSI / maxWeight * 10,['.' clr(mod(k,6) + 1)])
                
                allxCSI = [allxCSI; xCSI];
                allyCSI = [allyCSI; yCSI];
                allwCSI = [allwCSI; wCSI / maxWeight * 10];
                
            end
            
            thisScanInfo.xCSI = allxCSI;
            thisScanInfo.yCSI = allyCSI;
            thisScanInfo.wCSI = allwCSI;
            
%             [xCSI,ix,~] = unique(xCSI);
%             yCSI = yCSI(ix);
%             wCSI = wCSI(ix);
            
            %         [~,iCSI] = interpCSI(xCSI,yCSI, numel(traces(i).BM));
            %         plot(iCSI,'-r','LineWidth',2)
            
%             errorbar(xCSI,yCSI,wCSI / maxWeight * 10,'.r')
            
%             subplot(1,2,1), plot(traces(i).BM,'-m','LineWidth',2)
            if ~isempty(traces(i).RPEheight)
              subplot(1,2,1), plot(traces(i).RPEheight * ones(1,size(shiftedScans,2)),'-m','LineWidth',2)
              thisScanInfo.RPE = traces(i).RPEheight;
            else
              thisScanInfo.RPE = [];  
            end
            
            hold off
            
            subplot(1,2,2)
            hold on
            h5 = plot(xvec,repmat(yvec(i),length(xvec),1),'k--','linewidth',1.5);
            hold off
            drawnow
%             frame=getframe(df);
%             im=frame2im(frame);
 
            print(df,'~/aux.png','-dpng')
            im = imread('~/aux.png');
            [imind,cm]=rgb2ind(im,256);
            
            if i==1
                imwrite(imind,cm,filename,'gif','Loopcount',inf)
            else
                imwrite(imind,cm,filename,'gif','Writemode','append')
            end
            
            delete(h5)
            
            scansInfo = [scansInfo thisScanInfo];
            
            %         ff = figure();
            %         imshow(bscanstore{i},[],'Border','tight'); hold on
            %         plot(traces(i).BM,'-m','LineWidth',2)
            %         errorbar(xCSI,yCSI,wCSI * 10,'.r')
            %         hold off
            %         print(ff,fullfile(directory,'Results','singleFrames',['frame_' num2str(i) '.pdf']),'-dpdf')
            %         close(ff);
            
            disp(i)
        end
        
        save(fullfile(directory,'Results','bScans.mat'), 'scansInfo')
        
        delete('~/aux.png')
        
    catch exception
        errorString = ['Error MapMovie:' directory '. Message:' exception.message];
        errorString = [errorString buildCallStack(exception)];
        
        disp(logit(directory,errorString));
        
        close all
        continue
    end
    
    disp(logit(directory,['Done MapMovie:' directory]));
    
    close all
end

end

