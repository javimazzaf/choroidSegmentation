function [G] = OrientedGaussian(sigma,theta)

% Filter Size
filterLength = 8*ceil(sigma) + 1;
n            = (max(filterLength) - 1) / 2;
[x,y]        = meshgrid(-n:n);

%Orthogonal Directions
a = cosd( -theta );
b = sind( -theta );

c = -b;
d = a;

G = 1/(2*pi*sigma(1)*sigma(2))*exp(-(a*x+b*y).^2./(2*sigma(1)^2)-(c*x+d*y).^2./(2*sigma(2)^2));
G(G<eps*max(G(:))) = 0;

end
