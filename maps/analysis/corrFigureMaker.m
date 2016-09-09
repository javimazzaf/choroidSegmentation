function [slope,R2,pVal,fg] = corrFigureMaker(x,y)

fg = figure;

h1 = plot(x,y,'o'); hold all
set(h1,'markerfacecolor',get(h1,'color'))
set(gca,'FontSize',20)
xlabel('Age [yr]')
ylabel('meanThickness [\mum]')
mnX = min(x);
mxX = max(x);
xlim([-0.05,1.05] * (mxX-mnX) + mnX)

[datafit,gof,~] = fit(x,y,'poly1');
ALc             = coeffvalues(datafit);
[r,p]           = corrcoef([x,y,datafit(x)]);

plot(sort(x),datafit(sort(x)),'color',get(h1,'color'),'LineWidth',3);

slope = ALc(1);
R2 = gof.rsquare;
pVal = p(2,3);

end