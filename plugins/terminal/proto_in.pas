{$i terminal_defs.pas}

unit proto_in;

interface

uses {$ifdef MSWINDOWS}
       windows,
     {$endif}
     sysutils, math,
     crc32, 
     lowlevel, sortedlist,
     protodef;

const
//------------------------------------------------------------------------------------------------------------------------------------------
//---------------------- ParseStream results
  ps_OK              = 0;
  ps_ERR_CRC         = 1;
  ps_ERR_BUFLEN      = 2;
  ps_ERR_TABLEID     = 3;

//---------------------- InitCodes results
  ic_OK              = ps_OK;
  ic_ERR_CRC         = ps_ERR_CRC;
  ic_ERR_BUFLEN      = ps_ERR_BUFLEN;
  ic_ERR_TABLE_NAME  = ps_ERR_TABLEID;

//------------------------------------------------------------------------------------------------------------------------------------------
//---------------------- Lists with tables and/or fields

const
  MaxFieldsCountIfZero = 64;

type
  PFields = ^TFields;
  TFields = record
    Code : longint;
    Field: PChar;
  end;

  TFieldsArray = class (TSortedList)
    function  CheckItem (item: pointer): boolean; override;
    function  Compare (item1, item2: pointer): longint; override;
    procedure FreeItem (item: pointer); override;
  end;

//---------------------- Base class for decode incoming stream
type
  TDecoderClass = class of TDecoder;

//----- Events
  TNotifyStartParse  = procedure (Sender: TObject) of object;
  TNotifyEndParse    = procedure (Sender: TObject; var ErrorCode: longint) of object;

  TNotifyStartUpdate = procedure (Sender: TObject) of object;
  TNotifyEndUpdate   = procedure (Sender: TObject) of object;


  TDecoder = class (TObject)
  private
    BitMask      : PChar;
    BitMaskSize  : longint;

    FData        : pointer;

    FonEndParse  : TNotifyEndParse;
    FonStartParse: TNotifyStartParse;
  protected
    CountCodes : longint;
    Fields     : TFieldsArray;
    Position   : longint;

    FieldsCodes: array of longint;
    function    GetFieldCount: longint; virtual;
  public
    constructor Create (FieldsCount: longint = 0); virtual;
    destructor  Destroy; override;
    procedure   EndParse (var ParseErrorCode: longint); virtual;
    function    GetField (FieldNum: longint): PFields; virtual; abstract;
    function    InitCodes (Buffer: PChar; BufLen: longint): longint;
    procedure   InitComplete; virtual;
    function    ParseStream (Buffer: PChar; BufLen: longint): longint; virtual;
    function    RecUpdated: longint; virtual; abstract;
    procedure   StartParse; virtual;
    function    UpdateValue (Code: longint; Buffer: PChar): longint; virtual; abstract;

    property    Data        : pointer           read FData         write FData;
    property    onEndParse  : TNotifyEndParse   read FonEndParse   write FonEndParse;
    property    onStartParse: TNotifyStartParse read FonStartParse write FonStartParse;
  end;

  TMRecDecoder = class (TDecoder)
  private
    OldStockID: longint;
    OldLevel  : string;
    OldCode   : string;
    FirstRec  : boolean;

    FUpdateStarted: boolean;

    FonEndUpdate  : TNotifyEndUpdate;
    FonStartUpdate: TNotifyStartUpdate;
  protected
    function    CheckUpdate (StockID: longint; Level, Code: string): boolean;
  public
    procedure   EndParse (var ParseErrorCode: longint); override;
    procedure   EndUpdate; virtual;
    function    GetCode: string; virtual; abstract;
    function    GetLevel: string; virtual; abstract;
    function    GetStockID: longint; virtual; abstract;
    function    RecUpdated: longint; override;
    procedure   StartParse; override;
    procedure   StartUpdate; virtual;
    property    UpdateStarted: boolean            read FUpdateStarted;
    property    onEndUpdate  : TNotifyEndUpdate   read FonEndUpdate   write FonEndUpdate;
    property    onStartUpdate: TNotifyStartUpdate read FonStartUpdate write FonStartUpdate;
  end;

//------------------------------------------------------------------------------------------------------------------------------------------
//---------------------- Container of all table decoders
type
  PTable = ^TTable;
  TTable = record
    TableID: byte;
    Table  : PChar;
    Decoder: TDecoder;
  end;

