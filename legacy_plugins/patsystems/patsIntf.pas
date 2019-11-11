unit PATSINTF;


(*


RRRRRRRR  EEEEEEEE  AAAAAAAA  DDDDDDDD
R      R  E         A      A  D       D
R      R  E         A      A  D       D
R      R  E         A      A  D       D
RRRRRRRR  EEEEEEEE  AAAAAAAA  D       D
RR        E         A      A  D       D
R  R      E         A      A  D       D
R    R    E         A      A  D       D
R      R  EEEEEEEE  A      A  DDDDDDDD





DON'T USE "{}" TO SEPARETE FIELDS... THE TOOL THAT GENERATES .H FILE WILL
PICK THAT UP WHEN THE FOLOWING SITUATION HAPPEN:
{FIELDA:INTEGER;
FIELDB: INTEGER}
IT WILL INCLUDE FIELDB IN THE .H FILE

USE SIMPLE //
*)

interface

uses SysUtils;

const
  {$IFDEF DEMO}
     DLL_NAME = 'DEMOAPI.DLL';
  {$ELSE}
     DLL_NAME = 'PATSAPI.DLL';
  {$ENDIF}
//CONSTANTS
  ptAPIversion = 'v2.8.3';

  ptGateway     = 'G';               // application environment types
  ptClient      = 'C';
  ptTestClient  = 'T';
  ptTestGateway = 'g';
  ptDemoClient  = 'D';
  // VM 03/10/2008 new enviroments for Broker Intervention
  ptBroker      = 'B';
  ptTestBroker  = 'b';

  // Error codes returned by API
  ptSuccess             = 0;
  ptErrNotInitialised   = 1;        // ptInitialise not run yet
  ptErrCallbackNotSet   = 2;        // some callback addresses nil
  ptErrUnknownCallback  = 3;        // unknown callback ID
  ptErrNotLoggedOn      = 4;        // user has not successfully logged on
  ptErrInvalidPassword  = 5;        // old pwd incorrect on ptSetPassword
  ptErrBlankPassword    = 6;        // password may not be blank
  ptErrNotEnabled       = 7;        // user/accnt not enabled for this action
  ptErrInvalidIndex     = 8;        // index provided to ptGet<xxx> is invalid
  ptErrUnknownAccount   = 9;        // trader account not found
  ptErrNoData           = 10;       // could not find any data to return
  ptErrFalse            = 11;       // generic value not set/known error
  ptErrUnknownError     = 12;       // *** NOT USED - Spare return code ***
  ptErrWrongVersion     = 13;       // mismatch between application and API
  ptErrBadMsgType       = 14;       // Msg Type not ptAlert or ptNormal
  ptErrUnknownMsgID     = 15;       // msg ID sequence no. not found
  ptErrBufferOverflow   = 16;       // not enough room to write report
  ptErrBadPassword      = 17;       // new password was not recognisable text
  ptErrNotConnected     = 18;       // not connected to host or price feed
  ptErrUnknownCurrency  = 19;       // currency not recognised
  ptErrNoReport         = 20;       // no matching report for report type
  ptErrUnknownOrderType = 21;       // order type not known by API
  ptErrUnknownContract  = 22;       // contractname/date unknown
  ptErrUnknownCommodity = 23;       // commodity name not known
  ptErrPriceRequired    = 24;       // required price to entered for new order
  ptErrUnknownOrder     = 25;       // specified order ID not valid
  ptErrInvalidState     = 26;       // order is not in valid state for action
  ptErrInvalidPrice     = 27;       // supplied price string is invalid
  ptErrPriceNotRequired = 28;       // price specified and should not be
  ptErrInvalidVolume    = 29;       // volume (lots) is not valid
  ptErrAmendDisabled    = 30;       // amend not enabled for exch. (use cancel/add)
  ptErrQueryDisabled    = 31;       // ORPI query not enabled for exch.
  ptErrUnknownExchange  = 32;       // that exchange not known
  ptErrUnknownFill      = 33;       // fill ID not for valid fill
  ptErrNotTradable      = 34;       // Trader is View Only
  ptErrTASUnavailable   = 35;       // Transaction server is not connected
  ptErrMDSUnavailable   = 36;       // MDS not connected
  ptErrNotAlphaNumeric  = 37;       // new password was not alpha-numeric
  ptErrInvalidUnderlying= 38;       // invalid underlying contract for strategy
  ptErrUntradableOType  = 39;       // user is not allowed to trade with selected order type
  ptErrNoPreallocOrders = 40;       // returned when the user has no preallocated orders remaining
                                    //    and the request for more ids has been rejected.     
  ptErrDifferentMarkets = 41;       // Crossing Error - the contracts are in different markets
  ptErrDifferentOrderTypes = 42;    // Crossing Error - the orders are different types
  ptOrderAlreadyReceived= 43;       // user is not allowed to trade with selected order type
  ptVTSItemInvalid      = 44;       // the user has tried to retrieve an invalid Variable Tick Size
  ptErrInvalidOrderParent  = 45;    // The user has tried to add an order to an invalid parent order - OMI
  ptErrNotAggOrder      = 46;       //The user has tried to set an order to DoneForDay that isn't an Aggrgate Order - OMI
  ptErrOrderAlreadyAmending = 47;    // The order has already been passed to the Core Components.  It will be held in a queue until a valid state is returned
  ptErrNotTradableContract = 48;    //The user does not have permission to access this contract information
  ptErrFailedDecompress = 49;       // Unable to decompress contract data
  ptErrAmendMarketSuspended = 50;   //TGE Specific error - the user will get an error if the order cannot be amended
  ptErrGTOrderCancelled = 51;       //GT Message used to identify orders that have been cancelled due to the exchange closing.
  ptErrInvalidAmendOrderType = 52;  //This Order cannot be amended to this Order Type

  // VM 05/12/2007
  ptErrInvalidAlgoXML = 53; // invalid algo string

  // VM 09/01/2008
  ptErrInvalidIPAddress = 54;

  ptErrLast             = 54;       // Keep this in sync with last error number
                                    // Should be same as highest error number (except 99)

  ptErrUnexpected       = 99;       // unexpected error trapped - routine aborted

  // Constants for callback types.
  ptHostLinkStateChange  = 1;
  ptPriceLinkStateChange = 2;
  ptLogonStatus          = 3;
  ptMessage              = 4;
  ptOrder                = 5;
  ptForcedLogout         = 6;
  ptDataDLComplete       = 7;
  ptPriceUpdate          = 8;
  ptFill                 = 9;
  ptStatusChange         = 10;
  ptContractAdded        = 11;
  ptContractDeleted      = 12;
  ptExchangeRate         = 13;
  ptConnectivityStatus   = 14;
  ptOrderCancelFailure   = 15;
  ptAtBestUpdate         = 16;
  ptTickerUpdate         = 17;
  ptMemoryWarning        = 18;
  ptSubscriberDepthUpdate= 19;
  ptVTSCallback          = 20;  
  ptDOMUpdate            = 21;
  ptSettlementCallback   = 22;
  ptStrategyCreateSuccess= 23;
  ptStrategyCreateFailure= 24;
  ptAmendFailureCallback = 25;
  // Eurodollar changes
  ptGenericPriceUpdate   = 26;
  ptBlankPrice           = 27;
  // Jan release callbacks
  ptOrderSentFailure     = 28;
  ptOrderQueuedFailure   = 29;
  ptOrderBookReset       = 30;
  // Global Trading Changes
  ptExchangeUpdate       = 31;
  ptCommodityUpdate      = 32;
  ptContractDateUpdate   = 33;

  ptPurgeCompleted       = 36;
  ptTraderAdded           =37;
  ptOrderTypeUpdate      = 38;


  // Constants to describe socket link states
  ptLinkOpened     = 1;
  ptLinkConnecting = 2;
  ptLinkConnected  = 3;
  ptLinkClosed     = 4;
  ptLinkInvalid    = 5;

  // User message types
  ptAlert  = 1;
  ptNormal = 2;
                                                                                 
  //Group types inside messages
  ptFillGroup = 0;
  ptLegsGroup = 1;
  ptOrderGroup = 2;

  //Logon States
  ptLogonFailed       = 0;
  ptLogonSucceeded    = 1;
  ptForcedOut         = 2;
  ptObsoleteVers      = 3;
  ptWrongEnv          = 4;
  ptDatabaseErr       = 5;
  ptInvalidUser       = 6;
  ptLogonRejected     = 7;
  ptInvalidAppl       = 8;
  ptLoggedOn          = 9;
  ptInvalidLogonState = 99;

  //Fill Types
  ptNormalFill   = 1;
  ptExternalFill = 2;
  ptNettedFill   = 3;
  ptRetainedFill = 5;
  ptBlockLegFill = 52;

  // Pats Order Type Ids
  ptOrderTypeMarket         = 1;
  ptOrderTypeLimit          = 2;
  ptOrderTypeLimitFAK       = 3;
  ptOrderTypeLimitFOK       = 4;
  ptOrderTypeStop           = 5;
  ptOrderTypeSynthStop      = 6;
  ptOrderTypeSynthStopLimit = 7;
  ptOrderTypeMIT            = 8;
  ptOrderTypeSynthMIT       = 9;
  ptOrderTypeMarketFOK      = 10;
  ptOrderTypeMOO            = 11;
  ptOrderTypeIOC            = 12;
  ptOrderTypeStopRise       = 13;
  ptOrderTypeStopFall       = 14;
  ptOrderTypeRFQ            = 15;
  ptOrderTypeStopLoss       = 16;
  ptLimitAtOpen             = 17;
  ptMLM                     = 18;
  ptAggregateOrder          = 25;
  ptCustomerRequest         = 26;
  ptRFQi                    = 27;
  ptRFQt                    = 28;
  ptCrossingBatchType       = 42;
  ptBasisBatchType          = 43;
  ptBlockBatchType          = 44;
  ptAABatchType             = 45;
  ptCrossFaKBatchType       = 46;
  ptGTCMarket               = 50;
  ptGTCLimit                = 51;
  ptGTCStop                 = 52;
  ptGTDMarket               = 53;
  ptGTDLimit                = 54;
  ptGTDStop                 = 55;
  ptSETSRepenter 	    = 90;
  ptSETSRepcancel           = 91;
  ptSETSRepprerel           = 92;
  ptSETSSectDel             = 93;
  ptSETSInstDel             = 94;
  ptSETSCurDel              = 95;
  ptIceberg                 = 130;
  ptGhost                   = 131;
  ptProtected               = 132;
  ptStop                    = 133;

  //Internal BatchIDs
  ptBatchID                 = '10000';

  //Order States
  ptQueued                = 1;
  ptSent                  = 2;
  ptWorking               = 3;
  ptRejected              = 4;
  ptCancelled             = 5;
  ptBalCancelled          = 6;
  ptPartFilled            = 7;
  ptFilled                = 8;
  ptCancelPending         = 9;
  ptAmendPending          = 10;
  ptUnconfirmedFilled     = 11;
  ptUnconfirmedPartFilled = 12;
  ptHeldOrder             = 13;
  ptCancelHeldOrder       = 14;
  ptTransferred           = 20;
  ptExternalCancelled     = 24; // added for GT

  //Order Sub States
  ptSubStatePending       = 1;
  ptSubStateTriggered     = 2;

  // Price Movement
  ptPriceSame = 0;
  ptPriceRise = 1;
  ptPriceFall = 2;


  //GENERIC PRICES
  ptBuySide   =	1;     //	The RFQ is a buy order
  ptSellSide  =	2;     //	The RFQ is a sell order
  ptBothSide  =	3;     //	The RFQ is a for both sides
  PtCrossSide =	4;     //	This is for crossing RFQs

  //Fill Sub Types
  ptFillSubTypeSettlement = 1;
  ptFillSubTypeMinute = 2;
  ptFillSubTypeUnderlying = 3;
  ptFillSubTypeReverse = 4;

  //Settlement Price Types
  ptStlLegacyPrice= 0;
  ptStlCurPrice   = 7;
  ptStlLimitUp    = 21;
  ptStlLimitDown  = 22;
  ptStlExecDiff   = 23;

  // VM 27/11/2008 changed because these are the values according to what stas send to us...
  //ptStlNewPrice   = 24;
  //ptStlYDSPPrice  = 25;

  ptStlYDSPPrice  = 24;
  ptStlNewPrice   = 25;


  ptStlRFQiPrice  = 26;
  ptStlRFQtPrice  = 27;
  ptStlIndicative = 28;
  ptEFPVolume       = 33;
  ptEFSVolume       = 34;
  ptBlockVolume     = 35;
  ptEFPCummVolume   = 36;
  ptEFSCummVolume   = 37;
  ptBlockCummVolume = 38;

  // Price Changes
  ptChangeBid          = $00000001;
  ptChangeOffer        = $00000002;
  ptChangeImpliedBid   = $00000004;
  ptChangeImpliedOffer = $00000008;
  ptChangeRFQ          = $00000010;
  ptChangeLast         = $00000020;
  ptChangeTotal        = $00000040;
  ptChangeHigh         = $00000080;
  ptChangeLow          = $00000100;
  ptChangeOpening      = $00000200;
  ptChangeClosing      = $00000400;
  ptChangeBidDOM       = $00000800;
  ptChangeOfferDOM     = $00001000;
  ptChangeTGE          = $00002000;
  ptChangeSettlement   = $00004000;
  ptChangeIndic        = $00008000;

  // Mask for Cleared Prices
  ptChangeClear        = $0000181F;  // Bid, Offer, Implied Bid, Implied Offer,
                                     // RFQ, Bid DOM, Offer DOM
  // Contract Date Market Status
  ptStateUndeclared = -$0001;
  ptStateNormal     = $0000;
  ptStateExDiv      = $0001;
  ptStateAuction    = $0002;
  ptStateSuspended  = $0004;
  ptStateClosed     = $0008;
  ptStatePreOpen    = $0010;
  ptStatePreClose   = $0020;
  ptStateFastMarket = $0040;

  // Preallocated States
  ptIDsNull = -1;
  ptIDsReceived = 0;
  ptIDsRejected = 1;
  ptIDsRequested = 2;

  // Global Trading Alpha 16 June release AMC
  ptGTUndefined = 0;
  ptGTActive = 1;
  ptGTInactive = 2;
  ptGTExpired = 3;

  ptGTStartOfDay = 0;
  ptGTEndOfDay = 1;

  // Strategy creation codes
  ptFUT_CALENDAR                      = 'E';
  ptFUT_BUTTERFLY                     = 'B';
  ptFUT_CONDOR                        = 'W';
  ptFUT_STRIP                         = 'M';
  ptFUT_PACK                          = 'O';
  ptFUT_BUNDLE                        = 'Y';
  ptFUT_RTS                           = 'Z';
  ptOPT_BUTTERFLY                     = 'B';
  ptOPT_SPREAD                        = 'D';
  ptOPT_CALENDAR_SPREAD               = 'E';
  ptOPT_DIAG_CALENDAR_SPREAD          = 'F';
  ptOPT_GUTS                          = 'G';
  ptOPT_RATIO_SPREAD                  = 'H';
  ptOPT_IRON_BUTTERFLY                = 'I';
  ptOPT_COMBO                         = 'J';
  ptOPT_STRANGLE                      = 'K';
  ptOPT_LADDER                        = 'L';
  ptOPT_STRADDLE_CALENDAR_SPREAD      = 'N';
  ptOPT_DIAG_STRADDLE_CALENDAR_SPREAD = 'P';
  ptOPT_STRADDLE                      = 'S';
  ptOPT_CONDOR                        = 'W';
  ptOPT_BOX                           = 'X';
  ptOPT_SYNTHETIC_CONVERSION_REVERSAL = 'r';
  ptOPT_CALL_SPREAD_VS_PUT            = 'x';
  ptOPT_PUT_SPREAD_VS_CALL            = 'y';
  ptOPT_STRADDLE_VS_OPTION            = 'z';
  ptVOL_REVERSAL_CONVERSION           = 'R';
  ptVOL_OPTION                        = 'V';
  ptVOL_LADDER                        = 'a';
  ptVOL_CALL_SPREAD_VS_PUT            = 'c';
  ptVOL_SPREAD                        = 'd';
  ptVOL_COMBO                         = 'j';
  ptVOL_PUT_SPREAD_VS_CALL            = 'p';
  ptVOL_STRADDLE                      = 's';
  ptDIV_C_CALENDAR                    = 'I';
  ptDIV_C_SPREAD                      = 'H';
  ptDIV_CONVERSION                    = 'G';
  ptDIV_F_SPREAD                      = 'E';
  ptDIV_P_CALENDAR                    = 'A';
  ptDIV_P_SPREAD                      = 'B';
  ptDIV_STRADDLE                      = 'D';
  ptDIV_STRANGLE                      = 'J';

