clear all
close all

load ES1Index

TargetFactor = 0.1:0.1:5;
StopLossFactor = 0.1:0.1:5;

for iTarget = 1:length(TargetFactor)
    for iStopLoss = 1:length(StopLossFactor)

        TotalPnL(iTarget, iStopLoss) = RunStratMultipleDays(ES1Index, TargetFactor(iTarget), StopLossFactor(iStopLoss));

    end
end

% Plot
surf(StopLossFactor,TargetFactor,TotalPnL)
xlabel('Stop Loss Factor')
ylabel('Target Factor')
title('PnL as Function of Trading Parameters')
