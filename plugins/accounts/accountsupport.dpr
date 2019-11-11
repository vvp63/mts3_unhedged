library accountsupport;

{$R *.res}

uses  windows, sysutils,
      servertypes, serverapi, tterm_api, 
      accountsupport_common,
      legacy_accounts;

function  Init(memmgr: pMemoryManager): longint;   cdecl; forward;
function  Done: longint;                           cdecl; forward;
function  Connect: longint;                        cdecl; forward;
function  Disconnect: longint;                     cdecl; forward;
procedure AfterDayClose;                           cdecl; forward;

procedure ServerStatusChanged(status: longint);    cdecl; forward;

const stockAPI : tStockAPI        = ( stock_count      : 0;
                                      stock_list       : nil;
                                      pl_SetOrder      : nil;
                                      pl_DropOrder     : nil;


                                      pl_Connect       : Connect;
                                      pl_Disconnect    : Disconnect;
                                      pl_Hook          : nil;
                                      ev_BeforeDayOpen : nil;
                                      ev_AfterDayOpen  : nil;
                                      ev_BeforeDayClose: nil;
                                      ev_AfterDayClose : AfterDayClose;
                                      ev_OrderCommit   : nil;
                                      ev_ServerStatus  : ServerStatusChanged;
                                      pl_MoveOrder     : nil;
                                     );

      eventAPI : tEventHandlerAPI = ( evSecArrived     : onSecuritiesArrived;
                                      evAllTrdArrived  : nil;
                                      evKotirArrived   : nil;
                                      evOrderArrived   : nil;
                                      evTradesArrived  : onTradesArrived;
                                      evTransactionRes : nil;
                                      evAccountUpdated : nil;
                                      evSQLServerEvent : nil;
                                      evUserMessage    : nil;
                                      evTableUpdate    : onTablesUpdate;
                                     );

      plugApi : tDataSourceApi   = (  plugname         : PlugName;
                                      plugflags        : plStockProvider or plEventHandler;
                                      pl_Init          : Init;
                                      pl_Done          : Done;
                                      stockapi         : @stockAPI;
                                      newsapi          : nil;
                                      eventapi         : @eventAPI;
                                    );

function Init(memmgr: pMemoryManager): longint;
begin
//  InitSQLMonitor;
  result:= 0;
end;

function Done: longint;
begin
//  DoneSQLMonitor;
  result:= 0;
end;

function Connect: longint;
begin
  result:= 0;
end;

function Disconnect: longint;
begin
  result:= 0;
end;

procedure AfterDayClose;
begin
  // calculate ost_kon and save to file
end;

procedure ServerStatusChanged(status: longint);
begin
  if (status = dayWasOpened) then
    if assigned(accountregistry) then accountregistry.InitializeRegistry;
end;

function getDllAPI(srvapi: pServerAPI): pDataSourceAPI; cdecl;
begin
  server_api:= srvapi;
  plugin_api:= @plugapi;
  if assigned(server_api) then result:= @plugapi else result:= nil;
end;

exports
  getDllAPI;

begin
  IsMultiThread:= true;
  decimalseparator:= '.'; timeseparator:= ':';  
end.