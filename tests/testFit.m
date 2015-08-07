function testFit

[x,y] = meshgrid(1:10:100,1:10:100);

x = x(:);
y = y(:);

msk1 = y > x;
msk2 = ~msk1;

z = zeros(size(x));
w = ones(size(x));

ax = 0.01;
ay = -0.02;
az = 2;

z = - ax * x / az - ay * y / az;

% z(msk1) = x(msk1) + y(msk1);
% z(msk2) = x(msk2) + 2 * y(msk2);
% 
% w(msk1) = 1;
% w(msk2) = 100;

[sf, N] = fitPlane(x,y,z,w);

plot(sf,[x,y],z)

N
 
end

