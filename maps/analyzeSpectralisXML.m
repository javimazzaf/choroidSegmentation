function [patientData, timeSeries]=analyzeSpectralisXML(fileName)

% This function reads the Spectralis XML files and extracts the most
% relevant parameters. It gives back to struct variables, patientData and
% TimeSeries
% patientData contains personal data and the scan width
% timeSeries has details of every single image acquiered

% JM (20150706): 
% I rewrote this file to look for node names, instead of hardcoded node
% number. The reason for doing this is that
% for some XML files the node numbers just below patientNode have slightly
% different order, messing up everything. For these cases, the study node
% was in the same index as the Sex node was before. 

% The code is still cryptic because the XML file is cryptic. At least now
% it will work regardless of the nodes order, and it will be easier to find 
% bugs, since the error will show which node is missing.

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

% Check different styles of XML files
if size(studyNode.Children, 2) < 14;
    
    % Images in this case have one LOCALIZER image at the beginning and the
    % rest are OCTs, and only one Series, but many images
    
    error('This case is not implemented after the changes in this file. Implement it when this error mesage comes out. (JM)')
    
%     patientData.NumImages=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(18).Children.Data);
%     for it=1:patientData.NumImages-1
%         timeSeries(itOCT).id=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(2).Children.Data);
%         timeSeries(itOCT).hour=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(8).Children(2).Children(2).Children.Data);
%         timeSeries(itOCT).minute=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(8).Children(2).Children(4).Children.Data);
%         timeSeries(itOCT).second=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(8).Children(2).Children(6).Children.Data);
%         timeSeries(itOCT).UTC=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(8).Children(2).Children(8).Children.Data);
%         timeSeries(itOCT).width=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(2).Children.Data);
%         timeSeries(itOCT).height=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(4).Children.Data);
%         timeSeries(itOCT).scaleX=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(6).Children.Data);
%         timeSeries(itOCT).scaleY=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(8).Children.Data);
%         timeSeries(itOCT).numAvg=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(12).Children.Data);
%         timeSeries(itOCT).quality=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(14).Children.Data);
%         timeSeries(itOCT).startX=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(20).Children(2).Children(2).Children.Data);
%         timeSeries(itOCT).startY=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(20).Children(2).Children(4).Children.Data);
%         timeSeries(itOCT).endX=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(22).Children(2).Children(2).Children.Data);
%         timeSeries(itOCT).endY=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(22).Children(2).Children(4).Children.Data);
%         timeSeries(itOCT).filePath=allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(14).Children(4).Children.Data;
%         timeSeries(itOCT).fileName=timeSeries(itOCT).filePath(strfind(timeSeries(itOCT).filePath, '.')-8:strfind(timeSeries(itOCT).filePath, '.')+3);
% 
%         itOCT=itOCT+1;
%     end
    
    
else % if there are 2 children in "Series" 
    
    % in this case there are one LOCALIZER and one OCT per series, many
    % Series, two Images per Series
    
    seriesNodes = studyNode.Children(strcmp({studyNode.Children(:).Name},'Series'));
    if isempty(seriesNodes)
       error('No series data in XML file.')
     end
    
    for it = 1:numel(seriesNodes)
        
        thisSeriesNodes = seriesNodes(it).Children;
        
        timeSeries(it).id     = str2num(thisSeriesNodes(strcmp({thisSeriesNodes(:).Name},'ID')).Children.Data);
        
        % fundus = 1, oct = 2;
        imageNodes = thisSeriesNodes(strcmp({thisSeriesNodes(:).Name},'Image'));
        
        % Parse Fundus image Information        
        funImageNodes = imageNodes(1).Children;
        
        % Scale Information
        foacNodes = funImageNodes(strcmp({funImageNodes(:).Name},'OphthalmicAcquisitionContext')).Children;
        timeSeries(it).fwidth  = str2num(foacNodes(strcmp({foacNodes(:).Name},'Width')).Children.Data);
        timeSeries(it).fheight = str2num(foacNodes(strcmp({foacNodes(:).Name},'Height')).Children.Data);
        timeSeries(it).fscaleX = str2num(foacNodes(strcmp({foacNodes(:).Name},'ScaleX')).Children.Data);
        timeSeries(it).fscaleY = str2num(foacNodes(strcmp({foacNodes(:).Name},'ScaleY')).Children.Data);
        
        % File name Information
        fImageDataNodes   = funImageNodes(strcmp({funImageNodes(:).Name},'ImageData')).Children;
        fundusfileName = fImageDataNodes(strcmp({fImageDataNodes(:).Name},'ExamURL')).Children.Data;
        timeSeries(it).fundusfileName = fundusfileName(find(fundusfileName == '\',1,'Last')+1:end);
        
        % Parse OCT image Information
        octImageNodes = imageNodes(2).Children;
        
        % Acquisition time information
        acqNodes  = octImageNodes(strcmp({octImageNodes(:).Name},'AcquisitionTime')).Children;
        timeNodes = acqNodes(strcmp({acqNodes(:).Name},'Time')).Children;
        timeSeries(it).hour   = str2num(timeNodes(strcmp({timeNodes(:).Name},'Hour')).Children.Data);
        timeSeries(it).minute = str2num(timeNodes(strcmp({timeNodes(:).Name},'Minute')).Children.Data);
        timeSeries(it).second = str2num(timeNodes(strcmp({timeNodes(:).Name},'Second')).Children.Data);
        timeSeries(it).UTC    = str2num(timeNodes(strcmp({timeNodes(:).Name},'UTCBias')).Children.Data);
        
        % Image scale information
        oacNodes = octImageNodes(strcmp({octImageNodes(:).Name},'OphthalmicAcquisitionContext')).Children;
        timeSeries(it).width  = str2num(oacNodes(strcmp({oacNodes(:).Name},'Width')).Children.Data);
        timeSeries(it).height = str2num(oacNodes(strcmp({oacNodes(:).Name},'Height')).Children.Data);
        timeSeries(it).scaleX = str2num(oacNodes(strcmp({oacNodes(:).Name},'ScaleX')).Children.Data);
        timeSeries(it).scaleY = str2num(oacNodes(strcmp({oacNodes(:).Name},'ScaleY')).Children.Data);        
        
        % Averaging and Image quality information            
        timeSeries(it).numAvg = str2num(oacNodes(strcmp({oacNodes(:).Name},'NumAve')).Children.Data);
        timeSeries(it).quality= str2num(oacNodes(strcmp({oacNodes(:).Name},'ImageQuality')).Children.Data);
        
        % Scan coordinates information
        startNodes = oacNodes(strcmp({oacNodes(:).Name},'Start')).Children;
        sCoorNodes = startNodes(strcmp({startNodes(:).Name},'Coord')).Children;
        timeSeries(it).startX = str2num(sCoorNodes(strcmp({sCoorNodes(:).Name},'X')).Children.Data);
        timeSeries(it).startY = str2num(sCoorNodes(strcmp({sCoorNodes(:).Name},'Y')).Children.Data);
        
        endNodes   = oacNodes(strcmp({oacNodes(:).Name},'End')).Children;
        eCoorNodes = endNodes(strcmp({endNodes(:).Name},'Coord')).Children;        
        timeSeries(it).endX   = str2num(eCoorNodes(strcmp({eCoorNodes(:).Name},'X')).Children.Data);
        timeSeries(it).endY   = str2num(eCoorNodes(strcmp({eCoorNodes(:).Name},'Y')).Children.Data);
        
        % File name information
        imageDataNodes   = octImageNodes(strcmp({octImageNodes(:).Name},'ImageData')).Children;
        octfileName = imageDataNodes(strcmp({imageDataNodes(:).Name},'ExamURL')).Children.Data;
        timeSeries(it).filePath = octfileName;
        timeSeries(it).fileName = octfileName(find(octfileName == '\',1,'Last')+1:end);

    end
end


