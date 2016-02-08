function [HR] = GetHeartRate(directory)

% JM: First check the database for the heart rate 
if exist(fullfile(directory,'Data Files','VisitData.mat'),'file') 
   load(fullfile(directory,'Data Files','VisitData.mat'),'visitdata');
   
   if exist('visitdata','var') && any(strncmp('HR',visitdata.Properties.VariableNames,2))
       HR = visitdata.HR;
       if iscell(HR)
           HR = HR{:}; 
       end
       
       return
   end
end

% JM: If the HR is not in the database, it computes it from the oximeter trace

load(fullfile(directory,'Data Files','HeartInfo.mat'))
%Parse Heartfile Time data
hrttime=(60.*(abs(hrtdata(:,1)-floor(hrtdata(:,1)))*100)+hrtdata(:,2));
hrtseries(:,1)=hrttime(find(hrtdata(:,4),1,'first'):find(hrtdata(:,4),1,'last'),1);
hrtseries(:,2)=hrtdata(find(hrtdata(:,4),1,'first'):find(hrtdata(:,4),1,'last'),3);

[Ph,fh,~]=fastlomb(hrtseries(:,2),hrtseries(:,1),[],3,4);
fh=fh(fh<5);
Ph=Ph(fh<5);
[pks,locs]=findpeaks(Ph/max(Ph(:)),'minpeakheight',0.8);
% figure
% plot(fh,Ph)
% hold on
% plot(fh(locs),pks*max(Ph(:)),'ro');
HR=fh(locs(pks==max(pks)))*60;


