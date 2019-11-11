{$i tterm_defs.pas}
{$i serverdefs.pas}
{$define orders_advanced_stat}
{__$define ordertime_not_changing}

unit legacy_orderstable;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$else}
        unix,
      {$endif}
      sysutils,
      sortedlist, 
      servertypes, serverapi;

type  tOrdersTable = class(tSortedList)
        constructor create;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        function    add(item: pOrders; var fld: tOrdersSet): pOrdCollItm; reintroduce; virtual;
      end;

var   OrdersCritSect     : tRtlCriticalSection;

const Orders             : tOrdersTable = nil;

procedure srvOrdersLock(astock_id: longint; alevel: tLevel); cdecl;
procedure srvAddOrdersRec(var struc: tOrders; changedfields: TOrdersSet); cdecl;
function  srvGetOrdersRec(astock_id: longint; const aorderno: int64; var aorderitem: tOrdCollItm): boolean; cdecl;
procedure srvOrdersUnLock(astock_id: longint; alevel: tLevel); cdecl;

procedure srvUpdateOrders(var sour, dest:tOrders; var sourset, destset: tOrdersSet); cdecl;
procedure srvCleanupOrders(var sour: tOrders; const sourset: tOrdersSet); cdecl;

implementation

uses tterm_logger, tterm_legacy_apis, legacy_transactions;

{$ifndef MSWINDOWS}
function GetTickCount: cardinal;
var t : timeval;
begin
  fpgettimeofday(@t, nil);
  result := ((int64(t.tv_sec) * 1000000) + t.tv_usec) div 1000;
end;
{$endif}

function cmpi64(a, b: int64): longint;
begin
  a:= a - b;
  if a < 0 then result:= -1 else
  if a > 0 then result:= 1  else result:= 0;
end;

procedure srvUpdateOrders(var sour, dest:tOrders; var sourset, destset: tOrdersSet);
begin
  with dest do begin
    transaction := sour.transaction;
    internalid  := sour.internalid;
    if (ord_level      in sourset) and (level <> sour.level)           then begin level:=sour.level;           include(destset,ord_level);      end;
    if (ord_code       in sourset) and (code <> sour.code)             then begin code:=sour.code;             include(destset,ord_code);       end;
    {$ifdef ordertime_not_changing}
    if (ord_ordertime  in sourset) and (ordertime = 0)                 then begin ordertime:=sour.ordertime;   include(destset,ord_ordertime);  end;
    {$else}
    if (ord_ordertime  in sourset) and (ordertime <> sour.ordertime)   then begin ordertime:=sour.ordertime;   include(destset,ord_ordertime);  end;
    {$endif}
    if (ord_status     in sourset) and (status <> sour.status)         then begin status:=sour.status;         include(destset,ord_status);     end;
    if (ord_buysell    in sourset) and (buysell <> sour.buysell)       then begin buysell:=sour.buysell;       include(destset,ord_buysell);    end;
    if (ord_account    in sourset) and (account <> sour.account)       then begin account:=sour.account;       include(destset,ord_account);    end;
    if (ord_price      in sourset) and (price <> sour.price)           then begin price:=sour.price;           include(destset,ord_price);      end;
    if (ord_quantity   in sourset) and (quantity <> sour.quantity)     then begin quantity:=sour.quantity;     include(destset,ord_quantity);   end;
    if (ord_value      in sourset) and (value <> sour.value)           then begin value:=sour.value;           include(destset,ord_value);      end;
    if (ord_clientid   in sourset) and (clientid <> sour.clientid)     then begin clientid:=sour.clientid;     include(destset,ord_clientid);   end;
    if (ord_balance    in sourset) and (balance <> sour.balance)       then begin balance:=sour.balance;       include(destset,ord_balance);    end;
    if (ord_ordertype  in sourset) and (ordertype <> sour.ordertype)   then begin ordertype:=sour.ordertype;   include(destset,ord_ordertype);  end;
    if (ord_settlecode in sourset) and (settlecode <> sour.settlecode) then begin settlecode:=sour.settlecode; include(destset,ord_settlecode); end;
    if (ord_comment    in sourset) and (comment <> sour.comment)       then begin comment:=sour.comment;       include(destset,ord_comment);    end;
  end;
end;

procedure srvCleanupOrders(var sour: tOrders; const sourset: tOrdersSet); 
begin
  with sour do begin
    if not (ord_level      in sourset) then setlength(level, 0);
    if not (ord_code       in sourset) then setlength(code, 0);
    if not (ord_ordertime  in sourset) then ordertime  := 0;
    if not (ord_status     in sourset) then status     := #0;
    if not (ord_buysell    in sourset) then buysell    := #0;
    if not (ord_account    in sourset) then setlength(account, 0);
    if not (ord_price      in sourset) then price      := -1;
    if not (ord_quantity   in sourset) then quantity   := -1;
    if not (ord_value      in sourset) then value      := -1;
    if not (ord_clientid   in sourset) then setlength(clientid, 0);
    if not (ord_balance    in sourset) then balance    := -1;
    if not (ord_ordertype  in sourset) then ordertype  := #0;
    if not (ord_settlecode in sourset) then setlength(settlecode, 0);
    if not (ord_comment    in sourset) then setlength(comment, 0);
  end;
