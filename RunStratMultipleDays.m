function TotalPnL = RunStratMultipleDays(ES1Index, TargetFactor, StopLossFactor)
plotFlag = 0;

% Date range for testing
StartDate = '08/04/2013';
EndDate = '14/06/2013';
StartDateNumber = datenum(StartDate, 'dd/mm/yyyy');
EndDateNumber = datenum(EndDate, 'dd/mm/yyyy');
VectorDateNumber = StartDateNumber:EndDateNumber;
VectorDateNumber = VectorDateNumber(weekday(VectorDateNumber)<=6);
VectorDateNumber = VectorDateNumber(weekday(VectorDateNumber)>=2);

for iDate = 1:length(VectorDateNumber)
    
    Date = datestr(VectorDateNumber(iDate), 'dd/mm/yyyy');
    
    % Test strat
    PnL(iDate) = TradingStrategy_LN(ES1Index, Date, TargetFactor, StopLossFactor, plotFlag);
    
    % Save fig
    if plotFlag
        title(sprintf('%s PnL = %.2f USD', Date, PnL(iDate)));
        ylabel('ES1 Index')
        DateStr = regexprep(Date,'/','-');
        saveas(gcf, sprintf('../Figures/DayTrade_%s.jpg', DateStr), 'jpg')
        close all
    end
    
end

if plotFlag
stem(VectorDateNumber, PnL);
ylabel('Daily PnL');
StartDateStr = regexprep(StartDate,'/','-');
EndDateStr = regexprep(EndDate,'/','-');
title(sprintf('%s to %s PnL = %.2f USD', StartDate, EndDate, sum(PnL)));
datetick('x', 'dd/mm/yyyy')
saveas(gcf, sprintf('../Figures/PnL_%s_%s_Target_%d_StopLoss_%d.jpg', StartDateStr, EndDateStr, TargetFactor, StopLossFactor), 'jpg')
end

TotalPnL = sum(PnL);
