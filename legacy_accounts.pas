{$i tterm_defs.pas}
{$i serverdefs.pas}

unit  legacy_accounts;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$endif}
      classes, sysutils, math,
      sortedlist,
      servertypes, serverapi,
      legacy_database;

type  tAccountListIdx  = class(tSortedList)
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
      end;

type  tAccountList     = class(tSortedThreadList)
      private
        fAccIndex      : tAccountListIdx;
        function    addrecordcb(avalues: tStringList): boolean;

        function    fGetAccountData(const aaccount: tAccount): pStockAccListItm;
        function    fGetStockAccount(astock_id: longint; const aaccount: tAccount): tAccount;
        function    fGetDefaultAccout(astock_id: longint; const astockaccount: tAccount): tAccount;
      public
        constructor create;
        destructor  destroy; override;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        procedure   InitializeAccounts;

        property    accountdata[const aaccount: tAccount]: pStockAccListItm read fGetAccountData;
        property    stockaccounts[astock_id: longint; const aaccount: tAccount]: tAccount read fGetStockAccount;
        property    defaultaccounts[astock_id: longint; const astockaccount: tAccount]: tAccount read fGetDefaultAccout;
      end;

const StockAccountList : tAccountList = nil;

function  srvGetAccount(const aaccount: tAccount): pointer; cdecl;
function  srvGetAccountData(const aaccount: tAccount; buflen: longint; var buffer; var actlen: longint): boolean; cdecl;
procedure srvReleaseAccount(const aaccount: tAccount); cdecl;

implementation

uses  tterm_api, tterm_pluginsupport, tterm_logger;

{ tAccountListIdx }

procedure tAccountListIdx.freeitem(item: pointer);
begin end;

function tAccountListIdx.checkitem(item: pointer): boolean;
begin result:= assigned(item) and pStockAccListItm(item)^.default; end;

function tAccountListIdx.compare(item1, item2: pointer): longint;
begin
  result:= pStockAccListItm(item1)^.stock_id - pStockAccListItm(item2)^.stock_id;
  if (result = 0) then result:= CompareText(pStockAccListItm(item1)^.stockaccount, pStockAccListItm(item2)^.stockaccount);
end;

{ tAccountList }

constructor tAccountList.create;
begin
  inherited create;
  fduplicates:= dupIgnore;
  fAccIndex:= tAccountListIdx.create;
end;

destructor tAccountList.destroy;
begin
  if assigned(fAccIndex) then freeandnil(fAccIndex);
  inherited destroy;
end;

procedure tAccountList.freeitem(item: pointer);
begin if assigned(item) then dispose(pStockAccListItm(item)); end;

function tAccountList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tAccountList.compare(item1, item2: pointer): longint;
begin
  result:= pStockAccListItm(item1)^.stock_id - pStockAccListItm(item2)^.stock_id;
  if (result = 0) then result:= CompareText(pStockAccListItm(item1)^.account, pStockAccListItm(item2)^.account);
end;

function tAccountList.fGetAccountData(const aaccount: tAccount): pStockAccListItm;
var sitm : tStockAccListItm;
    idx  : longint;
    itm  : pStockAccListItm;
begin
  result:= nil;
  sitm.stock_id:= -1;
  sitm.account:= aaccount;
  locklist;
  try
    idx:= -1;
    search(@sitm, idx);
    if (idx >= 0) and (idx < count) then begin
      itm:= pStockAccListItm(items[idx]);
      if assigned(itm) and (AnsiCompareText(aaccount, itm^.account) = 0) then result:= itm;
    end;
  finally unlocklist; end;
end;

function tAccountList.fGetStockAccount(astock_id: longint; const aaccount: tAccount): tAccount;
var sitm : tStockAccListItm;
    idx  : longint;
begin
  sitm.stock_id:= astock_id;
  sitm.account:= aaccount;
  locklist;
  try
    if search(@sitm, idx) then result:= pStockAccListItm(items[idx])^.stockaccount else result:= aaccount;
  finally unlocklist; end;
end;

function tAccountList.fGetDefaultAccout(astock_id: longint; const astockaccount: tAccount): tAccount;
var sitm : tStockAccListItm;
    idx  : longint;
begin
  result:= astockaccount;
  if assigned(fAccIndex) then begin
    sitm.stock_id:= astock_id;
    sitm.stockaccount:= astockaccount;
    locklist;
    try
      if fAccIndex.search(@sitm, idx) then result:= pStockAccListItm(fAccIndex.items[idx])^.account;
    finally unlocklist; end;
  end;
end;

function tAccountList.addrecordcb(avalues: tStringList): boolean;
var itm : pStockAccListItm;
begin
  result:= assigned(avalues) and (avalues.count >= 6);
  if result then begin
    itm:= new(pStockAccListItm);
    with itm^ do begin
      stock_id     := strtointdef(avalues[0], 0);
      account      := avalues[1];
      marketcode   := avalues[2];
      stockaccount := avalues[3];
      default      := (strtointdef(avalues[4], 0) <> 0);
      account_type := strtointdef(avalues[5], 0);
    end;
    add(itm);
    if assigned(fAccIndex) then fAccIndex.add(itm);
  end;
end;

procedure tAccountList.InitializeAccounts;
begin
  locklist;
  try
    if not db_enumeratetablerecords('stockaccounts', addrecordcb) then log('ERROR: Stock accounts list initialization error');
  finally unlocklist; end;
end;

{ misc. functions }

function  srvGetAccount(const aaccount: tAccount): pointer; cdecl;
begin result:= nil; end;

function  srvGetAccountData(const aaccount: tAccount; buflen: longint; var buffer; var actlen: longint): boolean; cdecl;
var procs    : array of pointer;
    i, count : longint;
begin
  setlength(procs, GetPluginsCount);
  count:= min(GetPluginsProcAddressList(@procs[0], length(procs) * sizeof(pointer), PLG_GetAccountData), length(procs));
  result:= false;
  i:= 0;
  while i < count do begin
    if assigned(procs[i]) then result:= tGetAccountData(procs[i])(@aaccount, sizeof(aaccount), @buffer, buflen, actlen);
    if result then i:= count else inc(i);
  end;
end;

procedure srvReleaseAccount(const aaccount: tAccount); cdecl;
begin end;

exports
  srvGetAccount      name srv_GetAccount,
  srvGetAccountData  name srv_GetAccountData,
  srvReleaseAccount  name srv_ReleaseAccount;

initialization
  StockAccountList:= tAccountList.create;

finalization
  if assigned(StockAccountList) then freeandnil(StockAccountList);

end.