function edg = edgeness(inImage,scales,angs)

angFilt = zeros([size(inImage),numel(angs)]);

for a = 1:numel(angs)
    
    ang   = angs(a);
    
    aux = 0;
    
    for s = 1:numel(scales)
        
        scale = scales(s);
        
        gf = gaborFilter(scale,ang);
   
        grad = filter2(gf,inImage,'same');
        
        aux = aux + grad;
        
    end
    
    angFilt(:,:,a) = aux;
    
end

edg = max(angFilt,[],3);

% gf = gaborFilter(scales(1),ang(1));
% 
% edg = filter2(gf,inImage,'same');
% 
% %     bw = y > tan(angles(a)) * x;
% %
% %     gr = imfilter(im, heaviside(-11:11)' - 0.5);
end

% function gc = gaborContrast(inImage, width,ang)
%    gf = gaborFilter(width,ang);
%    
%    gDif = filter2(gf,inImage,'same');
%    gSum = filter2(abs(gf),inImage,'same');
%    
%    gc = gDif ./ gSum;
%    
%    gc(abs(gSum) < eps(gSum)) = NaN;
%    
% end

function gf = gaborFilter(width,ang)

sz = fix(6 * width/2) * 2 + 1;
[x,y] = meshgrid((1:sz)-ceil(sz/2));
xrot =   x * cosd(ang) + y * sind(ang);
yrot = - x * sind(ang) + y * cosd(ang);

gf = exp(- (xrot.^2 + yrot.^2) / 2 / width^2) .* sin(2 * pi * xrot / sz);

% gf = gf / sum(abs(gf(:))) / 2;

end