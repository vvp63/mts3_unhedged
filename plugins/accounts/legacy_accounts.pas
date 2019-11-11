{$i serverdefs.pas}

unit legacy_accounts;

interface

uses  windows, classes, sysutils,
      sortedlist, lowlevel,
      servertypes, protodef, serverapi,
      tterm_api,
      accountsupport_common;

type  pAccountParams         = ^tAccountParams;
      tAccountParams         = record                              // параметры ресурса на счету
        stock_id             : longint;                            // биржа
        code                 : tCode;                              // код бумаги
        isLiquid             : boolean;                            // признак ликвидности
        liquidlevel          : tLevel;                             // рынок ликвидной бумаги
        ostatok              : currency;                           // остаток ресурса на счету
        addition             : currency;                           // зачисление на счет
        fbuy                 : currency;                           // фактическая покупка
        fsell                : currency;                           // фактическая продажа
        fkomis               : currency;                           // фактическая комиссия
        pbuy                 : currency;                           // плановая покупка
        psell                : currency;                           // плановая продажа
        lpbuym               : currency;                           // плановая покупка ликвидных бумаг (сумма)
        nlbuym               : currency;                           // плфновая покупка неликвидных бумаг (сумма)
        lpsellm              : currency;                           // плановая продажа ликвидных бумаг (сумма)
        pkomis               : currency;                           // плановая комиссия
        ekomis               : currency;                           // плановая комиссия для расчета в SetOrder
        fdbt                 : currency;                           // фактическая задолженность
        pdbt                 : currency;                           // плановая задолженность
        fact                 : currency;                           // фактический остаток
        plan                 : currency;                           // плановый остаток
        afact                : currency;                           // фактический остаток или задолженность
        aplan                : currency;                           // плановый остаток или задолженность
        maxdebts             : currency;                           // максимальная задолженность
        maxpdbts             : currency;                           // максимальная плановая задолженность
        sumdebts             : currency;                           // суммарная задолженность
        reserved             : currency;                           // зарезервировано всего
        res_pos              : currency;                           // зарезервировано под позиции
        res_ord              : currency;                           // зарезервировано под заявки
        negvarmarg           : currency;                           // отрицательная вариационная маржа
        curvarmarg           : currency;                           // текущая вариационная маржа
        ostatokprice         : currency;                           // средняя цена остатка
      end;

type  tFactPlan              = record
        fact,plan            : currency;
        fdbt,pdbt            : currency;
      end;

type  tDebtStatus            = record
        now, inpast          : boolean;
        haslimits            : boolean;
      end;

type  pTradesEx              = ^tTradesEx;
      tTradesEx              = record
        trade                : tTrades;
        lotsize              : longint;
      end;

type  tTradesHolder          = class(tSortedList)
      private
        ffields              : tTradesSet;
      public
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        function    AddTrade(var atrade: tTrades; afields: tTradesSet; alotsize: longint): boolean;
        property    TradesFields: tTradesSet read ffields;
      end;

type  tAccountClass          = class of tBaseAccount;

      tBaseAccount           = class(tSortedList)
      private
        faccount             : tAccount;
        fmargininfo          : tMarginInfo;
        faccounttype         : longint;
        faccountdata         : tStockAccListItm;
      protected
        databuffer           : tMemoryStream;
        trades               : tTradesHolder;
        procedure   nullitem(item:pointer); virtual;
        function    searchadditem(astock_id: longint; acode: ansistring): pAccountParams; virtual;
        function    getindividuallimit(stock_id: longint; const code: tCode): currency; virtual;
        function    getindividuallimitcount: longint; virtual;
        procedure   initaccountparams;
      public
        registered           : boolean;
        constructor create(const aaccount: tAccount); overload; virtual;
        constructor create(const aaccount: tAccount; aaccdata: tStockAccListItm); overload; virtual;
        destructor  destroy; override;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        function    getaccountparams(astock_id: longint; acode: ansistring): tAccountParams; virtual;
        function    dogetaccountsums: tAccountParams; virtual; abstract;
        procedure   calculatemarginglevel(var mlvl: tMarginLevel); virtual; abstract;
        procedure   update(acc: tBaseAccount; ufact, uplan: boolean); virtual; abstract;
        function    debtstatus: tDebtStatus; virtual;
        procedure   updateregistry; virtual; abstract;
        function    hassecurity(astock_id: longint; acode: tCode): boolean; virtual;
        function    getaccountdata(var adatasize: longint): pAnsiChar; virtual; abstract;
        function    getrestsqueueitem: pQueueData; virtual;
        function    getlimitsqueueitem: pQueueData; virtual;
        procedure   initmargininfo; virtual;
        procedure   initindividuallimits; virtual;
        procedure   logAccount;

        function    AddTrade(var atrade: tTrades; afields: tTradesSet; alotsize: longint): boolean; virtual;

        property    account: tAccount read faccount;
        property    stockaccount: tAccount read faccountdata.stockaccount;
        property    margininfo: tMarginInfo read fmargininfo write fmargininfo;
        property    accounttype: longint read faccounttype;
        property    individuallimit[stock_id: longint; const code: tCode]: currency read getindividuallimit;
        property    individuallimitcount: longint read getindividuallimitcount;
      end;

