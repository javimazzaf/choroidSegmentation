function [quad, fh] = getQuadrantThickness(X,Y,thick,weights,eyeStr) %, maculaCenter)
% Measures the mean and SD of the thickness within the regions of the AREDS
% grid.

if strfind(eyeStr{:},'OS')
    eye = 'OS';
elseif strfind(eyeStr{:},'OD')
    eye = 'OD';
else
    error('Eye string is wrong')
end

R   = sqrt(X.^2 + Y.^2); 
ang = atan2(Y,X);

cs = cos(ang);
ss = sin(ang);


fh = figure('Visible','Off');
title(eye), axis square, hold on

for ar = {'nasalSuperior','nasalInferior','temporalSuperior','temporalInferior'}

    angStruct = struct('mean',[],'SD',[]);
    
    % Builds the mask for angle
    switch ar{:}
        case 'nasalSuperior'
            if strcmp(eye,'OD')
                msk = (cs > 0) & (ss < 0);
            else
                msk = (cs < 0) & (ss < 0);
            end
            
        case 'nasalInferior'
            if strcmp(eye,'OD')
                msk = (cs > 0) & (ss > 0);
            else
                msk = (cs < 0) & (ss > 0);
            end
            
        case 'temporalSuperior'
            if strcmp(eye,'OD')
                msk = (cs < 0) & (ss < 0);
            else
                msk = (cs > 0) & (ss < 0);
            end
          
        case 'temporalInferior'
            if strcmp(eye,'OD')
                msk = (cs < 0) & (ss > 0);
            else
                msk = (cs > 0) & (ss > 0);
            end    
    end
    
    plot(X(msk),Y(msk),'.'), xlim([-3000 3000]), ylim([-3000 3000])
    
    angStruct.N = sum(msk(:));
    [angStruct.mean, angStruct.SD] = maskMeanAndSd(thick,weights,msk);
    
    quad.(ar{:}) = angStruct;
    
end

end