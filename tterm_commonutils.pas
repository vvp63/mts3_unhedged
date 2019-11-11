{$I tterm_defs.pas}
{__$define with_guids}

{$ifndef MSWINDOWS}
  {$undef with_guids}
{$endif}

unit tterm_commonutils;

interface

uses  {$ifdef MSWINDOWS}
        windows,
        {$ifdef with_guids}activex, comobj, {$endif}
      {$else}
        unix, fclinifiles,
      {$endif}
      classes, sysutils, math;

{$ifdef MSWINDOWS}
type  pTimeVal     = ^tTimeVal;
      tTimeVal     = packed record
         tv_sec    : longint;
         tv_usec   : longint;
      end;
      timeval      = tTimeVal;

type  TPreciseTime = class(tObject)
      private
        fTime      : tDateTime;
        fStart     : int64;
        fFreq      : int64;
      public
        constructor Create;
        function    Now: TDateTime;
        function    Msecs: int64;
        function    MKsecs: int64;
      end;
{$endif}

{$ifndef MSWINDOWS}
function GetTickCount: cardinal;
{$endif}
function GetMksCount: int64;
function GetCPUClock: int64;

{$ifdef MSWINDOWS}
function DirectoryExists(const Name: ansistring): boolean;
function ForceDirectories(Dir: ansistring): boolean;

function  GetModuleName(Module: HMODULE): ansistring;
{$endif}

function  ANSIToOEM(const ANSIStr: ansistring): ansistring;
procedure ESetLength(var S: ansistring; NewLength: longint);
function  UnixTimeToDateTime(Value: Longword; InUTC: Boolean): TDateTime;
function  DateTimeToUnixTime(Value: TDateTime): longint;
procedure DecodeCommaText(const Value: ansistring; result: tStringList; adelimiter: AnsiChar);
procedure DecodePCharCommaText(Value: pAnsiChar; result: tStringList; adelimiter: AnsiChar);
procedure ReadIniSection(const aIniName, aSectionName: ansistring; sl: tStringList);
function  FilterString(const astr, pattern: ansistring): ansistring;
{$ifdef with_guids}
function  GenerateGUID (Default: ansistring): ansistring;
{$endif}

function  to_ansistring(apc: pAnsiChar): ansistring;

function  to_int64(abuf: pAnsiChar; amaxlen: longint; var e: boolean): int64;
function  to_int64def(abuf: pAnsiChar; amaxlen: longint; const defvalue: int64): int64;

function  int64_to_pchar_len(avalue: int64; abuf: pAnsiChar; amaxlen: longint): boolean;
function  int64_to_char_fixed_len(avalue: int64; abuf: pAnsiChar; alen: longint): pAnsiChar;

implementation

{$ifdef MSWINDOWS}
var   localtz       : TTimeZoneInformation;
{$endif}

const UnixStartDate : TDateTime = 25569.0;

{ TPreciseTime }

{$ifdef MSWINDOWS}
constructor TPreciseTime.Create;
begin
  inherited Create;
  QueryPerformanceFrequency(fFreq);
  FTime:= SysUtils.now;
  QueryPerformanceCounter(fStart);
end;

function TPreciseTime.Now: TDateTime;
var fEnd : int64;
begin
  QueryPerformanceCounter(fEnd);
  result:= fTime + (((fEnd - fStart) * 1000) div fFreq) / 86400000.0;
end;

function TPreciseTime.Msecs: int64;
var fEnd : int64;
begin
  QueryPerformanceCounter(fEnd);
  result:= (fEnd * 1000) div fFreq;
end;

function TPreciseTime.MKsecs: int64;
var fEnd : int64;
begin
  QueryPerformanceCounter(fEnd);
  result:= (fEnd * 1000) div (fFreq div 1000);
end;
{$endif}

{ misc. routines}

{$ifndef MSWINDOWS}
function GetTickCount: cardinal;
var t : timeval;
begin
  fpgettimeofday(@t, nil);
  result := ((int64(t.tv_sec) * 1000000) + t.tv_usec) div 1000;
end;
{$endif}

function GetMksCount: int64;
{$ifndef MSWINDOWS}
var t : timeval;
{$endif}
begin
{$ifdef MSWINDOWS}
  result := int64(GetTickCount) * 1000;
{$else}
  fpgettimeofday(@t, nil);
  result := (int64(t.tv_sec) * 1000000) + t.tv_usec;
{$endif}
end;

function GetCPUClock: int64;
{$ifndef MSWINDOWS}
var t : timeval;
{$endif}
begin
{$ifdef MSWINDOWS}
  QueryPerformanceCounter(result);
{$else}
  fpgettimeofday(@t, nil);
  result := (int64(t.tv_sec) * 1000000) + t.tv_usec;
{$endif}
end;