type  pAccRegEntry           = ^tAccRegEntry;
      tAccRegEntry           = record
        account              : tAccount;
        refcount             : longint;
        accountref           : tBaseAccount;
      end;

type  tAccountRegistry       = class(tSortedThreadList)
      private
        fUpdatedAccounts     : tStringList;
        function    on_enumerate_tablerows(atable_id: longint; abuf: pAnsiChar; abufsize: longint; aparams: pAnsiChar; aparamsize: longint): longint;
      public
        constructor create;
        destructor  destroy; override;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        function    getaccount(const aaccount: tAccount): tBaseAccount;
        function    accessaccount(const aaccount: tAccount): tBaseAccount;
        procedure   deleteaccount(const aaccount: tAccount);
        function    accountexists(const aaccount: tAccount): boolean;
        procedure   InitializeRegistry;
        procedure   logstorage;

        function    AddTrade(var atrade: tTrades; afields: tTradesSet): boolean;
        function    GetUpdatedAccountsList(alist: tStringList; areset: boolean): boolean;
      end;

type  pSecListItm            = ^tSecListItm;
      tSecListItm            = record
        stock_id             : longint;
        level                : tLevel;
        code                 : tCode;
        lotsize              : longint;
      end;

      tSecList               = class(tSortedThreadList)
      private
        function    FGetLotSize(astock_id: longint; const alevel: tLevel; const acode: tCode): longint;
        procedure   FSetLotSize(astock_id: longint; const alevel: tLevel; const acode: tCode; alotsize: longint);
      public
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;

        property    lotsize[astock_id: longint; const alevel: tLevel; const acode: tCode]: longint read FGetLotSize write FSetLotSize;
      end;

const defmargininfo          : tMarginInfo = ( normal   : 0.165;
                                               warning  : 0.155;
                                               critical : 0.140 );

var   accountregistry        : tAccountRegistry = nil;
      securitieslist         : tSecList         = nil;

function  CreateAccount(const aaccount: tAccount): tBaseAccount;

function  plgLockAccounts: boolean; stdcall;
function  plgUnlockAccounts: boolean; stdcall;

function  plgGetAccount(aaccount: pointer; accsize: longint): pointer; stdcall;
procedure plgReleaseAccount(aaccount: pointer; accsize: longint); stdcall;
function  plgGetAccountData(aaccount: pointer; accsize: longint; buffer: pAnsiChar; buflen: longint; var actlen: longint): boolean; stdcall;

procedure onTablesUpdate(aEventType: longint; astock_id: longint; alevel: tLevel); cdecl;
procedure onTradesArrived(var trade: tTrades; fields: tTradesSet); cdecl;
procedure onSecuritiesArrived(var sec: tSecurities; fields: TSecuritiesSet); cdecl;

implementation

uses legacy_calcaccount, legacy_prepaccount;

function enumtablerecords_callback(aref: pointer; atable_id: longint; abuf: pAnsiChar; abufsize: longint; aparams: pAnsiChar; aparamsize: longint): longint; stdcall;
begin
  if assigned(aref) and (atable_id = idAccountList) then
    if assigned(abuf) and (abufsize = sizeof(tStockAccListItm)) then pStockAccListItm(aref)^:= pStockAccListItm(abuf)^;
  result:= PLUGIN_ERROR; // only one record expected!
end;

