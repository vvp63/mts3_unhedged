{$define global_objects}

unit mmfsendreceive;

interface

uses windows, classes, sysutils;

{$ifdef global_objects}
const names_prefix        = 'Global\';
{$else}
const names_prefix        = 'Local\';
{$endif}

const MutexName           = names_prefix + '{95494550-C095-4C3E-A061-27C6747C8DBB}';
      EventNameReady      = names_prefix + '{E1D4868B-0D20-432B-ADFC-704C05641287}';
      EventNameDone       = names_prefix + '{043FE61B-D80D-4B71-B969-BEB62BA51CCF}';

      EventNameConv       = names_prefix + '{8F70B490-AB50-45A2-BF98-E3DB8D00FD2F}';

      mmfDataNameSend     = names_prefix + '{D6ADBDCA-8A35-4460-B036-4EA9DF90A34C}';
      mmfDataNameReceive  = names_prefix + '{7804AE81-AE77-4ABA-9670-AD4F0B8958E3}';

type  tMMFCommunicator    = class(TObject)
      public
        FMutex            : longint;
        FEvReady          : longint;
        FEvDone           : longint;
        FEvConv           : longint;
      public
        constructor create;
        destructor  destroy; override;

        function    CreateServer : boolean;
        function    OpenServer: boolean;
        procedure   CloseServer;
        procedure   DoneServer;

        procedure   ResetServer;

        function    AcquireServerMutex: boolean;
        function    WaitServerMutex(atimeout: longint): boolean;
        function    WaitDataIsReady(atimeout: longint): boolean;
        procedure   ReleaseServerMutex;
        procedure   CloseServerMutex;

        procedure   CancelWaiting;

        function    WaitConvIsReady(atimeout: longint): boolean;
        procedure   SetConvReady;

        procedure   MMFSendData (const adata; adatalen: longint; const ammfname: ansistring); overload;
        procedure   MMFSendData (SendStream: tMemoryStream; const ammfname: ansistring); overload;
        function    MMFReceiveData (var abuffer; abuflen: longint; var aactuallen: longint; const ammfname: ansistring): longint; overload;
        procedure   MMFReceiveData (ReceiveStream: tMemoryStream; const ammfname: ansistring); overload;
        procedure   MMFReceiveData (ReceiveStrings: tStringList; const ammfname: ansistring); overload;
      end;

type  TResultFieldType    = (itString, itInteger, itDate, itFloat);

      TResultFieldDef     = record
        fieldname         : ansistring;
        fieldtype         : tResultFieldType;
        fieldlength       : longint;
      end;

      TResultBuilder      = class(tMemoryStream)
      private
        FMaxCols          : longint;
        FFieldDefs        : array of TResultFieldDef;
        procedure   WriteString(const astring: ansistring); overload;
        procedure   WriteString(astring: ansistring; maxlength: longint); overload;
        function    fGetFieldDef(aindex: longint): TResultFieldDef;
      public
        procedure   Clear;
        procedure   WriteResultColumns(const anames: array of ansistring;
                                       const coltypes: array of tResultFieldType;
                                       const collengths: array of longint);
        procedure   WriteResultRow(const arow: array of const);
        procedure   ReadResultColumns;
        function    ReadStringField: ansistring;
        function    ReadIntField: longint;
        function    ReadFloatField: double;
        function    ReadDateTimeField: tDateTime;

        property    FieldCount: longint read FMaxCols;
        property    FieldDefs[aindex: longint]: TResultFieldDef read fGetFieldDef;
      end;

function min(x, y: longint): longint;
function max(x, y: longint): longint;

implementation

function min(x, y: longint): longint;
begin if x < y then result:= x else result:= y; end;

function max(x, y: longint): longint;
begin if x > y then result:= x else result:= y; end;

{ tMMFCommunicator }

constructor tMMFCommunicator.create;
begin
  inherited create;
  FMutex   := 0;
  FEvReady := 0;
  FEvDone  := 0;
  FEvConv  := 0; 
end;

destructor tMMFCommunicator.destroy;
begin
  ReleaseServerMutex;
  DoneServer;
  inherited destroy;
end;

function tMMFCommunicator.CreateServer: boolean;
begin
  FMutex   := CreateMutex(nil, False, MutexName);
  FEvReady := CreateEvent(nil, False, False, EventNameReady);
  FEvDone  := CreateEvent(nil, False, False, EventNameDone);
  FEvConv  := CreateEvent(nil, False, False, EventNameConv);
  result   := ((FMutex <> 0) and (FEvReady <> 0) and (FEvDone <> 0) and (FEvConv <> 0));
end;

