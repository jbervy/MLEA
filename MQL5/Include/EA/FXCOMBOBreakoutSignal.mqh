//+------------------------------------------------------------------+
//|                                        FXCOMBOBreakoutSignal.mqh |
//|                                                         Zephyrrr |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Zephyrrr"
#property link      "http://www.mql5.com"
#include <ExpertModel\ExpertModelSignal.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\DealInfo.mqh>

#include <Indicators\Trend.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\TimeSeries.mqh>

#include <ExpertModel\ExpertModel.mqh>
#include <Files\FileTxt.mqh>
#include <Utils\Utils.mqh>

// EURUSD, M5
class CFXCOMBOBreakoutSignal : public CExpertModelSignal
  {
private:
    CiClose m_iClose;
    CiMA m_iMa;
    CiATR m_iATR;
    int TakeProfit;
    int StopLoss;
    int Break;
    MqlDateTime m_lastTime;
    bool GetOpenSignal(int wantSignal);
    bool GetCloseSignal(int wantSignal);
public:
                     CFXCOMBOBreakoutSignal();
                    ~CFXCOMBOBreakoutSignal();
   virtual bool      ValidationSettings();
   virtual bool      InitIndicators(CIndicators* indicators);
   
   virtual bool      CheckOpenLong(double& price,double& sl,double& tp,datetime& expiration);
   virtual bool      CheckCloseLong(CTableOrder* t, double& price);
   virtual bool      CheckOpenShort(double& price,double& sl,double& tp,datetime& expiration);
   virtual bool      CheckCloseShort(CTableOrder* t, double& price);
  };

void CFXCOMBOBreakoutSignal::CFXCOMBOBreakoutSignal()
{
}

void CFXCOMBOBreakoutSignal::~CFXCOMBOBreakoutSignal()
{
}

bool CFXCOMBOBreakoutSignal::ValidationSettings()
{
    if(!CExpertSignal::ValidationSettings()) 
        return(false);
        
    if (false)
    {
      printf(__FUNCTION__+": Indicators should not be Null!");
      return(false);
    }
    return(true);
}

bool CFXCOMBOBreakoutSignal::InitIndicators(CIndicators* indicators)
{
    if(indicators==NULL) 
        return(false);
    bool ret = true;
    
    ret &= m_iClose.Create(m_symbol.Name(), PERIOD_M5);
    ret &= m_iMa.Create(m_symbol.Name(), PERIOD_H1, 1, 0, MODE_EMA, PRICE_CLOSE);
    ret &= m_iATR.Create(m_symbol.Name(), PERIOD_H1, 19);
    
    ret &= indicators.Add(GetPointer(m_iClose));
    ret &= indicators.Add(GetPointer(m_iMa));
    ret &= indicators.Add(GetPointer(m_iATR));
    
    TakeProfit = 500 * GetPointOffset(m_symbol.Digits());
    StopLoss = 30 * GetPointOffset(m_symbol.Digits());
    Break = 13 * GetPointOffset(m_symbol.Digits());

    return ret;
}

bool CFXCOMBOBreakoutSignal::CheckOpenLong(double& price,double& sl,double& tp,datetime& expiration)
{
    if (GetOpenSignal(1))
    {
        price = m_symbol.Ask();
        tp = price + TakeProfit * m_symbol.Point();
        sl = price - StopLoss * m_symbol.Point();
        
        Debug("CFXCOMBOBreakoutSignal open long with price = " + DoubleToString(price, 4) + " and tp = " + DoubleToString(tp, 4) + " and sl = " + DoubleToString(sl, 4));
        return true;
    }
    
    return false;
}

bool CFXCOMBOBreakoutSignal::CheckOpenShort(double& price,double& sl,double& tp,datetime& expiration)
{
    if (GetOpenSignal(-1))
    {
        price = m_symbol.Bid();
        tp = price - TakeProfit * m_symbol.Point();
        sl = price + StopLoss * m_symbol.Point();

        Debug("CFXCOMBOBreakoutSignal open short with price = " + DoubleToString(price, 4) + " and tp = " + DoubleToString(tp, 4) + " and sl = " + DoubleToString(sl, 4));
        
        return true;
    }
    
    return false;
}

bool CFXCOMBOBreakoutSignal::CheckCloseLong(CTableOrder* t, double& price)
{
    if (GetCloseSignal(1))
    {
        price = m_symbol.Bid();
        
        Debug("CFXCOMBOBreakoutSignal close long with price = " + DoubleToString(price, 4));
        return true;
    }
    return false;
}

