import pandas as pd
import numpy as np
import pandas_ta as pta
import matplotlib.pyplot as plt
import tpqoa
from datetime import datetime, timedelta
import time


class FrassTrader(tpqoa.tpqoa):
    

    def __init__(self, config_file, instrument, bar_length, EMA_5, EMA_10, EMA_20, units): 
        super().__init__(config_file)
        self.instrument = instrument    # Define an Instrument
        self.bar_length = pd.to_timedelta(bar_length)    # Define a Bar length 
        self.tick_data = pd.DataFrame() # Store Real Time Ticker Data In Empty Data Frame
        self.raw_data = None
        self.data = None 
        self.last_bar = None # first defined in get_most_recent()
        self.units = units
        self.position = 0
        self.profits = []
        
        
        #******************* Strategy Specific Attributes*************************
        self.ema_short = EMA_5
        self.ema_mid = EMA_10
        self.ema_long = EMA_20
        self.macd = pd.DataFrame()
        #**************************************************************************
          
        
        
    # Get Recent Historical Data
    def get_most_recent(self, days = 5): 
        while True: # Repeat until we get all historical data
            
            time.sleep(2)
           
            now = datetime.utcnow()
            now = now - timedelta(microseconds = now.microsecond)
            past = now - timedelta(days = days)
            df = self.get_history(instrument = self.instrument, start = past, end = now,
                              granularity = "S5", price = "M", localize = False).c.dropna().to_frame()
            df.rename(columns = {"c":self.instrument}, inplace = True)
            df = df.resample(self.bar_length, label = "right").last().dropna().iloc[:-1]
            self.raw_data = df.copy() # raw data
            self.last_bar = self.raw_data.index[-1] # raw data
            
            # accept, if less than [bar_lenght] has elapsed since the last full historical bar and now
            if pd.to_datetime(datetime.utcnow()).tz_localize("UTC") - self.last_bar < self.bar_length:
                break
        
        
    def on_success(self, time, bid, ask):
        
        print(self.ticks, end = " ")  #Print Running Tick Number Just So We Know It's Running
        
        #Get & Store Ticker Data  
        recent_tick = pd.to_datetime(time) # Turn time into timestamp object usising pandas
        
       
            
        df = pd.DataFrame({self.instrument:(ask + bid)/2}, 
                          index = [pd.to_datetime(time)]) # Pass time through date-time object and make index
        self.tick_data = pd.concat([self.tick_data,df])
        # if a time longer than the bar_lenght has elapsed between last full bar and the most recent tick
        
        if recent_tick - self.last_bar > self.bar_length:
            self.resample_and_join()
            self.define_strategy() # Prepare Data / Strategy Features
            self.execute_trades()
            
       
        
         
        
    def resample_and_join(self):
        # Via On Success method or On Success we resample the data.
        # Append the most resampled ticks ( most recent) to self.data
        self.raw_data = pd.concat([self.raw_data,self.tick_data.resample(self.bar_length, label = "right").last().ffill().iloc[:-1]])
        
        self.tick_data = self.tick_data.iloc[-1:] # Only Keep the lastest Tick 
        self.last_bar = self.raw_data.index[-1]  
        
        
    def define_strategy(self): # "strategy specific"
        
        df = self.raw_data.copy()
        
        self.macd = pta.macd(close = df[self.instrument])
        self.macd.columns = ['MACD_LINE','MACD_HISTOGRAM','MACD_SIGNAL_LINE']
        df = pd.merge(df,self.macd, left_index=True, right_index=True)
    
        
        #***********************Define Strategy********************
        
        df["EMA_5"] = pta.ema(df[self.instrument],length = self.ema_short, offset = 0)
        df["EMA_10"] = pta.ema(df[self.instrument],length = self.ema_mid, offset = 0)
        df["EMA_20"] = pta.ema(df[self.instrument],length = self.ema_long, offset = 0)
        df["RSI_14"] = pta.rsi(df[self.instrument], length = 14) 
        
       
        df["EMA_SIGNAL"] = np.where((df["EMA_5"] > df["EMA_10"]) & (df["EMA_5"] > df["EMA_20"]), 1, -1)
        df["RSI_SIGNAL"] = np.where((df["RSI_14"] > 50) , 1, -1)
        df["FIRST_CONFIRM"] = np.where(df.EMA_SIGNAL == df.RSI_SIGNAL, df.EMA_SIGNAL, 0)
        
        #df["MACD_CROSS"] = np.where(df["MACD_LINE"] > df["MACD_SIGNAL_LINE"], 1, -1)
        #df["SEC_CONFIRM"] = np.where(df.FIRST_CONFIRM == df.MACD_CROSS, df.FIRST_CONFIRM, 0)
        #**********************************************************
        
        self.data = df.copy()
    
    
   
        
    def execute_trades(self): # NEW!
        if self.data["FIRST_CONFIRM"].iloc[-1] == 1: # if position is long -> go/stay long
            if self.position == 0:
                order = self.create_order(self.instrument, self.units, suppress = True, ret = True)
                self.report_trade(order, "GOING LONG")
            elif self.position == -1:
                order = self.create_order(self.instrument, self.units * 2, suppress = True, ret = True) 
                self.report_trade(order, "GOING LONG")
            self.position = 1
        elif self.data["FIRST_CONFIRM"].iloc[-1] == -1: # if position is short -> go/stay short
            if self.position == 0:
                order = self.create_order(self.instrument, -self.units, suppress = True, ret = True)
                self.report_trade(order, "GOING SHORT")
            elif self.position == 1:
                order = self.create_order(self.instrument, -self.units * 2, suppress = True, ret = True)
                self.report_trade(order, "GOING SHORT")
            self.position = -1
        elif self.data["FIRST_CONFIRM"].iloc[-1] == 0:  # if position is neutral -> go/stay neutral
            if self.position == -1:
                order = self.create_order(self.instrument, self.units, suppress = True, ret = True) 
                self.report_trade(order, "GOING NEUTRAL")
            elif self.position == 1:
                order = self.create_order(self.instrument, -self.units, suppress = True, ret = True)
                self.report_trade(order, "GOING NEUTRAL")
            self.position = 0
            
    def report_trade(self, order, going):  # NEW
        time = order["time"]
        units = order["units"]
        price = order["price"]
        pl = float(order["pl"])
        self.profits.append(pl)
        cumpl = sum(self.profits)
        print("\n" + 100* "-")
        print("{} | {}".format(time, going))
        print("{} | units = {} | price = {} | P&L = {} | Cum P&L = {}".format(time, units, price, pl, cumpl))
        print(100 * "-" + "\n")  
        
        
if __name__ == "__main__":

    trader = FrassTrader(config, "EUR_USD", "5min", EMA_5 = 5, EMA_10 = 10, EMA_20=20, units = 10000)
    trader.get_most_recent()
    trader.stream_data(trader.instrument)
    if trader.position != 0:#If Open Position
        close_order = trader.create_order(trader.instrument, units = -trader.position * trader.units, suppress = True, ret = True)
        trader.report_trade(close_order, "GOING NEUTRAL")
        trader.position = 0
