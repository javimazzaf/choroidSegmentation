function [NTSI, fh] = getNTSIThickness(X,Y,thick,weights,eyeStr) %, maculaCenter)
% Measures the mean and SD of the thickness within Nasal, temporal,
% superior and inferior halfs.

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

for ar = {'nasal','temporal','superior','inferior'}

    angStruct = struct('mean',[],'SD',[]);
    
    % Builds the mask for angle
    switch ar{:}
        case 'nasal'
            if strcmp(eye,'OD')
                msk = cs > 0;
            else
                msk = cs < 0;
            end
            
        case 'temporal'
            if strcmp(eye,'OD')
                msk = cs < 0;
            else
                msk = cs > 0;
            end
            
        case 'superior'
            
            msk = ss < 0;
            
        case 'inferior'
            
            msk = ss > 0;   
    end
    
    plot(X(msk),Y(msk),'.'), xlim([-3000 3000]), ylim([-3000 3000])
    
    angStruct.N = sum(msk(:));
    [angStruct.mean, angStruct.SD] = maskMeanAndSd(thick,weights,msk);
    
    NTSI.(ar{:}) = angStruct;
    
end

end