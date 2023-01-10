//+------------------------------------------------------------------+
//|                                                           Engine |
//|                                    Copyright 2022, Yohan Naftali |
//|                                              https://yohanli.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Yohan Naftali"
#property link      "https://yohanli.com"
#property version   "220.914"

#include "Message.mqh"

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\DealInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

Message message;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Engine {
  private:
    CTrade           trade;
    CDealInfo        deal;
    COrderInfo       order;
    CPositionInfo    position;
    CAccountInfo     account;

    ulong            eaMagicNumber;

    string           beginOrderString;
    string           endOrderString;

    double           realSlPriceBuy;
    double           realSlPriceSell;
    double           hitRealSlPrice;

    double           pipToPrice;
    double           riskPercentage;
    double           riskReward;

    double           trailingStopPrice; // in price ex 0.00010
    double           stopLossPrice; // in price ex 0.00010
    double           stopLossPoint; // in point ex 10 point
    double           totalDelta;

    bool             hideStopLoss;
    double           stopLossSafetyPrice; // in price ex 0.00010

    int              directionStrategy;
    string           srIndicator;
    bool             useFinishedSR;
    double           offsetPrice; // in price ex 0.00010
    double           offsetPip;   // in pip   ex 1 pip

    double           safetySpreadMultiplier;
    double           minVolume;
    double           maxVolume;
    double           calculateVolume();
    double           stepVolume;

    bool             filterEma;
    int              emaHandle;
    double           calculateEma();

    bool             filterAdx;
    double           filterAdxMin;
    int              adxHandle;
    double           calculateAdx();

    bool             filterRsi;
    double           filterRsiLower;
    double           filterRsiUpper;
    int              rsiHandle;
    double           calculateRsi();

    bool             filterAtr;
    int              atrHandle;
    int              emaAtrHandle;
    double           calculateAtr();
    double           calculateAtrEma();

    int              positionLast;
    int              historyLast;
    int              dealLast;
    int              orderLast;

    int              stopsLevel;

    int              digitVolume;  // Digit volume
    int              pipToPoint; // Adjusted pip to point
    int              maxOpenOrder;
    int              maxTimeDelay;
    int              timeDelay();
    int              zigzagHandle;
    int              fractalsHandle;
    int              noBarSkip;
    int              totalPosition();
    int              totalOrder();
    int              totalHistory();
    int              getDigit(double num);

    bool             isNewBar();
    bool             isTradingTime();

    double           resistance;
    double           support;
    double           takeProfitMargin();

    void             updateTrailingStop();
    void             calculateSR();
    void             calculateZigzag();
    void             calculateFractals();
    void             onNewBar();
    bool             openLongBreakout();
    bool             openShortBreakout();
    bool             openLongReversal();
    bool             openShortReversal();
    void             createOrder();
    bool             clearAllOrders();

  public:
                     Engine();
                    ~Engine();
    int              onInit(
        string BeginOrder,
        string EndOrder,
        double RiskPercentage,
        double StopLossPip,
        double TrailingStopPip,
        bool HideStopLoss,
        double StopLossSafetyPip,
        double RiskReward,
        double SafteySpreadMultiplier,
        int DirectionStrategy,
        string SRIndicator,
        bool UseFinishedSR,
        double OffsetPip,
        int NoBarSkip,
        bool FilterEma,
        int FilterEmaPeriod,
        bool FilterAdx,
        int FilterAdxPeriod,
        double FilterAdxMin,
        bool FilterRsi,
        int FilterRsiPeriod,
        double FilterRsiUpper,
        double FilterRsiLower,
        bool FilterAtr,
        int FilterAtrPeriod,
        int FilterAtrEmaPeriod,
        string Brand,
        string Signature,
        ulong MagicNumber,
        string TelegramToken,
        long TelegramChannelTrader,
        string TelegramChannelInvestor
    );
    void             onDeinit(const int reason);
    void             onTick();
    void             onTrade();
    void             onTradeTransaction(
        const MqlTradeTransaction& trans,
        const MqlTradeRequest& request,
        const MqlTradeResult& result);
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Engine::Engine() {
    maxTimeDelay = 300;
    maxOpenOrder = 2;
    positionLast = 0;
    orderLast = 0;
    dealLast = 0;
    historyLast = 0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Engine::onInit(
    string BeginOrder,
    string EndOrder,
    double RiskPercentage,
    double StopLossPip,
    double TrailingStopPip,
    bool HideStopLoss,
    double StopLossSafetyPip,
    double RiskReward,
    double SafetySpreadMultiplier,
    int DirectionStrategy,
    string SRIndicator,
    bool UseFinishedSR,
    double OffsetPip,
    int NoBarSkip,
    bool FilterEma,
    int FilterEmaPeriod,
    bool FilterAdx,
    int FilterAdxPeriod,
    double FilterAdxMin,
    bool FilterRsi,
    int FilterRsiPeriod,
    double FilterRsiUpper,
    double FilterRsiLower,
    bool FilterAtr,
    int FilterAtrPeriod,
    int FilterAtrEmaPeriod,
    string Brand,
    string Signature,
    ulong MagicNumber,
    string TelegramToken,
    long TelegramChannelTrader,
    string TelegramChannelInvestor
) {

    message.Init(
        Brand,
        Signature,
        MagicNumber,
        TelegramToken,
        TelegramChannelTrader,
        TelegramChannelInvestor,
        _Symbol,
        EnumToString(_Period)
    );

    eaMagicNumber = MagicNumber;

    safetySpreadMultiplier = SafetySpreadMultiplier;

    noBarSkip = NoBarSkip;
    trade.SetExpertMagicNumber(eaMagicNumber);
    stepVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    digitVolume = getDigit(stepVolume);
    minVolume = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
    minVolume = NormalizeDouble(minVolume, digitVolume);
    maxVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    maxVolume = NormalizeDouble(maxVolume, digitVolume);
    pipToPoint = (_Digits == 3 || _Digits == 5) ? 10 : 1;
    pipToPrice = _Point * pipToPoint;

    beginOrderString = BeginOrder;
    endOrderString = EndOrder;
    riskPercentage = RiskPercentage;
    riskReward = RiskReward;
    stopLossPoint = StopLossPip * pipToPoint;
    stopLossPrice = NormalizeDouble(StopLossPip * pipToPrice, _Digits);
    stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);

    double trailingStopPoint = TrailingStopPip*pipToPoint;
    trailingStopPrice = NormalizeDouble(TrailingStopPip * pipToPrice, _Digits);

    hideStopLoss = HideStopLoss;
    double stopLossSafetyPoint = StopLossSafetyPip * pipToPoint;
    stopLossSafetyPrice = NormalizeDouble(StopLossSafetyPip * pipToPrice, _Digits);

    directionStrategy = DirectionStrategy;
    srIndicator = SRIndicator;
    useFinishedSR = UseFinishedSR;
    offsetPip = OffsetPip;
    offsetPrice = NormalizeDouble(offsetPip * pipToPrice, _Digits);

    resistance = 0;
    support = 0;

    int inpDepth = 12;
    int inpDeviation = 5;
    int inpBackstep = 3;
    if(srIndicator == "ZigZag") {
        zigzagHandle = iCustom(_Symbol, _Period, "Examples\\ZigZag", inpDepth, inpDeviation, inpBackstep);
        if(zigzagHandle == INVALID_HANDLE) {
            message.InvalidHandle("ZigZag");
            return (INIT_FAILED);
        }
    } else if(srIndicator == "Fractals") {
        fractalsHandle = iFractals(_Symbol, _Period);
        if (fractalsHandle == INVALID_HANDLE) {
            message.InvalidHandle("Fractals");
            return (INIT_FAILED);
        }
    }
    calculateSR();

    filterEma = FilterEma;
    if(filterEma) {
        emaHandle = iMA(_Symbol, _Period, FilterEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
        if (emaHandle == INVALID_HANDLE) {
            message.InvalidHandle("MA");
            return (INIT_FAILED);
        }
    }

    filterAdx = FilterAdx;
    filterAdxMin = FilterAdxMin;
    if(filterAdx) {
        adxHandle = iADX(_Symbol, _Period, FilterAdxPeriod);
        if (adxHandle == INVALID_HANDLE) {
            message.InvalidHandle("ADX");
            return (INIT_FAILED);
        }
    }

    filterRsi = FilterRsi;
    filterRsiLower = FilterRsiLower;
    filterRsiUpper = FilterRsiUpper;
    if(filterRsi) {
        rsiHandle = iRSI(_Symbol, _Period, FilterRsiPeriod, PRICE_CLOSE);
        if (rsiHandle == INVALID_HANDLE) {
            message.InvalidHandle("RSI");
            return (INIT_FAILED);
        }
    }

    filterAtr = FilterAtr;
    if(filterAtr) {
        atrHandle = iATR(_Symbol, _Period, FilterAtrPeriod);
        if (atrHandle == INVALID_HANDLE) {
            message.InvalidHandle("ATR");
            return (INIT_FAILED);
        } else {
            emaAtrHandle = iMA(_Symbol, _Period, FilterAtrEmaPeriod, 0, MODE_EMA, atrHandle);
            if (emaAtrHandle == INVALID_HANDLE) {
                message.InvalidHandle("MA ATR");
                return (INIT_FAILED);
            }
        }
    }

    totalDelta = 0;

    message.InitParameter(
        BeginOrder,
        EndOrder,
        DoubleToString(riskPercentage, 2),
        DoubleToString(StopLossPip, 2),
        DoubleToString(stopLossPoint, 2),
        DoubleToString(TrailingStopPip, 2),
        DoubleToString(trailingStopPoint, 2),
        hideStopLoss ? "True" : " False",
        DoubleToString(StopLossSafetyPip, 2),
        DoubleToString(stopLossSafetyPoint, 2),
        DoubleToString(riskReward, 0),
        directionStrategy == 0 ? "Breakout" : "Reversal",
        srIndicator,
        DoubleToString(offsetPip, 2),
        IntegerToString(noBarSkip),
        TimeToString(TimeCurrent()),
        TimeToString(TimeTradeServer()),
        TimeToString(TimeGMT()),
        TimeToString(TimeLocal()),
        IntegerToString(totalOrder()),
        IntegerToString(totalPosition())
    );

    if(timeDelay() > maxTimeDelay) {
        message.ErrorServerUnreachable();
    }
    positionLast = totalPosition();
    orderLast = totalOrder();
    dealLast = 0;
    historyLast = totalHistory();
    return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Engine::~Engine() {
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Engine::onDeinit(const int reason) {
    if(zigzagHandle != INVALID_HANDLE)
        IndicatorRelease(zigzagHandle);
    if(fractalsHandle != INVALID_HANDLE)
        IndicatorRelease(zigzagHandle);
    if(emaHandle != INVALID_HANDLE)
        IndicatorRelease(emaHandle);
    if(adxHandle != INVALID_HANDLE)
        IndicatorRelease(adxHandle);
    if(rsiHandle != INVALID_HANDLE)
        IndicatorRelease(rsiHandle);
    if(atrHandle != INVALID_HANDLE)
        IndicatorRelease(atrHandle);
    Comment("");
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Engine::onTick() {
// fix still update trailling stop even time to server fail
    updateTrailingStop();
    if(timeDelay() <= maxTimeDelay) {
        if(isNewBar()) {
            onNewBar();
        }
    } else {
        clearAllOrders();
        if (isTradingTime()) {
            message.ErrorServerUnreachable();
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Engine::onTradeTransaction(const MqlTradeTransaction& trans,
                                const MqlTradeRequest& request,
                                const MqlTradeResult& result) {
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Engine::onTrade() {
    int pos = totalPosition();
    if(positionLast != pos) {
        Print("✏️ Position Changed from " + IntegerToString(positionLast) + " to " +  IntegerToString(pos));
        positionLast = pos;
    }

    int ord = totalOrder();
    if(orderLast != ord) {
        Print("✏️ Order Changed from " + IntegerToString(orderLast) + " to " +  IntegerToString(ord));
        orderLast = ord;
    }
    if(pos == 0) {
        int his = totalHistory();
        if(historyLast != his) {
            totalDelta = 0;
            Print("✏️ History Changed from " + IntegerToString(historyLast) + " to " +  IntegerToString(his));
            clearAllOrders();
            historyLast = his;
            if (HistorySelect(0, TimeCurrent())) {
                int totalHistory = HistoryDealsTotal();
                for(int i = totalHistory ; i >= 0; i--) {
                    ulong ticket = 0;
                    if((ticket = HistoryDealGetTicket(i)) >0 ) {
                        string symbol=HistoryDealGetString(ticket, DEAL_SYMBOL);
                        ulong magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
                        if(symbol == _Symbol && magic == eaMagicNumber) {
                            long type = HistoryDealGetInteger(ticket, DEAL_TYPE);
                            long reason = HistoryDealGetInteger(ticket, DEAL_REASON);
                            if( (type == 0 || type == 1) && (reason == 3 || reason == 4 || reason == 5) ) {
                                string direction = type == 0 ? "Buy" : "Sell";
                                string volume = DoubleToString(HistoryDealGetDouble(ticket, DEAL_VOLUME), digitVolume) + " lot";
                                string price = DoubleToString(HistoryDealGetDouble(ticket, DEAL_PRICE), _Digits);
                                string tp = DoubleToString(HistoryDealGetDouble(ticket, DEAL_TP), _Digits);
                                string sl = DoubleToString(HistoryDealGetDouble(ticket, DEAL_SL), _Digits);
                                string realSl = DoubleToString(hitRealSlPrice, _Digits);
                                double profitDouble = HistoryDealGetDouble(ticket, DEAL_PROFIT);
                                string profit = DoubleToString(profitDouble, 2);
                                string commision = DoubleToString(HistoryDealGetDouble(ticket, DEAL_COMMISSION), 2);
                                string fee = DoubleToString(HistoryDealGetDouble(ticket, DEAL_FEE), 2);
                                string swap = DoubleToString(HistoryDealGetDouble(ticket, DEAL_SWAP), 2);
                                string ask = DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
                                string bid = DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
                                string spreadPoint = IntegerToString(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD));
                                message.DealCompleted(
                                    direction,
                                    volume,
                                    price,
                                    tp,
                                    sl,
                                    hideStopLoss && reason == 3 ? realSl : "",
                                    profitDouble,
                                    profit,
                                    commision,
                                    fee,
                                    swap,
                                    ask,
                                    bid,
                                    spreadPoint
                                );
                            }
                            break;
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Engine::onNewBar() {
    if (isTradingTime()) {
        createOrder();
    } else {
        clearAllOrders();
    }
    message.ShowPosition(
        IntegerToString(totalOrder()),
        IntegerToString(totalPosition())
    );
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Engine::createOrder() {
    calculateSR();
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    long spreadPoint = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    double spreadPrice = ask - bid;
    message.CreateOrderEvent(
        IntegerToString(totalOrder()),
        DoubleToString(resistance, _Digits),
        DoubleToString(support, _Digits),
        DoubleToString(ask, _Digits),
        DoubleToString(bid, _Digits),
        IntegerToString(spreadPoint)
    );
    if (resistance > 0 && support > 0 && totalPosition() == 0) {
        if ((resistance + offsetPrice > ask) || (support - offsetPrice < bid)) {
            if (clearAllOrders()) {
                // EMA
                double ema = 0;
                if(filterEma) {
                    ema = calculateEma();
                }
                // ADX
                double adx = 100;
                bool validAdx = true;
                if(filterAdx) {
                    adx = calculateAdx();
                    if(adx <= filterAdxMin) {
                        validAdx = false;
                        string msgAdxFilter = "⛔️ No opened trade: Market sideway - ADX " + DoubleToString(adx, 2)  + " lower than " +  DoubleToString(filterAdxMin, 2);
                        Print(msgAdxFilter);
                    } else {
                        string msgAdx = "⚽ Market trending - ADX: " + DoubleToString(adx, 2) + " is higher than " + DoubleToString(filterAdxMin, 2);
                        Print(msgAdx);
                    }
                }
                // ATR
                double atr = 100;
                double atrEma = 0;
                bool validAtr = true;
                if(filterAtr) {
                    atr = calculateAtr();
                    atrEma = calculateAtrEma();
                    string msgAdx = "";
                    if(atr <= atrEma) {
                        validAtr = false;
                        msgAdx = "⛔️ No opened trade:️ Market Sideway, ATR " + DoubleToString(atr) + " is lower or equal than ATR EMA " + DoubleToString(atrEma);
                    } else {
                        msgAdx = "⚽ Market trending - ATR " + DoubleToString(atr) + " is higher than ATR EMA " + DoubleToString(atrEma);
                    }
                    Print(msgAdx);
                }
                if(validAdx && validAtr) {
                    double rsi = 50;
                    if(filterRsi) {
                        rsi = calculateRsi();
                        string msgRsi = "❓ RSI: " + DoubleToString(rsi, 2) + " | Lower:" + DoubleToString(filterRsiLower, 0) + " |Upper:" + DoubleToString(filterRsiUpper, 0);
                        Print(msgRsi);
                    }
                    if (resistance + offsetPrice > ask) {
                        // Long
                        string strategy = directionStrategy == 0 ? "long" : "short";
                        bool validEma = true;
                        if(filterEma) {
                            if(resistance + offsetPrice <= ema) {
                                validEma = false;
                                string msgEmaFilter = "⛔️ No opened " + strategy + " trade: Price " + DoubleToString((resistance + offsetPrice), _Digits)  + " lower than EMA " +  DoubleToString(ema, _Digits);
                                Print(msgEmaFilter);
                            }
                        }
                        if(directionStrategy == 0) {
                            bool validRsi = true;
                            if(filterRsi) {
                                if(rsi < filterRsiUpper) {
                                    validRsi = false;
                                    string msgRsiFilter = "⛔️ No opened " + strategy + " trade: RSI " + DoubleToString(rsi, 0)  + " lower than upper RSI " +  DoubleToString(filterRsiUpper, _Digits);
                                    Print(msgRsiFilter);
                                }
                            }
                            if(validEma && validRsi ) {
                                openLongBreakout();
                            }
                        } else {
                            bool validRsi = true;
                            if(filterRsi) {
                                if(rsi > filterRsiUpper) {
                                    validRsi = false;
                                    string msgRsiFilter = "⛔️ No opened " + strategy + " trade: RSI " + DoubleToString(rsi, 0)  + " higher than upper RSI " +  DoubleToString(filterRsiUpper, _Digits);
                                    Print(msgRsiFilter);
                                }
                            }
                            if(validEma && validRsi ) {
                                openShortReversal();
                            }
                        }
                    }
                    if (support - offsetPrice < bid) {
                        // Short
                        string strategy = directionStrategy == 0 ? "short" : "long";
                        bool validEma = true;
                        if(filterEma) {
                            if(support - offsetPrice >= ema) {
                                validEma = false;
                                string msgEmaFilter = "⛔️ No opened " + strategy + " trade: Price " + DoubleToString((support - offsetPrice), _Digits)  + " higher than EMA " +  DoubleToString(ema, _Digits);
                                Print(msgEmaFilter);
                            }
                        }
                        if(directionStrategy == 0) {
                            bool validRsi = true;
                            if(filterRsi) {
                                if(rsi > filterRsiLower) {
                                    validRsi = false;
                                    string msgRsiFilter = "⛔️ No opened " + strategy + " trade: RSI " + DoubleToString(rsi, 0)  + " higher than lower RSI " +  DoubleToString(filterRsiLower, _Digits);
                                    Print(msgRsiFilter);
                                }
                            }
                            if(validEma && validRsi) {
                                openShortBreakout();
                            }
                        } else {
                            bool validRsi = true;
                            if(filterRsi) {
                                if(rsi < filterRsiLower) {
                                    validRsi = false;
                                    string msgRsiFilter = "⛔️ No opened " + strategy + " trade: RSI " + DoubleToString(rsi, 0)  + " lower than lower RSI " +  DoubleToString(filterRsiLower, _Digits);
                                    Print(msgRsiFilter);
                                }
                            }
                            if(validEma && validRsi) {
                                openLongReversal();
                            }
                        }
                    }
                }
            } else {
                string msgFailClear = "⛔️ Fail to clear other order";
                Print(msgFailClear);
            }
        } else {
            string msgNotAvailable = "⛔️ New order not available range";
            Print(msgNotAvailable);
        }
    } else {
        string msgNotInRange = "⛔️ Not in trading range or still have open position";
        Print(msgNotInRange);
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Engine::calculateVolume() {
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double pointValue = tickValue * _Point / tickSize;
    double lotStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
    double riskValue = balance * (riskPercentage / 100.0);
    double volumeLot = riskValue / stopLossPoint / pointValue;
    volumeLot = NormalizeDouble(volumeLot / lotStep, 0) * lotStep;
    volumeLot = volumeLot > maxVolume ? maxVolume : volumeLot;
    volumeLot = volumeLot < minVolume ? minVolume : volumeLot;
    return volumeLot;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Engine::openLongBreakout() {
    string direction = "Buy";
    double volume = calculateVolume();
    double price = NormalizeDouble(resistance + offsetPrice, _Digits);
    double sl = hideStopLoss ? stopLossSafetyPrice : stopLossPrice;
    double slPrice = price - sl;
    realSlPriceBuy = hideStopLoss ? price - stopLossPrice : slPrice;
    double tpPrice = price + takeProfitMargin();
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double spreadPrice = ask - bid;
    Print("- Spread: " + DoubleToString(spreadPrice, _Digits));
    if (price - (safetySpreadMultiplier * spreadPrice) > ask && slPrice > 0) {
        trade.SetExpertMagicNumber(eaMagicNumber);
        if (trade.BuyStop(volume, price, _Symbol, slPrice, tpPrice, ORDER_TIME_GTC, 0, "Buy Stop #" + IntegerToString(eaMagicNumber))) {
            message.OpenBreakoutSuccess(
                direction,
                DoubleToString(price, _Digits),
                DoubleToString(slPrice, _Digits),
                DoubleToString(realSlPriceBuy, _Digits),
                DoubleToString(tpPrice, _Digits),
                DoubleToString(volume, digitVolume),
                hideStopLoss
            );
            return true;
        } else {
            message.OpenBreakoutError(direction,  trade.ResultComment());
            return false;
        }
    } else {
        if (price - (safetySpreadMultiplier * spreadPrice) <= ask) {
            string error = "Price - allowable spread: " + DoubleToString(price - (safetySpreadMultiplier * spreadPrice), _Digits) + " is lower than ask: " + DoubleToString(ask, _Digits);
            message.OpenBreakoutError(direction,  error);
        }
        if (slPrice <= 0) {
            string error = "SL: " + DoubleToString(slPrice, _Digits) + " must greater than 0";
            message.OpenBreakoutError(direction,  error);
        }
        return false;
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Engine::openShortBreakout() {
    string direction = "Sell";
    double volume = calculateVolume();
    double price = NormalizeDouble(support - offsetPrice, _Digits);
    double sl = hideStopLoss ? stopLossSafetyPrice : stopLossPrice;
    double slPrice = price + sl;
    realSlPriceSell = hideStopLoss ?  price + stopLossPrice : slPrice;
    double tpPrice = price - takeProfitMargin();
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double spreadPrice = ask - bid;
    if (price + (safetySpreadMultiplier * spreadPrice) < bid && tpPrice > 0) {
        trade.SetExpertMagicNumber(eaMagicNumber);
        if (trade.SellStop(volume, price, _Symbol, slPrice, tpPrice, ORDER_TIME_GTC, 0, "Sell Stop #" + IntegerToString(eaMagicNumber))) {
            message.OpenBreakoutSuccess(
                direction,
                DoubleToString(price, _Digits),
                DoubleToString(slPrice, _Digits),
                DoubleToString(realSlPriceSell, _Digits),
                DoubleToString(tpPrice, _Digits),
                DoubleToString(volume, digitVolume),
                hideStopLoss
            );
            return true;
        } else {
            message.OpenBreakoutError(direction,  trade.ResultComment());
            return false;
        }
    } else {
        if (price + (safetySpreadMultiplier * spreadPrice) >= bid) {
            string error = "Price + allowable spread: " + DoubleToString(price + (safetySpreadMultiplier * spreadPrice), _Digits) + " is higher than bid: " + DoubleToString(bid, _Digits);
            message.OpenBreakoutError(direction,  error);
        }
        if (tpPrice <= 0) {
            string error = "TP: " + DoubleToString(tpPrice, _Digits) + " must greater than 0";
            message.OpenBreakoutError(direction,  error);
        }
        return false;
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Engine::openLongReversal() {
    string direction = "Buy";
    double volume = calculateVolume();
    double price = NormalizeDouble(support - offsetPrice, _Digits);
    double sl = hideStopLoss ? stopLossSafetyPrice : stopLossPrice;
    double slPrice = price - sl;
    realSlPriceBuy = hideStopLoss ? price - stopLossPrice : slPrice;
    double tpPrice = price + takeProfitMargin();
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double spreadPrice = ask - bid;
    Print("- Spread: " + DoubleToString(spreadPrice, _Digits));
    if (price + (safetySpreadMultiplier * spreadPrice) < bid && slPrice > 0) {
        trade.SetExpertMagicNumber(eaMagicNumber);
        if (trade.BuyLimit(volume, price, _Symbol, slPrice, tpPrice, ORDER_TIME_GTC, 0, "Buy Limit #" + IntegerToString(eaMagicNumber))) {
            message.OpenReversalSuccess(
                direction,
                DoubleToString(price, _Digits),
                DoubleToString(slPrice, _Digits),
                DoubleToString(realSlPriceBuy, _Digits),
                DoubleToString(tpPrice, _Digits),
                DoubleToString(volume, digitVolume),
                hideStopLoss
            );
            return true;
        } else {
            message.OpenReversalError(direction,  trade.ResultComment());
            return false;
        }
    } else {
        if (price + (safetySpreadMultiplier * spreadPrice) >= bid) {
            string error = "- Price + allowable spread: " + DoubleToString(price + (safetySpreadMultiplier * spreadPrice), _Digits) + " is higher than bid: " + DoubleToString(bid, _Digits);
            message.OpenReversalError(direction,  error);
        }
        if (slPrice <= 0) {
            string error = "- SL: " + DoubleToString(slPrice, _Digits) + " must greater than 0";
            message.OpenReversalError(direction,  error);
        }
        return false;
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Engine::openShortReversal() {
    string direction = "Sell";
    double volume = calculateVolume();
    double price = NormalizeDouble(resistance + offsetPrice, _Digits);
    double sl = hideStopLoss ? stopLossSafetyPrice : stopLossPrice;
    double slPrice = price + sl;
    realSlPriceSell = hideStopLoss ? price + stopLossPrice : slPrice;
    double tpPrice = price - takeProfitMargin();
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double spreadPrice = ask - bid;
    if (price - (safetySpreadMultiplier * spreadPrice) > ask && tpPrice > 0) {
        trade.SetExpertMagicNumber(eaMagicNumber);
        if (trade.SellLimit(volume, price, _Symbol, slPrice, tpPrice, ORDER_TIME_GTC, 0, "Sell Limit #" + IntegerToString(eaMagicNumber))) {
            message.OpenReversalSuccess(
                direction,
                DoubleToString(price, _Digits),
                DoubleToString(slPrice, _Digits),
                DoubleToString(realSlPriceSell, _Digits),
                DoubleToString(tpPrice, _Digits),
                DoubleToString(volume, digitVolume),
                hideStopLoss
            );
            return true;
        } else {
            message.OpenReversalError(direction,  trade.ResultComment());
            return false;
        }
    } else {
        if (price - (safetySpreadMultiplier * spreadPrice) <= ask) {
            string error = "- Price - allowable spread: " + DoubleToString(price + (safetySpreadMultiplier * spreadPrice), _Digits) + " is lower than ask: " + DoubleToString(bid, _Digits);
            message.OpenReversalError(direction,  error);
        }
        if (tpPrice <= 0) {
            string error = "- TP: " + DoubleToString(tpPrice, _Digits) + " must greater than 0";
            message.OpenReversalError(direction,  error);
        }
        return false;
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Engine::clearAllOrders() {
    if (totalOrder() > 0) {
        for (int i = (OrdersTotal() - 1); i >= 0; i--) {
            if (order.SelectByIndex(i)) {
                if (order.Symbol() == _Symbol && order.Magic() == eaMagicNumber) {
                    ulong ticket = order.Ticket();
                    trade.OrderDelete(ticket);
                }
            }
        }
    }
    return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Engine::updateTrailingStop() {
    if (position.SelectByMagic(_Symbol, eaMagicNumber)) {
        ulong ticket = position.Ticket();
        double currentSl = NormalizeDouble(position.StopLoss(), _Digits);
        double currentTp = position.TakeProfit();
        double tsPrice = hideStopLoss ? stopLossSafetyPrice : trailingStopPrice;
        // Buy
        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double spreadPrice = ask - bid;
        Print("... Trailing " + IntegerToString(ticket) + " " + _Symbol + " EA #" + IntegerToString(eaMagicNumber) + " - Ask: " + DoubleToString(ask, _Digits) + " | Bid: " + DoubleToString(bid, _Digits) + " | SL: " + DoubleToString(currentSl, _Digits) + " | Spread: " + DoubleToString(spreadPrice, _Digits));
        if (position.PositionType() == POSITION_TYPE_BUY) {
            double price = NormalizeDouble(bid, _Digits);
            if(hideStopLoss && price <= realSlPriceBuy) {
                Print("--- Long position finished | Price " + DoubleToString(price, _Digits) + " hit at or below real SL " + DoubleToString(realSlPriceBuy, _Digits));
                // Close position if price below real SL Price
                if(trade.PositionClose(ticket)) {
                    hitRealSlPrice = realSlPriceBuy;
                    Print("- Close long position at price " + DoubleToString(price, _Digits) + " because below real stop loss: " + DoubleToString(realSlPriceBuy, _Digits));
                } else {
                    string msgError = "!!! Error close long position: " + trade.ResultRetcodeDescription();
                    message.TrailingError(msgError);
                }
            } else {
                // Trailing
                double sl = NormalizeDouble(price - tsPrice, _Digits);
                if (sl > currentSl) {
                    double delta = sl - currentSl;
                    totalDelta += delta;
                    Print("--- Long position | SL trailing up " + DoubleToString(delta, _Digits) + " | Total: " + DoubleToString(totalDelta, _Digits));
                    double tp = price + takeProfitMargin();
                    if(hideStopLoss) {
                        realSlPriceBuy = NormalizeDouble(price - trailingStopPrice, _Digits);
                        Print("--- Long position | Modify real SL: " + DoubleToString(realSlPriceBuy, _Digits));
                    }
                    if(trade.PositionModify(ticket, sl, tp)) {
                        Print("--- Long position | Modify SL: " + DoubleToString(sl, _Digits) + " TP: " + DoubleToString(tp, _Digits));
                    } else {
                        string msgError = "!!! Error modify buy position: " + trade.ResultRetcodeDescription();
                        message.TrailingError(msgError);
                        // Forced Close position
                        if(trade.PositionClose(ticket)) {
                            hitRealSlPrice = realSlPriceBuy;
                            string msgError2 = "- Forced Close long position at price " + DoubleToString(price, _Digits);
                            message.TrailingError(msgError2);
                        } else {
                            string msgError3 = "!!! Error close long position: " + trade.ResultRetcodeDescription();
                            message.TrailingError(msgError3);
                        }
                    }
                }
            }
        }
        // Sell
        else if (position.PositionType() == POSITION_TYPE_SELL) {
            double price = ask;
            if(hideStopLoss &&  price >= realSlPriceSell) {
                Print("--- Short position finished | Price " + DoubleToString(price, _Digits) + " hit at or above real SL " + DoubleToString(realSlPriceSell, _Digits));
                // Close position if price above real SL Price
                if(trade.PositionClose(ticket)) {
                    hitRealSlPrice = realSlPriceSell;
                    Print("- Close short position at price " + DoubleToString(price, _Digits) + " because above real stop loss: " + DoubleToString(realSlPriceSell, _Digits));
                } else {
                    string msgError = "!!! Error close short position: " + trade.ResultRetcodeDescription();
                    message.TrailingError(msgError);
                }
            } else {
                // Trailing
                double sl = NormalizeDouble(price + tsPrice, _Digits);
                if (sl < currentSl) {
                    double delta = currentSl - sl;
                    totalDelta += delta;
                    Print("--- Short position | SL trailing down " + DoubleToString(delta, _Digits) + " | Total: " + DoubleToString(totalDelta, _Digits));
                    double tp = price - takeProfitMargin();
                    if(hideStopLoss) {
                        realSlPriceSell = NormalizeDouble(price - trailingStopPrice, _Digits);
                        Print("--- Short position | Modify real SL: " + DoubleToString(realSlPriceSell, _Digits));
                    }
                    if(trade.PositionModify(ticket, sl, tp)) {
                        Print("--- Short position | Modify SL: " + DoubleToString(sl, _Digits) + " TP: " + DoubleToString(tp, _Digits));
                    } else {
                        string msgError = "!!! Error modify short position: " + trade.ResultRetcodeDescription();
                        message.TrailingError(msgError);
                        // Forced Close position
                        if(trade.PositionClose(ticket)) {
                            hitRealSlPrice = realSlPriceSell;
                            string msgError2 = "- Forced Close short position at price " + DoubleToString(price, _Digits);
                            message.TrailingError(msgError2);

                        } else {
                            string msgError3 = "!!! Error close short position: " + trade.ResultRetcodeDescription();
                            message.TrailingError(msgError3);
                        }

                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Engine::totalPosition() {
    int res = 0;
    for (int i = 0; i < PositionsTotal(); i++) {
        if (position.SelectByIndex(i)) {
            if (position.Symbol() == _Symbol && position.Magic() == eaMagicNumber) {
                res++;
            }
        }
    }
    return res;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Engine::totalOrder() {
    int res = 0;
    for (int i = 0; i < OrdersTotal(); i++) {
        order.SelectByIndex(i);
        if (order.Symbol() == _Symbol && order.Magic() == eaMagicNumber) {
            res++;
        }
    }
    return res;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Engine::totalHistory() {
    int res = 0;
    if (HistorySelect(0, TimeCurrent())) {
        int totalHistory = HistoryDealsTotal();
        for (int i = 0; i < totalHistory; i++) {
            ulong ticket = 0;
            if ((ticket = HistoryDealGetTicket(i)) > 0) {
                string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
                ulong magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
                if (symbol == _Symbol && magic == eaMagicNumber) {
                    res++;
                }
            }
        }
    }
    return res;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Engine::getDigit(double num) {
    int d = 0;
    double p = 1;
    while (MathRound(num * p) / p != num) {
        p = MathPow(10, ++d);
    }
    return d;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Engine::timeDelay() {
    datetime currentTime = TimeCurrent();
    datetime serverTime = TimeTradeServer();
    return (int)(serverTime - currentTime);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Engine::isNewBar() {
    static datetime lastBar;
    return lastBar != (lastBar = iTime(_Symbol, PERIOD_CURRENT, 0));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Engine::isTradingTime() {
    if (beginOrderString == "" && endOrderString == "") {
        return true;
    } else {
        datetime orderBegin = StringToTime(beginOrderString);
        datetime orderEnd = StringToTime(endOrderString);
        datetime currentTime = TimeTradeServer();
        if (orderEnd > orderBegin) {
            if (currentTime >= orderBegin && currentTime <= orderEnd) {
                return true;
            } else {
                return false;
            }
        } else if (orderEnd < orderBegin) {
            // overlap time
            if (currentTime <= orderEnd) {
                return true;
            } else if (currentTime >= orderBegin) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Engine::takeProfitMargin() {
    double takeProfitValue = riskReward * stopLossPrice;
    takeProfitValue = NormalizeDouble(takeProfitValue, _Digits);
    return takeProfitValue;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Engine::calculateEma() {
    double emaArray[];
    ArraySetAsSeries(emaArray, true);
    CopyBuffer(emaHandle, 0, 0, 1, emaArray);
    return emaArray[0];
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Engine::calculateAdx() {
    double adxArray[];
    ArraySetAsSeries(adxArray, true);
    CopyBuffer(adxHandle, 0, 0, 1, adxArray);
    return adxArray[0];
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Engine::calculateRsi() {
    double rsiArray[];
    ArraySetAsSeries(rsiArray, true);
    CopyBuffer(rsiHandle, 0, 0, 1, rsiArray);
    return rsiArray[0];
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Engine::calculateAtr() {
    double atrArray[];
    ArraySetAsSeries(atrArray, true);
    CopyBuffer(atrHandle, 0, 0, 3, atrArray);
    return atrArray[0];
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Engine::calculateAtrEma() {
    double atrEmaArray[];
    ArraySetAsSeries(atrEmaArray, true);
    CopyBuffer(emaAtrHandle, 0, 0, 1, atrEmaArray);
    return atrEmaArray[0];
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Engine::calculateSR() {
    if(srIndicator == "ZigZag") {
        calculateZigzag();
    } else if(srIndicator == "Fractals") {
        calculateFractals();
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Engine::calculateZigzag() {
    int barCalc = BarsCalculated(zigzagHandle);
    double highest = 0;
    double bufferHigh[];
    ArrayResize(bufferHigh, barCalc);
    CopyBuffer(zigzagHandle, 1, 0, barCalc, bufferHigh);
    ArraySetAsSeries(bufferHigh, true);
    int iH = 0;
    for (int i = noBarSkip; i < barCalc; i++) {
        if (bufferHigh[i] != EMPTY_VALUE && bufferHigh[i] > 0) {
            highest = bufferHigh[i];
            iH = i+1;
            break;
        }
    }

    double lowest = 0;
    double bufferLow[];
    ArrayResize(bufferLow, barCalc);
    CopyBuffer(zigzagHandle, 2, 0, barCalc, bufferLow);
    ArraySetAsSeries(bufferLow, true);
    int iL = 0;
    for (int i = noBarSkip; i < barCalc; i++) {
        if (bufferLow[i] != EMPTY_VALUE && bufferLow[i] > 0) {
            lowest = bufferLow[i];
            iL = i+1;
            break;
        }
    }

    if(useFinishedSR) {
        if(iH < iL) {
            // Use Last High ZigZag
            if(iL < barCalc) {
                for (int i = iL; i < barCalc; i++) {
                    if (bufferHigh[i] != EMPTY_VALUE && bufferHigh[i] > 0) {
                        highest = bufferHigh[i];
                        break;
                    }
                }
            }
        } else {
            // Use Last Low ZigZag
            if(iH < barCalc) {
                for (int i = iH; i < barCalc; i++) {
                    if (bufferLow[i] != EMPTY_VALUE && bufferLow[i] > 0) {
                        lowest = bufferLow[i];
                        break;
                    }
                }
            }
        }
    }
    resistance = NormalizeDouble(highest, _Digits);
    support = NormalizeDouble(lowest, _Digits);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Engine::calculateFractals() {
    int barCalc = BarsCalculated(fractalsHandle);

    double highest = 0;
    double bufferHigh[];
    ArrayResize(bufferHigh, barCalc);
    CopyBuffer(fractalsHandle, UPPER_LINE, 0, barCalc, bufferHigh);
    ArraySetAsSeries(bufferHigh, true);
    int iH = 0;
    for (int i = noBarSkip; i < barCalc; i++) {
        if (bufferHigh[i] != EMPTY_VALUE && bufferHigh[i] > 0) {
            highest = bufferHigh[i];
            iH = i+1;
            break;
        }
    }

    double lowest = 0;
    double bufferLow[];
    ArrayResize(bufferLow, barCalc);
    CopyBuffer(fractalsHandle, LOWER_LINE, 0, barCalc, bufferLow);
    ArraySetAsSeries(bufferLow, true);
    int iL = 0;
    for (int i = noBarSkip; i < barCalc; i++) {
        if (bufferLow[i] != EMPTY_VALUE && bufferLow[i] > 0) {
            lowest = bufferLow[i];
            iL = i+1;
            break;
        }
    }

    if(useFinishedSR) {
        if(iH < iL) {
            // Use Last High Fractals
            if(iL < barCalc) {
                for (int i = iL; i < barCalc; i++) {
                    if (bufferHigh[i] != EMPTY_VALUE && bufferHigh[i] > 0) {
                        highest = bufferHigh[i];
                        break;
                    }
                }
            }
        } else {
            // Use Last Low Fractals
            if(iH < barCalc) {
                for (int i = iH; i < barCalc; i++) {
                    if (bufferLow[i] != EMPTY_VALUE && bufferLow[i] > 0) {
                        lowest = bufferLow[i];
                        break;
                    }
                }
            }
        }
    }
    resistance = NormalizeDouble(highest, _Digits);
    support = NormalizeDouble(lowest, _Digits);
}

//+------------------------------------------------------------------+
