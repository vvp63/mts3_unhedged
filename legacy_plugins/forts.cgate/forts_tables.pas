unit forts_tables;

interface

uses  {$ifdef MSWINDOWS}
        windows, 
      {$endif}
      classes, sysutils, math, inifiles, masks,
      classregistration, sortedlist,
      cgate, gateobjects, gateutils,
      servertypes, serverapi,
      forts_types, forts_common, forts_streams, forts_directory;

type  tFortsSessionContents = class(tFortsTable)
        sec                 : tSecurities;
        secset              : tSecuritiesSet;
        constructor create(AOwner: tFORTSDataStream; const ATableName: ansistring); override;
        function    OnStreamData(adata: pAnsiChar): longint; override;
      end;

type  tFortsDictionaryTable     = class(tFortsTable)
        local_isins         : tLocalIsinList;
        constructor create(AOwner: tFORTSDataStream; const ATableName: ansistring); override;
        destructor  destroy; override;
        procedure   LinkScheme(fields: pcg_field_desc); override;
      end;

type  tFortsCommonTable     = class(tFortsDictionaryTable)
        sec                 : tSecurities;
        constructor create(AOwner: tFORTSDataStream; const ATableName: ansistring); override;
        function    OnStreamData(adata: pAnsiChar): longint; override;
      end;

type  tFortsLockableTable   = class(tFortsDictionaryTable)
      private
        FLocked             : boolean;
      protected
        procedure   LockChange(alock: boolean); virtual;
      public
        constructor create(AOwner: tFORTSDataStream; const ATableName: ansistring); override;
        procedure   LockTable;
        procedure   UnlockTable;
      end;

type  tEnumMethod           = function(item: porders_aggr; adata: pointer): boolean of object;

      tSortedOrderBook      = class(tSortedList)
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;

        procedure   del(item: pointer);
      end;

      pOrderbooksItem       = ^tOrderbooksItem;
      tOrderbooksItem       = record
        isin_id             : longint;
        orderbook           : tSortedOrderBook;
      end;

      tOrderBooks           = class(tSortedList)
      private
        function    fGetOrderBook(aisin_id: longint): tSortedOrderBook;
      public
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;

        property    orderbooks[aisin_id: longint]: tSortedOrderBook read fGetOrderBook;
      end;

      tOrderBookHolder      = class(tSortedList)
      private
        FOrderBooks         : tOrderBooks;
      public
        constructor create;
        destructor  destroy; override;

        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        procedure   clear; override;

        procedure   FilterByRev(const arev: int64);

        function    SearchAddItem(item: porders_aggr): porders_aggr;
        function    EnumOrderbookItems(aisin_id: longint; afunc: tEnumMethod; adata: pointer): boolean;
        function    EnumAllItems(afunc: tEnumMethod; adata: pointer): boolean;
      end;

      tFortsOrderBookTable  = class(tFortsLockableTable)
      private
        FLastIsin           : pIsinListItem;
        FLastKotir          : tKotirovki;
        FTable              : tOrderBookHolder;
        FFilter             : tStringList;
      protected
        procedure   LockChange(alock: boolean); override;
      public
        constructor create(AOwner: tFORTSDataStream; const ATableName: ansistring); override;
        destructor  destroy; override;
        procedure   doLoad(AIni: TIniFile); override;
        procedure   LinkScheme(fields: pcg_field_desc); override;
        procedure   TransactionBegin; override;
        procedure   TransactionCommit; override;
        function    OnOrderbookEnumRow(item: porders_aggr; adata: pointer): boolean;
        procedure   OnIsinChange(aold, anew: pIsinListItem);
        function    OnStreamData(adata: pAnsiChar): longint; override;
        function    OnEnumRow(item: porders_aggr; adata: pointer): boolean;
        function    OnClearDeleted(const arev: int64): longint; override;
      end;

type  tFortsAllTradesTable  = class(tFortsLockableTable)
      protected
        procedure   LockChange(alock: boolean); override;
      public
        alltrd              : tAllTrades;
        constructor create(AOwner: tFORTSDataStream; const ATableName: ansistring); override;
        procedure   TransactionCommit; override;
        function    OnStreamData(adata: pAnsiChar): longint; override;
      end;

type  tFortsTradesTable     = class(tFortsLockableTable)
      protected
        procedure   LockChange(alock: boolean); override;
      public
        trd                 : tTrades;
        constructor create(AOwner: tFORTSDataStream; const ATableName: ansistring); override;
        procedure   TransactionCommit; override;
        function    OnStreamData(adata: pAnsiChar): longint; override;
      end;