end;

{ tOrdersTable }

constructor tOrdersTable.create;
begin inherited create; fduplicates:= dupReplace; end;

procedure tOrdersTable.freeitem(item: pointer); 
begin if assigned(item) then dispose(pOrdCollItm(item)); end;

function tOrdersTable.checkitem(item: pointer): boolean; 
begin result:= true; end;

function tOrdersTable.compare(item1, item2: pointer): longint; 
begin
  result:= pOrdCollItm(item1)^.ord.stock_id - pOrdCollItm(item2)^.ord.stock_id;
  if (result = 0) then result:= cmpi64(pOrdCollItm(item1)^.ord.orderno, pOrdCollItm(item2)^.ord.orderno);
end;

function tOrdersTable.Add(item: pOrders; var fld: tOrdersSet): pOrdCollItm; 
var idx     : integer;
    tempset : tOrdersSet;
begin
  result:= nil;
  if assigned(item) then try
    if search(item, idx) then begin
      result:= pOrdCollItm(items[idx]);
      with result^ do begin
        tempset := [ord_stock_id, ord_orderno];
        srvUpdateOrders(item^, ord, fld, tempset);
        ordset  := ordset + tempset;
        fld     := tempset;
      end;
    end else begin
      result         := new(pOrdCollItm);
      result^.ord    := item^;
      result^.ordset := fld + [ord_stock_id, ord_orderno];
      insert(idx, result);
    end;
  except on e:exception do log('ADDORDER: Upd: Exception: %s',[e.message]); end;
end;

{ misc. functions }

procedure srvOrdersLock(astock_id: longint; alevel: tLevel);
begin BroadcastTableEvent(evBeginOrders, astock_id, alevel); end;

procedure srvAddOrdersRec(var struc: tOrders; changedfields: TOrdersSet);
var  order       : pOrdCollItm;
     tempset     : tOrdersSet;
     i           : longint;
     {$ifdef orders_advanced_stat}
     total_ticks : cardinal;
     {$endif}
begin
  with struc do log('ADDORD: Arrived order: [%d] %s %d %d/%s/%s  %.2f/%d/%d %s',
                    [orderno, buysell, transaction, stock_id, level, code, price, quantity, balance, status]);
  try
    {$ifdef orders_advanced_stat} total_ticks:= gettickcount; {$endif}

    if assigned(transaction_registry) then transaction_registry.update_order(struc);

    EnterCriticalSection(OrdersCritSect);
    try
      order   := Orders.Add(@struc, changedfields);
      tempset := changedfields;
    finally LeaveCriticalSection(OrdersCritSect); end;

    if assigned(order) then
      for i:= 0 to event_apis_count - 1 do
        if assigned(event_apis[i]) then with event_apis[i]^ do
          if assigned(evOrderArrived) then evOrderArrived(order^.ord, tempset);

    {$ifdef orders_advanced_stat} log('ADDORD: Timings: Total: %d', [gettickcount - total_ticks]); {$endif}
  except on e: exception do log('ADDORDER: Exception: %s', [e.message]); end;
end;

function  srvGetOrdersRec(astock_id: longint; const aorderno: int64; var aorderitem: tOrdCollItm): boolean; 
var idx : longint;
begin
  EnterCriticalSection(OrdersCritSect);
  try
    aorderitem.ord.stock_id := astock_id;
    aorderitem.ord.orderno  := aorderno;
    result:= Orders.search(@aorderitem, idx);
    if result then aorderitem:= pOrdCollItm(Orders.items[idx])^;
  finally LeaveCriticalSection(OrdersCritSect); end;
end;

procedure srvOrdersUnLock(astock_id: longint; alevel: tLevel);
begin BroadcastTableEvent(evEndTrades, astock_id, alevel); end;

exports
  srvOrdersLock    name srv_OrdersBeginUpdate,
  srvAddOrdersRec  name srv_AddOrdersRec,
  srvGetOrdersRec  name srv_GetOrdersRec,
  srvOrdersUnLock  name srv_OrdersEndUpdate,

  srvUpdateOrders  name srv_UpdateOrders,
  srvCleanupOrders name srv_CleanupOrders;

initialization
  {$ifdef MSWINDOWS}
  InitializeCriticalSection(OrdersCritSect);
  {$else}
  InitCriticalSection(OrdersCritSect);
  {$endif}
  orders:= tOrdersTable.Create;

finalization
  if assigned(orders) then freeandnil(orders);
  {$ifdef MSWINDOWS}
  DeleteCriticalSection(OrdersCritSect);
  {$else}
  DoneCriticalSection(OrdersCritSect);
  {$endif}

end.