//TYPEDEFS

type
  // General type definitions
  Array2     = array [0..2]  of Char;
  Array3     = array [0..3]  of Char;
  Array5     = array [0..5]  of Char;
  Array6     = array [0..6]  of Char;
  Array8     = array [0..8]  of Char;
  Array9     = array [0..9]  of Char;
  Array10    = array [0..10] of Char;
  Array14    = array [0..14] of Char;
  Array15    = array [0..15] of Char;
  Array16    = array [0..16] of Char;
  Array20    = array [0..20] of Char;
  Array25    = array [0..25] of Char;
  Array30    = array [0..30] of Char;
  Array32    = array [0..32] of Char;
  Array36    = array [0..36] of Char;

  Array50    = array [0..50] of Char;
  Array60    = array [0..60] of Char;
  Array70    = array [0..70] of Char;
  Array120    = array [0..120] of Char;
  Array250   = array [0..250] of Char;
  Array255   = array [0..255] of Char;
  Array500   = array [0..500] of Char;
  ExchNameStr 	= array [0..10] of Char;                    
  ExchRateStr    = array [0..20] of Char;
  ConNameStr 	= array [0..10] of Char;
  ConDateStr 	= array [0..50] of Char;
  TraderStr 	= array [0..20] of Char;
  FloatStr 		= array [0..20] of Char;
  PriceStr 	= array [0..20] of Char;
  TextType 		= array [0..60] of Char;
  LongTextType 	= array [0..500] of Char;
  DateStr 		= array [0..8] of Char;
  TimeStr 		= array [0..6] of Char;
  LegType 		= array [0..5] of Array10;
  FillIDStr 	= array [0..70] of Char;
  CurrencyStr 	= array [0..10] of Char;
  MDSTokenStr   = array [0..10] of Char;
  RepTypeStr 	= array [0..20] of Char;
  CurrNameStr    = array [0..10] of Char;
  CertNameStr    = array [0..50] of Char;
  ReportTypeStr  = array [0..20] of Char;
  MsgIDStr 		= array [0..10] of Char;
  DebugStr       = Array [0..250] of Char;
  OrderIDStr 	= array [0..10] of Char;
  ExchIDStr 	= array [0..30] of Char;
  OrderTypeStr 	= array [0..10] of Char;
  UserNameStr 	= array [0..10] of Char;
  DeviceLabelStr 	= array [0..36] of Char;
  DeviceTypeStr 	= array [0..3] of Char;
  StatusStr 	= array [0..3] of Char;
  SeverityStr 	= array [0..3] of Char;
  DeviceNameStr 	= array [0..20] of Char;
  CommentaryStr 	= array [0..255] of Char;
  ExchangeIdStr 	= array [0..20] of Char;
  OwnerStr 		= array [0..20] of Char;
  TimeStampStr 	= array [0..14] of Char;
  SystemIDStr 	= array [0..10] of Char;
  GTDStr 		= array [0..8] of Char;
  LegStruct     = array [1..5] of Array10;
  WideArray500   = array [0..500] of WideChar;
  AmendTypesArray = Array [0..500] of char;
  AlgoBuff = Array of char;

//DATATYPES

  // Common PATS basic data types
  AmendTypesArrayptr = ^AmendTypesArray;
  CertNamePtr    = ^CertNameStr;
  IntegerPtr 	= ^Integer;
  ConNamePtr     = ^Array10;
  ConDatePtr     = ^Array50;
  CurrNamePtr 	  = ^Array10;
  ExchNamePtr 	  = ^Array10;
  ExchRatePtr 	  = ^Array20;
  MsgIDPtr 	      = ^MsgIDStr;
  OrderTypePtr 	  = ^Array10;
  OrderID 	      = Array10;
  OrderIDPtr 	    = ^OrderID;
  FloatPtr 	      = ^FloatStr;
  PricePtr        = ^PriceStr;
  ReportTypePtr 	= ^Array20;
  TraderPtr 	    = ^Array20;
  FillIDPtr       = ^FillIDStr;
  UserNameStrPtr  = ^UserNameStr;
  DebugStrPtr     = ^DebugStr;
  MDSTokenPtr    = ^MDSTokenStr;

  AlgoBuffptr        = ^AlgoBuff;

  //OBJECTS
  // Structures for reference data calls


  APIBuildVer = packed record
    Version : Array25;
  end;
  APIBuildVerPtr = ^APIBuildVer;


  ExchangeStruct = packed record
    Name        : Array10;
    QueryEnabled: Char;
    AmendEnabled: Char;
    Strategy    : Integer;  
    CustomDecs  : Char;
    Decimals    : Integer;
    TicketType  : char;
    RFQA        : Char;
    RFQT        : Char;
    EnableBlock : Char;
    EnableBasis : Char;
    EnableAA    : Char;
    EnableCross : Char;
    GTStatus    : Integer; //Extra GTStatus field for Global Trading
  end;
  ExchangeStructPtr = ^ExchangeStruct;

  TraderAcctStruct = packed record
    TraderAccount: Array20;
    BackOfficeID : Array20;
    Tradable     : Char;
    LossLimit    : Integer;
  end;
  TraderAcctStructPtr = ^TraderAcctStruct;



  OrderTypeStruct = packed record
    OrderType     : Array10;
    ExchangeName  : Array10;
    OrderTypeID   : Integer;
    NumPricesReqd : Byte;
    NumVolumesReqd: Byte;
    NumDatesReqd  : Byte;
    AutoCreated   : Char;
    TimeTriggered : Char;
    RealSynthetic : Char;
    GTCFlag : Char;
    TicketType    : Array2;
    PatsOrderType : Char;
    AmendOTCount  : integer;
    AlgoXML       : Array50;
  end;
  OrderTypeStructPtr = ^OrderTypeStruct;


  CommodityStruct = packed record
    ExchangeName : Array10;
    ContractName : Array10;
    Currency     : Array10;
    Group        : Array10;
    OnePoint     : Array10;
    TicksPerPoint: Integer;
    TickSize     : Array10;
    GTStatus     : Integer; //Extra GTStatus field for Global Trading
  end;
  CommodityStructPtr = ^CommodityStruct;

  //     contract type (F,C,P)
  //     commodity
  //     maturity date
  //     strike price
  //     whatever, eg volume ratio

  ContractStruct = packed record
    ContractName : Array10;
    ContractDate : Array50;
    ExchangeName : Array10;
    ExpiryDate   : Array8;
    LastTradeDate: Array8;
    NumberOfLegs : Integer;    
//Added as part of the Eurodollar development work.
    TicksPerPoint: Integer;
    TickSize     : Array10;
    Tradable     : char;
    GTStatus     : Integer;
//added for GT X-Link dev
    Margin       : Array20;
    ESATemplate  : Char;
    MarketRef    : Array16;
//added for Minute Market development work.  
    lnExchangeName : Array10;
    lnContractName : Array10;
    lnContractDate : Array50;
    ExternalID: packed array [1..2] of LegStruct;
  end;
  ContractStructPtr = ^ContractStruct;

  ExtendedContractStruct = packed record
    ContractName : Array10;
    ContractDate : Array50;
    ExchangeName : Array10;
    ExpiryDate   : Array8;
    LastTradeDate: Array8;
    NumberOfLegs : Integer;    
//Added as part of the Eurodollar development work.
    TicksPerPoint: Integer;
    TickSize     : Array10;
    Tradable     : Byte;
    GTStatus     : Integer;
//added for GT X-Link dev
    Margin       : Array20;
    ESATemplate  : Char;
    MarketRef    : Array16;    
