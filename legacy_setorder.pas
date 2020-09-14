{$i tterm_defs.pas}
{$i serverdefs.pas}

unit legacy_setorder;

interface

uses  {$ifdef MSWINDOWS}
        windows, inifiles,
      {$else}
        unix, fclinifiles,
      {$endif}
      sysutils,
      sortedlist,
      serverapi, servertypes;

procedure srvSetTransactionResult(var aresult: tSetOrderResult); cdecl;

function  srvSetSystemOrder(var order: tOrder; const acomment: pChar; var setresult: tSetOrderResult): boolean; cdecl;
function  srvMoveSystemOrder(var moveorder: tMoveOrder; var setresult: tSetOrderResult): boolean; cdecl;
function  srvDropOrder(const aaccount: tAccount; var droporder: tDropOrder): boolean; cdecl;
function  srvDropOrderEx(var droporder: tDropOrderEx; var setresult: tSetOrderResult): boolean; cdecl;

implementation

uses  tterm_logger, tterm_legacy_apis, legacy_sectable, legacy_transactions, legacy_orderstable, legacy_accounts;

{$ifndef MSWINDOWS}
function GetTickCount: cardinal;
var t : timeval;
begin
  fpgettimeofday(@t, nil);
  result := ((int64(t.tv_sec) * 1000000) + t.tv_usec) div 1000;
end;
{$endif}

{ misc functions }

procedure srvSetTransactionResult(var aresult: tSetOrderResult);
var i : longint;
begin
  try
    for i:= 0 to event_apis_count - 1 do
      if assigned(event_apis[i]) then with event_apis[i]^ do
        if assigned(evTransactionRes) then evTransactionRes(aresult);

    with aresult do
      case accepted of
        soAccepted      : log('Accepted. [%d] Stock reply: %s', [externaltrs, TEReply]);
        soRejected      : begin
                            log('Rejected. [%d] Stock reply: %s', [externaltrs, TEReply]);
                            if assigned(transaction_registry) then transaction_registry.remove_transaction(internalid);
                          end;
        soUnknown       : ;
        soDropAccepted  : log('Drop accepted. [%d] Stock reply: %s', [externaltrs, TEReply]);
        soDropRejected  : log('Drop rejected. [%d] Stock reply: %s', [externaltrs, TEReply]);
        soError         : log('Error setting order. [%d] Stock reply: %s', [externaltrs, TEReply]);
      end;

  except on e: exception do log('SETRES: Exception: %s', [e.message]); end;
end;

function srvSetSystemOrder(var order: tOrder; const acomment: pAnsiChar; var setresult: tSetOrderResult): boolean;
var  stockapi      : pStockAPI;
     {$ifdef enabletimecounters}
     tickcount     : cardinal;
     trstickcount  : cardinal;
     {$endif}
begin
  {$ifdef enabletimecounters} tickcount:= gettickcount; trstickcount:= 0; {$endif}
  setresult.accepted:= soRejected;
  setresult.quantity:= -1;

  with order do log('SETSYSORD: Setting system order: [%d] %s  %d/%s/%s  %s  %d/%f',
                    [transaction, account, stock_id, level, code, buysell, quantity, price]);

  stockapi:= stock_apis[byte(Order.stock_id)];
  if assigned(stockapi) and assigned(stockapi^.pl_SetOrder) then begin