type
  TTableArray = class (TSortedList)
    function  CheckItem (item: pointer): boolean; override;
    function  Compare (item1, item2: pointer): longint; override;
    procedure FreeItem (item: pointer); override;
  end;

  TTableList = class (TSortedList)
    function  CheckItem (item: pointer): boolean; override;
    function  Compare (item1, item2: pointer): longint; override;
    procedure FreeItem (item: pointer); override;
  end;

  TIncomingBufferDecoder = class (TObject)
    TableArray: TTableArray;
    TableList : TTableList;
    CritSect  : TRTLCriticalSection;
    constructor Create;
    destructor  Destroy; override;
    procedure   Init;
    function    InitCodes (Buffer: PChar; BufLen: longint): longint;
    function    ParseBuffer (Buffer: PChar; BufLen: longint): longint; virtual;
    procedure   RegisterDecoder (TableName: PChar; Decoder: TDecoder); virtual;
  end;

//------------------------------------------------------------------------------------------------------------------------------------------

procedure InitProto (BufDecoder: TIncomingBufferDecoder);

function RegisterDecoder (BufDecoder: TIncomingBufferDecoder; TableName: PChar; Decoder: TDecoder): boolean;

//------------------------------------------------------------------------------------------------------------------------------------------

function ConvertToDateTime (const Str: string): TDateTime;
function CheckCRC (Buffer: PChar; BufLen: longint): boolean;

function _StrToInt (const Str: string): longint;
function _StrToInt64 (const Str: string): int64;
function _StrToDateTime (const Str: string): TDateTime;
function _StrToFloat (const Str: string): real;
function _StrToCurr (const Str: string): currency;

implementation

//------------------------------------------------------------------------------------------------------------------------------------------

type
  PLongint = ^longint;

function ConvertToDateTime (const Str: string): TDateTime;
var w: array [0..5] of word;
begin
  w [0]:= StrToInt (Copy (Str, 1, 2));
  w [1]:= StrToInt (Copy (Str, 3, 2));
  w [2]:= StrToInt (Copy (Str, 5, 4));
  w [3]:= StrToInt (Copy (Str, 9, 2));
  w [4]:= StrToInt (Copy (Str, 11, 2));
  w [5]:= StrToInt (Copy (Str, 13, 2));
  result:= EncodeDate (w [2], w [1], w [0]) + EncodeTime (w [3], w [4], w [5], 0);
end;

function CheckCRC (Buffer: PChar; BufLen: longint): boolean;
var CRC: longint;
begin
  CRC:= PLongint (Buffer + sizeof (longint))^;
  PLongint (Buffer + sizeof (longint))^:= sgProtSign;
  result:= BufCRC32 (Buffer^, BufLen) = CRC;
end;

//------------------------------------------------------------------------------------------------------------------------------------------

function _StrToInt (const Str: string): longint;
begin if (length(Str) > 0) then result:= StrToIntDef (Str, 0) else result:= 0; end;

function _StrToInt64 (const Str: string): int64;
begin if (length(Str) > 0) then result:= StrToInt64Def (Str, 0) else result:= 0; end;

function _StrToDateTime (const Str: string): TDateTime;
begin if (length(Str) > 0) then result:= ConvertToDateTime (Str) else result:= 0;  end;

function _StrToFloat (const Str: string): real;
begin if (length(Str) > 0) then result:= StrToFloat (Str) else result:= 0; end;

function _StrToCurr (const Str: string): currency;
begin if (length(Str) > 0) then result:= StrToCurr (Str) else result:= 0; end;

//------------------------------------------------------------------------------------------------------------------------------------------

function TFieldsArray.CheckItem (item: pointer): boolean;
begin result:= true; end;

function TFieldsArray.Compare (item1, item2: pointer): longint;
begin result:= StrIComp (PFields (item1)^.Field, PFields (item2)^.Field); end;

procedure TFieldsArray.FreeItem (item: pointer);
begin end;

//------------------------------------------------------------------------------------------------------------------------------------------

constructor TDecoder.Create (FieldsCount: longint);
var i   : longint;
    Flds: longint;
begin
  inherited Create;
  Fields:= TFieldsArray.Create;
  Data:= nil;
  Flds:= max(FieldsCount, GetFieldCount);
  for i:= 0 to Flds - 1 do Fields.Add (GetField (i));
end;

destructor TDecoder.Destroy;
begin
  SetLength (FieldsCodes, 0);
  if Assigned (Fields) then Fields.Free;
  if Assigned (BitMask) then FreeMem (BitMask, BitMaskSize);
  inherited Destroy;
