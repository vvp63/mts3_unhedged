unit servertypes;

interface

{$A-}

const srvversion          = 9;                               // ������ �������

const msgKot              = $00;                             // ���� �������� �������
      msgSetOrd           = $01;
      msgEditOrd          = $02;
      msgDropOrd          = $03;
      msgAllTrades        = $04;
      msgQueryReport      = $05;
      msgQueryTrades      = $06;
      msgAllTradesReq     = $07;

const opNormal            = $00000000;                       // ���� ������
      opImmCancel         = $00000001;
      opMarketPrice       = $00000002;
      opWDRest            = $00000004;
      opDelayed           = $00000008;
      opMarging           = $00000010;
      opRpsDeal           = $00000020;
      opAuct              = $00000040;
      opRepoDeal          = $00000080;
      opCCP               = $00000100;

const errNoErrors         = $00;
      errSetOrderOK       = $01;
      errDropOrderOK      = $02;
      errEditOrderOK      = $03;
      errUnsupportedFn    = $04;
      errUnknownAccnt     = $05;
      errInvalidAccnt     = $06;
      errNoMoney          = $07;
      errInvalidDropPk    = $08;
      errNotEncrypted     = $09;
      errInvalidStock     = $0a;
      errDecryptFail      = $0b;
      errStockUnavail     = $0c;
      errDemoUser         = $0d;
      errMarginDisabled   = $0e;
      errNoSuchOrder      = $0f;
      errDecompressFail   = $10;
      errMonitorMode      = $11;
      errMarginLimit      = $12;
      errBCaseDemoLimit   = $13;
      errWaitTrades       = $14;
      errInvalidPeriod    = $15;
      errUnknownTrans     = $16;
      errFrozenAccnt      = $17;
      errRepoNotAllowed   = $18;
      errBrokerLimit      = $19;
      errNotAllowed       = $1a;
      errInvalidMarginAcc = $1b;
      errIncompleteTrs    = $1c;
      errUnsupportedStop  = $1d;
      errNotLiquid        = $1e;
      errStockReply       = $ff;

const soAccepted          = $00;                             // ������ ����������
      soRejected          = $01;                             // ������ ���������
      soUnknown           = $02;                             // ����������� ���������
      soDropAccepted      = $03;                             // ������ �����
      soDropRejected      = $04;                             // ������ ������ ���������
      soError             = $ff;                             // ������ ����������

const maxDropOrders       = 7;                               // ����. ���������� ������ ��� ������ � ��������� tClientQuery

const stockNone           = $00;
      stockView           = $01;
      stockWork           = $02;

const sfAddToList         = $00;                             // �������� � ������ �������� ��� ����������
      sfDelFromList       = $01;                             // ������� �� ������ �������� ��� ����������
      sfSendOnly          = $02;                             // �� ������� ������, ������ �������

const sfSendKot           = $01;
      sfSendAllTrades     = $02;
      sfSendSecurities    = $04;

const dayWasOpened        = $01;                             // ������ ���� �������
      dayWasClosed        = $02;                             // ������ ���� �������

                                                             // ������� ���������� ����-������
const stopLowerOrEqual    = $00;                             // lowoffer        <= value
      stopHigherOrEqual   = $01;                             // hibid           >= value

      stopOfferLOE        = stopLowerOrEqual;                // lowoffer        <= value
      stopOfferHOE        = $02;                             // lowoffer        >= value
      stopBidLOE          = $03;                             // hibid           <= value
      stopBidHOE          = stopHigherOrEqual;               // hibid           >= value
      stopLastSecLOE      = $04;                             // lastprice       <= value
      stopLastSecHOE      = $05;                             // lastprice       >= value

      stopLastAllTrdLOE   = $06;                             // alltrades.price <= value
      stopLastAllTrdHOE   = $07;                             // alltrades.price >= value

const dropNormalOrders    = $0000;                           // ����� �������� ������� ������ ��� ������
      dropStopOrders      = $0001;                           // ����� �������� ����-������ ��� ������

const newsQueryByDate     = $0000;                           // ������ ��������������� �������� �� ����
      newsQueryByID       = $0001;                           // ������ ��������������� �������� �� ������
      newsQueryText       = $0002;                           // ������ ������ ������� �� ��������������

