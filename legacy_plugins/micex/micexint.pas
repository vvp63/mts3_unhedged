{$I micexdefs.pas}

unit  micexint;

interface

uses  windows, sysutils,
      MTETypes, MTEApi,
      micexglobal, micexfldidx, micexthreads,
      servertypes, sortedlist;

type  pFieldDesc       = ^tFieldDesc;
      tFieldDesc       = record
       fName           : string;
       fDesc           : string;
       fEnumType       : string;
       fSize           : cardinal;
       fType           : cardinal;
       fAttr           : cardinal;
       fNumber         : cardinal;
       fUniIndex       : longint;
      end;

type  tfieldnums       = array of longint;

type  tBufParser       = class(tObject)
      private
       fbuffer         : pMTEMsg;
       foffset         : cardinal;
       fsize           : cardinal;
       procedure   fSetBuffer(buf: pMTEMsg);
       function    fIsEmpty: boolean;
      public
       constructor create(buf: pMTEMsg);
       destructor  destroy; override;
       property    buffer: pMTEMsg read fbuffer write fSetBuffer;
       property    empty: boolean read fIsEmpty;
       function    getchar:char;
       function    getinteger:longint;
       function    getsizedstring(len:cardinal):string;
       function    peeksizedstringofs(ofs,len:cardinal):string;
       function    getstring:string;
       procedure   skipbytes(len:longint);
       procedure   skipstring;
      end;

type  tTableDescriptor = class(tSortedList)
      private
       fParser         : tBufParser;
       fConnection     : tConnectionThread;
       fCSect          : pRTLCriticalSection;
       fTableName      : string;
       function    getitem(idx: longint): pointer;
       function    getlinkhandle: longint;
      protected
       procedure   settablename(const atablename: string); virtual;
       procedure   setrawdata(abuf: pMTEMsg);
      public
       handle          : longint;
       tabledesc       : string;
       tableattr       : longint;
       index           : array of longint;
       opened          : boolean;
       constructor create(aConnection: tConnectionThread; asection: pRTLCriticalSection); reintroduce; virtual;
       destructor  destroy; override;
       procedure   freeitem(item:pointer); override;
       function    checkitem(item:pointer):boolean; override;
       function    compare(item1,item2:pointer):longint; override;

       procedure   lock;
       procedure   unlock;

       procedure   registerboard(const alevel: tLevel);

       function    getstructure:longint;
       procedure   processfield(uniindex:longint; const value:array of const); virtual; abstract;
       function    open:longint; virtual; abstract;
       function    update:longint; virtual; abstract;
       function    close:longint; virtual;
       procedure   processfields(const fieldslist: tFieldNums; adevider: longint);
       function    getfieldbyname(const name: string; const fieldslist: tFieldNums):string;

       property    fields[idx:longint]:pointer read getitem;
       property    linkhandle: longint read getlinkhandle;
       property    tablename: string read ftablename write settablename;
       property    parser: tBufParser read fParser;
      end;

function max(x, y: cardinal): cardinal;
function min(x, y: cardinal): cardinal;
function intpower(base, exponent: cardinal): cardinal;

implementation

function min; register; assembler;
asm
         cmp     eax,edx
         jl      @@max01
         mov     eax,edx
@@max01:
end;

function max; register; assembler;
asm
         cmp     eax,edx
         jg      @@max01
         mov     eax,edx
@@max01:
end;

function intpower;
var i : cardinal;
begin
 result:= 1;
 for i:= 1 to exponent do result:= result * base;
end;

{ tBufParser }

constructor tBufParser.create;
begin
  inherited create;
  fbuffer:= nil; fsize:= 0;
  fSetBuffer(buf);
end;

destructor tBufParser.destroy;
var tmp : pointer;
begin
  fsize:= 0;
  tmp:= pointer(InterlockedExchange(longint(fbuffer), 0));
  if assigned(tmp) then freemem(tmp);
  inherited destroy;
end;

procedure tBufParser.fSetBuffer;
var size : cardinal;
begin
  try
    foffset:= 1;
    if assigned(buf) then begin
      size:= buf^.DataLen + sizeof(cardinal);
      if (fsize < size) then begin
        reallocmem(fbuffer, size);
        fsize:= size;
      end;
      if assigned(fbuffer) then system.move(buf^, fbuffer^, size);
    end else begin
      if assigned(fbuffer) and (fsize >= sizeof(cardinal)) then fbuffer^.DataLen:= 0;
    end;
  except
    on e: exception do begin
      micexlog('BUFPARSER: Error setting buffer: %p; exception: %s', [pointer(buf), e.message]);
      raise;
    end;
  end;
end;

function tBufParser.fIsEmpty: boolean;
begin result:= not (assigned(fbuffer) and (fsize >= sizeof(cardinal)) and (fbuffer^.DataLen > 0)); end;