//added for Minute Market development work.
    lnExchangeName : Array10;
    lnContractName : Array10;
    lnContractDate : Array50;
    ExternalID   : packed array [1..16] of LegStruct;
  end;
  ExtendedContractStructPtr = ^ExtendedContractStruct;

  // Structures for user-level requests
  LogonStatusStruct = packed record
    Status              : Byte;
    Reason              : Array60;
    DefaultTraderAccount: Array20;
    ShowReason          : Char;
    DOMEnabled          : Char;
    PostTradeAmend      : Char;
    UserName            : Array255;
    GTEnabled           : Char;
  end;
  LogonStatusStructPtr = ^LogonStatusStruct;

  LogonStruct = packed record
    UserID     : Array255;
    Password   : Array255;
    NewPassword: Array255;
    Reset      : Char;
    Reports    : Char;
  end;
  LogonStructPtr = ^LogonStruct;

  MessageStruct = packed record
    MsgID  : Array10;
    MsgText: Array500;
    IsAlert: Char;
    Status : Char;
  end;
  MessageStructPtr = ^MessageStruct;

  // Structures for issuing or registering callbacks
  LinkStateStruct = packed record
    OldState: byte;
    NewState: byte;
  end;
  LinkStateStructPtr = ^LinkStateStruct;

  ContractUpdStruct = packed record
    ExchangeName: Array10;
    ContractName: Array10;
    ContractDate: Array50;
  end;
  ContractUpdStructPtr = ^ContractUpdStruct;

  CommodityUpdStruct = packed record
    ExchangeName: Array10;
    ContractName: Array10;
  end;
  CommodityUpdStructPtr = ^CommodityUpdStruct;

  ExchangeUpdStruct = packed record
    ExchangeName: Array10;
  end;
  ExchangeUpdStructPtr = ^ExchangeUpdStruct;

  DOMUpdStruct = packed record 
    ExchangeName: Array10;
    ContractName: Array10;
    ContractDate: Array50;
  end;
  DOMUpdStructPtr = ^DOMUpdStruct;

  PriceUpdStruct = packed record
    ExchangeName: Array10;
    ContractName: Array10;
    ContractDate: Array50;
  end;
  PriceUpdStructPtr = ^PriceUpdStruct;

  AtBestUpdStruct = packed record
    ExchangeName: Array10;
    ContractName: Array10;
    ContractDate: Array50;
  end;
  AtBestUpdStructPtr = ^AtBestUpdStruct;

  SubscriberDepthUpdStruct = packed record
    ExchangeName: Array10;
    ContractName: Array10;
    ContractDate: Array50;
  end;
  SubscriberDepthUpdStructPtr = ^SubscriberDepthUpdStruct;

  StatusUpdStruct = packed record
    ExchangeName: Array10;
    ContractName: Array10;
    ContractDate: Array50;
    Status: Integer;
  end;
  StatusUpdStructPtr = ^StatusUpdStruct;

  FillUpdStruct = packed record
    OrderID: Array10;
    FillID : Array70;
  end;
  FillUpdStructPtr = ^FillUpdStruct;

  OrderUpdStruct = packed record
    OrderID   : Array10;
    OldOrderID: Array10;
    OrderStatus: Byte;
    OFSeqNumber : Integer; //added for Orders and Fills RB 69000
    OrderTypeId: Integer; // future reference
  end;
  OrderUpdStructPtr = ^OrderUpdStruct;

  VTSUpdStruct = packed record
    Exchange  : Array20;
    Commodity : Array20;
    Count     : Integer;
  end;
  VTSUpdStructPtr = ^VTSUpdStruct;

  SettlementPriceStruct = packed record
    ExchangeName  : Array10;
    ContractName  : Array10;
    ContractDate  : Array50;
    SettlementType: Integer;
    Price         : Array20;
    Time          : Array6;
    Date          : Array8;
  end;

  SettlementPriceStructPtr = ^SettlementPriceStruct;

  StrategyCreateSuccessStruct = packed record
    UserName       : Array10;
    ExchangeName   : Array10;
    ContractName   : Array10;
    ReqContractDate: Array50;
    GenContractDate: Array50;
  end;

  StrategyCreateSuccessStructPtr = ^StrategyCreateSuccessStruct;

  StrategyCreateFailureStruct = packed record
    UserName       : Array10;
    ExchangeName   : Array10;
    ContractName   : Array10;
    ContractDate   : Array50;
    Text           : Array60;
  end;
  StrategyCreateFailureStructPtr = ^StrategyCreateFailureStruct;

  BlankPriceStruct = packed record
    ExchangeName   : Array10;
    ContractName   : Array10;
    ContractDate   : Array50;
  end;
  BlankPriceStructPtr = ^BlankPriceStruct;

  ExchangeRateUpdStruct = packed record
    Currency: Array10;
  end;
  ExchangeRateUpdStructPtr = ^ExchangeRateUpdStruct;

  ConnectivityStatusUpdStruct = packed record
    DeviceLabel: Array36;
    DeviceType: Array3;
    Status: Array3;
    Severity: Array3;
    DeviceName: Array20;
    Commentary: Array255;
    ExchangeID: Array20;
    Owner: Array20;
    TimeStamp: Array14;
    SystemID: Array10;
  end;
  ConnectivityStatusUpdStructPtr = ^ConnectivityStatusUpdStruct;

  AtBestStruct = packed record
    Firm: Array3;
    Volume: Integer;
    BestType: Char;
  end;
  AtBestStructPtr = ^AtBestStruct;

  AtBestPriceStruct = packed record
    BidPrice: Array20;
    OfferPrice: Array20;
    LastBuyer: Array3;
    LastSeller: Array3;
  end;
  AtBestPriceStructPtr = ^AtBestPriceStruct;

  TickerUpdStruct = packed record
    ExchangeName: Array10;
    ContractName: Array10;
    ContractDate: Array50;
    BidPrice: Array20;
    BidVolume: Integer;
    OfferPrice: Array20;
    OfferVolume: Integer;
    LastPrice: Array20;
    LastVolume: Integer;
    Bid: Char;
    Offer: Char;
    Last: Char;  
  end;
  TickerUpdStructPtr = ^TickerUpdStruct;

  SubscriberDepthStruct = packed record
    Price: Array20;
    Volume: Integer;
    Firm: Array3;
    DepthType: Char;
  end;
  SubscriberDepthStructPtr = ^SubscriberDepthStruct;

  // Structures for trading routines
  FillStruct = packed record
    Index        : Integer;
    FillId       : FillIDStr;
    ExchangeName : Array10;
    ContractName : Array10;
    ContractDate : Array50;
    BuyOrSell    : Char;
    Lots         : Integer;
    Price        : Array20;		// FP number
    OrderID      : Array10;
    DateFilled   : Array8;
    TimeFilled   : Array6;
    DateHostRecd : Array8;
    TimeHostRecd : Array6;
    ExchOrderId  : Array30;
    FillType     : Byte;			// ptFill, ptExternal, ptNetted, ptRetained
    TraderAccount: Array20;
    UserName     : Array10;
  //CME FX  
    ExchangeFillID : Array70;
    ExchangeRawPrice : Array20;
    ExecutionID   : Array70;
    //Global Trading
    GTStatus      : Integer;
  //Minute and settlement Market change RFC 1017
    SubType       : Integer;
    CounterParty  : Array20;
   // Cjp
    Leg           : Array2;
  end;
  FillStructPtr = ^FillStruct;

  PositionStruct = packed record
    Profit: Array20;     // FP number
    Buys  : Integer;
    Sells : Integer;
  end;
  PositionStructPtr = ^PositionStruct;

  PriceDetailStruct = packed record
    Price     : Array20;       // FP number
    Volume    : Integer;       // does not apply to all price types
    AgeCounter: Byte;          // if zero, price is "expired"
    Direction : Byte;          // 0=Same, 1=Rise, 2=Fall
    Hour      : Byte;
    Minute    : Byte;  
    Second    : Byte;          // Timestamp
  end;
  PriceDetailStructPtr = ^PriceDetailStruct;

  // Returned price details. Cast this as aa array of the following type
  //   "Packed Array [1..<n>] of PriceDetailStruct"
  // if you wish to use a loop to decode price strings to real numbers.
  PriceStruct = packed record
    Bid         : PriceDetailStruct;
    Offer       : PriceDetailStruct;
    ImpliedBid  : PriceDetailStruct;
    ImpliedOffer: PriceDetailStruct;
    RFQ         : PriceDetailStruct;
    Last0       : PriceDetailStruct;
    Last1       : PriceDetailStruct;
    Last2       : PriceDetailStruct;
    Last3       : PriceDetailStruct;
    Last4       : PriceDetailStruct;
    Last5       : PriceDetailStruct;
    Last6       : PriceDetailStruct;
    Last7       : PriceDetailStruct;
    Last8       : PriceDetailStruct;
    Last9       : PriceDetailStruct;
    Last10      : PriceDetailStruct;
    Last11      : PriceDetailStruct;
    Last12      : PriceDetailStruct;
    Last13      : PriceDetailStruct;
    Last14      : PriceDetailStruct;
    Last15      : PriceDetailStruct;
    Last16      : PriceDetailStruct;
    Last17      : PriceDetailStruct;
    Last18      : PriceDetailStruct;
    Last19      : PriceDetailStruct;
    Total       : PriceDetailStruct;
    High        : PriceDetailStruct;
    Low         : PriceDetailStruct;
    Opening     : PriceDetailStruct;
    Closing     : PriceDetailStruct;
    BidDOM0     : PriceDetailStruct;
    BidDOM1     : PriceDetailStruct;
    BidDOM2     : PriceDetailStruct;
    BidDOM3     : PriceDetailStruct;
    BidDOM4     : PriceDetailStruct;
    BidDOM5     : PriceDetailStruct;
    BidDOM6     : PriceDetailStruct;
    BidDOM7     : PriceDetailStruct;
    BidDOM8     : PriceDetailStruct;
    BidDOM9     : PriceDetailStruct;
    BidDOM10    : PriceDetailStruct;
    BidDOM11    : PriceDetailStruct;
    BidDOM12    : PriceDetailStruct;
    BidDOM13    : PriceDetailStruct;
    BidDOM14    : PriceDetailStruct;
    BidDOM15    : PriceDetailStruct;
    BidDOM16    : PriceDetailStruct;
    BidDOM17    : PriceDetailStruct;
    BidDOM18    : PriceDetailStruct;
    BidDOM19    : PriceDetailStruct;
    OfferDOM0   : PriceDetailStruct;
    OfferDOM1   : PriceDetailStruct;
    OfferDOM2   : PriceDetailStruct;
    OfferDOM3   : PriceDetailStruct;
    OfferDOM4   : PriceDetailStruct;
    OfferDOM5   : PriceDetailStruct;
    OfferDOM6   : PriceDetailStruct;
    OfferDOM7   : PriceDetailStruct;
    OfferDOM8   : PriceDetailStruct;
    OfferDOM9   : PriceDetailStruct;
    OfferDOM10  : PriceDetailStruct;
    OfferDOM11  : PriceDetailStruct;
    OfferDOM12  : PriceDetailStruct;
    OfferDOM13  : PriceDetailStruct;
    OfferDOM14  : PriceDetailStruct;
    OfferDOM15  : PriceDetailStruct;
    OfferDOM16  : PriceDetailStruct;
    OfferDOM17  : PriceDetailStruct;
    OfferDOM18  : PriceDetailStruct;
    OfferDOM19  : PriceDetailStruct;
    LimitUp         : PriceDetailStruct;
    LimitDown       : PriceDetailStruct;
    ExecutionUp     : PriceDetailStruct;
    ExecutionDown   : PriceDetailStruct;
    ReferencePrice  : PriceDetailStruct;
    pvCurrStl   : PriceDetailStruct;
    pvSODStl    : PriceDetailStruct;
    pvNewStl    : PriceDetailStruct;
    pvIndBid    : PriceDetailStruct;
    pvIndOffer  : PriceDetailStruct;
    Status      : Integer;
    ChangeMask  : Integer;
    PriceStatus : Integer;
  end;
  PriceStructPtr = ^PriceStruct;

  NewAggOrderStruct = packed record
    TraderAccount: Array20;
    ExchangeName : Array10;
    ContractName : Array10;
    ContractDate : Array50;
    BuyOrSell    : Char;
    AveragePrice : Array20;   // FP number
    Reference    : Array25;
    DoneForDay   : Char;    
    Xref         : Integer;
  end;
  NewAggOrderStructPtr = ^NewAggOrderStruct;

  NewCustReqStruct = packed record
    TraderAccount: Array20;
    ExchangeName : Array10;
    ContractName : Array10;
    ContractDate : Array50;
    BuyOrSell    : Char;
    ActualAmount : Integer;
    OrderType    : Array10;
    Price        : Array20;
    Price2       : Array20;
    ParentID     : Array10;
    TotalVolume  : Integer;
    CumulativeVol: Integer;
    AveragePrice : Array20;
    Reference    : Array25;
    Xref         : Integer;
  end;
  NewCustReqStructPtr = ^NewCustReqStruct;

  NewOrderStruct = packed record
    TraderAccount: Array20;
    OrderType    : Array10;
    ExchangeName : Array10;
    ContractName : Array10;
    ContractDate : Array50;
    BuyOrSell    : Char;
    Price        : Array20;   // FP number
    Price2       : Array20;
    Lots         : Integer;
    LinkedOrder  : Array10;
    OpenOrClose  : Char;
    Xref         : Integer;
    XrefP        : Integer;
    GoodTillDate : Array8;
    TriggerNow   : Char;
    Reference    : Array25;
    ESARef       : Array50;
    Priority     : Integer;
    TriggerDate  : Array8;
    TriggerTime  : Array6;
    BatchID      : Array10;
    BatchType    : Array10;
    BatchCount   : Integer;
    BatchStatus  : Array10;
    //OMI Changes
    ParentID     : Array10;
    DoneForDay   : Char;

    BigRefField  : Array255;  
 //CME FX Change
    SenderLocationID : Array32;
    Rawprice     : Array20;// - Field will be populated as well as normal price field.
    Rawprice2    : Array20;// - 2nd price field for stop limit price etc.
    ExecutionID  :Array70;
    ClientID     : Array20;           
 //Connect 9.0 changes
    APIM         : Char;        //for conformance
    APIMUser     : Array20;     //for conformance
    YDSPAudit    : Array10;
    ICSNearLegPrice : Array10;
    ICSFarLegPrice  : Array10;
 //end of Connect 9.0
 //IceBerg and Ghost changes
    MinClipSize  : Integer;
    MaxClipSize  : Integer;
    Randomise    : Char;
    TicketType   : Array2;
    TicketVersion: Array3;
 //end of Iceberg and Ghost changes
 //Broker Desk additions
    ExchangeField: Array10;
    BOFID        : Array20;
    Badge        : Array5;
   //Additions for X Link
   LocalUserName : Array10;
   LocalTrader   : Array20;
   LocalBOF      : Array20;
   LocalOrderID  : Array10;
   LocalExAcct   : Array10;
   RoutingID1    : Array10;
   RoutingID2    : Array10;
//end of X Link changes
//OJG RFC 2090 Inactive Orders
   Inactive      : char;
  end;
  NewOrderStructPtr = ^NewOrderStruct;

  ProtectionStruc = packed Record
    Pr1_Price:	Array20;
    Pr1_Volume:	Integer;
    Pr2_Price:	Array20;
    Pr2_Volume:	Integer;
    Pr3_Price:	Array20;
    Pr3_Volume:	Integer;
    St_Type:	Array10;
    St_Price:	Array20;
    St_Step_1:	Array20;
    St_Step_2:	Array20;
  end;
  ProtectionStrucPtr = ^ProtectionStruc;

  BEPNewOrderStruct = packed Record
    NewOrders : Packed Array[1..10] of NewOrderStruct;
  end;
  BEPNewOrderStructPtr = ^BEPNewOrderStruct;

  BEPOrderIDStruct = packed Record
    OrderIDs : Packed Array[1..10] of OrderID;
  end;
  BEPOrderIDStructPtr = ^BEPOrderIDStruct;

  AmendOrderStruct = packed record
    Price              : Array20;   // FP number
    Price2             : Array20;
    Lots               : Integer;
    LinkedOrder        : Array10;
    OpenOrClose        : Char;
    Trader             : Array20;
    Reference          : Array25;
    Priority           : Integer;
    TriggerDate        : Array8;
    TriggerTime        : Array6;
    BatchID            : Array10;
    BatchType          : Array10;
    BatchCount         : Integer;
    BatchStatus        : Array10;
  //OMI Changes
    ParentID           : Array10;
    DoneForDay         : Char;
    BigRefField        : Array255;
    //TargLots   : integer;
    //ActLots    : integer;
 //CME FX Change
    SenderLocationID   : Array32;
    Rawprice           : Array20;// - Field will be populated as well as normal price field.
    Rawprice2          : Array20;// - 2nd price field for stop limit price etc.
    ExecutionID        : Array70;
    ClientID           : Array20;
    ESARef             : Array50;
 //Connect 9.0 changes
    YDSPAudit    : Array10;
    ICSNearLegPrice : Array10;
    ICSFarLegPrice  : Array10;
 //end of Connect 9.0
 //Iceberg and ghost
    MaxClipSize        : Integer;
 //end of Iceberg and ghost
//Additions for X Link
   LocalUserName : Array10;
   LocalTrader   : Array20;
   LocalBOF      : Array20;
   LocalOrderID  : Array10;
   LocalExAcct   : Array10;
   RoutingID1    : Array10;
   RoutingID2    : Array10;
//end of X Link changes
   AmendOrderType: Array10;
   TargetUserName: Array10;
  end;
  AmendOrderStructPtr = ^AmendOrderStruct;

  TUpdateType = (utInvalid, utAmend, utCancel, utDeactivate);

  AmendingOrderStruct = packed record
    OrderID      : Array10;
    UpdateType   : TUpdateType;
    AmendDetails : AmendOrderStruct;
    CancelTimeOut: integer;
  end;
  AmendingOrderStructPtr = ^AmendingOrderStruct;

  CrossingOrderIDs = packed record
    PrimaryOrder   : Array10;
    SecondaryOrder : Array10;
  end;
  CrossingOrderIDsPtr = ^CrossingOrderIDs;

  OrderDetailStruct = packed record
    Index        : Integer;
    Historic     : Char;
    Checked      : Char;
    OrderID      : Array10;
    DisplayID    : Array10;
    ExchOrderID  : Array30;
    UserName     : Array10;
    TraderAccount: Array20;
    OrderType    : Array10;
    ExchangeName : Array10;
    ContractName : Array10;
    ContractDate : Array50;
    BuyOrSell    : Char;
    Price        : Array20;
    Price2       : Array20;
    Lots         : Integer;
    LinkedOrder  : Array10;
    AmountFilled : Integer;
    NoOfFills    : Integer;
    AveragePrice : Array20;
    Status       : Byte;
    OpenOrClose  : Char;
    DateSent     : Array8;
    TimeSent     : Array6;
    DateHostRecd : Array8;
    TimeHostRecd : Array6;
    DateExchRecd : Array8;
    TimeExchRecd : Array6;
    DateExchAckn : Array8;
    TimeExchAckn : Array6;
    NonExecReason: Array60;
    Xref         : Integer;
    XrefP        : Integer;
    UpdateSeq    : Integer;
    GoodTillDate : Array8;
    Reference    : Array25;
    Priority     : Integer;
    TriggerDate  : Array8;
    TriggerTime  : Array6;
    SubState     : Integer;
    BatchID      : Array10;
    BatchType    : Array10;
    BatchCount   : Integer;
    BatchStatus  : Array10;
    //OMI Changes
    ParentID     : Array10;
    DoneForDay   : Char;
    BigRefField  : Array255;
    Timeout      : Integer;
    QuoteID      : Array120;
    LotsPosted   : Integer;
    ChildCount   : Integer;
    ActLots      : Integer;
//    TargLots     : Integer;  
 //CME FX
    SenderLocationID : Array32;
    Rawprice     : Array20;
    Rawprice2    : Array20;
    ExecutionID  : Array70;
    ClientID     : Array20;
    ESARef       : Array50;
 //basis changes
    ISINCode     : Array20;
    CashPrice    : Array20;
    Methodology  : Char;
    BasisRef     : Array20;
 //Change for J-Trader 6.2
    EntryDate  : Array8;
    EntryTime  : Array6;
 //end of J-Trader 6.2
 //Connect 9.0 changes
    APIM         : Char;
    APIMUser     : Array20;
    ICSNearLegPrice : Array10;
    ICSFarLegPrice : Array10;
 //end of Connect 9.0
 //Change for J-Trader 6.3 jan 06 release
    CreationDate : Array8;
    OrderHistorySeq : integer;
 //end of J-Trader 6.3 jan 06 release}
 //changes for icebergs and ghosts
 //IceBerg and Ghost changes
    MinClipSize  : Integer;
    MaxClipSize  : Integer;
    Randomise    : Char;
 //end of Iceberg and Ghost changes
 //Bracket
    ProfitLevel: Char;
 //end bracket
 //changes for orders and Fills RB 69000
   OFSeqNumber   : Integer;
//broker Desk Additions
    ExchangeField: Array10;
    BOFID        : Array20;
    Badge        : Array5;
 //end of OF changes
 // Extra for Global Trading
    GTStatus : Integer;
 //End of GT Additions
 //Additions for GT X Link
    LocalUserName : Array10;
    LocalTrader   : Array20;
    LocalBOF      : Array20;
    LocalOrderID  : Array10;
    LocalExAcct   : Array10;
    RoutingID1    : Array10;
    RoutingID2    : Array10;
