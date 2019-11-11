{$i tterm_defs.pas}

{$M+}

library ttermengine;

uses  tterm_sys,
      {$ifdef MSWINDOWS}
        windows, activex, inifiles, versioncontrol,
      {$else}
        baseunix, fclinifiles, crt,
      {$endif}
      sysutils,
      tterm_api, tterm_common, tterm_console, tterm_pluginsupport, tterm_logger,
      tterm_commandparser, tterm_utils, tterm_legacy_apis, tterm_tables,
      servertypes, serverapi,
      legacy_database, legacy_sectable, legacy_alltrdtable, legacy_tradestable, legacy_orderstable, legacy_kottable, legacy_setorder,
      legacy_repotables, legacy_accounts, legacy_misc_api, legacy_transactions;

{$R *.res}

type  tCmdInterface     = class(tCommandInterface)
      private
        function    processlegacycommand(aaction: tLegacyPluginCommandAction): boolean;
        function    processlegacyopenday(aaction: boolean): boolean;
      public
        function    processcommand(const acommand: ansistring): boolean; override;
        procedure   syntaxerror; override;
      published
        function    exit: boolean;
        function    quit: boolean;
        function    bye: boolean;
        function    help: boolean;
        function    log: boolean;
        function    hook: boolean;
        function    connect: boolean;
        function    disconnect: boolean;
        function    open: boolean;
        function    close: boolean;
        function    msg: boolean;
      end;

{$ifdef MSWINDOWS}
const exeversion          : TFileVersionInfo  = ( major: 0; minor: 0; release: 0; build: 0; );
{$endif}

const server_terminated   : boolean           = false;
      commandinterface    : tCmdInterface     = nil;

{ tCommandInterface }

function tCmdInterface.processcommand(const acommand: ansistring): boolean;
var procs    : array of pointer;
    count    : longint;
begin
  if not server_terminated and (length(acommand) > 0) then begin
    tterm_logger.log('>%s', [acommand]);
    result:= false;
    // broadcast command to plugins
    setlength(procs, GetPluginsCount);
    if (length(procs) > 0) then begin
      count:= min(GetPluginsProcAddressList(@procs[0], length(procs) * sizeof(pointer), PLG_ProcessUserCommand), length(procs));
      while (count > 0) do begin
        result:= result or (tProcessUserCommand(procs[count - 1])(pAnsiChar(acommand)) <> PLUGIN_ERROR);
        dec(count);
      end;
    end;
    // execute standard handler if needed
    if not result then result:= inherited processcommand(acommand);
    // write error if not processed
    if not result then tterm_logger.log('ERROR: unknown command: %s', [acommand]);
  end else result:= false;
end;

procedure tCmdInterface.syntaxerror;
begin tterm_logger.log('ERROR: incorrect command syntax: %s', [command]); end;

function tCmdInterface.exit: boolean;
begin if checkeoln then server_terminated:= true else syntaxerror; result:= true; end;
function tCmdInterface.quit: boolean; begin result:= self.exit; end;
function tCmdInterface.bye: boolean; begin result:= self.exit; end;
function tCmdInterface.help: boolean;
begin if checkeoln then typehelp else syntaxerror; result:= true; end;

function tCmdInterface.log: boolean;
var tmp : ansistring;
begin
  result:= not checkeoln;
  if result then begin
    tmp:= GetNextWord;
    if (CompareText(tmp, 'flush')  = 0) then begin
      result:= checkeoln;
      if result then log_flush;
    end else
    if (CompareText(tmp, 'on') = 0) then begin
      result:= checkeoln;
      if result then log_start;
    end else
    if (CompareText(tmp, 'off') = 0) then begin
      result:= checkeoln;
      if result then log_stop;
    end else result:= false;
  end;
  if not result then syntaxerror;
  result:= true;
end;

