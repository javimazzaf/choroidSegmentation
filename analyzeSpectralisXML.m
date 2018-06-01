function [patientData, timeSeries]=analyzeSpectralisXML(fileName)

% This function reads the Spectralis XML files and extracts the most
% relevant parameters. It gives back the struct patientData and
% thetable TimeSeries.
% patientData contains patient information
% timeSeries has details of every single image acquiered

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

% JM (20150706):
% I rewrote this file to look for node names, instead of hardcoded node
% number. The reason for doing this is that
% for some XML files the node numbers just below patientNode have slightly
% different order, messing up everything. For these cases, the study node
% was in the same index as the Sex node was before.

% The code is still cryptic because the XML file is cryptic. At least now
% it will work regardless of the nodes order, and it will be easier to find
% bugs, since the error will show which node is missing.

% JM (20160531):
% I simplified the function, and changed timeSeries to be table instead of
% a struct array.

% JM (20180601):
% I modified the file so it is compatible with version 6.6.2.0 of the
% Spectralis software

patientData = [];
timeSeries  = [];

allXMLfields = parseXML(fileName);
if isempty(allXMLfields), return, end

bodyNode = allXMLfields.Children(strcmp({allXMLfields.Children(:).Name},'BODY'));
if isempty(bodyNode), return, end

patientNode = bodyNode.Children(strcmp({bodyNode.Children(:).Name},'Patient'));

if isempty(patientNode)
    error('No patient data in XML file.')
end

patientData.LastName  = patientNode.Children(strcmp({patientNode.Children(:).Name},'LastName'  )).Children(1).Data;
patientData.FisrtName = patientNode.Children(strcmp({patientNode.Children(:).Name},'FirstNames')).Children(1).Data;
patientData.BirthDate = patientNode.Children(strcmp({patientNode.Children(:).Name},'Birthdate' )).Children(1).Data;
patientData.Sex       = patientNode.Children(strcmp({patientNode.Children(:).Name},'Sex'       )).Children(1).Data;

studyNode = patientNode.Children(strcmp({patientNode.Children(:).Name},'Study'));
if isempty(studyNode), error('No study data in XML file.'), end

seriesNodes = studyNode.Children(strcmp({studyNode.Children(:).Name},'Series'));
if isempty(seriesNodes), error('No series data in XML file.'), end

imagesNodes = seriesNodes.Children(strcmp({seriesNodes.Children(:).Name},'Image'));
if isempty(imagesNodes), error('No Image data in XML file.'), end


fundusInfo = getFundusInformation(imagesNodes);
if isempty(fundusInfo), error('No fundus information found in XML file.'), end

imagesNodes = getOCTnodes(imagesNodes);

col  = zeros([numel(imagesNodes),1]);
colc = cell([numel(imagesNodes),1]);

timeSeries = table(col,col,col,col,col,colc,col,col,col,col,col,col,col,col,col,col,col,col,col,col,colc,colc,...
      'VariableNames',{'id' 'fwidth' 'fheight' 'fscaleX' 'fscaleY' 'fundusfileName'...
                       'hour ' 'minute' 'second' 'UTC' 'width' 'height' 'scaleX'...
                       'scaleY' 'numAvg' 'quality' 'startX' 'startY' 'endX' 'endY'...
                       'filePath' 'fileName'});
            
