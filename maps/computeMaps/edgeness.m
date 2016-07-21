function edg = edgeness(inImage,scales,angs)

% Pad image to avoid edge effects
maxKernelSize = max(scales) * 6;
padSize = maxKernelSize / 2;
padIm =padarray(inImage,[padSize padSize],'both','replicate');

angFilt = zeros([size(padIm),numel(angs)]);

for a = 1:numel(angs)
    
    ang   = angs(a);
    
    aux = 0;
    
    for s = 1:numel(scales)
        
        scale = scales(s);
        
        gf = gaborFilter(scale,ang);
   
        grad = filter2(gf,padIm,'same');
        
        aux = aux + grad;
        
    end
    
    angFilt(:,:,a) = aux;
    
end

edg = max(angFilt,[],3);

% Undo padding
edg = edg(padSize+1:end-padSize,padSize+1:end-padSize);

end


function gf = gaborFilter(width,ang)

sz = fix(6 * width/2) * 2 + 1;
[x,y] = meshgrid((1:sz)-ceil(sz/2));
xrot =   x * cosd(ang) + y * sind(ang);
yrot = - x * sind(ang) + y * cosd(ang);

gf = exp(- (xrot.^2 + yrot.^2) / 2 / width^2) .* sin(2 * pi * xrot / sz);

end