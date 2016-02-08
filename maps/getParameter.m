function parValue = getParameter(parName)

parValue = [];

switch parName
    case 'AVERAGING_SIZE', parValue = 5; % In pixels
    case 'CHOROID_MIN_WIDTH', parValue = 15; % In pixels
    case 'CHOROID_MAX_WIDTH', parValue = 150; % In pixels
    case 'FIRST_DERIVATIVE_THRESHOLD', parValue = 0.7;
    case 'SECOND_DERIVATIVE_THRESHOLD', parValue = 1E-2;
    case 'EDGINESS_THRESHOLD',   parValue = 0.1;
    case 'MIN_MEAN_PATH_WEIGHT', parValue = 0.1; 
    case 'MIN_SUM_PATH_WEIGTH',  parValue = 0.5;
        
    % Relative weights for choosing among CSI segments that overlap.    
    case 'SEGMENT_SELECTION_SUMWEIGTH',  parValue = 0.8; 
    case 'SEGMENT_SELECTION_MEANWEIGTH', parValue = 0.1;
    case 'SEGMENT_SELECTION_HEIGHTS',    parValue = 0.1;
          
    otherwise,            error(['Parameter ' parName ' does not exist.'])
end

end