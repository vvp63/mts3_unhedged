unit MD5;

interface

type
  PByte = ^byte;
  PMD5Code = ^TMD5Code;
  TMD5Code = record
    A: longword;
    B: longword;
    C: longword;
    D: longword;
  end;

procedure MD5EncryptBuff (Buff: PByte; Size: longint; var Encrypted: TMD5Code);
procedure MD5EncryptString (Source: ansistring; var Encrypted: TMD5Code);
procedure MD5LoginPassword (Login, Password: pAnsiChar; var Encrypted: TMD5Code);

implementation

uses sysutils;

procedure ChLongs (var a, b: longword);
var tmp : longword;
begin tmp:= a; a:= b; b:= tmp; end;

procedure PatchMD5 (Code: PMD5Code);
begin
  ChLongs (Code^.A, Code^.C);
  ChLongs (Code^.A, Code^.B);
  ChLongs (Code^.B, Code^.D);
end;

const
  EncBuf  : TMD5Code = (A: 0; B: 0; C: 0; D: 0);
  ConstEnc: TMD5Code = (A: $67452301; B: $efcdab89; C: $98badcfe; D: $10325476);
  FpA     : pointer = @EncBuf.A;
  FpB     : pointer = @EncBuf.B;
  FpC     : pointer = @EncBuf.C;
  FpD     : pointer = @EncBuf.D;

procedure MD5_Init;
begin
  Move (ConstEnc, EncBuf, SizeOf (TMD5Code));
end;

type
  PMD5Buf = ^TMD5Buf;
  TMD5Buf = array [0..15] of longint;
  PLong   = ^longword;

const
  S11 = 7;
  S12 = 12;
  S13 = 17;
  S14 = 22;
  S21 = 5;
  S22 = 9;
  S23 = 14;
  S24 = 20;
  S31 = 4;
  S32 = 11;
  S33 = 16;
  S34 = 23;
  S41 = 6;
  S42 = 10;
  S43 = 15;
  S44 = 21;

function ROL (a: longint; Amount: byte): longint;
var i : longint;
begin
  for i:= 1 to amount do
    if (a and (1 shl 31) <> 0) then begin
      a:= a shl 1;
      a:= a or 1;
    end else a:= a shl 1;
  result:= a;
end;

procedure FF (a, b, c, d, x: pointer; s: byte; ac: longword);
{Purpose:  Round 1 of the Transform.
           Equivalent to a = b + ((a + F(b,c,d) + x + ac) <<< s)
           Where F(b,c,d) = b And c Or Not(b) And d
}
var Fret: longword;
begin
  Fret:= ((PLong (b)^) and (PLong (c)^)) or ((not (PLong (b)^)) and (PLong (d)^));
  PLong (a)^:= PLong (a)^ + Fret + PLong (x)^ + ac;
  longword (a^):= ROL (longword (a^), s);
  inc (PLong (a)^, PLong (b)^);
end;

procedure GG (a, b, c, d, x: pointer; s: byte; ac: longword);
{Purpose:  Round 2 of the Transform.
           Equivalent to a = b + ((a + G(b,c,d) + x + ac) <<< s)
           Where G(b,c,d) = b And d Or c Not d
}
var Gret: longword;
begin
  Gret:= (PLong(b)^ and PLong (d)^) or (PLong (c)^ and (not PLong (d)^));
  PLong (a)^:= PLong (a)^ + Gret + PLong (x)^ + ac;
  longword (a^):= ROL (longword (a^), s);
  inc (PLong (a)^, PLong (b)^);
end;

procedure HH (a, b, c, d, x: pointer; s: byte; ac: longword);
{Purpose:  Round 3 of the Transform.
           Equivalent to a = b + ((a + H(b,c,d) + x + ac) <<< s)
           Where H(b,c,d) = b Xor c Xor d
}
var Hret: longword;
begin
  Hret:= PLong (b)^ xor PLong (c)^ xor PLong (d)^;
  PLong (a)^:= PLong (a)^ + Hret + PLong (x)^ + ac;
  longword (a^):= ROL (longword (a^), s);
  PLong (a)^:= PLong (b)^ + PLong (a)^;
end;

procedure II (a, b, c, d, x: pointer; s: byte; ac: longword);
{Purpose:  Round 4 of the Transform.
           Equivalent to a = b + ((a + I(b,c,d) + x + ac) <<< s)
           Where I(b,c,d) = C Xor (b Or Not(d))
}
var Iret: longword;
begin
  Iret:= (PLong (c)^ xor (PLong (b)^ or (not PLong (d)^)));
  PLong (a)^:= PLong (a)^ + Iret + PLong (x)^ + ac;
  longword (a^):= ROL (PLong (a)^, s);
  PLong (a)^:= PLong (b)^ + PLong (a)^;
end;

