unit lowlevel;

interface

function  minimize(const base, delta: currency): currency;
function  r2d(value: currency): currency;

function  checkbit(mask: pointer; bitnum: longint): boolean;

function  cmpi64(a, b: int64): longint;
function  cmpreal(const a, b: real): longint;
function  cmpdouble(const a, b: double): longint;

function  charcount(ch: char; const str: ansistring): longint;
procedure filterstring(var source: ansistring);
function  enchancestring(const source: ansistring): ansistring;

implementation

function minimize(const base, delta: currency): currency;
begin
  if (base <= 0)    then result:= delta        else
  if (base < delta) then result:= delta - base else result:= 0;
end;

function r2d(value: currency): currency;
var i : int64 absolute value;
    k : longint;
begin
  k:= i mod 100;
  if (k < 50) then i:= (i div 100) * 100 else i:= (i div 100 + 1) * 100;
  result:= value;
end;

function checkbit(mask: pointer; bitnum: longint): boolean;
type pbytearray = ^tbytearray;
     tbytearray = array[0..0] of byte;
var  tmp : longint;
begin
  tmp:= pbytearray(mask)^[bitnum shr 3];
  result:= ((tmp and (1 shl (bitnum and 7))) <> 0);
end;

function cmpi64(a, b: int64): longint;
begin
 a:= a - b;
 if a < 0 then result:= -1 else
 if a > 0 then result:= 1  else result:= 0;
end;

function cmpreal(const a, b: real): longint;
var r : real;
begin
  r:= a - b;
  if r < 0 then result:= -1 else
  if r > 0 then result:= 1  else result:= 0;
end;

function cmpdouble(const a, b: double): longint;
var r : real;
begin
  r:= a - b;
  if r < 0 then result:= -1 else
  if r > 0 then result:= 1  else result:= 0;
end;

function charcount(ch: char; const str: ansistring): longint;
var i : longint;
begin
  result:= 0;
  for i:= 1 to length(str) do
    if (str[i] = ch) then inc(result);
end;

procedure filterstring(var source: ansistring);
var i : longint;
begin
  for i:= 1 to length(source) do
    if source[i] < #32 then source[i]:= #32 else
    if source[i] = #39 then source[i]:= #34;
end;

function enchancestring(const source: ansistring): ansistring;
var i, j, newlen : longint;
    f            : boolean;
begin
  newlen:=0; f:=true;
  for i:=1 to length(source) do
    if (source[i] > #32) then begin f:=false; inc(newlen); end
                         else if not f then begin f:=true; inc(newlen); end;
  if f then dec(newlen);
  setlength(result,newlen);
  j:=1; i:=1; f:=true;
  while (j <= newlen) do begin
    case source[i] of
      #0..#32 : if not f then begin f:= true; result[j]:= #32; inc(j); end;
      #39     : begin f:= false; result[j]:= #34;       inc(j); end;
      else      begin f:= false; result[j]:= source[i]; inc(j); end;
    end;
    inc(i);
  end;
end;

end.
