function [aredsT, fh] = getAREDSthickness(X,Y,thick,weights,eyeStr)
% Measures the mean and SD of the thickness within the regions of the AREDS
% grid.

if strfind(eyeStr{:},'OS')
    eye = 'OS';
elseif strfind(eyeStr{:},'OD')
    eye = 'OD';
else
    error('Eye string is wrong')
end

%Asumes the map is centered in the macula. 
Xo = (max(X) + min(X)) / 2;
Yo = (max(Y) + min(Y)) / 2;

X = X - Xo;
Y = Y - Yo;

R   = sqrt(X.^2 + Y.^2); 
ang = atan2(Y,X);

cs = cos(ang);
ss = sin(ang);

% Central circle
msk = (R <= 500);

aredsT.D1.N = sum(msk(:));
[aredsT.D1.mean, aredsT.D1.SD] = maskMeanAndSd(thick,weights,msk);

fh = figure('Visible','Off');
plot(X(msk),Y(msk),'.'), xlim([-3000 3000]), ylim([-3000 3000]), hold on
title(eye), axis square

for dd = [3,6] %Radial region
    
    % Builds the mask for the radius
    switch dd
        case 3, mskR = (R > 500)  & (R <= 1500);
        case 6, mskR = (R > 1500) & (R <= 3000);
    end
    
    radStruct = struct(); %Create structure to store info for current Radius
    
    for ar = {'nasal','inferior','temporal','superior'}
        
        angStruct = struct('mean',[],'SD',[]);
        
        % Builds the mask for angle
        switch ar{:}
            case 'nasal'
                if strcmp(eye,'OD')
                    mskA = (cs > 0) & (abs(ss) <= sin(pi/4));
                else
                    mskA = (cs < 0) & (abs(ss) <= sin(pi/4));
                end
            
             case 'temporal'
                if strcmp(eye,'OD')
                    mskA = (cs < 0) & (abs(ss) <= sin(pi/4));
                else
                    mskA = (cs > 0) & (abs(ss) <= sin(pi/4));
                end  
            case 'superior'
                mskA = (ss < 0) & (abs(cs) <= cos(pi/4));   
            case 'inferior'
                mskA = (ss > 0) & (abs(cs) <= cos(pi/4)); 
        end
        
        msk = mskR & mskA; 
        
        plot(X(msk),Y(msk),'.'), xlim([-3000 3000]), ylim([-3000 3000])
        
        angStruct.N = sum(msk(:));
        [angStruct.mean, angStruct.SD] = maskMeanAndSd(thick,weights,msk);
        
         radStruct.(ar{:}) = angStruct;
         
    end
    
    aredsT.(['D' num2str(dd)]) = radStruct;
    
    
    
end


end

function [mn, sd] = maskMeanAndSd(value,weight,msk)
%Computes weighted mean and standard deviation of "value" within msk

  mn  = sum(value(msk) .* weight(msk)) / sum(weight(msk));
  sd  = sqrt(sum(value(msk).^2 .* weight(msk)) / sum(weight(msk)) - mn^2);
end