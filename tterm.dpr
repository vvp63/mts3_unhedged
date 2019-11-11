{$i tterm_defs.pas}

{$ifndef UNIX}
  {$APPTYPE CONSOLE}
{$endif}

program tterm;

uses  tterm_sys,
      {$ifdef MSWINDOWS}
        windows, activex,
      {$else}
        unix, baseunix,
      {$endif}
      sysutils,
      crc32,
      tterm_common, tterm_utils;

{$R *.res}

const lib_engine = {$ifdef MSWINDOWS}'ttermengine.dll'{$else}'ttermengine'{$endif};

function  srv_execute_engine: longint; stdcall; external lib_engine;

function  srv_writelog(logstr: pAnsiChar): boolean; stdcall; external lib_engine;
procedure srv_flushlog; stdcall; external lib_engine;

function  srv_executeconsolecommand(acommand: pAnsiChar): boolean; stdcall; external lib_engine;

function  log(const logstr: ansistring): boolean; overload;
begin result:= srv_writelog(pAnsiChar(logstr)); end;
function  log(const logstr: ansistring; const params: array of const): boolean; overload;
begin result:= srv_writelog(pAnsiChar(format(logstr, params))); end;

{$ifdef MSWINDOWS}
function CtrlHandler(CtrlType: Longint): bool; stdcall;
const reasons : array[0..6] of pAnsiChar = ('ctrl-C', 'ctrl-break', 'close', nil, nil, 'logoff', 'shutdown');
begin
  result:= true;
  if ((CtrlType >= low(reasons)) and (CtrlType <= high(reasons))) then
    log('shutting down... reason: %s code: %d', [reasons[CtrlType], CtrlType]);
  srv_flushlog;
  srv_executeconsolecommand('exit');
end;
{$else}
procedure DoSig(sig: cint); cdecl;
begin
  log('shutting down... reason: sigint');
  srv_flushlog;
  srv_executeconsolecommand('exit');
end;
{$endif}

{$ifdef MSWINDOWS}
const MultMutexName   = 'Global\ITServer%.8x';
var   hMultMutex  : THandle;
{$endif}

begin
  {$ifdef MSWINDOWS}
  CoInitializeEx(nil, COINIT_MULTITHREADED);
  try
  {$endif}
    {$ifdef MSWINDOWS}
    hMultMutex:= CreateMutex(nil, true, pChar(format(MultMutexName, [StrCRC32(GetModuleName(HInstance))])));
    if (GetLastError = 0) then begin
    {$endif}

      {$ifdef MSWINDOWS}
      SetConsoleCtrlHandler(@CtrlHandler, true);
      {$else}
      fpSignal(SIGINT, SignalHandler(@DoSig));
      {$endif}

      chdir(ExeFilePath);

      {$ifdef MSWINDOWS}
      decimalseparator:= '.'; timeseparator:= ':';
      {$endif}

      srv_execute_engine;
      
    {$ifdef MSWINDOWS}
      closehandle(hMultMutex);
    end else log('Duplicate server instance!');
    {$endif}
  {$ifdef MSWINDOWS}
  finally CoUninitialize; end;
  {$endif}
end.
