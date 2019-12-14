library legacy_test;

{$R *.res}

uses  windows, classes, sysutils,
      servertypes, serverapi,
      mmfsendreceive;

function  Init(memmgr : pMemoryManager) : longint;  cdecl; forward;
function  Done : longint;                           cdecl; forward;

const PlugName  = 'legacy_test';

function OnSQLCommand(aeventcode, aeventparameter: pchar; aresulthandle: longint): boolean; cdecl; forward;
function OnHook(params: pointer): longint; cdecl; forward;
procedure OnOrder(var order: tOrders; fields: tOrdersSet); cdecl; forward;

const ev_api  : tEventHandlerAPI = (  evSecArrived     : nil;
                                      evAllTrdArrived  : nil;
                                      evKotirArrived   : nil;
                                      evOrderArrived   : OnOrder;
                                      evTradesArrived  : nil;
                                      evTransactionRes : nil;
                                      evAccountUpdated : nil;
                                      evSQLServerEvent : OnSQLCommand;
                                      evUserMessage    : nil;
                                      evTableUpdate    : nil;
                                      evLogEvent       : nil;
                                      );

      stockApi : tStockAPI       = (  stock_count      : 0;
                                      stock_list       : nil;
                                      pl_SetOrder      : nil;
                                      pl_DropOrder     : nil;


                                      pl_Connect       : nil;
                                      pl_Disconnect    : nil;
                                      pl_Hook          : OnHook;
                                      ev_BeforeDayOpen : nil;
                                      ev_AfterDayOpen  : nil;
                                      ev_BeforeDayClose: nil;
                                      ev_AfterDayClose : nil;
                                      ev_OrderCommit   : nil;
                                      ev_ServerStatus  : nil;
                                      pl_MoveOrder     : nil;


                                     );

      plugApi : tDataSourceApi   = (  plugname      : PlugName;
                                      plugflags     : plStockProvider or plEventHandler;
                                      pl_Init       : Init;
                                      pl_Done       : Done;
                                      stockapi      : @stockApi;
                                      newsapi       : nil;
                                      eventapi      : @ev_api);

var   pluginpath  : ansistring;
      server_api  : pServerAPI;

procedure log(const aevent: string; const aparams: array of const);
begin
  if assigned(server_api) and assigned(server_api^.LogEvent) then
    server_api^.LogEvent(pAnsiChar(format('TESTPLUG: ' + aevent, aparams)));
end;

function Init;
begin
  result:= 0;
  log('Test started ok', []);
end;

function Done;
begin
  result:= 0;
  log('Test shutdown complete...', []);
end;

function OnSQLCommand(aeventcode, aeventparameter: pchar; aresulthandle: longint): boolean;
var i : longint;
begin
  Randomize;
  result:= false;
  if assigned(server_api) and assigned(server_api^.SetSQLEventResult) then 
    if (CompareText(aeventcode, 'test') = 0) then begin
      with TResultBuilder.create do try
        WriteResultColumns(['srv_error', 'srv_description', 'srv_price', 'srv_date', 'srv_randomvalue'],
                           [itInteger, itString, itFloat, itDate, itInteger],
                           [0, 20, 0, 0]);
        WriteResultRow([0, 'no errors', 4.365, now, 0]);
        WriteResultRow([1, 'test', 6.2, now, 0]);
        for i:= 2 to 100 do
          WriteResultRow([i, aeventparameter, 0.0, date, random(100)]);
        server_api^.SetSQLEventResult(aresulthandle, memory, size);
      finally free; end;
      result:= true;
    end;
end;

procedure OnOrder(var order: tOrders; fields: tOrdersSet);
var mo  : tMoveOrder;
    res : tSetOrderResult;
begin
  if assigned(server_api) and assigned(server_api^.Move_SysOrder) then
    if (order.status = 'O') and (order.buysell = 'B') then begin
//      if (now - order.ordertime) < (1 / (24 * 60 * 60)) * 10 then begin
        fillchar(mo, sizeof(mo), 0);
        with mo do begin
          transaction   := 0;
          stock_id      := order.stock_id;
          level         := order.level;
          code          := order.code;
          orderno       := order.orderno;
          new_price     := order.price + 10;
          new_quantity  := 0;
          account       := order.account;
          flags         := 0;
          cid           := order.clientid;
        end;
        fillchar(res, sizeof(res), 0);
        server_api^.Move_SysOrder(mo, res);
//      end else log('order %d expired', [order.orderno]);
    end;
end;

function OnHook(params: pointer): longint;
var lst : tStringList;
    mo  : tMoveOrder;
    res : tSetOrderResult;
  function getparam(alist: tStringList; idx: longint): string;
  begin if assigned(alist) and (idx >= 0) and (idx < alist.count) then result:= alist.strings[idx] else setlength(result, 0); end;
begin
  result:= 0;
  if assigned(server_api) and assigned(server_api^.Move_SysOrder) then
    if assigned(params) then begin
      lst:= tStringList.create;
      try
        lst.CommaText:= pChar(params);
        if (comparetext(getparam(lst, 0), 'moveord') = 0) then begin
          with mo do begin
            transaction   := 0;
            stock_id      := 4;
            level         := 'FUTU';
            orderno       := strtoint(getparam(lst, 1));
            new_price     := strtofloat(getparam(lst, 2));
            new_quantity  := 0;
            account       := getparam(lst, 3);
            flags         := 0;
            cid           := getparam(lst, 3);
          end;
          fillchar(res, sizeof(res), 0);
          server_api^.Move_SysOrder(mo, res);
        end else log('unknown internal command', []);
      finally lst.free; end;
    end;
end;

function getDllAPI(srvapi: pServerAPI): pDataSourceAPI; cdecl;
begin
  server_api:= srvapi;
  if assigned(server_api) then result:= @plugapi else result:= nil;
end;

exports getDllAPI;

begin
  IsMultiThread:= true;
  pluginpath:= getcurrentdir;
end.
