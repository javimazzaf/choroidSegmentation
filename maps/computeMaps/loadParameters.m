function parameters = loadParameters

parameters.averagingSizeX  = 5; % in pixels
parameters.averagingSizeZ  = 5; % in pixels
parameters.choroidMinWidth = 15; % in pixels
parameters.choroidMaxWidth = 150; % in pixels
% parameters.firstDerivativeThreshold  = 0.7;
parameters.firstDerivativeThreshold  = 0.3;
parameters.secondDerivativeThreshold = 1e-2;
parameters.edginessThreshold   = 0.1;
parameters.minMeanPathWeight   = 0.1; 
parameters.minSumPathWeigth    = 0.5;
        
% relative weights for choosing among csi segments that overlap.    
parameters.segmentSelectionSumWeigth  = 0.8; 
parameters.segmentSelectionMeanWeigth = 0.1;
parameters.segmentSelectionHeights    = 0.1;

% Edge Probability
parameters.scalesize = [10 15 20];
parameters.angles    = [-20 0 20];

% Graph search
parameters.alpha      = 2;
parameters.wM         = 20000;
parameters.delColmax  = 40;
parameters.delRowmax  = 25;
parameters.maxJumpCol = 10;
parameters.maxJumpRow = 5;
parameters.on1        = 1;
parameters.on2        = 1;
parameters.on3        = 0;
parameters.on4        = 1;

end