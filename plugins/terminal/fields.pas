unit fields;

interface

const
  tbl_Securities       = 'securities';
  tbl_Kotirovki        = 'orderbook';
  tbl_Account          = 'account';
  tbl_Orders           = 'orders';
  tbl_Trades           = 'trades';
  tbl_AllTrades        = 'alltrades';
  tbl_MarginLevel      = 'marginlevel';
  tbl_MarginInfo       = 'margininfo';
  tbl_TrsResult        = 'trsresult';
  tbl_StockList        = 'stocklist';
  tbl_AccountList      = 'accountlist';
  tbl_Report           = 'report';
  tbl_ArcTrades        = 'arctrades';
  tbl_StopOrders       = 'stoporders';
  tbl_News             = 'news';
  tbl_LevelList        = 'levellist';
  tbl_LiquidList       = 'liquidlist';
  tbl_FirmList         = 'firmlist';
  tbl_ClientLimits     = 'clientlimits';
  tbl_AccountRests     = 'accountrests';
  tbl_SettleCodes      = 'settlecodes';
  tbl_IndividualLimits = 'individuallimits';

  tbl_ConnectionInfo   = 'conninfo';
  tbl_ServerStatus     = 'srvstat';
  tbl_UserMessage      = 'usermsg';

  tbl_KotQuery         = 'kotquery';
  tbl_SetOrder         = 'setorder';
  tbl_SetStopOrder     = 'setstop';
  tbl_ReportQuery      = 'repquery';
  tbl_ping             = 'ping';
  tbl_AllTradesQuery   = 'atrdquery';
  tbl_TradesQuery      = 'trdquery';
  tbl_DropOrder        = 'droporder';
  tbl_TrsQuery         = 'trsquery';
  tbl_NewsQuery        = 'newsquery';
  tbl_MoveOrder        = 'moveorder';

const
  fld_Stock_ID         = 'stockid';
  fld_Level            = 'level';
  fld_Code             = 'code';
  fld_ShortName        = 'shortname';
  fld_HiBid            = 'hibid';
  fld_LowOffer         = 'lowoffer';
  fld_InitPrice        = 'initprice';
  fld_MaxPrice         = 'maxprice';
  fld_MinPrice         = 'minprice';
  fld_MeanPrice        = 'meanprice';
  fld_meantype         = 'meantype';
  fld_Cnange           = 'change';
  fld_Value            = 'value';
  fld_Amount           = 'amount';
  fld_LotSize          = 'lotsize';
  fld_FaceValue        = 'facevalue';
  fld_LastDealPrice    = 'lastdealprice';
  fld_LastDealSize     = 'lastdealsize';
  fld_Quantity         = 'quantity';
  fld_LastDealQty      = fld_Quantity;
  fld_Time             = 'time';
  fld_LastDealTime     = fld_Time;
  fld_gko_accr         = 'gko_accr';
  fld_gko_yield        = 'gko_yield';
  fld_gko_matdate      = 'gko_matdate';
  fld_gko_cuponval     = 'gko_cuponval';
  fld_gko_nextcupon    = 'gko_nextcupon';
  fld_gko_cuponperiod  = 'gko_cuponperiod';
  fld_BidDepth         = 'biddepth';
  fld_OfferDepth       = 'offerdepth';
  fld_NumBids          = 'numbids';
  fld_NumOffers        = 'numoffers';
  fld_TradingStatus    = 'tradingstatus';
  fld_ClosePrice       = 'closeprice';
  fld_ActiveFields     = 'activefields';
  fld_Gko_IssueSize    = 'gko_issuesize';
  fld_Gko_BuybackPrice = 'gko_buybackprice';
  fld_Gko_BuybackDate  = 'gko_buybackdate';
  fld_PrevPrice        = 'prevprice';
  fld_Fut_Deposit      = 'fut_deposit';
  fld_Fut_Openedpos    = 'fut_openedpos';
  fld_MarketPrice      = 'marketprice';
  fld_LimitPriceHigh   = 'limitpricehigh';
  fld_LimitPriceLow    = 'limitpricelow';
  fld_Decimals         = 'decimals';
  fld_PriceStep        = 'pricestep';
  fld_StepPrice        = 'stepprice';

  fld_InternalID       = 'internalid';
  fld_BuySell          = 'buysell';
  fld_OrderNo          = 'orderno';
  fld_Status           = 'status';
  fld_OrderType        = 'ordertype';

  fld_Account          = 'account';
  fld_ClientID         = 'clientid';
  fld_Balance          = 'balance';
  fld_TradeNo          = 'tradeno';
  fld_Price            = 'price';
  fld_TradeType        = 'tradetype';

  fld_RepoTerm         = 'repoterm';

  fld_CFirmID          = 'cfirmid';
  fld_Match            = 'match';
  fld_SettleCode       = 'settlecode';
  fld_RefundRate       = 'refundrate';
  fld_RepoRate         = 'reporate';
  fld_Price2           = 'price2';

  fld_Fact             = 'fact';
  fld_Plan             = 'plan';
  fld_FactDebts        = 'factdebt';
  fld_PlanDebts        = 'plandebt';
                       
  fld_FactLvl          = 'factlvl';
  fld_PlanLvl          = 'planlvl';
  fld_MinLvl           = 'minlvl';

  fld_NormLvl          = 'normlvl';
  fld_WarnLvl          = 'warnlvl';
  fld_CritLvl          = 'critlvl';

  fld_Trs_ID           = 'trsid';
  fld_ErrorCode        = 'errorcode';
  fld_Message          = 'message';
  fld_MsgID            = 'msgid';
                       
  fld_StockName        = 'stockname';
  fld_StockFlags       = 'stockflags';
                       
  fld_AccountFlags     = 'accountflags';
  fld_AccountType      = 'accounttype';
  fld_Description      = 'descr';

  fld_StartDate        = 'startdate';
  fld_FinDate          = 'findate';
  fld_FullName         = 'fullname';
  fld_Address          = 'address';
  fld_PrcNDS           = 'prcnds';
  fld_Summ             = 'summ';
  fld_BKomiss          = 'bkomiss';
  fld_SKomiss          = 'skomiss';
  fld_MoveDate         = 'movedate';
  fld_Attrib           = 'attrib';
  fld_Comment          = 'comment';
  fld_Key              = 'key';

  fld_Flags            = 'flags';
  fld_Stop_ID          = 'stopid';
  fld_StopType         = 'stoptype';
  fld_StopPrice        = 'stopprice';
  fld_ExpireDate       = 'expire';

  fld_UserName         = 'username';
  fld_RealName         = 'realname';

  fld_Type             = 'type';

  fld_News_ID          = 'id';
  fld_NewsProvider     = 'provider';
  fld_Subj             = 'subj';
  fld_Text             = 'text';
  fld_NewsQryType      = 'newsqry';

  fld_MarketCode       = 'marketcode';
  fld_LevelType        = 'leveltype';
  fld_Default          = 'default';

  fld_OldLimit         = 'oldlimit';
  fld_StartLimit       = 'startlimit';
  fld_Free             = 'free';
  fld_Reserved         = 'reserved';
  fld_Res_pos          = 'respos';
  fld_Res_ord          = 'resord';
  fld_NegVarMarg       = 'negvarmarg';
  fld_CurVarMarg       = 'curvarmarg';

  fld_Firm_ID          = 'firmid';

  fld_SettleDate1      = 'settledate1';
  fld_SettleDate2      = 'settledate2';

implementation

end.