function enumtablerecords_callback2(aref: pointer; atable_id: longint; abuf: pAnsiChar; abufsize: longint; aparams: pAnsiChar; aparamsize: longint): longint; stdcall;
begin
  if assigned(aref) then result:= tAccountRegistry(aref).on_enumerate_tablerows(atable_id, abuf, abufsize, aparams, aparamsize)
                    else result:= PLUGIN_ERROR;
end;

{ tTradesHolder }

procedure tTradesHolder.freeitem(item: pointer);
begin if assigned(item) then dispose(pTrades(item)); end;

function tTradesHolder.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tTradesHolder.compare(item1, item2: pointer): longint;
begin
  result:= cmpi64(pTrades(item1)^.tradeno, pTrades(item2)^.tradeno);
  if (result = 0) then begin
    result:= cmpi64(pTrades(item1)^.orderno, pTrades(item2)^.orderno);
    if (result = 0) then result:= AnsiCompareText(pTrades(item1)^.code, pTrades(item2)^.code); 
  end;
end;

function tTradesHolder.AddTrade(var atrade: tTrades; afields: tTradesSet; alotsize: longint): boolean;
var itm : pTradesEx;
    idx : longint;
begin
  result:= not search(@atrade, idx);
  if result then begin
    itm:= new(pTradesEx);
    itm^.trade:= atrade;
    itm^.lotsize:= alotsize;
    insert(idx, itm);
    ffields:= ffields + afields;
  end;
end;


{ tBaseAccount }

constructor tBaseAccount.create(const aaccount: tAccount);
var accdata : tStockAccListItm;
begin
  fillchar(accdata, sizeof(accdata), 0);
  accdata.stock_id:= -1;
  if assigned(srv_enumtablerecords) then
    srv_enumtablerecords(@accdata, idAccountList, sizeof(tStockAccListItm), @aaccount, sizeof(tAccount), enumtablerecords_callback);
  create(aaccount, accdata);
end;

constructor tBaseAccount.create(const aaccount: tAccount; aaccdata: tStockAccListItm);
begin
  inherited create;
  fduplicates:= dupIgnore; faccount:= aaccount;
  databuffer:= tMemoryStream.create;
  trades:= tTradesHolder.create;
  registered:= false;
  faccountdata:= aaccdata;
  initmargininfo;
end;

destructor tBaseAccount.destroy;
begin
  if assigned(trades) then freeandnil(trades);
  if assigned(databuffer) then freeandnil(databuffer);
  inherited destroy;
end;

procedure tBaseAccount.freeitem;
begin if assigned(item) then dispose(pAccountParams(item)); end;

function tBaseAccount.checkitem;
begin result:= true; end;

function tBaseAccount.compare;
begin
  result:= pAccountParams(item1)^.stock_id - pAccountParams(item2)^.stock_id;
  if (result = 0) then result:= comparetext(pAccountParams(item1)^.code, pAccountParams(item2)^.code);
end;

procedure tBaseAccount.nullitem;
var astockid : longint;
    acode    : tCode;
    aliquid  : boolean;
    alevel   : tLevel;
begin
  if assigned(item) then with pAccountParams(item)^ do begin
    astockid:= stock_id; acode:= code; aliquid:= isliquid; alevel:= liquidlevel;
    fillchar(pAccountParams(item)^, sizeof(tAccountParams), 0);
    stock_id:= astockid; code:= acode; isliquid:= aliquid; liquidlevel:= alevel;
  end;
end;

function tBaseAccount.searchadditem;
var itm : pAccountParams;
    idx : longint;
begin
  itm:= new(pAccountParams); fillchar(itm^, sizeof(tAccountParams), 0);
  with itm^ do begin
    code:= acode;
    if (comparetext(acode, 'MONEY') <> 0) then stock_id:= astock_id;
  end;
  if search(itm,idx) then begin
    result:= items[idx]; dispose(pAccountParams(itm));
  end else begin
    insert(idx, itm); result:= itm;
  end;
end;

function tBaseAccount.getindividuallimit(stock_id: longint; const code: tCode): currency;
begin result:= 0; end;

function tBaseAccount.getindividuallimitcount: longint;
begin result:= 0; end;

function tBaseAccount.getaccountparams;
var itm : tAccountParams;
    idx : longint;
begin
  fillchar(itm, sizeof(tAccountParams), 0);
  itm.stock_id:= astock_id; itm.code:= acode;
  if search(@itm, idx) then result:= pAccountParams(items[idx])^
                       else result:= itm;