type  tChangesList          = class(tSortedList)
        constructor create;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
      end;

      tOrdersList           = class(tSortedList)
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        function    addrecord(var aorder: tOrders): pOrders; virtual;
      end;

      tFortsOrdersTable     = class(tFortsLockableTable)
      private
        FTable              : tOrdersList;
        FChanges            : tChangesList;
      protected
        procedure   LockChange(alock: boolean); override;
      public
        ord                 : tOrders;
        trd                 : tTrades;
        constructor create(AOwner: tFORTSDataStream; const ATableName: ansistring); override;
        destructor  destroy; override;
        procedure   TransactionCommit; override;
        function    OnStreamData(adata: pAnsiChar): longint; override;
      end;

type  tUSDTable             = class(tFortsTable)
        sec                 : tSecurities;
        constructor create(AOwner: tFORTSDataStream; const ATableName: ansistring); override;
        function    OnStreamData(adata: pAnsiChar): longint; override;
      end;

type  tIndexTable           = class(tFortsTable)
        sec                 : tSecurities;
        constructor create(AOwner: tFORTSDataStream; const ATableName: ansistring); override;
        function    OnStreamData(adata: pAnsiChar): longint; override;
      end;

implementation

function  cmpdouble(const a, b: double): longint;
var r : double;
begin
  r:= a - b;
  if r < 0 then result:= -1 else
  if r > 0 then result:= 1  else result:= 0;
end;

function  cmpi64(a, b: int64): longint;
begin
 a:= a - b;
 if a < 0 then result:= -1 else
 if a > 0 then result:= 1  else result:= 0;
end;