//end of GT X Link changes
//introduced as part of the ProMark 4.3 delivery
    FreeTextField1: Array20;
    FreeTextField2: Array20;
//OJG RFC 2090 Inactive Orders
   Inactive      : char;
  end;
  OrderDetailStructPtr = ^OrderDetailStruct;

  VTSDetailStruct = packed record
    Exchange     : Array10;
    ContractName : Array10;
    LowerLim     : Array20;
    UpperLim     : Array20;
    Multiplier   : Integer;
  end;
  VTSDetailStructPtr = ^VTSDetailStruct;

  StratLegStruct = packed record
    ContractType: Char;
    ContractDate: Array50;
    Price       : Array10;  
    Ratio       : Integer;
    //Added for Connect 9.0 functionality
    ContractName: Array10;
  end;

  StrategyLegsStruct = packed record
    Leg0: StratLegStruct;
    Leg1: StratLegStruct;
    Leg2: StratLegStruct;
    Leg3: StratLegStruct;
    Leg4: StratLegStruct;
    Leg5: StratLegStruct;
    Leg6: StratLegStruct;
    Leg7: StratLegStruct;
    Leg8: StratLegStruct;
    Leg9: StratLegStruct;
    Leg10: StratLegStruct;
    Leg11: StratLegStruct;
    Leg12: StratLegStruct;
    Leg13: StratLegStruct;
    Leg14: StratLegStruct;
    Leg15: StratLegStruct;
  end;
  StrategyLegsStructPtr = ^StrategyLegsStruct;

  LegPriceStruct = packed record
    Leg0Price: Array20;
    Leg1Price: Array20;
    Leg2Price: Array20;
    Leg3Price: Array20;
    Leg4Price: Array20;
    Leg5Price: Array20;
    Leg6Price: Array20;
    Leg7Price: Array20;
    Leg8Price: Array20;
    Leg9Price: Array20;
    Leg10Price: Array20;
    Leg11Price: Array20;
    Leg12Price: Array20;
    Leg13Price: Array20;
    Leg14Price: Array20;
    Leg15Price: Array20;
  end;
  LegPriceStructPtr = ^LegPriceStruct;

  BasisOrderStruct = packed record
    ISINCode: Array20;
    CashPrice: Array20;
    Methodology: Char;
    Reference: Array20;
  end;
  BasisOrderStructPtr = ^BasisOrderStruct;

  //Generic price structure added as part of CME Eurodollar changes    

  GenericPriceStruct = packed record
    ExchangeName : Array10;
    ContractName : Array10;
    ContractDate : Array50;
    PriceType    : integer;
    BuyOrSell    : Char;
  end;
  GenericPriceStructPtr = ^GenericPriceStruct;

//CLASS METHODS

  ProcAddr = procedure; stdcall;
  LinkProcAddr = procedure(Data: LinkStateStructPtr); stdcall;
  MsgProcAddr = procedure(MsgID: MsgIDPtr); stdcall;
  PriceProcAddr = procedure(PriceUpdate: PriceUpdStructPtr); stdcall;
  DOMProcAddr = procedure(DOMUpdate: DOMUpdStructPtr); stdcall;
  AtBestProcAddr = procedure(AtBestUpdate: AtBestUpdStructPtr); stdcall;
  SubscriberDepthProcAddr = procedure(SubscriberDepthUpdate: SubscriberDepthUpdStructPtr); stdcall;
  OrderProcAddr = procedure(Order: OrderUpdStructPtr); stdcall;
  FillProcAddr = procedure(Fill: FillUpdStructPtr); stdcall;
  ContractProcAddr = procedure(Contract: ContractUpdStructPtr); stdcall;
  CommodityProcAddr = procedure(Commodity: CommodityUpdStructPtr); stdcall;
  ExchangeProcAddr = procedure(Exchange: ExchangeUpdStructPtr); stdcall;
  StatusProcAddr = procedure(Status: StatusUpdStructPtr); stdcall;
  ExchangeRateProcAddr = procedure(ExchangeRate: ExchangeRateUpdStructPtr); stdcall;
  ConStatusProcAddr = procedure(ConStatus: ConnectivityStatusUpdStructPtr); stdcall;
  TickerUpdateProcAddr = procedure(TickerUpdate: TickerUpdStructPtr); stdcall;
  AmendFailureProcAddr = procedure(Order: OrderUpdStructPtr); stdcall;
  GenericPriceProcAddr = procedure(Price: GenericPriceStructPtr);stdcall;
  SettlementProcAddr = procedure(SettlementPrice: SettlementPriceStructPtr); stdcall;
  StrategyCreateSuccessProcAddr = procedure(Data: StrategyCreateSuccessStructPtr); stdcall;
  StrategyCreateFailureProcAddr = procedure(Data: StrategyCreateFailureStructPtr); stdcall;
  BlankPriceProcAddr = procedure(Data: BlankPriceStructPtr); stdcall;
  OrderBookResetProcAddr = procedure; stdcall;
  TraderAddedProcAddr = procedure(TraderAccount: TraderAcctStructPtr); StdCall;
  OrderTypeUpdateAddr = procedure(OrderType: OrderTypeStructPtr); stdCall;

//METHODS

{$IFNDEF API_INTERNAL}
{$IFNDEF DYNAMIC}
                     
// Routines for registering callbacks
function ptRegisterCallback(callbackID: Integer; CBackProc: ProcAddr): Integer;
  stdcall; external DLL_NAME;

