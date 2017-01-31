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
if isempty(studyNode)
    error('No study data in XML file.')
end

% Check XML files
if size(studyNode.Children, 2) < 14;
    error('This case is not implemented after the changes in this file. Implement it when this error mesage comes out. (JM)')
end

seriesNodes = studyNode.Children(strcmp({studyNode.Children(:).Name},'Series'));

if isempty(seriesNodes)
    error('No series data in XML file.')
end

col = zeros([numel(seriesNodes),1]);
colc = cell([numel(seriesNodes),1]);

timeSeries = table(col,col,col,col,col,colc,col,col,col,col,col,col,col,col,col,col,col,col,col,col,colc,colc,...
      'VariableNames',{'id' 'fwidth' 'fheight' 'fscaleX' 'fscaleY' 'fundusfileName'...
                       'hour ' 'minute' 'second' 'UTC' 'width' 'height' 'scaleX'...
                       'scaleY' 'numAvg' 'quality' 'startX' 'startY' 'endX' 'endY'...
                       'filePath' 'fileName'});

for k = 1:numel(seriesNodes)
    
    thisSeriesNodes = seriesNodes(k).Children;
    
    timeSeries{k,'id'} = str2num(thisSeriesNodes(strcmp({thisSeriesNodes(:).Name},'ID')).Children.Data);
    
    % fundus = 1, oct = 2;
    imageNodes = thisSeriesNodes(strcmp({thisSeriesNodes(:).Name},'Image'));
    
    % Parse Fundus image Information
    funImageNodes = imageNodes(1).Children;
    
    % Scale Information
    foacNodes = funImageNodes(strcmp({funImageNodes(:).Name},'OphthalmicAcquisitionContext')).Children;
    timeSeries{k,'fwidth'}  = str2num(foacNodes(strcmp({foacNodes(:).Name},'Width')).Children.Data);
    timeSeries{k,'fheight'} = str2num(foacNodes(strcmp({foacNodes(:).Name},'Height')).Children.Data);
    timeSeries{k,'fscaleX'} = str2num(foacNodes(strcmp({foacNodes(:).Name},'ScaleX')).Children.Data);
    timeSeries{k,'fscaleY'} = str2num(foacNodes(strcmp({foacNodes(:).Name},'ScaleY')).Children.Data);
    
    % File name Information
    fImageDataNodes   = funImageNodes(strcmp({funImageNodes(:).Name},'ImageData')).Children;
    fundusfileName    = fImageDataNodes(strcmp({fImageDataNodes(:).Name},'ExamURL')).Children.Data;
    timeSeries{k,'fundusfileName'} = {fundusfileName(find(fundusfileName == '\',1,'Last')+1:end)};
    
    % Parse OCT image Information
    octImageNodes = imageNodes(2).Children;
    
    % Acquisition time information
    acqNodes  = octImageNodes(strcmp({octImageNodes(:).Name},'AcquisitionTime')).Children;
    timeNodes = acqNodes(strcmp({acqNodes(:).Name},'Time')).Children;
    timeSeries{k,'hour'}   = str2num(timeNodes(strcmp({timeNodes(:).Name},'Hour')).Children.Data);
    timeSeries{k,'minute'} = str2num(timeNodes(strcmp({timeNodes(:).Name},'Minute')).Children.Data);
    timeSeries{k,'second'} = str2num(timeNodes(strcmp({timeNodes(:).Name},'Second')).Children.Data);
    timeSeries{k,'UTC'}    = str2num(timeNodes(strcmp({timeNodes(:).Name},'UTCBias')).Children.Data);
    
    % Image scale information
    oacNodes = octImageNodes(strcmp({octImageNodes(:).Name},'OphthalmicAcquisitionContext')).Children;
    timeSeries{k,'width'}  = str2num(oacNodes(strcmp({oacNodes(:).Name},'Width')).Children.Data);
    timeSeries{k,'height'} = str2num(oacNodes(strcmp({oacNodes(:).Name},'Height')).Children.Data);
    timeSeries{k,'scaleX'} = str2num(oacNodes(strcmp({oacNodes(:).Name},'ScaleX')).Children.Data);
    timeSeries{k,'scaleY'} = str2num(oacNodes(strcmp({oacNodes(:).Name},'ScaleY')).Children.Data);
    
    % Averaging and Image quality information
    timeSeries{k,'numAvg'} = str2num(oacNodes(strcmp({oacNodes(:).Name},'NumAve')).Children.Data);
    timeSeries{k,'quality'}= str2num(oacNodes(strcmp({oacNodes(:).Name},'ImageQuality')).Children.Data);
    
    % Scan coordinates information
    startNodes = oacNodes(strcmp({oacNodes(:).Name},'Start')).Children;
    sCoorNodes = startNodes(strcmp({startNodes(:).Name},'Coord')).Children;
    timeSeries{k,'startX'} = str2num(sCoorNodes(strcmp({sCoorNodes(:).Name},'X')).Children.Data);
    timeSeries{k,'startY'} = str2num(sCoorNodes(strcmp({sCoorNodes(:).Name},'Y')).Children.Data);
    
    endNodes   = oacNodes(strcmp({oacNodes(:).Name},'End')).Children;
    eCoorNodes = endNodes(strcmp({endNodes(:).Name},'Coord')).Children;
    timeSeries{k,'endX'}   = str2num(eCoorNodes(strcmp({eCoorNodes(:).Name},'X')).Children.Data);
    timeSeries{k,'endY'}   = str2num(eCoorNodes(strcmp({eCoorNodes(:).Name},'Y')).Children.Data);
    
    % File name information
    imageDataNodes   = octImageNodes(strcmp({octImageNodes(:).Name},'ImageData')).Children;
    octfileName = imageDataNodes(strcmp({imageDataNodes(:).Name},'ExamURL')).Children.Data;
    timeSeries{k,'filePath'} = {octfileName};
    timeSeries{k,'fileName'} = {octfileName(find(octfileName == '\',1,'Last')+1:end)};
     
end

    



