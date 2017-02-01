% Display String inline

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

% Example:
% nIter = 15;
% dispInline('init','Starting Loop')
% for k = 0:nIter
%     pause(1)
%     showString = ['Executing Iteration ' num2str(k) ' of ' num2str(nIter) '.'];
%     
%     if mod(k,5) == 0
%         dispInline('update',showString,'permanent')
%     else
%         dispInline('update',showString)
%     end
% end
% dispInline('end','Loop done.')

function dispInline(varargin)

persistent clearString

if nargin < 1
    error('dispInline: not enough parameters.')
end

command = varargin{1};

try
    showString  = ['>> ' varargin{2}];
    
    switch(command)
        case 'init'
            formatString = '%s\n';
            clearString = '';
        case 'update'
            formatString = [clearString '%s'];
            clearString = repmat('\b',1,numel(showString));
        case 'end'
            formatString = [clearString '%s\n'];
            clear clearString
        otherwise
            clear clearString
            error('dispInline: wrong command.')
    end
    
    if nargin >= 3 && strcmp(varargin{3},'permanent')
       fprintf(1,[formatString '\n'], showString); 
       clearString = '';
    else
       fprintf(1,formatString, showString);
    end
    
    
catch exception
    clear clearString
    throw(exception)
end

end