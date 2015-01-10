function MarketData = ReadMarketDataFromExcel
%ReadMarketDataFromExcel Reads market data from Excel
% Returns a MarketDataClass object.

% Specify location of Excel file (ES1 Index)
ExcelFileName = 'C:\Users\Lucca\Backtesting Platform\Data\es.xlsx';
NumberHeaderRows = 3;
TimeZoneAdjustment = -6;

% Read data from Excel file
[NumericalData, TextData, ~] = xlsread(ExcelFileName);

% Process time bar data
DateString = TextData((NumberHeaderRows+1):end,1);
DateFormat = '^\d{2}/\d{2}/\d{4}\s{1}\d{2}:\d{2}:\d{2}'; % Expected format "dd/mm/yyyy HH:MM:SS"
DateString = FormatDateString(DateString, DateFormat);
DateNumber = DateStr2DateNum(DateString, TimeZoneAdjustment);

% Create MarketDataClass
MarketData = MarketDataClass;
MarketData.AssetName = TextData{1,1};
MarketData.TimeBar = DateNumber;
MarketData.PriceOpen = NumericalData(:,1);
MarketData.PriceHigh = NumericalData(:,2);
MarketData.PriceLow = NumericalData(:,3);
MarketData.PriceClose = NumericalData(:,4);
MarketData.TradeVolume = NumericalData(:,5); 

end

%%% Subfunctions
function DateString = FormatDateString(DateString, DateFormat)
% Formats date strings correctly
% If time is missing it is assumed to be 00:00:00

for iEntry = 1:length(DateString)
    if isempty(regexp(DateString{iEntry}, DateFormat, 'once'))
        DateString{iEntry} = sprintf('%s 00:00:00', DateString{iEntry});
    end
end

end
function DateNumber = DateStr2DateNum(DateString, TimeZoneAdjustment)
% Converts a cell array of date strings 
% to a vector of date numbers

DateNumber = zeros(length(DateString), 1);
for iEntry = 1:length(DateString)
    DateNumber(iEntry) = datenum(DateString{iEntry},'dd/mm/yyyy HH:MM:SS') + TimeZoneAdjustment/24;
end

end