function tCmdInterface.processlegacycommand(aaction: tLegacyPluginCommandAction): boolean;
var plgname : ansistring;
begin
  result:= not checkeoln;
  if result then begin
    plgname:= GetNextWord;
    checkeoln;
    if not ExecuteLegacyPluginCommand(aaction, plgname, RestLine) then
      tterm_logger.log('ERROR: plugin %s not found or command is not supported', [plgname]);
  end;
  if not result then syntaxerror;
  result:= true;
end;

function tCmdInterface.hook: boolean;
begin result:= processlegacycommand(act_plg_hook); end;
function tCmdInterface.connect: boolean;
begin result:= processlegacycommand(act_plg_connect); end;
function tCmdInterface.disconnect: boolean;
begin result:= processlegacycommand(act_plg_disconnect); end;

function tCmdInterface.processlegacyopenday(aaction: boolean): boolean;
const aevents : array[boolean, boolean] of longint = ((evBeforeDayOpen,  evAfterDayOpen),
                                                      (evBeforeDayClose, evAfterDayClose));
      alogstr : array[boolean] of ansistring = ('opened', 'closed');
      status  : array[boolean] of longint = (dayWasClosed, dayWasOpened);
var   tmp     : boolean;
begin
  result:= not checkeoln;
  if result then begin
    if (CompareText(GetNextWord, 'day') = 0) then begin
      result:= checkeoln;
      if assigned(transaction_registry) then begin
        if (transaction_registry.DayOpenStatus = status[aaction]) then begin
          // execute "before" event
          ExecuteLegacyPluginEvent(aevents[aaction, false]);
          if aaction then tmp:= transaction_registry.move_to_archive(IncludeTrailingBackSlash(ArchivePath), auto_open_day) // close day
                     else tmp:= transaction_registry.initializetransactions(IncludeTrailingBackSlash(ExeFilePath) + transactions_file_name, true, initial_transaction_id); // open day
          if tmp then begin
            // execute "after" event
            ExecuteLegacyPluginEvent(aevents[aaction, true]);
            tterm_logger.log('Day %s successfully', [alogstr[aaction]]);
          end;
        end else tterm_logger.log('Day was already %s!', [alogstr[aaction]]);
      end;
    end;
  end;
  if not result then syntaxerror;
  result:= true;
end;

function tCmdInterface.open: boolean;
begin result:= processlegacyopenday(false); end;

function tCmdInterface.close: boolean;
begin result:= processlegacyopenday(true); end;

function tCmdInterface.msg: boolean;
var address     : ansistring;
    id, msgtext : ansistring;
    tmp         : longint;
begin
  result:= not checkeoln;
  if result then begin
    address:= GetNextWord;
    result:= not checkeoln;
    if result then msgtext:= restline else setlength(msgtext, 0);
    if (comparetext(address, '/all') = 0) then begin
      srvSendBroadcastMessage(0, pAnsiChar(msgtext));
      result:= true;
    end else begin
      tmp:= pos('@', address);
      if (tmp > 1) and (tmp < 6) then begin
        id:= copy(address, 1, tmp - 1);
        delete(address, 1, tmp);
        srvSendUserMessage(pAnsiChar(id), pAnsiChar(address), pAnsiChar(msgtext));
        result:= true;
      end;
    end;
  end;
  if not result then syntaxerror;
  result:= true;
end;


{ common functions }

procedure LoadConfig(const aininame: ansistring);
begin
  if fileexists(aininame) then
    with tIniFile.Create(aininame) do try
      ArchivePath:= ExpandFileName(IncludeTrailingBackSlash(ReadString(LegacySettings, 'archive', ArchivePath)));
      auto_open_day:= (ReadInteger(LegacySettings, 'auto_open_day', longint(auto_open_day)) <> 0);
      store_all_trades:= (ReadInteger(LegacySettings, 'store_all_trades', longint(store_all_trades)) <> 0);
      initial_transaction_id:= StrToInt64Def(ReadString(LegacySettings, 'initial_transaction_id', '1'), 1);
    finally free; end;
end;

