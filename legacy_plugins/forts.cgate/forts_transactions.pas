{$i forts_defs.pas}

unit forts_transactions;

interface

uses  {$ifdef MSWINDOWS}
        windows, 
      {$endif}
      sysutils,
      sortedlist,
      servertypes,
      forts_common;

const  errNoThreads       = 'FORTS: No transaction threads!';
       errNoQueue         = 'FORTS: No queue exists!';
       errNoGlobalQueue   = 'FORTS: Unable to queue request!';
       errInternalError   = 'FORTS: Internal error!';
       errPublisherError  = 'FORTS: Publisher is not ready!';
       errMessageError    = 'FORTS: Unable to allocate transaction message!';
       errPostError       = 'FORTS: Unable to post transaction message!';

type   tOrderAction       = (actSetOrder, actMoveOrder, actDropOrder);

type   pOrderQueueItem    = ^tOrderQueueItem;
       tOrderQueueItem    = record
         action           : tOrderAction;
         startcount       : int64;
         trs_id           : int64;
         res              : tSetOrderResult;
         case tOrderAction of
           actSetOrder  : ( order       : tOrder;
                            comment     : tOrderComment;
                          );
           actMoveOrder : ( moveorder   : tMoveOrder;
                            movecomment : tOrderComment;
                          );
           actDropOrder : ( orderno    : int64;
                            dropflags  : longint;
                            stock_id   : longint;
                            level      : TLevel;
                            code       : TCode;
                          );
       end;

type  tTransactionQueue   = class(tCustomList)
        procedure   freeitem(item: pointer); override;

        function    PeekOrderQueueItem: pOrderQueueItem;
      end;

type  pAccountGroupItem   = ^tAccountGroupItem;
      tAccountGroupItem   = record
        account           : tAccount;
        accountgroup      : longint;
      end;

type  tAccountGroupsList  = class(tSortedThreadList)
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;

        procedure   RegisterAccount(const aaccount: tAccount; aaccountgroup: longint);
        function    AccountGroup(const aaccount: tAccount): longint;
      end;

type  pQueueRegItem       = ^tQueueRegItem;
      tQueueRegItem       = record
        level             : tLevel;
        accountgroup      : longint;
        count             : longint;
        queue             : tTransactionQueue;
      end;

type  tFortsTransactionQueue = class(tSortedThreadList)
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;

        procedure   RegisterReceiverThread(const alevel: tLevel; aaccountgroup: longint);
        procedure   UnregisterReceiverThread(const alevel: tLevel; aaccountgroup: longint);

        function    PeekOrderQueueItem(const alevel: tLevel; aaccountgroup: longint): pOrderQueueItem;

        function    AddNewOrder(const aorder: tOrder; const acomment: tOrderComment;
                                var ares: tSetOrderResult): boolean;
        function    AddMoveOrder(const amoveorder: tMoveOrder; const acomment: tOrderComment;
                                 var ares: tSetOrderResult): boolean;
        function    AddDropOrder(aorderno: int64; aflags: longint;
                                 astock_id: longint; const alevel: TLevel; const acode: TCode;
                                 var ares: tSetOrderResult): boolean;
        function    AddDropOrderEx(const adroporder: tDropOrderEx; const acomment: tOrderComment;
                                   var ares: tSetOrderResult): boolean;
      end;

const forts_transaction_queue : tFortsTransactionQueue = nil;
      forts_penalty_time      : cardinal               = 0;
      forts_account_groups    : tAccountGroupsList     = nil;

procedure SetFortsTimePenalty(apenalty: cardinal);
function  GetFortsCurrentTime: cardinal;

implementation

procedure SetFortsTimePenalty(apenalty: cardinal);
begin
  forts_penalty_time:= (GetMksCount div 1000) + apenalty;
  log('Setting flood-control penalty: %d ms', [apenalty]);
end;

function  GetFortsCurrentTime: cardinal;
begin
  result:= GetMksCount div 1000;
end;

{ tTransactionQueue }

procedure tTransactionQueue.freeitem(item: pointer);
begin if assigned(item) then dispose(pOrderQueueItem(item)); end;

function tTransactionQueue.PeekOrderQueueItem: pOrderQueueItem;
begin
  result:= nil;
  if (count > 0) then try
    result:= pOrderQueueItem(items[0]);
    items[0]:= nil;
  finally delete(0); end;
end;

{ tAccountGroupsList }

procedure tAccountGroupsList.freeitem(item: pointer);
begin if assigned(item) then dispose(pAccountGroupItem(item)); end;

function tAccountGroupsList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tAccountGroupsList.compare(item1, item2: pointer): longint; 
begin result:= CompareStr(pAccountGroupItem(item1).account, pAccountGroupItem(item2).account); end;

