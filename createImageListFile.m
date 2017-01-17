function createImageListFile(folder,varargin)

% folder = '/Users/javimazzaf/Documents/work/proyectos/ophthalmology/SteJustine/data/';

% folder = [folder 'P2008209 20160912/'];
% folder = [folder 'P9852654 20120504/'];
% folder = [folder 'P9852654 20160518/'];

% folder = [folder 'P181-A 20160915/'];
% folder = [folder 'P181-B 20160915/'];

if nargin < 1
    
    xWidth = 6;
    yWidth = 6;
    zWidth = 2;
    
    xNpix = 512;
    yNpix = 128;
    zNpix = 1024;
    
    numAvg = 20;
    quality = 20;
    
else
    
    par = varargin{1};
    
    xWidth = par.xWidth;
    yWidth = par.yWidth;
    zWidth = par.zWidth;
    
    xNpix = par.xNpix;
    yNpix = par.yNpix;
    zNpix = par.zNpix;
    
    numAvg  = par.numAvg;
    quality = par.quality;
    
end

xStep = xWidth / xNpix;
yStep = yWidth / yNpix;
zStep = zWidth / zNpix;

col = zeros([yNpix,1]);
colc = cell([yNpix,1]);

ImageList = table(col,col,col,col,col,colc,col,col,col,col,col,col,col,col,col,col,col,col,col,col,colc,colc,...
    'VariableNames',{'id' 'fwidth' 'fheight' 'fscaleX' 'fscaleY' 'fundusfileName'...
    'hour ' 'minute' 'second' 'UTC' 'width' 'height' 'scaleX'...
    'scaleY' 'numAvg' 'quality' 'startX' 'startY' 'endX' 'endY'...
    'filePath' 'fileName'});

for k = 1:yNpix
    
    ImageList{k,'id'} = k;
    
    % Scale Information
    ImageList{k,'fwidth'}  = xNpix;
    ImageList{k,'fheight'} = xNpix;
    ImageList{k,'fscaleX'} = xStep;
    ImageList{k,'fscaleY'} = xStep;
    
    % File name Information
    ImageList{k,'fundusfileName'} = {'fundusImage.tif'};
    
    % Acquisition time information
    ImageList{k,'hour'}   = 0;
    ImageList{k,'minute'} = 0;
    ImageList{k,'second'} = 0;
    ImageList{k,'UTC'}    = 0;
    
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
    
    % File name information
    ImageList{k,'filePath'} = {''};
    ImageList{k,'fileName'} = {[num2str(k-1,'%5.5d'),'.png']};
    
end


% fundusIm = imread(fullfile(folder,char(ImageList{1,'fundusfileName'})));
fundusIm = uint8(zeros(512));
fundusIm = cat(3,fundusIm,fundusIm,fundusIm);

if ~exist(fullfile(folder,'DataFiles'),'dir')
    mkdir(fullfile(folder,'DataFiles'));
end

save(fullfile(folder,'DataFiles','ImageList.mat'),'ImageList','fundusIm');

end