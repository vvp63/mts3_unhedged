{$i console_defs.pas}

library console;

{$R *.res}

uses  {$ifdef MSWINDOWS}
        windows,
      {$else}
        dynlibs,
      {$endif}
      sysutils,
      serverapi,
      tterm_api,
      console_main;

const plugname      = 'CONSOLE';

const logproc       : tWriteLog           = nil;
      setloghandler : tSetWriteLogHandler = nil;

procedure log(const alogstr: ansistring); overload;
begin if assigned(logproc) then logproc(pAnsiChar(format(plugname + ': %s', [alogstr]))); end;

procedure log(const afmt: ansistring; const aparams: array of const); overload;
begin log(format(afmt, aparams)); end;

{ other plugin functions }

function  Init(aexeinstance: HModule; ainifilename: pAnsiChar): longint; stdcall;
begin
  initconsole(consolesize);
  logproc:= GetProcAddress(aexeinstance, SRV_WriteLog);
  setloghandler:= GetProcAddress(aexeinstance, SRV_SetWriteLogHandler);
  if assigned(setloghandler) then oldloghandler:= setloghandler(loghandler);
  log('Plugin initialized');
  result:= PLUGIN_OK;
end;

function  Done: longint; stdcall;
begin
  log('Plugin finished');
  if assigned(setloghandler) then setloghandler(oldloghandler);
  result:= PLUGIN_OK;
end;

exports  Init                    name PLG_Initialize,
         Done                    name PLG_UnInitialize,
         readconsolecommandex    name PLG_ReadConsoleCommandEx,
         executeconsolecommand   name PLG_ExecuteConsoleCommand;

begin
  IsMultiThread:= true;
end.