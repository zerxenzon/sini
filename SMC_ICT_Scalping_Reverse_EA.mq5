//+------------------------------------------------------------------+
//|                                  SMC_ICT_Scalping_Reverse_EA.mq5 |
//|                                         Smart Money Concepts     |
//|                                         + ICT + REVERSE/HEDGE    |
//|                                         For XAUUSD M1            |
//+------------------------------------------------------------------+
#property copyright "SMC ICT Reverse EA - zerxenzon"
#property version   "4.03"
#property strict
#property description "Full Featured EA with SMC & ICT + Reverse Trading"
#property description "Can BUY and SELL simultaneously - FIXED VERSION"

// Include Libraries
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                  |
//+------------------------------------------------------------------+

input group "=== 💰 MONEY MANAGEMENT ==="
input double   RiskPercent = 1.0;           // Risk per Trade (%)
input double   FixedLotSize = 0.01;         // Fixed Lot (if 0, use Risk%)
input double   MaxDailyLoss = 5.0;          // Max Daily Loss (%)
input double   MaxDailyProfit = 10.0;       // Max Daily Profit (%)
input int      MaxBuyPositions = 2;         // Max BUY Positions
input int      MaxSellPositions = 2;        // Max SELL Positions
input double   MinRiskReward = 1.5;         // Minimum Risk:Reward Ratio

input group "=== 🔄 REVERSE/HEDGE SETTINGS ==="
input bool     EnableHedging = true;        // Enable BUY + SELL Same Time
input bool     AutoReverse = true;          // Auto Reverse on Signal
input bool     UseGridTrading = false;      // Grid Trading Mode
input double   GridStep = 20;               // Grid Step (points)
input int      MaxGridLevels = 3;           // Max Grid Levels

input group "=== 📊 SMC SETTINGS ==="
input bool     UseSMC = true;               // Use Smart Money Concepts
input int      OrderBlockPeriod = 20;       // Order Block Detection Period
input bool     UseFVG = true;               // Use Fair Value Gap
input double   FVGMinSize = 10;             // Min FVG Size (points)
input bool     UseBOS = true;               // Use Break of Structure
input bool     UseCHoCH = true;             // Use Change of Character
input int      SwingPeriod = 10;            // Swing High/Low Period

input group "=== 🎯 ICT CONCEPTS ==="
input bool     UseICT = true;               // Use ICT Methodology
input bool     UseLiquiditySweep = true;    // Detect Liquidity Sweeps
input bool     UseKillZones = true;         // Trade Only in Kill Zones
input bool     UsePowerOf3 = true;          // Power of 3 Pattern
input int      AsianSessionStart = 0;       // Asian Session Start (hour)
input int      LondonSessionStart = 8;      // London Session Start (hour)
input int      NYSessionStart = 13;         // NY Session Start (hour)

input group "=== 📈 TECHNICAL INDICATORS ==="
input int      EMA_Fast = 9;                // Fast EMA Period
input int      EMA_Slow = 21;               // Slow EMA Period
input int      EMA_Trend = 50;              // Trend EMA Period
input int      RSI_Period = 14;             // RSI Period
input double   RSI_Overbought = 70;         // RSI Overbought Level
input double   RSI_Oversold = 30;           // RSI Oversold Level
input int      ATR_Period = 14;             // ATR Period
input double   ATR_Multiplier = 1.5;        // ATR Multiplier for SL

input group "=== 🛡️ RISK MANAGEMENT ==="
input bool     UseTrailingStop = true;      // Use Trailing Stop
input bool     UseBreakEven = true;         // Move to Breakeven
input double   BreakEvenTrigger = 15;       // BE Trigger (points)
input double   BreakEvenOffset = 2;         // BE Offset (points)
input bool     UsePartialClose = true;      // Partial Close at Target
input double   PartialClosePercent = 50;    // Partial Close %
input double   PartialCloseAt = 50;         // Partial Close at (%)

input group "=== ⚙️ ADVANCED SETTINGS ==="
input int      MagicNumber = 888888;        // Magic Number
input int      Slippage = 30;               // Max Slippage (points)
input int      MaxSpread = 30;              // Max Spread (points)
input bool     UseNewsFilter = false;       // Avoid News Times
input bool     ShowInfo = true;             // Show Info Panel
input bool     SendAlerts = true;           // Send Trade Alerts
input int      MinBarsBetweenEntry = 3;     // Min Bars Between Same Direction

input group "=== 🕒 TIME FILTER ==="
input bool     UseTimeFilter = false;       // Use Time Filter
input int      StartHour = 0;               // Start Hour
input int      EndHour = 23;                // End Hour

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+

CTrade trade;
CPositionInfo positionInfo;
COrderInfo orderInfo;
CSymbolInfo symbolInfo;

// Indicator Handles
int handleEMA_Fast, handleEMA_Slow, handleEMA_Trend;
int handleRSI, handleATR;

// Indicator Buffers
double emaFast[], emaSlow[], emaTrend[];
double rsiBuffer[], atrBuffer[];

// Market Data
MqlTick lastTick;
MqlRates rates[];

// Trading State
datetime lastBarTime = 0;
datetime lastBuyTime = 0;
datetime lastSellTime = 0;
datetime currentDay = 0;
double dailyProfit = 0;
double dailyLoss = 0;
int totalTradesToday = 0;
int totalBuyToday = 0;
int totalSellToday = 0;
double accountBalance = 0;

// Grid Trading
double lastBuyPrice = 0;
double lastSellPrice = 0;
int buyGridLevel = 0;
int sellGridLevel = 0;

// Hedging capability
bool canHedge = false;

// SMC Data Structures
struct OrderBlock {
    datetime time;
    double high;
    double low;
    bool isBullish;
    bool isValid;
};

struct FairValueGap {
    datetime time;
    double upper;
    double lower;
    bool isBullish;
    bool isFilled;
};

