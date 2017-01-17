% Simple function to write to a LOG file.
% The file is created for each day, if it does not exist. Otherwise, info
% is appended to the file. The inputs are the path and the text to append in a new
% line.

% Copyright (C) 2016 Javier Mazzaferri <javier.mazzaferri@gmail.com>
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

function outText = logit(dname,inText)

try
    
    fname = fullfile(dname,['log' datestr(now,'yyyymmdd') '.txt']);
    
    fid = fopen(fname,'a');
    
    if fid == -1, return, end
    
    outText = sprintf('%s: \t %s \n',datestr(now,'HH:MM:SS.FFF'),inText);
    
    fprintf(fid,'%s',outText);
    
catch
    
    outText = '';
    fclose(fid);
    
end

fclose(fid);

end
