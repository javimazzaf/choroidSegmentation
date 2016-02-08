function [h]=plot3d_errorbars(x, y, z, e)
% this matlab function plots 3d data using the plot3 function
% it adds vertical errorbars to each point symmetric around z
% I experimented a little with creating the standard horizontal hash 
% tops the error bars in a 2d plot, but it creates a mess when you rotate 
% the plot
%
% x = xaxis, y = yaxis, z = zaxis, e = error value

% create the standard 3d scatterplot
hold off;
h=plot3(x, y, z, '.k');

% looks better with large points
set(h, 'MarkerSize', 5);
hold on

% now draw the vertical errorbar for each point
for i=1:length(x)
	xV = [x(i); x(i)];
	yV = [y(i); y(i)];
	zMin = z(i) + e(i);
	zMax = z(i) - e(i);

	zV = [zMin, zMax];
	% draw vertical error bar
	h=plot3(xV, yV, zV, '-r');
	set(h, 'LineWidth', 2);
end