function tMMFCommunicator.OpenServer: boolean;
begin
  FEvReady:= OpenEvent(EVENT_ALL_ACCESS, False, EventNameReady);
  FEvDone:= OpenEvent(EVENT_ALL_ACCESS, False, EventNameDone);
  FEvConv:= OpenEvent(EVENT_ALL_ACCESS, False, EventNameConv);
  result:= ((FEvReady <> 0) and (FEvDone <> 0) and (FEvConv <> 0));
end;

procedure tMMFCommunicator.CloseServer;
var fm : THandle;
begin
  fm:= InterLockedExchange(FEvConv, 0);
  if (fm  <> 0) then CloseHandle(fm);
  fm:= InterLockedExchange(FEvDone, 0);
  if (fm  <> 0) then CloseHandle(fm);
  fm:= InterLockedExchange(FEvReady, 0);
  if (fm  <> 0) then CloseHandle(fm);
end;

procedure tMMFCommunicator.DoneServer;
var fm : THandle;
begin
  fm:= InterLockedExchange(FEvConv, 0);
  if (fm  <> 0) then CloseHandle(fm);
  fm:= InterLockedExchange(FEvReady, 0);
  if (fm  <> 0) then CloseHandle(fm);
  fm:= InterLockedExchange(FEvDone, 0);
  if (fm  <> 0) then CloseHandle(fm);
  fm:= InterLockedExchange(FMutex, 0);
  if (fm  <> 0) then CloseHandle(fm);
end;

procedure tMMFCommunicator.ResetServer;
begin
  if (FEvReady <> 0) then ResetEvent(FEvReady);
  if (FEvDone <> 0) then ResetEvent(FEvDone);
end;

function  tMMFCommunicator.AcquireServerMutex: boolean;
begin
  FMutex:= OpenMutex(MUTEX_ALL_ACCESS, False, MutexName);
  result:= (FMutex <> 0);
end;

function  tMMFCommunicator.WaitServerMutex(atimeout: longint): boolean;
begin result:= (WaitForSingleObject(FMutex, atimeout) = WAIT_OBJECT_0); end;

function  tMMFCommunicator.WaitDataIsReady(atimeout: longint): boolean;
begin result:= (WaitForSingleObject(FEvReady, atimeout) = WAIT_OBJECT_0); end;

procedure tMMFCommunicator.ReleaseServerMutex;
begin if (FMutex <> 0) then ReleaseMutex(FMutex); end;

procedure tMMFCommunicator.CloseServerMutex;
var fm : THandle;
begin
  fm:= InterLockedExchange(FMutex, 0);
  if (fm <> 0) then CloseHandle(fm);
end;


procedure tMMFCommunicator.CancelWaiting;
begin
  SetEvent(FEvReady);
end;


function  tMMFCommunicator.WaitConvIsReady(atimeout: longint): boolean;
begin
  result:= (WaitForSingleObject(FEvConv, atimeout) = WAIT_OBJECT_0);
end;

procedure tMMFCommunicator.SetConvReady;
begin
  SetEvent(FEvConv);
end;


procedure tMMFCommunicator.MMFSendData (const adata; adatalen: longint; const ammfname: ansistring);
var
  hDataFile    : THandle;
  pFileData, p : pAnsiChar;
  sd           : SECURITY_DESCRIPTOR;
  sa           : SECURITY_ATTRIBUTES;
begin
  InitializeSecurityDescriptor(@sd, SECURITY_DESCRIPTOR_REVISION);
  SetSecurityDescriptorDacl(@sd, true, nil, false);

  sa.nLength:= sizeof(sa);
  sa.lpSecurityDescriptor:= @sd;
  sa.bInheritHandle:= false;

  // Создаем MMF
  hDataFile:= CreateFileMapping(INVALID_HANDLE_VALUE, @sa, PAGE_READWRITE, 0, sizeof(longint) + adatalen, pAnsiChar(ammfname));
  if (hDataFile <> 0) then try
    pFileData := MapViewOfFile(hDataFile, FILE_MAP_WRITE, 0, 0, 0);
    if Assigned(pFileData) then try
      p:= pFileData;
      // copy data length to mmf
      CopyMemory(p, @adatalen, sizeof(longint));
      inc(p, sizeof(longint));
      // copy data to mmf
      CopyMemory(p, @adata, adatalen);
      // Signal to server that data is ready
      SetEvent(FEvReady);
      // Wait until data will be handled
      if (WaitForSingleObject(FEvDone, 10000) <> WAIT_OBJECT_0) then raise Exception.Create('SendEventServer was timed out');
    finally UnmapViewOfFile(pFileData); end else raise Exception.Create('Send Data memory-mapped file dataspace not found');
  finally CloseHandle(hDataFile); end else raise Exception.Create('Send Data memory-mapped file couldn''t be created');
end;

