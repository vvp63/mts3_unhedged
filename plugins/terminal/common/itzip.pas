{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit itzip;

interface

uses sysutils, classes;

function  StreamCompress(source: pointer; sourcelen: longint; abuf: tMemoryStream): longint;
function  StreamDecompress(source: pointer; sourcelen: integer; out dest: pointer; abuf: tMemoryStream): longint;

implementation

uses lzh;

type PMap = ^TMap;
     TMap = array [0..1] of longint;

function Compress (const Source: pointer; SSize: longint; const Target: PChar; out TSize: longint): boolean;
var PD: TPackData;
begin
  FillChar (PD, SizeOf (PD), 0);
  PD.InBuf:= Source; PD.OutBuf:= Target;
  PD.SSize:= SSize; PD.DSize:= SSize + SizeOf (longint) * 2;
  PD.OutPos:= SizeOf (longint) * 2;
  PackUnpack (true, PD);
  PMap (Target) [0]:= PD.WDSize;
  PMap (Target) [1]:= SSize;
  TSize:= PD.WDSize;
  result:= PD.Bytes_Written = SSize;
end;

function Decompress (const Source: pointer; SSize: longint; const Target: PChar): boolean;
var PD : TPackData;
    Map: PMap;
begin
  result:= false;
  FillChar (PD, SizeOf (PD), 0);
  PD.InBuf:= Source; PD.OutBuf:= Target;
  PD.SSize:= SSize; PD.InPos:= SizeOf (longint) * 2;
  Map:= Source;
  if Map^ [0] <= SSize then begin
    PD.TextSize:= Map^ [1];
    PD.DSize:= Map^ [1];
    PackUnpack (false, PD);
    result:= Map^ [1] = PD.WDSize;
  end;
end;

function  StreamCompress(source: pointer; sourcelen: longint; abuf: tMemoryStream): longint;
var destlen: longint;
begin
  result:= 0;
  if assigned(abuf) then begin
    if (sourcelen + sizeof (longint) * 2 > abuf.size) then abuf.size:= sourcelen * 2 + sizeof (longint) * 2;
    if compress(source, sourcelen, abuf.memory, destlen) and (destlen < sourcelen) then begin
      move(abuf.memory^, source^, destlen);
      result:= destlen;
    end;
  end;
end;

function  StreamDecompress(source: pointer; sourcelen: integer; out dest: pointer; abuf: tMemoryStream): longint;
begin
  result:= 0;
  dest:= nil;
  if assigned(abuf) then begin
    result:= PMap (source) [1];
    if (abuf.size < result) then abuf.size:= result * 2;
    if Decompress(source, sourcelen, abuf.memory) then dest:= abuf.Memory else result:= 0;
  end;
end;

end.
