{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit MyMIME;

interface

{$ifndef FPC}
function EncodeBuf(buf: pointer; len: longint): pAnsiChar; pascal;
function DecodeBuf(buf: pAnsiChar; var len: longint): pointer; pascal;
{$else}
function EncodeBuf(buf: pointer; len: longint): pAnsiChar;
function DecodeBuf(buf: pAnsiChar; var len: longint): pointer;
{$endif}

implementation

uses  sysutils;

{$ifdef FPC}
function encoded_size(asize: longint): longint;
begin
  result:= asize div 3;
  if (asize mod 3 <> 0) then inc(result);
  result:= result * 4;
  inc(result); // trailing zero
end;

function EncodeBuf(buf: pointer; len: longint): pAnsiChar;
begin
  // todo: encoder
  result:= nil;
end;

function decoded_size(asize: longint): longint;
begin
  result:= asize div 4;
  if (asize mod 4 <> 0) then inc(result);
  result:= result * 3;
  inc(result); // trailing zero
end;

function DecodeBuf(buf: pAnsiChar; var len: longint): pointer;
var destlen         : longint;
    fin, dest, dfin : pAnsiChar;
    tmp, res        : longint;
begin
  destlen:= decoded_size(len);
  if (destlen > 0) then begin
    result:= allocmem(destlen);
    dest:= result;
    dfin:= dest + destlen - 4;
    fin:= buf + len - 4;
    while (buf <= fin) do begin
      tmp:= plongint(buf)^ - $30303030;
      inc(buf, 4);
      res:= ((tmp or (tmp shr 2) and $c0) and $ff)
            or ((tmp shr 2 and $0f00) or ((tmp shr 4) and $f000) and $ff00)
            or ((tmp shr 4 and $070000) or ((tmp shr 6) and $fc0000) and $ff0000)
            ;
      if (dest <= dfin) then begin
        plongint(dest)^:= res;
        inc(dest, 3);
      end else buf:= fin + 1;
    end;
    pAnsiChar(result)[destlen - 1]:= #0;
    len:= destlen;
  end else result:= nil;
end;
{$else}
function EncodeBuf(buf: pointer; len: longint): pAnsiChar; assembler;
const    mval : longint = 4;
         dval : longint = 3;
asm
         mov    eax,len
         and    eax,eax
         jz     @@enb02

         push   esi
         push   edi
         push   edx
         push   ecx
         push   eax

         xor    edx,edx
         div    dval
         and    edx,edx
         jz     @@enb01
         inc    eax
@@enb01: mul    mval
         inc    eax
         call   allocmem

         mov    edi,eax
         mov    esi,buf

         pop    ecx
         push   eax

         cld

@@enb04: xor    edx,edx

         lodsb
         mov    dl,al
         dec    ecx
         jecxz  @@enb03

         lodsb
         mov    dh,al
         dec    ecx
         jecxz  @@enb03

         xor    eax,eax
         lodsb
         shl    eax,16
         or     edx,eax
         dec    ecx
         jecxz  @@enb03

         call   @@enb05
         jmp    @@enb04

@@enb03: call   @@enb05
         xor    al,al
         stosb

         pop    eax
         pop    ecx
         pop    edx
         pop    edi
         pop    esi

         jmp    @@enb02

@@enb05: push   ecx

         mov    ecx,4
@@enb07: push   ecx

         mov    ecx,6
@@enb08: shr    edx,1
         rcr    eax,1
         loop   @@enb08
         shr    eax,2

         pop    ecx
         loop   @@enb07

         add    eax,30303030h
         stosd

         pop    ecx
         ret

@@enb02:
end;

function DecodeBuf(buf: pAnsiChar; var len: longint): pointer; assembler;
const    mval : longint = 3;
         dval : longint = 4;
asm      mov    eax,buf
         call   strlen
         and    eax,eax
         jz     @@deb01

         push   esi
         push   edi
         push   edx
         push   ecx
         push   eax

         xor    edx,edx
         div    dval
         and    edx,edx
         jz     @@deb02
         inc    eax
@@deb02: mul    mval
         inc    eax
         mov    edx,len
         mov    [edx],eax
         call   allocmem

         mov    edi,eax
         mov    esi,buf

         pop    ecx
         push   eax

         cld
         shr    ecx,2
         jecxz  @@deb06

@@deb03: lodsd
         mov    edx,eax
         sub    edx,30303030h
         push   ecx

         mov    ecx,4
@@deb05: push   ecx

         mov    ecx,6
@@deb04: shr    edx,1
         rcr    eax,1
         loop   @@deb04
         shr    edx,2

         pop    ecx
         loop   @@deb05

         shr    eax,8
         stosw
         shr    eax,16
         stosb

         pop    ecx
         loop   @@deb03

@@deb06: xor    eax,eax
         stosb

         pop    eax
         pop    ecx
         pop    edx
         pop    edi
         pop    esi

@@deb01:
end;
{$endif}

end.


