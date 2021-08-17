{$M+}

unit mts3lx_start;


interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$else}
        cmem,
        cthreads,
      {$endif}
      dynlibs,
      sysutils,
      cmdparser,
      serverapi,
      servertypes,
      tterm_api,
      tterm_commandparser,
      mts3lx_logger;


//  Функции-обработчики инициализации и завершения

function  Init(memmgr: pMemoryManager): longint;  cdecl;
function  Done: longint; cdecl;

function  InitEx(aexeinstance, alibinstance: HModule; alibname, ainifilename: pAnsiChar): longint; stdcall;
function  ProcessUserCommand(acommand: pChar): longint; stdcall;

//  Обработчики приходящих событий

procedure MTS_SecArrived (var sec:tSecurities; changedfields:TSecuritiesSet); cdecl;
procedure MTS_AllTrdArrived (var alltrds:tAllTrades); cdecl;
procedure MTS_KotirArrived (kotirdata: pointer); cdecl;
procedure MTS_OrderArrived (var order: tOrders; fields: tOrdersSet); cdecl;
procedure MTS_TradesArrived (var trade: tTrades; fields: tTradesSet); cdecl;
procedure MTS_TransactionRes (var aresult: tSetOrderResult); cdecl;
function  MTS_SQLServerEvent (aeventcode, aeventparameter: pchar; aresulthandle: longint) : boolean; cdecl;
procedure MTS_UserMessage (aFromID, aFromUsername, aText: pchar); cdecl;
// procedure MTS_TableUpdated (aEventType: longint; astock_id: longint; alevel: tLevel); cdecl; forward;

function  MTS_HOOK (params: pointer): longint; cdecl;
function  MTS_Connect: longint; cdecl;
function  MTS_Disconnect: longint; cdecl;
procedure MTS_AfterDayOpen; cdecl;
procedure MTS_BeforeDayClose; cdecl;
procedure MTS_TradeSessionStatus (status:longint); cdecl;



// API виртуальных бирж

const      PlugName                    = 'MTS3';
const      MTSPlugName                 = 'MTS3';

const
  stockcount    = 1;

type
  TMSESL        = array [0..stockcount - 1] of TStockRec;

const                                                                            // Массив описателей виртуальных бирж
  stklst     : TMSESL           = ((stock_id          : 128;                  // Идентификатор виртуальной биржи MTS
                                    stock_name        : MTSPlugName)            // Имя виртуальной биржи MTS
                                  );

const
  MyStockAPI   : TStockAPI        = ( stock_count       : stockcount;              // Количество виртуальных бирж
                                    stock_list        : @stklst;                 // Указатель на массив описателей виртуальных бирж
                                    pl_SetOrder       : nil;                     // Функция "поставить заявку"
                                    pl_DropOrder      : nil;                     // Функция "снять заявку"
                                    pl_Connect        : MTS_Connect;             // Функция "соединиться с ТС биржи"
                                    pl_Disconnect     : MTS_Disconnect;          // Функция "разорвать соединение с ТС биржи"
                                    pl_Hook           : MTS_HOOK;                // Функция обработчика командной строки сервера
                                    ev_BeforeDayOpen  : nil;                     // Событие "перед открытием дня"
                                    ev_AfterDayOpen   : MTS_AfterDayOpen;        // Событие "после открытия дня"
                                    ev_BeforeDayClose : MTS_BeforeDayClose;      // Событие "перед закрытием дня"
                                    ev_AfterDayClose  : nil;                     // Событие "после закрытия дня"
                                    ev_OrderCommit    : nil;                     // Событие "Заявка обработана торговым сервером"
                                    ev_ServerStatus   : MTS_TradeSessionStatus); // Событие "Статус сервера (торгового дня)"

                                                                                 // API обработчика событий
  MyEventAPI   : TEventHandlerAPI = ( evSecArrived    : MTS_SecArrived;          // Событие "строка таблицы финансовые инструменты"
                                    evAllTrdArrived   : MTS_AllTrdArrived;       // Событие "строка таблицы все сделки"
                                    evKotirArrived    : MTS_KotirArrived;        // Событие "строка таблицы стаканы котировок"
                                    evOrderArrived    : MTS_OrderArrived;        // Событие "строка таблицы заявки"
                                    evTradesArrived   : MTS_TradesArrived;       // Событие "строка таблицы сделки"
                                    evTransactionRes  : MTS_TransactionRes;      // Событие "результат транзакции"
                                    evAccountUpdated  : nil;                     // Событие "торговый счет обновлен"
                                    evSQLServerEvent  : MTS_SQLServerEvent;      // Событие SQL-сервера
                                    evUserMessage     : MTS_UserMessage;         // Сообщения пользователя
                                    evTableUpdate     : nil;                     // Сообщение о приходе пакета
                                  );




