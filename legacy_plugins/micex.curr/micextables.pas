{$I micexdefs.pas}

unit micextables;

interface

uses  {$ifdef MSWINDOWS} windows, {$endif}
      sysutils, classes,
      servertypes, serverapi, sortedlist, classregistration,
      MTETypes, MTEApi, MTEUtils, 
      micexglobal, micexfldidx, micexint, micexthreads, micexstats, micexsubst;

type  tSettleCode      = string[3];

type  pOrderStorageItm = ^tOrderStorageItm;
      tOrderStorageItm = record
        order          : tOrders;
        orderset       : tOrdersSet;
      end;

      tOrderRegistry   = class(tCustomList)
        procedure   freeitem(item:pointer); override;
        procedure   add(var ord:tOrders; ordset:tOrdersSet); reintroduce; virtual;
        procedure   process; virtual;
      end;

type  pTradeStorageItm = ^tTradeStorageItm;
      tTradeStorageItm = record
        trade          : tTrades;
        tradeset       : tTradesSet;
      end;

      tTradeRegistry   = class(tCustomList)
        procedure   freeitem(item:pointer); override;
        procedure   add(var trd:tTrades; trdset:tTradesSet); reintroduce; virtual;
        procedure   process; virtual;
      end;

type  tCustomTableDescriptor = class(tTableDescriptor)
      private
        fTableParams         : string;
      protected
        fldnums              : tFieldNums;
        function    getdivider: cardinal; virtual;
        function    canopen: boolean; virtual;
        procedure   parse; virtual;
        procedure   beforeparse(arecordcount: longint); virtual;
        procedure   afterparse; virtual;
        procedure   beforeprocessfields; virtual;
        procedure   afterprocessfields; virtual;
      public
        constructor create(aConnection: tConnectionThread; asection:pRTLCriticalSection); override;
        function    open:longint; override;
        function    update:longint; override;
        property    TableParams: string read fTableParams write fTableParams;
      end;

type  tFirmsTable      = class(tCustomTableDescriptor)
      private
        frm            : tFirmIdent;
        frmset         : tFirmSet;
      protected
        procedure   beforeprocessfields; override;
        procedure   afterprocessfields; override;
      public
        constructor create(aConnection: tConnectionThread; asection: pRTLCriticalSection); override;
        procedure   processfield(uniindex: longint; const value: array of const); override;
      end;

type  tSettleCodesTable = class(tCustomTableDescriptor)
      private
        sc              : tSettleCodes;
      protected
        procedure   beforeprocessfields; override;
        procedure   afterprocessfields; override;
      public
        constructor create(aConnection: tConnectionThread; asection:pRTLCriticalSection); override;
        procedure   processfield(uniindex:longint; const value:array of const); override;
        function    update:longint; override;
      end;

type  tSystemTimeTable = class(tCustomTableDescriptor)
      private
        micex_dt       : tDateTime;
      protected
        procedure   beforeprocessfields; override;
        procedure   afterprocessfields; override;
      public
        constructor create(aConnection: tConnectionThread; asection:pRTLCriticalSection); override;
        procedure   processfield(uniindex:longint; const value:array of const); override;
        function    update:longint; override;
      end;

type  tSecuritiesTable = class(tCustomTableDescriptor)
      private
        sec            : tSecurities;
        secset         : tSecuritiesSet;
      protected
        function    getdivider: cardinal; override;
        procedure   beforeprocessfields; override;
        procedure   afterprocessfields; override;
      public
        constructor create(aConnection: tConnectionThread; asection: pRTLCriticalSection); override;
        destructor  destroy; override;
        procedure   processfield(uniindex: longint; const value: array of const); override;
        function    open: longint; override;
      end;

type  tFilteredTable   = class(tTableDescriptor)
        filterisset    : boolean;
        filtervalue    : ansistring;
        function    checkfilter: boolean; virtual;
      end;

type  tOrdersTable     = class(tFilteredTable)
        ord            : tOrders;
        ordset         : tOrdersSet;
        orderbuf       : tOrderRegistry;
        constructor create(aConnection: tConnectionThread; asection:pRTLCriticalSection); override;
        destructor  destroy; override;
        procedure   processfield(uniindex:longint; const value:array of const); override;
        function    open:longint; override;
        function    update:longint; override;
        procedure   parse;
      end;

type  tRepoOrdersTable = class(tFilteredTable)
        ord            : tOrders;
        ordset         : tOrdersSet;
        orderbuf       : tOrderRegistry;
        constructor create(aConnection: tConnectionThread; asection:pRTLCriticalSection); override;
        destructor  destroy; override;
        procedure   processfield(uniindex:longint; const value:array of const); override;
        function    open:longint; override;
        function    update:longint; override;
        procedure   parse;
      end;

type  tTradesTable     = class(tFilteredTable)
        trd            : tTrades;
        trdset         : tTradesSet;
        tradebuf       : tTradeRegistry;
        constructor create(aConnection: tConnectionThread; asection:pRTLCriticalSection); override;
        destructor  destroy; override;
        procedure   processfield(uniindex:longint; const value:array of const); override;
        function    open:longint; override;
        function    update:longint; override;
        procedure   parse;
      end;

type  tRepoTradesTable = class(tFilteredTable)
        trd            : tTrades;
        trdset         : tTradesSet;
        tradebuf       : tTradeRegistry;
        constructor create(aConnection: tConnectionThread; asection:pRTLCriticalSection); override;
        destructor  destroy; override;
        procedure   processfield(uniindex:longint; const value:array of const); override;
        function    open:longint; override;
        function    update:longint; override;
        procedure   parse;
      end;

type  tKotirovkiTable  = class(tCustomTableDescriptor)
      private
        kot            : tKotirovki;
        deleteditems   : tStringList;
      protected
        function    getdivider: cardinal; override;
        function    canopen: boolean; override;
        procedure   beforeparse(arecordcount: longint); override;
        procedure   afterparse; override;
        procedure   beforeprocessfields; override;
        procedure   afterprocessfields; override;
      public
        constructor create(aConnection: tConnectionThread; asection:pRTLCriticalSection); override;
        destructor  destroy; override;
        procedure   processfield(uniindex:longint; const value:array of const); override;
      end;

type  tAllTradesTable  = class(tCustomTableDescriptor)
      private
        atd            : tAllTrades;
        updatecounter  : longint;
      protected
        function    getdivider: cardinal; override;
        function    canopen: boolean; override;
        procedure   beforeprocessfields; override;
        procedure   afterprocessfields; override;
      public
        constructor create(aConnection: tConnectionThread; asection:pRTLCriticalSection); override;
        procedure   processfield(uniindex:longint; const value:array of const); override;
        function    update:longint; override;
      end;

type  tMessagesTable  = class(tCustomTableDescriptor)
      private
        updatecounter     : longint;
        fromuser, msgtext : string;
        msgtime           : tDateTime;
      protected
        procedure   beforeprocessfields; override;
        procedure   afterprocessfields; override;
      public
        constructor create(aConnection: tConnectionThread; asection:pRTLCriticalSection); override;
        procedure   processfield(uniindex:longint; const value:array of const); override;
        function    update:longint; override;
      end;

