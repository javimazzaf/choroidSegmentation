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

function prepareVolumeGeneric(dirlist)

% Hardcoded parameteres
% ********************************************************************
% *** SET HERE THE SIZE OF THE OCT VOLUME AND THE NUMBER OF PIXELS *** 
% *** IN EACH DIMENSION                                            *** 
% ********************************************************************

xWidth = 6;   % width of the Bscan in mm
yWidth = 6;   % width in direction perpendicular to Bscans in mm
zWidth = 2;   % height of Bscans in mm

xNpix = 496;  % Horizontal pixels of Bscans
% yNpix is determined inside the dirlist Loop, depending on the number of
% images in RawImages directory
zNpix = 512;  % Vertical pixels of Bscans

numAvg  = 20; % number of images averaged to obtain each Bscan
quality = 20; % Spectralis quality factor. Set it to 20 if you do not know. 

% *** END OF MANUAL PARAMETERES ***


xStep = xWidth / xNpix;
% yStep is determined inside the dirlist Loop
zStep = zWidth / zNpix;

for dr = 1:numel(dirlist)
    
    folder = dirlist{dr};
    
    % Number of Bscans is set to the number of tif images
    fnames = dir(fullfile(folder,'RawImages','*.tif'));
    fnames = sort({fnames(:).name});
    yNpix = numel(fnames);
    
    yStep = yWidth / yNpix;
    
    col = zeros([yNpix,1]);
    
    ImageList = table(col,col,col,col,col,col,col,col,col,col,col,col,col,col,...
        'VariableNames',{'fwidth' 'fheight' 'fscaleX' 'fscaleY' 'width'...
        'height' 'scaleX' 'scaleY' 'numAvg' 'quality' 'startX' 'startY'...
        'endX' 'endY'});
    
    fundusIm = uint8(zeros(512,512,3));
    
    for k = 1:yNpix
        
        % Scale Information
        ImageList{k,'fwidth'}  = xNpix;
        ImageList{k,'fheight'} = xNpix;
        ImageList{k,'fscaleX'} = xStep;
        ImageList{k,'fscaleY'} = xStep;
        
        % Bscan scale information
        ImageList{k,'width'}  = xNpix;
        ImageList{k,'height'} = zNpix;
        ImageList{k,'scaleX'} = xStep;
        ImageList{k,'scaleY'} = zStep;
        
        % Averaging and Image quality information
        ImageList{k,'numAvg'} = numAvg;
        ImageList{k,'quality'}= quality;
        
        % Scan coordinates information
        ImageList{k,'startX'} = 0;
        ImageList{k,'startY'} = yWidth - (k - 1) * yStep;
        
        ImageList{k,'endX'}   = xWidth;
        ImageList{k,'endY'}   = yWidth - (k - 1) * yStep;
        
    end
    
    if ~exist(fullfile(folder,'DataFiles'),'dir')
        mkdir(fullfile(folder,'DataFiles'));
    end
    
    % Create images target directory
    if ~exist(fullfile(folder,'ProcessedImages'),'dir')
        mkdir(fullfile(folder,'ProcessedImages'));
    end
    
    for q = 1:size(ImageList,1)
        
        imtif = imread(fullfile(folder,'RawImages',fnames{q}));
        
        imout = rgb2gray(imtif);
        
        imwrite(imout,fullfile(folder,'ProcessedImages',[num2str(q-1,'%5.5d'),'.png']))
        
    end
    
    save(fullfile(folder,'DataFiles','ImageList.mat'),'ImageList','fundusIm');
    
end

end