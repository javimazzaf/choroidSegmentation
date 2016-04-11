function [quad, fh] = getQuadrantThickness(X,Y,thick,weights,eyeStr, maculaCenter)
% Measures the mean and SD of the thickness within the regions of the AREDS
% grid.

if strfind(eyeStr{:},'OS')
    eye = 'OS';
elseif strfind(eyeStr{:},'OD')
    eye = 'OD';
else
    error('Eye string is wrong')
end

if exist('maculaCenter','var')
    Xo = maculaCenter.x;
    Yo = maculaCenter.y;
else %Asumes the map is centered in the macula.
    Xo = (max(X) + min(X)) / 2;
    Yo = (max(Y) + min(Y)) / 2;
end

X = X - Xo;
Y = Y - Yo;

X = X * 1000;
Y = Y * 1000;

optRadius = min([max(X) - maculaCenter.x  ,...
                 maculaCenter.x - min(X)  ,...
                 max(Y) - maculaCenter.y  ,...
                 maculaCenter.y - min(Y)]);

R   = sqrt(X.^2 + Y.^2); 
ang = atan2(Y,X);

cs = cos(ang);
ss = sin(ang);

% Central circle
mskR = (R <= optRadius);

fh = figure('Visible','Off');
title(eye), axis square, hold on

for ar = {'nasalSuperior','nasalInferior','temporalSuperior','temporalInferior'}

    angStruct = struct('mean',[],'SD',[]);
    
    % Builds the mask for angle
    switch ar{:}
        case 'nasalSuperior'
            if strcmp(eye,'OD')
                mskQ = (cs > 0) & (ss > 0);
            else
                mskQ = (cs < 0) & (ss > 0);
            end
            
        case 'nasalInferior'
            if strcmp(eye,'OD')
                mskQ = (cs > 0) & (ss < 0);
            else
                mskQ = (cs < 0) & (ss < 0);
            end
            
        case 'temporalSuperior'
            if strcmp(eye,'OD')
                mskQ = (cs < 0) & (ss > 0);
            else
                mskQ = (cs > 0) & (ss > 0);
            end
          
        case 'temporalInferior'
            if strcmp(eye,'OD')
                mskQ = (cs < 0) & (ss < 0);
            else
                mskQ = (cs > 0) & (ss < 0);
            end    
    end
    
    msk = mskR & mskQ;
    
    plot(X(msk),Y(msk),'.'), xlim([-3000 3000]), ylim([-3000 3000])
    
    angStruct.N = sum(msk(:));
    [angStruct.mean, angStruct.SD] = maskMeanAndSd(thick,weights,msk);
    
    quad.(ar{:}) = angStruct;
    
end

end