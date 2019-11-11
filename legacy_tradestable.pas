{$i tterm_defs.pas}
{$i serverdefs.pas}
{$define trades_advanced_stat}

unit legacy_tradestable;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$else}
        unix,
      {$endif}
      sysutils,
      sortedlist,   
      servertypes, serverapi;

type  tTradesTable       = class(tSortedList)
        constructor create;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        function    add(item: pTrades; var fld: tTradesSet; var isNewTrade: boolean): pTrdCollItm; reintroduce; virtual;
      end;

var   TradesCritSect     : tRtlCriticalSection;

const Trades             : tTradesTable  = nil;

const enableRecalcSumms  = true;
      disableRecalcSumms = false;

procedure srvTradesLock(astock_id: longint; alevel: tLevel); cdecl;
procedure srvAddTradesRec(var struc: tTrades; changedfields: tTradesSet); cdecl;
procedure srvTradesUnLock(astock_id: longint; alevel: tLevel); cdecl;

procedure srvUpdateTrades(var sour, dest: tTrades; var sourset, destset: tTradesSet); cdecl;
procedure srvCleanupTrades(var sour: tTrades; var sourset: tTradesSet); cdecl;

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

procedure srvUpdateTrades(var sour, dest: tTrades; var sourset, destset: tTradesSet);
begin
 with dest do begin
  transaction := sour.transaction;
  internalid  := sour.internalid;
  if (trd_orderno   in sourset) and (orderno<>sour.orderno)     then begin orderno:=sour.orderno;     include(destset,trd_orderno);   end;
  if (trd_tradetime in sourset) and (tradetime<>sour.tradetime) then begin tradetime:=sour.tradetime; include(destset,trd_tradetime); end;
  if (trd_level     in sourset) and (level<>sour.level)         then begin level:=sour.level;         include(destset,trd_level);     end;
  if (trd_code      in sourset) and (code<>sour.code)           then begin code:=sour.code;           include(destset,trd_code);      end;
  if (trd_buysell   in sourset) and (buysell<>sour.buysell)     then begin buysell:=sour.buysell;     include(destset,trd_buysell);   end;
  if (trd_account   in sourset) and (account<>sour.account)     then begin account:=sour.account;     include(destset,trd_account);   end;
  if (trd_price     in sourset) and (price<>sour.price)         then begin price:=sour.price;         include(destset,trd_price);     end;
  if (trd_quantity  in sourset) and (quantity<>sour.quantity)   then begin quantity:=sour.quantity;   include(destset,trd_quantity);  end;
  if (trd_value     in sourset) and (value<>sour.value)         then begin value:=sour.value;         include(destset,trd_value);     end;
  if (trd_accr      in sourset) and (accr<>sour.accr)           then begin accr:=sour.accr;           include(destset,trd_accr);      end;
  if (trd_clientid  in sourset) and (clientid<>sour.clientid)   then begin clientid:=sour.clientid;   include(destset,trd_clientid);  end;
  if (trd_tradetype in sourset) and (tradetype<>sour.tradetype) then begin tradetype:=sour.tradetype; include(destset,trd_tradetype); end;
  if (trd_comment   in sourset) and (comment<>sour.comment)     then begin comment:=sour.comment;     include(destset,trd_comment);   end;
 end;
end;

procedure srvCleanupTrades(var sour: tTrades; var sourset: tTradesSet);
begin
 with sour do begin
  if not (trd_orderno   in sourset) then orderno   := -1;
  if not (trd_tradetime in sourset) then tradetime := 0;
  if not (trd_level     in sourset) then setlength(level, 0);
  if not (trd_code      in sourset) then setlength(code, 0);
  if not (trd_buysell   in sourset) then buysell   := #0;
  if not (trd_account   in sourset) then setlength(account, 0);
  if not (trd_price     in sourset) then price     := -1;
  if not (trd_quantity  in sourset) then quantity  := -1;
  if not (trd_value     in sourset) then value     := -1;
  if not (trd_accr      in sourset) then accr      := -1;
  if not (trd_clientid  in sourset) then setlength(clientid, 0);
  if not (trd_tradetype in sourset) then tradetype := #0;
  if not (trd_comment   in sourset) then setlength(comment, 0);
 end;
end;

{ tTradesTable }

