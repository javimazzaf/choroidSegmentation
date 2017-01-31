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

function trimDetails(dirlist)

for k = 1:length(dirlist)
    
    folder = dirlist{k};
    
    try
        
        fname = fullfile(folder,'DataFiles','TrimInfo.txt');
        
        if exist(fname,'file'), continue, end
        
        pngList   = dir(fullfile(folder,'ProcessedImages','*.png'));
        numframes = numel(pngList);
        
        load(fullfile(folder,'DataFiles','ImageList.mat'), 'ImageList');
        
        qualityMask = ImageList.quality>=20 & ImageList.numAvg > 1;
        qualityMask(1:round(numframes/2)) = false;
        
        frame = find(qualityMask,1,'first');
        
        if isempty(frame), frame = numframes; end
        
        octImage = imread(fullfile(folder,'ProcessedImages',pngList(frame).name));
        
        [bscan,cropsize] = Crop2(octImage);
        
        happy = 'Redo';
        fh = figure;
        
        while strcmp(happy,'Redo')
            imshow(bscan)
            title('Please Select Left and Right Columns To Trim Off Entire Movie')
            
            if nargin >= 2 && strcmp(lower(varargin{2}),'notrim')
                trim = 'No';
            else
                trim = questdlg('Do you want to trim the image series?','Trim Dialog','Yes','No','Cancel','Yes');
            end
            
            if strcmp('Yes',trim)
                [col,~] = ginput(2);
                hold on
                plot(repmat(col(1),size(bscan,1),1),1:size(bscan,1),'g')
                plot(repmat(col(2),size(bscan,1),1),1:size(bscan,1),'g')
                hold off
                happy=questdlg('Accept or Redo?','Check','Accept','Redo','Accept');
            elseif strcmp('No',trim)
                happy='Accept';
                col=[1;size(bscan,2)];
            else
                delete(fname)
                return
            end
        end
        
        close(fh)
        
        % Sort, check limits, and save to file
        dlmwrite(fname,min(max(1,sort(col)),size(bscan,2))','precision','%g','delimiter',',')
        
        
    catch exception
        
        errorString = ['Error in TrimDetails. Message:' exception.message buildCallStack(exception)];
        disp(logit(folder,errorString));
        continue
        
    end
    
    disp(logit(folder,'Done TrimDetails'))
    
end
end