function fix3dPlot(h,xLims,yLims,zLims,xLabel,yLabel,zLabel,xTick,yTick,zTick,titleStr,legendStr)
    axes(h); h = gca; % just in case
    h.LineWidth = 2; h.Color = 'w';
    h.XColor = 'k'; h.YColor = 'k'; h.ZColor = 'k';
    h.Box = 'off';
    h.TickDir = 'out'; h.LineWidth = 2;
    h.GridAlpha = 0.05;
    h.GridLineStyle = '--';
    
    if ~isempty(xLims); h.XLim = round(xLims,1); end
    if ~isempty(yLims); h.YLim = round(yLims,1); end
    if ~isempty(zLims); h.ZLim = round(zLims,1); end
         
    if ~exist('xTick','var'); xTick = []; end
    if ~exist('yTick','var'); yTick = []; end
    if ~exist('zTick','var'); zTick = []; end
    
    if ~isempty(xTick)
        h.XTick = round(xTick,2);
    else
        h.XTick = linspace(h.XLim(1),h.XLim(2),5); 
    end
    if ~isempty(yTick) 
        h.YTick = round(yTick,2); 
    else
        h.YTick = linspace(h.YLim(1),h.YLim(2),5); 
    end
    if ~isempty(zTick) 
        h.ZTick = round(zTick,2); 
    else
        h.ZTick = linspace(h.ZLim(1),h.ZLim(2),5); 
    end
     
    h.FontSize = 12; h.FontName = 'Lato';
     
    h.XLabel.String = xLabel;
    h.XLabel.FontSize = 14; h.XLabel.FontName = 'Lato';
    h.YLabel.String = yLabel;
    h.YLabel.FontSize = 14; h.YLabel.FontName = 'Lato';
    h.ZLabel.String = zLabel;
    h.ZLabel.FontSize = 14; h.ZLabel.FontName = 'Lato';
     
    if exist('legendStr','var')
        hl = legend(h,legendStr);
        hl.FontSize = 14; hl.TextColor = 'k'; hl.Color = 'w'; hl.Box = 'off';
        hl.Location = 'northwest';
    end
     
    if exist('titleStr','var')
        ht = title(h,titleStr);
        ht.Interpreter = 'none';
        ht.Color = 'k'; ht.FontSize = 16; ht.FontName = 'Lato';
    end
    
    axis(h,'square');
    grid(h,'on');
end