procedure MD5_Calc (MD5Buf: PMD5Buf);
var MBuf: TMD5Code;
begin
  MBuf:= EncBuf;

  { Round 1 }
  FF (FpA, FpB, FpC, FpD, @MD5Buf^ [ 0], S11, $d76aa478); { 1 }
  FF (FpD, FpA, FpB, FpC, @MD5Buf^ [ 1], S12, $e8c7b756); { 2 }
  FF (FpC, FpD, FpA, FpB, @MD5Buf^ [ 2], S13, $242070db); { 3 }
  FF (FpB, FpC, FpD, FpA, @MD5Buf^ [ 3], S14, $c1bdceee); { 4 }
  FF (FpA, FpB, FpC, FpD, @MD5Buf^ [ 4], S11, $f57c0faf); { 5 }
  FF (FpD, FpA, FpB, FpC, @MD5Buf^ [ 5], S12, $4787c62a); { 6 }
  FF (FpC, FpD, FpA, FpB, @MD5Buf^ [ 6], S13, $a8304613); { 7 }
  FF (FpB, FpC, FpD, FpA, @MD5Buf^ [ 7], S14, $fd469501); { 8 }
  FF (FpA, FpB, FpC, FpD, @MD5Buf^ [ 8], S11, $698098d8); { 9 }
  FF (FpD, FpA, FpB, FpC, @MD5Buf^ [ 9], S12, $8b44f7af); { 10 }
  FF (FpC, FpD, FpA, FpB, @MD5Buf^ [10], S13, $ffff5bb1); { 11 }
  FF (FpB, FpC, FpD, FpA, @MD5Buf^ [11], S14, $895cd7be); { 12 }
  FF (FpA, FpB, FpC, FpD, @MD5Buf^ [12], S11, $6b901122); { 13 }
  FF (FpD, FpA, FpB, FpC, @MD5Buf^ [13], S12, $fd987193); { 14 }
  FF (FpC, FpD, FpA, FpB, @MD5Buf^ [14], S13, $a679438e); { 15 }
  FF (FpB, FpC, FpD, FpA, @MD5Buf^ [15], S14, $49b40821); { 16 }

 { Round 2 }
  GG (FpA, FpB, FpC, FpD, @MD5Buf^ [ 1], S21, $f61e2562); { 17 }
  GG (FpD, FpA, FpB, FpC, @MD5Buf^ [ 6], S22, $c040b340); { 18 }
  GG (FpC, FpD, FpA, FpB, @MD5Buf^ [11], S23, $265e5a51); { 19 }
  GG (FpB, FpC, FpD, FpA, @MD5Buf^ [ 0], S24, $e9b6c7aa); { 20 }
  GG (FpA, FpB, FpC, FpD, @MD5Buf^ [ 5], S21, $d62f105d); { 21 }
  GG (FpD, FpA, FpB, FpC, @MD5Buf^ [10], S22,  $2441453); { 22 }
  GG (FpC, FpD, FpA, FpB, @MD5Buf^ [15], S23, $d8a1e681); { 23 }
  GG (FpB, FpC, FpD, FpA, @MD5Buf^ [ 4], S24, $e7d3fbc8); { 24 }
  GG (FpA, FpB, FpC, FpD, @MD5Buf^ [ 9], S21, $21e1cde6); { 25 }
  GG (FpD, FpA, FpB, FpC, @MD5Buf^ [14], S22, $c33707d6); { 26 }
  GG (FpC, FpD, FpA, FpB, @MD5Buf^ [ 3], S23, $f4d50d87); { 27 }
  GG (FpB, FpC, FpD, FpA, @MD5Buf^ [ 8], S24, $455a14ed); { 28 }
  GG (FpA, FpB, FpC, FpD, @MD5Buf^ [13], S21, $a9e3e905); { 29 }
  GG (FpD, FpA, FpB, FpC, @MD5Buf^ [ 2], S22, $fcefa3f8); { 30 }
  GG (FpC, FpD, FpA, FpB, @MD5Buf^ [ 7], S23, $676f02d9); { 31 }
  GG (FpB, FpC, FpD, FpA, @MD5Buf^ [12], S24, $8d2a4c8a); { 32 }

  { Round 3 }
  HH (FpA, FpB, FpC, FpD, @MD5Buf^ [ 5], S31, $fffa3942); { 33 }
  HH (FpD, FpA, FpB, FpC, @MD5Buf^ [ 8], S32, $8771f681); { 34 }
  HH (FpC, FpD, FpA, FpB, @MD5Buf^ [11], S33, $6d9d6122); { 35 }
  HH (FpB, FpC, FpD, FpA, @MD5Buf^ [14], S34, $fde5380c); { 36 }
  HH (FpA, FpB, FpC, FpD, @MD5Buf^ [ 1], S31, $a4beea44); { 37 }
  HH (FpD, FpA, FpB, FpC, @MD5Buf^ [ 4], S32, $4bdecfa9); { 38 }
  HH (FpC, FpD, FpA, FpB, @MD5Buf^ [ 7], S33, $f6bb4b60); { 39 }
  HH (FpB, FpC, FpD, FpA, @MD5Buf^ [10], S34, $bebfbc70); { 40 }
  HH (FpA, FpB, FpC, FpD, @MD5Buf^ [13], S31, $289b7ec6); { 41 }
  HH (FpD, FpA, FpB, FpC, @MD5Buf^ [ 0], S32, $eaa127fa); { 42 }
  HH (FpC, FpD, FpA, FpB, @MD5Buf^ [ 3], S33, $d4ef3085); { 43 }
  HH (FpB, FpC, FpD, FpA, @MD5Buf^ [ 6], S34,  $4881d05); { 44 }
  HH (FpA, FpB, FpC, FpD, @MD5Buf^ [ 9], S31, $d9d4d039); { 45 }
  HH (FpD, FpA, FpB, FpC, @MD5Buf^ [12], S32, $e6db99e5); { 46 }
  HH (FpC, FpD, FpA, FpB, @MD5Buf^ [15], S33, $1fa27cf8); { 47 }
  HH (FpB, FpC, FpD, FpA, @MD5Buf^ [ 2], S34, $c4ac5665); { 48 }

  { Round 4 }
  II (FpA, FpB, FpC, FpD, @MD5Buf^ [ 0], S41, $f4292244); { 49 }
  II (FpD, FpA, FpB, FpC, @MD5Buf^ [ 7], S42, $432aff97); { 50 }
  II (FpC, FpD, FpA, FpB, @MD5Buf^ [14], S43, $ab9423a7); { 51 }
  II (FpB, FpC, FpD, FpA, @MD5Buf^ [ 5], S44, $fc93a039); { 52 }
  II (FpA, FpB, FpC, FpD, @MD5Buf^ [12], S41, $655b59c3); { 53 }
  II (FpD, FpA, FpB, FpC, @MD5Buf^ [ 3], S42, $8f0ccc92); { 54 }
  II (FpC, FpD, FpA, FpB, @MD5Buf^ [10], S43, $ffeff47d); { 55 }
  II (FpB, FpC, FpD, FpA, @MD5Buf^ [ 1], S44, $85845dd1); { 56 }
  II (FpA, FpB, FpC, FpD, @MD5Buf^ [ 8], S41, $6fa87e4f); { 57 }
  II (FpD, FpA, FpB, FpC, @MD5Buf^ [15], S42, $fe2ce6e0); { 58 }
  II (FpC, FpD, FpA, FpB, @MD5Buf^ [ 6], S43, $a3014314); { 59 }
  II (FpB, FpC, FpD, FpA, @MD5Buf^ [13], S44, $4e0811a1); { 60 }
  II (FpA, FpB, FpC, FpD, @MD5Buf^ [ 4], S41, $f7537e82); { 61 }
  II (FpD, FpA, FpB, FpC, @MD5Buf^ [11], S42, $bd3af235); { 62 }
  II (FpC, FpD, FpA, FpB, @MD5Buf^ [ 2], S43, $2ad7d2bb); { 63 }
  II (FpB, FpC, FpD, FpA, @MD5Buf^ [ 9], S44, $eb86d391); { 64 }

  inc (EncBuf.A, MBuf.A);
  inc (EncBuf.B, MBuf.B);
  inc (EncBuf.C, MBuf.C);
  inc (EncBuf.D, MBuf.D);
