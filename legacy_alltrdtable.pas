{$i tterm_defs.pas}
{$i serverdefs.pas}
{__$define use_alltrades_storage}

unit legacy_alltrdtable;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$endif}
      sysutils, math,
      sortedlist, 
      servertypes, serverapi;

type  tAllTradesStorage  = class(tSortedList)
        constructor create;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        function    add(var struc: tAllTrades): boolean; reintroduce; virtual;
      end;

type  pATRegistryItem    = ^tATRegistryItem;
      tATRegistryItem    = record
        boardid           : tBoardIdent;
        last_trade_no     : int64;
        storage           : tAllTradesStorage;
      end;

type  tAllTradesRegistry = class(tSortedList)
      private
        fStoreTrades     : boolean;
      public
        constructor create;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        function    add(var struc: tAllTrades): boolean; reintroduce; virtual;
        function    storagebyboardid(const aboardid: tBoardIdent): tAllTradesStorage;
        function    storagebyalltrade(const aalltrade: tAllTrades; var index: longint): tAllTradesStorage;
        procedure   savetofile(const filename: ansistring);

        property    store_all_trades: boolean read fStoreTrades write fStoreTrades;
      end;

var   AllTradesCritSect  : tRtlCriticalSection;
const AllTradesRegistry  : tAllTradesRegistry   = nil;

procedure srvAddAllTradesRec(var struc: tAllTrades); cdecl;

implementation

uses tterm_logger, tterm_legacy_apis;

function cmpi64(a, b: int64): longint;
begin
  a:= a - b;
  if a < 0 then result:= -1 else
  if a > 0 then result:= 1  else result:= 0;
end;

{ tAllTradesStorage }

constructor tAllTradesStorage.create;
begin inherited create; fDuplicates:= dupIgnore; end;

procedure tAllTradesStorage.freeitem(item: pointer);
begin if assigned(item) then dispose(pAllTrades(item)); end;

function tAllTradesStorage.checkitem(item: pointer): boolean;
begin result:= true; end;

function tAllTradesStorage.compare(item1, item2: pointer): longint;
begin result:=cmpi64(pAllTrades(item1)^.tradeno, pAllTrades(item2)^.tradeno); end;

function tAllTradesStorage.add(var struc: tAllTrades): boolean;
var itm : pAllTrades;
    idx : longint;
begin
  if not search(@struc,idx) then begin
    itm:= new(pAllTrades); itm^:= struc; insert(idx, itm);
    result:= true;
  end else result:= false;
end;

{ tAllTradesRegistry }

constructor tAllTradesRegistry.create;
begin
  inherited create;
  fDuplicates:= dupIgnore;
  fStoreTrades:= true;
end;

procedure tAllTradesRegistry.freeitem(item: pointer);
begin
  if assigned(item) then begin
    with pATRegistryItem(item)^ do if assigned(storage) then storage.free;
    dispose(pATRegistryItem(item));
  end;
end;

function tAllTradesRegistry.checkitem(item: pointer): boolean;
begin result:=true; end;

function tAllTradesRegistry.compare(item1, item2: pointer): longint;
begin
  result:=pATRegistryItem(item1)^.boardid.stock_id - pATRegistryItem(item2)^.boardid.stock_id;
  if (result = 0) then begin
    result:=CompareText(pATRegistryItem(item1)^.boardid.level, pATRegistryItem(item2)^.boardid.level);
  end;
end;

function tAllTradesRegistry.add(var struc: tAllTrades): boolean;
var itm    : tATRegistryItem;
    idx    : longint;
    newitm : pATRegistryItem;
