unit MTETableDecoder;

interface

uses  windows, classes, sysutils,
      MTETypes, MTEStruct;

type  tMicexSnapshot  = class(tMemoryStream)
      private
        function    FGetEncodedData: ansistring;
        procedure   FSetEncodedData(const adata: ansistring);
        function    ConvertEndian(avalue: longint): longint;
      public
        function    SetSnapshotBuf(const buffer; len: longint): boolean;
        function    GetSnapshot: pointer;

        property    SnapshotData: pointer read GetSnapshot;
        property    EncodedData: ansistring read FGetEncodedData write FSetEncodedData;
      end;

type  TMicexTableDecoder = class(TMicexObject)
      private
        FIntf            : TMicexIface;
        FSnapshot        : tMicexSnapshot;
      protected
        function    GetReference: THandle; virtual;
        function    GetMicexMessage: TMicexMessage; virtual;

        function    MakeKeyFromData(afields: TMicexFields; acount: longint; afldnums, adata: pAnsiChar): ansistring;
        function    GetFieldFromData(afields: TMicexFields; acount, aindex: longint; afldnums, adata: pAnsiChar; var res: ansistring): boolean;

        procedure   BeforeProcessRowFields(atable: TMicexMessage; afields: TMicexFields; acount: longint; afldnums, adata: pAnsiChar); virtual;
        procedure   ProcessRowField(atable: TMicexMessage; afield: TMicexField; adata: pAnsiChar); virtual;
        procedure   AfterProcessRowFields(atable: TMicexMessage; afields: TMicexFields); virtual;

        procedure   ProcessRowFields(atable: TMicexMessage; afields: TMicexFields; acount: longint; afldnums, adata: pAnsiChar); virtual;

        procedure   BeforeProcessTableRows(atable: TMicexMessage); virtual;
        procedure   ProcessTableRow(atable: TMicexMessage; var data: PAnsiChar); virtual;
        procedure   AfterProcessTableRows(atable: TMicexMessage); virtual;

        procedure   ProcessTable(atable: TMicexMessage; var data: PAnsiChar; aSnapshot: tMicexSnapshot = nil); virtual;
      public
        constructor create(AIntf: TMicexIface); virtual;

        procedure   ProcessData(aData: PAnsiChar; aTableList: TList; aSnapshot: tMicexSnapshot = nil); virtual;

        property    MicexInterface: TMicexIface read FIntf write FIntf;
        property    MicexSnapshot: tMicexSnapshot read FSnapshot;
      end;

implementation

var   AllFields : array[AnsiChar] of AnsiChar;

type  pSnapshotHeader = ^tSnapshotHeader;
      tSnapshotHeader = packed record
        Magic         : array[0..7] of AnsiChar;
        len           : longint;
        tablecount    : longint;
      end;

const base64alph : pAnsiChar = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
      base64pad  : pAnsiChar = '=';

{ tMicexSnapshot }

{$ifndef CPU64}
function tMicexSnapshot.ConvertEndian(avalue: longint): longint; assembler;
asm
  bswap   edx
  mov     eax, edx
end;
{$else}
function tMicexSnapshot.ConvertEndian(avalue: longint): longint;
begin
  result:= (avalue shr 24) or
           ((avalue shr 8) and $FF00) or
           ((avalue shl 8) and $FF0000) or
           ((avalue shl 24) and $FF000000);
end;
{$endif}

function tMicexSnapshot.SetSnapshotBuf(const buffer; len: Integer): boolean;
begin
  Clear;
  Write(buffer, len);
  Seek(0, soFromBeginning);
  result:= true;
end;

function tMicexSnapshot.GetSnapshot: pointer;
begin result:= Memory; end;

function tMicexSnapshot.FGetEncodedData: ansistring;
var i, l          : longint;
    outsize, widx : longint;
    w             : word;
begin
  if (size > 0) then begin
    if (size mod 3 > 0) then outsize:= (size div 3 + 1) * 4 else outsize:= size div 3 * 4;
    setlength(result, outsize);
    widx:= 1; w:= 0; l:= 0;
    for i:= 0 to size - 1 do begin
      w:= w or ((w or byte(pAnsiChar(memory)[i])) shl (8 - l));
      inc(l, 8);
      while (l >= 6) do begin
        result[widx]:= base64alph[hi(word(w shr 2))];
        inc(widx);
        w:= w shl 6;
        dec(l, 6);
      end;
    end;
    if (l > 0) then begin result[widx]:= base64alph[hi(word(w shr 2))]; inc(widx); end;
    for i:= widx to outsize do result[i]:= base64pad[0];
  end else setlength(result, 0);
end;

procedure tMicexSnapshot.FSetEncodedData(const adata: ansistring);
var pt, cpos   : pAnsiChar;
    i, j, p, l : longint;
    w          : cardinal;
begin
  if length(adata) mod 4 = 0 then begin
    Clear;

    pt:= @adata[1];
    for i:= 0 to length(adata) div 4 - 1 do begin
      w:= 0; l:= 3;
      for j:= 0 to 3 do begin
        cpos:= strscan(base64alph, pt[j]);
        if assigned(cpos) then begin
          p:= longint(cpos - base64alph);
          w:= w or cardinal(p shl ((3 - j) * 6));
        end else dec(l);
      end;

      w:= convertendian(w) shr 8;

      write(w, l);
      inc(pt, 4);
    end;

    Seek(0, soFromBeginning);
  end else SetSize(0);
