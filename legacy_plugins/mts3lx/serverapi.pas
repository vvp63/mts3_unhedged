{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit serverapi;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$endif}
      servertypes;

const clrByStruct            = $00000000;
      clrByStockId           = $00000001;
      clrByLevel             = $00000002;

const plDummy                = $00000000;
      plStockProvider        = $00000001;
      plNewsProvider         = $00000002;
      plEventHandler         = $00000004;

const evBeforeDayOpen        = $00000001;
      evAfterDayOpen         = $00000002;
      evBeforeDayClose       = $00000003;
      evAfterDayClose        = $00000004;

type  pStockName             = ^tStockName;
      tStockName             = string[20];

type  pPlugName              = ^tPlugName;
      tPlugName              = string[20];

type  pServerAPI             = ^tServerAPI;
      tServerAPI             = record
       {системные функции}
       SetTrsResult          : procedure (var aresult: tSetOrderResult);                                           cdecl;
       {сервисные функции}
       LogEvent              : procedure (event:pAnsiChar);                                                        cdecl;
       ReadBuf               : function  (prompt:pAnsiChar; masked:boolean;
                                          buf:pAnsiChar; buflen:longint):longint;                                  cdecl;
       {таблица финансовые инструменты}
       AddSecuritiesRec      : procedure (var struc:tSecurities; changedfields:TSecuritiesSet);                    cdecl;
       GetSecuritiesRec      : function  (var struc:tSecurities; flds:TSecuritiesSet):boolean;                     cdecl;
       {таблица котировок}
       LockKotirovki         : procedure;                                                                          cdecl;
       ClearKotirovkiTbl     : procedure (var struc:tKotirovki; flags:longint);                                    cdecl;
       AddKotirovkiRec       : procedure (var struc:tKotirovki);                                                   cdecl;
       UnlockKotirovki       : procedure;                                                                          cdecl;
       {таблица заявок}
       AddOrdersRec          : procedure (var struc:tOrders; changedfields:TOrdersSet);                            cdecl;
       {таблица сделок}
       AddTradesRec          : procedure (var struc:tTrades; changedfields:TTradesSet);                            cdecl;
       {таблица все сделки}
       AddAllTradesRec       : procedure (var struc:tAllTrades);                                                   cdecl;
       {комиссии}
       SetCommissBySec       : procedure (astock_id:longint; alevel:tLevel; acode:tCode; aprc:real; afs:currency); cdecl;
       {stock-dependent}
       SetAdditionalPrm      : procedure (astock_id:longint; aparams:pAnsiChar);                                   cdecl;
       {новости}
       GetLastNews           : procedure (news_id:longint; var lastdt:tdatetime; var lastno:int64);                cdecl;
       AddNewsRec            : function  (news_id:longint; news_no:int64; news_time:tdatetime;
                                          title, text:pAnsiChar):longint;                                          cdecl;
       {таблица денежных лимитов}
       SetClienLimit         : procedure (var struc:tClientLimit; changedfields:tLimitsSet);                       cdecl;
       {таблицы поддержки РПС/РЕПО}
       AddFirmsRec           : procedure (var struc: tFirmIdent; changedfields: tFirmSet);                         cdecl;
       AddSettleCodesRec     : procedure (var struc: tSettleCodes);                                                cdecl;

       {расширенное управление таблицами}
       OrdersBeginUpdate     : procedure (astock_id: longint; alevel: tLevel);                                     cdecl;
       OrdersEndUpdate       : procedure (astock_id: longint; alevel: tLevel);                                     cdecl;
       TradesBeginUpdate     : procedure (astock_id: longint; alevel: tLevel);                                     cdecl;
       TradesEndUpdate       : procedure (astock_id: longint; alevel: tLevel);                                     cdecl;
       AllTradesBeginUpdate  : procedure (astock_id: longint; alevel: tLevel);                                     cdecl;
       AllTradesEndUpdate    : procedure (astock_id: longint; alevel: tLevel);                                     cdecl;
       SecuritiesBeginUpdate : procedure (astock_id: longint; alevel: tLevel);                                     cdecl;
       SecuritiesEndUpdate   : procedure (astock_id: longint; alevel: tLevel);                                     cdecl;

       {управление счетами}
       GetAccount            : function (const aaccount: tAccount): pointer;                                       cdecl;
       GetAccountData        : function (const aaccount: tAccount; buflen: longint; var buffer;
                                         var actlen: longint): boolean;                                            cdecl;
       ReleaseAccount        : procedure (const aaccount: tAccount);                                               cdecl;

       {set_order и так далее}
       Set_Order             : function (var order: tOrder; const acomment: pAnsiChar;
                                         var setresult: tSetOrderResult): boolean;                                 cdecl;
       Drop_Order            : function (const aaccount: tAccount; var droporder: tDropOrder): boolean;            cdecl;
       Set_SysOrder          : function (var order: tOrder; const acomment: pAnsiChar;
                                         var setresult: tSetOrderResult): boolean;                                 cdecl;
       {отсылка сообщений пользователю}
       SendUserMessage       : function (aToID, aToUserName, aText: pAnsiChar): boolean;                           cdecl;
       SendBroadcastMessage  : function (aflags: longint; aText: pAnsiChar): boolean;                              cdecl;
       {отсылка результатов SQL}
       SetSQLEventResult     : function (aresulthandle: longint; adata: pAnsiChar; adatasize: longint): boolean;   cdecl;
       {move order}
       Move_SysOrder         : function (var moveorder: tMoveOrder; var setresult: tSetOrderResult): boolean;      cdecl;
       Drop_OrderEx          : function (var droporder: tDropOrderEx; var setresult: tSetOrderResult): boolean;    cdecl;
      end;

      { имена функций сервера для экспорта }