{$ifdef MSWINDOWS}
function DirectoryExists(const Name: ansistring): boolean;
var Code : Integer;
begin
  Code:= GetFileAttributes(pAnsiChar(Name));
  Result:= (Code <> -1) and (FILE_ATTRIBUTE_DIRECTORY and Code <> 0);
end;

function ForceDirectories(Dir: ansistring): boolean;
begin
  result:= true;
  if (Length(Dir) > 0) then begin
    dir:= ExcludeTrailingBackslash(Dir);
    if (Length(Dir) < 3) or DirectoryExists(Dir) or (ExtractFilePath(Dir) = Dir) then exit;
    result:= ForceDirectories(ExtractFilePath(Dir)) and CreateDir(Dir);
  end;
end;

function GetModuleName(Module: HMODULE): ansistring;
var ModName: array[0..MAX_PATH] of char;
begin SetString(Result, ModName, GetModuleFileName(Module, ModName, SizeOf(ModName))); end;
{$endif}

function ANSIToOEM(const ANSIStr: ansistring): ansistring;
var i : integer;
begin
  result:= ANSIStr;
  for i:= 1 to length(result) do
    case result[i] of
      #192..#239 : dec(result[i], 64);
      #240..#255 : dec(result[i], 16);
    end;
end;

{$ifndef CPU64}
procedure ESetLength(var S: ansistring; NewLength: longint);
begin
{ ->EAX   Pointer to S
    EDX   NewLength }
  asm
        MOV      ECX,[EAX]
        TEST     ECX,ECX
        JZ       @@Standard             // Если пустая строка, надо создать
        CMP      DWORD PTR [ECX-8],1    // RefCount
        JNE      @@Standard             // Если ссылок много, надо скопировать
        CMP      [ECX-4],EDX            // Length(S)
        JL       @@Standard             // New Size + 1 byte for trailing #0
        MOV      [ECX-4],EDX            // Set new length
        MOV      byte ptr [ECX+EDX],0   // Set trailing #0
        RET
    @@Standard:
  end;
  SetLength(S, NewLength);
end;
{$else}
procedure ESetLength(var S: ansistring; NewLength: longint);
begin SetLength(S, NewLength); end;
{$endif}

function UnixTimeToDateTime(Value: Longword; InUTC: Boolean): TDateTime;
var Days       : LongWord;
    Hour       : Word;
    Min        : Word;
    Sec        : Word;
    {$ifdef MSWINDOWS}
    localtime  : TSystemTime;
    systemtime : TSystemTime;
    {$endif}
begin
  Days  := Value div SecsPerDay;
  Value := Value mod SecsPerDay;
  Hour  := Value div 3600;
  Value := Value mod 3600;
  Min   := Value div 60;
  Sec   := Value mod 60;
  result:= 25569 + Days + EncodeTime(Hour, Min, Sec, 0);
  {$ifdef MSWINDOWS}
  if InUTC then begin
    DateTimeToSystemTime(result, systemtime);
    SystemTimeToTzSpecificLocalTime(@localtz, systemtime, localtime);
    result:= SystemTimeToDateTime(localtime);
  end;
  {$endif}
end;

function DateTimeToUnixTime(Value: TDateTime): longint;
begin Result := Round((Value - UnixStartDate) * 86400); end;

