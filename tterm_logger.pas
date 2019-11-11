{$i tterm_defs.pas}

unit tterm_logger;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$else}
        baseunix,
      {$endif}
      classes, sysutils,
      tterm_api, tterm_common, tterm_utils;

{$ifndef MSWINDOWS}
const INVALID_HANDLE_VALUE= -1;
{$endif}

const MaximumBufferSize   = 65535;

const log_date_format     = 'yyyy-mm-dd hh":"nn":"ss"."zzz';

type  tWriteLogHandler    = function (logstr: pAnsiChar): longint; stdcall;

type  tLogBuffer          = class(tMemoryStream)
      private
        FLogging          : boolean;
        FLogHandle        : tHandle;
        FCsect            : TRTLCriticalSection;
      protected
        function    OpenLogFile(const alogname: ansistring): longint; virtual;
        procedure   CloseLogFile;
        function    isEmpty: boolean; virtual;
      public
        constructor create;
        destructor  destroy; override;
        procedure   lock;
        procedure   unlock;
        procedure   log(alogstring: pAnsiChar; alength: longint); overload; virtual;
        procedure   log(const alogstring: ansistring); overload; virtual;
        procedure   flush; virtual;
        procedure   start; virtual;
        procedure   stop; virtual;
      end;

const WriteLogHandler  : tWriteLogHandler = nil;
      logbuffer        : tLogBuffer       = nil;

const deflogname       : ansistring       = 'tterm.log';

procedure legacy_logevent(aevent: pAnsiChar); cdecl;

function  writelog(logstr: pAnsiChar): boolean; stdcall;
procedure writeexceptionlog(buffer: pAnsiChar; BufferSize: Integer; CallStack, Registers, CustomInfo: pAnsiChar); stdcall;

function  log(const logstr: ansistring): boolean; overload;
function  log(const logstr: ansistring; const params: array of const): boolean; overload;

procedure log_start; stdcall;
procedure log_flush; stdcall;
procedure log_stop; stdcall;

implementation

{ tLogBuffer }

constructor tLogBuffer.create;
begin
  inherited create;
  {$ifdef MSWINDOWS}
  InitializeCriticalSection(FCSect);
  {$else}
  InitCriticalSection(FCSect);
  {$endif}
  FLogHandle:= INVALID_HANDLE_VALUE;
  FLogging:= {$ifdef filelog} true {$else} false {$endif} ;
  setsize(MaximumBufferSize + 1024);
end;

destructor tLogBuffer.destroy;
begin
  CloseLogFile;
  {$ifdef MSWINDOWS}
  DeleteCriticalSection(FCSect);
  {$else}
  DoneCriticalSection(FCSect);
  {$endif}
  inherited destroy;
end;

procedure tLogBuffer.lock;
begin
  EnterCriticalSection(FCSect);
end;

procedure tLogBuffer.unlock;
begin
  LeaveCriticalSection(FCSect);
end;

function tLogBuffer.isEmpty: boolean;
begin
  result:= (position = 0);
end;

procedure tLogBuffer.log(alogstring: pAnsiChar; alength: longint);
begin
  if flogging and (alength > 0) then write(alogstring^, alength);
  if (position > MaximumBufferSize) then flush;
end;

procedure tLogBuffer.log(const alogstring: ansistring);
begin
  if flogging and (length(alogstring) > 0) then write(alogstring[1], length(alogstring));
  if (position > MaximumBufferSize) then flush;
end;

function tLogBuffer.OpenLogFile(const alogname: ansistring): longint;
begin
  {$ifdef MSWINDOWS}
  FLogHandle := Integer(CreateFile(pAnsiChar(alogname),
                                   GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ,
                                   nil,
                                   OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL,
                                   0));
  {$else}
  FLogHandle := fpOpen(pAnsiChar(alogname), O_RdWr or O_Creat);
  {$endif}
  if (FLogHandle <> INVALID_HANDLE_VALUE) then FileSeek(FLogHandle, 0, 2);
  result:= FLogHandle;
end;