% Loops through OCT image nodes                   
for k = 1:numel(imagesNodes)
    
    thisImageNodes = imagesNodes(k).Children;
    
    %Fill fundus info (It is the same for all Bscans)
    timeSeries{k,'fwidth'}  = str2double(fundusInfo.width);
    timeSeries{k,'fheight'} = str2double(fundusInfo.height);
    timeSeries{k,'fscaleX'} = str2double(fundusInfo.scaleX);
    timeSeries{k,'fscaleY'} = str2double(fundusInfo.scaleY);
    timeSeries{k,'fundusfileName'} = {fundusInfo.fileName};
    
    timeSeries{k,'id'} = str2double(thisImageNodes(strcmp({thisImageNodes(:).Name},'ID')).Children.Data);
    
    % Acquisition time information
    acqNodes  = thisImageNodes(strcmp({thisImageNodes(:).Name},'AcquisitionTime')).Children;
    timeNodes = acqNodes(strcmp({acqNodes(:).Name},'Time')).Children;
    timeSeries{k,'hour'}   = str2double(timeNodes(strcmp({timeNodes(:).Name},'Hour')).Children.Data);
    timeSeries{k,'minute'} = str2double(timeNodes(strcmp({timeNodes(:).Name},'Minute')).Children.Data);
    timeSeries{k,'second'} = str2double(timeNodes(strcmp({timeNodes(:).Name},'Second')).Children.Data);
    timeSeries{k,'UTC'}    = str2double(timeNodes(strcmp({timeNodes(:).Name},'UTCBias')).Children.Data);
    
    % Image scale information
    oacNodes = thisImageNodes(strcmp({thisImageNodes(:).Name},'OphthalmicAcquisitionContext')).Children;
    timeSeries{k,'width'}  = str2double(oacNodes(strcmp({oacNodes(:).Name},'Width')).Children.Data);
    timeSeries{k,'height'} = str2double(oacNodes(strcmp({oacNodes(:).Name},'Height')).Children.Data);
    timeSeries{k,'scaleX'} = str2double(oacNodes(strcmp({oacNodes(:).Name},'ScaleX')).Children.Data);
    timeSeries{k,'scaleY'} = str2double(oacNodes(strcmp({oacNodes(:).Name},'ScaleY')).Children.Data);
    
    % Averaging and Image quality information
    timeSeries{k,'numAvg'} = str2double(oacNodes(strcmp({oacNodes(:).Name},'NumAve')).Children.Data);
    timeSeries{k,'quality'}= str2double(oacNodes(strcmp({oacNodes(:).Name},'ImageQuality')).Children.Data);
    
    % Scan coordinates information
    startNodes = oacNodes(strcmp({oacNodes(:).Name},'Start')).Children;
    sCoorNodes = startNodes(strcmp({startNodes(:).Name},'Coord')).Children;
    timeSeries{k,'startX'} = str2double(sCoorNodes(strcmp({sCoorNodes(:).Name},'X')).Children.Data);
    timeSeries{k,'startY'} = str2double(sCoorNodes(strcmp({sCoorNodes(:).Name},'Y')).Children.Data);
    
    endNodes   = oacNodes(strcmp({oacNodes(:).Name},'End')).Children;
    eCoorNodes = endNodes(strcmp({endNodes(:).Name},'Coord')).Children;
    timeSeries{k,'endX'}   = str2double(eCoorNodes(strcmp({eCoorNodes(:).Name},'X')).Children.Data);
    timeSeries{k,'endY'}   = str2double(eCoorNodes(strcmp({eCoorNodes(:).Name},'Y')).Children.Data);
    
    % File name information
    imageDataNodes   = thisImageNodes(strcmp({thisImageNodes(:).Name},'ImageData')).Children;
    octfileName = imageDataNodes(strcmp({imageDataNodes(:).Name},'ExamURL')).Children.Data;
    timeSeries{k,'filePath'} = {octfileName};
    timeSeries{k,'fileName'} = {octfileName(find(octfileName == '\',1,'Last')+1:end)};
    
end

end


% *** This function looks for fundus information in the imagesNodes and ***
% returns a structure with the information
function fundusInfo = getFundusInformation(imagesNodes)

fundusInfo = [];

for k = 1:numel(imagesNodes)
    
    thisImageNodes = imagesNodes(k).Children;
    
    % Get Image type: LOCALIZER (fundus)
    imageTypeNode = thisImageNodes(strcmp({thisImageNodes(:).Name},'ImageType')).Children;
    imageType     = imageTypeNode(strcmp({imageTypeNode(:).Name},'Type')).Children.Data;
    
    if strcmp(imageType,'LOCALIZER')
        
        % Scale Information
        foacNodes = thisImageNodes(strcmp({thisImageNodes(:).Name},'OphthalmicAcquisitionContext')).Children;
        fundusInfo.width  = foacNodes(strcmp({foacNodes(:).Name},'Width')).Children.Data;
        fundusInfo.height = foacNodes(strcmp({foacNodes(:).Name},'Height')).Children.Data;
        fundusInfo.scaleX = foacNodes(strcmp({foacNodes(:).Name},'ScaleX')).Children.Data;
        fundusInfo.scaleY = foacNodes(strcmp({foacNodes(:).Name},'ScaleY')).Children.Data;
        
        % File name Information
        fImageDataNodes   = thisImageNodes(strcmp({thisImageNodes(:).Name},'ImageData')).Children;
        fundusfileName    = fImageDataNodes(strcmp({fImageDataNodes(:).Name},'ExamURL')).Children.Data;
        fundusInfo.fileName    = fundusfileName(find(fundusfileName == '\',1,'Last')+1:end);
        
        break
    end
end

end

% *** This function KEEPS the nodes that are OCT images ***
function outNodes = getOCTnodes(inNodes)

   msk = arrayfun(@isOCT,inNodes);
   outNodes = inNodes(msk);

end

% *** This function checks if thisNode is an OCT image ***
function res = isOCT(thisNode)

    innerNodes = thisNode.Children;

    imageTypeNode = innerNodes(strcmp({innerNodes(:).Name},'ImageType')).Children;
    imageType     = imageTypeNode(strcmp({imageTypeNode(:).Name},'Type')).Children.Data;

    res = strcmp(imageType,'OCT');
    
end