type  tIndexesTable = class(tCustomTableDescriptor)
      private
        sec         : tSecurities;
        secset      : tSecuritiesSet;
      protected
        function    getdivider: cardinal; override;
        procedure   beforeprocessfields; override;
        procedure   afterprocessfields; override;
      public
        constructor create(aConnection: tConnectionThread; asection:pRTLCriticalSection); override;
        procedure   processfield(uniindex:longint; const value:array of const); override;
      end;

const SecuritiesFlag : boolean = false;

implementation

function CheckSettleCode(const asc: tSettleCode): boolean;
begin
  result:= true;
  if (length(asc) >= 1) then result:= (upcase(asc[1]) <> 'B') or (asc = 'B0');
end;

function SettleCodeToType(const asc: tSettleCode; rpsdef: boolean): char;
begin
  if ((length(asc) = 0) or (asc[1] = ' ')) then result:= 'N' else
  if (asc[1] = 'B')                        then result:= 'P' else
  if (asc[1] = 'R')                        then result:= 'R' else result:= asc[1];
  if rpsdef and (result = 'T') then result:= 'P';
end;

function getInternalTrsID(const avalue:string):longint;
begin result:= strtointdef(avalue, -1); end;

{ tOrderRegistry }

procedure tOrderRegistry.freeitem;
begin if assigned(item) then dispose(pOrderStorageItm(item)); end;

procedure tOrderRegistry.add;
var itm : pOrderStorageItm;
begin
  itm:=new(pOrderStorageItm);
  with itm^ do begin order:=ord; orderset:=ordset; end;
  inherited add(itm);
end;

procedure tOrderRegistry.process;
var aadd : boolean;
begin
  aadd:= false;
  try
    while {$ifdef UseSetOrderFlag}not setorderflag and{$endif} (count > 0) do try
      with pOrderStorageItm(items[0])^ do begin
        if not aadd then try
          if assigned(Server_API.OrdersBeginUpdate) then Server_API.OrdersBeginUpdate(micexId, '');
        finally aadd:= true; end;
        Server_API.AddOrdersRec(order, orderset);
      end;
    finally delete(0); end;
  finally if aadd and assigned(Server_API.OrdersEndUpdate) then Server_API.OrdersEndUpdate(micexId, ''); end;
end;

{ tTradeRegistry }

procedure tTradeRegistry.freeitem;
begin if assigned(item) then dispose(pTradeStorageItm(item)); end;

procedure tTradeRegistry.add;
var itm : pTradeStorageItm;
begin
  itm:=new(pTradeStorageItm);
  with itm^ do begin trade:=trd; tradeset:=trdset; end;
  inherited add(itm);
end;

procedure tTradeRegistry.process;
var aadd : boolean;
begin
  aadd:= false;
  try
    while {$ifdef UseSetOrderFlag}not setorderflag and{$endif} (count > 0) do try
      with pTradeStorageItm(items[0])^ do begin
        if not aadd then try
          if assigned(Server_API.TradesBeginUpdate) then Server_API.TradesBeginUpdate(micexId, '');
        finally aadd:= true; end;
        Server_API.AddTradesRec(trade, tradeset);
      end;
    finally delete(0); end;
  finally if aadd and assigned(Server_API.TradesEndUpdate) then Server_API.TradesEndUpdate(micexId, ''); end;
end;

{ tCustomTableDescriptor }

procedure tCustomTableDescriptor.afterparse;
begin end;

procedure tCustomTableDescriptor.beforeparse(arecordcount: longint);
begin end;

procedure tCustomTableDescriptor.afterprocessfields;
begin end;

procedure tCustomTableDescriptor.beforeprocessfields;
begin end;

function tCustomTableDescriptor.canopen: boolean;
begin result:= true; end;

function tCustomTableDescriptor.open: longint;
var heap     : pMTEMsg;
begin
  if not opened and canopen then begin
    getstructure;
    lock;
    try
      setrawdata(nil);
      try
        handle:= MTEOpenTable(linkhandle, pchar(TableName), pchar(TableParams), openTableComplete, heap);
        if (handle >= MTE_OK) then setrawdata(heap);
      except on e: exception do micexlog('%s OPEN: Exception: %s', [TableName, e.message]); end;
    finally unlock; end;
    if (handle >= MTE_OK) then begin
      if assigned(parser) and not parser.empty then parse;
      opened:= true;
    end;
    result:= handle;
  end else result:= 0;
end;

function tCustomTableDescriptor.update: longint;
var heap     : pMTEMsg;
begin
  if (handle >= MTE_OK) then begin
    result:= -1;
    lock;
    try
      setrawdata(nil);
      try
        MTEAddTable(linkhandle, handle, 0);
        result:= MTERefresh(linkhandle, heap);
        if (result >= MTE_OK) then setrawdata(heap);
      except on e: exception do micexlog('%s UPDATE: Exception: %s', [TableName, e.message]); end;
    finally unlock; end;
    if (result >= MTE_OK) and assigned(parser) and not parser.empty then parse;
  end else result:= -1;
end;

function tCustomTableDescriptor.getdivider: cardinal;
begin result:= 1; end;

procedure tCustomTableDescriptor.parse;
var i, j, flds  : longint;
    recordcount : longint;
begin
  if assigned(parser) and not parser.empty then with parser do begin
    if opened then skipbytes(4);      // скипуем кол-во таблиц. д.б. 1 (только при открытии)
    skipbytes(4);                     // поле ref
    recordcount:= getinteger;         // кол-во строк в таблице
    beforeparse(recordcount);
    try
      for i:= 1 to recordcount do begin
        flds:= byte(getchar);           // число полей в строке
        skipbytes(4);                   // длинна данных в строке
        if (flds = 0) then begin setlength(fldnums, count); for j:= 0 to count - 1 do fldnums[j]:= j; end
                      else begin setlength(fldnums, flds); for j:= 0 to flds - 1  do fldnums[j]:= byte(getchar); end;
        beforeprocessfields;
        try
          processfields(fldnums, getdivider);
        finally afterprocessfields; end;
      end;
    finally afterparse; end;
  end;
end;

constructor tCustomTableDescriptor.create(aConnection: tConnectionThread; asection: pRTLCriticalSection);
begin
  setlength(fTableParams, 0);
  inherited create(aConnection, asection);
end;

{ tFirmsTable }

constructor tFirmsTable.create;
begin
  inherited create(aConnection, asection);
  TableName:= 'FIRMS';
end;

procedure tFirmsTable.beforeprocessfields;
begin
  FillChar(frm,sizeof(tFirmIdent),0);
  frm.stock_id:= micexId;
  frmset:= [fid_stock_id];
end;

procedure tFirmsTable.processfield;
begin
  case uniindex of
    fldFIRMID        : begin frm.firmid := format('%s',value);     include(frmset, fid_firmid);   end;
    fldFIRMNAME      : begin frm.firmname := format('%s',value);   include(frmset, fid_firmname); end;
    fldSTATUS        : begin frm.status := format('%s ',value)[1]; include(frmset, fid_status);   end;
  end;
