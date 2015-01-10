function PnL = TradingStrategy_LN(MarketData, Date, TargetFactor, StopLossFactor, PlotFlag)
%Runs trading strategy on MarketData class.
%close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Trading strategy parameters %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Market hours
MarketOpen = '08:30';              % Format HH:MM
MarketClose = '16:00';             % N.B. 24 hour clock

% Commission fees & slippage
CommissionFeePerTrade = 0;                           % Cost per trade (flat)
Slippage = 0;
PricePerTick = 50;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialise based on inputs %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Identify range of market data for trading strategy
MarketOpenNumber = datenum(sprintf('%s %s', Date, MarketOpen), 'dd/mm/yyyy HH:MM');
MarketCloseNumber = datenum(sprintf('%s %s', Date, MarketClose), 'dd/mm/yyyy HH:MM');
MarketOpenBar = find(MarketData.TimeBar==MarketOpenNumber,1);
MarketCloseBar = find(MarketData.TimeBar==MarketCloseNumber,1);
if isempty(MarketOpenBar) || isempty(MarketCloseBar)
    error('Trading dates outside of range of market data or market is closed.')
end

% Plot market data
if PlotFlag, PlotTimeSeries(MarketData, 'OHLC Bars', MarketOpenBar, MarketCloseBar), end;

% Add horizontal bars for strategy
if PlotFlag
    hold on
    plot([MarketData.TimeBar(MarketOpenBar), MarketData.TimeBar(MarketCloseBar)], [MarketData.PriceHigh(MarketOpenBar), MarketData.PriceHigh(MarketOpenBar)], 'b--')
    plot([MarketData.TimeBar(MarketOpenBar), MarketData.TimeBar(MarketCloseBar)], [MarketData.PriceLow(MarketOpenBar), MarketData.PriceLow(MarketOpenBar)], 'b--')
end

HeightOpenBar = MarketData.PriceHigh(MarketOpenBar) - MarketData.PriceLow(MarketOpenBar);

% Execute trading strategy
bTradeOpen = 0;
bTradeClosed = 0;
for ThisTimeBar = (MarketOpenBar+1):MarketCloseBar
    % Market is open during these hours
    
    if bTradeOpen
        % Look for opportunities to close
        if strcmp(Type,'BUY')
            if MarketData.PriceHigh(ThisTimeBar)>=LongTarget
                if PlotFlag, plot(MarketData.TimeBar(ThisTimeBar), LongTarget, 'go'), end
                PnL = LongTarget - Price;
                bTradeClosed = 1;
                bTradeOpen = 0;
            elseif MarketData.PriceLow(ThisTimeBar)<=LongStopLoss
                % close unfavourably
                if PlotFlag, plot(MarketData.TimeBar(ThisTimeBar), LongStopLoss, 'ro'), end
                PnL = LongStopLoss - Price;
                bTradeClosed = 1;
                bTradeOpen = 0;
            end
            
        elseif strcmp(Type,'SELL')
            if MarketData.PriceLow(ThisTimeBar)<=ShortTarget
                % close favourably
                if PlotFlag, plot(MarketData.TimeBar(ThisTimeBar), ShortTarget, 'go'), end
                PnL = Price - ShortTarget;
                bTradeClosed = 1;
                bTradeOpen = 0;
            elseif MarketData.PriceHigh(ThisTimeBar)>=ShortStopLoss
                % close unfavourably
                if PlotFlag, plot(MarketData.TimeBar(ThisTimeBar), ShortStopLoss, 'ro'), end
                PnL = Price - ShortStopLoss;
                bTradeClosed = 1;
                bTradeOpen = 0;
            end
        end
        
        
    elseif ~bTradeClosed
        % Look for opportunities to open trade
        if MarketData.PriceHigh(ThisTimeBar)>=MarketData.PriceHigh(MarketOpenBar)
            % Place market order BUY
            % Think price is on the way up!
            % Purchase price will be the high of the open bar
            Price = MarketData.PriceHigh(MarketOpenBar);
            Type = 'BUY';
            if PlotFlag, plot(MarketData.TimeBar(ThisTimeBar), MarketData.PriceHigh(MarketOpenBar), 'bo'), end
            
            % Place limit order too
            LongTarget = MarketData.PriceHigh(MarketOpenBar)+HeightOpenBar*TargetFactor;
            LongStopLoss = MarketData.PriceHigh(MarketOpenBar)-HeightOpenBar*StopLossFactor;
            
            % Plot limits
            if PlotFlag, plot([MarketData.TimeBar(ThisTimeBar), MarketData.TimeBar(MarketCloseBar)], [LongTarget, LongTarget], 'g--'), end
            if PlotFlag, plot([MarketData.TimeBar(ThisTimeBar), MarketData.TimeBar(MarketCloseBar)], [LongStopLoss, LongStopLoss], 'r--'), end
            
            bTradeOpen = 1;
        elseif MarketData.PriceLow(ThisTimeBar)<=MarketData.PriceLow(MarketOpenBar)
            % Place market order SELL
            % Think price is on the way down!
            % Sell price will be the low of the open bar
            Price = MarketData.PriceLow(MarketOpenBar);
            Type = 'SELL';
            if PlotFlag, plot(MarketData.TimeBar(ThisTimeBar), MarketData.PriceLow(MarketOpenBar), 'bo'), end
            
            % Place limit order too
            ShortTarget = MarketData.PriceLow(MarketOpenBar)-HeightOpenBar*TargetFactor;
            ShortStopLoss = MarketData.PriceLow(MarketOpenBar)+HeightOpenBar*StopLossFactor;
            
            % Plot limits
            if PlotFlag, plot([MarketData.TimeBar(ThisTimeBar), MarketData.TimeBar(MarketCloseBar)], [ShortTarget, ShortTarget], 'g--'), end
            if PlotFlag, plot([MarketData.TimeBar(ThisTimeBar), MarketData.TimeBar(MarketCloseBar)], [ShortStopLoss, ShortStopLoss], 'r--'), end
            
            bTradeOpen = 1;
        end
    end
    
    if (ThisTimeBar == MarketCloseBar) && ~bTradeClosed
        if strcmp(Type,'BUY')
            PnL = MarketData.PriceHigh(MarketCloseBar) - Price;
        elseif strcmp(Type,'SELL')
            PnL = Price - MarketData.PriceLow(MarketCloseBar);
        end
    end
