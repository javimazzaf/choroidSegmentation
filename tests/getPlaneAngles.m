function [azimuth, polar] = getPlaneAngles(x,y,z,w)

[~, N] = fitPlane(x,y,z,w);

[azimuth,polar,~] = cart2sph(N(1),N(2),N(3)); 

azimuth = azimuth * 180 / pi; 

polar = polar * 180 / pi;

end