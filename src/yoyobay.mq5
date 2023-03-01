//+------------------------------------------------------------------+
//|                                                       YoYoBayPro |
//|                                       Copyright 2022, YoYoBayPro |
//|                                                http://yoyobay.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, YoYoBay Pro"
#property link      "https://yoyobay.io"
#property version   "230.117"

#include "Engine.mqh"

enum ENUM_SR_INDICATOR {
    ZigZag,
    Fractals
};

enum ENUM_STRATEGY {
    Breakout = 0,
    Reversal = 1
};

//--- input parameters
input group "Trading Window";
input string _Begin_Order                = "03:50";  // Start Order Time (hh:mm) (Server Time)
input string _End_Order                  = "14:30";  // End Order Time (hh:mm) (Server Time)

input group "Risk Management";
input double _Risk                       = 1;        // Risk (%)
input double _Risk_Reward                = 10;       // Risk/Reward Ratio
input double _Stop_Loss_Pip              = 5.0;      // Stop Loss (pip)
input double _Trailing_Stop_Pip          = 1;        // Trailing Stop (pip)
input bool _Hide_Stop_Loss               = false;    // Hide Stop Loss
input double _Stop_Loss_Safety_Pip       = 5.0;      // Safety Stop Loss (pip)
input double _Safety_Spread_Multiplier   = 3;        // Maximum Spread Multiplier (Spread.x < Stop Loss)

input group "S/R";
input ENUM_STRATEGY _Strategy            = Reversal; // Direction Strategy
input ENUM_SR_INDICATOR _SR_Indicator    = Fractals; // S/R Indicator
input bool _Use_Finihed_SR               = false;    // Use Last Finished S/R
input double _Offset_Pip                 = 0;        // Offset First Opened Order From S/R (pip)
input int _No_Bar_Skip                   = 0;        // No of Confirmation Bars

input group "Filter EMA";
input bool _Filter_Ema                   = true;     // Use EMA Filter
input int _Filter_Ema_Period             = 200;      // Period EMA

input group "Filter ADX";
input bool _Filter_Adx                   = true;     // Use ADX Filter
input int _Filter_Adx_Period             = 14;       // Period ADX
input double _Filter_Adx_Min             = 25;       // Minimum ADX

input group "Filter RSI";
input bool _Filter_Rsi                   = true;     // Use RSI Filter
input int _Filter_Rsi_Period             = 14;       // Period RSI
input double _Filter_Rsi_Upper           = 60;       // Upper Limit RSI
input double _Filter_Rsi_Lower           = 40;       // Lower Limit RSI

input group "Filter ATR VS EMA ATR";
input bool _Filter_Atr                   = true;     // Use ATR Filter
input int _Filter_Atr_Period             = 14;       // Period ATR
input int _Filter_Atr_Ema_Period         = 20;       // Period EMA ATR

input group "Expert Advisor"
input string _Brand                      = "YoYoBay";            // Brand
input string _Signature                  = "Powered by YoYoBay"; // Signature
input ulong _Expert_MagicNumber          = 1;                    // EA's MagicNumber

input group "Telegram";
input string _Telegram_Token             = "YOUR:TELEGRAM_BOT_TOKEN"; // Telegram Bot Token
input long _Telegram_Channel_Trader      = -1000000000000;            // Telegram Channel ID for Trader (starts with -)
input string _Telegram_Channel_Investor  = "";                        // Telegram Channel Name for Investor

Engine e;
int OnInit() {
    string _SR_Indicator_String = EnumToString(_SR_Indicator);
    int _Direction_Strategy = _Strategy;
    return (
               e.onInit (
                   _Begin_Order,
                   _End_Order,
                   _Risk,
                   _Stop_Loss_Pip,
                   _Trailing_Stop_Pip,
                   _Hide_Stop_Loss,
                   _Stop_Loss_Safety_Pip,
                   _Risk_Reward,
                   _Safety_Spread_Multiplier,
                   _Direction_Strategy,
                   _SR_Indicator_String,
                   _Use_Finihed_SR,
                   _Offset_Pip,
                   _No_Bar_Skip,
                   _Filter_Ema,
                   _Filter_Ema_Period,
                   _Filter_Adx,
                   _Filter_Adx_Period,
                   _Filter_Adx_Min,
                   _Filter_Rsi,
                   _Filter_Rsi_Period,
                   _Filter_Rsi_Upper,
                   _Filter_Rsi_Lower,
                   _Filter_Atr,
                   _Filter_Atr_Period,
                   _Filter_Atr_Ema_Period,
                   _Brand,
                   _Signature,
                   _Expert_MagicNumber,
                   _Telegram_Token,
                   _Telegram_Channel_Trader,
                   _Telegram_Channel_Investor
               )
           );
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    e.onDeinit(reason);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
    e.onTick();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTrade() {
    e.onTrade();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result) {
    e.onTradeTransaction(trans, request, result);
}
//+------------------------------------------------------------------+
