{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit mts3lx_start;

interface

uses  {$ifdef UNIX}
        dynlibs,
      {$else}
        windows,
      {$endif}
      sysutils,
      serverapi,
      tterm_api;

const      plugname                    = 'MTS3';
const      MTSPlugName                 = 'MTS3';

function  Init_old(memmgr: pMemoryManager): longint;   cdecl;
function  Done_old: longint;                           cdecl;

//  Обработчики приходящих событий
{
procedure MTS_SecArrived (var sec:tSecurities; changedfields:TSecuritiesSet); cdecl;
procedure MTS_AllTrdArrived (var alltrds:tAllTrades); cdecl;
procedure MTS_KotirArrived (kotirdata: pointer); cdecl;
procedure MTS_OrderArrived (var order: tOrders; fields: tOrdersSet); cdecl;
procedure MTS_TradesArrived (var trade: tTrades; fields: tTradesSet); cdecl;
procedure MTS_TransactionRes (var aresult: tSetOrderResult); cdecl;
function  MTS_SQLServerEvent (aeventcode, aeventparameter: pansichar; aresulthandle: longint) : boolean; cdecl;
}
procedure MTS_UserMessage (aFromID, aFromUsername, aText: pansichar); cdecl;
// procedure MTS_TableUpdated (aEventType: longint; astock_id: longint; alevel: tLevel); cdecl; forward;


function  MTS_HOOK (params: pointer): longint; cdecl;
function  MTS_Connect: longint; cdecl;
function  MTS_Disconnect: longint; cdecl;
procedure MTS_AfterDayOpen; cdecl;
procedure MTS_BeforeDayClose; cdecl;
procedure MTS_TradeSessionStatus (status:longint); cdecl;


// API обработчика событий


// API виртуальных бирж


const
  stockcount    = 1;


type
  TMSESL        = array [0..stockcount - 1] of TStockRec;

const                                                                 
  stklst     : TMSESL           = ((stock_id          : 128;          
                                    stock_name        : MTSPlugName)
                                  );

const
  MyStockAPI   : TStockAPI      = ( stock_count       : stockcount;              
                                    stock_list        : @stklst;                 
                                    pl_SetOrder       : nil;                     
                                    pl_DropOrder      : nil;                     
                                    pl_Connect        : nil; //MTS_Connect;      
                                    pl_Disconnect     : nil; //MTS_Disconnect;   
                                    pl_Hook           : nil; //MTS_HOOK;         
                                    ev_BeforeDayOpen  : nil;
                                    ev_AfterDayOpen   : nil; //MTS_AfterDayOpen;
                                    ev_BeforeDayClose : nil; //MTS_BeforeDayClose;
                                    ev_AfterDayClose  : nil;
                                    ev_OrderCommit    : nil;
                                    ev_ServerStatus   : nil; //MTS_TradeSessionStatus;
                                    pl_MoveOrder      : nil;
                                    pl_DropOrderEx    : nil;
                                  );
                                                                                 
  MyEventAPI   : TEventHandlerAPI = ( evSecArrived    : nil; //MTS_SecArrived;   
                                    evAllTrdArrived   : nil; //MTS_AllTrdArrived;
                                    evKotirArrived    : nil; //MTS_KotirArrived; 
                                    evOrderArrived    : nil; //MTS_OrderArrived; 
                                    evTradesArrived   : nil; //MTS_TradesArrived;
                                    evTransactionRes  : nil; //MTS_TransactionRes;
                                    evAccountUpdated  : nil;
                                    evSQLServerEvent  : nil; //MTS_SQLServerEvent;
                                    evUserMessage     : MTS_UserMessage;
                                    evTableUpdate     : nil;
                                    evLogEvent        : nil;
                                  );


const plugApi : tDataSourceApi   = (  plugname      : PlugName;
                                      plugflags     : plEventHandler; // or plStockProvider;
                                      pl_Init       : Init_old;
                                      pl_Done       : Done_old;
                                      stockapi      : nil; //@MyStockAPI;
                                      newsapi       : nil;
                                      eventapi      : @MyEventAPI;
                                    );


type  tWriteLog_old     = procedure (event: pAnsiChar); cdecl;

const logproc     : tWriteLog_old  = nil;
      server_api  : pServerAPI     = nil;
      plugin_api  : pDataSourceApi = nil;

implementation

{ other plugin functions }

function  Init_old(memmgr: pMemoryManager): longint;
begin
//  gLogFileTempl  :=  format(gLogFileTempl, [FormatDateTime('h_m_s', Now)]);
//  InitMTSLogger;
//  log('MTS3LX_START. Init_old');
//  MTS3_Init;
  result:= 0;
end;

function  Done_old: longint;
begin
//  MTS3_Done;
//  DoneMTSLogger;
  @logproc:= nil;
  result:= 0;
end;

{
procedure MTS_SecArrived (var sec: tSecurities; changedfields: TSecuritiesSet);
var vqueue  : tQueueItem;
begin
  FileLog('MTS_SecArrived  : %s %g', [sec.code, sec.lastdealprice], 2);
  if assigned(AllQueue) then begin
    vqueue.evTime:=  Now; vqueue.evType:= ev_type_sec; vqueue.evSec:= sec;
    AllQueue.push(vqueue);
  end;
end;
}

function MTS_ParseCommand (const fromid, fromuser, params: ansistring): longint;
//var vqueue  : tQueueItem;
//    vrelcode  : longint;
begin

  //Log('MTS_ParseCommand [%s %s] %s', [fromid, fromuser, params]);

  result:= -1;
{
  with tCommandParser.create(params) do try
    try

      if (paramlow[0] = 'init') or (paramlow[0] = 'i') then begin
        if assigned(AllQueue) then begin
          vqueue.evTime:=  Now; vqueue.evType:= ev_type_command; vqueue.evCommand:= 'i';
          AllQueue.push(vqueue);
        end;
        msglog(fromid, fromuser, 'Get Init Command', []);
      end;

      if (paramlow[0] = 'vol') then begin
        if assigned(AllQueue) then begin
          vqueue.evTime:=  Now; vqueue.evType:= ev_type_command; vqueue.evCommand:= 'vol';
          AllQueue.push(vqueue);
        end;
      end;

      if (paramlow[0] = 'start') then begin
        gGlobalHedgeStatus := true;  gGlobalOrderStatus  :=  true;
      end;

      if (paramlow[0] = 'stop') then begin
        gGlobalOrderStatus  :=  false;
      end;

      if (paramlow[0] = 'log') then begin
        gLogLevel := StrToIntDef(paramlow[1], gLogLevel);
        FileLog('MTS_ParseCommand SetLogLevel %d',[gLogLevel], 0);
      end;

//      if (paramlow[0] = 'starthedge') then begin
//        gGlobalHedgeStatus := true;
//        msglog(fromid, fromuser, 'Hedge is ON', [ReloadApproveCode]);
//      end;
//
//      if (paramlow[0] = 'stophedge') then begin
//        gGlobalHedgeStatus  :=  false;
//        msglog(fromid, fromuser, 'Hedge is OFF', [ReloadApproveCode]);
//      end;
//
//
//      if (paramlow[0] = 'starthedgepd') then begin
//        gUseHedgePD := true;
//        msglog(fromid, fromuser, 'HedgePD is ON', [ReloadApproveCode]);
//      end;
//
//      if (paramlow[0] = 'stophedgepd') then begin
//        gUseHedgePD  :=  false;
//        msglog(fromid, fromuser, 'HedgePD is OFF', [ReloadApproveCode]);
//      end;


//      if (paramlow[0] = 'reloadmts3') then begin
//
//        vrelcode  :=  StrToIntDef(paramlow[1], 0);
//        if (vrelcode = ReloadApproveCode) then MTS_ReloadMTS
//        else begin
//          ReloadApproveCode := 100 + Random(900);
//          msglog(fromid, fromuser, 'MTS3 reload code %d', [ReloadApproveCode]);
//        end;
//
//      end;
//
//      if (paramlow[0] = 'rehedgepd') then begin
//        PDRehedgeCommand  :=  StrToIntDef(paramlow[1], 0);
//        msglog(fromid, fromuser, 'Rehedging PD in %d', [PDRehedgeCommand]);
//      end;
//
//      if (paramlow[0] = 'usepdrehedge') then begin
//        vrelcode  :=  StrToIntDef(paramlow[1], 0);
//        if vrelcode <> 1 then vrelcode  :=  0;
//        if (vrelcode = 1) then UsePDRehedge := true else UsePDRehedge := false;
//        msglog(fromid, fromuser, 'Rehedging PD status %d', [vrelcode]);
//      end;
//
//      if (paramlow[0] = 'reloadpdkf') then begin
//        PDReloadKfCommand  :=  StrToIntDef(paramlow[1], 0);
//        msglog(fromid, fromuser, 'Reloading HedgeKf for TP %d', [PDReloadKfCommand]);
//      end;

      result:= 0;

    except on e:exception do Filelog('ParseCommand Exception: %s', [e.message], 0); end;
  finally free; end;

  filelog('MTS_ParseCommand finished', 2);
}
end;

{ common plugin functions }
{
function MTS_Init (MemoryManager: PMemoryManager): longint;
const ver : TFileVersionInfo = ( major: 0; minor: 0; release: 0; build: 0);

begin
  result:=  -1;
  Randomize;
  ReloadApproveCode := 100 + Random(900);

  try
    ExtractVersionInfo(ver);
    FileLog('       STARTING MTS3 version %d.%d [%d]',[ver.major, ver.minor, ver.build], 0);

    with MTSGetIni do begin
      if not InitDataBase(ReadString('database', 'server',   '(local)'),
                          ReadString('database', 'username', 'sa'),
                          ReadString('database', 'password', 'password'),
                          ReadString('database', 'database', 'mts')) then begin
        Filelog('Unable to connect database!',[], 0);
      end else Filelog('Connected to database %s!',[ConnectionRegistry.dbname], 0);
    end;

    MTS_LoadIniParams;

    InitScheldue;
    InitMTSAvg;
    InitMTSSec;
    InitMTSTP;
    InitOTManager;
    InitMTSQueue;

    result:= 0;
  except on e:exception do Filelog('INIT Exception: %s', [e.message], 0); end;
end;

function MTS_Done: longint;
begin
  result:= -1;
  try

    DoneMTSQueue;
    DoneOTManager;
    DoneMTSTP;
    DoneMTSSec;
    DoneMTSAvg;
    DoneScheldue;

    DoneDataBase;
    FileLog('       MTS3 FINISHED SUCSESSFULLY!', 0);
  except on e:exception do Filelog('DONE Exception: %s', [e.message], 0); end;
end;

procedure MTS_ReloadMTS;
begin
  FileLog('Reloading MTS3', [], 0);
  gGlobalOrderStatus  :=  false;
  gGlobalHedgeStatus  :=  false;
  DoneMTSQueue;
  DoneOTManager;
  DoneMTSTP;
  DoneMTSSec;
  DoneMTSAvg;
  DoneScheldue;
  MTS_LoadIniParams;
  InitScheldue;
  InitMTSAvg;
  InitMTSSec;
  InitMTSTP;
  InitOTManager;
  InitMTSQueue;
end;
}

{
procedure MTS_LoadIniParams;
var vUserCount, i : longint;
begin
  with MTSGetIni do begin
    LogLevel          := ReadInteger('logfile', 'loglevel', LogLevel);
    TerminalLevel     := ReadInteger('logfile', 'terminallevel', TerminalLevel);
    DefaultToId       :=  ReadString('clientmessage', 'clientid', '');
    vUserCount        :=  ReadInteger('clientmessage', 'usercount', 0);

    UsePDRehedge        :=  ReadBool('avgprocesses', 'usepdrehedge', false);
  //  UseKRecount         :=  ReadBool('avgprocesses', 'usekrecount', false);
    UsePortfolioRehedge :=  ReadBool('avgprocesses', 'useportfoliorehedge', false);
    AvgTPDelay          :=  ReadInteger('avgprocesses', 'avgtpdelay', AvgTPDelay);

    SetLength(DefaultToUser, vUserCount);
    for i:=low(DefaultToUser) to high(DefaultToUser) do
      DefaultToUser[i] :=  ReadString('clientmessage', format('clientuser%d', [i + 1]), '');
  end;
end;
}

{ event handlers }

{
procedure MTS_SecArrived (var sec: tSecurities; changedfields: TSecuritiesSet);
var vqueue  : tQueueItem;
begin
  FileLog(' MTS_SecArrived %s', [sec.code], 4);
  if assigned(AllQueue) then begin
    vqueue.evTime:=  Now; vqueue.evType:= ev_type_sec; vqueue.evSec:= sec;
    AllQueue.push(vqueue);
  end;

end;

procedure MTS_AllTrdArrived (var alltrds:tAllTrades);
begin
end;

procedure MTS_KotirArrived (kotirdata: pointer);
var vqueue  : tQueueItem;
    i       : longint;
    dataptr : pansichar;
begin

  if assigned(AllQueue) then begin
    vqueue.evTime:=  Now; vqueue.evType:= ev_type_quots;
    vqueue.evQuots  := pKotUpdateHdr(kotirdata)^;
    SetLength(vqueue.QItems, vqueue.evQuots.kotcount);
    dataptr:= pansichar(kotirdata) + sizeof(tKotUpdateHdr);
    for i:= low(vqueue.QItems) to high(vqueue.QItems) do begin
      vqueue.QItems[i]  := pKotUpdateItem(dataptr)^;
      inc(dataptr, sizeof(tKotUpdateItem));
    end;
    AllQueue.push(vqueue);
  end;
end;

procedure MTS_OrderArrived (var order: tOrders; fields: tOrdersSet);
var vqueue  : tQueueItem;
begin
  if assigned(AllQueue) then begin
    vqueue.evTime:=  Now; vqueue.evType:= ev_type_order; vqueue.evOrder:= order;
    AllQueue.push(vqueue);
  end;
end;

procedure MTS_TradesArrived (var trade: tTrades; fields: tTradesSet);
var vqueue  : tQueueItem;
begin
  if assigned(AllQueue) then begin
    vqueue.evTime:=  Now; vqueue.evType:= ev_type_trade; vqueue.evTrade:= trade;
    AllQueue.push(vqueue);
  end;
end;

procedure MTS_TransactionRes (var aresult: tSetOrderResult);
var vqueue  : tQueueItem;
begin
  if assigned(AllQueue) then begin
    vqueue.evTime:=  Now; vqueue.evType:= ev_type_soresult; vqueue.evSoResult:= aresult;
    AllQueue.push(vqueue);
  end;

end;

function  MTS_SQLServerEvent (aeventcode, aeventparameter: pansichar; aresulthandle: longint) : boolean;
begin
  result:=  false;
  FileLog('SQLCommand    : %s  %s', [aeventcode, aeventparameter], 0);
  if (comparetext(aeventcode, MTSPlugName) = 0) then begin
    MTS_ParseCommand('', '', ansistring(aeventparameter));
    result:=  true;
  end;
  filelog('MTS_SQLServerEvent finished', [], 2);
end;
}

function SendReply (const afromid, afromuser, atext: ansistring): longint;
//type pptrarray = ^tptrarray;
//     tptrarray = array[0..0] of pDataSourceAPI;
var  reply     : ansistring;
//     apis      : pptrarray;
//     i, count  : longint;
begin
  reply:= format('ID: %s User: %s Text: %s', [afromid, afromuser, atext]);
{
  log(reply);
  if assigned(srv_getapis) and (srv_getapis(pointer(apis), count) = PLUGIN_OK) then begin
    for i:= 0 to count - 1 do
      if assigned(apis^[i]) and (apis^[i] <> plugin_api) then
        if (apis^[i]^.plugflags and plEventHandler <> 0) then with apis^[i]^ do
          if assigned(eventAPI) and assigned(eventAPI^.evUserMessage) then
            eventAPI^.evUserMessage(pansichar(afromid), pansichar(afromuser), pansichar(reply));
  end;
}
  result:= 0;
end;


procedure MTS_UserMessage (aFromID, aFromUsername, aText: pansichar);
begin
//  MTS_ParseCommand(ansistring(aFromID), ansistring(aFromUsername), ansistring(aText));
//  MTS_ParseCommand('', '', ansistring(aText));
  SendReply(ansistring(aFromID), ansistring(aFromUserName), ansistring(aText));
end;

function MTS_HOOK (params: pointer): longint;
begin result:= MTS_ParseCommand('', '', ansistring(params)); end;

procedure MTS_AfterDayOpen; begin
//  GlobalTradeSessionStarted:= true;
end;

procedure MTS_BeforeDayClose;
begin
//  GlobalTradeSessionStarted:= false;
end;

procedure MTS_TradeSessionStatus (status:longint);
begin
//  GlobalTradeSessionStarted:= ((status and (dayWasOpened or dayWasClosed)) = dayWasOpened);
end;

function MTS_Connect: longint; begin
//  GlobalConnected:= true;
  result:= 0;
end;

function MTS_Disconnect: longint; begin
//  GlobalConnected:= false;
  result:= 0;
end;

end.