constructor tTradesTable.create;
begin inherited create; fduplicates:= dupReplace; end;

procedure tTradesTable.freeitem(item: pointer);
begin if assigned(item) then dispose(pTrdCollItm(item)); end;

function tTradesTable.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tTradesTable.compare(item1, item2: pointer): longint;
begin
  result:= pTrdCollItm(item1)^.trd.stock_id - pTrdCollItm(item2)^.trd.stock_id;
  if (result = 0) then begin
    result:= cmpi64(pTrdCollItm(item1)^.trd.tradeno, pTrdCollItm(item2)^.trd.tradeno);
    if (result = 0) then result:= byte(pTrdCollItm(item1)^.trd.buysell) - byte(pTrdCollItm(item2)^.trd.buysell);
  end;
end;

function tTradesTable.Add(item: pTrades; var fld: tTradesSet; var isNewTrade: boolean): pTrdCollItm;
var idx     : integer;
    tempset : tTradesSet;
begin
  result:= nil;
  isNewTrade:= false;
  if assigned(item) then begin
    if search(item, idx) then begin
      result:= pTrdCollItm(items[idx]);
      with result^ do begin
        tempset    := [trd_stock_id, trd_tradeno, trd_buysell];
        srvUpdateTrades(item^, trd, fld, tempset);
        trdset     := trdset + tempset;
        fld        := tempset;
      end;
    end else begin
      result         := new(pTrdCollItm);
      result^.trd    := item^;
      result^.trdset := fld + [trd_stock_id, trd_tradeno, trd_buysell];
      insert(idx, result);
      isNewTrade := true;
    end;
  end;
end;

{ misc. functions }

procedure srvTradesLock(astock_id: longint; alevel: tLevel);
begin BroadcastTableEvent(evBeginTrades, astock_id, alevel); end;

procedure srvAddTradesRec(var struc: tTrades; changedfields: tTradesSet);
var  trade            : pTrdCollItm;
     tempset          : tTradesSet;
     NewTradeArrived  : boolean;
     i                : longint;
     {$ifdef trades_advanced_stat}
     total_ticks      : cardinal;
     {$endif}
begin
  with struc do log('ADDTRD: Arrived trade: [%d,%d] %s %d %d/%s/%s  %.2f/%d',
                    [orderno, tradeno, buysell, transaction, stock_id, level, code, price, quantity]);

  try
    {$ifdef trades_advanced_stat} total_ticks:= gettickcount; {$endif}

    if assigned(transaction_registry) then transaction_registry.update_trade(struc);

    NewTradeArrived:= false;
    EnterCriticalSection(TradesCritSect);
    try
      trade:= Trades.Add(@struc, changedfields, NewTradeArrived);
      tempset:= changedfields;
    finally LeaveCriticalSection(TradesCritSect); end;

    if assigned(trade) then
      for i:= 0 to event_apis_count - 1 do
        if assigned(event_apis[i]) then with event_apis[i]^ do
          if assigned(evTradesArrived) then evTradesArrived(trade^.trd, trade^.trdset);

    {$ifdef trades_advanced_stat} log('ADDTRD: Timings: Total: %d', [gettickcount - total_ticks]); {$endif}

  except on e: exception do log('ADDTRADE: Exception: %s', [e.message]); end;
end;

procedure srvTradesUnLock(astock_id: longint; alevel: tLevel);
begin BroadcastTableEvent(evEndTrades, astock_id, alevel); end;

exports
  srvTradesLock    name srv_TradesBeginUpdate,
  srvAddTradesRec  name srv_AddTradesRec,
  srvTradesUnLock  name srv_TradesEndUpdate,

  srvUpdateTrades  name srv_UpdateTrades,
  srvCleanupTrades name srv_CleanupTrades;

initialization
  {$ifdef MSWINDOWS}
  InitializeCriticalSection(TradesCritSect);
  {$else}
  InitCriticalSection(TradesCritSect);
  {$endif}
//  AccQueue := tAccountQueue.create;
  Trades   := tTradesTable.Create;

finalization
//  if assigned(AccQueue) then freeandnil(AccQueue);
  if assigned(Trades) then freeandnil(Trades);
  {$ifdef MSWINDOWS}
  DeleteCriticalSection(TradesCritSect);
  {$else}
  DoneCriticalSection(TradesCritSect);
  {$endif}

end.