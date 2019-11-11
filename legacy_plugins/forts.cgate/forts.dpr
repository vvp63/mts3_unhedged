{$i forts_defs.pas}

{$ifdef FPC}
  {$M+}
{$endif}

library forts;

{$R *.res}

uses {$ifdef useexceptionhandler} ExcHandler, {$endif}
     {$ifdef UNIX}
       cthreads,
     {$endif}
     {$ifdef MSWINDOWS}
       windows, activex, inifiles, versioncontrol,
     {$else}
       baseunix, fclinifiles, threadmsg,
     {$endif}
     classes, sysutils, 
     ServerTypes, ServerAPI,
     classregistration,
     gateobjects, 
     forts_common, forts_transactions, forts_connection, forts_commandparser, forts_directory;

const  PLUGIN_ERROR                     = 0;
       PLUGIN_OK                        = 1;

function  Init(memmgr: pMemoryManager): longint;                                   cdecl; forward;
function  Done: longint;                                                           cdecl; forward;

function  Connect: longint;                                                        cdecl; forward;
function  Disconnect: longint;                                                     cdecl; forward;

procedure SetOrder(order:tOrder; comment:tOrderComment; var res:tSetOrderResult);  cdecl; forward;
procedure MoveOrder(moveorder:tMoveOrder; comment:tOrderComment;
                    var res:tSetOrderResult);                                      cdecl; forward;
procedure OrderCommit(commitresult:byte; orderno:int64);                           cdecl; forward;
procedure DropOrder(order: int64; flags: longint;
                    astock_id: longint; const alevel: TLevel; const acode: TCode;
                    var res: tSetOrderResult);                                     cdecl; forward;
procedure DropOrderEx(const droporder:tDropOrderEx; const comment:tOrderComment;
                      var res:tSetOrderResult);                                    cdecl; forward;

procedure AfterDayOpen;                                                            cdecl; forward;
procedure BeforeDayClose;                                                          cdecl; forward;
procedure ServerStatus(status:longint);                                            cdecl; forward;

function  FortsHook(params: pointer): longint;                                     cdecl; forward;

const fortsapi : tStockAPI      = ( stock_count       : stockcount;
                                    stock_list        : @stocklst;
                                    pl_SetOrder       : SetOrder;
                                    pl_DropOrder      : DropOrder;
                                    pl_Connect        : Connect;
                                    pl_Disconnect     : Disconnect;
                                    pl_Hook           : fortsHook;
                                    ev_BeforeDayOpen  : nil;
                                    ev_AfterDayOpen   : AfterDayOpen;
                                    ev_BeforeDayClose : BeforeDayClose;
                                    ev_AfterDayClose  : nil;
                                    ev_OrderCommit    : OrderCommit;
                                    ev_ServerStatus   : ServerStatus;
                                    pl_MoveOrder      : MoveOrder;
                                    pl_DropOrderEx    : DropOrderEx);

      plugapi  : tDataSourceAPI = ( plugname          : fortsplugname;
                                    plugflags         : plStockProvider;
                                    pl_Init           : Init;
                                    pl_Done           : Done;
                                    stockapi          : @fortsapi);


type  tCmdInterface     = class(tCommandInterface)
      public
        procedure   syntaxerror; override;
      published
        function    connect: boolean;
        function    disconnect: boolean;
      end;


const command_interface : tCmdInterface        = nil;

{ tCmdInterface }

procedure tCmdInterface.syntaxerror;
begin log('Incorrect command syntax: %s', [command]); end;

function tCmdInterface.connect: boolean;
begin
  result:= assigned(connection_list);
  if result then connection_list.BroadcastMessage(WM_CONNECT, 1, 0);
end;

function tCmdInterface.disconnect: boolean;
begin
  result:= assigned(connection_list);
  if result then connection_list.BroadcastMessage(WM_DISCONNECT, 0, 0);
end;

{ plugin functions }

