clearvars


load('\\Hmr-brain\Share\SpectralisData\Results\info.mat')
load('\\Hmr-brain\Share\SpectralisData\Results\manualSegmentation.mat')
load('\\Hmr-brain\Share\SpectralisData\Results\TianFirstProcessData.mat')
Convergeset=varycolor(25);
vol=zeros(25,1);
deltavol=inf(25,1);
convdelta=nan(25,1);
ybest=cell(25,1);

for i=1:25
    numtraces=length(find(~cellfun(@isempty,y(i,:))));
    Colorset=varycolor(numtraces+3);
    
    bscan=images{i};
    yBM=traces(i).BM;
    midlevel=round(mean(yBM));
    colshifts=-(yBM-midlevel*ones(length(yBM),1));
    shiftsize=double(max(abs(colshifts)));
    
    csi=cell2mat(y(i,1:numtraces)');
    csi=csi-repmat(shiftsize+colshifts',size(csi,1),1);
    
%     figure(1)
%     imshow(bscan)
%     set(gca,'ColorOrder',Colorset)
%     
%     hold on
%     plot(csi')
%     legend(num2str((1:numtraces)'))
%     
    
    for j=1:numtraces
        vol(j)= sum(csi(j,:)-yBM');
    end
    
    for j=2:numtraces
        deltavolperc(i,j)=(vol(j)-vol(j-1))/vol(j-1);
    end
    
    for j=2:numtraces
        if abs(deltavolperc(i,j))<=0.1 && all(abs(deltavolperc(i,(j+1):end))<=0.1) && isnan(convdelta(i)) 
           convdelta(i)=j;
           ybest{i}=y{i,convdelta(i)}-colshifts'-shiftsize;
        else
            if isnan(convdelta(i))
                ybest{i}=nan;
            end
        end
    end
    
    
%     Conv=find(deltavol(i)<=0.05*mean(vol(i,j-1)),1,'first');
    
%     figure(2)
%     set(gca,'ColorOrder',Convergeset)
%     
%     hold on
%     plot(1:numtraces,abs(deltavolperc(i,1:numtraces)))
%     plot(convdelta(i),deltavolperc(i,convdelta(i)),'kd')
%     legend(num2str((1:25)'))
%    
%     close all
end

save('\\Hmr-brain\Share\SpectralisData\Results\BestCurve.mat','ybest','convdelta')