function state_to_tradingstatus(astate: longint): ansichar;
const tsc : array[0..5] of ansichar = (#$4E, #$54, #$42, #$4E, #$4E, #$42);
begin if (astate >= low(tsc)) and (astate <= high(tsc)) then result:= tsc[astate] else result:= #$20; end;

{ tFortsSessionContents }

constructor tFortsSessionContents.Create(AOwner: tFORTSDataStream; const ATableName: ansistring);
begin
  inherited Create(AOwner, 'fut_sess_contents');
  fillchar(sec, sizeof(sec), 0);
end;

function tFortsSessionContents.OnStreamData(adata: pAnsiChar): longint;
var itm : pIsinListItem;
    ls  : longint;
begin
  with pfut_sess_contents(adata)^ do
    if (replAct = 0) then begin
      secset:= [];

      sec.stock_id         := GetFortsStockID;
      sec.shortname        := short_isin;
      sec.level            := level_futures;
      sec.code             := isin;

      sec.lotsize          := max(1, lot_volume);
      if fortssign(signs, flag_Spot) then ls:= 1 else ls:= max(1, lot_volume);

      sec.tradingstatus    := state_to_tradingstatus(state);
      sec.closeprice       := cg_utils_get_bcd(old_kotir) / ls;
      sec.prev_price       := cg_utils_get_bcd(old_kotir) / ls;
      sec.fut_deposit      := cg_utils_get_bcd(buy_deposit);

//      if (is_limited <> 0) then begin
      sec.limitpricehigh   := (cg_utils_get_bcd(last_cl_quote) + cg_utils_get_bcd(limit_up)) / ls;
      sec.limitpricelow    := (cg_utils_get_bcd(last_cl_quote) - cg_utils_get_bcd(limit_down)) / ls;
      secset := secset + [sec_limitpricehigh, sec_limitpricelow];
//      end;

      sec.decimals         := roundto + trunc(log10(max(1, lot_volume)));
      sec.pricestep        := cg_utils_get_bcd(min_step) / ls;
      sec.stepprice        := cg_utils_get_bcd(step_price) / ls;

      secset := secset + [sec_stock_id, sec_shortname, sec_level, sec_code, sec_lotsize, sec_tradingstatus, sec_closeprice,
                          sec_prev_price, sec_fut_deposit, sec_decimals, sec_pricestep, sec_stepprice];

      if assigned(isin_list) then begin
        isin_list.locklist;
        try
          itm:= isin_list.SearchAddItem(isin_id);
          if assigned(itm) then begin
            itm^.lsz        := sec.lotsize;
//            itm^.is_limited := (is_limited <> 0);
            itm^.signs      := signs;
            itm^.level      := sec.level;
            itm^.code       := sec.code;
          end;
        finally isin_list.unlocklist; end;
      end;

      Server_API.AddSecuritiesRec(sec, secset);
    end;

  result:= CG_ERR_OK;
end;

{ tFortsDictionaryTable }

constructor tFortsDictionaryTable.create(AOwner: tFORTSDataStream; const ATableName: ansistring);
begin
  inherited Create(AOwner, ATableName);
  local_isins:= nil;
end;

destructor tFortsDictionaryTable.destroy;
begin
  if assigned(local_isins) then freeandnil(local_isins);
  inherited destroy;
end;

procedure tFortsDictionaryTable.LinkScheme(fields: pcg_field_desc);
begin
  if not assigned(local_isins) then local_isins:= tLocalIsinList.create;
  if assigned(local_isins) then local_isins.load(isin_list);
end;

{ tFortsCommonTable }

constructor tFortsCommonTable.Create(AOwner: tFORTSDataStream; const ATableName: ansistring);
begin
  inherited Create(AOwner, 'common');
  fillchar(sec, sizeof(sec), 0);
end;

function tFortsCommonTable.OnStreamData(adata: pAnsiChar): longint;
var itm : pIsinListItem;
    ls  : longint;
begin
  with pcommon(adata)^ do
    if (replAct = 0) then begin

      if assigned(local_isins) then itm:= local_isins.isin[isin_id] else itm:= nil;
      if assigned(itm) then with itm^ do begin
        if fortssign(signs, flag_Spot) then ls:= 1 else ls:= lsz;

        sec.stock_id          := GetFortsStockID;
        sec.level             := level_futures;
        sec.code              := code;

        sec.hibid             := cg_utils_get_bcd(best_buy) / ls;
        sec.lowoffer          := cg_utils_get_bcd(best_sell) / ls;
        sec.maxprice          := cg_utils_get_bcd(max_price) / ls;
        sec.minprice          := cg_utils_get_bcd(min_price) / ls;
        sec.meanprice         := cg_utils_get_bcd(avr_price) / ls;
        sec.meantype          := 1;

        sec.lastdealtime      := cg_utils_get_time(deal_time);
        sec.lastdealprice     := cg_utils_get_bcd(price) / ls;
        sec.lastdealqty       := xamount;
        sec.lastdealsize      := (sec.lastdealprice * lsz) * sec.lastdealqty;
        sec.amount            := xcontr_count;
        sec.value             := trunc(cg_utils_get_bcd(capital));
        sec.fut_openedpos     := xpos;

        Server_API.AddSecuritiesRec(sec, [sec_stock_id, sec_level, sec_hibid, sec_lowoffer, sec_lastdealtime, sec_lastdealprice,
                                          sec_lastdealsize, sec_lastdealqty, sec_minprice, sec_maxprice, sec_meanprice, sec_amount,
                                          sec_value, sec_fut_openedpos, sec_meantype]);
      end;
    end;
  result:= CG_ERR_OK;
end;

{ tFortsLockableTable }

constructor tFortsLockableTable.create(AOwner: tFORTSDataStream; const ATableName: ansistring);
begin
  inherited Create(AOwner, ATableName);
  FLocked:= false;
end;

procedure tFortsLockableTable.LockChange(alock: boolean);
begin end;

procedure tFortsLockableTable.LockTable;
begin if not FLocked then begin FLocked:= true; LockChange(true); end; end;

procedure tFortsLockableTable.UnlockTable;
begin if FLocked then begin LockChange(false); FLocked:= false; end; end;

{ tSortedOrderBook }

procedure tSortedOrderBook.freeitem(item: pointer);
begin end;

function tSortedOrderBook.checkitem(item: pointer): boolean;
begin
  result:= assigned(item);
  if result then result:= (porders_aggr(item)^.volume > 0);
end;

function tSortedOrderBook.compare(item1, item2: pointer): longint;
begin
  result:= porders_aggr(item1)^.isin_id - porders_aggr(item2)^.isin_id;
  if (result = 0) then result:= cmpdouble(cg_utils_get_bcd(porders_aggr(item1)^.price), cg_utils_get_bcd(porders_aggr(item2)^.price));
end;

procedure tSortedOrderBook.del(item: pointer);
var idx : longint;
begin if assigned(item) and search(item, idx) then delete(idx); end;

{ tOrderBooks }

procedure tOrderBooks.freeitem(item: pointer);
begin
  if assigned(item) then begin
    with pOrderbooksItem(item)^ do
      if assigned(orderbook) then freeandnil(orderbook);
    dispose(pOrderbooksItem(item));
  end;
end;

function tOrderBooks.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tOrderBooks.compare(item1, item2: pointer): longint;
begin result:= pOrderbooksItem(item1)^.isin_id - pOrderbooksItem(item2)^.isin_id; end;

function tOrderBooks.fGetOrderBook(aisin_id: longint): tSortedOrderBook;
var sitm : tOrderbooksItem;
    idx  : longint;
    itm  : pOrderbooksItem;
begin
  sitm.isin_id:= aisin_id;
  if not search(@sitm, idx) then begin
    itm:= new(pOrderbooksItem);
    itm^.isin_id:= aisin_id;
    itm^.orderbook:= tSortedOrderBook.create;
    insert(idx, itm);
  end else itm:= pOrderbooksItem(items[idx]);
  if assigned(itm) then result:= itm^.orderbook else result:= nil;
end;

{ tOrderBookHolder }

constructor tOrderBookHolder.create;
begin
  inherited create;
  FOrderBooks:= tOrderBooks.create;
end;

destructor tOrderBookHolder.destroy;
begin
  if assigned(FOrderBooks) then freeandnil(FOrderBooks);
  inherited destroy;
end;

procedure tOrderBookHolder.freeitem(item: pointer);
begin if assigned(item) then dispose(porders_aggr(item)); end;

function tOrderBookHolder.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tOrderBookHolder.compare(item1, item2: pointer): longint;
begin
  result:= porders_aggr(item1)^.isin_id - porders_aggr(item2)^.isin_id;
  if (result = 0) then result:= cmpi64(porders_aggr(item1)^.replID, porders_aggr(item2)^.replID);
end;

procedure tOrderBookHolder.clear;
begin
  if assigned(FOrderBooks) then FOrderBooks.clear;
  inherited clear;
end;

procedure tOrderBookHolder.FilterByRev(const arev: int64);
var itm : porders_aggr;
    i   : longint;
begin
  for i:= count - 1 downto 0 do begin
    itm:= porders_aggr(items[i]);
    if assigned(itm) then begin
      if (itm^.replRev < arev) then begin
        if assigned(FOrderBooks) then FOrderBooks.orderbooks[itm^.isin_id].remove(itm);
        delete(i);
      end;
    end else delete(i);
  end;
end;

function tOrderBookHolder.SearchAddItem(item: porders_aggr): porders_aggr;
var idx: longint;
    itm: porders_aggr;
begin
  if assigned(item) and assigned(FOrderBooks) then begin
    if search(item, idx) then begin
      itm  := porders_aggr(items[idx]);
      FOrderBooks.orderbooks[itm^.isin_id].remove(itm);
      itm^ := item^;
      FOrderBooks.orderbooks[itm^.isin_id].add(itm);
    end else begin
      itm  := new(porders_aggr);
      itm^ := item^;
      FOrderBooks.orderbooks[itm^.isin_id].add(itm);
      insert(idx, itm);
    end;
    result:= itm;
  end else result:= nil;
end;

function tOrderBookHolder.EnumOrderbookItems(aisin_id: longint; afunc: tEnumMethod; adata: pointer): boolean;
var orderbook : tSortedOrderBook;
    i         : longint;
begin
  result:= true;
  if assigned(FOrderBooks) and assigned(afunc) then begin
    try
      orderbook:= FOrderBooks.orderbooks[aisin_id];
      for i:= 0 to orderbook.count - 1 do begin
        result:= afunc(porders_aggr(orderbook.items[i]), adata);
        if not result then break;
      end;
    except
      on e: exception do begin
        log('EnumOrderbookItems exception: %s', [e.message]);
        result:= false;
      end;
    end;
  end else result:= false;
end;

function tOrderBookHolder.EnumAllItems(afunc: tEnumMethod; adata: pointer): boolean;
var orderbook : tSortedOrderBook;
    i, j      : longint;
begin
  result:= true;
  if assigned(FOrderBooks) and assigned(afunc) then begin
    try
      for i:= 0 to FOrderBooks.count - 1 do begin
        orderbook:= pOrderbooksItem(FOrderBooks.items[i])^.orderbook;
        if assigned(orderbook) then
          for j:= 0 to orderbook.count - 1 do begin
            result:= afunc(porders_aggr(orderbook.items[j]), adata);
            if not result then break;
          end;
        if not result then break;
      end;
    except
      on e: exception do begin
        log('EnumAllItems exception: %s', [e.message]);
        result:= false;
      end;
    end;
  end;
end;

{ tFortsOrderBookTable }

constructor tFortsOrderBookTable.create(AOwner: tFORTSDataStream; const ATableName: ansistring);
begin
  inherited create(AOwner, 'orders_aggr');
  FTable:= tOrderBookHolder.create;
end;

destructor tFortsOrderBookTable.destroy;
begin
  if assigned(FTable) then freeandnil(FTable);
  if assigned(FFilter) then freeandnil(FFilter);
  inherited destroy;
end;

procedure tFortsOrderBookTable.doLoad(AIni: TIniFile);
var tmpitems: ansistring;
begin
  if assigned(AIni) then with AIni do begin
    tmpitems:= ReadString(Self.ClassName, 'filter', '');
    if (length(tmpitems) > 0) then begin
      if not assigned(FFilter) then FFilter:= tStringList.Create;
      if assigned(FFilter) then DecodeCommaText(tmpitems, FFilter, ';');
    end;
  end;
end;

procedure tFortsOrderBookTable.LinkScheme(fields: pcg_field_desc);
var i : longint;
  function check(const acode: tCode; afilter: tStringList): boolean;
  var i : longint;
  begin
    result:= false;
    if assigned(afilter) then begin
      for i:= 0 to afilter.count - 1 do begin
        result:= MatchesMask(acode, afilter[i]);
        if result then break;
      end;
    end;
  end;
begin
  inherited LinkScheme(fields);
  if assigned(FFilter) and assigned(local_isins) then
    for i:= local_isins.count - 1 downto 1 do
      if not check(local_isins.codes[i], FFilter) then local_isins.delete(i);
end;

procedure tFortsOrderBookTable.TransactionBegin;
begin
  FLastIsin:= nil;
  fillchar(FLastKotir, sizeof(FLastKotir), 0);
end;

procedure tFortsOrderBookTable.TransactionCommit;
begin
  OnIsinChange(FLastIsin, nil);
  UnlockTable;
end;

procedure tFortsOrderBookTable.LockChange(alock: boolean);
begin if alock then Server_API.LockKotirovki else Server_API.UnlockKotirovki; end;

function tFortsOrderBookTable.OnOrderbookEnumRow(item: porders_aggr; adata: pointer): boolean;
const bs : array[boolean] of char = ('S', 'B');
var   ls : longint;
begin
  if assigned(adata) then begin
    with pIsinListItem(adata)^ do
      if fortssign(signs, flag_Spot) then ls:= 1 else ls:= lsz;

    FLastKotir.price:= cg_utils_get_bcd(item^.price) / ls;
    FLastKotir.quantity:= item^.volume;
    FLastKotir.buysell:= bs[(item^.dir and 1 = 1)];

    Server_API.AddKotirovkiRec(FLastKotir);
  end;
  result:= true;
end;

procedure tFortsOrderBookTable.OnIsinChange(aold, anew: pIsinListItem);
begin
  if assigned(aold) and assigned(FTable) then begin
    LockTable;
    FTable.EnumOrderbookItems(aold^.isin_id, OnOrderbookEnumRow, aold);
  end;
  if assigned(anew) then begin
    FLastKotir.stock_id := GetFortsStockID;
    FLastKotir.level    := anew^.level;
    FLastKotir.code     := anew^.code;
    LockTable;
    Server_API.ClearKotirovkiTbl(FLastKotir, clrByStruct);
  end;
  FLastIsin:= anew;
end;

function tFortsOrderBookTable.OnStreamData(adata: pAnsiChar): longint;
begin
  with porders_aggr(adata)^ do
    if assigned(local_isins) and (replAct = 0) then begin
      if assigned(FTable) then FTable.SearchAddItem(porders_aggr(adata));
      if not assigned(FLastIsin) or (FLastIsin^.isin_id <> isin_id) then OnIsinChange(FLastIsin, local_isins.isin[isin_id]);
    end;
  result:= CG_ERR_OK;
end;

function tFortsOrderBookTable.OnEnumRow(item: porders_aggr; adata: pointer): boolean;
const bs  : array[boolean] of char = ('S', 'B');
var   kot : tKotirovki;
      itm : pIsinListItem;
      ls  : longint;
begin
  if assigned(adata) and assigned(local_isins) then begin
    itm:= local_isins.isin[item^.isin_id];
    if assigned(itm) then with itm^ do begin
      if fortssign(signs, flag_Spot) then ls:= 1 else ls:= lsz;

      fillchar(kot, sizeof(kot), 0);
      kot.stock_id := GetFortsStockID;
      kot.level    := level;
      kot.code     := code;
      kot.price    := cg_utils_get_bcd(item^.price) / ls;
      kot.quantity := item^.volume;
      kot.buysell  := bs[(item^.dir and 1 = 1)];

      Server_API.AddKotirovkiRec(kot);
    end;
  end;
  result:= true;
end;

function tFortsOrderBookTable.OnClearDeleted(const arev: int64): longint;
var kot: tKotirovki;
begin
  LockTable;
  try
    kot.stock_id := GetFortsStockID;
    kot.level    := level_futures;
    Server_API.ClearKotirovkiTbl(kot, clrByLevel);
    if (arev = $7fffffffffffffff) then begin
      if assigned(FTable) then FTable.clear;
      log('OrderBook cleardeleted: rev=ALL');
    end else begin
      FTable.FilterByRev(arev);
      FTable.EnumAllItems(OnEnumRow, nil);
      log('OrderBook cleardeleted: rev=%.16x', [arev]);
    end;
  finally
    UnlockTable;
  end;
  result:= CG_ERR_OK;
end;

{ tFortsAllTradesTable }

constructor tFortsAllTradesTable.create(AOwner: tFORTSDataStream; const ATableName: ansistring);
begin
  inherited Create(AOwner, 'deal');
  fillchar(alltrd, sizeof(alltrd), 0);
end;

procedure tFortsAllTradesTable.TransactionCommit;
begin UnlockTable; end;

procedure tFortsAllTradesTable.LockChange(alock: boolean);
begin
  if alock then begin
    if assigned(server_api.AllTradesBeginUpdate) then server_api.AllTradesBeginUpdate(GetFortsStockID, '');
  end else begin
    if assigned(server_api.AllTradesEndUpdate) then server_api.AllTradesEndUpdate(GetFortsStockID, '');
  end;
end;

function tFortsAllTradesTable.OnStreamData(adata: pAnsiChar): longint;
const buysellval : array[boolean] of char = ('S', 'B');
var   itm        : pIsinListItem;
      ls         : longint;
begin
  LockTable;
  with pdeal(adata)^ do
    if (replAct = 0) and (nosystem = 0) then begin
      if assigned(local_isins) then itm:= local_isins.isin[isin_id] else itm:= nil;
      if assigned(itm) then with itm^ do begin
        if fortssign(signs, flag_Spot) then ls:= 1 else ls:= lsz;

        alltrd.stock_id  := GetFortsStockID;
        alltrd.tradeno   := id_deal;
        alltrd.tradetime := cg_utils_get_time(moment);
        alltrd.level     := level_futures;
        alltrd.code      := code;
        alltrd.price     := cg_utils_get_bcd(price) / ls;
        alltrd.quantity  := xamount;
        alltrd.value     := (alltrd.price * lsz) * alltrd.quantity;
        alltrd.buysell   := buysellval[(id_ord_buy - id_ord_sell > 0)];

        server_api.AddAllTradesRec(alltrd);
      end;
    end;
  result:= CG_ERR_OK;
end;

{ tFortsTradesTable }

constructor tFortsTradesTable.create(AOwner: tFORTSDataStream; const ATableName: ansistring);
begin
  inherited Create(AOwner, 'user_deal');
  fillchar(trd, sizeof(trd), 0);
end;

procedure tFortsTradesTable.LockChange(alock: boolean);
begin
  if alock then begin
    if assigned(Server_API.TradesBeginUpdate) then Server_API.TradesBeginUpdate(GetFortsStockID, '');
  end else begin
    if assigned(Server_API.TradesEndUpdate) then Server_API.TradesEndUpdate(GetFortsStockID, '');
  end;
end;

procedure tFortsTradesTable.TransactionCommit;
begin UnlockTable; end;

function tFortsTradesTable.OnStreamData(adata: pAnsiChar): longint;
var itm : pIsinListItem;
    ls  : longint;
begin
  LockTable;
  with puser_deal(adata)^ do
    if (replAct = 0) then begin

      if assigned(local_isins) then itm:= local_isins.isin[isin_id] else itm:= nil;
      if assigned(itm) then with itm^ do begin
        if fortssign(signs, flag_Spot) then ls:= 1 else ls:= lsz;

        trd.stock_id     := GetFortsStockID;
        trd.tradeno      := id_deal;
        trd.tradetime    := cg_utils_get_time(moment);
        trd.level        := level_futures;
        trd.code         := code;
        trd.price        := cg_utils_get_bcd(price) / ls;
        trd.quantity     := xamount;
        trd.value        := (trd.price * lsz) * trd.quantity;

        if (strlen(code_sell) > 0) then begin
          trd.transaction := ext_id_sell;
          trd.orderno     := id_ord_sell;
          trd.buysell     := 'S';
          trd.account     := ClientCodeToAccount(level_futures, code_sell);
          trd.comment     := comment_sell;

          server_api.AddTradesRec(trd, [trd_stock_id,trd_tradeno,trd_orderno,trd_tradetime,trd_level,
                                        trd_code,trd_buysell,trd_account,trd_price,trd_quantity,trd_value,
                                        trd_comment]);
        end;

        if (strlen(code_buy) > 0) then begin
          trd.transaction := ext_id_buy;
          trd.orderno     := id_ord_buy;
          trd.buysell     := 'B';
          trd.account     := ClientCodeToAccount(level_futures, code_buy);
          trd.comment     := comment_buy;

          server_api.AddTradesRec(trd, [trd_stock_id,trd_tradeno,trd_orderno,trd_tradetime,trd_level,
                                        trd_code,trd_buysell,trd_account,trd_price,trd_quantity,trd_value,
                                        trd_comment]);
        end;
      end;
    end;
  result:= CG_ERR_OK;
end;

{ tChangesList }

constructor tChangesList.create;
begin
  inherited create;
  fDuplicates:= dupIgnore;
end;

procedure tChangesList.freeitem(item: pointer);
begin end;

function tChangesList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tChangesList.compare(item1, item2: pointer): longint;
begin
  if (pAnsiChar(item1) < pAnsiChar(item2)) then result:= -1 else
  if (pAnsiChar(item1) > pAnsiChar(item2)) then result:= 1 else result:= 0;
end;

{ tOrdersList }

procedure tOrdersList.freeitem(item: pointer);
begin if assigned(item) then dispose(pOrders(item)); end;

function tOrdersList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tOrdersList.compare(item1, item2: pointer): longint;
begin result:= cmpi64(pOrders(item1)^.orderno, pOrders(item2)^.orderno); end;

function tOrdersList.addrecord(var aorder: tOrders): pOrders;
var idx : longint;
begin
  if not search(@aorder, idx) then begin
    result  := new(pOrders);
    result^ := aorder;
    insert(idx, result);
  end else begin
    result:= pOrders(items[idx]);
    if assigned(result) then with result^ do begin
      balance := aorder.balance;
      status  := aorder.status;
    end;
  end;
end;

{ tFortsOrdersTable }

constructor tFortsOrdersTable.create(AOwner: tFORTSDataStream; const ATableName: ansistring);
begin
  inherited create(AOwner, 'orders_log');
  FTable:= tOrdersList.create;
  FChanges:= tChangesList.create;
  fillchar(ord, sizeof(ord), 0);
  fillchar(trd, sizeof(trd), 0);
end;

destructor tFortsOrdersTable.destroy;
begin
  if assigned(FChanges) then freeandnil(FChanges);
  if assigned(FTable) then freeandnil(FTable);
  inherited destroy;
end;

procedure tFortsOrdersTable.LockChange(alock: boolean);
begin
  if alock then begin
    if assigned(Server_API.TradesBeginUpdate) then Server_API.TradesBeginUpdate(GetFortsStockID, '');
  end else begin
    if assigned(Server_API.TradesEndUpdate) then Server_API.TradesEndUpdate(GetFortsStockID, '');
  end;
end;

procedure tFortsOrdersTable.TransactionCommit;
var i : longint;
begin
  UnlockTable;
  if assigned(FChanges) and (FChanges.Count > 0) then begin
    if assigned(Server_API.OrdersBeginUpdate) then Server_API.OrdersBeginUpdate(GetFortsStockID, '');
    try
      for i:= 0 to FChanges.Count - 1 do
        Server_API.AddOrdersRec(pOrders(FChanges.items[i])^, [ord_stock_id,ord_level,ord_code,ord_orderno,ord_ordertime,
                                                              ord_status,ord_buysell,ord_account,ord_price,ord_quantity,
                                                              ord_value,ord_balance,ord_comment]);
    finally
      if assigned(Server_API.OrdersEndUpdate) then Server_API.OrdersEndUpdate(GetFortsStockID, '');
      FChanges.Clear;
    end;
  end;
end;

function tFortsOrdersTable.OnStreamData(adata: pAnsiChar): longint;
const buysellval : array[boolean] of char = ('S', 'B');
      statusval  : array[boolean] of char = ('O', 'M');
var   itm        : pIsinListItem;
      ls         : longint;
begin
  LockTable;
  with porders_log(adata)^ do
    if (replAct = 0) and assigned(FTable) and assigned(FChanges) then begin

      if assigned(local_isins) then itm:= local_isins.isin[isin_id] else itm:= nil;
      if assigned(itm) then with itm^ do begin
        if fortssign(signs, flag_Spot) then ls:= 1 else ls:= lsz;

        ord.transaction := ext_id;
        ord.internalid  := sess_id;
        ord.stock_id    := GetFortsStockID;
        ord.level       := level_futures;
        ord.code        := code;
        ord.orderno     := id_ord;
        ord.ordertime   := cg_utils_get_time(moment);
        ord.buysell     := buysellval[(dir = 1)];
        ord.account     := ClientCodeToAccount(level_futures, client_code);
        ord.price       := cg_utils_get_bcd(price) / ls;
        ord.quantity    := xamount;
        ord.value       := (ord.price * lsz) * ord.quantity;
//        ord.clientid    :=
        ord.balance     := xamount_rest;
//        ord.ordertype   :=
//        ord.settlecode  :=
        ord.comment     := comment;

        case action of
          0    : begin
                   ord.status  := 'W';
                   ord.balance := ord.quantity;
                 end;
          1    : ord.status := statusval[ord.balance = 0];
          2    : begin
                   ord.status := statusval[ord.balance = 0];
                   
                   // fill trade
                   trd.transaction:= ord.transaction;
                   trd.internalid := ord.internalid;
                   trd.stock_id   := ord.stock_id;
                   trd.tradeno    := id_deal;
                   trd.orderno    := ord.orderno;
                   trd.tradetime  := ord.ordertime;
                   trd.level      := ord.level;
                   trd.code       := ord.code;
                   trd.buysell    := ord.buysell;
                   trd.account    := ord.account;
                   trd.price      := cg_utils_get_bcd(deal_price) / ls;
                   trd.quantity   := ord.quantity;
                   trd.value      := ord.value;
//                   trd.accr
//                   trd.clientid
//                   trd.tradetype
//                   trd.settlecode
                   trd.comment    := ord.comment;
                   
                   server_api.AddTradesRec(trd, [trd_stock_id,trd_tradeno,trd_orderno,trd_tradetime,trd_level,
                                                 trd_code,trd_buysell,trd_account,trd_price,trd_quantity,trd_value,
                                                 trd_comment]);
                 end;
        end;

        FChanges.Add(FTable.addrecord(ord));
      end;
    end;
  result:= CG_ERR_OK;
end;

{ tUSDTable }

constructor tUSDTable.create(AOwner: tFORTSDataStream; const ATableName: ansistring);
begin
  inherited Create(AOwner, 'usd_online');
  fillchar(sec, sizeof(sec), 0);
end;

function tUSDTable.OnStreamData(adata: pAnsiChar): longint;
begin
  with pusd_online(adata)^ do
    if (replAct = 0) then begin
      sec.stock_id         := GetFortsStockID;
      sec.level            := level_index;
      if (id = 1) then sec.code := 'RURUSD'
                  else sec.code := format('kurs-%d', [id]);
      sec.shortname        := sec.code;

      sec.lotsize          := 1;

      sec.tradingstatus    := #$4E;

      sec.hibid            := cg_utils_get_bcd(rate);
      sec.lowoffer         := sec.hibid;
      sec.lastdealprice    := sec.hibid;
      sec.closeprice       := sec.hibid;
      sec.prev_price       := sec.hibid;

      sec.lastdealtime     := cg_utils_get_time(moment);

      Server_API.AddSecuritiesRec(sec, [sec_stock_id, sec_level, sec_code, sec_shortname, sec_hibid, sec_lowoffer, //sec_change,
                                        sec_lastdealprice, sec_lastdealtime, sec_closeprice, sec_prev_price, sec_lotsize,
                                        sec_tradingstatus]);
    end;

  result:= CG_ERR_OK;
end;

{ tIndexTable }

constructor tIndexTable.create(AOwner: tFORTSDataStream; const ATableName: ansistring);
begin
  inherited Create(AOwner, 'rts_index');
  fillchar(sec, sizeof(sec), 0);
end;

function tIndexTable.OnStreamData(adata: pAnsiChar): longint;
begin
  with prts_index(adata)^ do
    if (replAct = 0) then begin
      sec.stock_id      := GetFortsStockID;
      sec.level         := level_index;
      sec.code          := name;

      sec.shortname     := sec.code;

      sec.hibid         := cg_utils_get_bcd(value);
      sec.lowoffer      := sec.hibid;
      sec.lastdealprice := sec.hibid;

      sec.lastdealtime  := cg_utils_get_time(moment);

      sec.initprice     := cg_utils_get_bcd(open_value);
      sec.minprice      := cg_utils_get_bcd(min_value);
      sec.maxprice      := cg_utils_get_bcd(max_value);
      sec.closeprice    := cg_utils_get_bcd(prev_close_value);
      sec.prev_price    := sec.closeprice;

      sec.tradingstatus := #$4E;

      sec.lotsize       := 1;

      server_api.AddSecuritiesRec(sec, [sec_stock_id, sec_level, sec_code, sec_shortname, sec_hibid, sec_lowoffer, //sec_change,
                                        sec_lastdealprice, sec_lastdealtime, sec_initprice, sec_minprice, sec_maxprice,
                                        sec_closeprice, sec_prev_price, sec_lotsize, sec_tradingstatus]);
    end;

  result:= CG_ERR_OK;
end;

initialization
  register_class([tFortsSessionContents, tFortsCommonTable, tFortsOrderBookTable, tFortsAllTradesTable,
                  tFortsTradesTable, tFortsOrdersTable, tUSDTable, tIndexTable]);

end.