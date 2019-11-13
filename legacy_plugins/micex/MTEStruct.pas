unit MTEStruct;

interface

uses
  Classes, MTETypes;

type
  TMicexObject = class
  public
    FOwner: TMicexObject;
    FName: string;
    FCaption: string;
    FDescription: string;
    procedure LoadFromBuf(var Data: PChar; v2: boolean); virtual;
    function DisplayName: string;
  end;

  TMicexList = class(TMicexObject)
  public
    FList: TList;
    constructor Create;
    destructor Destroy; override;
    function Count: Integer;
    function Find(const Name: string; var Index: Integer): Boolean;
  end;

  TMicexEnumType = class(TMicexObject)
  private
    FConsts: TStringList;
  public
    FSize: Integer;
    FKind: TTEEnumKind;
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromBuf(var Data: PChar; v2: boolean); override;
    function GetShortName(const Index: Integer; const Value: string = ''): string; overload;
    function GetShortName(const Value: string): string; overload;
    function GetLongName(const Index: Integer; const Value: string = ''): string; overload;
    function GetLongName(const Value: string): string; overload;
    function GetConstIndex(const Value: string): Integer;
    function GetConstCount: Integer;
    function GetConst(const Index: Integer): string;
    function GetAsText: string;
    function GetConstAndName(const Index: Integer): string;
  end;

  TMicexEnumTypes = class(TMicexList)
  private
    function GetEnumType(AIndex: Integer): TMicexEnumType;
    function FindType(const AName: string): TMicexEnumType;
  public
    procedure Add(AType: TMicexEnumType);
    procedure LoadFromBuf(var Data: PChar; v2: boolean); override;
    property Types[AIndex: Integer]: TMicexEnumType read GetEnumType; default;
  end;

  TFieldNameType = (fntNone, fntSecBoard, fntSecCode, fntUserId, fntFirmId, fntFirmUserId);

  TMicexField = class(TMicexObject)
  public
    FSize: Integer;
    FStart: Integer;
    FType: TTEFieldType;
    FIsInput: Boolean;
    FKey: Boolean;
    FSecCode: Boolean;
    FEnumType: string;
    FDefValue: string;
    FEnumPtr: TMicexEnumType;
    FNameType: TFieldNameType;
    FFlags: Integer;
    FDecimals: Integer;
    constructor Create(AIsInput: Boolean; AOwner: TMicexObject);
    procedure LoadFromBuf(var Data: PChar; v2: boolean); override;
  end;

  TMicexFields = class(TMicexList)
  private
    function GetField(AIndex: Integer): TMicexField;
  public
    FIsInput: Boolean;
    FSumSize: Integer;
    FKeyIdx: Integer;
    FKeyStart: Integer;
    FKeySize: Integer;
    constructor Create(AIsInput: Boolean; AOwner: TMicexObject);
    procedure Add(AField: TMicexField);
    procedure LoadFromBuf(var Data: PChar; v2: boolean); override;
    property Fields[AIndex: Integer]: TMicexField read GetField; default;
  end;

  TMicexMessage = class(TMicexObject)
  public
    FInFields: TMicexFields;
    FOutFields: TMicexFields;
    FIsTable: Boolean;
    FUpdateable: Boolean;
    FClearOnUpdate: Boolean;
    FIsOrderbook: Boolean;
    FSystemIndex: Integer;
    constructor Create(AIsTable: Boolean; AOwner: TMicexObject);
    destructor Destroy; override;
    procedure LoadFromBuf(var Data: PChar; v2: boolean); override;
  end;

  TMicexMessages = class(TMicexList)
  private
    function GetMessage(AIndex: Integer): TMicexMessage;
  public
    FIsTable: Boolean;
    constructor Create(AIsTable: Boolean; AOwner: TMicexObject);
    procedure Add(AMessage: TMicexMessage);
    procedure LoadFromBuf(var Data: PChar; v2: boolean); override;
    property Messages[AIndex: Integer]: TMicexMessage read GetMessage; default;
  end;

  TMicexIface = class(TMicexObject)
  public
    FTypes: TMicexEnumTypes;
    FTables: TMicexMessages;
    FTransactions: TMicexMessages;
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromBuf(var Data: PChar; v2: boolean); override;
  end;

implementation

uses
  SysUtils;

