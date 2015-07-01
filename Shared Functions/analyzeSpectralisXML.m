function [patientData, timeSeries]=analyzeSpectralisXML(fileName)

% This function reads the Spectralis XML files and extracts the most
% relevant parameters. It gives back to struct variables, patientData and
% TimeSeries
% patientData contains personal data and the scan width
% timeSeries has details of every single image acquiered
% 2 Body
% 4 Patient
% 12 Study
% 10 Series / 12 if the name of the study is included (dynamic laminometer)
% 18 Images


%% open and parse the file
%allXMLfields=parseXML('0DEBD110.xml')
%allXMLfields=parseXML('E72E5350.xml')

allXMLfields=parseXML(fileName);

%%
patientData.LastName=allXMLfields.Children(2).Children(4).Children(4).Children(1).Data;
patientData.FisrtName=allXMLfields.Children(2).Children(4).Children(6).Children(1).Data;
patientData.BirthDate=allXMLfields.Children(2).Children(4).Children(8).Children(1).Data;
patientData.Sex=allXMLfields.Children(2).Children(4).Children(10).Children(1).Data;
% patientData.Width=allXMLfields.Children(2).Children(4).Children(12).Children(10).Children(14).Children(2).Children.Data;
patientData.Width=allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(14).Children(2).Children.Data;

itOCT=1;
% Checks the number of fields inside "Study" in the XML file

% if size(allXMLfields.Children(2).Children(4).Children(12).Children, 2)<12;
if size(allXMLfields.Children(2).Children(4).Children(12).Children, 2)<14;
    
    % Images in this case have one LOCALIZER image at the beginning and the
    % rest are OCTs, and only one Series, but many images
    
    patientData.NumImages=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(18).Children.Data);
    for it=1:patientData.NumImages-1
        timeSeries(itOCT).id=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(2).Children.Data);
        timeSeries(itOCT).hour=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(8).Children(2).Children(2).Children.Data);
        timeSeries(itOCT).minute=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(8).Children(2).Children(4).Children.Data);
        timeSeries(itOCT).second=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(8).Children(2).Children(6).Children.Data);
        timeSeries(itOCT).UTC=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(8).Children(2).Children(8).Children.Data);
        timeSeries(itOCT).width=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(2).Children.Data);
        timeSeries(itOCT).height=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(4).Children.Data);
        timeSeries(itOCT).scaleX=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(6).Children.Data);
        timeSeries(itOCT).scaleY=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(8).Children.Data);
        timeSeries(itOCT).numAvg=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(12).Children.Data);
        timeSeries(itOCT).quality=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(14).Children.Data);
        timeSeries(itOCT).startX=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(20).Children(2).Children(2).Children.Data);
        timeSeries(itOCT).startY=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(20).Children(2).Children(4).Children.Data);
        timeSeries(itOCT).endX=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(22).Children(2).Children(2).Children.Data);
        timeSeries(itOCT).endY=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(12).Children(22).Children(2).Children(4).Children.Data);
        timeSeries(itOCT).filePath=allXMLfields.Children(2).Children(4).Children(12).Children(12).Children(20+2*it).Children(14).Children(4).Children.Data;
        timeSeries(itOCT).fileName=timeSeries(itOCT).filePath(strfind(timeSeries(itOCT).filePath, '.')-8:strfind(timeSeries(itOCT).filePath, '.')+3);

        itOCT=itOCT+1;
    end
    
    % if there are 2 children in "Series" 
else
    
    % in this case there are one LOCALIZER and one OCT per series, many
    % Series, two Images per Series
    
    for it=1:(size(allXMLfields.Children(2).Children(4).Children(12).Children, 2)-1)/2-5
        timeSeries(itOCT).id=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+2*it).Children(2).Children.Data);
        timeSeries(itOCT).hour=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+2*it).Children(20).Children(8).Children(2).Children(2).Children.Data);
        timeSeries(itOCT).minute=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+2*it).Children(20).Children(8).Children(2).Children(4).Children.Data);
        timeSeries(itOCT).second=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+2*it).Children(20).Children(8).Children(2).Children(6).Children.Data);
        timeSeries(itOCT).UTC=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+2*it).Children(20).Children(8).Children(2).Children(8).Children.Data);
        timeSeries(itOCT).width=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+2*it).Children(20).Children(12).Children(2).Children.Data);
        timeSeries(itOCT).height=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+2*it).Children(20).Children(12).Children(4).Children.Data);
        timeSeries(itOCT).scaleX=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+2*it).Children(20).Children(12).Children(6).Children.Data);
        timeSeries(itOCT).scaleY=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+2*it).Children(20).Children(12).Children(8).Children.Data);
        timeSeries(itOCT).numAvg=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+2*it).Children(20).Children(12).Children(12).Children.Data);
        timeSeries(itOCT).quality=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+2*it).Children(20).Children(12).Children(14).Children.Data);
        timeSeries(itOCT).startX=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+2*it).Children(20).Children(12).Children(20).Children(2).Children(2).Children.Data);
        timeSeries(itOCT).startY=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+2*it).Children(20).Children(12).Children(20).Children(2).Children(4).Children.Data);
        timeSeries(itOCT).endX=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+2*it).Children(20).Children(12).Children(22).Children(2).Children(2).Children.Data);
        timeSeries(itOCT).endY=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+2*it).Children(20).Children(12).Children(22).Children(2).Children(4).Children.Data);
        timeSeries(itOCT).filePath=allXMLfields.Children(2).Children(4).Children(12).Children(10+2*it).Children(20).Children(14).Children(4).Children.Data;
        timeSeries(itOCT).fileName=timeSeries(itOCT).filePath(strfind(timeSeries(itOCT).filePath, '.')-8:strfind(timeSeries(itOCT).filePath, '.')+3);
        fundusfileName=allXMLfields.Children(2).Children(4).Children(12).Children(10+it*2).Children(18).Children(14).Children(4).Children.Data;

        %timeSeries(itOCT).fundusfileName=fundusfileName(strfind(fundusfileName,'.')-8:strfind(fundusfileName,'.')+3);

        %<JM>
        stIx = strfind(fundusfileName,'\');
        if isempty(stIx), stIx = 1;
        else              stIx = stIx(end) + 1; end

        %disp(fundusfileName(stIx:end))

        timeSeries(itOCT).fundusfileName=fundusfileName(stIx:end);
        %</JM>

        timeSeries(itOCT).fwidth=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+it*2).Children(18).Children(12).Children(2).Children.Data);
        timeSeries(itOCT).fheight=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+it*2).Children(18).Children(12).Children(4).Children.Data);
        timeSeries(itOCT).fscaleX=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+it*2).Children(18).Children(12).Children(6).Children.Data);
        timeSeries(itOCT).fscaleY=str2num(allXMLfields.Children(2).Children(4).Children(12).Children(10+it*2).Children(18).Children(12).Children(8).Children.Data);
        
        itOCT=itOCT+1;
    end
end