const plugApi : tDataSourceApi   = (  plugname      : PlugName;
                                      plugflags     : plEventHandler or plStockProvider;
                                      pl_Init       : Init;
                                      pl_Done       : Done;
                                      stockapi      : @MyStockAPI;
                                      newsapi       : nil;
                                      eventapi      : @MyEventAPI;
                                    );


type  tWriteLog_old     = procedure (event: pAnsiChar); cdecl;

const
      {$ifdef plg_new_style}
      logproc     : tWriteLog      = nil;
      {$else}
      logproc     : tWriteLog_old = nil;
      {$endif}
      server_api  : pServerAPI     = nil;
      plugin_api  : pDataSourceApi = nil;


type  tCmdInterface     = class(tCommandInterface)
      public
        procedure   syntaxerror; override;
      published
        function    testcommand: boolean;
        function    help: boolean;
      end;

const cmdintf     : tCmdInterface  = nil;


implementation

uses mts3lx_main, mts3lx_common, mts3lx_queue;

{ tCmdInterface }

procedure tCmdInterface.syntaxerror;
begin log(format('incorrect command syntax: %s', [command])); end;

function tCmdInterface.testcommand: boolean;
begin log('TestCommand executed!'); result:= true; end;

function tCmdInterface.help: boolean;
var tmp : string;
begin
  result:= false;
  if not checkeoln then begin
    tmp:= GetNextWord;
    if (comparetext(tmp, plugname) = 0) then begin
      if checkeoln then log('sample help text') else syntaxerror;
      result:= true;
    end;
  end;
end;




{ other plugin functions }

function Init(memmgr: pMemoryManager): longint;   cdecl;
begin result:= 0; end;


function  InitEx(aexeinstance, alibinstance: HModule; alibname, ainifilename: pAnsiChar): longint; stdcall;
const section_system = 'system';
begin
  ExeFileName   := expandfilename(alibname);
  ExeFilePath   := includetrailingbackslash(extractfilepath(ExeFileName));
  gIniFileName  := ExeFilePath + gIniFileName;
  gLogFileTempl :=  ExeFilePath + format(gLogFileTempl, [FormatDateTime('h_m_s', Now)]);

  InitMTSLogger;
  cmdintf:= tCmdInterface.create;
  log('MTS3LX_START. InitEx', []);
  MTS3_Init;
  result:= PLUGIN_OK;
end;



function  Done: longint; cdecl;
begin
  MTS3_Done;
  if assigned(cmdintf) then freeandnil(cmdintf);
  DoneMTSLogger;
  result:= plugin_ok;
end;


function  ProcessUserCommand(acommand: pChar): longint; stdcall;
const res : array[boolean] of longint = (plugin_error, plugin_ok);
begin result:= res[assigned(cmdintf) and (cmdintf.processcommand(acommand))]; end;





{ обработчик командной строки }

function MTS_ParseCommand (const fromid, fromuser, params: string): longint;
var vqueue  : tQueueItem;
    vrelcode  : longint;
