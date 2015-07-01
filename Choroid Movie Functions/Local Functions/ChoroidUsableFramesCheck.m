function [Vchecked,inclframelist,Endcheck,CSIcheck,Vcheck,LEndFail,REndFail] = ChoroidUsableFramesCheck(numframes,Vframe,EndHeights,newEndHeights,usedEndHeights,traces)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%% Determine Usable Frames
frames=1:numframes;

usedLmeanHeight=median(usedEndHeights(~isnan(usedEndHeights(:,1)),1));
usedLstdHeight=std(usedEndHeights(~isnan(usedEndHeights(:,1)),1));
usedRmeanHeight=mean(usedEndHeights(~isnan(usedEndHeights(:,2)),2));
usedRstdHeight=std(usedEndHeights(~isnan(usedEndHeights(:,2)),2));

usedVmean=median(Vframe(Vframe~=0 & ~isnan(Vframe)));
usedVstd=std(Vframe(Vframe~=0 & ~isnan(Vframe)));

nLmeanHeight=mean(newEndHeights(~isnan(newEndHeights(:,1)),1));
nLstdHeight=std(newEndHeights(~isnan(newEndHeights(:,1)),1));
nRmeanHeight=mean(newEndHeights(~isnan(newEndHeights(:,2)),2));
nRstdHeight=std(newEndHeights(~isnan(newEndHeights(:,2)),2));

LmeanHeight=mean(EndHeights(~isnan(EndHeights(:,1)),1));
LstdHeight=std(EndHeights(~isnan(EndHeights(:,1)),1));
RmeanHeight=mean(EndHeights(~isnan(EndHeights(:,2)),2));
RstdHeight=std(EndHeights(~isnan(EndHeights(:,2)),2));

%Endheight Allowance
Allowed=20;
Endcheck=usedEndHeights(:,1) >= usedLmeanHeight-Allowed & ...
    usedEndHeights(:,1) <= usedLmeanHeight+Allowed & ...
    usedEndHeights(:,2) >= usedRmeanHeight-Allowed & ...
    usedEndHeights(:,2) <= usedRmeanHeight+Allowed & ...
    usedEndHeights(:,1) >= 0 & usedEndHeights(:,2) >= 0;

LEndFail =~(usedEndHeights(:,1) >= usedLmeanHeight-Allowed*usedLstdHeight & ...
    usedEndHeights(:,1) <= usedLmeanHeight+Allowed*usedLstdHeight & ...
      usedEndHeights(:,1) >= 0);
REndFail = ~(usedEndHeights(:,2) >= usedRmeanHeight-Allowed*usedRstdHeight & ...
    usedEndHeights(:,2) <= usedRmeanHeight+Allowed*usedRstdHeight & ...
    usedEndHeights(:,2) >= 0);

CSIcheck=~(cellfun(@length,cellfun(@isnan,traces,'uniformoutput',0))==1)';

%Volume Allowance
Allowed2=4000;

Vcheck=Vframe>=usedVmean-Allowed2 & Vframe<=usedVmean+Allowed2;
% Vcheck=Vtotal <= usedVmedian+mult2*usedVstd & ...
%     Vtotal >= usedVmedian-mult2*usedVstd;

inclframelist=frames(Endcheck&CSIcheck&Vcheck);
Vchecked=Vframe(logical(Endcheck&CSIcheck&Vcheck));

usedLEndheights=usedEndHeights(:,1);
usedREndheights=usedEndHeights(:,2);
nLEndheights=newEndHeights(:,1);
nREndheights=newEndHeights(:,2);
LEndheights=EndHeights(:,1);
REndheights=EndHeights(:,2);
 
% figure(160)
% plot(LEndheights,'r.')
% hold on
% plot(nLEndheights,'b.')
% plot(frames(Endcheck),usedLEndheights(Endcheck),'go')
% 
% legend('Left RPE-CSI Distance-Old','Left RPE-CSI Distance-Rerun','Left RPE-CSI Distance-Used');
% 
% plot(1:length(LEndheights),repmat(LmeanHeight,length(LEndheights),1),'r')
% plot(1:length(LEndheights),repmat(LmeanHeight-2*LstdHeight,length(LEndheights),1),'r--')
% plot(1:length(LEndheights),repmat(LmeanHeight+2*LstdHeight,length(LEndheights),1),'r--')
% 
% plot(1:length(nLEndheights),repmat(nLmeanHeight,length(nLEndheights),1),'b')
% plot(1:length(nLEndheights),repmat(nLmeanHeight-2*nLstdHeight,length(nLEndheights),1),'b--')
% plot(1:length(nLEndheights),repmat(nLmeanHeight+2*nLstdHeight,length(nLEndheights),1),'b--')
% 
% 
% plot(1:length(usedLEndheights),repmat(usedLmeanHeight,length(usedLEndheights),1),'g')
% plot(1:length(usedLEndheights),repmat(usedLmeanHeight-2*usedLstdHeight,length(usedLEndheights),1),'g--')
% plot(1:length(usedLEndheights),repmat(usedLmeanHeight+2*usedLstdHeight,length(usedLEndheights),1),'g--')
% 
% 
% figure(170)
% plot(REndheights,'r.')
% hold on
% plot(nREndheights,'b.')
% plot(frames(Endcheck),usedREndheights(Endcheck),'go')
% 
% legend('Right RPE-CSI Distance-Old','Right RPE-CSI Distance-Rerun','Right RPE-CSI Distance-Used');
% 
% plot(1:length(REndheights),repmat(RmeanHeight,length(REndheights),1),'r')
% plot(1:length(REndheights),repmat(RmeanHeight-2*RstdHeight,length(REndheights),1),'r:')
% plot(1:length(REndheights),repmat(RmeanHeight+2*RstdHeight,length(REndheights),1),'r:')
% 
% plot(1:length(nREndheights),repmat(nRmeanHeight,length(nREndheights),1),'b')
% plot(1:length(nREndheights),repmat(nRmeanHeight-2*nRstdHeight,length(nREndheights),1),'b:')
% plot(1:length(nREndheights),repmat(nRmeanHeight+2*nRstdHeight,length(nREndheights),1),'b:')
% 
% plot(1:length(usedREndheights),repmat(usedRmeanHeight,length(usedREndheights),1),'g')
% plot(1:length(usedREndheights),repmat(usedRmeanHeight-2*usedRstdHeight,length(usedREndheights),1),'g--')
% plot(1:length(usedREndheights),repmat(usedRmeanHeight+2*usedRstdHeight,length(usedREndheights),1),'g--')
% 
% 
% hold off
% 
% figure(180)
% plot(frames(Vframe~=0),Vframe(Vframe~=0),'b.')
% hold all
% plot(repmat(usedVmean,length(Vframe),1),'k')
% plot(repmat(usedVmean+2*usedVstd,length(Vframe),1),'k--')
% plot(repmat(usedVmean-2*usedVstd,length(Vframe),1),'k--')
% plot(frames(Vcheck),Vframe(Vcheck),'go')


end