procedure tAccountGroupsList.RegisterAccount(const aaccount: tAccount; aaccountgroup: longint);
var sitm : tAccountGroupItem;
    itm  : pAccountGroupItem;
    idx  : longint;
begin
  sitm.account:= aaccount;
  locklist;
  try
    if not search(@sitm, idx) then begin
      itm:= new(pAccountGroupItem);
      itm^.account:= aaccount;
      itm^.accountgroup:= aaccountgroup;
      insert(idx, itm);
    end;
  finally unlocklist; end;
end;

function tAccountGroupsList.AccountGroup(const aaccount: tAccount): longint;
var sitm : tAccountGroupItem;
    idx  : longint;
begin
  sitm.account:= aaccount;
  locklist;
  try
    if search(@sitm, idx) then result:= pAccountGroupItem(items[idx])^.accountgroup else result:= 0;
  finally unlocklist; end;
end;


{ tFortsTransactionQueue }

procedure tFortsTransactionQueue.freeitem(item: pointer);
begin
  if assigned(item) then begin
    with pQueueRegItem(item)^ do begin
      if assigned(queue) then freeandnil(queue);
    end;
    dispose(pQueueRegItem(item));
  end;
end;

function tFortsTransactionQueue.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tFortsTransactionQueue.compare(item1, item2: pointer): longint;
begin
  result:= CompareText(pQueueRegItem(item1)^.level, pQueueRegItem(item2)^.level);
  if (result = 0) then result:= pQueueRegItem(item1)^.accountgroup - pQueueRegItem(item2)^.accountgroup;
end;

procedure tFortsTransactionQueue.RegisterReceiverThread(const alevel: tLevel; aaccountgroup: longint);
var sitm : tQueueRegItem;
    idx  : longint;
    itm  : pQueueRegItem;
begin
  sitm.level:= alevel;
  sitm.accountgroup:= aaccountgroup;
  locklist;
  try
    if not search(@sitm, idx) then begin
      itm:= new(pQueueRegItem);
      with itm^ do begin
        level:= alevel;
        accountgroup:= aaccountgroup;
        count:= 0;
        queue:= tTransactionQueue.create;
      end;
      insert(idx, itm);
    end else itm:= pQueueRegItem(items[idx]);
    if assigned(itm) then with itm^ do begin
      inc(count);
    end;
  finally unlocklist; end;
end;

procedure tFortsTransactionQueue.UnregisterReceiverThread(const alevel: tLevel; aaccountgroup: longint);
var sitm : tQueueRegItem;
    idx  : longint;
begin
  sitm.level:= alevel;
  sitm.accountgroup:= aaccountgroup;
  locklist;
  try
    if search(@sitm, idx) then
      with pQueueRegItem(items[idx])^ do begin
        dec(count);
        if (count = 0) then delete(idx);
      end;
  finally unlocklist; end;
end;

function tFortsTransactionQueue.PeekOrderQueueItem(const alevel: tLevel; aaccountgroup: longint): pOrderQueueItem;
var sitm : tQueueRegItem;
    idx  : longint;
    {$ifdef enable_flood_penalty}
    tm   : cardinal;
    {$endif}
begin
  result:= nil;
  {$ifdef enable_flood_penalty}
  tm:= GetFortsCurrentTime;
  if (tm > forts_penalty_time) or (abs(longint(forts_penalty_time) - longint(tm)) > 1000) then begin
  {$endif}
    sitm.level:= alevel;
    sitm.accountgroup:= aaccountgroup;
    locklist;
    try
      if search(@sitm, idx) then
        with pQueueRegItem(items[idx])^ do
          if assigned(queue) then result:= queue.PeekOrderQueueItem;
    finally unlocklist; end;
  {$ifdef enable_flood_penalty}
  end;
  {$endif}
end;

function tFortsTransactionQueue.AddNewOrder(const aorder: tOrder; const acomment: tOrderComment; var ares: tSetOrderResult): boolean;
var sitm : tQueueRegItem;
    idx  : longint;
    itm  : pOrderQueueItem;
begin
  result:= false;
  sitm.level:= aorder.level;
  sitm.accountgroup:= 0;
  if use_account_groups then sitm.accountgroup:= forts_account_groups.AccountGroup(aorder.account);

  locklist;
  try
    if search(@sitm, idx) then begin
      with pQueueRegItem(items[idx])^ do
        if assigned(queue) then begin
          itm:= new(pOrderQueueItem);
          with itm^ do begin
            action  := actSetOrder;
            trs_id  := aorder.transaction;
            res     := ares;
            order   := aorder;
            comment := acomment;
          end;
          queue.add(itm);
          with ares do begin accepted := soUnknown; ExtNumber:= 0; TEReply:= ''; end;
          result:= true;
        end else begin
          with ares do begin accepted := soRejected; ExtNumber:= 0; TEReply:= errNoQueue; end;
        end;
    end else begin
      with ares do begin accepted := soRejected; ExtNumber:= 0; TEReply:= errNoThreads; end;
    end;
  finally unlocklist; end;