const marginNormal        = $0000;                           // ���������� �.�.
      marginBelowNormal   = $0001;                           // �.�. ���� �����������
      marginBelowWarning  = $0002;                           // �.�. ���� ������������������
      marginBelowCritical = $0003;                           // �.�. ���� ������������

const levelShares         = $0000;                           // �����
      levelBonds          = $0001;                           // ���������
      levelFutures        = $0002;                           // ��������
      levelOptions        = $0003;                           // �������

const acntViewOnly        = $0000;                           // ���� ������ ��� ���������
      acntAllowTrade      = $0001;                           // ��������� ��������
      acntAllowMargin     = $0002;                           // �������� �������

const acnttypeNormal      = $0000;                           // ������� ����
      acnttypePrepared    = $0001;                           // ���� �������������� �� �����

type  tTransactionID      = longint;

type  pTrsQueryID         = ^tTrsQueryID;
      tTrsQueryID         = int64;

type  pClientID           = ^tClientID;
      tClientID           = string[5];                       // ������������� �������

type  pAccount            = ^tAccount;
      tAccount            = string[20];                      // ���� �������

type  pMarketCode         = ^tMarketCode;
      tMarketCode         = string[3];                       // ��� �����

type  pLevel              = ^tLevel;
      tLevel              = string[4];                       // ��� ������

type  pCode               = ^tCode;                          // ��� ������
      tCode               = string[20];

type  pShortName          = ^tShortName;                     // ������������ ������
      tShortName          = string[20];

type  pComment            = ^tComment;                       // �����������
      tComment            = string[30];

type  pUserName           = ^tUserName;                      // ��� ������������
      tUserName           = string[20];

type  pSettleCode         = ^tSettleCode;                    // ��� ��������
      tSettleCode         = string[3];

type  pSecIdent           = ^tSecIdent;
      tSecIdent           = record
       stock_id           : longint;                         // �����. �������� ��������
       level              : tLevel;                          // ��� ������ ������
       code               : tCode;                           // ���������� ��� ������ ������
      end;

type  pBoardIdent         = ^tBoardIdent;
      tBoardIdent         = record
       stock_id           : longint;                         // �����. �������� ��������
       level              : tLevel;                          // ��� ������ ������
      end;

type  pSettleCodes        = ^tSettleCodes;
      tSettleCodes        = record
       stock_id           : longint;
       settlecode         : tSettleCode;
       description        : string[40];
       settledate1        : tDateTime;
       settledate2        : tDateTime;
      end;

type  tFirmSet            = set of (fid_stock_id, fid_firmid, fid_firmname, fid_status);

type  pFirmIdent          = ^tFirmIdent;
      tFirmIdent          = record
       stock_id           : longint;
       firmid             : string[20];
       firmname           : string[40];
       status             : char;
      end;

type  pFirmItem           = ^tFirmItem;
      tFirmItem           = record
       firm               : tFirmIdent;                      // �����
       firmset            : tFirmSet;                        // �������� ����
      end;

type  tSecuritiesSet      = set of (sec_stock_id,sec_shortname,sec_level,sec_code,sec_hibid, sec_lowoffer,
                                    sec_initprice,sec_maxprice,sec_minprice,sec_meanprice,sec_meantype,
                                    sec_change,sec_value,sec_amount,sec_lotsize,sec_facevalue,sec_lastdealprice,
                                    sec_lastdealsize,sec_lastdealqty,sec_lastdealtime,sec_gko_accr,sec_gko_yield,
                                    sec_gko_matdate,sec_gko_cuponval,sec_gko_nextcupon,sec_gko_cuponperiod,
                                    sec_srv_field,sec_biddepth,sec_offerdepth,sec_numbids,sec_numoffers,
                                    sec_tradingstatus,sec_closeprice,sec_gko_issuesize,sec_gko_buybackprice,
                                    sec_gko_buybackdate,sec_prev_price,sec_fut_deposit,sec_fut_openedpos,
                                    sec_marketprice, sec_limitpricehigh, sec_limitpricelow, sec_decimals,
                                    sec_pricestep, sec_stepprice);

