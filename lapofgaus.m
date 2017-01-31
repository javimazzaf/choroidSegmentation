% Lapacian of Gaussian - Absolut value
function LOG = lapofgaus(im,scale)

  scale = scale / 4;

  gf = gaussFilter(scale);
  
  padSize = ceil(scale * 3);
  
  padIm =padarray(im,[padSize padSize],'both','replicate');
  
  sm = filter2(gf,padIm,'same');
  
  LOG = scale * del2(sm);
  
  LOG = abs(LOG(padSize+1:end-padSize,padSize+1:end-padSize));

end

function gf = gaussFilter(scale)

sz = fix(6 * scale/2) * 2 + 1;

[x,y] = meshgrid((1:sz)-ceil(sz/2));

gf = exp(- (x.^2 + y.^2) / 2 / scale^2);

end