end;

function tFortsTransactionQueue.AddMoveOrder(const amoveorder: tMoveOrder; const acomment: tOrderComment; var ares: tSetOrderResult): boolean;
var sitm : tQueueRegItem;
    idx  : longint;
    itm  : pOrderQueueItem;
begin
  result:= false;
  sitm.level:= amoveorder.level;
  sitm.accountgroup:= 0;
  if use_account_groups then sitm.accountgroup:= forts_account_groups.AccountGroup(amoveorder.account);

  locklist;
  try
    if search(@sitm, idx) then begin
      with pQueueRegItem(items[idx])^ do
        if assigned(queue) then begin
          itm:= new(pOrderQueueItem);
          with itm^ do begin
            action      := actMoveOrder;
            trs_id      := amoveorder.transaction;
            res         := ares;
            moveorder   := amoveorder;
            movecomment := acomment;
          end;
          queue.add(itm);
          with ares do begin accepted := soUnknown; ExtNumber:= 0; TEReply:= ''; end;
          result:= true;
        end else begin
          with ares do begin accepted := soRejected; ExtNumber:= 0; TEReply:= errNoQueue; end;
        end;
    end else begin
      with ares do begin accepted := soRejected; ExtNumber:= 0; TEReply:= errNoThreads; end;
    end;
  finally unlocklist; end;
end;

function tFortsTransactionQueue.AddDropOrder(aorderno: int64; aflags, astock_id: Integer; const alevel: TLevel; const acode: TCode; var ares: tSetOrderResult): boolean;
var sitm : tQueueRegItem;
    idx  : longint;
    itm  : pOrderQueueItem;
begin
  result:= false;
  sitm.level:= alevel;
  sitm.accountgroup:= 0;

  locklist;
  try
    if search(@sitm, idx) then begin
      with pQueueRegItem(items[idx])^ do
        if assigned(queue) then begin
          itm:= new(pOrderQueueItem);
          with itm^ do begin
            action    := actDropOrder;
            trs_id    := aorderno;
            res       := ares;
            orderno   := aorderno;
            dropflags := aflags;
            stock_id  := astock_id;
            level     := alevel;
            code      := acode;
          end;
          queue.add(itm);
          with ares do begin accepted := soUnknown; ExtNumber:= 0; TEReply:= ''; end;
          result:= true;
        end else begin
          with ares do begin accepted := soRejected; ExtNumber:= 0; TEReply:= errNoQueue; end;
        end;
    end else begin
      with ares do begin accepted := soRejected; ExtNumber:= 0; TEReply:= errNoThreads; end;
    end;
  finally unlocklist; end;
end;

function tFortsTransactionQueue.AddDropOrderEx(const adroporder: tDropOrderEx; const acomment: tOrderComment; var ares: tSetOrderResult): boolean;
var sitm : tQueueRegItem;
    idx  : longint;
    itm  : pOrderQueueItem;
begin
  result:= false;
  sitm.level:= adroporder.level;
  sitm.accountgroup:= 0;
  if use_account_groups then sitm.accountgroup:= forts_account_groups.AccountGroup(adroporder.account);

  locklist;
  try
    if search(@sitm, idx) then begin
      with pQueueRegItem(items[idx])^ do
        if assigned(queue) then begin
          itm:= new(pOrderQueueItem);
          with itm^ do begin
            action    := actDropOrder;
            trs_id    := adroporder.transaction;
            res       := ares;
            orderno   := adroporder.orderno;
            dropflags := adroporder.flags;
            stock_id  := adroporder.stock_id;
            level     := adroporder.level;
            code      := adroporder.code;
          end;
          queue.add(itm);
          with ares do begin accepted := soUnknown; ExtNumber:= 0; TEReply:= ''; end;
          result:= true;
        end else begin
          with ares do begin accepted := soRejected; ExtNumber:= 0; TEReply:= errNoQueue; end;
        end;
    end else begin
      with ares do begin accepted := soRejected; ExtNumber:= 0; TEReply:= errNoThreads; end;
    end;
  finally unlocklist; end;
end;


initialization
  forts_transaction_queue:= tFortsTransactionQueue.create;
  forts_account_groups:= tAccountGroupsList.create;

finalization
  if assigned(forts_account_groups) then freeandnil(forts_account_groups);
  if assigned(forts_transaction_queue) then freeandnil(forts_transaction_queue);

end.