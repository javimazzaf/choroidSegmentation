function [deltad2,deltad3,d2,SNR]=LSFilt(imtime,d,hifac,ofac,directory,savedir,updatefigs)
%%

distance=d;

sT  = imtime;
sFn = distance;

fHR = GetHeartRate(directory)/60; % Convert BPM to [Hz]

% FastLomb + Cleaning
[wk1,wk2,~,~,F]=lspr(sT,(sFn-mean(sFn)).*hamming(length(sFn))',hifac,ofac);

% Manipulation of the Fourier spectrum F:
Fo = F;
f=(1:length(F)) * (wk1(2) - wk1(1))';
minf=.50*fHR;
maxf=fHR*3.1;
endf=2*f(end);

% Metric of Correlation
Fpeak=max(abs(F(f>(fHR-0.1) & f<(fHR+0.1))));
SNR=Fpeak/std(abs(F(f>minf & f<(endf-0.5))));


% Remove noise
noise_limit = max(abs(F((f>minf & f<maxf) | (f<(endf-minf) & f>(endf-maxf)))))/10;
ind = abs(F) < noise_limit ;
F(ind)=0; F(1)=Fo(1);
F(f<minf | (f>maxf & f<(endf-maxf)) | f>(endf-minf))=0;

% inverse Fourier transform
Fb=ifft(F);
d2=real(Fb);

%Correct time scale
tf = sT(1)+[0 (1:length(F))/(wk1(2)-wk1(1))/length(F)];
ind = find(tf < sT(end));
tf=tf(ind);
d2=((d2(ind)-mean(d2(ind)))./(hamming(length(tf))')+mean(distance))';
% d2=smooth(tf,d2,3,'rloess');
%Undo correct window
% yf = yf./hamming(length(yf))';



[pks,locs,vals,locs2,meandist] = WindowedPeaks(d2,mean(d2),...
    round((fHR/3)/mode(diff(imtime))),0.0039);

if jbtest(d2(locs))
    meanpks=median(d2(locs));
else
    meanpks=mean(d2(locs));
end

if jbtest(d2(locs2))
    meanvals=median(d2(locs2));
else
    meanvals=mean(d2(locs2));
end

if updatefigs
    figure(1)
    subplot(2,1,2), h1=plot([fHR fHR],[0 max(abs(F))*1.25],'b--','linewidth',2.5); hold on
    subplot(2,1,2), plot([2*fHR 2*fHR],[0 max(abs(F))*1.5],'b--','linewidth',2.5);
    subplot(2,1,2), h2=plot(f(f<wk1(end)),abs(Fo(f<wk1(end))),'-k','linewidth',4);
    subplot(2,1,2), h3=plot(f(f<wk1(end)),abs(F(f<wk1(end))),'-r','linewidth',4); title('a)');
    xlim([0 wk1(end)]);
    ylim([0 max(abs(F))*1.05]);legend([h1 h2 h3],'1st & 2nd Heart Harmonics','F','F_{m}')
    xlabel('f [Hz]');ylabel('F [AU]')
    
    subplot(2,1,1), plot(sT,sFn*1000,'-k','linewidth',1.75), hold on
    subplot(2,1,1), plot(tf,d2*1000,'-r','linewidth',3), title('b)') ;legend('CT_{raw}','CT')
    xlim([0 max(tf(end),sT(end))])
    ylim([min(min(sFn),min(d2)) max(max(sFn),max(d2))]*1000)
    xlabel('Time [s]');ylabel('CT [\mum]')
    saveas(gcf,fullfile(savedir,'LombScargleFilter.fig'))
    
    figure(2)
    subplot(2,1,1), plot(tf,d2-mean(d2),'-r','LineWidth',2.5); title('a)')
    hold all

    set(gca,'Ytick',[],'ylim',[min(d2-mean(d2)) max(d2-mean(d2))]);    
    legend('CT')
    
    subplot(2,1,2)
    hold all
    plot(tf,d2*1000,'k.','marker','.','linestyle','-','linewidth',2)

    xlim([0 tf(end)])
    plot(tf(locs),(pks)*1000,'mo')
    plot(tf(locs2),(vals)*1000,'go')
    plot(tf,repmat(mean(d2*1000)+1000*meandist/2,1,length(tf)),'r--')
    plot(tf,repmat(mean(d2*1000)-1000*meandist/2,1,length(tf)),'r--')
    xlabel('Time [s]');ylabel('CT [\mum]')
    legend('CT','Allowed Peaks','Allowed Valleys','Mean of Peaks and Valleys')
    title('b)')
    saveas(gcf,fullfile(savedir,'FilteredPeak2Peak.fig'))
end

deltad2 = meandist;
deltad3 = meanpks - meanvals;

end
