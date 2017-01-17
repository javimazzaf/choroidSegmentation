function [X,Y] = func_LinePoints(X0, Y0, X1, Y1,cols)
% Connect two pixels in an image with the desired graylevel
%
% Command line
% ------------
% result = func_DrawLine(Img, X1, Y1, X2, Y2)
% input:    Img : the original image.
%           (X1, Y1), (X2, Y2) : points to connect.
%           nG : the gray level of the line.
% output:   result
%
% Note
% ----
%   Img can be anything
%   (X1, Y1), (X2, Y2) should be NOT be OUT of the Img
%
%   The computation cost of this program is around half as Cubas's [1]
%   [1] As for Cubas's code, please refer
%   http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?obiectId=4177
%
% Example
% -------
% result = func_DrawLine(zeros(5, 10), 2, 1, 5, 10, 1)
% result =
%      0     0     0     0     0     0     0     0     0     0
%      1     1     1     0     0     0     0     0     0     0
%      0     0     0     1     1     1     0     0     0     0
%      0     0     0     0     0     0     1     1     1     0
%      0     0     0     0     0     0     0     0     0     1
%
%
% iing Tian Oct. 31 2000
% scuteeitian@hotmail.com
% This program is written in Oct.2000 during my postgraduate in
% GuangZhou, P. R. China.
% Version 1.0
X=nan(1,300);
Y=nan(1,300);


i=1;
if abs(X1 - X0) <= abs(Y1 - Y0)
    if Y1 < Y0
        k = X1; X1 = X0; X0 = k;
        k = Y1; Y1 = Y0; Y0 = k;
    end
    X(1)=X0;
    Y(1)=Y0;
    if (X1 >= X0) & (Y1 >= Y0)
        dy = Y1-Y0; dx = X1-X0;
        p = 2*dx; n = 2*dy - 2*dx; tn = dy;
        while (Y(i) < Y1)
            if tn >= 0
                tn = tn - p;
                X(i+1) = X(i);
            else
                tn = tn + n; X(i+1) = X(i) + 1;
            end
            Y(i+1) = Y(i) + 1;
            i=i+1;
        end
    else
        dy = Y1 - Y0; dx = X1 - X0;
        p = -2*dx; n = 2*dy + 2*dx; tn = dy;
        while (Y(i) <= Y1)
            if tn >= 0
                tn = tn - p;
                X(i+1) = X(i);
            else
                tn = tn + n; X(i+1) = X(i) - 1;
            end
            Y(i+1) = Y(i) + 1;
            i=i+1;
        end
    end
else
    if X1 < X0
        k = X1; X1 = X0; X0 = k;
        k = Y1; Y1 = Y0; Y0 = k;
    end
    X(1)=X0;
    Y(1)=Y0;
    if (X1 >= X0) & (Y1 >= Y0)
        dy = Y1 - Y0; dx = X1 - X0;
        p = 2*dy; n = 2*dx-2*dy; tn = dx;
        while (X(i) < X1)
            if tn >= 0
                tn = tn - p;
                Y(i+1) = Y(i);
            else
                tn = tn + n; Y(i+1) = Y(i) + 1;
            end
            X(i+1) = X(i) + 1; 
            i=i+1;
        end
    else
        dy = Y1 - Y0; dx = X1 - X0;
        p = -2*dy; n = 2*dy + 2*dx; tn = dx;
        while (X(i) < X1)
            if tn >= 0
                tn = tn - p;
                Y(i+1) = Y(i);
            else
                tn = tn + n; Y(i+1) = Y(i) - 1;
            end
            X(i+1) = X(i) + 1; 
            i=i+1;
        end
    end
end

Y=Y(Y>0 & Y<cols+1);
X=X(Y>0 & Y<cols+1);
b=1;