bool CFXCOMBOBreakoutSignal::CheckCloseShort(CTableOrder* t, double& price)
{
    if (GetCloseSignal(-1))
    {
        price = m_symbol.Ask();
        
        Debug("CFXCOMBOBreakoutSignal close short with price = " + DoubleToString(price, 4));
        return true;
    }
    return false;
}

bool CFXCOMBOBreakoutSignal::GetOpenSignal(int wantSignal)
{
    //if (!IsNewBar(Symbol(), Period()))
    //    return false;
        
    MqlDateTime now;
    TimeGMT(now);

    int hour = now.hour - GetGMTOffset();
    if (hour < 0) hour += 24;
    
    if (hour != 0 && hour != 8 && hour != 7 && hour != 18 && hour != 17 &&
        hour != 13 && hour != 14 && hour != 6 && hour != 9 && hour != 2 &&
        hour != 3)
        return false;
      
    CExpertModel* em = (CExpertModel *)m_expert;

    m_iClose.Refresh(-1);
    m_iMa.Refresh(-1);
    m_iATR.Refresh(-1);
    
    double l_iclose_268 = m_iClose.GetData(1);
    double l_ima_244 = m_iMa.Main(1);
    double l_iatr_236 = m_iATR.Main(1);
    double ld_252 = l_ima_244 + l_iatr_236 * 1.4;
    double ld_260 = l_ima_244 - l_iatr_236 * 1.4;
    
    /*
    datetime now2 = StructToTime(now);
    string fileName = "ComboBreakIndicator.txt";
    CFileTxt file;
    file.Open(fileName, FILE_READ|FILE_WRITE);
    file.Seek(0, SEEK_END);
    file.WriteString(TimeToString(now2));
    file.WriteString(",");
    file.WriteString(IntegerToString(hour));
    file.WriteString(",");
    file.WriteString(DoubleToString((l_ima_244) * 100, 3));
    file.WriteString(",");
    file.WriteString(DoubleToString((l_iclose_268) * 100, 3));
    file.WriteString(",");
    file.WriteString(DoubleToString(l_iatr_236 * 100, 3));
    file.WriteString("\r\n");
    file.Close();
    //Print(l_iclose_268, ", ", ld_252);
    return false;*/
    
    if (wantSignal == 1 && em.GetOrderCount(ORDER_TYPE_BUY) < 1 && l_iclose_268 >= ld_252 + Break * m_symbol.Point()) 
    {
        Debug("CFXCOMBOBreakoutSignal Get Open long signal, l_iclose_268 = " + DoubleToString(l_iclose_268, 4) + ", ld_252 = " + DoubleToString(ld_252, 4));
        return true;
    }
    else if (wantSignal == -1 && em.GetOrderCount(ORDER_TYPE_SELL) < 1 && l_iclose_268 <= ld_260 - Break * m_symbol.Point())
    {
        Debug("CFXCOMBOBreakoutSignal Get Open short signal, l_iclose_268 = " + DoubleToString(l_iclose_268, 4) + ", ld_252 = " + DoubleToString(ld_252, 4));
        return true;
    }

    return false;
}

bool CFXCOMBOBreakoutSignal::GetCloseSignal(int wantSignal)
{
    m_iClose.Refresh(-1);
    m_iMa.Refresh(-1);
    m_iATR.Refresh(-1);

    double l_iclose_268 = m_iClose.GetData(1);
    double l_ima_244 = m_iMa.Main(1);
    double l_iatr_236 = m_iATR.Main(1);
    double ld_252 = l_ima_244 + l_iatr_236 * 1.4;
    double ld_260 = l_ima_244 - l_iatr_236 * 1.4;
    
    if (wantSignal == 1 && l_iclose_268 <= ld_260 - Break * m_symbol.Point())
    {
        Debug("CFXCOMBOBreakoutSignal Get close long signal, l_iclose_268 = " + DoubleToString(l_iclose_268, 4) + ", ld_260 = " + DoubleToString(ld_260, 4));
        return true;
    }
    else if (wantSignal == -1 && l_iclose_268 >= ld_252 + Break * m_symbol.Point())
    {
        Debug("CFXCOMBOBreakoutSignal Get close short signal, l_iclose_268 = " + DoubleToString(l_iclose_268, 4) + ", ld_252 = " + DoubleToString(ld_252, 4));
        return true;
    }
    return false;
}