const srv_SetTransactionResult     = 'srvSetTransactionResult';
      srv_LogEventPC               = 'srvLogEvent';
      srv_ReadBuf                  = 'srvReadBuf';
      srv_AddSecuritiesRec         = 'srvAddSecuritiesRec';
      srv_GetSecuritiesRec         = 'srvGetSecuritiesRec';
      srv_KotirovkiLock            = 'srvKotirovkiLock';
      srv_ClearKotirovkiTbl        = 'srvClearKotirovkiTbl';
      srv_AddKotirovkiRec          = 'srvAddKotirovkiRec';
      srv_KotirovkiUnlock          = 'srvKotirovkiUnlock';
      srv_AddOrdersRec             = 'srvAddOrdersRec';
      srv_GetOrdersRec             = 'srvGetOrdersRec';
      srv_AddTradesRec             = 'srvAddTradesRec';
      srv_AddAllTradesRec          = 'srvAddAllTradesRec';
      srv_SetStockComissionBySec   = 'srvSetStockComissionBySec';
      srv_SetStockAdditionalParams = 'srvSetStockAdditionalParams';
      srv_GetLastNews              = 'srvGetLastNews';
      srv_AddNewsRec               = 'srvAddNewsRec';
      srv_SetClientLimit           = 'srvSetClientLimit';
      srv_AddFirmsRec              = 'srvAddFirmsRec';
      srv_AddSettleCodesRec        = 'srvAddSettleCodesRec';

      srv_OrdersBeginUpdate        = 'srvOrdersBeginUpdate';
      srv_OrdersEndUpdate          = 'srvOrdersEndUpdate';
      srv_TradesBeginUpdate        = 'srvTradesBeginUpdate';
      srv_TradesEndUpdate          = 'srvTradesEndUpdate';

      srv_AllTradesBeginUpdate     = 'srvAllTradesBeginUpdate';
      srv_AllTradesEndUpdate       = 'srvAllTradesEndUpdate';
      srv_SecuritiesBeginUpdate    = 'srvSecuritiesBeginUpdate';
      srv_SecuritiesEndUpdate      = 'srvSecuritiesEndUpdate';

      srv_GetAccount               = 'srvGetAccount';
      srv_GetAccountData           = 'srvGetAccountData';
      srv_ReleaseAccount           = 'srvReleaseAccount';

      srv_SetOrder                 = 'srvSetOrder';
      srv_DropOrder                = 'srvDropOrder';
      srv_SetSystemOrder           = 'srvSetSystemOrder';
      srv_MoveSystemOrder          = 'srvMoveSystemOrder';
      srv_DropOrderEx              = 'srvDropOrderEx';

      srv_SendUserMessage          = 'srvSendUserMessage';
      srv_SendBroadcastMessage     = 'srvSendBroadcastMessage';

      srv_SetSQLEventResult        = 'srvSetSQLEventResult';

      {разное}

