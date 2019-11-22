{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit MTEUtils;

interface

uses  sysutils;

const openTableComplete = true;
      openTablePartial  = false;

function  TimeAsStr(Value: Integer): ansistring;
function  DateAsStr(Value: Integer): ansistring;

procedure DecodeMicexTime(Value: longint; var hour, minute, second: Word; var fraction: cardinal);
procedure DecodeMicexDate(Value: longint; var year: Smallint; var month, day: Word);

function  MicexTimeToDateTime(Value: longint): TDateTime;
function  MicexDateToDateTime(Value: longint): TDateTime;

function  EDivMod(Dividend, Divisor: longint; var Reminder: longint): longint;
procedure ESetLength(var S: ansistring; NewLength: Integer);

implementation

{$ifndef CPU64}
function EDivMod(Dividend, Divisor: longint; var Reminder: longint): longint; assembler;
asm
        PUSH    EBX
        MOV     EBX,EDX
        CDQ
        IDIV    EBX
        MOV     [ECX],EDX
        POP     EBX
end;

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
function EDivMod(Dividend, Divisor: longint; var Reminder: longint): longint;
begin
  Reminder:= Dividend mod Divisor;
  result:= Dividend div Divisor;
end;

procedure ESetLength(var S: ansistring; NewLength: longint);
begin SetLength(S, NewLength); end;
{$endif}

function TimeAsStr(Value: Integer): ansistring;
var H, M, S: Integer;
begin
  H := EDivMod(Value, 10000, M);
  M := EDivMod(M, 100, S);
  FmtStr(Result, '%d:%.2d:%.2d', [H, M, S]);
end;

function DateAsStr(Value: Integer): ansistring;
var Y, M, D: Integer;
begin
  Y := EDivMod(Value, 10000, M);
  M := EDivMod(M, 100, D);
  FmtStr(Result, '%.4d-%.2d-%.2d', [Y, M, D]);
end;

procedure DecodeMicexTime(Value: longint; var hour, minute, second: Word; var fraction: cardinal);
var H, M, S: Integer;
begin
  H := EDivMod(Value, 10000, M);
  M := EDivMod(M, 100, S);
  hour:= H; minute:= M; second:= S; fraction:= 0;
end;

procedure DecodeMicexDate(Value: longint; var year: Smallint; var month, day: Word);
var
  Y, M, D: Integer;
begin
  Y := EDivMod(Value, 10000, M);
  M := EDivMod(M, 100, D);
  year:= Y; month:= M; day:= D;
end;

function  MicexTimeToDateTime(Value: longint): TDateTime;
var hour, minute, second : word;
    fraction             : cardinal;
begin
  DecodeMicexTime(Value, hour, minute, second, fraction);
  result:= EncodeTime(hour, minute, second, 0);
end;

function  MicexDateToDateTime(Value: longint): TDateTime;
var year       : smallint;
    month, day : word;
begin
  DecodeMicexDate(Value, year, month, day);
  result:= EncodeDate(year, month, day);
end;

end.