end;

function tBaseAccount.debtstatus;
begin with result do begin now:= false; inpast:= false; haslimits:= false; end; end;

function tBaseAccount.hassecurity;
var itm : tAccountParams;
    idx : longint;
begin
  itm.stock_id:= astock_id; itm.code:= acode;
  result:= search(@itm,idx);
end;

function tBaseAccount.getrestsqueueitem:pQueueData;
begin result:= nil; end;

function tBaseAccount.getlimitsqueueitem:pQueueData;
begin result:= nil; end;

procedure tBaseAccount.initmargininfo;
begin fmargininfo:= defmargininfo; end;

procedure tBaseAccount.initaccountparams;
begin
  fillchar(faccountdata, sizeof(faccountdata), 0);
  faccountdata.stock_id:= -1;
  if assigned(srv_enumtablerecords) then
    srv_enumtablerecords(@faccountdata, idAccountList, sizeof(tStockAccListItm), @faccount, sizeof(tAccount), enumtablerecords_callback);
end;

procedure tBaseAccount.initindividuallimits;
begin end;

procedure tBaseAccount.logAccount;
var i  : longint;
    ch : char;
begin
  try
    for i:=0 to count-1 do with pAccountParams(items[i])^ do begin
      if (i = 0) or (i = count-1) then ch:='+' else ch:='|';
      log('%s %-10s %1d %-15s %10m %10m %10m %10m %10m %10m',
          [ch, faccount, stock_id, code, afact, aplan, pbuy, lpbuym, psell, lpsellm]);
    end;
  except on e:exception do log('LogAccount exception: %s', [e.message]); end;
end;

function tBaseAccount.AddTrade(var atrade: tTrades; afields: tTradesSet; alotsize: longint): boolean;
begin result:= assigned(trades) and trades.AddTrade(atrade, afields, alotsize); end;

{ tAccountRegistry }

constructor tAccountRegistry.create;
begin
  inherited create;
  fduplicates:= dupIgnore;
  fUpdatedAccounts:= tStringList.Create;
  with fUpdatedAccounts do begin
    Sorted:= true;
    Duplicates:= classes.dupIgnore;
  end;  
end;

destructor tAccountRegistry.destroy;
begin
  if assigned(fUpdatedAccounts) then freeandnil(fUpdatedAccounts);
  inherited destroy;
end;

procedure tAccountRegistry.freeitem;
begin
  if assigned(item) then begin
    if assigned(pAccRegEntry(item)^.accountref) then freeandnil(pAccRegEntry(item)^.accountref);
    dispose(pAccRegEntry(item));
  end;
end;

function tAccountRegistry.checkitem;
begin result:= true; end;

function tAccountRegistry.compare;
begin result:= AnsiCompareText(pAccRegEntry(item1)^.account, pAccRegEntry(item2)^.account); end;

function tAccountRegistry.getaccount(const aaccount: tAccount): tBaseAccount;
var sitm : tAccRegEntry;
    itm  : pAccRegEntry;
    idx  : longint;
begin
  locklist;
  try
    sitm.account:= aaccount;
    if not search(@sitm, idx) then begin
      itm:= new(pAccRegEntry); itm^.account:= aaccount;
      with itm^ do begin
        accountref:= CreateAccount(account);
        accountref.registered:= true;
        refcount:= 1;
        result:= accountref;
      end;
      insert(idx, itm);
    end else begin
      with pAccRegEntry(items[idx])^ do begin
        inc(refcount); result:= accountref;
      end;
    end;
  finally unlocklist; end;
end;

function tAccountRegistry.accessaccount(const aaccount: tAccount): tBaseAccount;
var itm : tAccRegEntry;
    idx : longint;
begin
  locklist;
  try
    itm.account:= aaccount;
    if search(@itm,idx) then result:= pAccRegEntry(items[idx])^.accountref
                        else result:= nil;
  finally unlocklist; end;
end;

procedure tAccountRegistry.deleteaccount(const aaccount: tAccount);
var itm : tAccRegEntry;
    idx : longint;
begin
  locklist;
  try
    itm.account:= aaccount;
    if search(@itm, idx) then
      with pAccRegEntry(items[idx])^ do try
        dec(refcount);
      finally if (refcount <= 0) then delete(idx); end;
  finally unlocklist; end;
end;

