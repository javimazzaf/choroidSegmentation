function [missdata,missraw,missprocessim,missregims,missresults] = CheckDirContents(dirlist)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

datacheck=fullfile(dirlist,'Data Files','VisitData.mat');
rawimscheck=fullfile(dirlist,'Raw Images');
processedimscheck=fullfile(dirlist,'Processed Images');
regimscheck=fullfile(dirlist,'Data Files','RegisteredImages.mat');
resultscheck=fullfile(dirlist,'Results','Results.mat');

missdata=~logical(cellfun(@exist,datacheck,repmat({'file'},size(datacheck))));
missraw=~logical(cellfun(@exist,rawimscheck,repmat({'file'},size(rawimscheck))));
missprocessim=~logical(cellfun(@exist,processedimscheck,repmat({'file'},size(processedimscheck))));
missregims=~logical(cellfun(@exist,regimscheck,repmat({'file'},size(regimscheck))));
missresults=~logical(cellfun(@exist,resultscheck,repmat({'file'},size(resultscheck))));



end

