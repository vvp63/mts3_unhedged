{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit filedump;

interface

uses  {$ifdef MSWINDOWS} windows, {$endif}
      sysutils;

procedure advanceddumpbuf(const afilename, acomment: string; buf: pchar; size: longint); overload;
procedure advanceddumpbuf(const acomment: string); overload;

var   dumpbufsect    : tRTLCriticalSection; // avoid data loss caused by file lock when logging to the same
                                            // file from different threads

const defaultlogname : string = 'dump.log';

implementation

procedure advanceddumpbuf(const acomment: string);
begin
  advanceddumpbuf(defaultlogname, acomment, nil, 0);
end;

procedure advanceddumpbuf(const afilename, acomment: string; buf: pchar; size: longint);
const  datetimeoffs   = 1;
       bufferlength   = 81;
type   tDumpBuf       = string[bufferlength];
const  stdbuf   : tDumpBuf = '                        |           |           |            |                 '#$0d#$0a;
       crlf     : pchar = #$0d#$0a;
       hexoffs  : array[0..15] of longint = (14, 17, 20, 23, 26, 29, 32, 35, 38, 41, 44, 47, 50, 53, 56, 59);
       chroffs  : array[0..15] of longint = (64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79);
       hexdigit : array[0..15] of char    = ('0', '1', '2', '3', '4', '5', '6', '7',
                                             '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
       addroffs : array[0..7]  of longint = (8, 7, 6, 5, 4, 3, 2, 1);
const  counter  : longint = 0;
var    buffer   : tDumpBuf;
       st       : string;
       i        : longint;
       fh       : longint;
  procedure filloffset(aofs: longint);
  var i : longint;
  begin
    for i:= 0 to 7 do begin
      buffer[addroffs[i]]:= hexdigit[aofs and $f];
      aofs:= aofs shr 4;
    end;
  end;
begin
  if (length(afilename) > 0) then begin
    EnterCriticalSection(dumpbufsect);
    try
      if fileexists(afilename) then fh:= fileopen(afilename, fmOpenReadWrite or fmShareDenyWrite) else fh:= filecreate(afilename);
      if (fh >= 0) then try
        fileseek(fh, 0, 2);
        buffer:= stdbuf;

        st:= format ('%s [%d] %s'#$0d#$0a, [formatdatetime('yyyy/mm/dd hh:nn:ss.zzz', now), counter, acomment]);
        filewrite(fh, st[1], length(st));
        if assigned(buf) then begin
          i:= 0; filloffset(i);
          while (i < size) do begin
            buffer[hexoffs[i and $0f]]     := hexdigit[(byte(buf^) shr 4) and $0f];
            buffer[hexoffs[i and $0f] + 1] := hexdigit[byte(buf^) and $0f];
            if (char(buf^) >= #$20) then buffer[chroffs[i and $0f]]:= char(buf^) else buffer[chroffs[i and $0f]]:= #$b7;
            inc(i); inc(buf);
            if (i > 0) and (i and $0f = 0) then begin filewrite(fh, buffer[1], bufferlength); buffer:= stdbuf; filloffset(i); end;
          end;
          if (i > 0) and (i and $0f <> 0) then filewrite(fh, buffer[1], bufferlength);
        end;
        filewrite(fh, crlf^, 2);
      finally fileclose(fh); end;
      inc(counter);
    finally LeaveCriticalSection(dumpbufsect); end;
  end;
end;

{$ifdef MSWINDOWS}
function GetModuleName(Module: HMODULE): string;
var ModName: array[0..MAX_PATH] of char;
begin SetString(Result, ModName, GetModuleFileName(Module, ModName, SizeOf(ModName))); end;
{$endif}

initialization
  {$ifdef MSWINDOWS}
  defaultlogname:= expandfilename(changefileext(GetModuleName(hInstance), '.log'));
  InitializeCriticalSection(dumpbufsect);
  {$else}
  InitCriticalSection(dumpbufsect);
  {$endif}

finalization
  {$ifdef MSWINDOWS}
  DeleteCriticalSection(dumpbufsect);
  {$else}
  DoneCriticalSection(dumpbufsect);
  {$endif}

end.
