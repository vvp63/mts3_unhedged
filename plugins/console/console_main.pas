{$i console_defs.pas}

unit console_main;

interface

uses  {$ifdef MSWINDOWS}
        windows, crt32,
      {$else}
        crt,
      {$endif}
      classes, sysutils, math, ansioem,
      tterm_api;

{$ifndef MSWINDOWS}
type  PCoord                 = ^TCoord;
      TCoord                 = packed record
        X                    : Smallint;
        Y                    : Smallint;
      end;
{$endif}

type  tCommandLine        = class(tObject)
      private
        fCSect            : tRTLCriticalSection;
        fUseOEM           : boolean;
        fCmdLine          : ansistring;
        fPrompt           : ansistring;
        fMasked           : boolean;

        fCommands         : tStringList;
        fCmdIndex         : longint;
        fDir              : boolean;

        fCommandQueue     : tStringList;

        {$ifdef enable_log_buffer}
        fLogBuffer        : tMemoryStream;
        fTempBuffer       : tMemoryStream;
        fBufferCSect      : tRTLCriticalSection;
        {$endif}

        function    fGetPrompt: ansistring;
        procedure   fSetPrompt(const aprompt: ansistring);
        function    fGetCommand: ansistring;
        procedure   fSetCommand(const acommand: ansistring);

      protected
        procedure   lock; virtual;
        procedure   unlock; virtual;
        {$ifdef enable_log_buffer}
        procedure   lockbuffer;
        procedure   unlockbuffer;
        {$endif}
        function    getdispcmdline: ansistring;

        function    addchar(asciichar: ansichar; actrl: boolean): boolean;
        function    popcommand(var acommand: ansistring): boolean;
      public
        constructor create;
        destructor  destroy; override;

        function    readlncommand(const aprompt: ansistring; amasked: boolean; aidleproc: tMainIdleHandler = nil): ansistring;
        procedure   outputcommandline;
        procedure   outputbuffer;

        procedure   executecommand(const acommand: ansistring);

        property    Masked: boolean read fMasked write fMasked;
        property    Prompt: ansistring read fGetPrompt write fSetPrompt;
        property    Command: ansistring read fGetCommand write fSetCommand;

        property    UseOEM: boolean read fUseOEM;
      end;
                                             
const commandline         : tCommandLine     = nil;
      consolesize         : tCoord           = (x:80; y:25);

      oldloghandler       : tWriteLogHandler = nil;

function  loghandler(logstr: pAnsiChar): longint; stdcall;

procedure initconsole(var aconsolesize: tCoord); stdcall;
function  readconsolecommandex(prompt: pAnsiChar; masked: boolean; buf: pAnsiChar; buflen: longint; idle: boolean; idleproc: tMainIdleHandler): longint; stdcall;
function  executeconsolecommand(acommand: pAnsiChar): longint; stdcall;

implementation

function loghandler(logstr: pAnsiChar): longint; stdcall;
{$ifdef enable_log_buffer}
const crlf    : pAnsiChar = #$0d#$0a#0;
      crlflen = 3;
{$endif}
begin
  if assigned(commandline) then with commandline do begin
    {$ifdef enable_log_buffer}
    lockbuffer;
    try
      if assigned(fLogBuffer) then begin
        fLogBuffer.Write(logstr^, strlen(logstr));
        fLogBuffer.Write(crlf^, crlflen);
        fLogBuffer.Seek(-1, soFromCurrent);
      end;
    finally unlockbuffer; end;
    {$else}
    lock;
    try
      gotoxy(1, wherey); clreol;
      if assigned(logstr) then begin
        if UseOEM then writeln(ansitooem(logstr)) else writeln(logstr);
      end;
      if assigned(commandline) then commandline.outputcommandline;
    finally unlock; end;
    {$endif}
  end;
  if assigned(oldloghandler) then result:= oldloghandler(logstr)
                             else result:= PLUGIN_OK;
end;

function copystr(const astr: ansistring): ansistring;
begin
  setlength(result, length(astr));
  if (length(result) > 0) then system.move(astr[1], result[1], length(result));
end;

{ tCommandLine }

constructor tCommandLine.create;
begin
  inherited create;
  {$ifdef MSWINDOWS}
  InitializeCriticalSection(fCSect);
  {$else}
  InitCriticalSection(fCSect);
  {$endif}
  {$ifdef enable_log_buffer}
  fLogBuffer:= tMemoryStream.create;
  fLogBuffer.SetSize($10000);
  fTempBuffer:= tMemoryStream.create;
  fTempBuffer.SetSize($10000);
    {$ifdef MSWINDOWS}
    InitializeCriticalSection(FBufferCSect);
    {$else}
    InitCriticalSection(fBufferCSect);
    {$endif}
  {$endif}
  {$ifdef MSWINDOWS}
  fUseOEM:= true;
  {$else}
  fUseOEM:= false;
  {$endif}
  setlength(fcmdline, 0);
  setlength(fprompt, 0);
  fCommands:= tStringList.create; fCmdIndex:= 0;
  fCommandQueue:= tStringList.create;
