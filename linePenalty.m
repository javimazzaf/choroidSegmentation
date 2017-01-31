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

function Affinity = linePenalty(indx,row,col,connected,texture)


Affinity=zeros(length(connected),1);
[a,b]=size(texture);

[X,Y]=arrayfun(@func_LinePoints,repmat(row(indx),length(connected),1),...
    repmat(col(indx),length(connected),1),...
    row(connected),col(connected),...
    repmat(b,length(connected),1),...
    'uniformoutput',0);


for i=1:length(connected)
    if isempty(X{i}) && col(indx)==0
        Affinity(i)=texture(row(indx),1);
    elseif isempty(X{i}) && col(indx)==b+1
        Affinity(i)=texture(row(indx),b);
    else
    Affinity(i)=mean(texture(sub2ind([a,b],X{i},Y{i})));
    end
end

end

