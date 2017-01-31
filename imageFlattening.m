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

function flatImage = imageFlattening(origImage,colshifts,shiftsize)
% Shits origImage columns according to colshifts to make a particular
% membrane flat

[~,nCols] = size(origImage);

origImage = padarray(origImage,[shiftsize,0]);

flatImage = zeros(size(origImage)); 

% Shift col by col
for j=1:nCols
    flatImage(:,j) = circshift(origImage(:,j),colshifts(j)); 
end

flatImage = flatImage(shiftsize+1:end-shiftsize,:);

end