end;

destructor tCommandLine.destroy;
begin
  if assigned(fCommandQueue) then freeandnil(fCommandQueue);
  if assigned(fCommands) then freeandnil(fCommands);
  {$ifdef enable_log_buffer}
  outputbuffer;
  if assigned(fLogBuffer) then freeandnil(fLogBuffer);
  if assigned(fTempBuffer) then freeandnil(fTempBuffer);
    {$ifdef MSWINDOWS}
    DeleteCriticalSection(FBufferCSect);
    {$else}
    DoneCriticalSection(fBufferCSect);
    {$endif}
  {$endif}
  {$ifdef MSWINDOWS}
  DeleteCriticalSection(FCSect);
  {$else}
  DoneCriticalSection(FCSect);
  {$endif}
  inherited destroy;
end;

procedure tCommandLine.lock;
begin EnterCriticalSection(fCSect); end;

procedure tCommandLine.unlock;
begin LeaveCriticalSection(fCSect); end;

{$ifdef enable_log_buffer}
procedure tCommandLine.lockbuffer;
begin EnterCriticalSection(fBufferCSect); end;

procedure tCommandLine.unlockbuffer;
begin LeaveCriticalSection(fBufferCSect); end;
{$endif}

function tCommandLine.fGetCommand: ansistring;
begin
  lock;
  try result:= copystr(fCmdLine);
  finally unlock; end;
end;

function tCommandLine.fGetPrompt: ansistring;
begin
  lock;
  try result:= copystr(fPrompt);
  finally unlock; end;
end;

procedure tCommandLine.fSetCommand(const acommand: ansistring);
begin
  lock;
  try fCmdLine:= copystr(acommand);
  finally unlock; end;                                            
end;

procedure tCommandLine.fSetPrompt(const aprompt: ansistring);
begin
  lock;
  try fPrompt:= copystr(aprompt);
  finally unlock; end;
end;

function tCommandLine.getdispcmdline: ansistring;
var prmt : ansistring;
begin
  prmt:= Prompt;
  result:= Command;
  if fmasked and (length(result) > 0) then fillchar(result[1], length(result), '*');

  with consolesize do
    if (length(result) <= x - length(prmt) - 2) then begin
      result:= format('%s%s', [prmt, result]);
    end else begin
      result:= format('%s...%s', [prmt, system.copy(result, length(result) - (x - length(prmt) - 5), length(result))]);
    end;
end;

procedure tCommandLine.outputcommandline;
begin
  Lock;
  try
    gotoxy(1, wherey);
    if fUseOEM then write(ansitooem(getdispcmdline)) else write(getdispcmdline);
    clreol;
  finally Unlock; end;
end;

procedure tCommandLine.outputbuffer;
{$ifdef enable_log_buffer}
var datasize : longint;
{$endif}
begin
  {$ifdef enable_log_buffer}
  lock;
  try
    lockbuffer;
    try
      datasize:= fLogBuffer.Position;
      if (datasize > 0) then begin
        if (fTempBuffer.Size < datasize + 1) then fTempBuffer.Size:= datasize + 1;
        move(fLogBuffer.memory^, fTempBuffer.memory^, datasize + 1);
        fLogBuffer.Seek(0, soFromBeginning);
      end;
    finally unlockbuffer; end;

    if (datasize > 0) then begin
      gotoxy(1, wherey); clreol;
      if UseOEM then ANSIToOEMBuf(fTempBuffer.memory, datasize);
      write(pAnsiChar(fTempBuffer.memory));
      if assigned(commandline) then commandline.outputcommandline;
    end;
  finally unlock; end;
  {$endif}
end;

function tCommandLine.popcommand(var acommand: ansistring): boolean;
begin
  result:= false;
  lock;
  try
    if assigned(fCommandQueue) and (fCommandQueue.count > 0) then begin
      acommand:= fCommandQueue.strings[0];
      fCommandQueue.Delete(0);
      result:= true;
    end;
  finally unlock; end;
end;

function tCommandLine.addchar(asciichar: ansichar; actrl: boolean): boolean;
  function chg(delta:longint):longint;
  begin
    result:= fcmdindex + delta;
    if result < 0 then result:= fcommands.count - 1;
    if result >= fcommands.count then result:= 0;
  end;