type  pSecurities         = ^tSecurities;
      tSecurities         = record
       stock_id           : longint;                         // �����. �������� ��������
       shortname          : tShortName;                      // �������� �����������
       level              : tLevel;                          // ��� ������ ������
       code               : tCode;                           // ���������� ��� ������ ������
       hibid              : real;                            // �����
       lowoffer           : real;                            // �����������
       initprice          : real;                            // ���� ��������
       maxprice           : real;                            // ����. ���� ������ ������
       minprice           : real;                            // ���. ���� ������ ������
       meanprice          : real;                            // ���������������� ����
       meantype           : byte;                            // ��� ������� ���������.
       change             : real;                            // ��������� (� ��������)
       value              : int64;                           // ����� ������ �� ���. ���� � ������
       amount             : int64;                           // ����� ������ �� ���. ���� � �������
       lotsize            : longint;                         // ������ ����
       facevalue          : real;                            // �������
       lastdealprice      : real;                            // ���� ��� ��������� ������
       lastdealsize       : real;                            // ����� ��������� ������ � ������
       lastdealqty        : longint;                         // ����� ��������� ������ � �����
       lastdealtime       : double;                          // ����� ��������� ������
       gko_accr           : real;                            // ����������� �����
       gko_yield          : currency;                        // ���������� ���
       gko_matdate        : double;                          // ���� ��������� ���
       gko_cuponval       : currency;                        // �������� ������
       gko_nextcupon      : double;                          // ���� ������� ������
       gko_cuponperiod    : longint;                         // ������������ ������
       biddepth           : int64;                           // ����� ���� ������ �� �������
       offerdepth         : int64;                           // ����� ���� ������ �� �������
       numbids            : longint;                         // ���������� ������ �� ������� � ������� �� � �����
       numoffers          : longint;                         // ���������� ������ �� ������� � ������� �� � �����
       tradingstatus      : char;                            // ��������� ������ �� ����������� �����������
       closeprice         : real;                            // ���� ��������
       srv_field          : string[10];                      // ��������� ����
       gko_issuesize      : int64;                           // ����� ���������
       gko_buybackprice   : real;                            // ���� ������
       gko_buybackdate    : double;                          // ���� ������
       prev_price         : real;                            // ��������� ���������� ������
       fut_deposit        : real;                            // ����������� �����������
       fut_openedpos      : int64;                           // ���-�� �������� �������
       marketprice        : real;                            // �������� ���� ����������� ���
       limitpricehigh     : real;                            // ������� ����� ����
       limitpricelow      : real;                            // ������ ����� ����
       decimals           : longint;                         // ���������� ������ ����� �������
       pricestep          : real;                            // ����������� ��� ����
       stepprice          : real;                            // ��������� ������������ ���� ����
      end;

type  pSecuritiesItem     = ^tSecuritiesItem;
      tSecuritiesItem     = record
       sec                : tSecurities;                     // ���. ����������
       secset             : tSecuritiesSet;                  // �������� ����
      end;

type  pKotirovki          = ^tKotirovki;
      tKotirovki          = record
       stock_id           : longint;                         // �����. �������� ��������
       level              : tLevel;                          // ��� ������ ������
       code               : tCode;                           // ���������� ��� ������ ������
       buysell            : char;                            // �����/�������
       price              : real;                            // ����
       quantity           : longint;                         // ����������
       gko_yield          : currency;                        // ���������� ���
      end;

type  pKotUpdateHdr       = ^tKotUpdateHdr;
      tKotUpdateHdr       = record
       stock_id           : longint;                         // �����. �������� ��������
       level              : tLevel;                          // ��� ������ ������
       code               : tCode;                           // ���������� ��� ������ ������
       kotcount           : longint;                         // ���-�� ��������� � �������
      end;

      pKotUpdateItem      = ^tKotUpdateItem;
      tKotUpdateItem      = record
       buysell            : char;                            // �����/�������
       price              : real;                            // ����
       quantity           : longint;                         // ����������
       gko_yield          : currency;                        // ���������� ���
      end;