end

% Adjust PnL for fees
PnL = PnL - 2*Slippage;
PnL = PnL*PricePerTick;
PnL = PnL - 2*CommissionFeePerTrade;

end


%%%%%%%%%%%%%%%%
% Subfunctions %
%%%%%%%%%%%%%%%%

function PlotCapital(x, y)
figure
plot(x,y, '.-')
datetick('x')
xlabel('Time')
ylabel('Capital')
end

function y = Linear(x,m,c)
y = m*x + c;
end

function gradient = GradientCalculator(dy, dx)
gradient = dy/dx;
end

function TradeVolume = GetTradeVolume(TradeVolumeFunction, varargin)
% Decide how large the trade should be
[A, B] = varargin([1, 2]);
switch TradeVolumeFunction
    case 'Constant'
        % TV = A
        TradeVolume = A;
    case 'Linear'
        % TV = m*|X| + C
        TradeVolume = A*abs(TradeVolumeGradient)*MarketData.PriceGradient(iTime) + C;
    case 'Exponential'
        % TV = A*exp(B*|X|)
        TradeVolume = A*exp(B*abs(TradeVolumeGradient));
    otherwise
end
end

function Fraction = GetFractionalPart(Number)
% Returns the fractional part of a number
% e.g. Number = 1.23 returns Fraction = 0.23
Integer = fix(Number);
Fraction = abs(Number - Integer);
end

function bMarketOpen = IsMarketOpen(CurrentTime, MarketOpen, MarketClose)
% Evaluates whether market is open at current time
bAfterMarketOpen = (GetFractionalPart(CurrentTime) - GetFractionalPart(MarketOpen)) >= 0;    % 1 if current time after market opened
bBeforeMarketClose = (GetFractionalPart(MarketClose) - GetFractionalPart(CurrentTime)) >= 0; % 1 if current time before market closed
bMarketOpen = bAfterMarketOpen*bBeforeMarketClose; % 1 if market open
%fprintf('%s AfterOpen %d BeforeClose %d\n', datestr(CurrentTime, 'dd/mm/yyyy HH:MM:SS'), bAfterOpen, bBeforeClose); % For debugging
end

function bClosingOutPeriod = IsClosingOutPeriod(CurrentTime, MarketClose, EndOfTrading)
% Evaluates whether in closing out period at current time
bAfterMarketClose = (GetFractionalPart(CurrentTime) - GetFractionalPart(MarketClose)) >= 0;    % 1 if current time after market closed
bBeforeEndOfTrading = (GetFractionalPart(EndOfTrading) - GetFractionalPart(CurrentTime)) >= 0; % 1 if before the end of the closing out period
bClosingOutPeriod = bAfterMarketClose*bBeforeEndOfTrading; % 1 if closing out period
end