end;

procedure TDecoder.EndParse (var ParseErrorCode: longint);
begin
  if Assigned (FonEndParse) then FonEndParse (Self, ParseErrorCode);
end;

procedure TDecoder.InitComplete;
begin
  SetLength (FieldsCodes, CountCodes);
  BitMaskSize:= CountCodes div 8;
  if CountCodes mod 8 <> 0 then inc (BitMaskSize);
  BitMask:= AllocMem (BitMaskSize);
end;

function TDecoder.GetFieldCount: longint;
begin result:= 0; end;

function TDecoder.InitCodes (Buffer: PChar; BufLen: longint): longint;
var Position: longint;
    Field   : TFields;
    Index   : longint;
begin
  result:= ic_OK;
  Position:= 0;
  SetLength (FieldsCodes, max (MaxFieldsCountIfZero, Fields.Count * 2));
  CountCodes:= 0;
  while Position < BufLen do begin
    Field.Field:= PChar (Buffer + Position);

    if Fields.Search (@Field, Index) then FieldsCodes [CountCodes]:= PFields (Fields [Index])^.Code
                                     else FieldsCodes [CountCodes]:= 0;
    inc (CountCodes);
    inc (Position, StrLen (Field.Field) + SizeOf (char));
  end;
  InitComplete;
end;

function TDecoder.ParseStream (Buffer: PChar; BufLen: longint): longint;
var BitNum    : longint;
    WaitedSize: longint;
begin
  result:= ps_OK;
  Position:= 0;
  StartParse;
  if CountCodes > 0 then while (result = ps_OK) and (Position < BufLen) do begin
    Move ((Buffer + Position)^, (BitMask)^, BitMaskSize);
    inc (Position, BitMaskSize);
    BitNum:= 0;
    while (result = ps_OK) and (Position < BufLen) and (BitNum < CountCodes) do begin
      if CheckBit (BitMask, BitNum) then begin
        WaitedSize:= UpdateValue (FieldsCodes [BitNum], Buffer + Position) + SizeOf (char);
        if WaitedSize < SizeOf (char) then result:= ps_ERR_BUFLEN else inc (Position, WaitedSize);
      end;
      inc (BitNum);
    end;
    if result = ps_OK then result:= RecUpdated;
  end;
  EndParse (result);
end;

procedure TDecoder.StartParse;
begin
  if Assigned (FonStartParse) then FonStartParse (Self);
end;

//------------------------------------------------------------------------------------------------------------------------------------------

function TMRecDecoder.CheckUpdate (StockID: longint; Level, Code: string): boolean;
begin
  result:= (StockID <> OldStockID) or (Level <> OldLevel) or (Code <> OldCode);
  if result then begin
    OldStockID:= StockID;
    OldLevel:= Level;
    OldCode:= Code;
  end;
end;

procedure TMRecDecoder.EndParse (var ParseErrorCode: longint);
begin
  inherited EndParse (ParseErrorCode);
  if ParseErrorCode = ps_OK then EndUpdate;
end;

procedure TMRecDecoder.EndUpdate;
begin
  if Assigned (FonEndUpdate) then FonEndUpdate (Self);
end;

function TMRecDecoder.RecUpdated: longint;
begin
  FUpdateStarted:= false;
  if CheckUpdate (GetStockID, GetLevel, GetCode) then begin
    if not FirstRec then EndUpdate;
    StartUpdate;
  end;
  FirstRec:= false;
  result:= ps_OK;
end;

procedure TMRecDecoder.StartParse;
begin
  inherited StartParse;
  CheckUpdate (0, '', '');
  FirstRec:= true;
end;

procedure TMRecDecoder.StartUpdate;
begin
  FUpdateStarted:= true;
  if Assigned (FonStartUpdate) then FonStartUpdate (Self);
end;

//------------------------------------------------------------------------------------------------------------------------------------------

function TTableList.CheckItem (item: pointer): boolean;
begin
  result:= Assigned (PTable (item)^.Decoder);
end;

function TTableList.Compare (item1, item2: pointer): longint;
begin
  result:= PTable (item1)^.TableID - PTable (item2)^.TableID;
end;

procedure TTableList.FreeItem (item: pointer);
begin
end;

//------------------------------------------------------------------------------------------------------------------------------------------

function TTableArray.CheckItem (item: pointer): boolean;
begin
  result:= Assigned (PTable (item)^.Decoder);
