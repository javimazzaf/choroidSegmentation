function testingChoroidMapFirstProcess(directory)
% This function segments the retina interface, RPE, Bruchs membrane and the
% coroid-sclera interface, in each frame in the array bscanstore in the
% file RegisteredImages.mat for each directory in varargin{1}.

savedir   = fullfile(directory,'Results');
if ~exist(savedir,'dir'), mkdir(savedir), end

disp(['Starting testingChoroidFirstProcess: ' directory])

if ~exist(fullfile(savedir,'processedImages.mat'),'file')
    testingPreProcessFrames(directory,6/1000,6/100);
end

varStruct = load(fullfile(savedir,'processedImages.mat'),'avgScans','indToProcess','RPEheight');
avgScans     = varStruct.avgScans;
indToProcess = varStruct.indToProcess;
RPEheight    = varStruct.RPEheight;

if exist(fullfile(savedir,'FirstProcessDataNew.mat'),'file')
    varStruct = load(fullfile(savedir,'FirstProcessDataNew.mat'),'traces','other','EndHeights');
    traces = varStruct.traces;
    other = varStruct.other;
    EndHeights = varStruct.EndHeights;
end

%-% Iterate over frames of current subject
for frame = indToProcess
    try
        
        bscan = avgScans{frame};
        
        yCSI = getCSI(bscan,RPEheight(frame));
        
        if isempty(yCSI), continue, end
        
        EndHeights(frame,:) = [NaN NaN];
        
        %-% Store Other Relevant Variables
        traces(frame).RPEheight = RPEheight(frame);
        traces(frame).CSI = yCSI;
        
        
        disp(logit(savedir,['Succeeded frame:' num2str(frame)]));
        
    catch localExc
        errString = ['Error frame:' num2str(frame) ' ' localExc.message];
        errString = [errString buildCallStack(localExc)];
        disp(logit(savedir,errString));
    end
end

%-% Save Data
save(fullfile(savedir,'FirstProcessDataNew.mat'),'traces','other','EndHeights');

% Log & Display
disp(['Done ChoroidMapFirstProcess(iter=' num2str(iter) '): ' directory]);

end