end;

{ TMicexTableDecoder }

constructor TMicexTableDecoder.create(AIntf: TMicexIface);
begin
  inherited create;
  FIntf:= AIntf;
end;

function TMicexTableDecoder.GetReference: THandle;
begin result:= THandle(Self); end;

function TMicexTableDecoder.GetMicexMessage: TMicexMessage;
begin result:= nil; end;

function TMicexTableDecoder.MakeKeyFromData(afields: TMicexFields; acount: longint; afldnums, adata: pAnsiChar): ansistring;
var i, offset : longint;
    keyfield  : ansistring;
begin
  setlength(result, 0);
  offset:= 0;
  for i:= 0 to acount - 1 do with afields[Byte(afldnums[i])] do begin
    if FKey then begin
      SetString(keyfield, adata + offset, FSize);
      result := result + keyfield;
    end;
    inc(offset, FSize);
  end;
end;

function TMicexTableDecoder.GetFieldFromData(afields: TMicexFields; acount, aindex: longint; afldnums, adata: pAnsiChar; var res: ansistring): boolean;
var i, offset : longint;
begin
  result:= false;
  setlength(res, 0);
  if (aindex >= 0) then begin
    offset:= 0;
    for i:= 0 to acount - 1 do with afields[Byte(afldnums[i])] do begin
      if (ord(afldnums[i]) = aindex) then begin
        SetString(res, adata + offset, FSize);
        result:= true;
        break;
      end;
      inc(offset, FSize);
    end;
  end;
end;


procedure TMicexTableDecoder.BeforeProcessRowFields(atable: TMicexMessage; afields: TMicexFields; acount: longint; afldnums, adata: pAnsiChar);
begin end;
procedure TMicexTableDecoder.ProcessRowField(atable: TMicexMessage; afield: TMicexField; adata: pAnsiChar);
begin end;
procedure TMicexTableDecoder.AfterProcessRowFields(atable: TMicexMessage; afields: TMicexFields);
begin end;

procedure TMicexTableDecoder.ProcessRowFields(atable: TMicexMessage; afields: TMicexFields; acount: longint; afldnums, adata: pAnsiChar);
var i   : longint;

    fld : TMicexField;
begin
  BeforeProcessRowFields(atable, afields, acount, afldnums, adata);

  for i:= 0 to acount - 1 do begin
    fld:= afields[byte(afldnums[i])];
    with fld do begin
      ProcessRowField(atable, fld, adata);
      inc(adata, FSize);
    end;
  end;

  AfterProcessRowFields(atable, afields);
end;

procedure TMicexTableDecoder.BeforeProcessTableRows(atable: TMicexMessage);
begin end;

procedure TMicexTableDecoder.ProcessTableRow(atable: TMicexMessage; var data: PAnsiChar);
var fldcount         : longint;
    rowheader        : TMTERow;
    fldnums, dataptr : pAnsiChar;
begin
  // get row header
  System.Move(data^, rowheader, SizeOf(rowheader));
  inc(data, sizeof(rowheader));

  fldcount:= rowheader.FldCount;
  dataptr:= data + fldcount;
  if (fldcount = 0) then begin
    fldcount:= atable.FOutFields.Count;
    fldnums:= allfields;
  end else fldnums:= data;

  ProcessRowFields(atable, atable.FOutFields, fldcount, fldnums, dataptr);

  inc(data, rowheader.FldCount + rowheader.RowLen);
end;

procedure TMicexTableDecoder.AfterProcessTableRows(atable: TMicexMessage);
begin end;

procedure TMicexTableDecoder.ProcessTable(atable: TMicexMessage; var data: PAnsiChar; aSnapshot: tMicexSnapshot);
var i, cnt : longint;
begin
  FSnapshot:= aSnapshot;

  cnt:= PMTETable(Data)^.RowCount;
  data:= @PMTETable(Data)^.TblData;

  BeforeProcessTableRows(atable);
  for i:= 0 to cnt - 1 do ProcessTableRow(atable, data);
  AfterProcessTableRows(atable);
end;

procedure TMicexTableDecoder.ProcessData(aData: PAnsiChar; aTableList: TList; aSnapshot: tMicexSnapshot);
var data   : PAnsiChar;
    i, cnt : longint;
    tbl    : TMicexTableDecoder;
    ref    : TMicexMessage;
begin
  if assigned(FIntf) and assigned(aData) then begin
    cnt:= PMTETables(aData)^.TblCount;
    data:= @PMTETables(aData)^.Tables;
    for i:= 0 to cnt - 1 do begin
      tbl:= TMicexTableDecoder(aTableList[PMTETable(Data)^.Ref]);
      if not assigned(tbl) then begin
        tbl:= Self;
        ref:= GetMicexMessage;
      end else ref:= tbl.GetMicexMessage;
      if assigned(tbl) and assigned(ref) then tbl.ProcessTable(ref, data, aSnapshot) else raise Exception.Create('Invalid table reference');
    end;
  end;
end;

{ initialization }

var i : AnsiChar;

initialization
  for i:= low(AllFields) to high(AllFields) do AllFields[i]:= i;

finalization

end.