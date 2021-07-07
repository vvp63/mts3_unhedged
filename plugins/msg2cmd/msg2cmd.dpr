{$i msg2cmd_defs.pas}

library msg2cmd;

{$R *.res}

uses  {$ifdef MSWINDOWS}
        windows,
      {$else}
        dynlibs,
      {$endif}
      sysutils,
      serverapi,
      tterm_api;

const plugname        = 'MSG2CMD';

type  tExecuteCommand = function (acommand: pAnsiChar): longint; stdcall;

const logproc         : tWriteLog           = nil;
      executecommand  : tExecuteCommand     = nil;

function  Init(memmgr: pMemoryManager): longint;                   cdecl; forward;
function  Done: longint;                                           cdecl; forward;
procedure OnUserMessage(aFromID, aFromUserName, aText: pAnsiChar); cdecl; forward;

const EventAPI        : TEventHandlerAPI = ( evSecArrived      : nil;
                                             evAllTrdArrived   : nil;
                                             evKotirArrived    : nil;
                                             evOrderArrived    : nil;
                                             evTradesArrived   : nil;
                                             evTransactionRes  : nil;
                                             evAccountUpdated  : nil;
                                             evSQLServerEvent  : nil;
                                             evUserMessage     : OnUserMessage;
                                             evTableUpdate     : nil;
                                             evLogEvent        : nil;
                                           );

const plugApi : tDataSourceApi           = ( plugname      : PlugName;
                                             plugflags     : plEventHandler;
                                             pl_Init       : Init;
                                             pl_Done       : Done;
                                             stockapi      : nil;
                                             newsapi       : nil;
                                             eventapi      : @EventAPI;
                                           );

procedure OnUserMessage(aFromID, aFromUserName, aText: pAnsiChar); cdecl;
begin 
  if assigned(executecommand) then 
    if (AnsiCompareText(aFromID, 'SOLID') = 0) then executecommand(aText); 
end;

{ log functions }

procedure log(const alogstr: ansistring); overload;
begin if assigned(logproc) then logproc(pAnsiChar(format(plugname + ': %s', [alogstr]))); end;

procedure log(const afmt: ansistring; const aparams: array of const); overload;
begin log(format(afmt, aparams)); end;

{ other plugin functions }

function  InitEx(aexeinstance, alibinstance: HModule; alibname, ainifilename: pAnsiChar): longint; stdcall;
begin
  logproc:= GetProcAddress(aexeinstance, SRV_WriteLog);
  executecommand:= GetProcAddress(aexeinstance, SRV_ExecuteConsoleCommand);
  result:= PLUGIN_OK;
end;

function Init(memmgr: pMemoryManager): longint; cdecl;
begin
  log('Plugin initialized');
  result:= 0;
end;

function Done: longint; cdecl;
begin
  executecommand = nil;
  log('Plugin finished');
  result:= 0;
end;

function getDllAPI(srvapi: pServerAPI): pDataSourceAPI; cdecl;
begin
//  Server_API := srvapi^; // not neede for now
  result     := @plugapi;
end;

exports  getDllAPI name 'getDllAPI',
         InitEX    name 'plg_initialize_ex';

begin
  IsMultiThread:= true;
end.