//    setresult.username:= ''; setresult.clientid:= order.cid; // !!!set this values in external code!!!
    if assigned(transaction_registry) then setresult.internalid:= transaction_registry.new_transaction(order)
                                      else setresult.internalid:= 0;
    setresult.externaltrs:= order.transaction;
    setresult.account:= order.account;

    order.transaction:= setresult.internalid;
    if assigned(StockAccountList) then order.account:= StockAccountList.stockaccounts[order.stock_id, order.account];

    {$ifdef enabletimecounters}trstickcount:= gettickcount;{$endif}
    try
      stockapi^.pl_SetOrder(order, acomment, setresult);
    except on e:exception do log('STOCKSETORDER: Exception: %s', [e.message]); end;
    {$ifdef enabletimecounters}trstickcount:= gettickcount - trstickcount;{$endif}

    try with stockapi^ do if assigned(ev_OrderCommit) then with setresult do ev_OrderCommit(accepted, extnumber);
    except on e:exception do log('STOCKCOMMIT: Exception: %s', [e.message]); end;
  end;

  {$ifdef enabletimecounters}
  log('SETSYSORD: System order for %s set in %d msecs, trs delay: %d', [setresult.account, gettickcount - tickcount, trstickcount]);
  {$endif}
  result:= not ((setresult.accepted = soRejected) or (setresult.accepted = soError));
end;

function srvMoveSystemOrder(var moveorder: tMoveOrder; var setresult: tSetOrderResult): boolean; cdecl;
var  stockapi      : pStockAPI;
     {$ifdef enabletimecounters}
     tickcount     : cardinal;
     trstickcount  : cardinal;
     {$endif}
begin
  {$ifdef enabletimecounters} tickcount:= gettickcount; trstickcount:= 0; {$endif}
  setresult.accepted:= soRejected; setresult.quantity:= -1;

  with moveorder do log('MOVESYSORD: Moving system order: [%d] %d %s  %d/%s/%s  %d/%f',
                        [transaction, moveorder.orderno, moveorder.account, stock_id, level, code, new_quantity, new_price]);

  stockapi:= stock_apis[byte(moveorder.stock_id)];
  if assigned(stockapi) and assigned(stockapi^.pl_MoveOrder) then begin

//    setresult.username:= ''; setresult.clientid:= moveorder.cid; // !!!set this values in external code!!!
    if assigned(transaction_registry) then setresult.internalid:= transaction_registry.new_transaction(moveorder)
                                      else setresult.internalid:= 0;
    setresult.externaltrs:= moveorder.transaction;
    setresult.account:= moveorder.account;

    moveorder.transaction:= setresult.internalid;
    if assigned(StockAccountList) then moveorder.account:= StockAccountList.stockaccounts[moveorder.stock_id, moveorder.account];

    {$ifdef enabletimecounters}trstickcount:= gettickcount;{$endif}
    try
      stockapi^.pl_MoveOrder(moveorder, '', setresult);
    except on e:exception do log('STOCKMOVEORDER: Exception: %s', [e.message]); end;
    {$ifdef enabletimecounters}trstickcount:= gettickcount - trstickcount;{$endif}

    try with stockapi^ do if assigned(ev_OrderCommit) then with setresult do ev_OrderCommit(accepted, extnumber);
    except on e:exception do log('STOCKCOMMIT: Exception: %s', [e.message]); end;
  end;

  {$ifdef enabletimecounters}
  log('MOVESYSORD: System moveorder for %s set in %d msecs, trs delay: %d', [setresult.account, gettickcount - tickcount, trstickcount]);
  {$endif}

  result:= not ((setresult.accepted = soRejected) or (setresult.accepted = soError));
end;

function  srvDropOrder(const aaccount: tAccount; var droporder: tDropOrder): boolean;
var   i         : integer;
      stockapi  : pStockAPI;
      setresult : tSetOrderResult;
      {$ifdef enabletimecounters}
      tickcount : cardinal;
      {$endif}
var   dropordprms  : array[1..maxDropOrders] of tDropOrderEx;
      dropordcount : longint;
      dropped      : longint;
      orderitem    : tOrdCollItm;
