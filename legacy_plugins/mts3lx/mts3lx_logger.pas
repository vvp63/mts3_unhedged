unit mts3lx_logger;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$else}
        cmem,
        cthreads,
        baseunix,
      {$endif}
      dynlibs,
      classes, sysutils,
      tterm_api, tterm_common, tterm_utils;

{$ifndef MSWINDOWS}
const INVALID_HANDLE_VALUE= -1;
{$endif}

const   log_date_format                    = 'hh":"nn":"ss"."zzz';
        //log_date_format                    = 'yyyy-mm-dd hh":"nn":"ss"."zzz';


const FLogHandle        : tHandle         = INVALID_HANDLE_VALUE;
const crlf              : pAnsiChar  = #$0d#$0a;

const TMinPrev : string    = '59';
const TMinCurr : string    = '00';




procedure FileOpenTry(const afilename : string);
procedure FileCloseHandle;
procedure LogFileWrite(const astr : string);


procedure InitMTSLogger;
procedure DoneMTSLogger;


implementation

uses mts3lx_common;



procedure FileOpenTry(const afilename : string);
begin
  FLogHandle := fpOpen(pAnsiChar(afilename), O_RdWr or O_Creat);
  if (FLogHandle <> INVALID_HANDLE_VALUE) then FileSeek(FLogHandle, 0, 2);
end;

procedure FileCloseHandle;
begin
  if (FLogHandle <> INVALID_HANDLE_VALUE) then fpClose(FLogHandle);
  FLogHandle:= INVALID_HANDLE_VALUE;
end;


procedure LogFileWrite(const astr : string);
var vfullstr  : string;
    vsize     : longint;
begin
  TMinCurr  := formatdatetime('nn', now);
  If ( (TMinCurr = '00') and (TMinPrev = '59') ) then begin
    FileCloseHandle;
    gLogFileName  :=  ExeFilePath + format(gLogFileTempl, [FormatDateTime('h_m_s', Now)]);
  end;

  vfullstr  := format('%s %s', [formatdatetime(log_date_format, now), astr]);
  vsize :=  length(vfullstr);
  if (FLogHandle = INVALID_HANDLE_VALUE) then FileOpenTry(gLogFileName);
  if (FLogHandle <> INVALID_HANDLE_VALUE) then begin
    FpWrite(FLogHandle, PChar(vfullstr), vsize);
    FpWrite(FLogHandle, crlf, 2);
  end;
  TMinPrev  :=  TMinCurr;
end;


//  --------------------------------------  //


procedure InitMTSLogger;
begin
  log('Initializing logfile %s', [gLogFileName]);
  FileOpenTry(gLogFileName);
end;


procedure DoneMTSLogger;
begin
  FileCloseHandle;
end;


end.
