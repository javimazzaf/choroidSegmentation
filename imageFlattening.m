function flatImage = imageFlattening(origImage,colshifts,shiftsize)
% Shits origImage columns according to colshifts to make a particular
% membrane flat

[~,nCols] = size(origImage);

origImage = padarray(origImage,[shiftsize,0]);

flatImage = zeros(size(origImage)); 

% Shift col by col
for j=1:nCols
    flatImage(:,j) = circshift(origImage(:,j),colshifts(j)); 
end

flatImage = flatImage(shiftsize+1:end-shiftsize,:);

end

