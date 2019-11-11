unit rc5;

interface

uses  MyMIME, Crc32, math, RC5Const, RC5Impl;

const RC5Ok         = 0;
      RC5Error      = 1;
      RC5CRCError   = 2;

type  pKey          = RC5Const.pKey;
      tKey          = RC5Const.tKey;

function   rc5encryptbuf(buf: pAnsiChar; len: longint; key: pKey): longint;
function   rc5decryptbuf(buf: pAnsiChar; len: longint; key: pKey): longint; 

function   rc5encryptstaticbufcrc32(buf: pAnsiChar; len, buflen: longint; key: pKey): longint;
function   rc5decryptstaticbufcrc32(buf: pAnsiChar; len: longint; key: pKey): longint;

function   calculatelen(length: longint): longint;
procedure  generatekey(key: pKey);

function   MIMEKey(key: pKey): pAnsiChar;
procedure  UnMIMEKey(skey: pAnsiChar; key: pKey);

function   GenerateMIMEKey: pAnsiChar;

implementation

uses sysutils;

type pLongInt = ^LongInt;

function rc5encryptbuf(buf:pChar; len:longint; key: pKey):longint;
var i   : longint;
    tbl : tExpandedKey;
begin
  result:= RC5Ok;
  if assigned(buf) then try
    RC5Setup(key, tbl);
    for i:=0 to (len shr 3)-1 do
      pQWord(@buf[i shl 3])^:=RC5Encrypt(pQWord(@buf[i shl 3])^,tbl);
  except result:= RC5Error; end;
end;

function rc5decryptbuf(buf:pChar; len:longint; key:pKey):longint;
var i   : longint;
    tbl : tExpandedKey;
begin
  result:= RC5Ok;
  if assigned(buf) then try
    RC5Setup(key, tbl);
    for i:=0 to (len shr 3)-1 do
      pQWord(@buf[i shl 3])^:=RC5Decrypt(pQWord(@buf[i shl 3])^,tbl);
  except result:= RC5Error; end;
end;

function calculatelen(length: longint): longint;
begin
  if (length and 7 <> 0) then result:= ((length shr 3) + 1) shl 3
                         else result:= length;
end;

function rc5encryptstaticbufcrc32(buf: pAnsiChar; len, buflen: longint; key: pKey): longint;
begin
  result:= calculatelen(len + 4);
  if (result <= buflen) then begin
    plongint(@buf[result - sizeof(longint)])^:= BufCRC32(buf^, result - sizeof(longint));
    rc5encryptbuf(buf, result, key);
  end else result:= 0;
end;

function rc5decryptstaticbufcrc32(buf: pAnsiChar; len: longint; key: pKey): longint;
begin
  if len > 4 then begin
    result:= rc5decryptbuf(buf, len, key);
    if (result = RC5Ok) then
      if (plongint(@buf[len - 4])^ <> BufCRC32(buf^, len - 4)) then result:= RC5CRCError;
  end else result:= RC5Error;
end;

procedure generatekey(key: pKey);
var i   : longint;
begin
  if assigned(key) then
    for i:=0 to _b-1 do key[i]:= random(256);
end;

function MIMEKey(key: pKey): pAnsiChar;
begin
  if assigned(key) then result:= EncodeBuf(key, sizeof(tKey))
                   else result:= nil;     
end;

procedure UnMIMEKey(skey: pAnsiChar; key: pKey);
var pc  : pAnsiChar;
    len : longint;
begin
  if assigned(key) and assigned(skey) then begin
    fillchar(key^, sizeof(tKey), 0);
    len:= strlen(skey);
    pc:= DecodeBuf(skey, len);
    if assigned(pc) then begin
      move(pc^, key^, min(len, sizeof(tKey)));
      freemem(pc);
    end;
  end;
end;

function GenerateMIMEKey: pAnsiChar;
var key : tKey;
begin
  generatekey(@key);
  result:= MIMEKey(@key);
end;

initialization
  Randomize;

end.