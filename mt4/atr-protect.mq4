//+------------------------------------------------------------------+
//|                                               AutoATRStopLoss.mq4|
//|                        Automatically adds a 2 ATR stop loss      |
//+------------------------------------------------------------------+
#property strict

// ATR period
input int ATR_Period = 14; // ATR的周期
input double ATR_Multiplier = 1.5; // ATR的倍数，用于止损距离

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // 设置订单事件处理
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
  }
//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer()
  {
   CheckOrders();
  }
//+------------------------------------------------------------------+
//| Function to check and set stop loss for orders                   |
//+------------------------------------------------------------------+
void CheckOrders()
  {
   // 获取当前ATR值并输出调试信息
   double atrValue = iATR(NULL, 0, ATR_Period, 0) * ATR_Multiplier;
   Print("Calculated ATR Value: ", atrValue);

   // 确保ATR值在合理范围
   if (atrValue <= 0)
   {
      Print("Invalid ATR value, skipping stop loss modification.");
      return;
   }

   for (int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         // Check if the order has no stop loss set
         if (OrderStopLoss() == 0)
           {
            double stopLoss = 0.0;

            if (OrderType() == OP_BUY)
               stopLoss = OrderOpenPrice() - atrValue; // 买单止损设置
            else if (OrderType() == OP_SELL)
               stopLoss = OrderOpenPrice() + atrValue; // 卖单止损设置

            // 确保止损在合理价格范围
            if (stopLoss < 0 || stopLoss > MarketInfo(Symbol(), MODE_HIGH) * 10) 
            {
               Print("Stop Loss value is out of reasonable range, skipping modification.");
               continue;
            }

            // Modify order to add stop loss
            if (OrderModify(OrderTicket(), OrderOpenPrice(), stopLoss, OrderTakeProfit(), 0, clrNONE))
               Print("Order modified with ATR Stop Loss: ", stopLoss);
            else
               Print("Error modifying order: ", GetLastError());
           }
        }
     }
  }
//+------------------------------------------------------------------+
