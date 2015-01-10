classdef TradeBookClass
    %TRADEBOOKCLASS Stores a record of all trades
    %   Contains methods for opening and closing positions
    %   and plotting results of a strategy
    
    properties
        Status     % Position open or closed?
        Type       % Position long or short?
        Volume     % Size of position
        OpenTime   % Time position opened at
        OpenPrice  % Price position opened at
        CloseTime  % Time position closed at
        ClosePrice % Price position closed at
        PnL        % PnL for this trade
    end
    
    methods
        function [obj, Capital] = OpenTradePosition(obj, Capital, Type, Volume, Time, Price, Fee)
            % Opens a new trade position
            obj.Status{end+1,1} = 'Open';
            obj.Type{end+1,1} = Type;
            obj.Volume(end+1,1) = Volume;
            obj.OpenTime(end+1,1) = Time;
            obj.OpenPrice(end+1,1) = Price;
            obj.PnL(end+1,1) = -Volume*Fee;
            
            % Edit capital
            Capital = Capital - Volume*(Price + Fee);
            %Capital = UpdateCapital()
            
        end
        function [obj, Capital] = CloseTradePositions(obj, Capital, CurrentTime, CurrentPrice, TargetLong, StopLossLong, TargetShort, StopLossShort, Fee)
            % Closes existing trade positions according to current price
            
            % Find open positions
            OpenPositions = find(strcmp('Open', obj.Status)); % Indices of open positions
            
            % Close long positions if current price outside of acceptable range
            OpenLongPositions = OpenPositions(strcmp('Long', obj.Type(OpenPositions))); % Indices of open long positions
            LongPositionsToClose = OpenLongPositions((CurrentPrice > obj.OpenPrice(OpenLongPositions)*(1+TargetLong) | CurrentPrice < obj.OpenPrice(OpenLongPositions)*(1+StopLossLong)));
            if ~isempty(LongPositionsToClose)
                obj.Status(LongPositionsToClose) = {'Closed'};
                obj.ClosePrice(LongPositionsToClose,1) = CurrentPrice;
                obj.CloseTime(LongPositionsToClose,1) = CurrentTime;
                obj.PnL(LongPositionsToClose,1) = obj.PnL(LongPositionsToClose,1) + obj.ClosePrice(LongPositionsToClose) - obj.OpenPrice(LongPositionsToClose) - obj.Volume(LongPositionsToClose)*Fee;
                Capital = Capital + length(LongPositionsToClose)*(CurrentPrice - Fee);
            end
            
            % Close short positions if current price outside of acceptable range
            OpenShortPositions = OpenPositions(strcmp('Short', obj.Type(OpenPositions))); % Indices of open short positions
            ShortPositionsToClose = OpenShortPositions((CurrentPrice < obj.OpenPrice(OpenShortPositions)*(1+TargetShort) | CurrentPrice > obj.OpenPrice(OpenShortPositions)*(1+StopLossShort)));
            if ~isempty(ShortPositionsToClose)
                obj.Status(ShortPositionsToClose,1) = {'Closed'};
                obj.ClosePrice(ShortPositionsToClose,1) = CurrentPrice;
                obj.CloseTime(ShortPositionsToClose,1) = CurrentTime;
                obj.PnL(ShortPositionsToClose,1) = obj.PnL(ShortPositionsToClose,1) + obj.OpenPrice(ShortPositionsToClose) - obj.ClosePrice(ShortPositionsToClose) - obj.Volume(ShortPositionsToClose)*Fee;
                Capital = Capital + 2*sum(obj.Volume(ShortPositionsToClose,1).*obj.OpenPrice(ShortPositionsToClose,1)) - length(ShortPositionsToClose)*(CurrentPrice + Fee);
            end
            
        end
        function PlotTimeSeries(obj, VariableToPlot, varargin)
            % Plot time series of prices or trading volumes.
            % VariableToPlot is one of the prices or the trading volume.
            % Optional third argument is an x-axis range [xmin xmax] in datenum format.
            
            figure
            MarkerSize = 4;
            
            % Order by closing time
            [SortedClosingTimes, Sorting] = sort(obj.CloseTime);
            
            switch VariableToPlot
                case 'Daily Volumes'
                    % Plot time series of daily volumes opened and closed.
                    plot(obj.OpenTime, obj.Volume, '.')
                    %accumarray(Sorting)
                    %, SortedClosingTimes, obj.Volume(Sorting), 'x');
                case 'Daily PnL'
                    % Plot time series of daily PnL (as trades are closed).
                    plot(SortedClosingTimes, obj.PnL(Sorting));
                case 'Cumulative PnL'
                    % Plot time series of cumulative PnL
                    plot(SortedClosingTimes, cumsum(obj.PnL(Sorting)),'.')
                otherwise
                    disp('Unrecognised variable to plot');
            end
            
            title(sprintf('Time Series of %s', VariableToPlot))
            ylabel(VariableToPlot)
            if nargin == 4
                XRange = [datenum(varargin(1)), datenum(varargin(2))];
            else
                XRange = [SortedClosingTimes(1), SortedClosingTimes(end)];
            end
            xlim(XRange)
            datetick('x')
            xlabel('Time')
        end
        function ProduceSummary(obj)
            % Writes out summary of performance of trading strategy
            
            % PnL
            [~, Sorting] = sort(obj.CloseTime); % Order by closing time
            CumSum = cumsum(obj.PnL(Sorting));
            fprintf('PnL %.2f\n', CumSum(end));
            
        end

    end
    
end