end;

procedure tFirmsTable.afterprocessfields;
begin if (frmset >= [fid_stock_id,fid_firmid]) then Server_API.AddFirmsRec(frm, frmset); end;

{ tSettleCodesTable }

constructor tSettleCodesTable.create;
begin
  inherited create(aConnection, asection);
  TableName:= 'SETTLECODES';
end;

procedure tSettleCodesTable.beforeprocessfields;
begin FillChar(sc, sizeof(tSettleCodes), 0); sc.stock_id:= micexId; end;

procedure tSettleCodesTable.processfield;
begin
  case uniindex of
    fldSETTLECODE      : sc.settlecode:= format('%s',value);
    fldDESCRIPTION     : sc.description:= format('%s',value);
    fldSETTLEDATE      : sc.settledate1:= value[low(value)].vextended^;
    fldSETTLEDATE2     : sc.settledate2:= value[low(value)].vextended^;
  end;
end;

procedure tSettleCodesTable.afterprocessfields;
begin Server_API.AddSettleCodesRec(sc); end;

function tSettleCodesTable.update;
begin result:= MTE_OK; end;

{ tSystemTimeTable }

constructor tSystemTimeTable.create;
begin
  inherited create(aConnection, asection);
  TableName:= 'TESYSTIME';
end;

procedure tSystemTimeTable.beforeprocessfields;
begin micex_dt:= now; end;

procedure tSystemTimeTable.processfield;
begin
  case uniindex of
    fldTIME     : micex_dt := trunc(micex_dt) + value[low(value)].vextended^;
    fldDATE     : micex_dt := frac(micex_dt) + value[low(value)].vextended^;
  end;
end;

procedure tSystemTimeTable.afterprocessfields;
begin if synchronizetime then MicexSynchronizeTime(micex_dt); end;

function tSystemTimeTable.update;
begin result:= MTE_OK; end;

{ tSecuritiesTable }

constructor tSecuritiesTable.create;
begin
  inherited create(aConnection, asection);
  TableName:= 'SECURITIES';
  TableParams:= '        ';
end;

destructor tSecuritiesTable.destroy;
begin securitiesflag:= false; inherited destroy; end;

function tSecuritiesTable.getdivider: cardinal;
var tmp : string;
begin
  if not opened then begin
    tmp:= getfieldbyname('DECIMALS', fldnums);
    if (length(tmp) > 0) then result:= intpower(10, strtointdef(tmp, 0))
                         else result:= ExtractDivider(getfieldbyname('SECBOARD', fldnums), getfieldbyname('SECCODE', fldnums));
  end else result:= ExtractDivider(getfieldbyname('SECBOARD', fldnums), getfieldbyname('SECCODE', fldnums));
end;

procedure tSecuritiesTable.beforeprocessfields;
begin
  FillChar(sec,sizeof(tSecurities),0);
  sec.stock_id:= micexId;
  secset:= [sec_stock_id];
end;

procedure tSecuritiesTable.processfield;
begin
  case uniindex of
    fldSECBOARD      : begin sec.level := format('%s',value);                                   include(secset, sec_level);            end;
    fldSECCODE       : begin sec.code := format('%s',value);                                    include(secset, sec_code);             end;
    fldSHORTNAME     : begin sec.shortname := format('%s',value);                               include(secset, sec_shortname);        end;
    fldBID           : begin sec.hibid := value[low(value)].vextended^;                         include(secset, sec_hibid);            end;
    fldOFFER         : begin sec.lowoffer := value[low(value)].vextended^;                      include(secset, sec_lowoffer);         end;
    fldOPEN          : begin sec.initprice := value[low(value)].vextended^;                     include(secset, sec_initprice);        end;
    fldHIGH          : begin sec.maxprice := value[low(value)].vextended^;                      include(secset, sec_maxprice);         end;
    fldLOW           : begin sec.minprice := value[low(value)].vextended^;                      include(secset, sec_minprice);         end;
    fldWAPRICE       : begin sec.meanprice := value[low(value)].vextended^;                     include(secset, sec_meanprice);        end;
    fldCHANGE        : begin sec.change := value[low(value)].vextended^;                        include(secset, sec_change);           end;
    fldVOLTODAY      : begin sec.amount := value[low(value)].vint64^;                           include(secset, sec_amount);           end;
    fldVALTODAY      : begin sec.value := value[low(value)].vint64^;                            include(secset, sec_value);            end;
    fldLOTSIZE       : begin sec.lotsize := value[low(value)].vint64^;                          include(secset, sec_lotsize);          end;
    fldLAST          : begin sec.lastdealprice := value[low(value)].vextended^;                 include(secset, sec_lastdealprice);    end;
    fldVALUE         : begin
//                         sec.lastdealsize := value[low(value)].vextended^;
                         with value[low(value)] do
                           if VType = vtCurrency then sec.lastdealsize := vcurrency^ else sec.lastdealsize := vextended^;
                         include(secset, sec_lastdealsize);
                       end;
    fldTIME          : begin sec.lastdealtime := value[low(value)].vextended^ + date;           include(secset, sec_lastdealtime);     end;
    fldYIELD         : begin sec.gko_yield := value[low(value)].vcurrency^;                     include(secset, sec_gko_yield);        end;
    fldMATDATE       : begin sec.gko_matdate := value[low(value)].vextended^;                   include(secset, sec_gko_matdate);      end;
    fldCOUPONVALUE   : begin sec.gko_cuponval := value[low(value)].vcurrency^;                  include(secset, sec_gko_cuponval);     end;
    fldNEXTCOUPON    : begin sec.gko_nextcupon := value[low(value)].vextended^;                 include(secset, sec_gko_nextcupon);    end;

