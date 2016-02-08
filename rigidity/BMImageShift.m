function shiftedIm = BMImageShift(im,colshifts,shiftsize,PadOps)
% Shits "im" columns according to colshifts

[~,nCols]=size(im);

if strcmp(PadOps,'Pad')
    im=padarray(im,[shiftsize,0]);
end

shiftedIm = zeros(size(im)); %Prealloc

for j=1:nCols
    shiftedIm(:,j)=circshift(im(:,j),colshifts(j)); %Shift col by col
end

if strcmp(PadOps,'Unpad')
    shiftedIm = shiftedIm(shiftsize+1:end-shiftsize,:);
end

end