function  Init (memmgr: pMemoryManager): longint;
{$ifdef MSWINDOWS}
const ver : TFileVersionInfo = ( major: 0; minor: 0; release: 0; build: 0);
{$endif}
begin
  result:= PLUGIN_ERROR;
  try
    {$ifdef MSWINDOWS}
    ExtractVersionInfo(ver);
    log('FORTS plugin version %d.%d [%d]', [ver.major, ver.minor, ver.build]);
    {$else}
    log('FORTS plugin version 0.1 [1]');
    {$endif}
    command_interface:= tCmdInterface.Create;

    result:= PLUGIN_OK;
  except on e: exception do log('Init exception: %s', [e.message]); end;
end;

function  InitEx(aexeinstance, alibinstance: HModule; alibname, ainifilename: pAnsiChar): longint; stdcall;
const section_system = 'system';
begin
  pluginfilename := expandfilename(alibname);
  pluginfilepath := includetrailingbackslash(extractfilepath(pluginfilename));
  pluginininame  := changefileext(pluginfilename, '.ini');

  if fileexists(pluginininame) then
    with tIniFile.create(pluginininame) do try
      stocklst[0].stock_id :=  readinteger(section_system, 'stock_id',       GetFortsStockID);
      log_stream_state     := (readinteger(section_system, 'logstreamstate', longint(log_stream_state)) <> 0);

      fortsbrokercode      :=  readstring(section_system,  'broker_code',    fortsbrokercode);

      gatewayinifilename   := AdjustFilePath(readstring(section_system, 'gatewayinifilename', gatewayinifilename), pluginfilepath);
      gatewaytblchema      := AdjustFilePath(readstring(section_system, 'gatewaytblcheme',    gatewaytblchema),    pluginfilepath);
      gatewaymsgschema     := AdjustFilePath(readstring(section_system, 'gatewaymsgscheme',   gatewaymsgschema),   pluginfilepath);

      cgate_env_params     :=  readstring(section_system,  'environment',    cgate_env_params);

      use_account_groups   := (readinteger(section_system, 'use_account_groups', 0) <> 0);
    finally free; end;

  EnvironmentSettings:= cgate_env_params;
  result:= PLUGIN_OK;
end;

function  Done: longint;
begin
  try
    if assigned(connection_list) then freeandnil(connection_list);
    if assigned(command_interface) then freeandnil(command_interface);
    log('Done');
  except on e: exception do log('Done exception: %s', [e.message]); end;
  result:= PLUGIN_OK;
end;

function  Connect: longint;
const warning_string     = 'Connect %s failed: %s exception: %s';
      sec_connections    = 'conections';
var   i, j               : longint;
      objclass           : tObjectClass;
      obj1               : tObject;
      connlist           : tStringList;
      clname             : ansistring;
      accgroups, acclist : tStringList;
begin
  result:= PLUGIN_ERROR;
  try
    if not assigned(connection_list) then connection_list:= tFortsConnectionList.create;
    if assigned(connection_list) then begin
      // disconnect all
      connection_list.UnregisterAllConnections;

      // cleanup global directory
      DirectoryCleanUp;

      // create streams, tables and connect
      if fileexists(pluginininame) then begin
        connlist:= tStringList.create;
        try
          with tIniFile.create(pluginininame) do try
            // load account groups here!!!
            if use_account_groups and assigned(forts_account_groups) then begin
              accgroups:= tStringList.create;
              acclist:=  tStringList.create;
              try
                readsection('accountgroups', accgroups);
                for i:= 0 to accgroups.count - 1 do begin
                  DecodeCommaText(readstring('accountgroups', accgroups[i], ''), acclist, ';');
                  for j:= 0 to acclist.count - 1 do
                    forts_account_groups.RegisterAccount(acclist[j], StrToIntDef(accgroups[i], 0));
                end;
              finally
                accgroups.free;
                acclist.free;
              end;
            end;

            // создаем соединения
            DecodeCommaText(readstring (sec_connections, 'connections',    ''), connlist, ';');
            for i:= 0 to connlist.Count - 1 do begin
              clname:= readstring(connlist[i], 'type', '');
              objclass:= get_class(clname);
              if assigned(objclass) then begin
                try
                  obj1:= objclass.NewInstance;
                  if assigned(obj1) then begin
                    if obj1 is tFortsConnection then begin
                      try
                        tFortsConnection(obj1).create(pluginininame, connlist[i]);
                      finally connection_list.RegisterConnection(tFortsConnection(obj1)); end;
                    end else obj1.FreeInstance;
                  end;
                except on e: exception do log(warning_string, ['connection', connlist[i], e.message]); end;
              end else log('Connect unable to locate class: %s', [])
            end;
          finally free; end;
        finally connlist.free; end;
      end;

      sleep(1000);

      connection_list.BroadcastMessage(WM_CONNECT, 0, 0);
    end;
    log('Connected ok');
    result:= PLUGIN_OK;
  except on e: exception do log('Connect exception: %s', [e.message]); end;