//    fldCOUPONPERIOD  : begin sec.gko_cuponperiod := strtointdef(format('%s',value), 0);         include(secset, sec_gko_cuponperiod);  end;
    fldCOUPONPERIOD  : begin sec.gko_cuponperiod := value[low(value)].vint64^;                  include(secset, sec_gko_cuponperiod);  end;

    fldDECIMALS      : begin
                         sec.decimals  := value[low(value)].vint64^;            include(secset, sec_decimals);
                         sec.srv_field := inttostr(intpower(10, sec.decimals)); include(secset, sec_srv_field);
                       end;
    fldFACEVALUE     : begin sec.facevalue := value[low(value)].vint64^ / 100;                  include(secset, sec_facevalue);        end;
    fldBIDDEPTHT     : begin sec.biddepth := value[low(value)].vint64^;                         include(secset, sec_biddepth);         end;
    fldOFFERDEPTHT   : begin sec.offerdepth := value[low(value)].vint64^;                       include(secset, sec_offerdepth);       end;
    fldNUMBIDS       : begin sec.numbids := value[low(value)].vint64^;                          include(secset, sec_numbids);          end;
    fldNUMOFFERS     : begin sec.numoffers := value[low(value)].vint64^;                        include(secset, sec_numoffers);        end;
    fldTRADINGSTATUS : begin sec.tradingstatus := format('%s ',value)[1];                       include(secset, sec_tradingstatus);    end;
    fldCLOSEPRICE    : begin sec.closeprice := value[low(value)].vextended^;                    include(secset, sec_closeprice);       end;
    fldQTY           : begin sec.lastdealqty := value[low(value)].vint64^;                      include(secset, sec_lastdealqty);      end;
    fldACCRUEDINT    : begin sec.gko_accr := value[low(value)].vextended^;                      include(secset, sec_gko_accr);         end;
    fldPREVPRICE     : begin sec.prev_price:= value[low(value)].vextended^;                     include(secset, sec_prev_price);       end;
    fldISSUESIZE     : begin sec.gko_issuesize:= value[low(value)].vint64^;                     include(secset, sec_gko_issuesize);    end;
    fldBUYBACKPRICE  : begin sec.gko_buybackprice:= value[low(value)].vextended^;               include(secset, sec_gko_buybackprice); end;
    fldBUYBACKDATE   : begin sec.gko_buybackdate:= value[low(value)].vextended^;                include(secset, sec_gko_buybackdate);  end;
    fldMARKETPRICE   : begin sec.marketprice:= value[low(value)].vextended^;                    include(secset, sec_marketprice);      end;
  end;
end;

procedure tSecuritiesTable.afterprocessfields;
begin
  if (secset >= [sec_stock_id, sec_level, sec_code]) then begin
    registerboard(sec.level);
    Server_API.AddSecuritiesRec(sec, secset);
  end;
end;

function tSecuritiesTable.open;
begin
  if not opened then begin
    result:= inherited open;
    if opened then SecuritiesFlag:= true;
  end else result:= 0;
end;

{ tOrdersTable }

constructor tOrdersTable.create;
begin
  inherited create(aConnection, asection);
  TableName:= 'ORDERS';
  orderbuf:= tOrderRegistry.create;
end;

destructor tOrdersTable.destroy;
begin
  if assigned(orderbuf) then freeandnil(orderbuf);
  inherited destroy;
end;

procedure tOrdersTable.processfield;
begin
  case uniindex of
    fldORDERNO   : begin ord.orderno     := value[low(value)].vint64^;            include(ordset, ord_orderno);   end;
    fldORDERTIME : begin ord.ordertime   := value[low(value)].vextended^ + date;  include(ordset, ord_ordertime); end;
    fldSTATUS    : begin ord.status      := format('%s ',value)[1];               include(ordset, ord_status);    end;
    fldBUYSELL   : begin ord.buysell     := format('%s ',value)[1];               include(ordset, ord_buysell);   end;
    fldACCOUNT   : begin ord.account     := format('%s',value);                   include(ordset, ord_account);   end;
    fldSECBOARD  : begin ord.level       := format('%s',value);                   include(ordset, ord_level);     end;
    fldSECCODE   : begin ord.code        := format('%s',value);                   include(ordset, ord_code);      end;
    fldPRICE     : begin ord.price       := value[low(value)].vextended^;         include(ordset, ord_price);     end;
    fldQUANTITY  : begin ord.quantity    := value[low(value)].vint64^;            include(ordset, ord_quantity);  end;
    fldVALUE     : begin
                     //ord.value       := value[low(value)].vextended^;
                     with value[low(value)] do
                       if VType = vtCurrency then ord.value := vcurrency^ else ord.value := vextended^;
                     include(ordset, ord_value);
                   end;
    fldBALANCE   : begin ord.balance     := value[low(value)].vint64^;            include(ordset, ord_balance);   end;
    fldBROKERREF : begin
                     filtervalue  := format('%s', value);
                     filterisset  := true;
                     ord.clientid := copy(filtervalue, 7, 5);
                     include(ordset, ord_clientid);
                   end;
    fldEXTREF    :       ord.transaction := getInternalTrsID(format('%s',value));
  end;
end;

function tOrdersTable.open;
var heap     : pMTEMsg;
begin
  if not opened and SecuritiesFlag then begin
    getstructure;
    lock;
    try
      setrawdata(nil);
      try
        handle:= MTEOpenTable(linkhandle,pchar(tablename),'',openTableComplete,heap);
        if (handle >= MTE_OK) then setrawdata(heap);
      except on e:exception do micexlog('ORDOPEN: Exception: %s', [e.message]); end;
    finally unlock; end;
    if (handle >= MTE_OK) then begin
      if assigned(parser) and not parser.empty then parse;
      opened:= true;
    end;
    if assigned(orderbuf) then orderbuf.process;
    result:= handle;
  end else result:= 0;
end;

function tOrdersTable.update;
var heap     : pMTEMsg;
begin
  if (handle >= MTE_OK) then begin
    result:= -1;
    lock;
    try
      setrawdata(nil);
      try
        MTEAddTable(linkhandle,handle,0);
        result:= MTERefresh(linkhandle,heap);
        if (result >= MTE_OK) then setrawdata(heap);
      except on e:exception do micexlog('ORDUPD: Exception: %s', [e.message]); end;
    finally unlock; end;
    if (result >= MTE_OK) and assigned(parser) and not parser.empty then parse;
    if assigned(orderbuf) then orderbuf.process;
  end else result:=-1;
end;

procedure tOrdersTable.parse;
var i,j,flds,devider : longint;
    fldnums          : tfieldnums;
    ordercount       : longint;
    aadd             : boolean;
begin
  aadd:= false;
  if assigned(parser) and not parser.empty then with parser do begin
    if opened then skipbytes(4);      // скипуем кол-во таблиц. д.б. 1 (только при открытии)
    skipbytes(4);                     // поле ref
    ordercount:= getinteger;          // кол-во строк в таблице
    if (ordercount > 0) then try
      for i:=1 to ordercount do begin
        FillChar(ord,sizeof(tOrders),0); ord.stock_id:=micexId;
        flds:=byte(getchar);             // число полей в строке
        skipbytes(4);                    // длинна данных в строке
        if flds=0 then begin setlength(fldnums,count); for j:=0 to count-1 do fldnums[j]:=j; end
                  else begin setlength(fldnums,flds); for j:=0 to flds-1  do fldnums[j]:=byte(getchar); end;
        devider:=ExtractDivider(getfieldbyname('SECBOARD',fldnums),
                                getfieldbyname('SECCODE',fldnums));
        ordset:=[ord_stock_id];
        filterisset:= false;
        processfields(fldnums,devider);
        if checkfilter then begin
          ord.ordertype:= 'N'; ord.settlecode:='T0'; ordset:= ordset + [ord_ordertype, ord_settlecode];
          {$IFDEF LogOrdersUpdates}
          if opened then with ord do micexlog('Order: %s\%d\%s\%d', [clientid,orderno,status,balance]);
          {$ENDIF}
          {$ifdef UseSetOrderFlag}if not setorderflag and (orderbuf.count=0) then begin{$endif}
          if not aadd then try
            if assigned(Server_API.OrdersBeginUpdate) then Server_API.OrdersBeginUpdate(micexId, '');
          finally aadd:= true; end;
          Server_API.AddOrdersRec(ord, ordset);
          {$ifdef UseSetOrderFlag}end else orderbuf.add(ord, ordset);{$endif}
        end;
      end;
    finally if aadd and assigned(Server_API.OrdersEndUpdate) then Server_API.OrdersEndUpdate(micexId, ''); end;
  end;
