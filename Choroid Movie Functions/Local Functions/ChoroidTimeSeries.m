function [Output] = ChoroidTimeSeries(Vchecked,inclframelist,directory,savedir)

contents = dir(fullfile(directory,'Data Files'));

load(fullfile(directory,'Data Files','ImageList.mat'));

heartfile = any(strcmp({contents(:).name}','HeartInfo.mat'));

if heartfile
    
    load(fullfile(directory,'Data Files','HeartInfo.mat'));
    
    %Parse Heartfile Time data
    hrttime=(60.*(abs(hrtdata(:,1)-floor(hrtdata(:,1)))*100)+hrtdata(:,2));
    hrtseries(:,1)=hrttime(find(hrtdata(:,4),1,'first'):find(hrtdata(:,4),1,'last'),1);
    hrtseries(:,2)=hrtdata(find(hrtdata(:,4),1,'first'):find(hrtdata(:,4),1,'last'),3);
    
    %Parse Image Time data
    imtime=(60.*[ImageList.minute]+[ImageList.second]);
    imtime=imtime(inclframelist);
    
    % Zero both Heart and Image Time
    timeoffset=min(imtime(1),hrtseries(1,1));
    imtime=imtime-timeoffset;
    hrtseries(:,1)=hrtseries(:,1)-timeoffset;
    
    % Heart Power Spectrum
    [wk1h,wk2h,~,~,Fh]=lspr(hrtseries(:,1)',hrtseries(:,2)',2,4);

    % Total Volume Power Spectrum
    
    [wk1v,wk2v,~,~,Fv]=lspr(imtime,Vchecked,2,4);
       
    Output={wk2v,wk1v,wk2h,wk1h,imtime,hrtseries,Fv,Fh};
else
   
    %Parse Image Time data
    imtime = 60 * [ImageList.minute] + [ImageList.second];
    imtime = imtime(inclframelist);
    imtime = imtime-imtime(1);
    
    % Total Volume Power Spectrum
    [wk1v,wk2v,~,~,Fv]=lspr(imtime,Vchecked,2,4);
       
    Output = {wk2v,wk1v,NaN,NaN,imtime,NaN,Fv,NaN};
    
    
%     imtime=(60.*[ImageList.minute]+[ImageList.second]);
%     imtime=imtime(inclframelist);
%     timeoffset=imtime(1);
%     imtime=imtime-timeoffset;
%     
%     figure(3)
%     hold all
%     plot(imtime,Vchecked)
%     xlabel('Time (s)')
%     ylabel('Choroid Volume [Pixels]')
%     saveas(gcf,fullfile(savedir,'Volume Change.fig'));
%     
%     Output={imtime};
end
end