procedure tMMFCommunicator.MMFSendData (SendStream: tMemoryStream; const ammfname: ansistring);
begin if assigned(SendStream) then MMFSendData(SendStream.memory^, SendStream.Size, ammfname); end;

function tMMFCommunicator.MMFReceiveData (var abuffer; abuflen: longint; var aactuallen: longint; const ammfname: ansistring): longint;
var hDataFile     : THandle;
    pFileData, p  : pAnsiChar;
begin
  result:= 0; aactuallen:= 0;
  try
    hDataFile := OpenFileMapping(FILE_MAP_READ, False, pAnsiChar(ammfname));
    if (hDataFile <> 0) then try
      pFileData := MapViewOfFile(hDataFile, FILE_MAP_READ, 0, 0, 0);
      if Assigned(pFileData) then try
        p:= pFileData;
        CopyMemory(@aactuallen, p, sizeof(longint));
        result:= max(0, min(aactuallen, abuflen));
        inc(p, sizeof(longint));
        CopyMemory(@abuffer, p, result);
      finally UnmapViewOfFile(pFileData); end;
    finally CloseHandle(hDataFile); end;
  finally SetEvent(FEvDone); end;
end;

procedure tMMFCommunicator.MMFReceiveData (ReceiveStream: tMemoryStream; const ammfname: ansistring);
var hDataFile     : THandle;
    pFileData, p  : pAnsiChar;
    len           : longint;
begin
  try
    if assigned(ReceiveStream) then begin
      hDataFile := OpenFileMapping(FILE_MAP_READ, False, pAnsiChar(ammfname));
      if (hDataFile <> 0) then try
        pFileData := MapViewOfFile(hDataFile, FILE_MAP_READ, 0, 0, 0);
        if Assigned(pFileData) then try
          p:= pFileData;
          CopyMemory(@len, p, sizeof(longint));
          ReceiveStream.SetSize(len);
          if (len > 0) then begin
            inc(p, sizeof(longint));
            CopyMemory(ReceiveStream.memory, p, len);
          end;
          ReceiveStream.seek(0, soFromBeginning);
        finally UnmapViewOfFile(pFileData); end;
      finally CloseHandle(hDataFile); end;
    end;
  finally SetEvent(FEvDone); end;
end;

procedure tMMFCommunicator.MMFReceiveData (ReceiveStrings: tStringList; const ammfname: ansistring);
var hDataFile        : THandle;
    pFileData, p, pe : pAnsiChar;
    len              : longint;
    tmpstr           : ansistring;
begin
  try
    if assigned(ReceiveStrings) then begin
      hDataFile := OpenFileMapping(FILE_MAP_READ, False, pAnsiChar(ammfname));
      if (hDataFile <> 0) then try
        pFileData := MapViewOfFile(hDataFile, FILE_MAP_READ, 0, 0, 0);
        if Assigned(pFileData) then try
          CopyMemory(@len, pFileData, sizeof(longint));
          p:= pFileData + sizeof(longint); pe:= pFileData + sizeof(longint) + len;
          while (p < pe) do begin
            CopyMemory(@len, p, sizeof(longint));
            inc(p, sizeof(longint));
            if (p + len <= pe) then begin
              setlength(tmpstr, len);
              if (len > 0) then begin
                CopyMemory(@tmpstr[1], p, len);
                inc(p, len);
              end;
              ReceiveStrings.Add(tmpstr);
            end else inc(p, len);
          end;
        finally UnmapViewOfFile(pFileData); end;
      finally CloseHandle(hDataFile); end;
    end;
  finally SetEvent(FEvDone); end;
end;

{ TResultBuilder }

procedure TResultBuilder.Clear;
begin
  inherited Clear;
  FMaxCols:= 0;
  setlength(FFieldDefs, 0);
end;

procedure TResultBuilder.WriteString(const astring: ansistring);
var tmp : longint;
begin
  tmp:= length(astring);
  write(tmp, sizeof(tmp));
  if (tmp > 0) then write(astring[1], tmp);
end;

procedure TResultBuilder.WriteString(astring: ansistring; maxlength: longint);
var tmp : longint;
begin
  if (length(astring) > maxlength) then setlength(astring, maxlength);
  tmp:= length(astring);
  write(tmp, sizeof(tmp));
  if (tmp > 0) then write(astring[1], tmp);
end;

function TResultBuilder.fGetFieldDef(aindex: longint): TResultFieldDef;
begin
  if (aindex >= 0) and (aindex < length(FFieldDefs)) then begin
    result:= FFieldDefs[aindex];
  end else begin
    result.fieldname:= format('column%d', [aindex]);
    result.fieldtype:= itString;
  end;
end;