end;

{ tRepoOrdersTable }

constructor tRepoOrdersTable.create;
begin
  inherited create(aConnection, asection);
  TableName:= 'NEGDEALS';
  orderbuf:= tOrderRegistry.create;
end;

destructor tRepoOrdersTable.destroy;
begin orderbuf.free; inherited destroy; end;

procedure tRepoOrdersTable.processfield;
begin
  case uniindex of
    fldSTATUS    : begin ord.status      := format('%s ',value)[1];               include(ordset, ord_status);    end;
    fldBUYSELL   : begin ord.buysell     := format('%s ',value)[1];               include(ordset, ord_buysell);   end;
    fldACCOUNT   : begin ord.account     := format('%s',value);                   include(ordset, ord_account);   end;
    fldSECBOARD  : begin ord.level       := format('%s',value);                   include(ordset, ord_level);     end;
    fldSECCODE   : begin ord.code        := format('%s',value);                   include(ordset, ord_code);      end;
    fldDEALNO    : begin ord.orderno     := value[low(value)].vint64^;            include(ordset, ord_orderno);   end;
    fldDEALTIME  : begin ord.ordertime   := value[low(value)].vextended^ + date;  include(ordset, ord_ordertime); end;
    fldPRICE     : begin ord.price       := value[low(value)].vextended^;         include(ordset, ord_price);     end;
    fldVALUE     : begin
                     //ord.value       := value[low(value)].vextended^;
                     with value[low(value)] do
                       if VType = vtCurrency then ord.value := vcurrency^ else ord.value := vextended^;
                     include(ordset, ord_value);
                   end;
    fldQUANTITY  : begin ord.quantity    := value[low(value)].vint64^;            include(ordset, ord_quantity);
                         ord.balance     := ord.quantity;                         include(ordset, ord_balance);   end;
    fldSETTLECODE: begin
                     ord.settlecode  := format('%s',value);
                     ord.ordertype   := SettleCodeToType(ord.settlecode, true);
                     ordset          := ordset + [ord_ordertype, ord_settlecode];
                   end;
    fldBROKERREF : begin
                     filtervalue  := format('%s', value);
                     filterisset  := true;
                     ord.clientid := copy(filtervalue, 7, 5);
                     include(ordset, ord_clientid);
                   end;
    fldEXTREF    :       ord.transaction := getInternalTrsID(format('%s',value));
  end;
end;

function tRepoOrdersTable.open;
var heap     : pMTEMsg;
begin
  if not opened and SecuritiesFlag then begin
    getstructure;
    lock;
    try
      setrawdata(nil);
      try
        handle:= MTEOpenTable(linkhandle,pchar(tablename),'',openTableComplete,heap);
        if (handle >= MTE_OK) then setrawdata(heap);
      except on e:exception do micexlog('REPOPEN: Exception: %s', [e.message]); end;
    finally unlock; end;
    if (handle >= MTE_OK) then begin
      if assigned(parser) and not parser.empty then parse;
      opened:= true;
    end;
    if assigned(orderbuf) then orderbuf.process;
    result:= handle;
  end else result:= 0;
end;

function tRepoOrdersTable.update;
var heap     : pMTEMsg;
begin
  if (handle >= MTE_OK) then begin
    result:= -1;
    lock;
    try
      setrawdata(nil);
      try
        MTEAddTable(linkhandle,handle,0);
        result:= MTERefresh(linkhandle,heap);
        if (result >= MTE_OK) then setrawdata(heap);
      except on e:exception do micexlog('REPUPD: Exception: %s', [e.message]); end;
    finally unlock; end;
    if (result >= MTE_OK) and assigned(parser) and not parser.empty then parse;
    if assigned(orderbuf) then orderbuf.process;
  end else result:= -1;
end;

procedure tRepoOrdersTable.parse;
var i,j,flds,devider : longint;
    fldnums          : tfieldnums;
    ordercount       : longint;
    aadd             : boolean;
begin
  aadd:= false;
  if assigned(parser) and not parser.empty then with parser do begin
    if opened then skipbytes(4);      // скипуем кол-во таблиц. д.б. 1 (только при открытии)
    skipbytes(4);                     // поле ref
    ordercount:= getinteger;          // кол-во строк в таблице
    if (ordercount > 0) then try
      for i:=1 to ordercount do begin
        FillChar(ord,sizeof(tOrders),0); ord.stock_id:=micexId;
        flds:=byte(getchar);             // число полей в строке
        skipbytes(4);                    // длинна данных в строке
        if flds=0 then begin setlength(fldnums,count); for j:=0 to count-1 do fldnums[j]:=j; ordset:=allordersfields; end
                  else begin setlength(fldnums,flds); for j:=0 to flds-1  do fldnums[j]:=byte(getchar); ordset:=[ord_stock_id]; end;
        devider:=ExtractDivider(getfieldbyname('SECBOARD',fldnums),
                                getfieldbyname('SECCODE',fldnums));
        filterisset:= false;
        processfields(fldnums,devider);
        if checkfilter then begin
          if (ord_status in ordset) and (upcase(ord.status)='M') then begin ord.balance:=0; include(ordset, ord_balance); end;
          {$IFDEF LogREPOOrdersUpdates}
          if opened then with ord do micexlog('RepoOrder: %s\%d\%s', [clientid,orderno,status]);
          {$ENDIF}
          {$ifdef UseSetOrderFlag}if not setorderflag and (orderbuf.count = 0) then begin{$endif}
          if not aadd then try
            if assigned(Server_API.OrdersBeginUpdate) then Server_API.OrdersBeginUpdate(micexId, '');
          finally aadd:= true; end;
          Server_API.AddOrdersRec(ord, ordset);
          {$ifdef UseSetOrderFlag}end else orderbuf.add(ord, ordset);{$endif}
        end;
      end;
    finally if aadd and assigned(Server_API.OrdersEndUpdate) then Server_API.OrdersEndUpdate(micexId, ''); end;
  end;
end;

{ tTradesTable }

constructor tTradesTable.create;
begin
  inherited create(aConnection, asection);
  TableName:= 'TRADES';
  tradebuf:= tTradeRegistry.create;
end;

destructor tTradesTable.destroy;
begin
  if assigned(tradebuf) then freeandnil(tradebuf);
  inherited destroy;
end;

