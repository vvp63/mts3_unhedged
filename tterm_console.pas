{$i tterm_defs.pas}

unit tterm_console;

interface

uses  {$ifdef MSWINDOWS} windows, {$endif}
      classes, sysutils, math,
      tterm_api, tterm_pluginsupport, tterm_logger, tterm_classes;

function  getnextconsolecommand(aidleproc: tMainIdleHandler): ansistring;

function  readconsolecommandex(prompt: pAnsiChar; masked: boolean; buf: pAnsiChar; buflen: longint; idle: boolean; idleproc: tMainIdleHandler): longint; stdcall;
function  readconsolecommand(prompt: pAnsiChar; masked: boolean; buf: pAnsiChar; buflen: longint): longint; stdcall;
function  legacy_readconsolecommand(prompt: pAnsiChar; masked: boolean; buf: pAnsiChar; buflen: longint): longint; cdecl;
function  executeconsolecommand(acommand: pAnsiChar): longint; stdcall;

implementation

const command_queue : tThreadStringQueue = nil;

{ misc functions }

function  getnextconsolecommand(aidleproc: tMainIdleHandler): ansistring;
var buf : array[0..4096] of ansichar;
    res : boolean;
begin
  res:= assigned(command_queue);
  if res then result:= command_queue.pop(res);
  if not res then setstring(result, buf, readconsolecommandex('>', false, @buf, sizeof(buf), false, aidleproc));
end;

function  readconsolecommandex(prompt: pAnsiChar; masked: boolean; buf: pAnsiChar; buflen: longint; idle: boolean; idleproc: tMainIdleHandler): longint;
var procs    : array of pointer;
    i, count : longint;
begin
  setlength(procs, GetPluginsCount);
  count:= min(GetPluginsProcAddressList(@procs[0], length(procs) * sizeof(pointer), PLG_ReadConsoleCommandEx), length(procs));
  result:= 0;
  i:= 0;
  while i < count do begin
    if assigned(procs[i]) then result:= tReadConsoleCommandEx(procs[i])(prompt, masked, buf, buflen, idle, idleproc);
    if (result > 0) then i:= count else inc(i);
  end;
end;

function  readconsolecommand(prompt: pAnsiChar; masked: boolean; buf: pAnsiChar; buflen: longint): longint;
begin result:= readconsolecommandex(prompt, masked, buf, buflen, true, nil); end;

function  legacy_readconsolecommand(prompt: pAnsiChar; masked: boolean; buf: pAnsiChar; buflen: longint): longint;
begin result:= readconsolecommandex(prompt, masked, buf, buflen, true, nil); end;

function executeconsolecommand(acommand: pAnsiChar): longint;
const results  : array[boolean] of longint = (PLUGIN_ERROR, PLUGIN_OK);
var   procs    : array of pointer;
      i, count : longint;
begin
  setlength(procs, GetPluginsCount);
  count:= min(GetPluginsProcAddressList(@procs[0], length(procs) * sizeof(pointer), PLG_ExecuteConsoleCommand), length(procs));
  result:= PLUGIN_ERROR;
  i:= 0;
  while i < count do begin
    if assigned(procs[i]) then result:= tExecuteConsoleCommand(procs[i])(acommand);
    if (result = PLUGIN_OK) then i:= count else inc(i);
  end;
  if (result = PLUGIN_ERROR) and assigned(command_queue) then result:= results[command_queue.push(acommand)];
end;

exports
  executeconsolecommand     name SRV_ExecuteConsoleCommand,
  readconsolecommandex      name SRV_ReadConsoleCommandEx,
  readconsolecommand        name SRV_ReadConsoleCommand,
  legacy_readconsolecommand name 'srvReadBuf';

initialization
  command_queue:= tThreadStringQueue.create;

finalization
  if assigned(command_queue) then freeandnil(command_queue);

end.
