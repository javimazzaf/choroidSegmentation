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

function [aC,bC,aIm,bIm,imind,edges,num] = ConnectivityMatrix(region,connectivity)

[m,n]  = size(region);
region = double(region);
old    = 1;

for j = 1:n
    col = find(region(:,j));
    region(col,j) = region(col,j) .* (1:length(col))' + old;
    old = length(col) + old;
end

imind = find(region); %Indices of all foreground pixels in region(mask) 
num   = length(imind) + 2;

if connectivity==4
    
    aimind=repmat(imind,1,3);
    aimind=reshape(aimind',size(aimind,1)*size(aimind,2),1);
    
    right=imind+m;
    up=imind-1;
    down=imind+1;
    imhood=[up right down];
    
    keep=[(rem(imind-1,m)~=0) imind+m<=(m*n) (rem(imind+1,m)~=1)]; 
    keep=reshape((ismember(imhood,imind)&keep)',size(imind,1)*3,1);
    imhood=reshape(imhood',size(imhood,1)*size(imhood,2),1);
    
elseif connectivity==8
    
    aimind = repmat(imind,1,5);
    aimind = reshape(aimind',numel(aimind),1);
    
    % Index of pixels in positions relative to pixels in imind
    right    = imind + m;
    diagup   = imind + m - 1;
    up       = imind - 1;
    diagdown = imind + m + 1;
    down     = imind + 1;
    
    imhood   = [up diagup right diagdown down]; % Pixels on the right side
    
    
    keep = [(rem(imind - 1,m)      ~= 0),...    % Not in first row
            (rem(imind + m - 1, m) ~= 0),...    % Right-up is not first row
            imind + m              <= (m*n),... % Not in last column 
            (rem(imind + m + 1, m) ~= 1),...    % Right-down pix is not in first row
            (rem(imind + 1, m)     ~=1)];       % Down pix is not first row
        
    keep   = ismember(imhood,imind) & keep; % Keep only real pixels and kept ones
    keep   = reshape(keep',numel(keep),1);  
    imhood = reshape(imhood',numel(imhood),1);
else
    error('Error In ConnectivityMatrix.mat, Connectivity Must be 4 or 8')
end

aimind = aimind(keep); %Idexes repeated 5 times [1 1 1 1 1 2 2 2 2 2 ...]'
bimind = imhood(keep); %Indexs of neighbour pixels [up1 diagup1 right1 ... up2 diagup2 right2 ...]

aIm    = aimind; %Idexes repeated 5 times [1 1 1 1 1 2 2 2 2 2 ...]'
bIm    = bimind; %Indexs of neighbour pixels [up1 diagup1 right1 ... up2 diagup2 right2 ...]

aC     = region(aimind); %region in aIm 
bC     = region(bimind); %region in bIm

startedge   = region(:,1) > 0; %logical(region(:,1));
startlength = sum(startedge);  %length(find(startedge));

endedge     = region(:,n) > 0; %logical(region(:,n));
endlength   = sum(endedge);    %length(find(endedge));

aC = [ones(startlength,1);aC;region(endedge,n)];
bC = [region(startedge,1);bC;repmat(num,endlength,1)];

edges = [startedge endedge];

end