end;

function TTableArray.Compare (item1, item2: pointer): longint;
begin
  result:= StrIComp (PTable (item1)^.Table, PTable (item2)^.Table);
end;

procedure TTableArray.FreeItem (item: pointer);
begin
  if assigned(item) then begin
    if Assigned (PTable (item)^.Decoder) then freeandnil(PTable (item)^.Decoder);
    dispose(PTable(item));
  end;
end;

//------------------------------------------------------------------------------------------------------------------------------------------

constructor TIncomingBufferDecoder.Create;
begin
  inherited Create;
  {$ifdef MSWINDOWS}
  InitializeCriticalSection(CritSect);
  {$else}
  InitCriticalSection(CritSect);
  {$endif}
  TableArray:= TTableArray.Create;
  TableList:= TTableList.Create;
  TableList.fDuplicates:= dupReplace;
end;

destructor TIncomingBufferDecoder.Destroy;
begin
  TableList.Free;
  TableArray.Free;
  {$ifdef MSWINDOWS}
  DeleteCriticalSection(CritSect);
  {$else}
  DoneCriticalSection(CritSect);
  {$endif}
  inherited Destroy;
end;

procedure TIncomingBufferDecoder.Init;
begin
  EnterCriticalSection (CritSect);
  TableList.FreeAll;
  LeaveCriticalSection (CritSect);
end;

function TIncomingBufferDecoder.InitCodes (Buffer: PChar; BufLen: longint): longint;
const c  = SizeOf (char);
      b  = SizeOf (byte);
var idx: longint;
    tbl: TTable;
    tl : PTable;
    len: longint;
begin
  tbl.Table:= (Buffer + b);
  if not TableArray.Search (@tbl, idx) then result:= ic_ERR_TABLE_NAME
  else begin
    tl:= PTable (TableArray [idx]);
    tl^.TableID:= byte (Buffer^);
    TableList.Add (tl);
    len:= Length (tbl.Table) + c + b;
    result:= tl^.Decoder.InitCodes (Buffer + len, BufLen - len);
  end;
end;

function TIncomingBufferDecoder.ParseBuffer (Buffer: PChar; BufLen: longint): longint;
const lb = SizeOf (longint) * 2 + SizeOf (byte);
      l  = SizeOf (longint) * 2;
var idx: longint;
    tbl: TTable;

begin
  EnterCriticalSection (CritSect);
  result:= ps_OK;
  try
//  try
    if (BufLen >= l) and (PLongint (Buffer)^ >= l) and (PLongint (Buffer)^ <= BufLen) then begin
      BufLen:= PLongint (Buffer)^;
      if CheckCRC (Buffer, BufLen) then begin
        if BufLen > l then
          if byte ((Buffer + l)^) = idTableDescr then result:= InitCodes (Buffer + lb, BufLen - lb)
          else begin
            tbl.TableID:= byte ((Buffer + l)^);
            if TableList.Search (@tbl, idx) then result:= PTable (TableList [idx])^.Decoder.ParseStream (Buffer + lb, BufLen - lb)
            else result:= ps_ERR_TABLEID;
          end;
      end else result:= ic_ERR_CRC;
    end else result:= ps_ERR_BUFLEN;
//  except
//    on e: exception do begin
//                         MessageBox (0, PChar (Format ('Exception: %s'#13'Buffer/Size: %p/%d', [e.Message, pointer (Buffer), BufLen])), 'IBD.ParseBuffer', 0);
//                         result:= ic_ERR_CRC
//                       end;
//  end;
  finally LeaveCriticalSection (CritSect); end;
end;

procedure TIncomingBufferDecoder.RegisterDecoder (TableName: PChar; Decoder: TDecoder);
var rec: PTable;
begin
  rec:= New (PTable);
  rec^.Table:= TableName;
  rec^.Decoder:= Decoder;
  TableArray.Add (rec);
end;

//------------------------------------------------------------------------------------------------------------------------------------------

procedure InitProto (BufDecoder: TIncomingBufferDecoder);
begin
  if Assigned (BufDecoder) then BufDecoder.Init;
end;

function RegisterDecoder (BufDecoder: TIncomingBufferDecoder; TableName: PChar; Decoder: TDecoder): boolean;
begin
  if Assigned (BufDecoder) then begin
    result:= true;
    BufDecoder.RegisterDecoder (TableName, Decoder);
  end else result:= false;
end;

end.
