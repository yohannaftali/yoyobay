//+------------------------------------------------------------------+
//|                                                          Message |
//|                                    Copyright 2022, Yohan Naftali |
//|                                              https://yohanli.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Yohan Naftali"
#property link      "https://yohanli.com"
#property version   "220.907"

#include <Telegram\Telegram.mqh>

// Setup telegram
// Ask bot father for new bot
// Write down bot [token] and set in EA paramater
// Set privacy to allow read channel
// Create new channel for trader (set private for trader)
// Add bot as admin to allow bot send message to channel
// Send message /start in channel
// Go to https://api.telegram.org/bot[token]/GetUpdates
// Search channel id starts with -
// Put channel id on Telegram Channel Trader ID
// Create new channel for investor (set as public)
// Also add bot as admin
// Put Channel Name (not channel title) on parameters
// Copy Telegram Folder into Include Folder

class Message {
  private:

    CCustomBot       bot;

    string           telegramToken;
    long             telegramChannelTrader;
    string           telegramChannelInvestor;
    string           brand;
    string           signature;
    string           eaMagic;
    string           symbol;
    string           period;
    string           title;

  public:
    bool             telegramBot;
    void             Init(
        string Brand,
        string Signature,
        ulong MagicNumber,
        string TelegramToken,
        long TelegramChannelTrader,
        string TelegramChannelInvestor,
        string StringSymbol,
        string StringPeriod
    );
    void             InitParameter(
        string BeginOrder,
        string EndOrder,
        string riskPercentage,
        string stopLossPip,
        string stopLossPoint,
        string trailingStopPip,
        string trailingStopPoint,
        string hideStopLossString,
        string stopLossSafetyPip,
        string stopLossSafetyPoint,
        string riskReward,
        string directionStrategy,
        string srIndicator,
        string offsetPip,
        string noBarSkip,
        string currentTime,
        string serverTime,
        string gmtTime,
        string localTime,
        string totalOrder,
        string totalPosition
    );

    void             OpenBreakoutSuccess(
        string direction,
        string price,
        string sl,
        string realSl,
        string tp,
        string volume,
        bool hideStopLoss
    );
    void             OpenReversalSuccess(
        string direction,
        string price,
        string sl,
        string realSl,
        string tp,
        string volume,
        bool hideStopLoss
    );

    void             OpenBreakoutError(
        string direction,
        string errorMessage
    );
    void             OpenReversalError(
        string direction,
        string errorMessage
    );

    void             TrailingError(
        string errorMessage
    );


    void             ErrorServerUnreachable();

    void             DealCompleted(
        string direction,
        string volume,
        string price,
        string tp,
        string sl,
        string realSl,
        double profitDouble,
        string profit,
        string commision,
        string fee,
        string swap,
        string ask,
        string bid,
        string spreadPoint
    );

