function [sf, N] = fitPlane(x,y,z,w)

ft = fittype('poly11');

fo = fitoptions('poly11');

w = max(0,w); % Eliminate points with negative weight 

% fo.Normal = 'on';
fo.Weights = w;

sf = fit([x, y],z,ft,fo);

N = [-sf.p10, -sf.p01, 1];
N = N / norm(N);

end