procedure tLogBuffer.CloseLogFile;
begin
  flush;
  {$ifdef MSWINDOWS}
  if (FLogHandle <> INVALID_HANDLE_VALUE) then FileClose(FLogHandle);
  {$else}
  if (FLogHandle <> INVALID_HANDLE_VALUE) then fpClose(FLogHandle);
  {$endif}
  FLogHandle:= INVALID_HANDLE_VALUE;
end;

procedure tLogBuffer.flush;
begin
  if not isEmpty then try
    if (FLogHandle = INVALID_HANDLE_VALUE) then OpenLogFile(deflogname);
    if (FLogHandle <> INVALID_HANDLE_VALUE) then FileWrite(FLogHandle, memory^, position);
  finally position:= 0; end;
end;

procedure tLogBuffer.start;
begin
  FLogging:= true;
end;

procedure tLogBuffer.stop;
begin
  FLogging:= false;
  CloseLogFile;
end;

// ������� ��� ��������� log-������

const crlf            : pAnsiChar  = #$0d#$0a;
      hline           : pAnsiChar  = '--------------------------'#$0d#$0a;

//��������� ��������� � ������

procedure legacy_logevent(aevent: pAnsiChar); cdecl;
begin writelog(aevent); end;

function  writelog(logstr: pAnsiChar): boolean; stdcall;
var buf : ansistring;
begin
  if assigned(logstr) and (strlen(logstr) > 0) then begin
    buf:= format('%s %s', [formatdatetime(log_date_format, now), logstr])
  end else setlength(buf, 0);
  if assigned(logbuffer) then begin
    logbuffer.lock;
    try
      logbuffer.log(buf);
      logbuffer.log(crlf, 2);
    finally logbuffer.unlock; end;
  end;
  if assigned(WriteLogHandler) then WriteLogHandler(pAnsiChar(buf));
  result:= true;
end;

// ������� � log-���� ���������� �� ����������

procedure writeexceptionlog(buffer: pAnsiChar; BufferSize: Integer; CallStack, Registers, CustomInfo: pAnsiChar); stdcall;
var buf : ansistring;
begin
  buf:= format('%s: Exception dump informantion:'#$0d#$0a, [formatdatetime(log_date_format, now)]);
  if assigned(logbuffer) then with logbuffer do begin
    lock;
    try
      log(buf);
      log(crlf, 2);
      log(hline, strlen(hline));
      if assigned(Buffer)     then begin log(buffer, buffersize);             log(crlf, 2); end;
      log(crlf, 2);

      if assigned(CallStack)  then begin log(CallStack, strlen(CallStack));   log(crlf, 2); end;
      if assigned(Registers)  then begin log(Registers, strlen(Registers));   log(crlf, 2); end;
      if assigned(CustomInfo) then begin log(CustomInfo, strlen(CustomInfo)); log(crlf, 2); end;
      log(crlf, 2);

      flush;
    finally unlock; end;
  end;

  if assigned(WriteLogHandler) then begin
    WriteLogHandler(pAnsiChar(buf));
    WriteLogHandler(buffer);
  end;
end;

// ����� � ���

function  log(const logstr: ansistring): boolean; overload;
begin result:= writelog(pAnsiChar(logstr)); end;

function  log(const logstr: ansistring; const params: array of const): boolean; overload;
begin result:= writelog(pAnsiChar(format(logstr, params))); end;

procedure log_start;
begin
  if assigned(logbuffer) then begin
    logbuffer.lock;
    try logbuffer.start;
    finally logbuffer.unlock; end;
  end;
end;

procedure log_flush;
begin
  if assigned(logbuffer) then begin
    logbuffer.lock;
    try logbuffer.flush;
    finally logbuffer.unlock; end;
  end;
end;

procedure log_stop;
begin
  if assigned(logbuffer) then begin
    logbuffer.lock;
    try logbuffer.stop;
    finally logbuffer.unlock; end;
  end;
end;

exports
  legacy_logevent name 'srvLogEvent',
  writelog        name SRV_WriteLog,
  log_start       name SRV_StartLog,
  log_flush       name SRV_FlushLog,
  log_stop        name SRV_StopLog;

initialization
  deflogname:= format('%s%s', [ExeFilePath, ChangeFileExt(ExeFileName, '.log')]);
  logbuffer:= tLogBuffer.create;

finalization
  if assigned(logbuffer) then freeandnil(logbuffer);

end.