end;

procedure MD5EncryptBuff (Buff: PByte; Size: longint; var Encrypted: TMD5Code);
var BitSize: int64;
    BufSize: longint;
    Need   : longint;
    Buffer : PAnsiChar;
begin
  MD5_Init;
  BitSize:= Size * 8;
  BufSize:= Size + 1;
  Need:= BufSize mod 64;
  if Need <= 56 then inc (BufSize, 64 - Need)
  else inc (BufSize, 120 - Need);
  GetMem (Buffer, BufSize);

  FillChar (Buffer^, BufSize, 0);
  Move (Buff^, Buffer^ , Size);
  Move (BitSize, (Buffer + BufSize - 8)^, 8);
  Buffer [Size]:= #$80;

  Need:= 0;
  repeat
    MD5_Calc (pointer(Buffer + Need));
    inc (Need, 64);
  until BufSize = Need;

  FreeMem (Buffer, BufSize);

  PatchMD5 (@EncBuf);
  Encrypted:= EncBuf;
end;

procedure MD5EncryptString (Source: ansistring; var Encrypted: TMD5Code);
begin
  MD5EncryptBuff (@Source [1], Length (Source), Encrypted);
end;

procedure MD5LoginPassword (Login, Password: pAnsiChar; var Encrypted: TMD5Code);
var s: ansistring;
    p: ansistring;
begin
  p:= Password;
  s:= lowercase(Login);
  MD5EncryptString (s + p, Encrypted);
end;

end.