{$ifdef MSWINDOWS}
function CtrlHandler(CtrlType: Longint): bool; stdcall;
const reasons : array[0..6] of pAnsiChar = ('ctrl-C', 'ctrl-break', 'close', nil, nil, 'logoff', 'shutdown');
begin
  result:= true;
  if ((CtrlType >= low(reasons)) and (CtrlType <= high(reasons))) then
    log('shutting down... reason: %s code: %d', [reasons[CtrlType], CtrlType]);
  log_flush;
  if assigned(commandline) then commandline.executecommand('exit');
end;
{$endif}

var   day_open_status : longint = dayWasOpened;

function execute_engine: longint; stdcall;
var i           : longint;
    {$ifdef MSWINDOWS}
    consoleinfo : TConsoleScreenBufferInfo;
    {$endif}
begin
  GetMemoryManager(memorymanager);
  {$ifdef MSWINDOWS}
  SetConsoleCtrlHandler(@CtrlHandler, true);
  {$endif}

  {$ifdef MSWINDOWS}
  decimalseparator:= '.'; timeseparator:= ':';
  {$endif}

  commandinterface:= tCmdInterface.create;

  // set console size
  {$ifdef MSWINDOWS}
  SetConsoleScreenBufferSize(GetStdHandle(STD_OUTPUT_HANDLE), consolesize);
  GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), consoleinfo);
  consolesize:= consoleinfo.dwSize;
  {$else}
  consolesize.x:= WindMaxX; consolesize.y:= WindMaxY;
  {$endif}

  log('');
  {$ifdef MSWINDOWS}
  ExtractVersionInfo(exeversion);
  with exeversion do log('Starting: %s ver. %d.%d.%d build: %d', [changefileext(ExeFileName, ''), major, minor, release, build]);
  {$else}
  log('Starting: %s', [changefileext(ExeFileName, '')]);
  {$endif}

  LoadConfig(IniFileName);

  if not db_initialize then log('ERROR: Database init failed!');

  try
    if assigned(AllTradesRegistry) then AllTradesRegistry.store_all_trades:= store_all_trades;

    if assigned(transaction_registry) then begin
      transaction_registry.initializetransactions(ExeFilePath + transactions_file_name, auto_open_day, initial_transaction_id);
      day_open_status:= transaction_registry.DayOpenStatus;
    end;

    if assigned(StockList)        then StockList.InitializeStocks;          // stock parameters (name, flags)
    if assigned(LevelAttr)        then LevelAttr.InitializeLevelAttr;       // board parameters (facevalue, marketcode)
    if assigned(StockAccountList) then StockAccountList.InitializeAccounts; // accounts translation

    LoadAndInstallPlugins(hinstance, pAnsiChar(IniFileName));
    try
      // init plugins
      log('Starting plugins...');
      for i:= 0 to plugin_apis_count - 1 do
        if assigned(plugin_apis[i]) then
          with plugin_apis[i]^ do if assigned(pl_Init) then pl_Init(@memorymanager);

      // connect stocks
      for i:= 0 to plugin_apis_count - 1 do
        if assigned(plugin_apis[i]) then with plugin_apis[i]^ do begin
          if (plugflags and plStockProvider <> 0) then with stockAPI^ do begin
            if assigned(ev_ServerStatus) then ev_ServerStatus(day_open_status);
            if assigned(pl_Connect) then pl_Connect;
          end;
        end;

      log('Initialization complete');

      // execute main program cycle
      if assigned(commandline) and assigned(commandinterface) then
        while not server_terminated do
          commandinterface.processcommand(commandline.readlncommand('>', false, commandinterface.processmessagequeue));

      log('Disconnecting plugins...');

      // disconnect data source plugins
      for i:= 0 to plugin_apis_count - 1 do
        if assigned(plugin_apis[i]) then with plugin_apis[i]^ do begin
          if (plugflags and plStockProvider <> 0) then with stockAPI^ do begin
            if assigned(pl_Disconnect) then pl_Disconnect;
          end;
        end;

      if assigned(transaction_registry) then transaction_registry.finalizetransactions;

    finally
      log('Terminating plugins...');
      FreePlugins;
    end;
  except on e: exception do log('exception: %s', [e.message]); end;

  log('Done');

  log_flush;

  if assigned(commandinterface) then freeandnil(commandinterface);

  result:= plugin_ok;
