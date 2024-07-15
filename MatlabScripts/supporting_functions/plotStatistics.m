function plotStatistics(p, max, xedgemin, xedgemax)

xvalue = (xedgemin+xedgemax)/2;
plot([xedgemin xedgemax],[max*1.05 max*1.05], 'Marker', '|', 'Color', 'k')
if p <= 0.05 && p > 0.01
    text(xvalue, max*1.1,'*','HorizontalAlignment','center','VerticalAlignment','top')
elseif p <= 0.01 && p > 0.001
    text(xvalue, max*1.1,'**','HorizontalAlignment','center','VerticalAlignment','top')
elseif p <= 0.001
    text(xvalue, max*1.1,'***','HorizontalAlignment','center','VerticalAlignment','top')
else
    text(xvalue, max*1.1,'ns','HorizontalAlignment','center')
end

end