function tAccountRegistry.accountexists(const aaccount: tAccount): boolean;
begin result:= assigned(accessaccount(aaccount)); end;

function tAccountRegistry.on_enumerate_tablerows(atable_id: longint; abuf: pAnsiChar; abufsize: longint; aparams: pAnsiChar; aparamsize: longint): longint;
begin
  if (atable_id = idAccountList) and assigned(abuf) and (abufsize = sizeof(tStockAccListItm)) then
    with pStockAccListItm(abuf)^ do
      if not accountexists(account) then getaccount(account);
  result:= PLUGIN_OK;
end;

procedure tAccountRegistry.InitializeRegistry;
begin
  if assigned(srv_enumtablerecords) then
    srv_enumtablerecords(Self, idAccountList, sizeof(tStockAccListItm), nil, 0, enumtablerecords_callback2);
  logstorage;  
end;

procedure tAccountRegistry.logstorage;
var i : longint;
begin
  locklist;
  try
    log('--- %s', [classname]);
    for i:=0 to count-1 do
      with pAccRegEntry(items[i])^ do log('%d: %s', [refcount, account]);
    log('---');
  finally unlocklist; end;
end;

function tAccountRegistry.AddTrade(var atrade: tTrades; afields: tTradesSet): boolean;
var accnt   : tBaseAccount;
    lotsize : longint;
begin
  if assigned(securitieslist) then lotsize:= securitieslist.lotsize[atrade.stock_id, atrade.level, atrade.code] else lotsize:= 1;
  locklist;
  try
    accnt:= accessaccount(atrade.account);
    result:= assigned(accnt) and accnt.AddTrade(atrade, afields, lotsize);
    if result then fUpdatedAccounts.add(atrade.account);
  finally unlocklist; end;
end;

function tAccountRegistry.GetUpdatedAccountsList(alist: tStringList; areset: boolean): boolean;
begin
  if assigned(alist) then begin
    locklist;
    try
      alist.Assign(fUpdatedAccounts);
      result:= (alist.Count > 0);
      if areset then fUpdatedAccounts.Clear;
    finally unlocklist; end;
  end else result:= false;
end;

{ tSecList }

procedure tSecList.freeitem(item: pointer);
begin if assigned(item) then dispose(pSecListItm(item)); end;

function tSecList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tSecList.compare(item1, item2: pointer): longint;
begin
  result:= pSecListItm(item1)^.stock_id - pSecListItm(item2).stock_id;
  if (result = 0) then begin
    result:= AnsiCompareText(pSecListItm(item1)^.level, pSecListItm(item2)^.level);
    if (result = 0) then result:= AnsiCompareText(pSecListItm(item1)^.code, pSecListItm(item2)^.code);
  end;
end;

function tSecList.FGetLotSize(astock_id: longint; const alevel: tLevel; const acode: tCode): longint;
var itm : tSecListItm;
    idx : longint;
begin
  itm.stock_id := astock_id;
  itm.level    := alevel;
  itm.code     := acode;
  locklist;
  try
    if search(@itm, idx) then result:= max(pSecListItm(items[idx])^.lotsize, 1) else result:= 1;
  finally unlocklist; end;
end;

procedure tSecList.FSetLotSize(astock_id: longint; const alevel: tLevel; const acode: tCode; alotsize: Integer);
var sitm : tSecListItm;
    itm  : pSecListItm;
    idx  : longint;
begin
  sitm.stock_id := astock_id;
  sitm.level    := alevel;
  sitm.code     := acode;
  sitm.lotsize  := max(alotsize, 1);
  locklist;
  try
    if not search(@sitm, idx) then begin
      itm:= new(pSecListItm);
      itm^:= sitm;
      insert(idx, itm);
    end else pSecListItm(items[idx])^.lotsize:= sitm.lotsize;
  finally unlocklist; end;
end;


{ misc. functions }

function createsutableaccount(const aaccount: tAccount; const classes: array of tAccountClass; defaultindex: longint): tBaseAccount;
var data : tStockAccListItm;
    idx  : longint;
begin
  defaultindex:= min(max(low(classes), defaultindex), high(classes));
  data.stock_id:= -1;
  if assigned(srv_enumtablerecords) then
    srv_enumtablerecords(@data, idAccountList, sizeof(tStockAccListItm), @aaccount, sizeof(tAccount), enumtablerecords_callback);
  if (data.stock_id <> -1) then begin
    idx:= data.account_type;
    if not ((idx >= low(classes)) and (idx <= high(classes))) then idx:= defaultindex;
  end else idx:= defaultindex;
  result:= classes[idx].create(aaccount);
  result.faccounttype:= idx;