end;

exports
  {$ifndef MSWINDOWS}
  srvGetAccount             name srv_GetAccount,
  srvGetAccountData         name srv_GetAccountData,
  srvReleaseAccount         name srv_ReleaseAccount,

  srvAddAllTradesRec        name srv_AddAllTradesRec,

  srvKotirovkiLock          name srv_KotirovkiLock,
  srvClearKotirovkiTbl      name srv_ClearKotirovkiTbl,
  srvAddKotirovkiRec        name srv_AddKotirovkiRec,
  srvKotirovkiUnlock        name srv_KotirovkiUnlock,

  srvSetCommissBySec        name srv_SetStockComissionBySec,

  srvSetAdditionalPrm       name srv_SetStockAdditionalParams,

  srvGetLastNews            name srv_GetLastNews,
  srvAddNewsRec             name srv_AddNewsRec,

  srvSetClientLimit         name srv_SetClientLimit,

  srvSendUserMessage        name srv_SendUserMessage,
  srvSendBroadcastMessage   name srv_SendBroadcastMessage,

  srvSetSQLEventResult      name srv_SetSQLEventResult,

  srvOrdersLock             name srv_OrdersBeginUpdate,
  srvAddOrdersRec           name srv_AddOrdersRec,
  srvGetOrdersRec           name srv_GetOrdersRec,
  srvOrdersUnLock           name srv_OrdersEndUpdate,

  srvUpdateOrders           name srv_UpdateOrders,
  srvCleanupOrders          name srv_CleanupOrders,

  srvUpdateFirmsRec         name srv_UpdateFirmsRec,

  srvAddFirmsRec            name srv_AddFirmsRec,
  srvAddSettleCodesRec      name srv_AddSettleCodesRec,

  srvAddSecuritiesRec       name srv_AddSecuritiesRec,
  srvGetSecuritiesRec       name srv_GetSecuritiesRec,
  srvUpdateSecurities       name srv_UpdateSecuritiesRec,
  srvCleanupSecurities      name srv_CleanupSecuritiesRec,

  srvSetTransactionResult   name srv_SetTransactionResult,

  srvSetSystemOrder         name srv_SetSystemOrder,
  srvMoveSystemOrder        name srv_MoveSystemOrder,
  srvDropOrder              name srv_DropOrder,
  srvDropOrderEx            name srv_DropOrderEx,

  srvTradesLock             name srv_TradesBeginUpdate,
  srvAddTradesRec           name srv_AddTradesRec,
  srvTradesUnLock           name srv_TradesEndUpdate,

  srvUpdateTrades           name srv_UpdateTrades,
  srvCleanupTrades          name srv_CleanupTrades,

  executeconsolecommand     name SRV_ExecuteConsoleCommand,
  readconsolecommand        name SRV_ReadConsoleCommand,
  legacy_readconsolecommand name 'srvReadBuf',

  GetLegacyAPIs             name SRV_GetLegacyAPIs,

  legacy_logevent           name 'srvLogEvent',
  writelog                  name SRV_WriteLog,
  log_start                 name SRV_StartLog,
  log_flush                 name SRV_FlushLog,
  log_stop                  name SRV_StopLog,

  GetPluginsCount           name SRV_GetPluginsCount,
  GetPluginsHandles         name SRV_GetPluginsHandles,
  GetPluginsProcAddressList name SRV_GetPluginsProcAddressList,

  EnumerateTables           name SRV_EnumerateTables,
  EnumerateTableRecords     name SRV_EnumerateTableRecords,
  {$endif}

  execute_engine            name 'srv_execute_engine';

begin
end.
