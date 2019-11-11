{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

{$M+}

library test;

{$R *.res}

uses  {$ifdef MSWINDOWS}
        windows,
      {$else}
        dynlibs,
      {$endif}
      sysutils,
      serverapi,
      tterm_api,
      tterm_commandparser;

const plugname                   = 'TEST';

function  Init_old(memmgr: pMemoryManager): longint;             cdecl; forward;
function  Done_old: longint;                                     cdecl; forward;
procedure UserMessage(aFromID, aFromUserName, aText: pAnsiChar); cdecl; forward;

const ev_api  : tEventHandlerAPI = (  evSecArrived     : nil;
                                      evAllTrdArrived  : nil;
                                      evKotirArrived   : nil;
                                      evOrderArrived   : nil;
                                      evTradesArrived  : nil;
                                      evTransactionRes : nil;
                                      evAccountUpdated : nil;
                                      evSQLServerEvent : nil;
                                      evUserMessage    : UserMessage;
                                      evTableUpdate    : nil;
                                    );

      plugApi : tDataSourceApi   = (  plugname         : PlugName;
                                      plugflags        : plEventHandler;
                                      pl_Init          : Init_old;
                                      pl_Done          : Done_old;
                                      stockapi         : nil;
                                      newsapi          : nil;
                                      eventapi         : @ev_api;
                                    );

type  tWriteLog_old     = procedure (event: pAnsiChar); cdecl;

type  tCmdInterface     = class(tCommandInterface)
      public
        procedure   syntaxerror; override;
      published
        function    testcommand: boolean;
        function    help: boolean;
      end;

const cmdintf     : tCmdInterface  = nil;
      logproc     : tWriteLog      = nil;
      server_api  : pServerAPI     = nil;
      plugin_api  : pDataSourceApi = nil;

      srv_getapis : tGetLegacyAPIs = nil;

procedure log(const alogstr: string);
begin if assigned(logproc) then logproc(pAnsiChar(format(plugname + ': %s', [alogstr]))); end;

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

function  Init(aexeinstance: longint; ainifilename: pChar): longint; stdcall;
begin
  cmdintf:= tCmdInterface.create;

  @logproc:= GetProcAddress(aexeinstance, SRV_WriteLog);
  @srv_getapis:= GetProcAddress(aexeinstance, SRV_GetLegacyAPIs);
  log('Test initialized.');
  result:= plugin_ok;
end;

function  Done: longint; stdcall;
begin
  if assigned(cmdintf) then freeandnil(cmdintf);

  result:= plugin_ok;
end;

function  Init_old(memmgr: pMemoryManager): longint;
begin
  cmdintf:= tCmdInterface.create;
  log('Test initialized (old API call)');
  result:= 0;
end;

function  Done_old: longint;
begin
  done;
  result:= 0;
end;

function SendReply (const afromid, afromuser, atext: ansistring): longint;
type pptrarray = ^tptrarray;
     tptrarray = array[0..0] of pDataSourceAPI;
var  apis      : pptrarray;
     i, count  : longint;
     reply     : ansistring;
begin
  reply:= format('ID: %s User: %s Text: %s', [afromid, afromuser, atext]);
  log(reply);
  if assigned(srv_getapis) and (srv_getapis(pointer(apis), count) = PLUGIN_OK) then begin
    for i:= 0 to count - 1 do
      if assigned(apis^[i]) and (apis^[i] <> plugin_api) then
        if (apis^[i]^.plugflags and plEventHandler <> 0) then with apis^[i]^ do
          if assigned(eventAPI) and assigned(eventAPI^.evUserMessage) then
            eventAPI^.evUserMessage(pansichar(afromid), pansichar(afromuser), pansichar(reply));
  end;
  result:= 0;
end;

procedure UserMessage(aFromID, aFromUserName, aText: pAnsiChar);
begin
  SendReply(ansistring(aFromID), ansistring(aFromUserName), ansistring(aText));
end;

function getDllAPI(srvapi: pServerAPI): pDataSourceAPI; cdecl;
begin
  server_api:= srvapi;
  plugin_api:= @plugapi;
  if assigned(server_api) then result:= plugin_api
                          else result:= nil;
end;

function  ProcessUserCommand(acommand: pChar): longint; stdcall;
const res : array[boolean] of longint = (plugin_error, plugin_ok);
begin result:= res[assigned(cmdintf) and (cmdintf.processcommand(acommand))]; end;


exports  Init                    name PLG_Initialize,
         Done                    name PLG_UnInitialize,
         getDllAPI,
         ProcessUserCommand      name PLG_ProcessUserCommand;

begin
  IsMultiThread:= true;
end.