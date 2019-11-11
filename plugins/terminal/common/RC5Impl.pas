{$Q-}
unit RC5Impl;

interface

uses RC5Const;

procedure RC5Setup(K: pKey; var s: tExpandedKey);                // secret input key K[0...b-1]
function  RC5EnCrypt(var pt: QWord; var s: tExpandedKey): QWord;
function  RC5DeCrypt(var ct: QWord; var s: tExpandedKey): QWord; // 2 WORD input ct/output pt

implementation

const _P            = $b7e15163;             // magic constants
      _Q            = $9e3779b9;

function max(x, y: cardinal): cardinal;
begin if x > y then result:= x else result:= y; end;

function rotl(x, y: cardinal): cardinal;
var i : longint;
begin
  for i:= 1 to (y and (_w - 1)) do
    if (x and (1 shl 31) <> 0) then x:= (x shl 1) or 1
                               else x:= x shl 1;
  result:= x;
end;

function rotr(x, y: cardinal): cardinal;
var i : longint;
begin
  for i:= 1 to (y and (_w - 1)) do
    if (x and 1 <> 0) then x:= (x shr 1) or cardinal(1 shl 31)
                      else x:= x shr 1;
  result:= x;
end;

function RC5EnCrypt(var pt: QWord; var s: tExpandedKey): QWord;
var i, A, B: cardinal;
begin
  A:=pt[0]+S[0]; B:=pt[1]+S[1];
  for i:=1 to _r do
  begin
    A:=ROTL(A xor B,B)+S[2*i];
    B:=ROTL(B xor A,A)+S[2*i+1];
  end;
  Result[0]:=A; Result[1]:=B;
end;

function RC5DeCrypt(var ct: QWord; var s: tExpandedKey): QWord;
var i, A, B: cardinal;
begin
  B:=ct[1]; A:=ct[0];
  for i:=_r downto 1 do
  begin
    B:=ROTR(B-S[2*i+1],A) xor A;
    A:=ROTR(A-S[2*i],B) xor B;
  end;
  Result[1]:=B-S[1]; Result[0]:=A-S[0];
end;

procedure RC5Setup(K: pKey; var s: tExpandedKey);
var i, j, m, A, B : cardinal;
    L             : array[0.._c-1] of cardinal;
begin
   { Initialize L, then S, then mix key into S }
   L[_c-1]:=0; Move(K^,L,_b);
   S[0]:=_P; for i:=1 to _t-1 do S[i]:=S[i-1]+_Q;
   i:=0; j:=0; A:=0; B:=0;
   for m:=1 to 3*max(_t,_c) do
   begin
     A:=rotl(S[i]+A+B,3); S[i]:=A;
     B:=rotl(L[j]+A+B,A+B); L[j]:=B;
     i:=(i+1) mod _t; j:=(j+1) mod _c;
   end;
end;

end.