type  tOrdersSet          = set of (ord_stock_id,ord_level,ord_code,ord_orderno,ord_ordertime,ord_status,
                                    ord_buysell,ord_account,ord_price,ord_quantity,ord_value,ord_clientid,
                                    ord_balance,ord_ordertype,ord_settlecode,ord_comment);

type  pOrders             = ^tOrders;
      tOrders             = record
       transaction        : tTransactionID;                  // ����� ����������
       internalid         : tTransactionID;                  // ����� ���������
       stock_id           : longint;                         // �����. �������� ��������
       level              : tLevel;                          // ��� ������ ������
       code               : tCode;                           // ���������� ��� ������ ������
       orderno            : int64;                           // ����� ������ � �������� �������
       ordertime          : double;                          // ����� ���������� ������
       status             : char;                            // ��������� ������
       buysell            : char;                            // �����/�������
       account            : tAccount;                        // ����
       price              : real;                            // ����
       quantity           : longint;                         // ���-��
       value              : real;                            // �����
       clientid           : tClientID;                       // ID �������
       balance            : longint;                         // ������� �� ������
       ordertype          : char;                            // ��� ������ (�������, ���, ����)
       settlecode         : tSettleCode;                     // ��� ��������
       comment            : tComment;                        // ����������� � ������
      end;

type  pOrdCollItm       = ^tOrdCollItm;
      tOrdCollItm       = record
        ord             : tOrders;
        ordset          : tOrdersSet;
      end;

type  tTradesSet          = set of (trd_stock_id,trd_tradeno,trd_orderno,trd_tradetime,trd_level,trd_code,
                                    trd_buysell,trd_account,trd_price,trd_quantity,trd_value,trd_accr,
                                    trd_clientid,trd_tradetype,trd_settlecode,trd_comment);

type  pTrades             = ^tTrades;
      tTrades             = record
       transaction        : tTransactionID;                  // ����� ����������
       internalid         : tTransactionID;                  // ����� ���������
       stock_id           : longint;                         // �����. �������� ��������
       tradeno            : int64;                           // ����� ������
       orderno            : int64;                           // ����� ������
       tradetime          : double;                          // ����� ������
       level              : tLevel;                          // ��� ������ ������
       code               : tCode;                           // ���������� ��� ������ ������
       buysell            : char;                            // �����/�������
       account            : tAccount;                        // ����
       price              : real;                            // ����
       quantity           : longint;                         // ���-��
       value              : real;                            // �����
       accr               : real;                            // ����������� �����
       clientid           : tClientID;                       // ID �������
       tradetype          : char;                            // ��� ������ (�������, ���, ����)
       settlecode         : tSettleCode;                     // ��� ��������
       comment            : tComment;                        // ����������� � ������
      end;

type  pTrdCollItm       = ^tTrdCollItm;
      tTrdCollItm       = record
        trd             : tTrades;
        trdset          : tTradesSet;
      end;

type  pAllTrades          = ^tAllTrades;
      tAllTrades          = record
       stock_id           : longint;                         // �����. �������� ��������
       tradeno            : int64;                           // ����� ������
       tradetime          : double;                          // ����� ������
       level              : tLevel;                          // ��� ������ ������
       code               : tCode;                           // ���������� ��� ������ ������
       price              : real;                            // ����
       quantity           : longint;                         // ���-��
       value              : real;                            // �����
       buysell            : char;                            // ��������� ������
       reporate           : real;                            // ������ ���� � %
       repoterm           : longint;                         // ���� ���� � ����������� ����
      end;

type  tLimitsSet          = set of (lim_account, lim_stock_id, lim_code, lim_oldlimit, lim_startlimit, lim_free,
                                    lim_reserved, lim_res_pos, lim_res_ord, lim_negvarmarg, lim_curvarmarg);

type  pClientLimit        = ^tClientLimit;
      tClientLimit        = record
       account            : tAccount;                        // ����
       stock_id           : longint;                         // �����. �������� ��������
       code               : tCode;                           // ���������� ��� ������ ������
       oldlimit           : currency;                        // ����� ���������� �������� ������
       startlimit         : currency;                        // ������� �����
       free               : currency;                        // ��������� �������
       reserved           : currency;                        // ��������������� �����
       res_pos            : currency;                        // ��������������� ��� �������
       res_ord            : currency;                        // ��������������� ��� ������
       negvarmarg         : currency;                        // ������������� ������������ �����
       curvarmarg         : currency;                        // ������������ �����
      end;

