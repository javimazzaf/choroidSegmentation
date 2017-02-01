% Copyright (C) 2017, Javier Mazzaferri, Luke Beaton, Santiago Costantino 
% Hopital Maisonneuve-Rosemont, 
% Centre de Recherche
% www.biophotonics.ca
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

function choroidMovie(dirlist)

for q = 1:length(dirlist)
    
    folder = dirlist{q};
    
    dispInline('init',logit(folder,['Starting choroidMovie:' folder]));
    
    try
        
        load(fullfile(folder,'Results','segmentationResults.mat')); %Get Traces

        load(fullfile(folder,'Results','flattenedBscans.mat'),'shiftedScans','safeTopLimit','safeBottomLimit'); %'avgScans'
        
        shiftedScans = uint8(shiftedScans / max(shiftedScans(:)) * 255);
        
        load(fullfile(folder,'Results','ChoroidMap.mat')); %Get Map 
        
        df = figure('Visible','Off');

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
        
        if ~isnan(safeTopLimit(1)) && ~isnan(safeBottomLimit(1))
           subimage(shiftedScans(safeTopLimit(1):safeBottomLimit(1),:,1));
        else
           subimage(shiftedScans(:,:,1));
        end

        pos1=get(ax1,'position');
        pos2=get(ax2,'position');
        set(ax1,'Position',[pos1(1) pos2(2) pos2(3) pos2(4)])
        
        filename=fullfile(folder,'Results','choroidMovie.gif');
        
        % Compute absolute max weight
        maxWeight = -Inf;
        for p=1:length(yvec)
           for k = 1:numel(traces(p).CSI)
               
               thisWeight = max(traces(p).CSI(k).weight(:));
               
               if ~isempty(thisWeight)
                   maxWeight = max(maxWeight,thisWeight);
               end
               
           end
        end

        scansInfo = [];
        
        for p=1:length(yvec)

            h4=subplot(1,2,1);

            if ~isnan(safeTopLimit(p)) && ~isnan(safeBottomLimit(p))
              thisBscan = shiftedScans(safeTopLimit(p):safeBottomLimit(p),:,p);
            else
              thisBscan = shiftedScans(:,:,p);
            end
            
            subimage(thisBscan);
            
            thisScanInfo.bscan = thisBscan;
            
            set(h4,'visible','off')
            hold on
            
            allxCSI = [];
            allyCSI = [];
            allwCSI = [];
            
            clr = 'rgymcb';
            for k = 1:numel(traces(p).CSI)
                if ~(traces(p).CSI(k).keep), continue, end
                
                xCSI = traces(p).CSI(k).x(:);
                yCSI = traces(p).CSI(k).y(:);
                wCSI = traces(p).CSI(k).weight(:);
                
                errorbar(xCSI,yCSI,wCSI / maxWeight * 10,['.' clr(mod(k,6) + 1)])
                
                allxCSI = [allxCSI; xCSI];
                allyCSI = [allyCSI; yCSI];
                allwCSI = [allwCSI; wCSI / maxWeight * 10];
                
            end
            
            thisScanInfo.xCSI = allxCSI;
            thisScanInfo.yCSI = allyCSI;
            thisScanInfo.wCSI = allwCSI;
            
            if ~isempty(traces(p).RPEheight)
              subplot(1,2,1), plot(traces(p).RPEheight * ones(1,size(shiftedScans,2)),'-m','LineWidth',2)
              thisScanInfo.RPE = traces(p).RPEheight;
            else
              thisScanInfo.RPE = [];  
            end
            
            hold off
            
            subplot(1,2,2)
            hold on
            h5 = plot(xvec,repmat(yvec(p),length(xvec),1),'k--','linewidth',1.5);
            hold off
            drawnow
 
            auxfname = fullfile(folder,'Results','auxChoroidMovie.png');
            
            print(df,auxfname,'-dpng')
            im = imread(auxfname);
            [imind,cm]=rgb2ind(im,256);
            
            if p==1
                imwrite(imind,cm,filename,'gif','Loopcount',inf)
            else
                imwrite(imind,cm,filename,'gif','Writemode','append')
            end
            
            delete(h5)
            
            scansInfo = [scansInfo thisScanInfo];
            
            dispInline('update',logit(folder,['choroidMovie. processing Frame: ' num2str(p)]));
        end
        
        save(fullfile(folder,'Results','bScans.mat'), 'scansInfo')
        
        delete(auxfname);
        
    catch exception
        errorString = ['Error choroidMovie:' folder '. Message:' exception.message];
        errorString = [errorString buildCallStack(exception)];
        
        dispInline('end',logit(folder,errorString));
        
        close all
        continue
    end
    
    dispInline('end',logit(folder,['Done choroidMovie:' folder]));
    
    close all
end

end