    void             InvalidHandle(string lastError);
    void             ShowPosition(
        string totalOrder,
        string totalPosition
    );
    void             CreateOrderEvent(
        string totalOrder,
        string zigzagHigh,
        string zigzagLow,
        string ask,
        string bid,
        string spreadPoint
    );
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Message::CreateOrderEvent(
    string totalOrder,
    string zigzagHigh,
    string zigzagLow,
    string ask,
    string bid,
    string spreadPoint
) {
    string msg = "---⏰⏰⏰ " + title + " | Create Order Event" + " ⏰⏰⏰---\n";
    msg += "- Current Order: " + totalOrder + "\n";
    msg += "- Support: " + zigzagLow + "\n";
    msg += "- Resistance: " + zigzagHigh + "\n";
    msg += "- Ask: " + ask + " Bid:" + bid + "\n";
    msg += "- Spread: " + spreadPoint + " points" + "\n";
    Print(msg);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Message::ShowPosition(
    string totalOrder,
    string totalPosition
) {
    string msg = title + "\n";
    msg += "No Order: " + totalOrder + "\n";
    msg += "Position: " + totalPosition;
    Comment(msg);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Message::Init(
    string Brand,
    string Signature,
    ulong MagicNumber,
    string TelegramToken,
    long TelegramChannelTrader,
    string TelegramChannelInvestor,
    string StringSymbol,
    string StringPeriod
) {
    symbol = StringSymbol;
    period =  StringPeriod;
    eaMagic = IntegerToString(MagicNumber);
    brand = Brand;
    signature = Signature;
    telegramToken = TelegramToken;
    telegramChannelTrader = TelegramChannelTrader;
    telegramChannelInvestor = TelegramChannelInvestor;

    title = brand + " " + symbol + " " + period + " #" + eaMagic;

    telegramBot = false;
    if(telegramToken != "") {
        bot.Token(telegramToken);
        int getMeResult = bot.GetMe();
        if(getMeResult != 0) {
            Print("⚠️ Error: " + GetErrorDescription(getMeResult));
            Print("⚠️ Please set allow web request https://api.telegram.org from Tools->Options->Expert Advisor Tab");
            telegramBot = false;
        } else {
            telegramBot = true;
        }
    }
    Comment(title);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Message::InitParameter(
    string BeginOrder,
    string EndOrder,
    string riskPercentage,
    string stopLossPip,
    string stopLossPoint,
    string trailingStopPip,
    string trailingStopPoint,
    string hideStopLossString,
    string stopLossSafetyPip,
    string stopLossSafetyPoint,
    string riskReward,
    string directionStrategy,
    string srIndicator,
    string offsetPip,
    string noBarSkip,
    string currentTime,
    string serverTime,
    string gmtTime,
    string localTime,
    string totalOrder,
    string totalPosition
) {
    string msg = "✳️✳✳️ Initialize ✳️✳✳️\n";
    msg += "❤️ " + title + "\n";
    msg += "⚽️ Order Time Window (Server Time): " + BeginOrder + " - " + EndOrder + "\n";
    msg += "⚠️ Risk: " + riskPercentage + " %" + "\n";
    msg += "⛔️ Stop Loss: " + stopLossPip + " pip | " + stopLossPoint + " point"  + "\n";
    msg += "✉️ Trailing Stop: " + trailingStopPip + " pip | " + trailingStopPoint + " point" + "\n";
    msg += "❓ Hide Stop Loss: " + hideStopLossString + "\n";
    msg += "⛔️ Safety Stop Loss: " + stopLossSafetyPip + " pip | " + stopLossSafetyPoint + " point" + "\n";
    msg += "✅ Risk Reward Ratio : " + riskReward + "\n";
    msg += "⚽ Strategy : " + directionStrategy + "\n";
    msg += "♣  S/R Indicator : " + srIndicator + "\n";
    msg += "⏰ Offset Order Price : " + offsetPip + " pip" + "\n";
    msg += "❓ No of Confirmation Bars: " + noBarSkip + "\n";
    msg += "⏱ Current Time: " + currentTime + "\n";
    msg += "♠️  Server Time: " + serverTime + "\n";
    msg += "⏳ GMT Time: " + gmtTime + "\n";
    msg += "♦️  Local Time: " + localTime + "\n";
    msg += "❄️ Current Order: " + totalOrder + "\n";
    msg += "✏️ Current Position: " + totalPosition;
    Print(msg);
    if(telegramBot && telegramChannelTrader != 0) {
        bot.SendMessage(telegramChannelTrader, msg, NULL, true);
    }
    Comment(title);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Message::OpenBreakoutSuccess(
    string direction,
    string price,
    string sl,
    string realSl,
    string tp,
    string volume,
    bool hideStopLoss
) {
    string msg = "---⚽️⚽️⚽ ️" + title + " ⚽️⚽️⚽️---\n";
    msg += "- Success: Open " + direction + " Stop Order with Breakout Strategy\n";
    msg += "- Price: " + price + "\n";
    if(hideStopLoss) {
        msg += "- Safety SL: " + sl + "\n";
        msg += "- Real SL: " + realSl + "\n";
    } else {
        msg += "- SL: " + sl + "\n";
    }
    msg += "- TP: " + tp + "\n";
    msg += "- Volume: " + volume + " lot";
    Print(msg);
    if (telegramBot && telegramChannelTrader != 0) {
        bot.SendMessage(telegramChannelTrader, msg, NULL, true);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Message::OpenReversalSuccess(
    string direction,
    string price,
    string sl,
    string realSl,
    string tp,
    string volume,
    bool hideStopLoss
) {
    string msg = "---⚽️⚽️⚽ ️" + title + " ⚽️⚽️⚽️---\n";
    msg += "- Success: Open " + direction + " Limit Order with Reversal Strategy\n";
    msg += "- Price: " + price + "\n";
    if(hideStopLoss) {
        msg += "- Safety SL: " + sl + "\n";
        msg += "- Real SL: " + realSl + "\n";
    } else {
        msg += "- SL: " + sl + "\n";
    }
    msg += "- TP: " + tp + "\n";
    msg += "- Volume: " + volume + " lot";
    Print(msg);
    if (telegramBot && telegramChannelTrader != 0) {
        bot.SendMessage(telegramChannelTrader, msg, NULL, true);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Message::OpenBreakoutError(
    string direction,
    string errorMessage
) {
    string msg = "---⚽️⚽️⚽ ️" + title + " ⚽️⚽️⚽️---\n";
    msg += "- Error: Failed Open " + direction + " Stop Order with Breakout Strategy\n";
    msg += "- " + errorMessage;
    Print(msg);
    if (telegramBot && telegramChannelTrader != 0) {
        bot.SendMessage(telegramChannelTrader, msg, NULL, true);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Message::OpenReversalError(
    string direction,
    string errorMessage
) {
    string msg = "---⚽️⚽️⚽ ️" + title + " ⚽️⚽️⚽️---\n";
    msg += "- Error: Failed Open " + direction + " Limit Order with Reversal Strategy\n";
    msg += "- " + errorMessage;
    Print(msg);
    if (telegramBot && telegramChannelTrader != 0) {
        bot.SendMessage(telegramChannelTrader, msg, NULL, true);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Message::TrailingError(
    string errorMessage
) {
    string msg = "---⚽️⚽️⚽ ️" + title + " ⚽️⚽️⚽️---\n";
    msg += "- Error: Trailing Error\n";
    msg += "- " + errorMessage;
    Print(msg);
    if (telegramBot && telegramChannelTrader != 0) {
        bot.SendMessage(telegramChannelTrader, msg, NULL, true);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Message::ErrorServerUnreachable() {
    string msg = "⛔️ Market is closed or server timeout !!!";
    Print(msg);
    if (telegramBot && telegramChannelTrader != 0) {
        bot.SendMessage(telegramChannelTrader, msg, NULL, true);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Message::DealCompleted(
    string direction,
    string volume,
    string price,
    string tp,
    string sl,
    string realSl,
    double profitDouble,
    string profit,
    string commision,
    string fee,
    string swap,
    string ask,
    string bid,
    string spreadPoint
) {

    string msg = "<strong>" + direction + " Deal Completed</strong>\n";
    msg += profitDouble > 0 ? "❤❤❤ " : "⚠️⚠️⚠️ ";
    msg += title + "\n";
    msg += "⚽️ Pair: " + _Symbol + "\n";
    msg += "✏️ Volume: " + volume + "\n";
    msg += profitDouble > 0 ?  "✅ Profit: " + profit + " ❤❤❤\n": "⚠️ Loss: " + profit + "\n";
    msg += commision != "0.00" ? "✏️ Commision: " + commision + "\n" : "";
    msg += fee != "0.00" ? "✏️ Fee: " + fee + "\n" : "";
    msg += swap != "0.00" ? "✏️ Swap: " + swap + "\n" : "";
    msg += "♦️ Last Price: " + price  + "\n";
    msg += "♠️ TP: " + tp + "\n";
    msg += realSl != "" ? "⛔️ Safety SL: " + sl : "⛔️ SL: " + sl;
    msg += realSl != "" ? " | Real SL: " + realSl + "\n": "\n";
    msg += "❓ Ask: " + ask + " | ♣️ Bid:" + bid + " | Spread: " + spreadPoint + " points\n";
    msg +=  "\n" + signature;
    Print(msg);
    if(telegramBot) {
        if(telegramChannelInvestor != "") {
            bot.SendMessage(telegramChannelInvestor, msg, true);
        }
        if(telegramChannelTrader != 0) {
            bot.SendMessage(telegramChannelTrader, msg, NULL, true);
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Message::InvalidHandle(string lastError) {
    Print("⛔️ Invalid handle, error: ", lastError);
    Comment("Error - Invalid handle");
}
//+------------------------------------------------------------------+