type  pClientLimitItem    = ^tClientLimitItem;
      tClientLimitItem    = record
        limit             : tClientLimit;                    // �����
        limitset          : tLimitsSet;                      // �������� ����
      end;

type  pArcTradeBuf        = ^tArcTradeBuf;
      tArcTradeBuf        = record
       account            : tAccount;                        // ����
       stock_id           : longint;                         // �����. �������� ��������
       code               : tCode;                           // ���������� ��� ������ ������
       rowcount           : longint;
      end;

      pArcTradeRow        = ^tArcTradeRow;
      tArcTradeRow        = record
       tradeno            : int64;                           // ����� ������
       tradetime          : double;                          // ����� ������
       price              : real;                            // ����
       quantity           : longint;                         // ���-��
       accr               : real;                            // ����������� �����
      end;

type  pLevelAttrItem     = ^tLevelAttrItem;                  // ������ ������
      tLevelAttrItem     = record
       stock_id          : longint;                          // �����. �������� ��������
       level             : tLevel;                           // ��� ������ ������
       usefacevalue      : boolean;                          // ������������� ��������
       marketcode        : tMarketCode;                      // ��� �����
       leveltype         : longint;                          // ��� ����� (�� ��������� level*)
       default           : longint;                          // ������� "����� �� ���������"
       description       : string[50];                       // ��������� ��������
      end;

type  pMarginInfo         = ^tMarginInfo;                    // �������� ������� �����
      tMarginInfo         = record
       normal             : real;
       warning            : real;
       critical           : real;
      end;

type  pAccountListItm     = ^tAccountListItm;                // ������ ������
      tAccountListItm     = record
       stock_id           : longint;                         // �����. �������� ��������
       account            : tAccount;                        // ����
       flags              : longint;                         // �����
       margininfo         : tMarginInfo;                     // ���������� �� �������������� �������
       descr              : string[100];                     // �������� �����
      end;

type  pStockAccListItm    = ^tStockAccListItm;               // ������ �������� ������
      tStockAccListItm    = record
       stock_id           : longint;                         // �����. �������� ��������
       account            : tAccount;                        // ����
       marketcode         : tMarketCode;                     // ��� �����
       stockaccount       : tAccount;                        // ���� �� �����
       default            : boolean;                         // ������� ����� ��-��������� ��� ��������� ��������������
       account_type       : longint;                         // ��� �����
      end;

type  tMargLevel          = ( margin_normal,                 // ���������� ������� �����
                              margin_warning,                // ����������������� ������� �����
                              margin_critical );             // ����������� ������� �����

type  pMarginLevel        = ^tMarginLevel;                   // ������� ������� �����
      tMarginLevel        = record
       account            : tAccount;                        // ����� �����
       factlvl            : real;                            // ����������� �.�.
       planlvl            : real;                            // �������� �.�.
       minlvl             : real;                            // ����������� �.�.
       marginstate        : longint;                         // ������ ������������ ��������������� �������
       planlvlb           : real;                            // �������� �.�. � ������� �������
       planlvls           : real;                            // �������� �.�. � ������� �������
       planlvlmid         : real;                            // �������� �.�. ��� ����� ������ ����������
       planlvlbn          : real;                            // �������� �.�. � ������� ������� � ������ ���������
      end;

type  tAccountSet         = set of (acc_stock_id, acc_code, acc_fact, acc_plan, acc_fdbt, acc_pdbt, acc_reserved,
                                    acc_res_pos, acc_res_ord, acc_negvarmarg, acc_curvarmarg);