type  tsrvUpdateSecuritiesRec      = procedure (var sour, dest: tSecurities;
                                                var sourset, destset: tSecuritiesSet);                             cdecl;
      tsrvCleanupSecuritiesRec     = procedure (var sour: tSecurities; const sourset: tSecuritiesSet);             cdecl;
      tsrvGetOrdersRec             = function  (astock_id: longint; const aorderno: int64;
                                                var aorderitem: tOrdCollItm): boolean;                             cdecl;
      tsrvUpdateOrders             = procedure (var sour, dest:tOrders; var sourset, destset: tOrdersSet);         cdecl;
      tsrvCleanupOrders            = procedure (var sour: tOrders; const sourset: tOrdersSet);                     cdecl;
      tsrvUpdateTrades             = procedure (var sour, dest: tTrades; var sourset, destset: tTradesSet);        cdecl;
      tsrvCleanupTrades            = procedure (var sour: tTrades; var sourset: tTradesSet);                       cdecl;
      tsrvUpdateFirmsRec           = procedure (var sour, dest: tFirmIdent;
                                                var sourset, destset, changes: tFirmSet);                          cdecl;

const srv_UpdateSecuritiesRec      = 'srvUpdateSecuritiesRec';
      srv_CleanupSecuritiesRec     = 'srvCleanupSecuritiesRec';
      srv_UpdateOrders             = 'srvUpdateOrders';
      srv_CleanupOrders            = 'srvCleanupOrders';
      srv_UpdateTrades             = 'srvUpdateTrades';
      srv_CleanupTrades            = 'srvCleanupTrades';
      srv_UpdateFirmsRec           = 'srvUpdateFirmsRec';

type  tplgSetOrder           = procedure (order:tOrder; comment:tOrderComment; var res:tSetOrderResult);           cdecl;
      tplgDropOrder          = procedure (order: int64; flags: longint;
                                          astock_id: longint; const alevel: TLevel; const acode: TCode;
                                          var res: tSetOrderResult);                                               cdecl;
      tplgConnect            = function:longint;                                                                   cdecl;
      tplgDisconnect         = function:longint;                                                                   cdecl;
      tplgHook               = function  (params:pointer):longint;                                                 cdecl;
      tplgevBeforeDayOpen    = procedure;                                                                          cdecl;
      tplgevAfterDayOpen     = procedure;                                                                          cdecl;
      tplgevBeforeDayClose   = procedure;                                                                          cdecl;
      tplgevAfterDayClose    = procedure;                                                                          cdecl;
      tplgevOrderCommit      = procedure (commitresult:byte; orderno:int64);                                       cdecl;
      tplgevServerStatus     = procedure (status:longint);                                                         cdecl;
      tplgMoveOrder          = procedure (moveorder:tMoveOrder; comment:tOrderComment; var res:tSetOrderResult);   cdecl;
      tplgDropOrderEx        = procedure (const droporder:tDropOrderEx; const comment:tOrderComment;
                                          var res:tSetOrderResult);                                                cdecl;

      tStockRec              = record
       stock_id              : longint;
       stock_name            : tStockName;
      end;

      pStockList             = ^tStockList;
      tStockList             = array[0..0] of tStockRec;

      pStockAPI              = ^tStockAPI;
      tStockAPI              = record
       stock_count           : longint;
       stock_list            : pStockList;
       pl_SetOrder           : tplgSetOrder;
       pl_DropOrder          : tplgDropOrder;
       pl_Connect            : tplgConnect;
       pl_Disconnect         : tplgDisconnect;
       pl_Hook               : tplgHook;
       ev_BeforeDayOpen      : tplgevBeforeDayOpen;
       ev_AfterDayOpen       : tplgevAfterDayOpen;
       ev_BeforeDayClose     : tplgevBeforeDayClose;
       ev_AfterDayClose      : tplgevAfterDayClose;
       ev_OrderCommit        : tplgevOrderCommit;
       ev_ServerStatus       : tplgevServerStatus;
       pl_MoveOrder          : tplgMoveOrder;
       pl_DropOrderEx        : tplgDropOrderEx;
     end;

type  pNewsAPI               = ^tNewsAPI;
      tNewsAPI               = record
       news_id               : longint;
       news_provider         : tStockName;
      end;

const evNone                 = $00000000;
      evBeginSec             = $00000001;
      evEndSec               = $00000002;
      evBeginOrders          = $00000003;
      evEndOrders            = $00000004;
      evBeginTrades          = $00000005;
      evEndTrades            = $00000006;
      evBeginAllTrades       = $00000007;
      evEndAllTrades         = $00000008;