procedure TResultBuilder.WriteResultColumns(const anames: array of ansistring;
                                            const coltypes: array of tResultFieldType;
                                            const collengths: array of longint);
var   i : longint;
begin
   Clear;
   FMaxCols:= max(length(anames), length(coltypes));
   setlength(FFieldDefs, FMaxCols);
   Write(FMaxCols, sizeof(FMaxCols));
   if (FMaxCols > 0) then
     for i:= 0 to FMaxCols - 1 do
       with FFieldDefs[i] do begin
         if (i <= high(anames))    then fieldname:= anames[i]   else fieldname:= format('column%d', [i]);
         if (i <= high(coltypes))  then fieldtype:= coltypes[i] else fieldtype:= itString;
         case fieldtype of
           itString  : if (i <= high(collengths)) then begin
                         fieldlength:= min(8000, collengths[i]);
                       end else fieldlength:= 8000;
           itInteger : fieldlength:= sizeof(longint);
           itFloat,
           itDate    : fieldlength:= sizeof(double);
         end;
         WriteString(fieldname);
         Write(fieldtype, sizeof(fieldtype));
         Write(fieldlength, sizeof(fieldlength));
       end;
end;

procedure TResultBuilder.WriteResultRow(const arow: array of const);
var   i       : longint;
      fv      : double;
const boolval : array[boolean] of longint = (0, 1);
  procedure writeempty(afieldtype: tResultFieldType);
  const intnull : longint = 0;
        dblnull : double  = 0.0;
  begin
    case afieldtype of
      itString        : writestring('');
      itInteger       : write(intnull, sizeof(longint));
      itDate, itFloat : write(dblnull, sizeof(double));
    end;
  end;
begin
  if (length(arow) > 0) then
    for i:= 0 to FMaxCols - 1 do with FieldDefs[i] do
      if i < length(arow) then begin
        with arow[i] do
          case vType of
            vtBoolean,
            vtInteger,
            vtInt64      : if (fieldtype = itInteger) then begin
                             case vType of
                               {boolean}
                               vtBoolean    : write(boolval[vBoolean], sizeof(longint));
                               {numeric}
                               vtInteger    : write(vInteger, sizeof(longint));
                               vtInt64      : begin fv:= vInt64^;    write(fv, sizeof(fv)); end;
                             end;
                           end else writeempty(fieldtype);

            vtExtended,
            vtCurrency   : if ((fieldtype = itDate) or (fieldtype = itFloat)) then begin
                             case vType of
                               {numeric}
                               vtExtended   : begin fv:= vExtended^; write(fv, sizeof(fv)); end;
                               vtCurrency   : begin fv:= vCurrency^; write(fv, sizeof(fv)); end;
                             end;
                           end else writeempty(fieldtype);
            vtChar,
            vtString,
            vtPChar,
            vtAnsiString,
            vtVariant    : if (fieldtype = itString) then begin
                             case vType of
                               {string}
                               vtChar       : WriteString(vChar, fieldlength);
                               vtString     : WriteString(ansistring(vString^), fieldlength);
                               vtPChar      : WriteString(vPChar, fieldlength);
                               vtAnsiString : WriteString(ansistring(vAnsiString), fieldlength);
                               {variant}
                               vtVariant    : WriteString(ansistring(vVariant^), fieldlength);
                             end;
                           end else writeempty(fieldtype);
          end;
      end else writeempty(fieldtype);
end;

procedure TResultBuilder.ReadResultColumns;
var i   : longint;
    tmp : longint;
begin
  FMaxCols:= 0;
  if (read(FMaxCols, sizeof(FMaxCols)) = sizeof(FMaxCols)) then begin
    setlength(FFieldDefs, FMaxCols);
    for i:= 0 to FMaxCols - 1 do with FFieldDefs[i] do
      if (read(tmp, sizeof(tmp)) = sizeof(tmp)) then begin
        setlength(fieldname, tmp);
        read(fieldname[1], tmp);
        read(fieldtype, sizeof(fieldtype));
        read(fieldlength, sizeof(fieldlength));
      end else begin
        setlength(fieldname, 0);
        fieldtype:= itInteger;
        fieldlength:= sizeof(longint);
      end;
  end else setlength(FFieldDefs, FMaxCols);
end;

function TResultBuilder.ReadStringField: ansistring;
var len : longint;
begin
  len:= 0;
  read(len, sizeof(len));
  setlength(result, len);
  if (len > 0) then read(result[1], len);
end;

function TResultBuilder.ReadIntField: longint;
begin read(result, sizeof(result)); end;

function TResultBuilder.ReadFloatField: double;
begin read(result, sizeof(result)); end;

function TResultBuilder.ReadDateTimeField: tDateTime;
begin result:= ReadFloatField; end;

end.