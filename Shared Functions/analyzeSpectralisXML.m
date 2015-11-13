function [patientData,timeSeries]=analyzeSpectralisXML(fileName)
% This function reads the Spectralis XML files and extracts the most
% relevant parameters. timeSeries includes both the oct and fundus
% parameters of each series. (it works with the previous xml format)
%
% 14/09/2015 M.Hidalgo

allXMLfields=parseXML(fileName);

b=struct2cell(allXMLfields.Children);
b=strmatch('BODY',cellstr(b(1,1,1:end)),'exact');
p=struct2cell(allXMLfields.Children(b).Children);
p=strmatch('Patient',cellstr(p(1,1,1:end)),'exact');
ln=struct2cell(allXMLfields.Children(b).Children(p).Children);
ln=strmatch('LastName',cellstr(ln(1,1,1:end)),'exact');

patientData.LastName=allXMLfields.Children(b).Children(p).Children(ln).Children(1).Data;
patientData.FirstName=allXMLfields.Children(b).Children(p).Children(ln+2).Children(1).Data;
patientData.Sex=allXMLfields.Children(b).Children(p).Children(ln+6).Children(1).Data;
study=allXMLfields.Children(b).Children(p).Children(ln+8).Children;
s=struct2cell(study); s=strmatch('Series',cellstr(s(1,1,1:end)),'exact');
acq=struct2cell(study(s(1)).Children); acq=cellstr(acq(1,1,1:end)); im=strmatch('Image',acq,'exact');
oct=struct2cell(study(s(1)).Children(im(2)).Children); oct=cellstr(oct(1,1,1:end));
oa=strmatch('OphthalmicAcquisitionContext',oct,'exact'); T=strmatch('AcquisitionTime',oct,'exact');

for i=1:numel(s)
    %fundus image parameters
    fundusfileName=study(s(i)).Children(im(1)).Children(strmatch('ImageData',oct,'exact')).Children(4).Children.Data;
    indx=strfind(fundusfileName,'\'); timeSeries(i).fundusfileName=fundusfileName(indx(end)+1:end);
    timeSeries(i).fwidth=str2num(study(s(i)).Children(im(1)).Children(oa).Children(2).Children.Data);
    timeSeries(i).fheight=str2num(study(s(i)).Children(im(1)).Children(oa).Children(4).Children.Data);
    timeSeries(i).fscaleX=str2num(study(s(i)).Children(im(1)).Children(oa).Children(6).Children.Data);
    timeSeries(i).fscaleY=str2num(study(s(i)).Children(im(1)).Children(oa).Children(8).Children.Data);
    %oct image parameters
    timeSeries(i).id=str2num(study(s(i)).Children(strmatch('ID',acq,'exact')).Children(1).Data);
    timeSeries(i).hour=str2num(study(s(i)).Children(im(2)).Children(T).Children(2).Children(2).Children.Data);
    timeSeries(i).minute=str2num(study(s(i)).Children(im(2)).Children(T).Children(2).Children(4).Children.Data);
    timeSeries(i).second=str2num(study(s(i)).Children(im(2)).Children(T).Children(2).Children(6).Children.Data);
    timeSeries(i).UTC=str2num(study(s(i)).Children(im(2)).Children(T).Children(2).Children(8).Children.Data);
    timeSeries(i).width=str2num(study(s(i)).Children(im(2)).Children(oa).Children(2).Children.Data);
    timeSeries(i).height=str2num(study(s(i)).Children(im(2)).Children(oa).Children(4).Children.Data);
    timeSeries(i).scaleX=str2num(study(s(i)).Children(im(2)).Children(oa).Children(6).Children.Data);
    timeSeries(i).scaleY=str2num(study(s(i)).Children(im(2)).Children(oa).Children(8).Children.Data);
    timeSeries(i).numAvg=str2num(study(s(i)).Children(im(2)).Children(oa).Children(12).Children.Data);
    timeSeries(i).quality=str2num(study(s(i)).Children(im(2)).Children(oa).Children(14).Children.Data);
    timeSeries(i).startX=str2num(study(s(i)).Children(im(2)).Children(oa).Children(20).Children(2).Children(2).Children.Data);
    timeSeries(i).startY=str2num(study(s(i)).Children(im(2)).Children(oa).Children(20).Children(2).Children(4).Children.Data);
    timeSeries(i).endX=str2num(study(s(i)).Children(im(2)).Children(oa).Children(22).Children(2).Children(2).Children.Data);
    timeSeries(i).endY=str2num(study(s(i)).Children(im(2)).Children(oa).Children(22).Children(2).Children(4).Children.Data);
    timeSeries(i).filePath=study(s(i)).Children(im(2)).Children(strmatch('ImageData',oct,'exact')).Children(4).Children.Data;
    indx2=strfind(timeSeries(i).filePath,'\'); timeSeries(i).fileName=timeSeries(i).filePath(indx2(end)+1:end);
    clear indx indx2
end

end