type  tplgevSecArrived       = procedure (var sec:tSecurities; changedfields:TSecuritiesSet);                      cdecl;
      tplgevAllTrdArrived    = procedure (var alltrds:tAllTrades);                                                 cdecl;
      tplgevKotirArrived     = procedure (kotirdata: pointer);                                                     cdecl;
      tplgevOrderArrived     = procedure (var order: tOrders; fields: tOrdersSet);                                 cdecl;
      tplgevTradesArrived    = procedure (var trade: tTrades; fields: tTradesSet);                                 cdecl;
      tplgevTransactionRes   = procedure (var aresult: tSetOrderResult);                                           cdecl;
      tplgevAccountUpdated   = procedure (var aaccount: tAccount);                                                 cdecl;
      tplgevSQLServerEvent   = function (aeventcode, aeventparameter: pAnsiChar; aresulthandle: longint): boolean; cdecl;
      tplgevUserMessage      = procedure (aFromID, aFromUserName, aText: pAnsiChar);                               cdecl;
      tplgevTableUpdate      = procedure (aEventType: longint; astock_id: longint; alevel: tLevel);                cdecl;

      pEventHandlerAPI       = ^tEventHandlerAPI;
      tEventHandlerAPI       = record
       evSecArrived          : tplgevSecArrived;    
       evAllTrdArrived       : tplgevAllTrdArrived;
       evKotirArrived        : tplgevKotirArrived;
       evOrderArrived        : tplgevOrderArrived;
       evTradesArrived       : tplgevTradesArrived;
       {результаты транзакций}
       evTransactionRes      : tplgevTransactionRes;
       {событие обновления счета}
       evAccountUpdated      : tplgevAccountUpdated;
       {событие SQL-сервера}
       evSQLServerEvent      : tplgevSQLServerEvent;
       {сообщения пользователя}
       evUserMessage         : tplgevUserMessage;
       {события обновления таблиц}
       evTableUpdate         : tplgevTableUpdate;
      end;

type  tplgInit               = function  (memorymanager:pMemoryManager):longint;                                   cdecl;
      tplgDone               = function:longint;                                                                   cdecl;

      pDataSourceAPI         = ^tDataSourceAPI;
      tDataSourceAPI         = record
       plugname              : tPlugName;
       plugflags             : longint;
       pl_Init               : tplgInit;
       pl_Done               : tplgDone;
       stockAPI              : pStockAPI;
       newsAPI               : pNewsAPI;
       eventAPI              : pEventHandlerAPI;
      end;

      tplgGetDllAPI          = function  (srvapi:pServerAPI):pDataSourceAPI;                                       cdecl;

      pPluginRec             = ^tPluginRec;
      tPluginRec             = record
       handle                : hModule;
       API                   : pDataSourceAPI;
       GetAPI                : tplgGetDllAPI;
       apiallocated          : boolean;
      end;

const { общие структуры }
      plg_PlugName           = 'plgPlugName';
      plg_PlugFlags          = 'plgPlugFlags';

      { структуры плагина биржи }
      plg_StockRec           = 'plgStockRec';
      plg_StockList          = 'plgStockList';
      plg_StockCount         = 'plgStockCount';

      { структуры плагина новостей }
      plg_NewsID             = 'plgNewsID';
      plg_NewsProvider       = 'plgNewsProvider';

      { общие функции }
      plg_getDllAPI          = 'getDllAPI';
      plg_Init               = 'plgInit';
      plg_Done               = 'plgDone';

      { функции плагина биржи }
      plg_SetOrder           = 'plgSetOrder';
      plg_DropOrder          = 'plgDropOrder';
      plg_Connect            = 'plgConnect';
      plg_Disconnect         = 'plgDisconnect';
      plg_Hook               = 'plgHook';
      plg_ev_BeforeDayOpen   = 'plgEvBeforeDayOpen';
      plg_ev_AfterDayOpen    = 'plgEvAfterDayOpen';
      plg_ev_BeforeDayClose  = 'plgEvBeforeDayClose';
      plg_ev_AfterDayClose   = 'plgEvAfterDayClose';
      plg_ev_OrderCommit     = 'plgEvOrderCommit';
      plg_ev_ServerStatus    = 'plgEvServerStatus';
      plg_MoveOrder          = 'plgMoveOrder';
      plg_DropOrderEx        = 'plgDropOrderEx';

      { функции плагина-обработчика }
      plg_EvSecArrived       = 'plgEvSecArrived';
      plg_EvAllTrdArrived    = 'plgEvAllTrdArrived';
      plg_EvKotirArrived     = 'plgEvKotirArrived';
      plg_EvOrderArrived     = 'plgEvOrderArrived';
      plg_EvTradesArrived    = 'plgEvTradesArrived';
      plg_EvTransactionRes   = 'plgEvTransactionRes';
      plg_EvAccountUpdated   = 'plgEvAccountUpdated';
      plg_EvSQLServerEvent   = 'plgEvSQLServerEvent';
      plg_EvUserMessage      = 'plgEvUserMessage';
      plg_EvTableUpdate      = 'plgEvTableUpdate';

implementation

end.