procedure tTradesTable.processfield;
begin
  case uniindex of
    fldTRADENO    : begin trd.tradeno     := value[low(value)].vint64^;            include(trdset, trd_tradeno);   end;
    fldORDERNO    : begin trd.orderno     := value[low(value)].vint64^;            include(trdset, trd_orderno);   end;
    fldTRADETIME  : begin trd.tradetime   := value[low(value)].vextended^ + date;  include(trdset, trd_tradetime); end;
    fldBUYSELL    : begin trd.buysell     := format('%s ',value)[1];               include(trdset, trd_buysell);   end;
    fldACCOUNT    : begin trd.account     := format('%s',value);                   include(trdset, trd_account);   end;
    fldSECBOARD   : begin trd.level       := format('%s',value);                   include(trdset, trd_level);     end;
    fldSECCODE    : begin trd.code        := format('%s',value);                   include(trdset, trd_code);      end;
    fldPRICE      : begin trd.price       := value[low(value)].vextended^;         include(trdset, trd_price);     end;
    fldQUANTITY   : begin trd.quantity    := value[low(value)].vint64^;            include(trdset, trd_quantity);  end;
    fldVALUE      : begin
//                      trd.value       := value[low(value)].vextended^;
                     with value[low(value)] do
                       if VType = vtCurrency then trd.value := vcurrency^ else trd.value := vextended^;
                      include(trdset, trd_value);
                    end;
    fldACCRUEDINT : begin trd.accr        := value[low(value)].vextended^;         include(trdset, trd_accr);      end;
    fldSETTLECODE : begin
                      trd.settlecode  := format('%s',value);
                      include(trdset, trd_settlecode);
                      trd.tradetype   := SettleCodeToType(trd.settlecode, false);
                      if (trd.tradetype <> 'T') then include(trdset, trd_tradetype);
                    end;
    fldBROKERREF  : begin
                      filtervalue  := format('%s', value);
                      filterisset  := true;
                      trd.clientid := copy(filtervalue, 7, 5);
                      include(trdset, trd_clientid);
                    end;
    fldEXTREF     :       trd.transaction := getInternalTrsID(format('%s',value));
  end;
end;

function tTradesTable.open;
var heap     : pMTEMsg;
begin
  if not opened and SecuritiesFlag then begin
    getstructure;
    lock;
    try
      setrawdata(nil);
      try
        handle:= MTEOpenTable(linkhandle,pchar(tablename),'',openTableComplete,heap);
        if (handle >= MTE_OK) then setrawdata(heap);
      except on e:exception do micexlog('TRDOPEN: Exception: %s', [e.message]); end;
    finally unlock; end;
    if (handle >= MTE_OK) then begin
      if assigned(parser) and not parser.empty then parse;
      opened:= true;
    end;
    if assigned(tradebuf) then tradebuf.process;
    result:= handle;
  end else result:= 0;
end;

function tTradesTable.update;
var heap     : pMTEMsg;
begin
  if (handle >= MTE_OK) then begin
    result:= -1;
    lock;
    try
      setrawdata(nil);
      try
        MTEAddTable(linkhandle,handle,0);
        result:= MTERefresh(linkhandle,heap);
        if (result >= MTE_OK) then setrawdata(heap);
      except on e:exception do micexlog('TRDUPD: Exception: %s', [e.message]); end;
    finally unlock; end;
    if (result >= MTE_OK) and assigned(parser) and not parser.empty then parse;
    if assigned(tradebuf) then tradebuf.process;
  end else result:= -1;
end;

procedure tTradesTable.parse;
var  i,j,flds,devider : longint;
     fldnums          : tfieldnums;
     scode            : tSettleCode;
     tradecount       : longint;
     aadd             : boolean;
begin
  aadd:= false;
  if assigned(parser) and not parser.empty then with parser do begin
    if opened then skipbytes(4);      // скипуем кол-во таблиц. д.б. 1 (только при открытии)
    skipbytes(4);                     // поле ref
    tradecount:= getinteger;          // кол-во строк в таблице
    if (tradecount > 0) then try
      for i:=1 to tradecount do begin
        FillChar(trd,sizeof(tTrades),0); trd.stock_id:=micexId;
        flds:=byte(getchar);             // число полей в строке
        skipbytes(4);                    // длинна данных в строке
        if flds=0 then begin setlength(fldnums,count); for j:=0 to count-1 do fldnums[j]:=j; end
                  else begin setlength(fldnums,flds); for j:=0 to flds-1 do fldnums[j]:=byte(getchar); end;
        devider:=ExtractDivider(getfieldbyname('SECBOARD', fldnums),
                                getfieldbyname('SECCODE', fldnums));
        scode:=getfieldbyname('SETTLECODE', fldnums);
        trdset:=[trd_stock_id];
        filterisset:= false;
        processfields(fldnums,devider);
        if checkfilter and checksettlecode(scode) then begin
          {$IFDEF LogTradesUpdates}
          if opened then with trd do micexlog('Trade: %s\%d\%d\%s', [clientid,tradeno,orderno,account]);
          {$ENDIF}
          {$ifdef UseSetOrderFlag}if not setorderflag and (tradebuf.count = 0) then begin{$endif}
          if not aadd then try
            if assigned(Server_API.TradesBeginUpdate) then Server_API.TradesBeginUpdate(micexId, '');
          finally aadd:= true; end;
          Server_API.AddTradesRec(trd, trdset);
          {$ifdef UseSetOrderFlag}end else tradebuf.add(trd, trdset);{$endif}
        end;
      end;
    finally if aadd and assigned(Server_API.TradesEndUpdate) then Server_API.TradesEndUpdate(micexId, ''); end;
  end;
end;

{ tRepoTradesTable }

constructor tRepoTradesTable.create;
begin
  inherited create(aConnection, asection);
  TableName:= 'USTRADES';
  tradebuf:= tTradeRegistry.create;
end;

destructor tRepoTradesTable.destroy;
begin tradebuf.free; inherited destroy; end;

procedure tRepoTradesTable.processfield;
begin
  case uniindex of
    fldTRADENO    : begin trd.tradeno     := value[low(value)].vint64^;                  include(trdset, trd_tradeno);   end;
//    fldORDERNO    : begin trd.orderno     := value[low(value)].vint64^;                  include(trdset, trd_orderno);   end;
    fldTRADEDATE  : begin trd.tradetime   := value[low(value)].vextended^;               include(trdset, trd_tradetime); end;
    fldBUYSELL    : begin trd.buysell     := format('%s ',value)[1];                     include(trdset, trd_buysell);   end;
//    fldTRDACCID   : begin trd.account     := format('%s',value);                         include(trdset, trd_account);   end;
    fldSECBOARD   : begin trd.level       := format('%s',value);                         include(trdset, trd_level);     end;
    fldSECCODE    : begin trd.code        := format('%s',value);                         include(trdset, trd_code);      end;
    fldPRICE      : begin trd.price       := value[low(value)].vextended^;               include(trdset, trd_price);     end;
    fldQUANTITY   : begin trd.quantity    := value[low(value)].vint64^;                  include(trdset, trd_quantity);  end;
    fldVALUE      : begin
                      //trd.value       := value[low(value)].vextended^;
                     with value[low(value)] do
                       if VType = vtCurrency then trd.value := vcurrency^ else trd.value := vextended^;
                      include(trdset, trd_value);
                    end;
    fldACCRUEDINT : begin trd.accr        := value[low(value)].vextended^;               include(trdset, trd_accr);      end;
    fldSETTLECODE : begin
                      trd.settlecode  := format('%s',value);
                      trd.tradetype   := SettleCodeToType(trd.settlecode, true);
                      trdset          :=  trdset + [trd_tradetype, trd_settlecode];
                    end;
    fldBROKERREF  : begin
                      filtervalue  := format('%s',value);
                      filterisset  := true;
                      trd.account  := format('%s000%s', [copy(filtervalue, 7, 5), copy(filtervalue, 13, length(filtervalue))]);
                      trd.clientid := trd.account;
                      trdset       := trdset + [trd_clientid, trd_account];
                    end;
