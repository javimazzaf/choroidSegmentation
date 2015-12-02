% function testing

figure(2)

po = 0.01;

noiseP = P(P < prctile(P,95));
% 
% beta = sqrt(var(noiseP));
% 

[h,x] = hist(noiseP(1:12:end),10);
fo = fit(x',h','exp1');
sigma0 = sqrt(- 1 / fo.b);

zo = -log(po) * sigma0^2



% 
% distr = exp(-x/beta) / beta;
% 
% normCte = h(1) / distr(1);
% 
% plot(x,h/normCte,'ok')
% hold on
% plot(x,distr,'-r')
% hold off

% end