function tBufParser.getchar;
begin
  result:= #0;
  if assigned(fbuffer) then
    if (foffset - 1 <= fbuffer^.DataLen - 1) then begin
      result:= char(pAnsiChar(@fbuffer^.data)[foffset]);
      inc(foffset);
    end;
end;

function tBufParser.getinteger;
begin
  result:= 0;
  if assigned(fbuffer) then
    if (foffset - 1 <= fbuffer^.DataLen - 4) then begin
      system.move(pAnsiChar(@fbuffer^.data)[foffset], result, 4);
      inc(foffset, 4);
    end;
end;

function tBufParser.getsizedstring;
begin
  setlength(result, 0);
  if assigned(fbuffer) and (len > 0) then
    if (foffset - 1 <= fbuffer^.DataLen - len) then begin
      setlength(result, len);
      move(pAnsiChar(@fbuffer^.data)[foffset], result[1], len);
      inc(foffset, len);
    end;
end;

function tBufParser.peeksizedstringofs;
begin
  setlength(result, 0);
  if assigned(fbuffer) and (len > 0) then
    if (foffset - 1 <= fbuffer^.DataLen - len - ofs) then begin
      setlength(result, len);
      move(pAnsiChar(@fbuffer^.data)[foffset + ofs], result[1], len);
    end;
end;

function tBufParser.getstring;
begin result:= getsizedstring(getinteger); end;

procedure tBufParser.skipbytes;
begin inc(foffset, len); end;

procedure tBufParser.skipstring;
begin skipbytes(getinteger); end;

{ tTableDescriptor }

constructor tTableDescriptor.create(aConnection: tConnectionThread; asection: pRTLCriticalSection);
begin
  inherited create;
  fduplicates := dupIgnore;
  setlength(index, 0);
  fParser     := nil;
  fConnection := aConnection;
  fCSect      := asection;
  handle      := -1;
  opened      := false;
end;

destructor tTableDescriptor.destroy;
begin
  close;
  if assigned(fParser) then freeandnil(fParser);
  inherited destroy;
end;

procedure tTableDescriptor.freeitem; begin if assigned(item) then dispose(pFieldDesc(item)); end;
function tTableDescriptor.checkitem; begin result:= true; end;
function tTableDescriptor.compare; begin result:= CompareText(pFieldDesc(item1)^.fName, pFieldDesc(item2)^.fName); end;
function tTableDescriptor.getitem; begin if (idx >= 0) and (idx < count) then result:= items[index[idx]] else result:= nil; end;

function tTableDescriptor.getlinkhandle: longint;
begin if assigned(fConnection) then result:= fConnection.datconnection else result:= -1; end;

procedure tTableDescriptor.settablename(const atablename: string);
begin fTableName:= atablename; end;

procedure tTableDescriptor.setrawdata(abuf: pMTEMsg);
begin
  if not assigned(fParser) then begin
    if assigned(abuf) then fParser:= tBufParser.create(abuf);
  end else fParser.buffer:= abuf;
end;


procedure tTableDescriptor.lock;
begin if assigned(fCSect) then EnterCriticalSection(fCSect^); end;
procedure tTableDescriptor.unlock;
begin if assigned(fCSect) then LeaveCriticalSection(fCSect^); end;

procedure tTableDescriptor.registerboard(const alevel: tLevel);
begin if assigned(fConnection) and assigned(fConnection.Boards) then fConnection.Boards.registerboard(alevel); end;

function tTableDescriptor.getstructure;
var heap   : pMTEMsg;
    i,j    : longint;
    tname  : string;
    f      : boolean;
    itm    : pFieldDesc;
begin
  heap:= nil;
  freeall; result:=-1;
  try
    lock;
    try
      result:= MTEStructure(linkhandle, heap);
      if (result = MTE_OK) then setrawdata(heap) else setrawdata(nil);
      if assigned(parser) and not parser.empty then with parser do begin
        //--- пропускаем информацию о интерфейсе --------------------------
        skipstring;                                          // Имя интерфейса
        skipstring;                                          // Описание интерфейса
        for i:= 1 to getinteger do begin                     // Количество перечислимых типов
          skipstring;                                        // Имя
          skipstring;                                        // Описание
          skipbytes(4 * 2);                                  // Размер // Тип
          for j:= 1 to getinteger do skipstring;             // Кол-во констант
        end;
        //--- выцепляем структуру нужной таблицы --------------------------
        for i:= 1 to getinteger do begin                      // Число таблиц
          tname:= getstring;                                  // Название таблицы
          f:= (uppercase(trim(tname)) = tablename);
          if f then begin
            tabledesc:=getstring;                             // Описание таблицы
            tableattr:=getinteger;                            // Атрибуты
          end else begin skipstring; skipbytes(4); end;
          for j:= 0 to getinteger - 1 do begin                // Число входных полей в таблице
            skipstring;                                       // Имя поля
            skipstring;                                       // Описание
            skipbytes(4*3);                                   // Размер поля // Тип поля // Атрибуты поля
            skipstring;                                       // Перечислимый тип
            skipstring;                                       // Значение по умолчанию
          end;
          for j:=0 to getinteger-1 do begin                   // Число выходных полей в таблице
            itm:= new(pFieldDesc);
            with itm^ do begin
              fname     := getstring;                         // Имя поля
              fdesc     := getstring;                         // Описание
              fsize     := getinteger;                        // Размер поля
              ftype     := getinteger;                        // Тип поля
              fattr     := getinteger;                        // Атрибуты поля
              fenumtype := getstring;                         // Перечислимый тип
              fnumber   := j;                                 // Номер поля
              fUniIndex := FieldNameIndex.indexbyname(fname); // Уникальный внутренний номер поля
              {$ifdef FixMicexAccruedintBug}
              if (fUniIndex = fldACCRUEDINT) then ftype:= ord(ftFloat);
              {$endif}
            end;
            if f then add(itm) else dispose(itm);
          end;
        end;
        //--- далее идут описания транзакций, мы их скипуем ---------------
        setlength(index, count);
        for i:= 0 to count - 1 do
          with pFieldDesc(items[i])^ do index[fnumber]:= i;
      end;
    finally unlock; end;
  except on e:exception do micexlog('Exception: %s', [e.message]); end;
