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

function edg = edgeness(inImage,scales,angs)

% Pad image to avoid edge effects
maxKernelSize = max(scales) * 6;
padSize = maxKernelSize / 2;
padIm =padarray(inImage,[padSize padSize],'both','replicate');

angFilt = zeros([size(padIm),numel(angs)]);

for a = 1:numel(angs)
    
    ang   = angs(a);
    
    aux = 0;
    
    for s = 1:numel(scales)
        
        scale = scales(s);
        
        gf = gaborFilter(scale,ang);
   
        grad = filter2(gf,padIm,'same');
        
        aux = aux + grad;
        
    end
    
    angFilt(:,:,a) = aux;
    
end

edg = max(angFilt,[],3);

% Undo padding
edg = edg(padSize+1:end-padSize,padSize+1:end-padSize);

end


function gf = gaborFilter(width,ang)

sz = fix(6 * width/2) * 2 + 1;
[x,y] = meshgrid((1:sz)-ceil(sz/2));
xrot =   x * cosd(ang) + y * sind(ang);
yrot = - x * sind(ang) + y * cosd(ang);

gf = exp(- (xrot.^2 + yrot.^2) / 2 / width^2) .* sin(2 * pi * xrot / sz);

end