type  pAccountBuf         = ^tAccountBuf;
      tAccountBuf         = record                           // ������� �� �����
       account            : tAccount;                        // ����
       rowcount           : longint;                         // ���������� ����� � �����
      end;

      pAccountRow         = ^tAccountRow;
      tAccountRow         = record
       fields             : tAccountSet;                     // ����
       // ����� ����
       stock_id           : longint;                         // �����
       code               : tCode;                           // ��� ������
       // �������� �����
       fact               : currency;                        // ����������� �������
       plan               : currency;                        // �������� �������
       fdbt               : currency;                        // ����������� �������������
       pdbt               : currency;                        // �������� �������������
       // ������� �����
       reserved           : currency;                        // ��������������� �����
       res_pos            : currency;                        // ��������������� ��� �������
       res_ord            : currency;                        // ��������������� ��� ������
       negvarmarg         : currency;                        // ������������� ������������ �����
       curvarmarg         : currency;                        // ������� ������������ �����
      end;

type  pAccountRestsBuf    = ^tAccountRestsBuf;
      tAccountRestsBuf    = record                           // ������� �� �����
       account            : tAccount;                        // ����
       rowcount           : longint;                         // ���������� ����� � �����
      end;

      pAccountRestsRow    = ^tAccountRestsRow;               // ������� �� ������ ���
      tAccountRestsRow    = record
       stock_id           : longint;                         // �����
       code               : tCode;                           // ��� ������
       fact               : currency;                        // �������
       avgprice           : currency;                        // ������� ���� �������
      end;

type  pLiquidListItem     = ^tLiquidListItem;
      tLiquidListItem     = record                           // ������ ��������� �����
       stock_id           : longint;                         // �����
       level              : tLevel;                          // ��� ������ ������
       code               : tCode;                           // ��� ������
       price              : real;                            // ���� ������
       hibid              : real;                            // �����
       lowoffer           : real;                            // �����������
       repolevel          : tLevel;                          // �����, �� ������� ����������� ������ ��C
      end;

type  pOrder              = ^tOrder;                         // ������ (������)
      tOrder              = record
       transaction        : tTransactionID;                  // ����� ����������
       stock_id           : longint;                         // ������������� �������� ��������
       level              : tLevel;                          // �����
       code               : tCode;                           // ��� ������
       buysell            : char;                            // �������/�������
       price              : real;                            // ���� �� ������
       quantity           : longint;                         // ���������� � �����
       account            : tAccount;                        // ����
       flags              : longint;                         // ����� ������
       cid                : tClientId;                       // ������������� �������
       cfirmid            : string[20];                      // ������������� ����� ��� ���������� ����/���
       match              : string[20];                      // ������ ��� ����/���
       settlecode         : tSettleCode;                     // ��� ��������
       refundrate         : real;                            // ����������
       reporate           : real;                            // ������ ����
       price2             : real;                            // ���� ������ ����
      end;

type  pMoveOrder          = ^tMoveOrder;                     // ������ �� ������� ������
      tMoveOrder          = record
       transaction        : tTransactionID;                  // ����� ����������
       stock_id           : longint;                         // ������������� ��������
       level              : tLevel;                          // �����
       code               : tCode;                           // ��� ������
       orderno            : int64;                           // ����� �������������� ������
       new_price          : real;                            // ����� ����
       new_quantity       : longint;                         // ����� ����������
       account            : tAccount;                        // ����
       flags              : longint;                         // ����� �������� ����������
       cid                : tClientId;                       // ������������� �������
      end;

type  pDropOrderEx        = ^tDropOrderEx;                   // ������ �� ������ ������
      tDropOrderEx        = record
       transaction        : tTransactionID;                  // ����� ����������
       orderno            : int64;                           // ����� ��������� ������
       stock_id           : longint;                         // ������������� ��������
       level              : TLevel;                          // �����
       code               : TCode;                           // ��� ������
       account            : tAccount;                        // ����
       flags              : longint;                         // ����� ������ ������
       cid                : tClientId;                       // ������������� �������
      end;

type  pStopOrder          = ^tStopOrder;                     // ����-������ (������)
      tStopOrder          = record
       order              : tOrder;                          // ������
       stoptype           : byte;                            // ������� ������������
       stopprice          : real;                            // ���� ������������
       expiredatetime     : tdatetime;                       // ���� � ����� ������ ������
      end;