end;

function tTableDescriptor.close;
begin
  if (linkhandle >= MTE_OK) and (handle >= MTE_OK) then begin
    lock;
    try result:= MTECloseTable(linkhandle, handle);
    finally unlock; end;
  end else result:=-1;
end;

procedure tTableDescriptor.processfields;
var i               : longint;
    itm             : pFieldDesc;
    fldint          : int64;
    fldfix          : currency absolute fldint;

  function trimnumber(const st: string): string;
  begin result:= trim(st); if (length(result) = 0) then result:= '0'; end;

  function micexstrtodate(const md: string): tDateTime;
  var d, m, y : longint;
  begin
    if (length(md) = 8) and (md <> '00000000') then begin
      y:= strtointdef(copy(md, 1, 4), 0);
      m:= strtointdef(copy(md, 5, 2), 0);
      d:= strtointdef(copy(md, 7, 2), 0);
      result:= encodedate(y, m, d);
    end else result:= 0;
  end;

  function micexstrtotime(const mt: string): tDateTime;
  var h, m, s : longint;
  begin
    if (length(mt) = 6) and (mt <> '000000') then begin
      h:= strtointdef(copy(mt, 1, 2), 0);
      m:= strtointdef(copy(mt, 3, 2), 0);
      s:= strtointdef(copy(mt, 5, 2), 0);
      result:= encodetime(h, m, s, 0);
    end else result:= 0;
  end;

begin
  if adevider = 0 then adevider:= 1;
  if assigned(parser) and not parser.empty then begin
    for i:= 0 to length(fieldslist) - 1 do begin
      itm:= fields[fieldslist[i]];
      try
        if assigned(itm) then with itm^ do
          if (funiindex <> fldUnknownField) then begin
            case TTEFieldType(ftype) of
              ftChar    : processfield(funiindex,[trim(parser.getsizedstring(fsize))]);
              ftInteger : processfield(funiindex,[strtoint64def(trimnumber(parser.getsizedstring(fsize)), 0)]);
              ftFixed   : begin
                            fldint:= strtoint64def(trimnumber(parser.getsizedstring(fsize)), 0) * 100;
                            processfield(funiindex, [fldfix]);
                          end;
              ftFloat   : processfield(funiindex,[strtoint64def(trimnumber(parser.getsizedstring(fsize)), 0) / adevider]);
              ftDate    : processfield(funiindex, [micexstrtodate(trim(parser.getsizedstring(fsize)))]);
              ftTime    : processfield(funiindex, [micexstrtotime(trim(parser.getsizedstring(fsize)))]);
            end;
          end else parser.skipbytes(fsize);
      except on e:exception do micexlog('Field name: %s Exception: %s', [itm^.fname, e.message]); end;
    end;
  end;
end;

function tTableDescriptor.getfieldbyname;
 var itm    : tFieldDesc;
     idx    : longint;
     ofs    : cardinal;
     nfield : longint;
begin
  try
    setlength(result,0);
    itm.fname:= name;
    if assigned(parser) and not parser.empty and search(@itm,idx) then begin
      nfield:= pFieldDesc(items[idx])^.fNumber;
      ofs:= 0; idx:= 0;
      while (idx<length(fieldslist)) do begin
        if (fieldslist[idx] = nfield) then begin
          result:=trim(parser.peeksizedstringofs(ofs, pFieldDesc(fields[fieldslist[idx]])^.fSize));
          idx:=length(fieldslist);
        end else inc(ofs,pFieldDesc(fields[fieldslist[idx]])^.fSize);
        inc(idx);
      end;
    end;
  except on e:exception do setlength(result,0); end;
end;

end.