end;

function Disconnect: longint;
begin
  try
    if assigned(connection_list) then connection_list.UnregisterAllConnections;
    log('Disconnected ok');
  except on e: exception do log('Disconnect exception: %s', [e.message]); end;  
  result:= PLUGIN_OK;
end;

procedure SetOrder (order: tOrder; comment: tOrderComment; var res: tSetOrderResult);
begin
  if assigned(forts_transaction_queue) then begin
    forts_transaction_queue.AddNewOrder(order, comment, res);
  end else with res do begin
    accepted:= soRejected; ExtNumber:= 0; TEReply:= errNoGlobalQueue;
  end;
  if (res.Accepted <> soUnknown) and assigned(Server_API.SetTrsResult) then Server_API.SetTrsResult(res);
end;

procedure MoveOrder(moveorder:tMoveOrder; comment:tOrderComment; var res:tSetOrderResult);
begin
  if assigned(forts_transaction_queue) then begin
    forts_transaction_queue.AddMoveOrder(moveorder, comment, res);
  end else with res do begin
    accepted:= soRejected; ExtNumber:= 0; TEReply:= errNoGlobalQueue;
  end;
  if (res.Accepted <> soUnknown) and assigned(Server_API.SetTrsResult) then Server_API.SetTrsResult(res);
end;

procedure OrderCommit (commitresult: byte; orderno: int64);
begin end;

procedure DropOrder (order: int64; flags: longint;
                     astock_id: longint; const alevel: TLevel; const acode: TCode;
                     var res: tSetOrderResult);
begin
  if assigned(forts_transaction_queue) then begin
    forts_transaction_queue.AddDropOrder(order, flags, astock_id, alevel, acode, res);
  end else with res do begin
    accepted:= soRejected; ExtNumber:= 0; TEReply:= errNoGlobalQueue;
  end;
end;

procedure DropOrderEx(const droporder:tDropOrderEx; const comment:tOrderComment;
                      var res:tSetOrderResult);
begin
  if assigned(forts_transaction_queue) then begin
    forts_transaction_queue.AddDropOrderEx(droporder, comment, res);
  end else with res do begin
    accepted:= soRejected; ExtNumber:= 0; TEReply:= errNoGlobalQueue;
  end;
end;

procedure AfterDayOpen;
begin
//  if assigned(Transactions) then Transactions.cleanup;
  interlockedexchange(intraday, 1);
end;

procedure BeforeDayClose;
begin interlockedexchange(intraday, 0); end;

procedure ServerStatus (status: longint);
begin interlockedexchange(intraday, longint(status and (dayWasOpened or dayWasClosed) = dayWasOpened)); end;

function  FortsHook (params: pointer): longint;
begin
  if assigned(command_interface) and assigned(params) then
    if not command_interface.processcommand(pChar(params)) then log('Unknown command: %s', [pChar(params)]);
  result:= PLUGIN_OK;
end;

function  getDllAPI(srvapi: pServerAPI): pDataSourceAPI; cdecl;
begin
  Server_API := srvapi^;
  result     := @plugapi;
end;

exports   getDllAPI name 'getDllAPI',
          InitEX    name 'plg_initialize_ex';

begin
  IsMultiThread:= true;
  decimalseparator := '.';

end.
