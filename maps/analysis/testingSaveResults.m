function testingSaveResults(directory)

load(fullfile(directory,'Results','FirstProcessDataNew.mat')); %Get Traces
load(fullfile(directory,'Results','processedImages.mat'),'shiftedScans','safeTopLimit','safeBottomLimit'); %'avgScans'

shiftedScans = uint8(shiftedScans / max(shiftedScans(:)) * 255);

savedir = fullfile(directory,'Results','frames');

if ~exist(savedir,'dir'), mkdir(savedir), end

% Compute absolute max weight
maxWeight = -Inf;

for i=1:size(shiftedScans,3)
    for k = 1:numel(traces(i).CSI)
        maxWeight = max(maxWeight,max(traces(i).CSI(k).weight(:)));
    end
end

for i=1:size(shiftedScans,3)
    
    df = figure;
    
    if ~isnan(safeTopLimit(i)) && ~isnan(safeBottomLimit(i))
        imshow(shiftedScans(safeTopLimit(i):safeBottomLimit(i),:,i));
    else
        imshow(shiftedScans(:,:,i));
    end
    
    hold on
    
    clr = 'rgymcb';
    
    for k = 1:numel(traces(i).CSI)
        if ~(traces(i).CSI(k).keep), continue, end
        
        xCSI = traces(i).CSI(k).x(:);
        yCSI = traces(i).CSI(k).y(:);
        wCSI = traces(i).CSI(k).weight(:);
        
        errorbar(xCSI,yCSI,wCSI / maxWeight * 10,['.' clr(mod(k,6) + 1)])
        
    end
    
    if ~isempty(traces(i).RPEheight)
        plot(traces(i).RPEheight * ones(1,size(shiftedScans,2)),'-m','LineWidth',2)
    end
    
    hold off
    
    print(df,fullfile(savedir,['frame' num2str(i,'%03.0f') '.png']),'-dpng')
    
    close(df)
    
    disp(i)
end
end