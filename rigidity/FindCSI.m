function [yCSI] = FindCSI(varargin)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
if nargin==4
    Set1=varargin{1};
    Set2=varargin{2};
    shiftsize=varargin{3};
    colshifts=varargin{4};
    option=1;
elseif nargin>=5
    Set1=varargin{1};
    Set2=varargin{2};
    shiftsize=varargin{3};
    colshifts=varargin{4};
    option=2;
    meanCSI=varargin{5};
else
    error('Incorrect Number of inputs to function FindCSI.  Check requirements')
end

    
[k,l]=size(Set1);
%% Graph Search
if option==1
    PathPts=GraphSearchFirstPass(Set1,Set2,2,20000,40,25,10,5,1,1,0,1);
else
    PathPts=GraphSearchSecondPass(Set1,Set2,meanCSI,2,20000,40,25,10,5,1,1,0,1);
end

%% Inverse Shift
if ~isnan(PathPts)
    [y,~]=ind2sub([k l],PathPts);
    yCSI=y'-colshifts-shiftsize;
else
    yCSI=nan;
end
% imshow(imoverlay(Set2,Set1))
% hold all
% plot(y)
end

