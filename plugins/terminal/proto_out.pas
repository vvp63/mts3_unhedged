{$i terminal_defs.pas}

unit proto_out;

interface

uses  classes, sysutils, math, 
      protodef,
      lowlevel, crc32, itzip, rc5;

const compression_enabled = true;

type  tEncoderStream      = class(tMemoryStream)
      private
        fencoding         : boolean;
        fbuffer           : tMemoryStream;
      protected
        frame             : tProtocolRec;
        frameposition     : longint;
        startposition     : longint;

        property    internal_buffer: tMemoryStream read fbuffer;
      public
        fmincompsize      : longint;
        enablecompression : boolean;
        constructor create(amincompsize: longint; abuf: tMemoryStream);
        procedure   startencode(internalid: byte); virtual;
        procedure   stopencode(key: pKey); virtual;
        procedure   generatedescriptor; virtual; abstract;
        procedure   encoderow(item: pAnsiChar; datasize: longint); virtual; abstract;
        procedure   writevalue(const value: array of const);

        property    encoding: boolean read fencoding write fencoding;
      end;

const stddtformat         = 'ddmmyyyyhhnnss';

implementation

constructor tEncoderStream.create(amincompsize: longint; abuf: tMemoryStream);
begin
  inherited create;
  fbuffer:= abuf;
  with frame do begin signature:= sgProtSign; tableid:= 0; flags:= pfNoFlags; rowcount:= 0; end;
  fmincompsize:= max(amincompsize, 0);
  enablecompression:= compression_enabled;
  fencoding:= false;
end;

procedure tEncoderStream.StartEncode(internalid: byte);
const crc   : longint = sgProtSign;
      len   : longint = 0;
begin
  fencoding:= true;

  frame.tableid:= internalid;
  frame.flags:= pfNoFlags;
  frame.rowcount:= 0;
  frameposition:= Position;
  write(frame, sizeof(frame));

  startposition:= Position;
  write(len, sizeof(longint));
  write(crc, sizeof(longint));
  write(internalid, sizeof(byte));
end;

procedure tEncoderStream.StopEncode(key: pKey);
var crc, destlen, tmp : longint;
begin
  destlen:= max(0, position - startposition);
  seek(startposition, soFromBeginning);
  write(destlen, (sizeof(longint)));
  crc:= BufCRC32((pAnsiChar(memory) + startposition)^, destlen);
  write(crc, sizeof(longint));
  if assigned(fbuffer) and enablecompression and (destlen >= fmincompsize) then begin
    tmp:= StreamCompress(pAnsiChar(memory) + startposition, destlen, fbuffer);
    if (tmp > 0) then begin
      destlen:= tmp;
      setsize(startposition + destlen);
      frame.flags:= frame.flags or pfPacked;
    end;
  end;
  if assigned(key) then begin
    destlen:= calculatelen(destlen);
    setsize(startposition + destlen);
    rc5encryptbuf(pAnsiChar(memory) + startposition, destlen, key);
    frame.flags:= frame.flags or pfEncrypted;
  end;
  frame.datasize:= destlen;
  updateprotocolcrc(frame);
  pProtocolRec(pAnsiChar(memory) + frameposition)^:= frame;
  seek(0, soFromEnd);
  
  fencoding:= false;
end;

procedure tEncoderStream.writevalue(const value: array of const);
var   i       : longint;
const nullval : byte  = 0;
      trueval : byte  = 1;
  procedure writepc(pc: pAnsiChar);
  begin if assigned(pc) then write(pc^, strlen(pc)); end;
  procedure writestr(const st: ansistring);
  begin if (length(st) > 0) then write(st[1], length(st)); end;
begin
  if (length(value) > 0) then
    for i:= low(value) to high(value) do with value[i] do try
      case vType of
        {boolean}
        vtBoolean    : if vBoolean          then write(trueval, sizeof(byte));
        {numeric}
        vtInteger    : if (vInteger <> 0)   then writestr(inttostr(vInteger));
        vtExtended   : if (vExtended^ <> 0) then writestr(floattostr(vExtended^));
        vtCurrency   : if (vCurrency^ <> 0) then writestr(floattostr(vCurrency^));
        vtInt64      : if (vInt64^ <> 0)    then writestr(inttostr(vInt64^));
        {ansistring}
        vtChar       : if (vChar <> #0)     then write(vChar, sizeof(char));
        vtString     :                           writestr(ansistring(vString^));
        vtpChar      :                           writepc(vpChar);
        vtAnsiString :                           writestr(ansistring(vAnsiString));
        {variant}
        vtVariant    :                           writestr(ansistring(vVariant^));
      end;
    finally write(nullval, sizeof(byte)); end;
end;

end.
