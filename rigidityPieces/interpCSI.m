function [x,y] = interpCSI(xi,yi, n)
    vals = fit(xi,yi,'linear');
   
    x = 1:n;
    
    vals = vals(x);
    
    y    = round(smooth(vals,50,'rloess'))'; %0.2
%     PathPts = sub2ind([m n],vals,1:length(vals));
end