begin
  dropped:= -1;

  fillchar(setresult, sizeof(setresult), 0);
  setresult.accepted:= soUnknown; setresult.quantity:= -1;
  try
    {$ifdef enabletimecounters} tickcount:= GetTickCount; {$endif}
    with droporder do log('DROPORD: Dropping system order: [%d] %d/%d', [transaction, droporder.stock_id, droporder.count]);

    if (droporder.count <= maxDropOrders) then begin

      stockapi:= stock_apis[byte(droporder.stock_id)];
      if assigned(stockapi) then begin

        dropordcount:= 0;
        for i:= 1 to droporder.count do begin
          inc(dropordcount);
          with dropordprms[dropordcount] do begin
            transaction := droporder.transaction;
            orderno     := droporder.orders[i];
            stock_id    := droporder.stock_id;
            if srvGetOrdersRec(stock_id, orderno, orderitem) then begin
              level     := orderitem.ord.level;
              code      := orderitem.ord.code;
              account   := orderitem.ord.account;
              cid       := orderitem.ord.clientid;
            end else begin
              account   := aaccount;
              cid       := '';
            end;
            flags       := 0;
          end;
        end;

        dropped:= droporder.count;
        for i:= 0 to dropordcount - 1 do with dropordprms[i + 1] do begin
          setresult.internalid := 0;
          setresult.externaltrs := droporder.transaction;
          setresult.account:= account;

          if assigned(stockapi^.pl_DropOrderEx) then begin
            if assigned(StockAccountList) then account:= StockAccountList.stockaccounts[stock_id, account];
            stockapi^.pl_DropOrderEx(dropordprms[i + 1], '', setresult)
          end else stockapi^.pl_DropOrder(orderno, flags, stock_id, level, code, setresult);

          with setresult do begin
            if (not accepted in [soAccepted, soDropAccepted]) then log('Drop rejected. [%d] Stock reply: %s', [externaltrs, TEReply])
                                                              else dec(dropped);
          end;
        end;
      end;
    end;
    {$ifdef enabletimecounters}log('DROPORD: DropOrder packet proceed in %d msecs', [GetTickCount - tickcount]);{$endif}
  except on e: exception do log('DROPORD: Exception: %s', [e.message]); end;

  result:= (dropped = 0);
end;

function srvDropOrderEx(var droporder: tDropOrderEx; var setresult: tSetOrderResult): boolean;    cdecl;
var   stockapi  : pStockAPI;
      {$ifdef enabletimecounters}
      tickcount : cardinal;
      {$endif}
begin
  setresult.accepted:= soUnknown; setresult.quantity:= -1;
  try
    {$ifdef enabletimecounters} tickcount:= GetTickCount; {$endif}
    with droporder do log('DROPORDEX: Dropping system order: [%d] %d %d', [transaction, droporder.orderno, droporder.stock_id]);
    stockapi:= stock_apis[byte(droporder.stock_id)];
    if assigned(stockapi) then with droporder do begin
      setresult.internalid  := 0;
      setresult.externaltrs := transaction;
      setresult.account     := account;
      if assigned(StockAccountList) then account:= StockAccountList.stockaccounts[stock_id, account];

      if assigned(stockapi^.pl_DropOrderEx) then stockapi^.pl_DropOrderEx(droporder, '', setresult)
                                            else stockapi^.pl_DropOrder(orderno, flags, stock_id, level, code, setresult);

      with setresult do begin
        if (not accepted in [soAccepted, soDropAccepted]) then log('Drop rejected. [%d] Stock reply: %s', [externaltrs, TEReply]);
      end;
    end;
    {$ifdef enabletimecounters}log('DROPORDEX: DropOrderEx proceed in %d msecs', [GetTickCount - tickcount]);{$endif}
  except on e: exception do log('DROPORDEX: Exception: %s', [e.message]); end;

  result:= not ((setresult.accepted = soRejected) or (setresult.accepted = soError));
end;

exports
  srvSetTransactionResult  name srv_SetTransactionResult,

  srvSetSystemOrder        name srv_SetSystemOrder,
  srvMoveSystemOrder       name srv_MoveSystemOrder,
  srvDropOrder             name srv_DropOrder,
  srvDropOrderEx           name srv_DropOrderEx;

end.