//    fldEXTREF     :       trd.transaction := getInternalTrsID(format('%s',value));
  end;
end;

function tRepoTradesTable.open;
var heap     : pMTEMsg;
begin
  if not opened and SecuritiesFlag then begin
    getstructure;
    lock;
    try
      setrawdata(nil);
      try
        handle:= MTEOpenTable(linkhandle,pchar(tablename),'',openTableComplete,heap);
        if (handle >= MTE_OK) then setrawdata(heap);
      except on e:exception do micexlog('REPOTRDOPEN: Exception: %s', [e.message]); end;
    finally unlock; end;
    if (handle >= MTE_OK) then begin
      if assigned(parser) and not parser.empty then parse;
      opened:= true;
    end;
    if assigned(tradebuf) then tradebuf.process;
    result:= handle;
  end else result:= 0;
end;

function tRepoTradesTable.update;
var heap     : pMTEMsg;
begin
  if (handle >= MTE_OK) then begin
    result:=-1;
    lock;
    try
      setrawdata(nil);
      try
        MTEAddTable(linkhandle,handle,0);
        result:= MTERefresh(linkhandle,heap);
        if (result >= MTE_OK) then setrawdata(heap);
      except on e:exception do micexlog('REPOTRDUPD: Exception: %s', [e.message]); end;
    finally unlock; end;
    if (result >= MTE_OK) and assigned(parser) and not parser.empty then parse;
    tradebuf.process;
  end else result:=-1;
end;

procedure tRepoTradesTable.parse;
var i,j,flds,devider : longint;
    fldnums          : tfieldnums;
    status           : string[1];
    tradecount       : longint;
    aadd             : boolean;
begin
  aadd:= false;
  if assigned(parser) and not parser.empty then with parser do begin
    if opened then skipbytes(4);      // скипуем кол-во таблиц. д.б. 1 (только при открытии)
    skipbytes(4);                     // поле ref
    tradecount:= getinteger;          // кол-во строк в таблице
    if (tradecount > 0) then try
      for i:=1 to tradecount do begin
        FillChar(trd,sizeof(tTrades),0); trd.stock_id:=micexId;
        flds:=byte(getchar);             // число полей в строке
        skipbytes(4);                    // длинна данных в строке
        if flds=0 then begin setlength(fldnums,count); for j:=0 to count-1 do fldnums[j]:=j; end
                  else begin setlength(fldnums,flds); for j:=0 to flds-1  do fldnums[j]:=byte(getchar); end;
        devider:=ExtractDivider(getfieldbyname('SECBOARD', fldnums),
                                getfieldbyname('SECCODE', fldnums));
        status:= getfieldbyname('STATUS', fldnums);
        trdset:=[trd_stock_id];
        filterisset:= false;
        processfields(fldnums,devider);
        if checkfilter and (status = 'M') then begin
          with trd do begin
            transaction := 0;  // транзакции нет, заявка "порождается" торговой площадкой
            orderno     := 0;  // заявки тоже нет
          end;
          if opened then with trd do micexlog('REPOTrade: %s\%d\%d\%s', [clientid,tradeno,orderno,account]);
          {$ifdef UseSetOrderFlag}if not setorderflag and (tradebuf.count = 0) then begin{$endif}
            if not aadd then try
              if assigned(Server_API.TradesBeginUpdate) then Server_API.TradesBeginUpdate(micexId, '');
            finally aadd:= true; end;
            Server_API.AddTradesRec(trd, trdset);
          {$ifdef UseSetOrderFlag}end else tradebuf.add(trd, trdset);{$endif}
        end;
      end;
    finally if aadd and assigned(Server_API.TradesEndUpdate) then Server_API.TradesEndUpdate(micexId, ''); end;
  end;
end;

{ tKotirovkiTable }

constructor tKotirovkiTable.create;
begin
  inherited create(aConnection, asection);
  TableName:= orderbooktable;
  if (comparetext(TableName, 'ORDERBOOK') = 0)     then TableParams:= '                ' else
  if (comparetext(TableName, 'EXT_ORDERBOOK') = 0) then TableParams:= '                  ';
  deleteditems:= tStringList.create;
  deleteditems.sorted:= True;
end;

destructor tKotirovkiTable.destroy;
begin
  if assigned(deleteditems) then freeandnil(deleteditems);
  inherited destroy;
end;

function tKotirovkiTable.canopen: boolean;
begin result:= SecuritiesFlag; end;

function tKotirovkiTable.getdivider: cardinal;
begin result:= ExtractDivider(getfieldbyname('SECBOARD', fldnums), getfieldbyname('SECCODE', fldnums)); end;

procedure tKotirovkiTable.beforeparse(arecordcount: longint);
begin
  if assigned(deleteditems) then deleteditems.clear;
  Server_API.LockKotirovki;
end;

procedure tKotirovkiTable.beforeprocessfields;
var lvl, cod : string;
    delitm   : string;
    tmpkot   : tKotirovki;
    idx      : longint;
begin
  FillChar(kot, sizeof(tKotirovki), 0); kot.stock_id:= micexId;
  if assigned(deleteditems) then begin
    lvl:= getfieldbyname('SECBOARD', fldnums);
    cod:= getfieldbyname('SECCODE', fldnums);
    delitm:= format('%s/%s', [lvl, cod]);
    if not deleteditems.find(delitm, idx) then try
      fillchar(tmpkot, sizeof(tKotirovki), 0);
      with tmpkot do begin stock_id:= micexId; level:= lvl; code:= cod; end;
      Server_API.ClearKotirovkiTbl(tmpkot, clrByStruct);
    finally deleteditems.add(delitm); end;
  end;
end;

procedure tKotirovkiTable.processfield;
begin
  case uniindex of
    fldSECBOARD : kot.level := format('%s',value);
    fldSECCODE  : kot.code := format('%s',value);
    fldBUYSELL  : kot.buysell := format('%s ',value)[1];
    fldPRICE    : kot.price := value[low(value)].vextended^;
    fldQUANTITY : kot.quantity := value[low(value)].vint64^;
    fldYIELD    : kot.gko_yield := value[low(value)].vcurrency^;
  end;
end;

procedure tKotirovkiTable.afterprocessfields;
begin Server_API.AddKotirovkiRec(kot);
end;

procedure tKotirovkiTable.afterparse;
begin Server_API.UnlockKotirovki; end;

{ tAllTradesTable}