{$ifndef MSWINDOWS}
function CharNext(apc: pAnsiChar): pAnsiChar;
begin
  result:= apc;
  if assigned(result) and (result^ <> #0) then inc(result);
end;
{$endif}

procedure DecodeCommaText(const Value: ansistring; result: tStringList; adelimiter: AnsiChar);
begin DecodePCharCommaText(PAnsiChar(Value), result, adelimiter); end;

procedure DecodePCharCommaText(Value: pAnsiChar; result: tStringList; adelimiter: AnsiChar);
var P, P1 : PAnsiChar;
    S     : ansistring;
  function filter(const astr, pattern: ansistring): ansistring;
  var i, j : longint;
  begin
    setlength(result, length(astr));
    j:= 0;
    for i:= 1 to length(astr) do
      if (pos(astr[i], pattern) = 0) then begin
        inc(j); result[j]:= astr[i];
      end;
    setlength(result, j);
  end;
begin
  if assigned(result) then begin
    result.BeginUpdate;
    try
      result.Clear;
      P := Value;
      while P^ in [#1..#31] do P := CharNext(P);
      while P^ <> #0 do
      begin
        if P^ = '"' then
          S := AnsiExtractQuotedStr(P, '"')
        else
        begin
          P1 := P;
          while (P^ >= ' ') and (P^ <> adelimiter) do P := CharNext(P);
          SetString(S, P1, P - P1);
        end;
        result.Add(filter(S, '"'));
        while P^ in [#1..#31] do P := CharNext(P);
        if P^ = adelimiter then
          repeat
            P := CharNext(P);
          until not (P^ in [#1..#31]);
      end;
    finally
      result.EndUpdate;
    end;
  end;
end;

procedure ReadIniSection(const aIniName, aSectionName: ansistring; sl: tStringList);
const bufsize = $10000;
{$ifdef MSWINDOWS}
var   buf, tmp : pAnsiChar;
{$endif}
begin
  {$ifdef MSWINDOWS}
  buf:= allocmem(bufsize);
  try
    sl.BeginUpdate;
    try
      sl.Clear;
      GetPrivateProfileSection(PChar(aSectionName), buf, bufsize, PChar(aIniName));
      tmp:= buf;
       while tmp^ <> #0 do begin
        sl.Add(tmp);
        Inc(tmp, StrLen(tmp) + 1);
       end;
    finally sl.EndUpdate; end;
  finally freemem(buf); end;
  {$else}
  with tIniFile.Create(aIniName) do try
    ReadSectionValues(aSectionName, sl);
  finally free; end;
  // TIniFileSection
  {$endif}
end;

function FilterString(const astr, pattern: ansistring): ansistring;
var i, j : longint;
begin
  setlength(result, length(astr));
  j:= 0;
  for i:= 1 to length(astr) do
    if (pos(astr[i], pattern) = 0) then begin
      inc(j); result[j]:= astr[i];
    end;
  setlength(result, j);
end;

{$ifdef with_guids}
function GenerateGUID (Default: ansistring): ansistring;
var GUID : TGUID;
begin if (CoCreateGuid(GUID) = S_OK) then result:= GUIDToString (GUID) else result:= Default; end;
{$endif}

function to_ansistring(apc: pAnsiChar): ansistring;
begin
  if assigned(apc) then begin
    setlength(result, strlen(apc));
    if (length(result) > 0) then move(apc^, result[1], length(result));
  end else setlength(result, 0);
end;

function to_int64(abuf: pAnsiChar; amaxlen: longint; var e: boolean): int64;
var s : boolean;
    v : byte;
begin
  e:= false;
  result:= 0;
  s:= (abuf[0] = '-');
  if s then begin dec(amaxlen); inc(abuf); end;
  while (amaxlen > 0) do begin
    v:= pByte(abuf)^ - $30;
    if (v < 10) then begin result:= result * 10 + v; dec(amaxlen); end else begin e:= true; amaxlen:= 0; end;
    inc(abuf);
  end;
  if s then result:= -result;
end;

function to_int64def(abuf: pAnsiChar; amaxlen: longint; const defvalue: int64): int64;
var s, e : boolean;
    v    : byte;
begin
  e:= false;
  result:= 0;
  s:= (abuf[0] = '-');
  if s then begin dec(amaxlen); inc(abuf); end;
  while (amaxlen > 0) do begin
    v:= pByte(abuf)^ - $30;
    if (v < 10) then begin result:= result * 10 + v; dec(amaxlen); end else begin e:= true; amaxlen:= 0; end;
    inc(abuf);
  end;
  if not e then begin
    if s then result:= -result;
  end else result:= defvalue;
end;

function int64_to_pchar_len(avalue: int64; abuf: pAnsiChar; amaxlen: longint): boolean;
var   buf   : array[0..32] of ansichar;
      i, j  : longint;
      s     : boolean;
begin
  if (amaxlen > 0) then begin
    s:= (avalue < 0);
    if s then avalue:= -avalue;

    i:= 0;
    buf[i + 1]:= #0;
    inc(i);
    repeat
      buf[i + 1]:= ansichar(byte(avalue mod 10) + ord('0'));
      avalue:= avalue div 10;
      inc(i);
    until (avalue = 0);
    if s then begin
      buf[i + 1]:= '-';
      inc(i);
    end;

    for j:= 0 to min(i, amaxlen) - 1 do abuf[j]:= buf[i - j];

    abuf[amaxlen - 1]:= #0;

    result:= true;
  end else result:= false;
end;

function int64_to_char_fixed_len(avalue: int64; abuf: pAnsiChar; alen: longint): pAnsiChar;
var   buf    : array[0..32] of ansichar;
      tmpbuf : pAnsiChar;
      s      : boolean;
begin
  if (alen > 0) then begin
    s:= (avalue < 0);
    if s then begin
      avalue:= -avalue;
      dec(alen);
    end;

    tmpbuf:= @buf;
    if (alen > 0) then
      repeat
        tmpbuf^:= ansichar(byte(avalue mod 10) + ord('0'));
        avalue:= avalue div 10;
        inc(tmpbuf);
        dec(alen);
      until (alen <= 0);

    if s then begin
      tmpbuf^:= '-';
      inc(tmpbuf);
    end;

    while (tmpbuf > @buf) do begin
      dec(tmpbuf);
      abuf^:= tmpbuf^;
      inc(abuf);
    end;
  end;
  result:= abuf;
end;

initialization
  {$ifdef MSWINDOWS}
  GetTimeZoneInformation(localtz);
  {$endif}

end.