resourcestring
  SNoEnum = 'Перечислимый тип %s не определен';

{var
  CurEnumTypes: TMicexEnumTypes;}

function ReadInt(var Data: PChar): Integer;
type
  PInteger = ^Integer;
begin
  Result := PInteger(Data)^;
  Inc(Data, 4);
end;

function ReadStr(var Data: PChar): string;
var
  Len: Integer;
begin
  Len := ReadInt(Data);
  SetString(Result, Data, Len);
  Inc(Data, Len);
end;

{ TMicexFields }

procedure TMicexFields.Add(AField: TMicexField);
begin
  FList.Add(AField);
end;

constructor TMicexFields.Create(AIsInput: Boolean; AOwner: TMicexObject);
begin
  inherited Create;
  FOwner := AOwner;
  FIsInput := AIsInput;
end;

function TMicexFields.GetField(AIndex: Integer): TMicexField;
begin
  Result := FList.Items[AIndex];
end;

procedure TMicexFields.LoadFromBuf(var Data: PChar; v2: boolean);
var
  Count, SumSize, Idx: Integer;
  Fld: TMicexField;
begin
  Count := ReadInt(Data);
  SumSize := 0;
  Idx := 0;
  FKeyIdx := -1;
  FKeySize := 0;
  while Count > 0 do
  begin
    Fld := TMicexField.Create(FIsInput, Self);
    Fld.LoadFromBuf(Data, v2);
    Add(Fld);
    Fld.FStart := SumSize;
    if Fld.FKey then
    begin
      FKeyIdx := Idx;
      FKeyStart := SumSize;
      Inc(FKeySize, Fld.FSize);
    end;
    Inc(SumSize, Fld.FSize);
    Dec(Count);
    Inc(Idx);
  end;
  FSumSize := SumSize;
end;

{ TMicexMessage }

constructor TMicexMessage.Create(AIsTable: Boolean; AOwner: TMicexObject);
begin
  inherited Create;
  FOwner := AOwner;
  FIsTable := AIsTable;
  FInFields := TMicexFields.Create(True, Self);
  FOutFields := TMicexFields.Create(False, Self);
end;

destructor TMicexMessage.Destroy;
begin
  FInFields.Free;
  FOutFields.Free;
  inherited;
end;

procedure TMicexMessage.LoadFromBuf(var Data: PChar; v2: boolean);
var
  Flags: Integer;
begin
  FName := ReadStr(Data);
  FCaption := ReadStr(Data);
  if v2 then begin
    FDescription:= ReadStr(Data);
    FSystemIndex:= ReadInt(Data);
  end;
  if FIsTable then begin
    Flags := ReadInt(Data);
    FUpdateable := Flags and tfUpdateable <> 0;
    FClearOnUpdate := Flags and tfClearOnUpdate <> 0;
    FIsOrderbook := Flags and tfOrderBook <> 0;
  end;
  FInFields.LoadFromBuf(Data, v2);
  if FIsTable then FOutFields.LoadFromBuf(Data, v2);
end;

{ TMicexList }

function TMicexList.Count: Integer;
begin
  Result := FList.Count;
end;

constructor TMicexList.Create;
begin
  inherited;
  FList := TList.Create;
end;

destructor TMicexList.Destroy;
var i : longint;
begin
  for i:= 0 to FList.count - 1 do tObject(FList.Items[i]).free; 
  FList.Free;
  inherited;
end;