constructor tAllTradesTable.create;
begin
  inherited create(aConnection, asection);
  TableName:= 'ALL_TRADES';
  updatecounter:= 0;
end;

procedure tAllTradesTable.beforeprocessfields;
begin FillChar(atd, sizeof(tAllTrades), 0); atd.stock_id:= micexId; end;

procedure tAllTradesTable.processfield;
begin
  case uniindex of
    fldTRADENO   : atd.tradeno := value[low(value)].vint64^;
    fldTRADETIME : atd.tradetime := value[low(value)].vextended^ + date;
    fldSECBOARD  : atd.level := format('%s',value);
    fldSECCODE   : atd.code := format('%s',value);
    fldPRICE     : atd.price := value[low(value)].vextended^;
    fldQUANTITY  : atd.quantity := value[low(value)].vint64^;
    fldVALUE     : with value[low(value)] do
                     if VType = vtCurrency then atd.value := vcurrency^ else atd.value := vextended^;
    fldBUYSELL   : atd.buysell:= format('%s ',value)[1];
    fldREPORATE  : atd.reporate := value[low(value)].vextended^;
    fldREPOTERM  : atd.repoterm := value[low(value)].vint64^;
  end;
end;

procedure tAllTradesTable.afterprocessfields;
begin
  SetAlltradesStats(atd);
  Server_API.AddAllTradesRec(atd);
end;

function tAllTradesTable.getdivider: cardinal;
begin result:= ExtractDivider(getfieldbyname('SECBOARD', fldnums), getfieldbyname('SECCODE', fldnums)); end;

function tAllTradesTable.canopen: boolean;
begin result:= SecuritiesFlag; end;

function tAllTradesTable.update;
begin
  {$IFDEF AllTradesLowPriority}
  inc(updatecounter); updatecounter:=updatecounter and 1;
  if (updatecounter = 0) then begin
  {$ENDIF}
  result:= inherited update;
  {$IFDEF AllTradesLowPriority}
  end else result:=0;
  {$ENDIF}
end;

{ tMessagesTable }

constructor tMessagesTable.create;
begin
  inherited create(aConnection, asection);
  TableName:= 'BCMESSAGES';
  updatecounter:= 0;
end;

procedure tMessagesTable.beforeprocessfields;
begin
  setlength(msgtext, 0); setlength(fromuser, 0); msgtime:= now;
end;

procedure tMessagesTable.processfield;
  function extracttime(const mt: string): tDateTime;
  var h, m, s : longint;
  begin
    if (length(mt) = 8) then begin
      h:= strtointdef(copy(mt, 1, 2), 0);
      m:= strtointdef(copy(mt, 4, 2), 0);
      s:= strtointdef(copy(mt, 7, 2), 0);
      result:= encodetime(h, m, s, 0);
    end else result:= 0;
  end;
begin
  case uniindex of
    fldFROMUSER  : fromuser:= format('%s', value);
    fldMSGTIME   : msgtime:= extracttime(format('%s', value)) + date;
    fldMSGTEXT   : msgtext:= format('%s', value);
  end;
end;

procedure tMessagesTable.afterprocessfields;
var amsg: string;
begin
  if (length(msgtext) > 0) then try
    amsg:= format('MICEX: %s from: %s %s',
                  [formatdatetime('DD-MM-YYY HH:NN:SS', msgtime), fromuser, msgtext]);
    server_api.SendBroadcastMessage(0, pChar(amsg));
  except on e: exception do micexlog('MESSAGESEND: Exception: %s', [e.message]); end;
end;

function tMessagesTable.update;
begin
  {$IFDEF MessagesLowPriority}
  inc(updatecounter); updatecounter:= updatecounter and 7; 
  if (updatecounter = 0) then begin
  {$ENDIF}
  result:= inherited update;
  {$IFDEF MessagesLowPriority}
  end else result:= 0;
  {$ENDIF}
end;

{ tIndexesTable }

constructor tIndexesTable.create(aConnection: tConnectionThread; asection: pRTLCriticalSection);
begin
  inherited create(aConnection, asection);
  TableName:= 'INDEXES';
end;

function tIndexesTable.getdivider: cardinal;
var tmp : string;
begin
  if not opened then begin
    tmp:= getfieldbyname('DECIMALS', fldnums);
    if (length(tmp) > 0) then result:= intpower(10, strtointdef(tmp, 0))
                         else result:= ExtractDivider(getfieldbyname('INDEXBOARD', fldnums), getfieldbyname('INDEXCODE', fldnums));
  end else result:= ExtractDivider(getfieldbyname('INDEXBOARD', fldnums), getfieldbyname('INDEXCODE', fldnums));
end;


procedure tIndexesTable.beforeprocessfields;
begin
  FillChar(sec,sizeof(tSecurities),0);
  sec.stock_id      := micexId;
  sec.tradingstatus := #$4E;
  secset:= [sec_stock_id, sec_tradingstatus];
end;

procedure tIndexesTable.processfield(uniindex: Integer; const value: array of const);
begin
  case uniindex of
    fldINDEXBOARD   : begin sec.level := format('%s',value);                                   include(secset, sec_level);         end;
    fldINDEXCODE    : begin sec.code := format('%s',value);                                    include(secset, sec_code);          end;
    fldSHORTNAME    : begin sec.shortname := format('%s',value);                               include(secset, sec_shortname);     end;
    fldCURRENTVALUE : begin sec.hibid := value[low(value)].vextended^;                         include(secset, sec_hibid);
                            sec.lowoffer := value[low(value)].vextended^;                      include(secset, sec_lowoffer);
                            sec.lastdealprice := value[low(value)].vextended^;                 include(secset, sec_lastdealprice); end;
    fldLASTVALUE    : begin sec.closeprice := value[low(value)].vextended^;                    include(secset, sec_closeprice);    end;
    fldTIME         : begin sec.lastdealtime := value[low(value)].vextended^ + date;           include(secset, sec_lastdealtime);  end;
    fldOPENVALUE    : begin sec.initprice := value[low(value)].vextended^;                     include(secset, sec_initprice);     end;
    fldDECIMALS     : begin
                        sec.decimals  := value[low(value)].vint64^;            include(secset, sec_decimals);
                        sec.srv_field := inttostr(intpower(10, sec.decimals)); include(secset, sec_srv_field);
                      end;
  end;
end;

procedure tIndexesTable.afterprocessfields;
begin
  if (secset >= [sec_stock_id,sec_level,sec_code]) then begin
    registerboard(sec.level);
    Server_API.AddSecuritiesRec(sec, secset);
  end;
end;

{ tFilteredTable }

function tFilteredTable.checkfilter: boolean;
begin
  if assigned(brokerrefs) then result:= not filterisset or brokerrefs.exists(filtervalue)
                          else result:= true;
end;

initialization
  register_class([tSystemTimeTable, tSettleCodesTable, tFirmsTable, tSecuritiesTable, tKotirovkiTable, tAllTradesTable,
                  tOrdersTable, tRepoOrdersTable, tTradesTable, tRepoTradesTable, tMessagesTable, tIndexesTable]);

end.