begin
  fillchar(itm, sizeof(itm), 0);
  with itm.boardid do begin stock_id:= struc.stock_id; level:= struc.level; end;
  if not search(@itm, idx) then begin
    newitm:= new(pATRegistryItem);
    with newitm^ do begin
      boardid:= itm.boardid;
      last_trade_no:= struc.tradeno;
      storage:= tAllTradesStorage.create;
      if fStoreTrades then result:= storage.add(struc) else result:= true;
    end;
    insert(idx, newitm);
  end else begin
    with pATRegistryItem(items[idx])^ do begin
      if fStoreTrades then begin
        last_trade_no:= max(last_trade_no, struc.tradeno);
        result:= assigned(storage) and storage.add(struc);
      end else begin
        result:= (struc.tradeno > last_trade_no);
        last_trade_no:= struc.tradeno;
      end;
    end;
  end;
end;

function tAllTradesRegistry.storagebyboardid(const aboardid: tBoardIdent): tAllTradesStorage;
var itm    : tATRegistryItem;
    idx    : longint;
begin
  itm.boardid:= aboardid;
  if search(@itm, idx) then result:= pATRegistryItem(items[idx])^.storage else result:= nil;
end;

function tAllTradesRegistry.storagebyalltrade(const aalltrade: tAllTrades; var index: longint): tAllTradesStorage;
var itm    : tATRegistryItem;
    idx    : longint;
begin
  fillchar(itm, sizeof(itm), 0);
  with itm.boardid do begin stock_id:= aalltrade.stock_id; level:= aalltrade.level; end;
  if search(@itm, idx) then begin
    result:= pATRegistryItem(items[idx])^.storage;
    if assigned(result) then result.search(@aalltrade, index)
                        else index:= 0;     
  end else result:= nil;
end;

procedure tAllTradesRegistry.savetofile(const filename: ansistring);
var fh, i, j : longint;
    st       : ansistring;
begin
  fh:= filecreate(filename);
  if (fh >= 0) then try
    for i:= 0 to count - 1 do
      if assigned(items[i]) then with pATRegistryItem(items[i])^ do
        if assigned(storage) then with storage do begin
          for j:= 0 to count - 1 do
            if assigned(items[j]) then with pAllTrades(items[j])^ do begin
              st:= format('%s,%d,%d,%s,%s,%s,%d,%s,%s,%s,%s'#$0d#$0a,
                          [datetimetostr(tradetime), tradeno, stock_id, level, code, floattostr(price),
                           quantity, floattostr(value), buysell, floattostr(reporate), floattostr(repoterm)]);
              filewrite(fh, st[1], length(st));
            end;
        end;
  finally fileclose(fh); end;
end;

// -------------------------------------------------------------------

procedure srvAddAllTradesRec(var struc: tAllTrades);
var i               : longint;
    {$ifdef use_alltrades_storage}
    NewTradeArrived : boolean;
    {$endif}
begin
  {$ifdef use_alltrades_storage}
  NewTradeArrived:= false;
  try
    if assigned(AllTradesRegistry) then begin
      EnterCriticalSection(AllTradesCritSect);
      try NewTradeArrived:= AllTradesRegistry.add(struc);
      finally LeaveCriticalSection(AllTradesCritSect); end;
    end;
  {$else}
  try
  {$endif}

    for i:= 0 to event_apis_count - 1 do
      if assigned(event_apis[i]) then with event_apis[i]^ do
        if assigned(evAllTrdArrived) then evAllTrdArrived(struc);

  except on e: exception do log('ALLTRADES: Exception: %s', [e.message]); end;
end;

exports
  srvAddAllTradesRec name srv_AddAllTradesRec;

initialization
  {$ifdef MSWINDOWS}
  InitializeCriticalSection(AllTradesCritSect);
  {$else}
  InitCriticalSection(AllTradesCritSect);
  {$endif}
  AllTradesRegistry:= tAllTradesRegistry.create;

finalization
  if assigned(AllTradesRegistry) then freeandnil(AllTradesRegistry);
  {$ifdef MSWINDOWS}
  DeleteCriticalSection(AllTradesCritSect);
  {$else}
  DoneCriticalSection(AllTradesCritSect);
  {$endif}

end.