function parValue = getParameter(parName)

parValue = [];

switch parName
    case 'AVERAGING_SIZE', parValue = 5; % In pixels
    case 'CHOROID_MIN_WIDTH', parValue = 5; % In pixels
    case 'CHOROID_MAX_WIDTH', parValue = 150; % In pixels
        
    otherwise,            error(['Parameter ' parName ' does not exist.'])
end

end