type  pStopOrders         = ^tStopOrders;                    // ����-������
      tStopOrders         = record
       stopid             : int64;                           // �����
       stoptime           : tdatetime;                       // ����� ������
       stoporder          : tStopOrder;                      // ����-������
       status             : char;                            // ������
       so_clientid        : tClientId;                       // ������������� �������
       so_username        : tUserName;                       // ��� ������������
       so_ucf             : longint;                         //
       so_sf              : longint;                         //
       comment            : tComment;                        // �����������
      end;

type  tNewsSet            = set of (nws_newsprovider, nws_newstime);

type  pNewsHeader         = ^tNewsHeader;
      tNewsHeader         = record
       id                 : longint;                         // ���������� ������������� �������
       news_id            : longint;                         // ������������� ����������
       newstime           : tDateTime;                       // ����� �������
       newsfields         : tNewsSet;                        // ����������� ����
       subjlen            : longint;                         // ������ ����
       textlen            : longint;                         // ������ ������
      end;                                                   // ��������� ���� ������ �� ����������

type  pNewsQuery          = ^tNewsQuery;
      tNewsQuery          = record
       lastid             : longint;                         // ������������� �������
       lastdate           : tDateTime;                       // ����/����� ��������� �������
       querytype          : longint;                         // ��� �������
      end;

type  tOrderComment       = string[20];

type  tOrdersArray        = array [1..maxDropOrders] of int64;

type  pDropOrder          = ^tDropOrder;
      tDropOrder          = record
       transaction        : tTrsQueryID;
       stock_id           : word;                            // ������������� �������� ��������. word ��� �������������
       dropflags          : word;                            // �����: ���� ������ ��� �������
       count              : byte;
       orders             : tOrdersArray;
      end;

      tAllTradesSw        = record
       TradesFlag         : boolean;
       stock_id           : longint;
       LastTrade          : int64;
      end;

      tReportQuery        = record
       account            : tAccount;
       sdate,fdate        : tDateTime;
      end;

      tTradesQuery        = record
       account            : tAccount;
       stock_id           : longint;
       code               : tCode;
       quantity           : longint;
      end;

      pClientQuery        = ^tClientQuery;
      tClientQuery        = record                           // ������� �� �������
       case msgid         : byte of
        msgKot            : (add          : byte;
                             secid        : tSecIdent);
        msgAllTrades      : (TradesSwitch : tAllTradesSw);
        msgSetOrd         : (SetOrder     : tOrder);
        msgEditOrd        : (EditOrder    : tOrder);
        msgDropOrd        : (DropOrder    : tDropOrder);
        msgQueryReport    : (ReportQuery  : tReportQuery);
        msgQueryTrades    : (TradesQuery  : tTradesQuery);
        msgAllTradesReq   : (atrdadd      : byte;
                             atrdboardid  : tBoardIdent;
                             atrdtradeno  : int64);
      end;

type  pSetOrderResult     = ^tSetOrderResult;
      tSetOrderResult     = record
       // ����, � ������� ������������ ���������
       accepted           : byte;                            // ������� �� ������
       ExtNumber          : int64;                           // ����� ������
       TEReply            : string[235];                     // ��������� ��������� �������� ��������
       Quantity           : int64;                           // ���-�� (� ������ ����� ������, ���������...), ������� �� ����������
       Reserved           : int64;                           // ���������������
       // ��������� ���� ������� ������ �����������
       ID                 : longint;                         // ������������ �������������
       clientid           : tClientId;                       // ������������� �������
       username           : tUserName;                       // ��� ������������
       account            : tAccount;                        // ���� � �������
       internalid         : tTransactionID;                  // ���������� ����� ����������
       externaltrs        : tTransactionID;                  // ����� ���������� ������� �������
      end;

type  pTrsQuery           = ^tTrsQuery;
      tTrsQuery           = array[0..0] of tTrsQueryID;      // ������ ������������� ����������

type  pTrsResult          = ^tTrsResult;
      tTrsResult          = record
       transaction        : tTrsQueryID;                     // ����� ����������
       errcode            : byte;                            // ��� ��������
       quantity           : int64;                           // ���-��
       reserved           : int64;                           // ���������������
      end;                                                   // ��������� ��������� ������ �� ����������

type  pReportHeader       = ^tReportHeader;
      tReportHeader       = record                           // ��������� ������
       sdat               : tdatetime;                       // ��������� ����
       fdat               : tdatetime;                       // �������� ����
       fullname           : string[50];                      // ���������� � �������
       address            : string[50];                      // ���������� � ��������
       prcnds             : real;                            // ��������� ���
       rowcount           : longint;                         // ������� �����
      end;

      pReportRow          = ^tReportRow;
      tReportRow          = record                           // ������ ������
       transaction        : tTransactionID;                  // ���������� (����� ���������)
       trstype            : char;                            // ��� ������
       dealid             : int64;                           // ����� ������
       dt                 : tDateTime;                       // �����
       stock_id           : longint;                         // ������������� �������� ��������
       code               : tCode;                           // ��� ������ ������
       shortname          : tShortName;                      // ������������ �����������
       buysell            : char;                            // �������/�������
       price              : real;                            // ����
       quantity           : currency;                        // ����������
       value              : currency;                        // �����
       nkd                : currency;                        // �������� �����
       stockkommiss       : currency;                        // �������� �����
       brokerkommiss      : currency;                        // �������� �������
       comment            : string[100];                     // �����������
      end;

type  pStockRow           = ^tStockRow;                      // �������� �������� ��������
      tStockRow           = record
       stock_id           : longint;                         // ������������� �������� ��������
       stock_name         : string[20];                      // ������������
       stock_flags        : byte;                            // ����� (����������� � ��� �����)
      end;

type  pSecFlagsItm        = ^tSecFlagsItm;
      tSecFlagsItm        = record
       secid              : tSecIdent;
       flags              : longint;
       lasttradeno        : int64;
      end;

type  pQueueData          = ^tQueueData;
      tQueueData          = record
       id                 : longint;
       size               : longint;
       cnt                : longint;
       data               : pChar;
      end;

type  pIndLimitsBuf       = ^tIndLimitsBuf;                  // �������������� ������
      tIndLimitsBuf       = record
       account            : tAccount;                        // ����
       rowcount           : longint;                         // ���-�� ����� � ���. ��������
      end;

      pIndLimitsRow       = ^tIndLimitsRow;                  // �������������� �����
      tIndLimitsRow       = record
       stock_id           : longint;                         // ������������� �������� ��������
       code               : tCode;                           // ��� ������
       limit              : currency;                        // �������� ������
      end;

const allsecuritiesfields : tSecuritiesSet = [sec_stock_id,sec_shortname, sec_level,sec_code,sec_hibid,
                                              sec_lowoffer,sec_initprice,sec_maxprice,sec_minprice,sec_meanprice,
                                              sec_meantype,sec_change,sec_value,sec_amount,sec_lotsize,sec_facevalue,
                                              sec_lastdealprice,sec_lastdealsize,sec_lastdealqty,sec_lastdealtime,
                                              sec_gko_accr,sec_gko_yield,sec_gko_matdate,sec_gko_cuponval,
                                              sec_gko_nextcupon,sec_gko_cuponperiod,sec_srv_field,sec_biddepth,
                                              sec_offerdepth,sec_numbids,sec_numoffers,sec_tradingstatus,sec_closeprice,
                                              sec_gko_issuesize, sec_gko_buybackprice, sec_gko_buybackdate,
                                              sec_prev_price,sec_fut_deposit,sec_fut_openedpos,sec_marketprice,
                                              sec_limitpricehigh,sec_limitpricelow, sec_decimals, sec_pricestep,
                                              sec_stepprice];

const allordersfields     : tOrdersSet     = [ord_stock_id,ord_level,ord_code,ord_orderno,ord_ordertime,
                                              ord_status,ord_buysell,ord_account,ord_price,ord_quantity,
                                              ord_value,ord_clientid,ord_balance,ord_ordertype,ord_comment];

const alltradesfields     : tTradesSet     = [trd_stock_id,trd_tradeno,trd_orderno,trd_tradetime,trd_level,
                                              trd_code,trd_buysell,trd_account,trd_price,trd_quantity,trd_value,
                                              trd_accr,trd_clientid,trd_tradetype,trd_comment];

implementation

end.


