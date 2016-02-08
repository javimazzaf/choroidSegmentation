function [Output] = ChoroidTimeSeries(Vchecked,inclframelist,directory)

load(fullfile(directory,'Data Files','ImageList.mat'),'ImageList');

% Set default values
wk2h      = NaN;
wk1h      = NaN;
hrtseries = NaN;
Fh        = NaN;
Output    = {NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN};

%Parse Image Time data
imtime = 60 * [ImageList.minute] + [ImageList.second];
imtime = imtime(inclframelist);

if isempty(imtime), return, end

timeoffset = imtime(1);

if exist(fullfile(directory,'Data Files','HeartInfo.mat'),'file')
    
    load(fullfile(directory,'Data Files','HeartInfo.mat'),'hrttime','hrtdata');
    
    %Parse Heartfile Time data
    hrttime = 60 * (abs(hrtdata(:,1) - floor(hrtdata(:,1))) * 100) + hrtdata(:,2);
    hrtTimeRange = find(hrtdata(:,4),1,'first'):find(hrtdata(:,4),1,'last');
    
    if ~isempty(hrtTimeRange)
        
        hrtseries = [hrttime(hrtTimeRange,1), hrtdata(hrtTimeRange,3)];
        
        % Zero both Heart and Image Time
        timeoffset = min(imtime(1),hrtseries(1,1));
        
        hrtseries(:,1)=hrtseries(:,1)-timeoffset;
        
        % Heart Power Spectrum
        [wk1h,wk2h,~,~,Fh] = lspr(hrtseries(:,1)',hrtseries(:,2)',2,4);
        
    end
    
end

% Bring imtime to the offset
imtime = imtime - timeoffset;

% Total Volume Power Spectrum
[wk1v,wk2v,~,~,Fv] = lspr(imtime,Vchecked,2,4);

Output = {wk2v,wk1v,wk2h,wk1h,imtime,hrtseries,Fv,Fh};

end

