% Copyright (C) 2017, Javier Mazzaferri, Luke Beaton, Santiago Costantino 
% Hopital Maisonneuve-Rosemont, 
% Centre de Recherche
% www.biophotonics.ca
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

function mapPseudoRegistration(dirlist)

for k = 1:length(dirlist)
    
    folder = dirlist{k};
    
    disp(logit(folder,'Starting mapPseudoRegistration'))
    
    try
        
        pngList = dir(fullfile(folder,'ProcessedImages','*.png'));
        
        numframes  = numel(pngList);
        bscanstore = cell(numframes,1);
        
        cropLimits = dlmread(fullfile(folder, 'DataFiles', 'TrimInfo.txt'),',');
        
        for frame = 1:numframes
            bscan = imread(fullfile(folder, 'ProcessedImages', pngList(frame).name));
            bscanstore{frame} = bscan(:,cropLimits(1):cropLimits(2));
        end
        
        skippedind = [];
        start      = 1;
        save(fullfile(folder,'DataFiles','RegisteredImages.mat'),'bscanstore','skippedind','start');
        
    catch exception
        
        errorString = ['Error in mapPseudoRegistration. In' folder ' Message:' exception.message buildCallStack(exception)];
        disp(logit(folder,errorString));
        continue
        
    end
    
    disp(logit(folder,'Done mapPseudoRegistration'))
    
end