struct SwingPoint {
    datetime time;
    double price;
    bool isHigh;
};

OrderBlock bullishOB, bearishOB;
FairValueGap lastFVG;
SwingPoint lastSwingHigh, lastSwingLow;

// ICT Data
bool isAsianKillZone = false;
bool isLondonKillZone = false;
bool isNYKillZone = false;
bool liquiditySweepBullish = false;
bool liquiditySweepBearish = false;

// Price Action
bool breakOfStructureBullish = false;
bool breakOfStructureBearish = false;
bool changeOfCharacterBullish = false;
bool changeOfCharacterBearish = false;

//+------------------------------------------------------------------+
//| Get Best Filling Mode for Symbol - PROPERLY FIXED                |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetFillingMode()
{
    // Initialize symbol info
    symbolInfo.Name(_Symbol);
    symbolInfo.RefreshRates();
    
    // Get filling mode flags
    uint filling_mode = (uint)symbolInfo.TradeFillFlags();
    
    // Check each filling mode
    if((filling_mode & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
    {
        Print("✅ Using ORDER_FILLING_FOK");
        return ORDER_FILLING_FOK;
    }
    
    if((filling_mode & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
    {
        Print("✅ Using ORDER_FILLING_IOC");
        return ORDER_FILLING_IOC;
    }
    
    // Default
    Print("✅ Using ORDER_FILLING_RETURN (default)");
    return ORDER_FILLING_RETURN;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
    // Print EA Info
    Print("╔════════════════════════════════════════╗");
    Print("║   SMC + ICT REVERSE EA v4.03          ║");
    Print("║   Smart Money + ICT + HEDGE           ║");
    Print("║   Developer: zerxenzon                ║");
    Print("║   PROPERLY FIXED VERSION              ║");
    Print("╚════════════════════════════════════════╝");
    
    // Initialize Symbol Info
    symbolInfo.Name(_Symbol);
    if(!symbolInfo.RefreshRates())
    {
        Print("❌ ERROR: Failed to get symbol info!");
        return INIT_FAILED;
    }
    
    // Check Hedging capability
    ENUM_ACCOUNT_MARGIN_MODE marginMode = (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
    
    if(EnableHedging)
    {
        if(marginMode == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
        {
            canHedge = true;
            Print("✅ HEDGE Account Detected - Hedging Enabled!");
        }
        else
        {
            canHedge = false;
            Print("⚠️ WARNING: NETTING Account Detected");
            Print("⚠️ Current mode: ", EnumToString(marginMode));
            Print("⚠️ Hedging disabled, will use AUTO REVERSE instead");
        }
    }
    else
    {
        canHedge = false;
        Print("ℹ️ Hedging disabled by user settings");
    }
    
    // Validate Symbol
    if(_Symbol != "XAUUSD" && _Symbol != "GOLD" && _Symbol != "XAUUSDm" && 
       StringFind(_Symbol, "GOLD") == -1 && StringFind(_Symbol, "XAU") == -1)
    {
        Print("⚠️ WARNING: EA optimized for XAUUSD/GOLD");
    }
    
    // Initialize Indicators
    handleEMA_Fast = iMA(_Symbol, PERIOD_M1, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
    handleEMA_Slow = iMA(_Symbol, PERIOD_M1, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
    handleEMA_Trend = iMA(_Symbol, PERIOD_M1, EMA_Trend, 0, MODE_EMA, PRICE_CLOSE);
    handleRSI = iRSI(_Symbol, PERIOD_M1, RSI_Period, PRICE_CLOSE);
    handleATR = iATR(_Symbol, PERIOD_M1, ATR_Period);
    
    if(handleEMA_Fast == INVALID_HANDLE || handleEMA_Slow == INVALID_HANDLE ||
       handleEMA_Trend == INVALID_HANDLE || handleRSI == INVALID_HANDLE ||
       handleATR == INVALID_HANDLE)
    {
        Print("❌ ERROR: Failed to create indicators!");
        return INIT_FAILED;
    }
    
    // Setup Trade Object
    trade.SetExpertMagicNumber(MagicNumber);
    trade.SetDeviationInPoints(Slippage);
    trade.SetAsyncMode(false);
    
    // FIXED: Set filling mode properly
    ENUM_ORDER_TYPE_FILLING fillingMode = GetFillingMode();
    trade.SetTypeFilling(fillingMode);
    
    // Set Array as Series
    ArraySetAsSeries(emaFast, true);
    ArraySetAsSeries(emaSlow, true);
    ArraySetAsSeries(emaTrend, true);
    ArraySetAsSeries(rsiBuffer, true);
    ArraySetAsSeries(atrBuffer, true);
    ArraySetAsSeries(rates, true);
    
    // Initialize Variables
    accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    currentDay = GetCurrentDay();
    
    // Initialize SMC Structures
    bullishOB.isValid = false;
    bearishOB.isValid = false;
    lastFVG.isFilled = true;
    
    Print("✅ EA Initialized Successfully!");
    Print("💰 Account Balance: $", accountBalance);
    Print("📊 Risk per Trade: ", RiskPercent, "%");
    Print("🎯 Min R:R Ratio: 1:", MinRiskReward);
    Print("🔧 SMC: ", UseSMC ? "ON" : "OFF", " | ICT: ", UseICT ? "ON" : "OFF");
    Print("🔄 Hedging: ", canHedge ? "ON" : "OFF", " | Reverse: ", AutoReverse ? "ON" : "OFF");
    Print("📊 Max BUY: ", MaxBuyPositions, " | Max SELL: ", MaxSellPositions);
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release Indicators
    if(handleEMA_Fast != INVALID_HANDLE) IndicatorRelease(handleEMA_Fast);
    if(handleEMA_Slow != INVALID_HANDLE) IndicatorRelease(handleEMA_Slow);
    if(handleEMA_Trend != INVALID_HANDLE) IndicatorRelease(handleEMA_Trend);
    if(handleRSI != INVALID_HANDLE) IndicatorRelease(handleRSI);
    if(handleATR != INVALID_HANDLE) IndicatorRelease(handleATR);
    
    // Print Summary
    Print("╔════════════════════════════════════════╗");
    Print("║   TRADING SESSION SUMMARY             ║");
    Print("╠════════════════════════════════════════╣");
    Print("║ Total Trades: ", totalTradesToday);
    Print("║ BUY Trades: ", totalBuyToday);
    Print("║ SELL Trades: ", totalSellToday);
    Print("║ Daily P/L: $", NormalizeDouble(dailyProfit - dailyLoss, 2));
    Print("╚════════════════════════════════════════╝");
    
    Comment("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if new bar
    datetime currentBarTime = iTime(_Symbol, PERIOD_M1, 0);
    bool isNewBar = (currentBarTime != lastBarTime);
    if(isNewBar) lastBarTime = currentBarTime;
    
    // Get current tick
    if(!SymbolInfoTick(_Symbol, lastTick)) return;
    
    // Update daily stats
    UpdateDailyStats();
    
    // Check daily limits
    if(CheckDailyLimits())
    {
        if(ShowInfo) DisplayInfo();
        return;
    }
    
    // Check spread
    if(!CheckSpread())
    {
        if(ShowInfo) DisplayInfo();
        return;
    }
    
    // Time filter
    if(UseTimeFilter && !IsTimeToTrade())
    {
        if(ShowInfo) DisplayInfo();
        return;
    }
    
    // Update indicators
    if(!UpdateIndicators()) 
    {
        if(ShowInfo) DisplayInfo();
        return;
    }
    
    // Update market data
    int copied = CopyRates(_Symbol, PERIOD_M1, 0, 100, rates);
    if(copied < 100) return;
    
    // Manage existing positions
    ManagePositions();
    
    // Only check for entries on new bar
    if(!isNewBar) 
    {
        if(ShowInfo) DisplayInfo();
        return;
    }
    
    // Update SMC analysis
    if(UseSMC) UpdateSMCAnalysis();
    
    // Update ICT analysis
    if(UseICT) UpdateICTAnalysis();
    
    // Check for trading opportunities
    CheckForBothEntries();
    
    // Display info panel
    if(ShowInfo) DisplayInfo();
}

//+------------------------------------------------------------------+
//| Update all indicators                                             |
//+------------------------------------------------------------------+
bool UpdateIndicators()
{
    if(CopyBuffer(handleEMA_Fast, 0, 0, 50, emaFast) < 50) return false;
    if(CopyBuffer(handleEMA_Slow, 0, 0, 50, emaSlow) < 50) return false;
    if(CopyBuffer(handleEMA_Trend, 0, 0, 50, emaTrend) < 50) return false;
    if(CopyBuffer(handleRSI, 0, 0, 50, rsiBuffer) < 50) return false;
    if(CopyBuffer(handleATR, 0, 0, 50, atrBuffer) < 50) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Update SMC Analysis                                               |
//+------------------------------------------------------------------+
void UpdateSMCAnalysis()
{
    DetectOrderBlocks();
    if(UseFVG) DetectFairValueGaps();
    if(UseBOS) DetectBreakOfStructure();
    if(UseCHoCH) DetectChangeOfCharacter();
    UpdateSwingPoints();
}

//+------------------------------------------------------------------+
//| Detect Order Blocks                                              |
//+------------------------------------------------------------------+
void DetectOrderBlocks()
{
    int barsCount = ArraySize(rates);
    if(barsCount < OrderBlockPeriod + 5) return;
    
    for(int i = 1; i < OrderBlockPeriod && i < barsCount - 2; i++)
    {
        // Bullish OB
        if(rates[i].close < rates[i].open && 
           rates[i-1].close > rates[i-1].open && 
           rates[i-1].close > rates[i].high)
        {
            bullishOB.time = rates[i].time;
            bullishOB.high = rates[i].high;
            bullishOB.low = rates[i].low;
            bullishOB.isBullish = true;
            bullishOB.isValid = true;
            break;
        }
        
        // Bearish OB
        if(rates[i].close > rates[i].open && 
           rates[i-1].close < rates[i-1].open && 
           rates[i-1].close < rates[i].low)
        {
            bearishOB.time = rates[i].time;
            bearishOB.high = rates[i].high;
            bearishOB.low = rates[i].low;
            bearishOB.isBullish = false;
            bearishOB.isValid = true;
            break;
        }
    }
    
    if(bullishOB.isValid && lastTick.bid < bullishOB.low)
        bullishOB.isValid = false;
    
    if(bearishOB.isValid && lastTick.ask > bearishOB.high)
        bearishOB.isValid = false;
}

//+------------------------------------------------------------------+
//| Detect Fair Value Gaps                                           |
//+------------------------------------------------------------------+
void DetectFairValueGaps()
{
    int barsCount = ArraySize(rates);
    if(barsCount < 5) return;
    
    if(barsCount > 2)
    {
        double bullishGap = rates[2].low - rates[0].high;
        if(bullishGap > FVGMinSize * _Point && lastFVG.isFilled)
        {
            lastFVG.time = rates[1].time;
            lastFVG.upper = rates[2].low;
            lastFVG.lower = rates[0].high;
            lastFVG.isBullish = true;
            lastFVG.isFilled = false;
        }
        
        double bearishGap = rates[0].low - rates[2].high;
        if(bearishGap > FVGMinSize * _Point && lastFVG.isFilled)
        {
            lastFVG.time = rates[1].time;
            lastFVG.upper = rates[0].low;
            lastFVG.lower = rates[2].high;
            lastFVG.isBullish = false;
            lastFVG.isFilled = false;
        }
    }
    
    if(!lastFVG.isFilled)
    {
        if(lastFVG.isBullish && lastTick.bid <= lastFVG.lower)
            lastFVG.isFilled = true;
        if(!lastFVG.isBullish && lastTick.ask >= lastFVG.upper)
            lastFVG.isFilled = true;
    }
}

//+------------------------------------------------------------------+
//| Detect Break of Structure                                        |
//+------------------------------------------------------------------+
void DetectBreakOfStructure()
{
    int barsCount = ArraySize(rates);
    if(barsCount < SwingPeriod) return;
    
    int checkBars = MathMin(SwingPeriod, barsCount);
    
    double recentHigh = rates[0].high;
    double recentLow = rates[0].low;
    
    for(int i = 1; i < checkBars; i++)
    {
        if(rates[i].high > recentHigh)
            recentHigh = rates[i].high;
        if(rates[i].low < recentLow)
            recentLow = rates[i].low;
    }
    
    if(lastTick.ask > recentHigh && !breakOfStructureBullish)
    {
        breakOfStructureBullish = true;
        breakOfStructureBearish = false;
        if(SendAlerts) Alert("🔼 Bullish BOS on ", _Symbol);
    }
    
    if(lastTick.bid < recentLow && !breakOfStructureBearish)
    {
        breakOfStructureBearish = true;
        breakOfStructureBullish = false;
        if(SendAlerts) Alert("🔽 Bearish BOS on ", _Symbol);
    }
}

//+------------------------------------------------------------------+
//| Detect Change of Character                                       |
//+------------------------------------------------------------------+
void DetectChangeOfCharacter()
{
    if(ArraySize(emaFast) < 2 || ArraySize(emaSlow) < 2 || ArraySize(emaTrend) < 2)
        return;
    
    if(ArraySize(rates) < 2)
        return;
    
    static bool wasInUptrend = false;
    static bool wasInDowntrend = false;
    
    bool isUptrend = (emaFast[0] > emaSlow[0] && emaSlow[0] > emaTrend[0]);
    bool isDowntrend = (emaFast[0] < emaSlow[0] && emaSlow[0] < emaTrend[0]);
    
    if(wasInDowntrend && !isDowntrend && rates[0].close > rates[1].high)
    {
        changeOfCharacterBullish = true;
        changeOfCharacterBearish = false;
        if(SendAlerts) Alert("🔄 Bullish CHoCH on ", _Symbol);
    }
    
    if(wasInUptrend && !isUptrend && rates[0].close < rates[1].low)
    {
        changeOfCharacterBearish = true;
        changeOfCharacterBullish = false;
        if(SendAlerts) Alert("🔄 Bearish CHoCH on ", _Symbol);
    }
    
    wasInUptrend = isUptrend;
    wasInDowntrend = isDowntrend;
}

//+------------------------------------------------------------------+
//| Update Swing Points                                              |
//+------------------------------------------------------------------+
void UpdateSwingPoints()
{
    int barsCount = ArraySize(rates);
    if(barsCount < SwingPeriod) return;
    
    int checkBars = MathMin(SwingPeriod, barsCount);
    
    int maxIdx = 0;
    double maxPrice = rates[0].high;
    for(int i = 1; i < checkBars; i++)
    {
        if(rates[i].high > maxPrice)
        {
            maxPrice = rates[i].high;
            maxIdx = i;
        }
    }
    
    if(maxIdx >= 0 && maxIdx < barsCount)
    {
        lastSwingHigh.time = rates[maxIdx].time;
        lastSwingHigh.price = rates[maxIdx].high;
        lastSwingHigh.isHigh = true;
    }
    
    int minIdx = 0;
    double minPrice = rates[0].low;
    for(int i = 1; i < checkBars; i++)
    {
        if(rates[i].low < minPrice)
        {
            minPrice = rates[i].low;
            minIdx = i;
        }
    }
    
    if(minIdx >= 0 && minIdx < barsCount)
    {
        lastSwingLow.time = rates[minIdx].time;
        lastSwingLow.price = rates[minIdx].low;
        lastSwingLow.isHigh = false;
    }
}

//+------------------------------------------------------------------+
//| Update ICT Analysis                                               |
//+------------------------------------------------------------------+
void UpdateICTAnalysis()
{
    if(UseKillZones) UpdateKillZones();
    if(UseLiquiditySweep) DetectLiquiditySweeps();
}

//+------------------------------------------------------------------+
//| Update Kill Zones                                                 |
//+------------------------------------------------------------------+
void UpdateKillZones()
{
    MqlDateTime timeStruct;
    TimeToStruct(TimeCurrent(), timeStruct);
    int currentHour = timeStruct.hour;
    
    isAsianKillZone = (currentHour >= AsianSessionStart && currentHour < AsianSessionStart + 3);
    isLondonKillZone = (currentHour >= LondonSessionStart && currentHour < LondonSessionStart + 3);
    isNYKillZone = (currentHour >= NYSessionStart && currentHour < NYSessionStart + 3);
}

//+------------------------------------------------------------------+
//| Detect Liquidity Sweeps                                          |
//+------------------------------------------------------------------+
void DetectLiquiditySweeps()
{
    if(ArraySize(rates) < 2) return;
    
    if(rates[1].low < lastSwingLow.price && rates[0].close > rates[1].high)
    {
        liquiditySweepBullish = true;
        liquiditySweepBearish = false;
        if(SendAlerts) Alert("💧 Bullish Liquidity Sweep on ", _Symbol);
    }
    
    if(rates[1].high > lastSwingHigh.price && rates[0].close < rates[1].low)
    {
        liquiditySweepBearish = true;
        liquiditySweepBullish = false;
        if(SendAlerts) Alert("💧 Bearish Liquidity Sweep on ", _Symbol);
    }
    
    static int sweepBarCount = 0;
    if(liquiditySweepBullish || liquiditySweepBearish)
    {
        sweepBarCount++;
        if(sweepBarCount > 5)
        {
            liquiditySweepBullish = false;
            liquiditySweepBearish = false;
            sweepBarCount = 0;
        }
    }
}

//+------------------------------------------------------------------+
//| Check for BOTH BUY and SELL entries                              |
//+------------------------------------------------------------------+
void CheckForBothEntries()
{
    if(ArraySize(atrBuffer) < 1 || ArraySize(emaFast) < 1) return;
    
    int currentBuyPos = CountPositionsByType(POSITION_TYPE_BUY);
    int currentSellPos = CountPositionsByType(POSITION_TYPE_SELL);
    
    bool canBuy = (currentBuyPos < MaxBuyPositions);
    bool canSell = (currentSellPos < MaxSellPositions);
    
    // Check BUY signal
    if(canBuy)
    {
        bool buySignal = GetBullishBias();
        
        if(buySignal)
        {
            int barsSinceLastBuy = CalculateBarsSinceLastTrade(lastBuyTime);
            
            if(barsSinceLastBuy >= MinBarsBetweenEntry)
            {
                bool canOpenBuyGrid = true;
                if(UseGridTrading && lastBuyPrice > 0)
                {
                    double distanceFromLastBuy = MathAbs(lastTick.ask - lastBuyPrice) / _Point;
                    if(distanceFromLastBuy < GridStep || buyGridLevel >= MaxGridLevels)
                        canOpenBuyGrid = false;
                }
                
                if(canOpenBuyGrid)
                {
                    double entryPrice = lastTick.ask;
                    double sl = CalculateStopLoss(true, entryPrice);
                    double tp = CalculateTakeProfit(true, entryPrice, sl);
                    
                    double risk = MathAbs(entryPrice - sl);
                    double reward = MathAbs(tp - entryPrice);
                    
                    if(risk > 0 && reward / risk >= MinRiskReward)
                    {
                        double lotSize = CalculateLotSize(risk);
                        if(lotSize > 0)
                        {
                            ExecuteBuy(entryPrice, sl, tp, lotSize);
                        }
                    }
                }
            }
        }
    }
    
    // Check SELL signal
    if(canSell)
    {
        bool sellSignal = GetBearishBias();
        
        bool canOpenSell = true;
        if(!canHedge && currentBuyPos > 0)
            canOpenSell = false;
        
        if(sellSignal && canOpenSell)
        {
            int barsSinceLastSell = CalculateBarsSinceLastTrade(lastSellTime);
            
            if(barsSinceLastSell >= MinBarsBetweenEntry)
            {
                bool canOpenSellGrid = true;
                if(UseGridTrading && lastSellPrice > 0)
                {
                    double distanceFromLastSell = MathAbs(lastTick.bid - lastSellPrice) / _Point;
                    if(distanceFromLastSell < GridStep || sellGridLevel >= MaxGridLevels)
                        canOpenSellGrid = false;
                }
                
                if(canOpenSellGrid)
                {
                    double entryPrice = lastTick.bid;
                    double sl = CalculateStopLoss(false, entryPrice);
                    double tp = CalculateTakeProfit(false, entryPrice, sl);
                    
                    double risk = MathAbs(sl - entryPrice);
                    double reward = MathAbs(entryPrice - tp);
                    
                    if(risk > 0 && reward / risk >= MinRiskReward)
                    {
                        double lotSize = CalculateLotSize(risk);
                        if(lotSize > 0)
                        {
                            ExecuteSell(entryPrice, sl, tp, lotSize);
                        }
                    }
                }
            }
        }
    }
    
    if(AutoReverse)
    {
        CheckAutoReverse();
    }
}

//+------------------------------------------------------------------+
//| Calculate Bars Since Last Trade                                  |
//+------------------------------------------------------------------+
int CalculateBarsSinceLastTrade(datetime lastTradeTime)
{
    if(lastTradeTime == 0)
        return MinBarsBetweenEntry;
    
    datetime barTimes[];
    ArraySetAsSeries(barTimes, true);
    int copied = CopyTime(_Symbol, PERIOD_M1, 0, 100, barTimes);
    
    if(copied > 0)
    {
        for(int i = 0; i < copied; i++)
        {
            if(barTimes[i] <= lastTradeTime)
                return i;
        }
    }
    
    return 0;
}

//+------------------------------------------------------------------+
//| Check Auto Reverse                                                |
//+------------------------------------------------------------------+
void CheckAutoReverse()
{
    int buyConfirmations = GetBullishConfirmations();
    int sellConfirmations = GetBearishConfirmations();
    
    if(GetBearishBias() && sellConfirmations >= 7 && buyConfirmations <= 2)
    {
        int buyPos = CountPositionsByType(POSITION_TYPE_BUY);
        if(buyPos > 0)
        {
            CloseAllPositionsByType(POSITION_TYPE_BUY);
            Print("🔄 AUTO REVERSE: Closed ", buyPos, " BUY positions");
        }
    }
    
    if(GetBullishBias() && buyConfirmations >= 7 && sellConfirmations <= 2)
    {
        int sellPos = CountPositionsByType(POSITION_TYPE_SELL);
        if(sellPos > 0)
        {
            CloseAllPositionsByType(POSITION_TYPE_SELL);
            Print("🔄 AUTO REVERSE: Closed ", sellPos, " SELL positions");
        }
    }
}

//+------------------------------------------------------------------+
//| Get Bullish Confirmations                                         |
//+------------------------------------------------------------------+
int GetBullishConfirmations()
{
    if(ArraySize(emaFast) < 1 || ArraySize(emaSlow) < 1 || ArraySize(emaTrend) < 1)
        return 0;
    if(ArraySize(rsiBuffer) < 1 || ArraySize(rates) < 2)
        return 0;
    
    int confirmations = 0;
    
    if(emaFast[0] > emaSlow[0] && emaSlow[0] > emaTrend[0]) confirmations++;
    if(rsiBuffer[0] > RSI_Oversold && rsiBuffer[0] < 60) confirmations++;
    if(lastTick.bid > emaFast[0]) confirmations++;
    
    if(UseSMC)
    {
        if(bullishOB.isValid && lastTick.bid >= bullishOB.low && lastTick.bid <= bullishOB.high) confirmations++;
        if(!lastFVG.isFilled && lastFVG.isBullish && lastTick.bid >= lastFVG.lower && lastTick.bid <= lastFVG.upper) confirmations++;
        if(breakOfStructureBullish) confirmations++;
        if(changeOfCharacterBullish) confirmations++;
    }
    
    if(UseICT)
    {
        if(!UseKillZones || isLondonKillZone || isNYKillZone) confirmations++;
        if(liquiditySweepBullish) confirmations += 2;
    }
    
    if(rates[0].close > rates[0].open && rates[0].close > rates[1].high) confirmations++;
    
    return confirmations;
}

//+------------------------------------------------------------------+
//| Get Bearish Confirmations                                         |
//+------------------------------------------------------------------+
int GetBearishConfirmations()
{
    if(ArraySize(emaFast) < 1 || ArraySize(emaSlow) < 1 || ArraySize(emaTrend) < 1)
        return 0;
    if(ArraySize(rsiBuffer) < 1 || ArraySize(rates) < 2)
        return 0;
    
    int confirmations = 0;
    
    if(emaFast[0] < emaSlow[0] && emaSlow[0] < emaTrend[0]) confirmations++;
    if(rsiBuffer[0] < RSI_Overbought && rsiBuffer[0] > 40) confirmations++;
    if(lastTick.ask < emaFast[0]) confirmations++;
    
    if(UseSMC)
    {
        if(bearishOB.isValid && lastTick.ask <= bearishOB.high && lastTick.ask >= bearishOB.low) confirmations++;
        if(!lastFVG.isFilled && !lastFVG.isBullish && lastTick.ask <= lastFVG.upper && lastTick.ask >= lastFVG.lower) confirmations++;
        if(breakOfStructureBearish) confirmations++;
        if(changeOfCharacterBearish) confirmations++;
    }
    
    if(UseICT)
    {
        if(!UseKillZones || isLondonKillZone || isNYKillZone) confirmations++;
        if(liquiditySweepBearish) confirmations += 2;
    }
    
    if(rates[0].close < rates[0].open && rates[0].close < rates[1].low) confirmations++;
    
    return confirmations;
}

//+------------------------------------------------------------------+
//| Get Bullish Bias                                                  |
//+------------------------------------------------------------------+
bool GetBullishBias()
{
    int confirmations = GetBullishConfirmations();
    return (confirmations >= 3);
}

//+------------------------------------------------------------------+
//| Get Bearish Bias                                                  |
//+------------------------------------------------------------------+
bool GetBearishBias()
{
    int confirmations = GetBearishConfirmations();
    return (confirmations >= 3);
}

//+------------------------------------------------------------------+
//| Calculate Stop Loss                                               |
//+------------------------------------------------------------------+
double CalculateStopLoss(bool isBuy, double entryPrice)
{
    if(ArraySize(atrBuffer) < 1) return 0;
    
    double sl = 0;
    double atr = atrBuffer[0];
    double slDistance = atr * ATR_Multiplier;
    
    if(isBuy)
    {
        sl = entryPrice - slDistance;
        
        if(UseSMC && bullishOB.isValid)
        {
            double obSL = bullishOB.low - 5 * _Point;
            if(obSL > sl) sl = obSL;
        }
        
        double minSL = entryPrice - 20 * _Point;
        if(sl > minSL) sl = minSL;
    }
    else
    {
        sl = entryPrice + slDistance;
        
        if(UseSMC && bearishOB.isValid)
        {
            double obSL = bearishOB.high + 5 * _Point;
            if(obSL < sl) sl = obSL;
        }
        
        double minSL = entryPrice + 20 * _Point;
        if(sl < minSL) sl = minSL;
    }
    
    return NormalizeDouble(sl, _Digits);
}

//+------------------------------------------------------------------+
//| Calculate Take Profit                                             |
//+------------------------------------------------------------------+
double CalculateTakeProfit(bool isBuy, double entryPrice, double sl)
{
    double risk = MathAbs(entryPrice - sl);
    double reward = risk * MinRiskReward;
    
    double tp = isBuy ? entryPrice + reward : entryPrice - reward;
    
    return NormalizeDouble(tp, _Digits);
}

//+------------------------------------------------------------------+
//| Calculate Lot Size                                                |
//+------------------------------------------------------------------+
double CalculateLotSize(double slDistance)
{
    if(FixedLotSize > 0)
        return FixedLotSize;
    
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = balance * RiskPercent / 100.0;
    
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    
    if(tickValue == 0 || tickSize == 0) return minLot;
    
    double slPoints = slDistance / _Point;
    if(slPoints == 0) return minLot;
    
    double lotSize = (riskAmount / slPoints) / tickValue * tickSize;
    
    lotSize = MathFloor(lotSize / lotStep) * lotStep;
    
    if(lotSize < minLot) lotSize = minLot;
    if(lotSize > maxLot) lotSize = maxLot;
    
    return NormalizeDouble(lotSize, 2);
}

//+------------------------------------------------------------------+
//| Execute Buy Order                                                 |
//+------------------------------------------------------------------+
void ExecuteBuy(double price, double sl, double tp, double lotSize)
{
    if(trade.Buy(lotSize, _Symbol, price, sl, tp, "SMC-ICT Buy"))
    {
        totalTradesToday++;
        totalBuyToday++;
        lastBuyTime = TimeCurrent();
        lastBuyPrice = price;
        buyGridLevel++;
        
        Print("╔════════════════════════════════════════╗");
        Print("║ ✅ BUY ORDER #", totalBuyToday, " EXECUTED         ║");
        Print("╠════════════════════════════════════════╣");
        Print("║ Ticket: ", trade.ResultOrder());
        Print("║ Price: ", price, " | SL: ", sl, " | TP: ", tp);
        Print("║ Lot: ", lotSize, " | Grid: ", buyGridLevel);
        Print("╚════════════════════════════════════════╝");
        
        if(SendAlerts)
            Alert("🟢 BUY ", _Symbol, " #", totalBuyToday, " @ ", price);
    }
    else
    {
        Print("❌ BUY FAILED: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
    }
}

//+------------------------------------------------------------------+
//| Execute Sell Order                                                |
//+------------------------------------------------------------------+
void ExecuteSell(double price, double sl, double tp, double lotSize)
{
    if(trade.Sell(lotSize, _Symbol, price, sl, tp, "SMC-ICT Sell"))
    {
        totalTradesToday++;
        totalSellToday++;
        lastSellTime = TimeCurrent();
        lastSellPrice = price;
        sellGridLevel++;
        
        Print("╔════════════════════════════════════════╗");
        Print("║ ✅ SELL ORDER #", totalSellToday, " EXECUTED        ║");
        Print("╠════════════════════════════════════════╣");
        Print("║ Ticket: ", trade.ResultOrder());
        Print("║ Price: ", price, " | SL: ", sl, " | TP: ", tp);
        Print("║ Lot: ", lotSize, " | Grid: ", sellGridLevel);
        Print("╚════════════════════════════════════════╝");
        
        if(SendAlerts)
            Alert("🔴 SELL ", _Symbol, " #", totalSellToday, " @ ", price);
    }
    else
    {
        Print("❌ SELL FAILED: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
    }
}

//+------------------------------------------------------------------+
//| Manage Positions                                                  |
//+------------------------------------------------------------------+
void ManagePositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket <= 0) continue;
        
        if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
           PositionGetInteger(POSITION_MAGIC) == MagicNumber)
        {
            if(UseBreakEven) MoveToBreakEven(ticket);
            if(UseTrailingStop) ApplyTrailingStop(ticket);
            if(UsePartialClose) CheckPartialClose(ticket);
        }
    }
}

//+------------------------------------------------------------------+
//| Move to Breakeven                                                 |
//+------------------------------------------------------------------+
void MoveToBreakEven(ulong ticket)
{
    if(!PositionSelectByTicket(ticket)) return;
    
    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double sl = PositionGetDouble(POSITION_SL);
    double tp = PositionGetDouble(POSITION_TP);
    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    if(type == POSITION_TYPE_BUY)
    {
        double currentProfit = lastTick.bid - openPrice;
        if(currentProfit >= BreakEvenTrigger * _Point && sl < openPrice)
        {
            double newSL = openPrice + BreakEvenOffset * _Point;
            if(trade.PositionModify(ticket, newSL, tp))
            {
                Print("🎯 BE (BUY) #", ticket);
            }
        }
    }
    else if(type == POSITION_TYPE_SELL)
    {
        double currentProfit = openPrice - lastTick.ask;
        if(currentProfit >= BreakEvenTrigger * _Point && (sl > openPrice || sl == 0))
        {
            double newSL = openPrice - BreakEvenOffset * _Point;
            if(trade.PositionModify(ticket, newSL, tp))
            {
                Print("🎯 BE (SELL) #", ticket);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Apply Trailing Stop                                               |
//+------------------------------------------------------------------+
void ApplyTrailingStop(ulong ticket)
{
    if(!PositionSelectByTicket(ticket)) return;
    if(ArraySize(atrBuffer) < 1) return;
    
    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double sl = PositionGetDouble(POSITION_SL);
    double tp = PositionGetDouble(POSITION_TP);
    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    double atr = atrBuffer[0];
    double trailDistance = atr * 0.5;
    
    if(type == POSITION_TYPE_BUY)
    {
        double newSL = lastTick.bid - trailDistance;
        if(newSL > sl && newSL > openPrice + BreakEvenOffset * _Point)
        {
            if(trade.PositionModify(ticket, NormalizeDouble(newSL, _Digits), tp))
            {
                Print("📈 Trail (BUY) #", ticket);
            }
        }
    }
    else if(type == POSITION_TYPE_SELL)
    {
        double newSL = lastTick.ask + trailDistance;
        if((newSL < sl || sl == 0) && newSL < openPrice - BreakEvenOffset * _Point)
        {
            if(trade.PositionModify(ticket, NormalizeDouble(newSL, _Digits), tp))
            {
                Print("📉 Trail (SELL) #", ticket);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check Partial Close                                               |
//+------------------------------------------------------------------+
void CheckPartialClose(ulong ticket)
{
    if(!PositionSelectByTicket(ticket)) return;
    
    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double tp = PositionGetDouble(POSITION_TP);
    double volume = PositionGetDouble(POSITION_VOLUME);
    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    string comment = PositionGetString(POSITION_COMMENT);
    if(StringFind(comment, "Partial") >= 0) return;
    
    double targetDistance = MathAbs(tp - openPrice);
    double partialTarget = targetDistance * (PartialCloseAt / 100.0);
    
    if(type == POSITION_TYPE_BUY)
    {
        double currentProfit = lastTick.bid - openPrice;
        if(currentProfit >= partialTarget)
        {
            double closeVolume = NormalizeDouble(volume * (PartialClosePercent / 100.0), 2);
            if(closeVolume >= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
            {
                if(trade.PositionClosePartial(ticket, closeVolume))
                {
                    Print("💰 Partial (BUY) #", ticket);
                }
            }
        }
    }
    else if(type == POSITION_TYPE_SELL)
    {
        double currentProfit = openPrice - lastTick.ask;
        if(currentProfit >= partialTarget)
        {
            double closeVolume = NormalizeDouble(volume * (PartialClosePercent / 100.0), 2);
            if(closeVolume >= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
            {
                if(trade.PositionClosePartial(ticket, closeVolume))
                {
                    Print("💰 Partial (SELL) #", ticket);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Count Positions by Type                                          |
//+------------------------------------------------------------------+
int CountPositionsByType(ENUM_POSITION_TYPE type)
{
    int count = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0)
        {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
               PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
               PositionGetInteger(POSITION_TYPE) == type)
            {
                count++;
            }
        }
    }
    
    if(count == 0)
    {
        if(type == POSITION_TYPE_BUY)
        {
            buyGridLevel = 0;
            lastBuyPrice = 0;
        }
        else
        {
            sellGridLevel = 0;
            lastSellPrice = 0;
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Close All Positions by Type                                      |
//+------------------------------------------------------------------+
void CloseAllPositionsByType(ENUM_POSITION_TYPE type)
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0)
        {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
               PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
               PositionGetInteger(POSITION_TYPE) == type)
            {
                trade.PositionClose(ticket);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Update Daily Stats                                                |
//+------------------------------------------------------------------+
void UpdateDailyStats()
{
    datetime today = GetCurrentDay();
    if(today != currentDay)
    {
        currentDay = today;
        dailyProfit = 0;
        dailyLoss = 0;
        totalTradesToday = 0;
        totalBuyToday = 0;
        totalSellToday = 0;
        accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        
        Print("📅 New Day | Balance: $", accountBalance);
    }
}

//+------------------------------------------------------------------+
//| Check Daily Limits                                                |
//+------------------------------------------------------------------+
bool CheckDailyLimits()
{
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double todayPL = currentBalance - accountBalance;
    
    if(accountBalance == 0) return false;
    
    double todayPLPercent = (todayPL / accountBalance) * 100.0;
    
    if(todayPLPercent <= -MaxDailyLoss)
    {
        Print("⛔ Loss limit: ", NormalizeDouble(todayPLPercent, 2), "%");
        return true;
    }
    
    if(todayPLPercent >= MaxDailyProfit)
    {
        Print("🎯 Profit target: ", NormalizeDouble(todayPLPercent, 2), "%");
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check Spread                                                      |
//+------------------------------------------------------------------+
bool CheckSpread()
{
    double spread = lastTick.ask - lastTick.bid;
    int spreadPoints = (int)(spread / _Point);
    return (spreadPoints <= MaxSpread);
}

//+------------------------------------------------------------------+
//| Check Time Filter                                                 |
//+------------------------------------------------------------------+
bool IsTimeToTrade()
{
    MqlDateTime timeStruct;
    TimeToStruct(TimeCurrent(), timeStruct);
    int currentHour = timeStruct.hour;
    
    if(StartHour <= EndHour)
        return (currentHour >= StartHour && currentHour < EndHour);
    else
        return (currentHour >= StartHour || currentHour < EndHour);
}

//+------------------------------------------------------------------+
//| Get Current Day                                                   |
//+------------------------------------------------------------------+
datetime GetCurrentDay()
{
    MqlDateTime timeStruct;
    TimeToStruct(TimeCurrent(), timeStruct);
    timeStruct.hour = 0;
    timeStruct.min = 0;
    timeStruct.sec = 0;
    return StructToTime(timeStruct);
}

//+------------------------------------------------------------------+
//| Display Info Panel                                                |
//+------------------------------------------------------------------+
void DisplayInfo()
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double todayPL = balance - accountBalance;
    double todayPLPercent = accountBalance > 0 ? (todayPL / accountBalance) * 100 : 0;
    
    int buyPos = CountPositionsByType(POSITION_TYPE_BUY);
    int sellPos = CountPositionsByType(POSITION_TYPE_SELL);
    int spreadPoints = (int)((lastTick.ask - lastTick.bid) / _Point);
    
    string info = "";
    info += "╔═════════════════════════════════════╗\n";
    info += "║  SMC + ICT REVERSE EA v4.03        ║\n";
    info += "╠═════════════════════════════════════╣\n";
    info += StringFormat("║ Balance: $%.2f\n", balance);
    info += StringFormat("║ Equity: $%.2f\n", equity);
    info += StringFormat("║ Today: $%.2f (%.2f%%)\n", todayPL, todayPLPercent);
    info += StringFormat("║ Trades: %d (B:%d|S:%d)\n", totalTradesToday, totalBuyToday, totalSellToday);
    info += "╠═════════════════════════════════════╣\n";
    info += StringFormat("║ 🟢 BUY: %d/%d\n", buyPos, MaxBuyPositions);
    info += StringFormat("║ 🔴 SELL: %d/%d\n", sellPos, MaxSellPositions);
    info += StringFormat("║ Spread: %d | Hedge: %s\n", spreadPoints, canHedge?"ON":"OFF");
    info += "╠═════════════════════════════════════╣\n";
    info += "║ SMC:\n";
    info += StringFormat("║ • OB: %s|%s\n", bullishOB.isValid?"B✓":"B✗", bearishOB.isValid?"S✓":"S✗");
    info += StringFormat("║ • FVG: %s\n", !lastFVG.isFilled?(lastFVG.isBullish?"↑":"↓"):"None");
    info += StringFormat("║ • BOS: %s\n", breakOfStructureBullish?"↑":(breakOfStructureBearish?"↓":"-"));
    info += "╠═════════════════════════════════════╣\n";
    info += "║ ICT:\n";
    info += StringFormat("║ • KZ: %s\n", isLondonKillZone?"LDN":(isNYKillZone?"NY":(isAsianKillZone?"ASN":"None")));
    info += StringFormat("║ • Liq: %s\n", liquiditySweepBullish?"↑":(liquiditySweepBearish?"↓":"None"));
    info += "╚═════════════════════════════════════╝";
    
    Comment(info);
}
//+------------------------------------------------------------------+