begin

  //Log('MTS_ParseCommand [%s %s] %s', [fromid, fromuser, params]);

  result:= -1;

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
        msglog(fromid, fromuser, 'Get Vol command', []);
      end;

      if (paramlow[0] = 'start') then begin
        gGlobalHedgeStatus := true;  gGlobalOrderStatus  :=  true;
        msglog(fromid, fromuser, 'Started', []);
      end;

      if (paramlow[0] = 'stop') then begin
        gGlobalOrderStatus  :=  false;
        msglog(fromid, fromuser, 'Stoped', []);
      end;

      if (paramlow[0] = 'log') then begin
        gLogLevel := StrToIntDef(paramlow[1], gLogLevel);
        FileLog('MTS_ParseCommand SetLogLevel %d',[gLogLevel], 0);
     //   msglog(fromid, fromuser, 'Set Log level %d', [gLogLevel]);
      end;


      if (paramlow[0] = 'reloadmts3') then begin

        vrelcode  :=  StrToIntDef(paramlow[1], 0);
        if (vrelcode = ReloadApproveCode) then begin
          MTS_ReloadMTS;
       //   msglog(fromid, fromuser, 'MTS3 reloaded', []);
        end
        else begin
          ReloadApproveCode := 100 + Random(900);
          msglog(fromid, fromuser, 'MTS3 reload code %d', [ReloadApproveCode]);
        end;

      end;


      if (paramlow[0] = 'starthedge') then begin
        gGlobalHedgeStatus := true;
       // msglog(fromid, fromuser, 'Hedge is ON', []);
      end;

      if (paramlow[0] = 'stophedge') then begin
        gGlobalHedgeStatus  :=  false;
       // msglog(fromid, fromuser, 'Hedge is OFF', []);
      end;

      if (paramlow[0] = 'starthedgepd') then begin
        gUseHedgePD := true;
        FileLog('MTS_ParseCommand starthedgepd', [], 1);
        msglog(fromid, fromuser, 'HedgePD is ON', []);
      end;

      if (paramlow[0] = 'stophedgepd') then begin
        gUseHedgePD  :=  false;
        FileLog('MTS_ParseCommand stophedgepd', [], 1);
        msglog(fromid, fromuser, 'HedgePD is OFF', []);
      end;








      {
      if (paramlow[0] = 'rehedgepd') then begin
        PDRehedgeCommand  :=  StrToIntDef(paramlow[1], 0);
        msglog(fromid, fromuser, 'Rehedging PD in %d', [PDRehedgeCommand]);
      end;

      if (paramlow[0] = 'usepdrehedge') then begin
        vrelcode  :=  StrToIntDef(paramlow[1], 0);
        if vrelcode <> 1 then vrelcode  :=  0;
        if (vrelcode = 1) then UsePDRehedge := true else UsePDRehedge := false;
        msglog(fromid, fromuser, 'Rehedging PD status %d', [vrelcode]);
      end;
      }
      if (paramlow[0] = 'reloadpdkf') then begin
        PDReloadKfCommand  :=  StrToIntDef(paramlow[1], 0);
        msglog(fromid, fromuser, 'Reloading HedgeKf for TP %d', [PDReloadKfCommand]);
      end;
      

      result:= 0;
      
    except on e:exception do Filelog('ParseCommand Exception: %s', [e.message], 0); end;
  finally free; end;
  filelog('MTS_ParseCommand finished', [], 2);

end;


{ common plugin functions }
// инициализация плагина
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



// завершение работы плагина
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

// обработчик таблицы "финансовые инструменты"
procedure MTS_SecArrived (var sec: tSecurities; changedfields: TSecuritiesSet);
var vqueue  : tQueueItem;
begin
  FileLog(' MTS_SecArrived %s', [sec.code], 4);
  if assigned(AllQueue) then begin
    vqueue.evTime:=  Now; vqueue.evType:= ev_type_sec; vqueue.evSec:= sec;
    AllQueue.push(vqueue);
  end;

end;