function TMicexList.Find(const Name: string; var Index: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Count - 1 do
    if AnsiCompareText(TMicexObject(FList[I]).FName, Name) = 0 then
    begin
      Result := True;
      Index := I;
      Break;
    end;
end;

{ TMicexMessages }

procedure TMicexMessages.Add(AMessage: TMicexMessage);
begin
  FList.Add(AMessage);
end;

constructor TMicexMessages.Create(AIsTable: Boolean; AOwner: TMicexObject);
begin
  inherited Create;
  FOwner := AOwner;
  FIsTable := AIsTable;
end;

function TMicexMessages.GetMessage(AIndex: Integer): TMicexMessage;
begin
  Result := FList.Items[AIndex];
end;

procedure TMicexMessages.LoadFromBuf(var Data: PChar; v2: boolean);
var
  Count: Integer;
  Msg: TMicexMessage;
begin
  Count := ReadInt(Data);
  while Count > 0 do
  begin
    Msg := TMicexMessage.Create(FIsTable, Self);
    Msg.LoadFromBuf(Data, v2);
    Add(Msg);
    Dec(Count);
  end;
end;

{ TMicexIface }

constructor TMicexIface.Create;
begin
  inherited;
  FTypes := TMicexEnumTypes.Create;
  FTypes.FOwner := Self;
  FTables := TMicexMessages.Create(True, Self);
  FTransactions := TMicexMessages.Create(False, Self);
end;

destructor TMicexIface.Destroy;
begin
  FTables.Free;
  FTransactions.Free;
  FTypes.Free;
  inherited;
end;

procedure TMicexIface.LoadFromBuf(var Data: PChar; v2: boolean);
var Buf : PChar;
begin
  Buf:= Data;
  FName := ReadStr(Buf);
  FCaption := ReadStr(Buf);
  if v2 then FDescription:= ReadStr(Buf);
  FTypes.LoadFromBuf(Buf, v2);
//  CurEnumTypes := FTypes;
  FTables.LoadFromBuf(Buf, v2);
  FTransactions.LoadFromBuf(Buf, v2);
//  CurEnumTypes := nil;
end;

{ TMicexObject }

function TMicexObject.DisplayName: string;
begin
  if FCaption <> '' then Result := FCaption else
    if FName <> '' then Result := FName else
      Result := ClassName;
end;

procedure TMicexObject.LoadFromBuf(var Data: PChar; v2: boolean);
begin end;

{ TMicexField }

constructor TMicexField.Create(AIsInput: Boolean; AOwner: TMicexObject);
begin
  inherited Create;
  FOwner := AOwner;
  FIsInput := AIsInput;
end;

function TableHasFlagField(Table: TMicexMessage): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 0 to Table.FOutFields.Count - 1 do
    if Pos('FLAG', Table.FOutFields[I].FName) > 0 then Exit;
  Result := False;
end;

procedure TMicexField.LoadFromBuf(var Data: PChar; v2: boolean);
var
  CurEnumTypes: TMicexEnumTypes;
begin
  FName := ReadStr(Data);
  FCaption := ReadStr(Data);
  if v2 then FDescription := ReadStr(Data);
  FSize := ReadInt(Data);
  FType := TTEFieldType(ReadInt(Data));
  if v2 then FDecimals := ReadInt(Data);
  FFlags := ReadInt(Data);
  FKey := FFlags and ffKey <> 0;
  FSecCode := FFlags and ffSecCode <> 0;
  FEnumType := ReadStr(Data);
  case FType of
    ftFixed:
      begin
        if FFlags and ffFixedMask = ffFixed1 then FDecimals := 1 else
        if FFlags and ffFixedMask = ffFixed3 then FDecimals := 3 else
        if FFlags and ffFixedMask = ffFixed4 then FDecimals := 4
        else FDecimals := 2;
      end;
    ftFloat: FDecimals := -1;
  end;

  if FEnumType <> '' then
  begin
    CurEnumTypes := TMicexIface(FOwner.FOwner.FOwner.FOwner).FTypes;
    FEnumPtr := CurEnumTypes.FindType(FEnumType);
  end;
  if FIsInput then FDefValue := ReadStr(Data);

  if FSecCode and not SameText(FOwner.FOwner.FName, 'SECS')
    and not SameText(FOwner.FOwner.FName, 'SECURITIES') then FNameType := fntSecCode
  else
    if SameText(FName, 'SECBOARD') then FNameType := fntSecBoard
    else
      if ((Pos('USERID', UpperCase(FName)) > 0) or (Pos('FROMUSER', UpperCase(FName)) > 0))
        and not SameText(FOwner.FOwner.FName, 'USERS') then FNameType := fntUserId
      else
        if (Pos('FIRMID', UpperCase(FName)) > 0)
          and not SameText(FOwner.FOwner.FName, 'FIRMS') then
            FNameType := fntFirmId
        else
          if SameText(FName, 'ID') and TableHasFlagField(FOwner.FOwner as TMicexMessage) then FNameType := fntFirmUserId;
end;

{ TMicexEnumTypes }

procedure TMicexEnumTypes.Add(AType: TMicexEnumType);
begin
  FList.Add(AType);
end;

function TMicexEnumTypes.FindType(const AName: string): TMicexEnumType;
var
  I: Integer;
begin
  for I := 0 to FList.Count - 1 do
    if Types[I].FName = AName then
    begin
      Result := Types[I];
      Exit;
    end;
  raise Exception.CreateFmt(SNoEnum, [AName]);
end;

function TMicexEnumTypes.GetEnumType(AIndex: Integer): TMicexEnumType;
begin
  Result := FList.Items[AIndex];
end;

procedure TMicexEnumTypes.LoadFromBuf(var Data: PChar; v2: boolean);
var
  Count: Integer;
  Enm: TMicexEnumType;
begin
  Count := ReadInt(Data);
  while Count > 0 do
  begin
    Enm := TMicexEnumType.Create;
    Enm.LoadFromBuf(Data, v2);
    Add(Enm);
    Dec(Count);
  end;
end;

{ TMicexEnumType }

constructor TMicexEnumType.Create;
begin
  inherited;
  FConsts := TStringList.Create;
end;

destructor TMicexEnumType.Destroy;
begin
  FConsts.Free;
  inherited;
end;

function TMicexEnumType.GetAsText: string;
var
  I: Integer;
  S: string;
begin
  Result := '';
  for I := 0 to GetConstCount - 1 do
  begin
    FmtStr(S, '''%s''=%s', [GetConst(I), GetLongName(I)]);
    if Result <> '' then Result := Result + '; ';
    Result := Result + S; 
  end;
end;

function TMicexEnumType.GetConst(const Index: Integer): string;
begin
  if (Index >= 0) and (Index <= GetConstCount) then
    Result := Copy(FConsts[Index], 1, FSize)
  else Result := '';
end;

function TMicexEnumType.GetConstAndName(const Index: Integer): string;
var
  ZeroPos: Integer;
begin
  if (Index >= 0) and (Index <= GetConstCount) then
  begin
    Result := FConsts[Index];
    ZeroPos := Pos(#0, Result);
    if ZeroPos > 0 then Delete(Result, ZeroPos, MaxInt);
  end
  else Result := '';
end;

function TMicexEnumType.GetConstCount: Integer;
begin
  Result := FConsts.Count;
end;

function TMicexEnumType.GetConstIndex(const Value: string): Integer;
begin
  Result := FConsts.IndexOfName(Value);
end;

function TMicexEnumType.GetLongName(const Value: string): string;
begin
  Result := GetLongName(GetConstIndex(Value), Value);
end;

function TMicexEnumType.GetLongName(const Index: Integer; const Value: string = ''): string;
var
  ZeroPos: Integer;
begin
  if (Index >= 0) and (Index < GetConstCount) then
  begin
    Result := Copy(FConsts[Index], FSize + 2, MaxInt);
    ZeroPos := Pos(#0, Result);
    if ZeroPos > 0 then Delete(Result, ZeroPos, MaxInt);
  end
  else FmtStr(Result, '<%s>', [Value]);
end;

function TMicexEnumType.GetShortName(const Value: string): string;
begin
  Result := GetShortName(GetConstIndex(Value), Value);
end;

function TMicexEnumType.GetShortName(const Index: Integer; const Value: string = ''): string;
var
  ZeroPos: Integer;
begin
  if (Index >= 0) and (Index < GetConstCount) then
  begin
    Result := Copy(FConsts[Index], FSize + 2, MaxInt);
    ZeroPos := Pos(#0, Result);
    if ZeroPos > 0 then Delete(Result, 1, ZeroPos);
  end
  else FmtStr(Result, '<%s>', [Value]);
end;

procedure TMicexEnumType.LoadFromBuf(var Data: PChar; v2: boolean);
var
  Count: Integer;
begin
  FName := ReadStr(Data);
  FCaption := ReadStr(Data);
  if v2 then FDescription:= ReadStr(Data);
  FSize := ReadInt(Data);
  FKind := TTEEnumKind(ReadInt(Data));
  Count := ReadInt(Data);
  while Count > 0 do
  begin
    FConsts.Add(ReadStr(Data));
    if v2 then begin
      ReadStr(Data); // skip long desc
      ReadStr(Data); // skip short desc
    end;
    Dec(Count);
  end;
end;

end.
