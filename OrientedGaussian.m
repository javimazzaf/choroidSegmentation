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

function [G] = OrientedGaussian(sigma,theta)

% Filter Size
filterLength = 8*ceil(sigma) + 1;
n            = (max(filterLength) - 1) / 2;
[x,y]        = meshgrid(-n:n);

%Orthogonal Directions
a = cosd( -theta );
b = sind( -theta );

c = -b;
d = a;

G = 1/(2*pi*sigma(1)*sigma(2))*exp(-(a*x+b*y).^2./(2*sigma(1)^2)-(c*x+d*y).^2./(2*sigma(2)^2));

G(G<eps*max(G(:))) = 0;

end
