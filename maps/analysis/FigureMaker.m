function [r,p,gof]=FigureMaker(x,y,xlab,ylab,linespec,fittype,new,exclude)
if new
    figure
else
    figure(gcf)
end
hold all
h1=plot(x,y,linespec);
set(h1,'markerfacecolor',get(h1,'color'))
set(gca,'FontSize',20)
xlabel(xlab)
ylabel(ylab)
mnX = min(x);
mxX = max(x);
xlim([-0.05,1.05] * (mxX-mnX) + mnX)

[datafit,gof,~]=fit(x,y,fittype,'exclude',exclude);
ALc=coeffvalues(datafit);
[r,p]=corrcoef([x,y,datafit(x)]);
gcf
plot(sort(x),datafit(sort(x)),'color',get(h1,'color'),'LineWidth',3);
if ischar(fittype)
    o=' (';
else
    o=' Ln(';
end
annot=strvcat([ylab(1:regexp(ylab,'[')-2) ' = ' num2str(ALc(1)) o xlab(1:regexp(xlab,'[')-2)...
    ') + ' num2str(ALc(2))],['   R^{2} = ' num2str(gof.rsquare)],['    P = ' num2str(p(2,3))]);
top=get(get(h1,'parent'),'ytick');
top=top(end);
right=get(get(h1,'parent'),'xtick');
right=right(end);

text(right,top,annot,'horizontalalignment','right','verticalalignment','top','FontSize',18)






end