end;

function CreateAccount(const aaccount: tAccount): tBaseAccount;
begin
  result:= nil;
  try result:= createsutableaccount(aaccount, [tCalculatedAccount, tPreparedAccount], 0);
  except on e:exception do log('CreateAccount: %s exception: %s', [aaccount, e.message]); end;
end;

function  plgLockAccounts: boolean;
begin
  result:= assigned(accountregistry);
  if result then accountregistry.locklist;
end;

function  plgUnlockAccounts: boolean;
begin
  result:= assigned(accountregistry);
  if result then accountregistry.unlocklist;
end;

function plgGetAccount(aaccount: pointer; accsize: longint): pointer;
begin if assigned(accountregistry) and assigned(aaccount) and (accsize = sizeof(tAccount)) then result:= accountregistry.getaccount(pAccount(aaccount)^) else result:= nil; end;

procedure plgReleaseAccount(aaccount: pointer; accsize: longint);
begin if assigned(accountregistry) and assigned(aaccount) and (accsize = sizeof(tAccount)) then accountregistry.deleteaccount(pAccount(aaccount)^); end;

function plgGetAccountData(aaccount: pointer; accsize: longint; buffer: pAnsiChar; buflen: longint; var actlen: longint): boolean;
var account  : tBaseAccount;
    data     : pAnsiChar;
begin
  result:= false; actlen:= 0;
  if assigned(accountregistry) and assigned(aaccount) and (accsize = sizeof(tAccount)) then begin
    plgLockAccounts;
    try
      account:= accountregistry.accessaccount(pAccount(aaccount)^);
      if assigned(account) then begin
        data:= account.getaccountdata(actlen);
        system.move(data^, buffer^, min(buflen, actlen));
        result:= (buflen >= actlen);
      end else log('GetAccountData: %s not found', [pAccount(aaccount)^]);
    finally plgUnlockAccounts; end;
  end;
end;

procedure onTablesUpdate(aEventType: longint; astock_id: longint; alevel: tLevel);
type pptrarray = ^tptrarray;
     tptrarray = array[0..0] of pDataSourceAPI;
var  sl        : tStringList;
     i, j      : longint;
     apis      : pptrarray;
     cnt       : longint;
     acc       : tAccount;
begin
  case aEventType of
//    evEndOrders,
    evEndTrades   : if assigned(accountregistry) then begin
                      sl:= tStringList.Create;
                      try
                        if accountregistry.GetUpdatedAccountsList(sl, true) then
                          if assigned(srv_getapis) and (srv_getapis(pointer(apis), cnt) = PLUGIN_OK) then
                            for i:= 0 to cnt - 1 do
                              if assigned(apis^[i]) and (apis^[i] <> plugin_api) then
                                if (apis^[i]^.plugflags and plEventHandler <> 0) then with apis^[i]^ do
                                  if assigned(eventAPI) and assigned(eventAPI^.evAccountUpdated) then
                                    for j:= 0 to sl.Count - 1 do begin
                                      acc:= sl[j];
                                      eventAPI^.evAccountUpdated(acc);
                                    end;
                      finally sl.free; end;
                    end;
  end
end;

procedure onTradesArrived(var trade: tTrades; fields: tTradesSet);
begin if assigned(accountregistry) then accountregistry.AddTrade(trade, fields); end;

procedure onSecuritiesArrived(var sec: tSecurities; fields: TSecuritiesSet);
begin
  if assigned(securitieslist) and (sec_lotsize in fields) then
    securitieslist.lotsize[sec.stock_id, sec.level, sec.code]:= sec.lotsize;
end;

exports
  plgLockAccounts    name PLG_LockAccount,
  plgUnlockAccounts  name PLG_UnlockAccount,
  plgGetAccount      name PLG_GetAccount,
  plgReleaseAccount  name PLG_ReleaseAccount,
  plgGetAccountData  name PLG_GetAccountData;

initialization
  accountregistry:= tAccountRegistry.create;
  securitieslist:= tSecList.create;

finalization
  if assigned(securitieslist) then freeandnil(securitieslist);
  if assigned(accountregistry) then freeandnil(accountregistry);

end.