// обработчик таблицы "все сделки"
procedure MTS_AllTrdArrived (var alltrds:tAllTrades);
begin
  //
end;

// обработчик таблицы "котировки"
procedure MTS_KotirArrived (kotirdata: pointer);
var vqueue  : tQueueItem;
    i       : longint;
    dataptr : pchar;
begin

  if assigned(AllQueue) then begin
    vqueue.evTime:=  Now; vqueue.evType:= ev_type_quots;
    vqueue.evQuots  := pKotUpdateHdr(kotirdata)^;
    SetLength(vqueue.QItems, vqueue.evQuots.kotcount);
    dataptr:= pchar(kotirdata) + sizeof(tKotUpdateHdr);
    for i:= low(vqueue.QItems) to high(vqueue.QItems) do begin
      vqueue.QItems[i]  := pKotUpdateItem(dataptr)^;
      inc(dataptr, sizeof(tKotUpdateItem));
    end;
    AllQueue.push(vqueue);
  end;

end;

// обработчик таблицы "заявки"
procedure MTS_OrderArrived (var order: tOrders; fields: tOrdersSet);
var vqueue  : tQueueItem;
begin

  if assigned(AllQueue) then begin
    vqueue.evTime:=  Now; vqueue.evType:= ev_type_order; vqueue.evOrder:= order;
    AllQueue.push(vqueue);
  end;

end;

// обработчик таблицы "сделки"
procedure MTS_TradesArrived (var trade: tTrades; fields: tTradesSet);
var vqueue  : tQueueItem;
begin

  if assigned(AllQueue) then begin
    vqueue.evTime:=  Now; vqueue.evType:= ev_type_trade; vqueue.evTrade:= trade;
    AllQueue.push(vqueue);
  end;

end;

// обработчик результата транзакции, необходим когда результат в
// момент постановки заявки не известен (soUnknown)
procedure MTS_TransactionRes (var aresult: tSetOrderResult);
var vqueue  : tQueueItem;
begin

  if assigned(AllQueue) then begin
    vqueue.evTime:=  Now; vqueue.evType:= ev_type_soresult; vqueue.evSoResult:= aresult;
    AllQueue.push(vqueue);
  end;

end;

// обработчик событий SQL
function  MTS_SQLServerEvent (aeventcode, aeventparameter: pchar; aresulthandle: longint) : boolean;
begin
  result:=  false;
  FileLog('SQLCommand    : %s  %s', [aeventcode, aeventparameter], 0);
  if (comparetext(aeventcode, MTSPlugName) = 0) then begin
    MTS_ParseCommand('', '', string(aeventparameter));
    result:=  true;
  end;
  filelog('MTS_SQLServerEvent finished', [], 2);
end;







// обработчик управляющих сообщений клиента
procedure MTS_UserMessage (aFromID, aFromUsername, aText: pchar);
begin MTS_ParseCommand(string(aFromID), string(aFromUsername), string(aText)); end;

// обработчик командной строки сервера
function MTS_HOOK (params: pointer): longint;
begin result:= MTS_ParseCommand('', '', string(params)); end;

// обработчики открытия, закрытия и статуса торговой сессии сервера
// обработчик команды сервера OPEN DAY
procedure MTS_AfterDayOpen; begin GlobalTradeSessionStarted:= true; end;
// обработчик команды сервера CLOSE DAY
procedure MTS_BeforeDayClose; begin GlobalTradeSessionStarted:= false; end;
// обработчик статуса торговой сессии при перезапуске в середине дня
procedure MTS_TradeSessionStatus (status:longint);
begin GlobalTradeSessionStarted:= ((status and (dayWasOpened or dayWasClosed)) = dayWasOpened); end;

// пустые функции "соединения"
// соединиться с сервером биржи
function MTS_Connect: longint; begin
  GlobalConnected:= true; result:= 0;
end;
// разорвать соединение с сервером биржи
function MTS_Disconnect: longint; begin
  GlobalConnected:= false; result:= 0;
end;



end.