begin
  result:= false;
  lock;
  try
    if actrl then begin
      if assigned(fcommands) then begin
        case asciichar of
          #72       : if (fcommands.count > 0) then begin
                        if not fdir then fcmdindex:= chg(-1);
                        fcmdline:= fcommands.strings[fcmdindex];
                        fcmdindex:= chg(-1);
                        fdir:= true;
                      end;
          #80       : if (fcommands.count > 0) then begin
                        if fdir then fcmdindex:= chg(1);
                        fcmdindex:= chg(1);
                        fcmdline:= fcommands.strings[fcmdindex];
                        fdir:= false;
                      end;
        end;
      end;
    end else begin
      case asciichar of
        #8        : setlength(fcmdline, length(fcmdline) - 1);
        #13       : result:= (length(fcmdline) > 0);
        #27       : setlength(fcmdline, 0);
        #32..#255 : if UseOEM then fcmdline:= fcmdline + OemToANSIChar(asciichar)
                              else fcmdline:= fcmdline + asciichar;
      end;
    end;
  finally unlock; end;
end;

function tCommandLine.readlncommand(const aprompt: ansistring; amasked: boolean; aidleproc: tMainIdleHandler): ansistring;
var fexecute : boolean;
    {$ifdef MSWINDOWS}
    ir       : tInputRecord;
    numread  : cardinal;
    {$else}
    ch       : ansichar;
    ctlkey   : boolean;
    {$endif}
begin
  if UseOEM then Prompt:= ansitooem(aprompt) else Prompt:= aprompt;
  fmasked:= amasked; fDir:= true;

  OutputCommandLine;

  setlength(result, 0); fexecute:= false;
  while not fexecute do begin
    {$ifdef MSWINDOWS}
    GetNumberOfConsoleInputEvents(hConsoleInput, numread);
    if (numread > 0) then ReadConsoleInput(hConsoleInput, ir, 1, numread);
    if (numread > 0) then begin
      if (ir.EventType = KEY_EVENT) and ir.Event.KeyEvent.bKeyDown then
        with ir.event.keyevent do
          if (asciichar = #0) then begin
            case wVirtualKeyCode of
              vk_up     : fexecute:= addchar(#72, true);
              vk_down   : fexecute:= addchar(#80, true);
            end;
          end else fexecute:= addchar(asciichar, false);
    {$else}
    if keypressed then begin
      ch:= ReadKey;
      ctlkey:= (ch = #0);
      if ctlkey then ch:= ReadKey;
      fexecute:= addchar(ch, false);
    {$endif}
      OutputCommandLine;
      if fexecute then begin
        result:= Command;
        Command:= '';
      end;
    end else begin
      OutputBuffer;
      fexecute:= popcommand(result);
      if fexecute then begin
        Command:= result;
        OutputCommandLine;
        Command:= '';
      end else begin
        if assigned(aidleproc) then aidleproc;
        sleep(1);
      end;
    end;
  end;

  if not fmasked and assigned(fcommands) then
    with fcommands do
      if (count > 0) then begin
        if (ansicomparetext(strings[count - 1], result) <> 0) then begin add(result); fcmdindex:= count - 1; end;
      end else begin
        add(result); fcmdindex:= count - 1;
      end;

  lock;
  try writeln;
  finally unlock; end;
end;

procedure tCommandLine.executecommand(const acommand: ansistring);
begin
  lock;
  try
    if assigned(fCommandQueue) then fCommandQueue.add(copystr(acommand));
  finally unlock; end;
end;

{ common functions }

procedure initconsole(var aconsolesize: tCoord);
{$ifdef MSWINDOWS}
var consoleinfo : TConsoleScreenBufferInfo;
{$endif}
begin
  {$ifdef MSWINDOWS}
  GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), consoleinfo);
  consolesize:= consoleinfo.dwSize;
  {$else}
  consolesize.x:= WindMaxX; consolesize.y:= WindMaxY;
  {$endif}
end;

function  readconsolecommandex(prompt: pAnsiChar; masked: boolean; buf: pAnsiChar; buflen: longint; idle: boolean; idleproc: tMainIdleHandler): longint;
var cmd : ansistring;
begin
  if assigned(commandline) and assigned(buf) and (buflen > 0) then begin
    cmd:= commandline.readlncommand(ansistring(prompt), masked, idleproc);
    result:= math.min(length(cmd), buflen - 1);
    system.move(cmd[1], buf^, result);
    buf[buflen - 1]:= #0;
  end else result:= 0;
end;

function  executeconsolecommand(acommand: pAnsiChar): longint;
begin
  if assigned(commandline) then begin
    if assigned(acommand) then commandline.executecommand(acommand);
    result:= PLUGIN_OK;
  end else result:= PLUGIN_ERROR;
end;

initialization
  commandline:= tCommandLine.create;

finalization
  if assigned(commandline) then freeandnil(commandline);

end.
