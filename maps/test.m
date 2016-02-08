% function test
[~,y] = meshgrid(1:256,1:256);

im = 1./(1+exp((-y+128) / 1));
x = [];
y = [];
for k = 1:5:100
    
    x = [x,k];
    
    edg = edgeness(im,k,90); 
    
    y = [y,max(edg(128,:))];

    disp(k)
end

plot(x,y)