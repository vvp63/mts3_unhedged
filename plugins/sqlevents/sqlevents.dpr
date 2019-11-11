library sqlevents;

{$R *.res}

uses  windows, sysutils,
      servertypes, serverapi, tterm_api, 
      sqlevents_common, sqlevents_thread;

function  Init(memmgr: pMemoryManager): longint;   cdecl; forward;
function  Done: longint;                           cdecl; forward;

procedure ServerStatusChanged(status: longint);    cdecl; forward;

const stockAPI : tStockAPI       = (  stock_count      : 0;
                                      stock_list       : nil;
                                      pl_SetOrder      : nil;
                                      pl_DropOrder     : nil;


                                      pl_Connect       : nil;
                                      pl_Disconnect    : nil;
                                      pl_Hook          : nil;
                                      ev_BeforeDayOpen : nil;
                                      ev_AfterDayOpen  : nil;
                                      ev_BeforeDayClose: nil;
                                      ev_AfterDayClose : nil;
                                      ev_OrderCommit   : nil;
                                      ev_ServerStatus  : ServerStatusChanged;
                                      pl_MoveOrder     : nil;
                                     );

      plugApi : tDataSourceApi   = (  plugname      : PlugName;
                                      plugflags     : plStockProvider;
                                      pl_Init       : Init;
                                      pl_Done       : Done;
                                      stockapi      : @stockAPI;
                                      newsapi       : nil;
                                      eventapi      : nil;
                                    );

function Init(memmgr: pMemoryManager): longint;
begin
  InitSQLMonitor;
  result:= 0;
end;

function Done: longint;
begin
  DoneSQLMonitor;
  result:= 0;
end;

procedure ServerStatusChanged(status: longint);
const msgs : array[boolean] of ansistring = ('Event processing suspended', 'Event processing started');
begin
  if assigned(SQLEventThread) then begin
    SQLEventThread.EnableEvents:= (status = dayWasOpened);
    log(msgs[SQLEventThread.EnableEvents]);
  end;
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