function ptRegisterLinkStateCallback(callbackID: Integer;
  CBackProc: LinkProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterMsgCallback(callbackID: Integer;
  CBackProc: MsgProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterOrderCallback(callbackID: Integer;
  CBackProc: OrderProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterOrderTypeUpdateCallback(callbackID: Integer;
  CBackProc: OrderTypeUpdateAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterFillCallback(callbackID: Integer;
  CBackProc: FillProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterPriceCallback(callbackID: Integer;
  CBackProc: PriceProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterBlankPriceCallback(callbackID: Integer;
  CBackProc: BlankPriceProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterGenericPriceCallback(callbackID: Integer;
  CBackProc: PriceProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterDOMCallback(callbackID: Integer;
  CBackProc: DOMProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterContractCallback(callbackID: Integer;
  CBackProc: ContractProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterCommodityCallback(callbackID: Integer;
  CBackProc: CommodityProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterExchangeCallback(callbackID: Integer;
  CBackProc: ExchangeProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterStatusCallback(CallbackID: Integer;
  CBackProc: StatusProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterExchangeRateCallback(CallbackID: Integer;
  CBackProc: ExchangeRateProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterConStatusCallback(CallbackID: Integer;
  CBackProc: ConStatusProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterOrderCancelFailureCallback(callbackID: Integer;
  CBackProc: OrderProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterOrderSentFailureCallback(callbackID: Integer;
  CBackProc: OrderProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterOrderQueuedFailureCallback(callbackID: Integer;
  CBackProc: OrderProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterAtBestCallback(callbackID: Integer;
  CBackProc: AtBestProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterTickerCallback(callbackID: Integer;
  CBackProc: TickerUpdateProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterAmendFailureCallback(callbackID: Integer;
  CBackProc:AmendFailureProcAddr ): Integer; stdcall; external DLL_NAME;

function ptRegisterSubscriberDepthCallback(callbackID: Integer;
  CBackProc: SubscriberDepthProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterSettlementCallback(callbackID: Integer;
  CBackProc: SettlementProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterStrategyCreateSuccess(callbackID: Integer;
  CBackProc: StrategyCreateSuccessProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterStrategyCreateFailure(callbackID: Integer;
  CBackProc: StrategyCreateFailureProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterOrderBookReset(CallbackID: Integer;
  CBackProc: OrderBookResetProcAddr): Integer; stdcall; external DLL_NAME;

function ptRegisterTraderAdded(callbackID: integer;
  CBackProc: TraderAddedProcAddr): Integer; stdcall; external DLL_NAME;

// Routines to obtain reference data
function ptCountExchanges(Count: IntegerPtr): Integer; stdcall;
  external DLL_NAME;

function ptGetExchange(Index: Integer;
  ExchangeDetails: ExchangeStructPtr): Integer; stdcall; external DLL_NAME;

function ptGetExchangeByName(ExchangeName: ExchNamePtr;
  ExchangeDetails: ExchangeStructPtr): Integer; stdcall; external DLL_NAME;

function ptExchangeExists(ExchangeName: ExchNamePtr): Integer; stdcall;
  external DLL_NAME;

function ptCountTraders(Count: IntegerPtr): Integer; stdcall;
  external DLL_NAME;

function ptGetTrader(Index: Integer;
  TraderDetails: TraderAcctStructPtr): Integer; stdcall; external DLL_NAME;

function ptGetTraderByName(TraderAccount: TraderPtr;
  TraderDetails: TraderAcctStructPtr): Integer; stdcall; external DLL_NAME;

function ptTraderExists(TraderAccount: TraderPtr): Integer; stdcall;
  external DLL_NAME;

function ptCountOrderTypes(Count: IntegerPtr): Integer; stdcall;
  external DLL_NAME;

function ptGetOrderType(Index: Integer;
  OrderTypeRec: OrderTypeStructPtr; AmendOrderTypes : AmendTypesArray): Integer; stdcall; external DLL_NAME;

function ptGetExchangeRate(Currency: CurrNamePtr;
  ExchRate: ExchRatePtr): Integer; stdcall; external DLL_NAME;

function ptCountReportTypes(Count: IntegerPtr): Integer; stdcall;
  external DLL_NAME;

function ptGetReportType(Index: Integer; ReportType: ReportTypePtr): Integer;
  stdcall; external DLL_NAME;

function ptReportTypeExists(ReportType: ReportTypePtr): Integer; stdcall;
  external DLL_NAME;

function ptGetReportSize(ReportType: ReportTypePtr;
  ReportSize: IntegerPtr): Integer; stdcall; external DLL_NAME;

function ptGetReport(ReportType: ReportTypePtr; BufferSize: Integer;
  BufferAddr: Pointer): Integer; stdcall; external DLL_NAME;

function ptCountCommodities(Count: IntegerPtr): Integer; stdcall;
  external DLL_NAME;

function ptGetCommodity(Index: Integer; Commodity: CommodityStructPtr): Integer;
  stdcall; external DLL_NAME;

function ptCommodityExists(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr):Integer; stdcall; external DLL_NAME;

function ptGetCommodityByName(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; Commodity: CommodityStructPtr): Integer;
  stdcall; external DLL_NAME;

function ptCountContracts(Count: IntegerPtr): Integer; stdcall;
  external DLL_NAME;

function ptGetContract(Index: Integer; Contract: ContractStructPtr): Integer;
  stdcall; external DLL_NAME;

function ptGetContractByName(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  Contract: ContractStructPtr): Integer; stdcall; external DLL_NAME;

function ptGetContractByExternalID(ContractIn,
  ContractOut: ContractStructPtr): Integer; stdcall; external DLL_NAME;

function ptGetExtendedContract(Index: Integer;
  ExtContract: ExtendedContractStructPtr): Integer; stdcall;
  external DLL_NAME;

function ptGetExtendedContractByName(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  ExtContract: ExtendedContractStructPtr): Integer;  stdcall;
  external DLL_NAME;

function ptContractExists(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr): Integer;
  stdcall; external DLL_NAME;

// Routines for setting up the API
function ptInitialise(Env: Char; APIversion, ApplicID, ApplicVersion,
  License: PChar; InitReset : boolean): Integer; stdcall; external DLL_NAME;

function ptGetAPIBuildVersion(APIVersion : APIBuildVerPtr):Integer; stdCall; external DLL_NAME;

function ptReady: Integer; stdcall; external DLL_NAME;

function ptPurge(PDate,PTime: PChar):integer; stdcall; external DLL_NAME;

function ptDisconnect: Integer; stdcall; external DLL_NAME;

function ptSetHostAddress(IPaddress, IPSocket: PChar): Integer; stdcall;
  external DLL_NAME;

function ptSetPriceAddress(IPaddress, IPSocket: PChar): Integer; stdcall;
  external DLL_NAME;

procedure ptEnable(Code: Integer); stdcall; external DLL_NAME;

procedure ptDisable(Code: Integer); stdcall; external DLL_NAME;

procedure ptLogString(DebugStr : DebugStrPtr); stdcall; external DLL_NAME;

function ptOMIEnabled(Enabled: char): integer;stdcall; external DLL_NAME;

function ptNotifyAllMessages(Enabled: Char): Integer; stdcall;
  external DLL_NAME;

function ptSetHostReconnect(Interval: Integer): Integer; stdcall;
  external DLL_NAME;

function ptSetPriceReconnect(Interval: Integer): Integer; stdcall;
  external DLL_NAME;

function ptSetPriceAgeCounter (MaxAge: Integer): Integer; stdcall;
  external DLL_NAME;

function ptSubscribePrice(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr): Integer;
  stdcall; external DLL_NAME;

function ptSubscribeToMarket(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr): Integer;
  stdcall; external DLL_NAME;

function ptUnsubscribePrice(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr): Integer;
  stdcall; external DLL_NAME;

function ptUnsubscribeToMarket(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr): Integer;
  stdcall; external DLL_NAME;

function ptPriceSnapshot(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  Wait: Integer): Integer;
  stdcall; external DLL_NAME;

procedure ptSetEncryptionCode(Code: Char); stdcall; external DLL_NAME;

function ptSetHandShakePeriod(Seconds: Integer): Integer; stdcall;
  external DLL_NAME;

function ptSetHostHandShake(Interval, TimeOut: Integer): Integer; stdcall;
  external DLL_NAME;

function ptSetPriceHandShake(Interval, TimeOut: Integer): Integer; stdcall;
  external DLL_NAME;

function ptSetInternetUser(Enabled: Char): Integer; stdcall;
  external DLL_NAME;

procedure ptSetClientPath(Path: PChar); stdcall; external DLL_NAME;

function ptGetErrorMessage(Error: Integer): PChar; stdcall;
  external DLL_NAME;

function ptDumpLastError: Integer; stdcall; external DLL_NAME;

function ptSnapdragonEnabled: Char; stdcall; external DLL_NAME;

function ptSubscribeBroadcast(ExchangeName: ExchNamePtr): Integer;
  stdcall; external DLL_NAME;

function ptUnsubscribeBroadcast(ExchangeName: ExchNamePtr): Integer;
  stdcall; external DLL_NAME;

// Routines for trading
function ptCountFills(Count: IntegerPtr): Integer; stdcall;
  external DLL_NAME;

function ptGetFill(Index: Integer; Fill: FillStructPtr): Integer; stdcall;
  external DLL_NAME;

function ptGetFillByID(ID: FillIDPtr; Fill: FillStructPtr): Integer; stdcall;
  external DLL_NAME;

function ptGetContractPosition(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  TraderAccount: TraderPtr; Position: PositionStructPtr): Integer; stdcall;
  external DLL_NAME;

function ptGetOpenPosition(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  TraderAccount: TraderPtr; Position: PositionStructPtr): Integer; stdcall;
  external DLL_NAME;

function ptGetTotalPosition(TraderAccount: TraderPtr;
  Position: PositionStructPtr): Integer; stdcall; external DLL_NAME;

function ptGetAveragePrice(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  TraderAccount: TraderPtr; Price: PricePtr): Integer; stdcall;
  external DLL_NAME;

function ptCountOrders(Count: IntegerPtr): Integer; stdcall;
  external DLL_NAME;

function ptGetOrder(Index: Integer;
  OrderDetail: OrderDetailStructPtr): Integer; stdcall; external DLL_NAME;

function ptGetOrderByID(OrderID: OrderIDPtr;
  OrderDetail: OrderDetailStructPtr; OFSequenceNumber : Integer = 0): Integer; stdcall; external DLL_NAME;

function ptGetOrderIndex(OrderID: OrderIDPtr; Index: IntegerPtr): Integer;
  stdcall; external DLL_NAME;

procedure ptBlankPrices; stdcall; external DLL_NAME;

function ptGetPrice(Index: Integer; CurrentPrice: PriceStructPtr): Integer;
  stdcall; external DLL_NAME;

function ptGetPriceForContract(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  CurrentPrice: PriceStructPtr): Integer; stdcall; external DLL_NAME;

function ptGetGenericPrice(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  PriceType: integer; Side : integer;
  Price: PriceStructPtr): Integer; stdcall; external DLL_NAME;

function ptAddOrder(NewOrder: NewOrderStructPtr; OrderID: OrderIDPtr): Integer; stdcall;
  external DLL_NAME;


function ptAddAlgoOrder(NewOrder: NewOrderStructPtr; BuffSize : integer; AlgoBuffer : AlgoBuff; OrderID: OrderIDPtr): Integer; stdcall; external DLL_NAME;

function ptGetOrderEx(Index: Integer; OrderDetail: OrderDetailStructPtr; AlgoDetail: AlgoBuffPtr; AlgoSize: IntegerPtr): Integer; stdcall; external DLL_NAME;

function ptGetOrderByIDEx(OrderID: OrderIDPtr; OrderDetail: OrderDetailStructPtr; AlgoDetail: AlgoBuffPtr; AlgoSize: IntegerPtr; OFSequenceNumber : Integer = 0): Integer; stdcall; external DLL_NAME;

function ptGetOrderHistoryEx(Index, Position: Integer; OrderDetail: OrderDetailStructPtr; AlgoDetail: AlgoBuffPtr; AlgoSize: IntegerPtr): Integer; stdcall; external DLL_NAME;



function ptAddProtectionOrder(NewOrder: NewOrderStructPtr; Protection: ProtectionStrucPtr;
                OrderID: OrderIDPtr): Integer; stdcall;  external DLL_NAME;

Function ptAddBatchOrder(OrderCount : Integer; BEPNewOrder : BEPNewOrderStructPtr;
          BEPOrderIDs : BEPOrderIDStructPtr): Integer; stdcall; external DLL_NAME;

function ptAddAggregateOrder(NewAggOrder: NewAggOrderStructPtr; OrderID: OrderIDPtr): Integer; stdcall;
  external DLL_NAME;

function ptAddCustRequest(NewCustReq: NewCustReqStructPtr; OrderID: OrderIDPtr): Integer; stdcall;
  external DLL_NAME

function ptReParent(OrderID, DestParentID: OrderIDPtr): Integer; stdcall;
  external DLL_NAME;

function ptDoneForDay(OrderID: OrderIDPtr): Integer; stdcall;
  external DLL_NAME;

function ptAddCrossingOrder(PrimaryOrder, SecondaryOrder :NewOrderStructPtr; LegPrices: LegPriceStructPtr;
  OrderIDs: CrossingOrderIDsPtr; FAK : Char = 'L'):Integer; stdCall; external DLL_NAME;

function ptAddBlockOrder(PrimaryOrder, SecondaryOrder: NewOrderStructPtr; LegPrices: LegPriceStructPtr;
  OrderIDs: CrossingOrderIDsPtr): Integer; stdcall; external DLL_NAME;

function ptAddBasisOrder(PrimaryOrder, SecondaryOrder: NewOrderStructPtr; BasisOrder: BasisOrderStructPtr;
  OrderID: CrossingOrderIDsPtr): Integer; stdcall; external DLL_NAME;

function ptAddAAOrder(PrimaryOrder, SecondaryOrder: NewOrderStructPtr; BidUser, OfferUser: UserNameStrPtr;
  OrderID: CrossingOrderIDsPtr): Integer; stdcall; external DLL_NAME;

Function ptGetConsolidatedPosition(Exchange: ExchNamePtr; ContractName: ConNamePtr;
                                      ContractDate: ConDatePtr; TraderAccount: TraderPtr;
                                      PositionType: integer; fill: FillStructPtr): integer; stdcall; external DLL_NAME;

function ptAmendOrder(OrderID: OrderIDPtr;
  NewDetails: AmendOrderStructPtr): Integer; stdcall; external DLL_NAME;

function ptAmendAlgoOrder(OrderID: OrderIDPtr; BuffSize: integer; AlgoBuffer: AlgoBuff; NewDetails: AmendOrderStructPtr): Integer; stdcall; external DLL_NAME;


function ptCancelOrder(OrderID: OrderIDPtr): Integer; stdcall;
  external DLL_NAME;

function ptActivateOrder(OrderID: OrderIDPtr): Integer; stdcall;
  external DLL_NAME;

function ptDeactivateOrder(OrderID: OrderIDPtr): Integer; stdcall;
  external DLL_NAME;

function ptCancelBuys(TraderAccount: TraderPtr; ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr): Integer;
  stdcall; external DLL_NAME;

function ptCancelSells(TraderAccount: TraderPtr; ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr): Integer;
  stdcall; external DLL_NAME;

function ptCancelOrders(TraderAccount: TraderPtr; ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr): Integer;
  stdcall; external DLL_NAME;

function ptCancelAll(TraderAccount: TraderPtr): Integer; stdcall;
  external DLL_NAME;

function ptOrderChecked(OrderID: OrderIDPtr; Checked: Char): Integer; stdcall;
  external DLL_NAME;

function ptQueryOrderStatus(OrderID: OrderIDPtr): Integer; stdcall;
  external DLL_NAME;

function ptCountOrderHistory(Index: Integer; Count: IntegerPtr): Integer;
  stdcall; external DLL_NAME;

function ptGetOrderHistory(Index, Position: Integer;
  OrderDetail: OrderDetailStructPtr): Integer; stdcall; external DLL_NAME;

function ptSetUserIDFilter(Enabled: Char): Integer; stdcall;
  external DLL_NAME;

function ptNextOrderSequence(Sequence: IntegerPtr): Integer; stdcall; external DLL_NAME;

// Routines for user-level requests
function ptLogOn(LogonDetails: LogonStructPtr): Integer; stdcall;
  external DLL_NAME;

function ptLogOff: Integer; stdcall; external DLL_NAME;

function ptGetLogonStatus(LogonStatus: LogonStatusStructPtr): Integer; stdcall;
  external DLL_NAME;

function ptDOMEnabled: Integer; stdcall; external DLL_NAME;

function ptPostTradeAmendEnabled: Integer; stdcall;  external DLL_NAME;

function ptEnabledFunctionality(FunctionalityEnabled, SoftwareEnabled: IntegerPtr): Integer;
  stdcall; external DLL_NAME;

function ptCountUsrMsgs(Count: IntegerPtr): Integer; stdcall;
  external DLL_NAME;

function ptGetUsrMsg(Index: Integer; UserMsg: MessageStructPtr): Integer;
  stdcall; external DLL_NAME;

function ptGetUsrMsgByID(MsgID: MsgIDPtr;
  UserMsg: MessageStructPtr): Integer; stdcall; external DLL_NAME;

function ptAcknowledgeUsrMsg(MsgID: MsgIDPtr): Integer; stdcall;
  external DLL_NAME;

function ptPriceStep(Price: double; TickSize: double; NumSteps: Integer;
  TicksPerPoint: Integer): double; stdcall; external DLL_NAME;

function ptPLBurnRate(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  TraderAccount: TraderPtr; BurnRate: FloatPtr): Integer; stdcall;
  external DLL_NAME;

function ptOpenPositionExposure(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  TraderAccount: TraderPtr; Exposure: FloatPtr): Integer; stdcall;
  external DLL_NAME;

function ptBuyingPowerRemaining(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  TraderAccount: TraderPtr; BPRemaining: FloatPtr): Integer; stdcall;
  external DLL_NAME;

function ptBuyingPowerUsed(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  TraderAccount: TraderPtr; BPUsed: FloatPtr): Integer; stdcall;
  external DLL_NAME;

function ptTotalMarginForTrade(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  TraderAccount: TraderPtr; Lots: IntegerPtr; OrderID: OrderIDPtr;
  Price: PricePtr; MarginReqd: FloatPtr): Integer; stdcall;
  external DLL_NAME;

function ptMarginForTrade(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  TraderAccount: TraderPtr; Lots: IntegerPtr; OrderID: OrderIDPtr;
  Price: PricePtr; MarginReqd: FloatPtr): Integer; stdcall;
  external DLL_NAME;

procedure ptSetOrderCancelFailureDelay(Code: Integer); stdcall; external DLL_NAME;

procedure ptSetOrderSentFailureDelay(Code: Integer); stdcall; external DLL_NAME;

procedure ptSetOrderQueuedFailureDelay(Code: Integer); stdcall; external DLL_NAME;

function ptCountContractAtBest(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  Count: IntegerPtr): Integer; stdcall; external DLL_NAME;

function ptGetContractAtBest(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  Index: Integer; AtBest: AtBestStructPtr): Integer; stdcall; external DLL_NAME;

function ptGetContractAtBestPrices(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  AtBestPrices: AtBestPriceStructPtr): Integer; stdcall; external DLL_NAME;

function ptCountContractSubscriberDepth(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  Count: IntegerPtr): Integer; stdcall; external DLL_NAME;

function ptGetContractSubscriberDepth(ExchangeName: ExchNamePtr;
  ContractName: ConNamePtr; ContractDate: ConDatePtr;
  Index: Integer; SubscriberDepth: SubscriberDepthStructPtr): Integer; stdcall; external DLL_NAME;

function ptSuperTASEnabled: Integer; stdcall; external DLL_NAME;

function ptSetSSL(Enabled: Char): Integer; stdcall; external DLL_NAME;

function ptSetPDDSSL(Enabled: Char): Integer; stdcall; external DLL_NAME;

function ptSetMDSToken(MDSToken: MDSTokenPtr): Integer; stdcall; external DLL_NAME;

function ptSetSSLCertificateName(CertName: CertNamePtr): Integer; stdcall; external DLL_NAME;

function ptSetPDDSSLCertificateName(CertName: CertNamePtr): Integer; stdcall; external DLL_NAME;

function ptSetSSLClientAuthName(CertName: CertNamePtr): Integer; stdcall; external DLL_NAME;

function ptSetPDDSSLClientAuthName(CertName: CertNamePtr): Integer; stdcall; external DLL_NAME;

function ptSetSuperTAS(Enabled: Char): Integer; stdcall; external DLL_NAME;

function ptSetMemoryWarning(MemAmount: Integer): Integer; stdcall; external DLL_NAME;

function ptCreateStrategy(StrategyCode: Char; NoOfLegs: Integer; ExchangeName: ExchNamePtr;
    ContractName: ConNamePtr; Legs: StrategyLegsStructPtr):Integer; stdcall; external DLL_NAME;

function ptGetOptionPremium(ExchangeName: ExchNamePtr;
    ContractName: ConNamePtr; ContractDate: ConDatePtr;
    BuySell: Char; Price: PricePtr; Lots: Integer; OPr: FloatPtr): Integer; stdcall; external DLL_NAME;

function ptLockUpdates : integer; stdcall; external DLL_NAME;

function ptUnlockUpdates : integer; stdcall;  external DLL_NAME;

  // APIcallback

{$ELSE}
const
  ptErrLibNotLoaded = ptErrLast + 1;
  ptErrBadLib       = ptErrLast + 2;
  ptErrLibLoaded    = ptErrLast + 3;
  ptErrCantLoad     = ptErrLast + 4;
  ptErrLastDynamic  = ptErrLast + 4;

  DynamicMessages : array [ptErrLibNotLoaded..ptErrLastDynamic] of PChar = (
    'Library not loaded',
    'Cannot find function in API',
    'Library already loaded',
    'Cannot load library'
  );

type
  EPATS = class(Exception)
    FError: Integer;
  public
    constructor Create(Error: Integer); overload;
    property Error: Integer read FError;
  end;

  // ***** Function type declarations *****

  // APIcallback
  TptRegisterCallback = function(callbackID: Integer; CBackProc: ProcAddr): Integer; stdcall;
  TptRegisterLinkStateCallback = function(callbackID: Integer; CBackProc: LinkProcAddr): Integer; stdcall;
  TptRegisterMsgCallback = function(callbackID: Integer; CBackProc: MsgProcAddr): Integer; stdcall;
  TptRegisterOrderCallback = function(callbackID: Integer; CBackProc: OrderProcAddr): Integer; stdcall;
  TptRegisterFillCallback = function(callbackID: Integer; CBackProc: FillProcAddr): Integer; stdcall;
  TptRegisterPriceCallback = function(callbackID: Integer; CBackProc: PriceProcAddr): Integer; stdcall;
  TptRegisterBlankPriceCallback = function(callbackID: Integer; CBackProc: BlankPriceProcAddr): Integer; stdcall;
  TptRegisterGenericPriceCallback = function(callbackID: Integer; CBackProc: GenericPriceProcAddr): Integer; stdcall;
  TptRegisterDOMCallback = function(callbackID: Integer; CBackProc: DOMProcAddr): Integer; stdcall;
  TptRegisterContractCallback = function(callbackID: Integer; CBackProc: ContractProcAddr): Integer; stdcall;
  TptRegisterCommodityCallback = function(callbackID: Integer; CBackProc: CommodityProcAddr): Integer; stdcall;
  TptRegisterExchangeCallback = function(callbackID: Integer; CBackProc: ExchangeProcAddr): Integer; stdcall;
  TptRegisterStatusCallback = function(callbackID: Integer; CBackProce: StatusProcAddr): Integer; stdcall;
  TptRegisterExchangeRateCallback = function(callbackID: Integer; CBackProc: ExchangeRateProcAddr): Integer; stdcall;
  TptRegisterConStatusCallback = function(callbackID: Integer; CBackProc: ConStatusProcAddr): Integer; stdcall;
  TptRegisterOrderCancelFailureCallback = function(callbackID: Integer; CBackProc: OrderProcAddr): Integer; stdcall;
  TptRegisterOrderSentFailureCallback = function(callbackID: Integer; CBackProc: OrderProcAddr): Integer; stdcall;
  TptRegisterOrderQueuedFailureCallback = function(callbackID: Integer; CBackProc: OrderProcAddr): Integer; stdcall;
  TptRegisterAtBestCallback = function(callbackID: Integer; CBackProc: AtBestProcAddr): Integer; stdcall;
  TptRegisterTickerCallback = function(callbackID: Integer; CBackProc: TickerUpdateProcAddr): Integer; stdcall;
  TptRegisterAmendFailureCallback = function(callbackID: Integer; CBackProc: AmendFailureProcAddr): Integer; stdcall;
  TptRegisterSubscriberDepthCallback = function(callbackID: Integer; CBackProc: SubscriberDepthProcAddr): Integer; stdcall;
  TptRegisterSettlementCallback = function(callbackID: Integer; CBackProc: SettlementProcAddr): Integer; stdcall;
  TptRegisterStrategyCreateSuccess = function(callbackID: Integer; CBackProc: StrategyCreateSuccessProcAddr): Integer; stdcall;
  TptRegisterStrategyCreateFailure = function(callbackID: Integer; CBackProc: StrategyCreateFailureProcAddr): Integer; stdcall;
  TptRegisterOrderBookReset = function(callbackID: Integer; CBackProc: OrderBookResetProcAddr): Integer; stdcall;
  TptRegisterTraderAddedCallback = function(callbackID: Integer; CBackProc: TraderAddedProcAddr): Integer; stdcall;
  TptRegisterOrderTypeUpdateCallback = function(callbackID: Integer; CBackProc: OrderTypeUpdateAddr): Integer; stdcall;

  // APIrefdata
  TptCountExchanges = function(Count: IntegerPtr): Integer; stdcall;
  TptGetExchange = function(Index: Integer; ExchangeDetails: ExchangeStructPtr): Integer; stdcall;
  TptGetExchangeByName = function(ExchangeName: ExchNamePtr; ExchangeDetails: ExchangeStructPtr): Integer; stdcall;
  TptExchangeExists = function (ExchangeName: ExchNamePtr): Integer; stdcall;
  TptCountTraders = function(Count: IntegerPtr): Integer; stdcall;
  TptGetTrader = function(Index: Integer; TraderDetails: TraderAcctStructPtr): Integer; stdcall;
  TptGetTraderByName = function(TraderAccount: TraderPtr; TraderDetails: TraderAcctStructPtr): Integer; stdcall;
  TptTraderExists = function(TraderAccount: TraderPtr): Integer; stdcall;
  TptCountOrderTypes = function(Count: IntegerPtr): Integer; stdcall;
  TptGetOrderType = function(Index: Integer; OrderTypeRec: OrderTypeStructPtr; AmendOrderTypes : AmendTypesArrayptr): Integer; stdcall;
  TptGetExchangeRate = function(Currency: CurrNamePtr; ExchRate: ExchRatePtr): Integer; stdcall;
  TptCountReportTypes = function(Count: IntegerPtr): Integer; stdcall;
  TptGetReportType = function(Index: Integer; ReportType: ReportTypePtr): Integer; stdcall;
  TptReportTypeExists = function(ReportType: ReportTypePtr): Integer; stdcall;
  TptGetReportSize = function(ReportType: ReportTypePtr; ReportSize: IntegerPtr): Integer; stdcall;
  TptGetReport = function(ReportType: ReportTypePtr; BufferSize: Integer; BufferAddr: Pointer): Integer; stdcall;
  TptCountCommodities = function(Count: IntegerPtr): Integer; stdcall;
  TptGetCommodity = function(Index: Integer; Commodity: CommodityStructPtr): Integer; stdcall;
  TptCommodityExists = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr):Integer; stdcall;
  TptGetCommodityByName = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr;
    Commodity: CommodityStructPtr): Integer; stdcall;
  TptCountContracts = function(Count: IntegerPtr): Integer; stdcall;
  TptGetContract = function(Index: Integer; Contract: ContractStructPtr): Integer; stdcall;
  TptGetContractByName = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr;
    ContractDate: ConDatePtr; Contract: ContractStructPtr): Integer; stdcall;
  TptGetContractByExternalID = function(ContractIn, ContractOut: ContractStructPtr): Integer; stdcall;
  TptGetExtendedContract = function(Index: Integer; ExtContract: ExtendedContractStructPtr): Integer; stdcall;
  TptGetExtendedContractByName = function(ContractExchange: ExchNamePtr; ContractName: ConNamePtr;
    ContractDate: ConDatePtr; ExtContract: ExtendedContractStructPtr): Integer; stdcall;
  TptContractExists = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr;
    ContractDate: ConDatePtr): Integer; stdcall;
  TptCountContractAtBest = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr;
    ContractDate: ConDatePtr; Count: IntegerPtr): Integer; stdcall;
  TptGetContractAtBest = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr;
    ContractDate: ConDatePtr; Index: Integer; AtBest: AtBestStructPtr): Integer; stdcall;
  TptGetContractAtBestPrices = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr;
    ContractDate: ConDatePtr; AtBestPrices: AtBestPriceStructPtr): Integer; stdcall;
  TptCountContractSubscriberDepth = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr;
    ContractDate: ConDatePtr; Count: IntegerPtr): Integer; stdcall;
  TptGetContractSubscriberDepth = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr;
    ContractDate: ConDatePtr; Index: Integer; SubscriberDepth: SubscriberDepthStructPtr): Integer; stdcall;

  // APIsetup
  TptInitialise = function(Env: char; APIversion, ApplicID, ApplicVersion, License: PChar; InitReset : boolean) : Integer; stdcall;
  TptGetAPIBuildVersion = function (APIVersion : APIBuildVerptr):Integer; stdCall;
  TptReady = function: Integer; stdcall;
  TptPurge = Function(Pdate,PTime: PChar):Integer; stdcall;
  TptDisconnect = function: Integer; stdcall;
  TptSetHostAddress =  function(IPaddress, IPSocket: PChar): Integer; stdcall;
  TptSetPriceAddress = TptSetHostAddress;
  TptEnable = procedure(Code: integer); stdcall;
  TptDisable = TptEnable;
  TptLogString = procedure (DebugStr : DebugStrPtr); stdcall;
  TptOMIEnabled = function(Enabled: char):integer;stdcall;
  TptNotifyAllMessages = function(Enabled: char): Integer; stdcall;
  TptSetHostReconnect = function(Interval: Integer): Integer; stdcall;
  TptSetPriceReconnect = TptSetHostReconnect;
  TptSetPriceAgeCounter = function(MaxAge: integer): Integer; stdcall;
  TptSubscribePrice = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr;
    ContractDate: ConDatePtr): Integer; stdcall;
  TptSubscribeToMarket = TptSubscribePrice;
  TptUnsubscribeToMarket = TptSubscribePrice;
  TptUnsubscribePrice = TptSubscribePrice;
  TptPriceSnapshot = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr;
    ContractDate: ConDatePtr; Wait: Integer): Integer; stdcall;
  TptSetEncryptionCode = procedure(Code: Char); stdcall;
  TptSetHandShakePeriod = function(Seconds: Integer): Integer; stdcall;
  TptSetHostHandShake = function(Interval, TimeOut: Integer): Integer; stdcall;
  TptSetPriceHandShake = TptSetHostHandShake;
  TptSetInternetUser = function(Enabled: Char): Integer; stdcall;
  TptSetClientPath = procedure(Path: PChar); stdcall;
  TptGetErrorMessage = function(Error: Integer): PChar; stdcall;
  TptDumpLastError = function: Integer; stdcall;
  TptSnapdragonEnabled = function: Char; stdcall;
  TptSetOrderCancelFailureDelay = procedure(Code: integer); stdcall;
  TptSetOrderSentFailureDelay = procedure(Code: integer); stdcall;
  TptSetOrderQueuedFailureDelay = procedure(Code: integer); stdcall;
  TptSuperTASEnabled = function: Integer; stdcall;
  TptSetSSL = function(Enabled: Char): Integer; stdcall;
  TptSetSSLCertificateName = function(CertName: CertNamePtr): Integer; stdcall;
  TptSetSSLClientAuthName = function(CertName: CertNamePtr): Integer; stdcall;    
  TptSetMDSToken = function(MDSToken: string): Integer; stdcall; 
  TptSetSuperTAS = function(Enabled: Char): Integer; stdcall;
  TptSetMemoryWarning = function(MemAmount: Integer): Integer; stdcall;
  TptSubscribeBroadcast = function(ExchangeName: ExchNamePtr): Integer; stdcall;
  TptUnsubscribeBroadcast = TptSubscribeBroadcast;
  TptCreateStrategy = function(StrategyCode: Char; NoOfLegs: Integer; ExchangeName: ExchNamePtr;
    ContractName: ConNamePtr; Legs: StrategyLegsStructPtr):Integer; stdcall;

  // APItrade
  TptCountFills = function(Count: IntegerPtr): Integer; stdcall;
  TptCountOrders = function(Count: IntegerPtr): Integer; stdcall;
  TptGetFill = function(Index: Integer; Fill: FillStructPtr): Integer; stdcall;
  TptGetFillByID = function(ID: FillIDPtr; Fill: FillStructPtr): Integer; stdcall;
  TptGetContractPosition = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr;
    ContractDate: ConDatePtr; TraderAccount: TraderPtr; Position: PositionStructPtr): Integer; stdcall;
  TptGetOpenPosition = TptGetContractPosition;
  TptGetTotalPosition = function(TraderAccount: TraderPtr; Position: PositionStructPtr): Integer; stdcall;
  TptGetAveragePrice = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr;
    ContractDate: ConDatePtr; TraderAccount: TraderPtr; Price: PricePtr): Integer; stdcall;
  TptGetOrder = function(Index: Integer; OrderDetail: OrderDetailStructPtr): Integer; stdcall;

  TptGetOrderEx = function(Index: Integer; OrderDetail: OrderDetailStructPtr; AlgoDetail: AlgoBuffPtr; AlgoSize: IntegerPtr): Integer; stdcall;

  TptGetOrderByID = function(OrderID: OrderIDPtr; OrderDetail: OrderDetailStructPtr; OFSeqNumber : integer = 0): Integer; stdcall;

  TptGetOrderByIDEx = function (OrderID: OrderIDPtr; OrderDetail: OrderDetailStructPtr; AlgoDetail: AlgoBuffPtr; AlgoSize: Integerptr; OFSequenceNumber : Integer = 0): Integer; stdcall;

  TptGetOrderIndex = function(OrderID: OrderIDPtr; Index: IntegerPtr): Integer; stdcall;

  TptBlankPrices = procedure; stdcall;
  TptGetPrice = function(Index: Integer; CurrentPrice: PriceStructPtr): Integer; stdcall;
  TptGetPriceForContract = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr;
    ContractDate: ConDatePtr; CurrentPrice: PriceStructPtr): Integer; stdcall;

  TptGetGenericPrice= function(ExchangeName: ExchNamePtr;ContractName: ConNamePtr; ContractDate: ConDatePtr;
    PriceType: integer; Side : integer; Price: PriceDetailStructPtr): Integer; stdcall;
  TptAddOrder = function (NewOrder: NewOrderStructPtr; OrderID: OrderIDPtr): Integer; stdcall;
  TptAddAlgoOrder = function (NewOrder: NewOrderStructPtr; BuffSize : integer; AlgoBuffer : AlgoBuff; OrderID: OrderIDPtr): Integer; stdcall;
  TptAddProtectionOrder = function(NewOrder: NewOrderStructPtr; Protection: ProtectionStrucPtr;
                                OrderID: OrderIDPtr): Integer; stdcall;
  TptAddBatchOrder = Function (OrderCount : Integer; BEPNewOrder : BEPNewOrderStructPtr; BEPOrderIDs : BEPOrderIDStructPtr; GroupID : OrderIDPtr): Integer; stdcall;
  TptAddAggregateOrder = function (NewAggOrder: NewAggOrderStructPtr; OrderID: OrderIDPtr): Integer; stdcall;
  TptAddCustRequest = function (NewCustReq: NewCustReqStructPtr; OrderID: OrderIDPtr): Integer; stdcall;
  TptReParent = function (OrderID, DestParentID: OrderIDPtr): Integer; stdcall;
  TptDoneForDay = function (OrderID: OrderIDPtr): Integer; stdcall;
  TptAmendOrder = function(OrderID: OrderIDPtr; NewDetails: AmendOrderStructPtr): Integer; stdcall;

  TptAmendAlgoOrder = function (OrderID: OrderIDPtr; BuffSize : integer; AlgoBuffer : AlgoBuff; NewDetails: AmendOrderStructPtr): Integer; stdcall;

  TptCancelOrder = function(OrderID: OrderIDPtr): Integer; stdcall;
  TptActivateOrder = function(OrderID: OrderIDPtr): Integer; stdcall;
  TptDeactivateOrder = function(OrderID: OrderIDPtr): Integer; stdcall;
  TptCancelBuys = function(TraderAccount: TraderPtr; ExchangeName: ExchNamePtr;
    ContractName: ConNamePtr; ContractDate: ConDatePtr): Integer; stdcall;
  TptCancelSells = TptCancelBuys;           
  TptCancelOrders = TptCancelBuys;
  TptCancelAll = function(TraderAccount: TraderPtr): Integer; stdcall;
  TptOrderChecked = function(OrderID: OrderIDPtr; Checked: Char): Integer; stdcall;
  TptQueryOrderStatus = TptCancelOrder;
  TptCountOrderHistory = function(Index: Integer; Count: IntegerPtr): Integer; stdcall;
  TptGetOrderHistory = function(Index, Position: Integer; OrderDetail: OrderDetailStructPtr): Integer; stdcall;

  TptGetOrderHistoryEx = function(Index, Position: Integer; OrderDetail: OrderDetailStructPtr; AlgoDetail: AlgoBuffPtr; AlgoSize: IntegerPtr): Integer; stdcall;

  TptSetUserIDFilter = function(Enabled: Char): Integer; stdcall;
  TptPLBurnRate = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr;
    ContractDate: ConDatePtr; TraderAccount: TraderPtr; BurnRate: FloatPtr):
    Integer; stdcall;
  TptOpenPositionExposure = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr;
    ContractDate: ConDatePtr; TraderAccount: TraderPtr; Exposure: FloatPtr):
    Integer; stdcall;
  TptBuyingPowerRemaining = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr;
    ContractDate: ConDatePtr; TraderAccount: TraderPtr; BPRemaining: FloatPtr):
    Integer; stdcall;
  TptBuyingPowerUsed = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr;
    ContractDate: ConDatePtr; TraderAccount: TraderPtr; BPUsed: FloatPtr):
    Integer; stdcall;
  TptMarginForTrade = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr; ContractDate: ConDatePtr;
    TraderAccount: TraderPtr; Lots: IntegerPtr; OrderID: OrderIDPtr; Price: PricePtr; MarginReqd: FloatPtr): Integer; stdcall;

  TptTotalMarginPaid = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr; ContractDate: ConDatePtr;
    TraderAccount: TraderPtr; MarginReqd: FloatPtr): Integer; stdcall;

  TptGetMarginPerLot = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr; ContractDate: ConDatePtr;
    TraderAccount: TraderPtr; Margin: FloatPtr): Integer; stdcall;
  
  TptNextOrderSequence = function(Count: IntegerPtr): Integer; stdcall;

  TptGetOptionPremium = function(ExchangeName: ExchNamePtr; ContractName: ConNamePtr;
    ContractDate: ConDatePtr; BuySell: Char; Price: PricePtr; Lots: Integer; OPr: FloatPtr): Integer; stdcall;

  // Wholesale Trade
  TptAddCrossingOrder = function (PrimaryOrder,SecondaryOrder :NewOrderStructPtr; LegPrices: LegPriceStructPtr;
    OrderIDs: CrossingOrderIDsPtr; FAK : Char = 'L'):Integer;stdCall;
  TptAddBlockOrder = function (PrimaryOrder, SecondaryOrder: NewOrderStructPtr; LegPrices: LegPriceStructPtr;
    OrderIDs: CrossingOrderIDsPtr): Integer; stdcall;
  TptAddBasisOrder = function (PrimaryOrder, SecondaryOrder: NewOrderStructPtr; BasisOrder: BasisOrderStructPtr;
   OrderID: CrossingOrderIDsPtr): Integer; stdcall;
  TptAddAAOrder = function (PrimaryOrder, SecondaryOrder: NewOrderStructPtr; BidUser, OfferUser: UserNameStrPtr;
    OrderID: CrossingOrderIDsPtr): Integer; stdcall;
  TptgetConsolidatedPosition = function(Exchange: ExchNamePtr; ContractName: ConNamePtr;
                                      ContractDate: CondatePtr; TraderAccount: TraderPtr;
                                      PositionType: integer; fill: FillStructPtr): integer; stdcall;

  // APIuser
  TptLogOn = function(LogonDetails: LogonStructPtr): Integer; stdcall;
  TptLogOff = function: Integer; stdcall;
  TptGetLogonStatus = function(LogonStatus: LogonStatusStructPtr): Integer; stdcall;
  TptDOMEnabled = function: Integer; stdcall;
  TptPostTradeAmendEnabled = function: Integer; stdcall;
  TptEnabledFunctionality = function(FunctionalityEnabled, SoftwareEnabled: IntegerPtr): Integer; stdcall;
  TptCountUsrMsgs = function(Count: IntegerPtr): Integer; stdcall;
  TptGetUsrMsg = function(Index: Integer; UserMsg: MessageStructPtr): Integer; stdcall;
  TptGetUsrMsgByID = function(MsgID: MsgIDPtr; UserMsg: MessageStructPtr): Integer; stdcall;
  TptAcknowledgeUsrMsg = function(MsgID: MsgIDPtr): Integer; stdcall;

  // APIPriceStep
  TptPriceStep = function(Price: double; TickSize: double; NumSteps: Integer;
    TicksPerPoint: Integer): double; stdcall;

  TptLockUpdates = function : integer; stdcall;
  TptUnlockUpdates = function : integer; stdcall;


// ***** Variable declarations *****
var
  // APIcallback
  ptRegisterCallback:                   TptRegisterCallback;
  ptRegisterLinkStateCallback:          TptRegisterLinkStateCallback;
  ptRegisterMsgCallback:                TptRegisterMsgCallback;
  ptRegisterOrderCallback:              TptRegisterOrderCallback;
  ptRegisterFillCallback:               TptRegisterFillCallback;
  ptRegisterPriceCallback:              TptRegisterPriceCallback;
  ptRegisterBlankPriceCallback:         TptRegisterBlankPriceCallback;
  ptRegisterGenericPriceCallback:       TptRegisterGenericPriceCallback;
  ptRegisterDOMCallback:                TptRegisterDOMCallback;
  ptRegisterContractCallback:           TptRegisterContractCallback;
  ptRegisterCommodityCallback:          TptRegisterCommodityCallback;
  ptRegisterExchangeCallback:           TptRegisterExchangeCallback;
  ptRegisterStatusCallback:             TptRegisterStatusCallback;
  ptRegisterExchangeRateCallback:       TptRegisterExchangeRateCallback;
  ptRegisterConStatusCallback:          TptRegisterConStatusCallback;
  ptRegisterOrderCancelFailureCallback: TptRegisterOrderCancelFailureCallback;
  ptRegisterOrderSentFailureCallback:   TptRegisterOrderSentFailureCallback;
  ptRegisterOrderQueuedFailureCallback: TptRegisterOrderQueuedFailureCallback;
  ptRegisterAtBestCallback:             TptRegisterAtBestCallback;
  ptRegisterTickerCallback:             TptRegisterTickerCallback;
  ptRegisterSubsciberDepthCallback:     TptRegisterSubscriberDepthCallback;
  ptRegisterAmendFailureCallback:       TptRegisterAmendFailureCallback;
  ptRegisterSettlementCallback:         TptRegisterSettlementCallback;
  ptRegisterStrategyCreateFailure:      TptRegisterStrategyCreateFailure;
  ptRegisterStrategyCreateSuccess:      TptRegisterStrategyCreateSuccess;
  ptRegisterOrderBookReset:             TptRegisterOrderBookReset;
  ptregisterTraderAddedCallback:        TptRegisterTraderAddedCallback;
  ptRegisterOrderTypeUpdateCallback:    TptRegisterOrderTypeUpdateCallback;

  ptCountExchanges:             TptCountExchanges;
  ptGetExchange:                TptGetExchange;
  ptGetExchangeByName:          TptGetExchangeByName;
  ptExchangeExists:             TptExchangeExists;
  ptCountTraders:               TptCountTraders;
  ptGetTrader:                  TptGetTrader;
  ptGetTraderByName:            TptGetTraderByName;
  ptTraderExists:               TptTraderExists;
  ptCountOrderTypes:            TptCountOrderTypes;
  ptGetOrderType:               TptGetOrderType;
  ptGetExchangeRate:            TptGetExchangeRate;
  ptCountReportTypes:           TptCountReportTypes;
  ptGetReportType:              TptGetReportType;
  ptReportTypeExists:           TptReportTypeExists;
  ptGetReportSize:              TptGetReportSize;
  ptGetReport:                  TptGetReport;
  ptCountCommodities:           TptCountCommodities;
  ptGetCommodity:               TptGetCommodity;
  ptCommodityExists:            TptCommodityExists;
  ptGetCommodityByName:         TptGetCommodityByName;
  ptCountContracts:             TptCountContracts;
  ptGetContract:                TptGetContract;
  ptGetContractByName:          TptGetContractByName;
  ptGetContractByExternalID:    TptGetContractByExternalID;
  ptGetExtendedContract:        TptGetExtendedContract;
  ptGetExtendedContractByName:  TptGetExtendedContractByName;
  ptContractExists:             TptContractExists;
  ptCountContractAtBest:        TptCountContractAtBest;
  ptGetContractAtBest:          TptGetContractAtBest;
  ptGetContractAtBestPrices:    TptGetContractAtBestPrices;
  ptCountContractSubscriberDepth: TptCountContractSubscriberDepth;
  ptGetContractSubscriberDepth: TptGetContractSubscriberDepth;

  ptInitialise:                 TptInitialise;
  ptGetAPIBuildVersion:         TptGetAPIBuildVersion;
  ptReady:                      TptReady;
  ptPurge:                      TptPurge;
  ptDisconnect:                 TptDisconnect;
  ptSetHostAddress:             TptSetHostAddress;
  ptSetPriceAddress:            TptSetPriceAddress;
  ptEnable:                     TptEnable;
  ptDisable:                    TptDisable;
  ptLogString:                  TptLogString;
  ptOMIEnabled:                 TptOMIEnabled;
  ptNotifyAllMessages:          TptNotifyAllMessages;
  ptSetHostReconnect:           TptSetHostReconnect;
  ptSetPriceReconnect:          TptSetPricereconnect;
  ptSetPriceAgeCounter:         TptSetPriceAgeCounter;
  ptSubscribePrice:             TptSubscribePrice;
  ptSubscribeToMarket:          TptSubscribeToMarket;
  ptUnsubscribePrice:           TptUnsubscribePrice;
  ptUnsubscribeToMarket:        TptUnsubscribeToMarket;
  ptPriceSnapshot:              TptPriceSnapshot;
  ptSetEncryptionCode:          TptSetEncryptionCode;
  ptSetHandShakePeriod:         TptSetHandShakePeriod;
  ptSetHostHandShake:           TptSetHostHandShake;
  ptSetPriceHandShake:          TptSetPriceHandShake;
  ptSetInternetUser:            TptSetInternetUser;
  ptSetClientPath:              TptSetClientPath;
  ptAPIGetErrorMessage:         TptGetErrorMessage;    //NOTE: Should be a different name
  ptDumpLastError:              TptDumpLastError;
  ptSnapdragonEnabled:          TptSnapDragonEnabled;
  ptSetOrderCancelFailureDelay: TptSetOrderCancelFailureDelay;
  ptSetOrderSentFailureDelay:   TptSetOrderSentFailureDelay;
  ptSetOrderQueuedFailureDelay: TptSetOrderQueuedFailureDelay;
  ptSuperTASEnabled:            TptSuperTASEnabled;
  ptSetSSL:                     TptSetSSL;
  ptSetPDDSSL:                     TptSetSSL;
  ptSetSSLCertificateName:      TptSetSSLCertificateName;
  ptSetPDDSSLCertificateName:      TptSetSSLCertificateName;
  ptSetSSLClientAuthName:       TptSetSSLClientAuthName;
  ptSetPDDSSLClientAuthName:       TptSetSSLClientAuthName;
  ptSetMDSToken:                TptSetMDSToken;
  ptSetSuperTAS:                TptSetSuperTAS;
  ptSetMemoryWarning:           TptSetMemoryWarning;
  ptSubscribeBroadcast:         TptSubscribeBroadcast;
  ptUnsubscribeBroadcast:       TptUnsubscribeBroadcast;
  ptCreateStrategy:             TptCreateStrategy;

  ptCountFills:                 TptCountFills;
  ptCountOrders:                TptCountOrders;
  ptGetFill:                    TptGetFill;
  ptGetFillByID:                TptGetFillByID;
  ptGetContractPosition:        TptGetContractPosition;
  ptGetOpenPosition:            TptGetOpenPosition;
  ptGetTotalPosition:           TptGetTotalPosition;
  ptGetAveragePrice:            TptGetAveragePrice;
  ptGetOrder:                   TptGetOrder;

  ptGetOrderEx:                 TptGetOrderEx;

  ptGetOrderByID:               TptGetOrderByID;

  ptGetOrderByIDEx:             TptGetOrderByIDEx;

  ptGetOrderIndex:              TptGetOrderIndex;
  ptBlankPrices:                TptBlankPrices;
  ptGetPrice:                   TptGetPrice;
  ptGetPriceForContract:        TptGetPriceForContract;
  ptGetGenericPrice:            TptGetGenericPrice;
  ptAddOrder:                   TptAddOrder;
  ptAddAlgoOrder:               TptAddAlgoOrder;
  ptAddProtectionOrder:         TptAddProtectionOrder;
  ptAddBatchOrder:              TptAddBatchOrder;
  ptAddAggregateOrder:          TptAddAggregateOrder;
  ptAddCustRequest:             TptAddCustRequest;
  ptReParent:                   TptReParent;
  ptDoneForDay:                 TptDoneForDay;
  ptAmendOrder:                 TptAmendOrder;

  ptAmendAlgoOrder:             TptAmendAlgoOrder;
  ptgetConsolidatedPosition:    TptgetConsolidatedPosition;
  ptCancelOrder:                TptCancelOrder;
  ptActivateOrder:              TptActivateOrder;
  ptDeactivateOrder:            TptDeactivateOrder;
  ptCancelBuys:                 TptCancelBuys;
  ptCancelSells:                TptCancelSells;
  ptCancelOrders:               TptCancelOrders;
  ptCancelAll:                  TptCancelAll;
  ptOrderChecked:               TptOrderChecked;
  ptQueryOrderStatus:           TptQueryOrderStatus;
  ptCountOrderHistory:          TptCountOrderHistory;
  ptGetOrderHistory:            TptGetOrderHistory;


  ptGetOrderHistoryEx:          TptGetOrderHistoryEx;

  ptSetUserIDFilter:            TptSetUserIDFilter;
  ptPLBurnRate:                 TptPLBurnRate;
  ptOpenPositionExposure:       TptOpenPositionExposure;
  ptBuyingPowerRemaining:       TptBuyingPowerRemaining;
  ptBuyingPowerUsed:            TptBuyingPowerUsed;
  ptMarginForTrade:             TptMarginForTrade;
  ptGetMarginPerLot:            TptGetMarginPerLot;
  ptTotalMarginPaid:            TptTotalMarginPaid;
  ptNextOrderSequence:          TptNextOrderSequence;
  ptGetOptionPremium:           TptGetOptionPremium;
  ptAddCrossingOrder:           TptAddCrossingOrder;
  ptAddBlockOrder:              TptAddBlockOrder;
  ptAddBasisOrder:              TptAddBasisOrder;
  ptAddAAOrder:                 TptAddAAOrder;


  ptLogOn:                      TptLogOn;
  ptLogOff:                     TptLogOff;
  ptGetLogonStatus:             TptGetLogonStatus;
  ptDOMEnabled:                 TptDOMEnabled;
  ptPostTradeAmendEnabled:      TptPostTradeAmendEnabled;
  ptEnabledFunctionality:       TptEnabledFunctionality;

  ptCountUsrMsgs:               TptCountUsrMsgs;
  ptGetUsrMsg:                  TptGetUsrMsg;
  ptGetUsrMsgByID:              TptGetUsrMsgByID;
  ptAcknowledgeUsrMsg:          TptAcknowledgeUsrMsg;

  ptPriceStep:                  TptPriceStep;

  ptLockUpdates :               TptLockUpdates;
  ptUnlockUpdates :             TptUnlockUpdates;

  LastAddr: Byte;

  Handle: Integer = 0;

function  ptGetErrorMessage(Error: Integer): PChar;
procedure ptLoadAPI(const Filename: String);
procedure ptUnloadAPI(Var Status: String);
procedure ptCheckAPILoaded;

{$ENDIF}
{$ENDIF}

implementation

{$IFNDEF API_INTERNAL}
{$IFDEF DYNAMIC}

uses Windows;

// EPATS
Var
  Status: string;

constructor EPATS.Create(Error: Integer);
begin
  FError := Error;
  inherited Create('PATS API Error: ' + IntToStr(Error));
end;

function ptGetErrorMessage(Error: Integer): PChar;
begin
  if Error in [ptErrLibNotLoaded..ptErrLastDynamic] then
    Result := DynamicMessages[Error]
  else if not Assigned(ptAPIGetErrorMessage) then
    Result := 'Dynamic API Error - ptGetErrorMessage not Assigned'
  else
    Result := ptAPIGetErrorMessage(Error);
end;

procedure Clear;
var Addr, Size: Integer;
begin
  Addr := Integer(@@ptRegisterCallback);
  Size := Integer(@LastAddr) - Addr;
  ZeroMemory(Pointer(Addr),Size);
end;

procedure RegisterProc(var Routine; Name: String);
begin
  Pointer(Routine) := GetProcAddress(Handle,PChar(Name));
  if not Assigned(Pointer(Routine)) then
  begin
    // VM 04/11/2008 - hum..... messagebox... right!
    //MessageBox(0,PChar('Can''t find ' + Name),'Error',MB_ICONERROR);
    raise EPATS.Create(ptErrBadLib);
  end;
end;

procedure ptLoadAPI(const Filename: String);
var
  i: Integer;
begin

  // This allows a previous instance of the applet to unload (within 10 secs)
  i := 100;
  while Handle <> 0 do
  begin
    Sleep(100);
    Dec(i);
    if i = 0 then
      raise EPATS.Create(ptErrLibLoaded);
  end;

  Handle := LoadLibrary(PChar(Filename));
  if Handle = 0 then
    raise EPATS.Create(ptErrCantLoad);

  Clear;
  try
    // APIcallback

    RegisterProc(ptRegisterCallback, 'ptRegisterCallback');
    RegisterProc(ptRegisterLinkStateCallback, 'ptRegisterLinkStateCallback');
    RegisterProc(ptRegisterMsgCallback, 'ptRegisterMsgCallback');
    RegisterProc(ptRegisterOrderCallback, 'ptRegisterOrderCallback');
    RegisterProc(ptRegisterFillCallback, 'ptRegisterFillCallback');
    RegisterProc(ptRegisterPriceCallback, 'ptRegisterPriceCallback');
    RegisterProc(ptRegisterBlankPriceCallback, 'ptRegisterBlankPriceCallback');
    RegisterProc(ptRegisterGenericPriceCallback, 'ptRegisterGenericPriceCallback');
    RegisterProc(ptRegisterDOMCallback, 'ptRegisterDOMCallback');
    RegisterProc(ptRegisterContractCallback, 'ptRegisterContractCallback');
    RegisterProc(ptRegisterCommodityCallback, 'ptRegisterCommodityCallback');
    RegisterProc(ptRegisterExchangeCallback, 'ptRegisterExchangeCallback');
    RegisterProc(ptRegisterStatusCallback, 'ptRegisterStatusCallback');
    RegisterProc(ptRegisterExchangeRateCallback, 'ptRegisterExchangeRateCallback');
    RegisterProc(ptRegisterConStatusCallback, 'ptRegisterConStatusCallback');
    RegisterProc(ptRegisterOrderCancelFailureCallback, 'ptRegisterOrderCancelFailureCallback');
    RegisterProc(ptRegisterOrderSentFailureCallback, 'ptRegisterOrderSentFailureCallback');
    RegisterProc(ptRegisterOrderQueuedFailureCallback, 'ptRegisterOrderQueuedFailureCallback');
    RegisterProc(ptRegisterAtBestCallback, 'ptRegisterAtBestCallback');
    RegisterProc(ptGetContractAtBestPrices, 'ptGetContractAtBestPrices');
    RegisterProc(ptRegisterTickerCallback, 'ptRegisterTickerCallback');
    RegisterProc(ptRegisterSubsciberDepthCallback, 'ptRegisterSubscriberDepthCallback');
    RegisterProc(ptRegisterAmendFailureCallback, 'ptRegisterAmendFailureCallback');
    RegisterProc(ptRegisterSettlementCallback, 'ptRegisterSettlementCallback');
    RegisterProc(ptRegisterStrategyCreateSuccess, 'ptRegisterStrategyCreateSuccess');
    RegisterProc(ptRegisterStrategyCreateFailure, 'ptRegisterStrategyCreateFailure');
    RegisterProc(ptRegisterOrderBookReset, 'ptRegisterOrderBookReset');
    RegisterProc(ptRegisterTraderAddedCallback, 'ptRegisterTraderAddedCallback');
    RegisterProc(ptRegisterOrderTypeUpdateCallback, 'ptRegisterOrderTypeUpdateCallback');

    // APIrefdata


    RegisterProc(ptCountExchanges, 'ptCountExchanges');
    RegisterProc(ptGetExchange, 'ptGetExchange');
    RegisterProc(ptGetExchangeByName, 'ptGetExchangeByName');
    RegisterProc(ptExchangeExists, 'ptExchangeExists');
    RegisterProc(ptCountTraders, 'ptCountTraders');
    RegisterProc(ptGetTrader, 'ptGetTrader');
    RegisterProc(ptGetTraderByName, 'ptGetTraderByName');
    RegisterProc(ptTraderExists, 'ptTraderExists');
    RegisterProc(ptCountOrderTypes, 'ptCountOrderTypes');
    RegisterProc(ptGetOrderType, 'ptGetOrderType');
    RegisterProc(ptGetExchangeRate, 'ptGetExchangeRate');
    RegisterProc(ptCountReportTypes, 'ptCountReportTypes');
    RegisterProc(ptGetReportType, 'ptGetReportType');
    RegisterProc(ptReportTypeExists, 'ptReportTypeExists');
    RegisterProc(ptGetReportSize, 'ptGetReportSize');
    RegisterProc(ptGetReport, 'ptGetReport');
    RegisterProc(ptCountCommodities, 'ptCountCommodities');
    RegisterProc(ptGetCommodity, 'ptGetCommodity');
    RegisterProc(ptCommodityExists, 'ptCommodityExists');
    RegisterProc(ptGetCommodityByName, 'ptGetCommodityByName');
    RegisterProc(ptCountContracts, 'ptCountContracts');
    RegisterProc(ptGetContract, 'ptGetContract');
    RegisterProc(ptGetContractByName, 'ptGetContractByName');
    RegisterProc(ptGetContractByExternalID, 'ptGetContractByExternalID');
    RegisterProc(ptGetExtendedContract, 'ptGetExtendedContract');
    RegisterProc(ptGetExtendedContractByName, 'ptGetExtendedContractByName');
    RegisterProc(ptContractExists, 'ptContractExists');
    RegisterProc(ptCountContractAtBest, 'ptCountContractAtBest');
    RegisterProc(ptGetContractAtBest, 'ptGetContractAtBest');
    RegisterProc(ptGetContractAtBestPrices, 'ptGetContractAtBestPrices');
    RegisterProc(ptCountContractSubscriberDepth, 'ptCountContractSubscriberDepth');
    RegisterProc(ptGetContractSubscriberDepth, 'ptGetContractSubscriberDepth');

    // APIsetup


    RegisterProc(ptInitialise, 'ptInitialise');
    RegisterProc(ptGetAPIBuildVersion, 'ptGetAPIBuildVersion');
    RegisterProc(ptReady, 'ptReady');
    RegisterProc(ptPurge, 'ptPurge');
    RegisterProc(ptDisconnect, 'ptDisconnect');
    RegisterProc(ptSetHostAddress, 'ptSetHostAddress');
    RegisterProc(ptSetPriceAddress, 'ptSetPriceAddress');
    RegisterProc(ptEnable, 'ptEnable');
    RegisterProc(ptDisable, 'ptDisable');
    RegisterProc(ptLogString, 'ptLogString');
    RegisterProc(ptOMIEnabled, 'ptOMIEnabled');
    RegisterProc(ptNotifyAllMessages, 'ptNotifyAllMessages');
    RegisterProc(ptSetHostReconnect, 'ptSetHostReconnect');
    RegisterProc(ptSetPriceReconnect, 'ptSetPriceReconnect');
    RegisterProc(ptSetPriceAgeCounter, 'ptSetPriceAgeCounter');
    RegisterProc(ptSubscribePrice, 'ptSubscribePrice');
    RegisterProc(ptSubscribeToMarket, 'ptSubscribeToMarket');
    RegisterProc(ptUnsubscribePrice, 'ptUnsubscribePrice');
    RegisterProc(ptUnsubscribeToMarket, 'ptUnsubscribeToMarket');
    RegisterProc(ptPriceSnapshot, 'ptPriceSnapshot');
    RegisterProc(ptSetEncryptionCode, 'ptSetEncryptionCode');
    RegisterProc(ptSetHandShakePeriod, 'ptSetHandShakePeriod');
    RegisterProc(ptSetHostHandShake, 'ptSetHostHandShake');
    RegisterProc(ptSetPriceHandShake, 'ptSetPriceHandShake');
    RegisterProc(ptSetInternetUser, 'ptSetInternetUser');
    RegisterProc(ptSetClientPath, 'ptSetClientPath');
    RegisterProc(ptAPIGetErrorMessage, 'ptGetErrorMessage');   //NOTE: Should be different
    RegisterProc(ptDumpLastError, 'ptDumpLastError');
    RegisterProc(ptSnapdragonEnabled, 'ptSnapdragonEnabled');
    RegisterProc(ptSetOrderCancelFailureDelay, 'ptSetOrderCancelFailureDelay');
    RegisterProc(ptSetOrderSentFailureDelay, 'ptSetOrderSentFailureDelay');
    RegisterProc(ptSetOrderQueuedFailureDelay, 'ptSetOrderQueuedFailureDelay');
    RegisterProc(ptSuperTASEnabled, 'ptSuperTASEnabled');
    RegisterProc(ptSetSSL, 'ptSetSSL');
    RegisterProc(ptSetPDDSSL, 'ptSetPDDSSL');
    RegisterProc(ptSetPDDSSLCertificateName, 'ptSetPDDSSLCertificateName');
    RegisterProc(ptSetPDDSSLClientAuthName, 'ptSetPDDSSLClientAuthName');
    RegisterProc(ptSetSSLCertificateName, 'ptSetSSLCertificateName');
    RegisterProc(ptSetSSLClientAuthName, 'ptSetSSLClientAuthName');
    RegisterProc(ptSetMDSToken, 'ptSetMDSToken');
    RegisterProc(ptSetSuperTAS, 'ptSetSuperTAS');
    RegisterProc(ptSetMemoryWarning, 'ptSetMemoryWarning');
    RegisterProc(ptSubscribeBroadcast, 'ptSubscribeBroadcast');
    RegisterProc(ptUnsubscribeBroadcast, 'ptUnsubscribeBroadcast');
    RegisterProc(ptCreateStrategy, 'ptCreateStrategy');
    RegisterProc(ptPurge, 'ptPurge');

    // APItrade
    RegisterProc(ptCountFills, 'ptCountFills');
    RegisterProc(ptCountOrders, 'ptCountOrders');
    RegisterProc(ptGetFill, 'ptGetFill');
    RegisterProc(ptGetFillByID, 'ptGetFillByID');
    RegisterProc(ptGetContractPosition, 'ptGetContractPosition');
    RegisterProc(ptGetOpenPosition, 'ptGetOpenPosition');
    RegisterProc(ptGetTotalPosition, 'ptGetTotalPosition');
    RegisterProc(ptGetAveragePrice, 'ptGetAveragePrice');
    RegisterProc(ptGetOrder, 'ptGetOrder');

    RegisterProc(ptGetOrderEx, 'ptGetOrderEx');

    RegisterProc(ptGetOrderByID, 'ptGetOrderByID');

    RegisterProc(ptGetOrderByIDEx, 'ptGetOrderByIDEx');

    RegisterProc(ptGetOrderIndex, 'ptGetOrderIndex');
    RegisterProc(ptBlankPrices, 'ptBlankPrices');
    RegisterProc(ptGetPrice, 'ptGetPrice');
    RegisterProc(ptGetPriceForContract, 'ptGetPriceForContract');
    RegisterProc(ptGetGenericPrice, 'ptGetGenericPrice');
    RegisterProc(ptAddOrder, 'ptAddOrder');
    RegisterProc(ptAddAlgoOrder, 'ptAddAlgoOrder');
    RegisterProc(ptAddProtectionOrder, 'ptAddProtectionOrder');
    RegisterProc(ptAddBatchOrder, 'ptAddBatchOrder');
    RegisterProc(ptAddAggregateOrder, 'ptAddAggregateOrder');
    RegisterProc(ptAddCustRequest, 'ptAddCustRequest');
    RegisterProc(ptReParent, 'ptReParent');
    RegisterProc(ptDoneForDay, 'ptDoneForDay');
    RegisterProc(ptDoneForDay, 'ptDoneForDay');
    RegisterProc(ptAmendOrder, 'ptAmendOrder');

    RegisterProc(ptAmendAlgoOrder, 'ptAmendAlgoOrder');

    RegisterProc(ptCancelOrder, 'ptCancelOrder');
    RegisterProc(ptActivateOrder, 'ptActivateOrder');
    RegisterProc(ptDeactivateOrder, 'ptDeactivateOrder');
    RegisterProc(ptCancelBuys, 'ptCancelBuys');
    RegisterProc(ptCancelSells, 'ptCancelSells');
    RegisterProc(ptCancelOrders, 'ptCancelOrders');
    RegisterProc(ptCancelAll, 'ptCancelAll');
    RegisterProc(ptOrderChecked, 'ptOrderChecked');
    RegisterProc(ptQueryOrderStatus, 'ptQueryOrderStatus');
    RegisterProc(ptCountOrderHistory, 'ptCountOrderHistory');
    RegisterProc(ptGetOrderHistory, 'ptGetOrderHistory');

    RegisterProc(ptGetOrderHistoryEx, 'ptGetOrderHistoryEx');

    RegisterProc(ptSetUserIDFilter, 'ptSetUserIDFilter');
    RegisterProc(ptPLBurnRate, 'ptPLBurnRate');
    RegisterProc(ptOpenPositionExposure, 'ptOpenPositionExposure');
    RegisterProc(ptBuyingPowerRemaining, 'ptBuyingPowerRemaining');
    RegisterProc(ptBuyingPowerUsed, 'ptBuyingPowerUsed');
    RegisterProc(ptMarginForTrade, 'ptMarginForTrade');
    RegisterProc(ptTotalMarginPaid, 'ptTotalMarginPaid');
    RegisterProc(ptGetMarginPerLot,'ptGetMarginPerLot');
    RegisterProc(ptNextOrderSequence, 'ptNextOrderSequence');
    RegisterProc(ptGetOptionPremium, 'ptGetOptionPremium');
    RegisterProc(ptAddCrossingOrder, 'ptAddCrossingOrder');
    RegisterProc(ptAddBlockOrder, 'ptAddBlockOrder');
    RegisterProc(ptAddBasisOrder, 'ptAddBasisOrder');
    RegisterProc(ptAddAAOrder, 'ptAddAAOrder');
    RegisterProc(ptgetConsolidatedPosition, 'ptgetConsolidatedPosition');

    // APIuser

    RegisterProc(ptLogOn, 'ptLogOn');
    RegisterProc(ptLogOff, 'ptLogOff');
    RegisterProc(ptGetLogonStatus, 'ptGetLogonStatus');
    RegisterProc(ptDOMEnabled, 'ptDOMEnabled');
    RegisterProc(ptPostTradeAmendEnabled, 'ptPostTradeAmendEnabled');
    RegisterProc(ptEnabledFunctionality, 'ptEnabledFunctionality');
    RegisterProc(ptCountUsrMsgs, 'ptCountUsrMsgs');
    RegisterProc(ptGetUsrMsg, 'ptGetUsrMsg');
    RegisterProc(ptGetUsrMsgByID, 'ptGetUsrMsgByID');
    RegisterProc(ptAcknowledgeUsrMsg, 'ptAcknowledgeUsrMsg');

    // APIPriceStep
    RegisterProc(ptPriceStep, 'ptPriceStep');

    RegisterProc(ptLockUpdates, 'ptLockUpdates');
    RegisterProc(ptUnlockUpdates, 'ptUnlockUpdates');
  except
    ptUnloadAPI(Status);
    raise;
  end;
end;

//Cjp
//added exception handlers in the event web launch for
//j-trader logon screen hangs on closedown.
procedure ptUnloadAPI(Var Status: String);
begin
  if Handle <> 0 then
  begin
    try
      Clear;
    Except On E: Exception Do
    begin
      Status := 'ptUnload Clear Process:- failed to unload callback memory '+ E.Message;
      Handle := 0;
    end;
    end;
    try
      FreeLibrary(Handle);
    Except On E: Exception Do
    begin
      Status := 'ptUnload FreeLibrary :- failed to free library '+ E.Message;
      Handle := 0;
    end;
    end;

  end;
end;

procedure ptCheckAPILoaded;
begin
  if Handle = 0 then
    raise EPats.Create(ptErrLibNotLoaded);
end;

initialization

finalization

  ptUnloadAPI(Status);
{$ENDIF}   // DYNAMIC
{$ENDIF}   // INTERNAL_API

end.



