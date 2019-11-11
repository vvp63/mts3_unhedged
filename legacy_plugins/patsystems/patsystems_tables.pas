unit patsystems_tables;

interface

uses  windows, classes, sysutils, inifiles, math, 
      sortedlist,
      ServerTypes, ServerAPI,
      patsystems_common,
      PATSINTF;

type  pLevelItm        = ^tLevelItm;
      tLevelItm        = record
        stockname      : shortstring;
        level          : tLevel;
      end;

      tLevelListIdx    = class(tSortedList)
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
      end;

      tLevelList       = class(tSortedThreadList)
      private
        fIdx           : tLevelListIdx;
        function    fGetByLevel(const alevel: tLevel): shortstring;
        procedure   fSetByLevel(const alevel: tLevel; const astock: shortstring);
        function    fGetByStock(const astock: shortstring): tLevel;
        procedure   fSetByStock(const astock: shortstring; const alevel: tLevel);
      public
        constructor create;
        destructor  destroy; override;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;

        procedure   LoadFromIni(aIni: tIniFile; asection: ansistring);

        property    bylevel[const alevel: tLevel]: shortstring read fGetByLevel write fSetByLevel;
        property    byStock[const astock: shortstring]: tLevel read fGetByStock write fSetByStock;
      end;

type pPriceArray       = ^tPriceArray;
     tPriceArray       = array[0..19] of PriceDetailStruct;

type  pContractItem    = ^tContractItem;
      tContractItem    = record
        level          : tLevel;
        code           : tCode;
        lotsize        : longint;
        contract       : ContractStruct;
        bids           : tPriceArray;
        offers         : tPriceArray;
      end;

      tContractListIdx = class(tSortedList)
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
      end;

      tContractList    = class(tSortedThreadList)
      private
        fIdx           : tContractListIdx;
        fFilter        : tStringList;
        function    fGetContract(const alevel: tLevel; const acode: tCode; var alotsize: longint): ContractStruct;
        function    fGetContractItem(const alevel: tLevel; const acode: tCode): pContractItem;
      public
        constructor create;
        destructor  destroy; override;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;

        procedure   LoadFromIni(aIni: tIniFile; asection: ansistring);

        procedure   InitList;
        function    RegisterContract(const acontract: ContractStruct; const alevel: tLevel; const acode: tCode; var alotsize: longint): boolean;

        property    contracts[const alevel: tLevel; const acode: tCode; var alotsize: longint]: ContractStruct read fGetContract;
        property    contractitems[const alevel: tLevel; const acode: tCode]: pContractItem read fGetContractItem;
      end;

type  pOrderListItm    = ^tOrderListItm;
      tOrderListItm    = record
        orderid        : OrderIDStr;
        set_result     : tSetOrderResult;
      end;

      tOrderList       = class(tSortedThreadList)
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;

        procedure   push(aid: OrderIDPtr; var res: tSetOrderResult);
        function    pop(aid: OrderIDPtr; var res: tSetOrderResult): boolean;

        procedure   InitList;
      end;

procedure PriceUpdate(PriceUpdate: PriceUpdStructPtr); stdcall;
procedure DOMUpdate(DOMUpdate: DOMUpdStructPtr); stdcall;

procedure AddSecurity(const acontract: ContractStruct);
procedure AddOrder(const aorderdetail: OrderDetailStruct);
procedure AddTrade(const afilldetail: FillStruct; atransaction: int64);

procedure LoadStaticData;

const level_list    : tLevelList = nil;
      contract_list : tContractList = nil;
      order_list    : tOrderList = nil;

implementation

const lastpricecallback : cardinal = 0;

procedure UpdateDOMData(contractitem: pContractItem; var CurrentPrice: PriceStruct);
var cflag  : boolean;
    kot    : tKotirovki;
    i, lsz : longint;
    tmp    : extended;
begin
  if assigned(contractitem) then begin
    with contractitem^ do begin
      kot.stock_id := GetPatsStockID;
      kot.level    := level;
      kot.code     := code;
      lsz:= max(1, lotsize);
    end;
    with CurrentPrice do begin
      cflag:= (ChangeMask and ptChangeBidDOM <> 0) or (ChangeMask and ptChangeOfferDOM <> 0);
      if (ChangeMask and ptChangeBidDOM <> 0) then move(BidDOM0, contractitem^.bids, sizeof(contractitem^.bids));
      if (ChangeMask and ptChangeOfferDOM <> 0) then move(OfferDOM0, contractitem^.offers, sizeof(contractitem^.offers));
      if cflag then begin
        Server_API.LockKotirovki;
        try
          Server_API.ClearKotirovkiTbl(kot, clrByStruct);

          with contractitem^ do begin
            kot.buysell  := 'B';
            for i:= 19 downto 0 do with bids[i] do
              if (Volume > 0) and TextToFloat(@Price, tmp, fvExtended) then begin
                kot.price:= tmp / lsz;
                kot.quantity:= Volume;
                Server_API.AddKotirovkiRec(kot);
              end;

            kot.buysell  := 'S';
            for i:= 0 to 19 do with offers[i] do
              if (Volume > 0) and TextToFloat(@Price, tmp, fvExtended) then begin
                kot.price:= tmp / lsz;
                kot.quantity:= Volume;
                Server_API.AddKotirovkiRec(kot);
              end;
          end;

        finally Server_API.UnlockKotirovki; end;
      end;
    end;
  end;
end;

procedure PriceUpdate(PriceUpdate: PriceUpdStructPtr); stdcall;
var  CurrentPrice : PriceStruct;
     sec          : tSecurities;
     secset       : tSecuritiesSet;
     tmp          : extended;
     lsz          : longint;
     contractitem : pContractItem;
begin
  lastpricecallback:= GetTickCount;
  with PriceUpdate^ do begin
    sec.stock_id:= GetPatsStockID;
    sec.level:= level_list.byStock[ExchangeName];
    if (length(sec.level) > 0) then begin
      sec.code:= format('%s%s', [ContractName, ContractDate]);

      contractitem:= contract_list.contractitems[sec.level, sec.code];
      if assigned(contractitem) then begin
        lsz:= max(1, contractitem^.lotsize);
        secset:= [sec_stock_id, sec_level, sec_code];

        if (ptGetPriceForContract(@ExchangeName, @ContractName, @ContractDate, @CurrentPrice) = ptSuccess) then begin
          with CurrentPrice do begin
            if (ChangeMask and ptChangeBid <> 0) and TextToFloat(@Bid.Price, tmp, fvExtended) then begin sec.hibid:= tmp / lsz; include(secset, sec_hibid); end;
            if (ChangeMask and ptChangeOffer <> 0) and TextToFloat(@Offer.Price, tmp, fvExtended) then begin sec.lowoffer:= tmp / lsz; include(secset, sec_lowoffer); end;
            if (ChangeMask and ptChangeLast <> 0) then begin
              if TextToFloat(@Last0.Price, tmp, fvExtended) then begin sec.lastdealprice:= tmp / lsz; include(secset, sec_lastdealprice); end;
              sec.lastdealqty:= Last0.Volume; include(secset, sec_lastdealqty);
              sec.lastdealtime:= EncodeTime(Last0.Hour, Last0.Minute, Last0.Second, 0); include(secset, sec_lastdealtime);
            end;
            if (ChangeMask and ptChangeHigh <> 0) and TextToFloat(@High.Price, tmp, fvExtended) then begin sec.maxprice:= tmp / lsz; include(secset, sec_maxprice); end;
            if (ChangeMask and ptChangeLow <> 0) and TextToFloat(@Low.Price, tmp, fvExtended) then begin sec.minprice:= tmp / lsz; include(secset, sec_minprice); end;
            if (ChangeMask and ptChangeOpening <> 0) and TextToFloat(@Opening.Price, tmp, fvExtended) then begin sec.initprice:= tmp / lsz; include(secset, sec_initprice); end;
            if (ChangeMask and ptChangeClosing <> 0) and TextToFloat(@Closing.Price, tmp, fvExtended) then begin sec.closeprice:= tmp / lsz; include(secset, sec_closeprice); end;
            if (ChangeMask and ptChangeTotal <> 0) then begin sec.amount:= Total.Volume; include(secset, sec_amount); end;

//            if TextToFloat(@LimitUp.Price, tmp, fvExtended) then begin sec.limitpricehigh:= tmp / lsz; include(secset, sec_limitpricehigh); end;
//            if TextToFloat(@LimitDown.Price, tmp, fvExtended) then begin sec.limitpricelow:= tmp / lsz; include(secset, sec_limitpricelow); end;

            Server_API.AddSecuritiesRec(sec, secset);
          end;
          if is_demo then UpdateDOMData(contractitem, CurrentPrice);
        end;  
      end;
    end;
  end;
end;

procedure DOMUpdate(DOMUpdate: DOMUpdStructPtr); stdcall;
var  CurrentPrice : PriceStruct;
     contractitem : pContractItem;
     level        : tLevel;
     code         : tCode;
begin
  if (GetTickCount - lastpricecallback <> 0) then begin
   with DOMUpdate^ do begin
     level:= level_list.byStock[ExchangeName];
     if (length(level) > 0) then begin
       code:= format('%s%s', [ContractName, ContractDate]);

       contractitem:= contract_list.contractitems[level, code];
       if assigned(contractitem) then
         if (ptGetPriceForContract(@ExchangeName, @ContractName, @ContractDate, @CurrentPrice) = ptSuccess) then UpdateDOMData(contractitem, CurrentPrice);
     end;
   end;
  end else lastpricecallback:= 0;
end;

procedure AddSecurity(const acontract: ContractStruct);
var  sec    : tSecurities;
     secset : tSecuritiesSet;
     tmp    : extended;
     lsz    : longint;
begin
  fillchar(sec, sizeof(sec), 0);
  
  sec.stock_id:= GetPatsStockID;
  sec.level:= level_list.byStock[acontract.ExchangeName];
  if (length(sec.level) > 0) then begin
    secset:= [sec_stock_id, sec_level, sec_code, sec_shortname, sec_lotsize, sec_decimals, sec_tradingstatus];

    sec.code:= format('%s%s', [acontract.ContractName, acontract.ContractDate]);
    sec.shortname:= format('%s %s', [acontract.ContractName, acontract.ContractDate]);
    if (acontract.Tradable = 'Y') then sec.tradingstatus:= 'T' else sec.tradingstatus:= 'N';

    if assigned(contract_list) then
      if contract_list.RegisterContract(acontract, sec.level, sec.code, sec.lotsize) then begin

        lsz:= max(1, sec.lotsize);

        sec.decimals:= round(Log10(acontract.TicksPerPoint) + Log10(sec.lotsize));
        if TextToFloat(@acontract.TickSize, tmp, fvExtended) then begin sec.pricestep:= tmp / lsz; include(secset, sec_pricestep); end;

        Server_API.AddSecuritiesRec(sec, secset);

        if(ptSubscribePrice(@acontract.ExchangeName, @acontract.ContractName, @acontract.ContractDate) <> ptSuccess) then begin
          log('Failed to subscribe prices: Exchange=%s Commodity=%s Contract=%s', [acontract.ExchangeName, acontract.ContractName, acontract.ContractDate]);
        end;

//      log('Contract %d Exchange=%s Commodity=%s Contract=%s Expiry=%s TickPerPoint=%d TickSize=%s Tradeable=%s',
//          [i, contract.ExchangeName, contract.ContractName, contract.ContractDate, contract.ExpiryDate, contract.TicksPerPoint, contract.TickSize, contract.Tradable]);
    end;
  end;
end;

procedure AddOrder(const aorderdetail: OrderDetailStruct);
var ord          : tOrders;
    ordset       : tOrdersSet;
    tmp          : extended;
    lsz          : longint;
    contractitem : pContractItem;
begin
  fillchar(ord, sizeof(ord), 0);

  ord.transaction := aorderdetail.XrefP;
  ord.stock_id    := GetPatsStockID;
  ord.level       := level_list.byStock[aorderdetail.ExchangeName];
  ord.code        := format('%s%s', [aorderdetail.ContractName, aorderdetail.ContractDate]);

  contractitem:= contract_list.contractitems[ord.level, ord.code];
  if assigned(contractitem) then lsz:= max(1, contractitem^.lotsize) else lsz:= 1;

  ord.orderno     := StrToInt64Def(aorderdetail.OrderID, 0);
  ord.account     := aorderdetail.TraderAccount;
  ord.buysell     := aorderdetail.BuyOrSell;
  ord.quantity    := aorderdetail.Lots;
  ord.balance     := aorderdetail.Lots - aorderdetail.AmountFilled;
  if TextToFloat(@aorderdetail.Price, tmp, fvExtended) then ord.price:= tmp / lsz else ord.price:= 0;
  ord.value       := ord.price * ord.quantity * lsz;
  ord.ordertime   := decodedatetime(aorderdetail.DateExchRecd, aorderdetail.TimeExchRecd);

  case aorderdetail.Status of
    ptWorking,
    ptPartFilled,
    ptCancelPending,
    ptAmendPending,
    ptUnconfirmedFilled,
    ptUnconfirmedPartFilled,
    ptHeldOrder,
    ptTransferred            : ord.status:= 'O';
    ptBalCancelled,
    ptCancelHeldOrder,
    ptCancelled              : ord.status:= 'W';
    ptFilled                 : ord.status:= 'M';
    ptExternalCancelled      : ord.status:= 'C';
  end;

  ordset:= [ord_stock_id, ord_level, ord_code, ord_orderno, ord_account, ord_buysell,
            ord_quantity, ord_balance, ord_price, ord_value, ord_status, ord_ordertime];

  Server_API.AddOrdersRec(ord, ordset);
end;

procedure AddTrade(const afilldetail: FillStruct; atransaction: int64);
var trd          : tTrades;
    trdset       : tTradesSet;
    tmp          : extended;
    lsz          : longint;
    contractitem : pContractItem;
begin
  fillchar(trd, sizeof(trd), 0);

  trd.transaction := atransaction;
  trd.stock_id    := GetPatsStockID;
  trd.level       := level_list.byStock[afilldetail.ExchangeName];
  trd.code        := format('%s%s', [afilldetail.ContractName, afilldetail.ContractDate]);

  contractitem:= contract_list.contractitems[trd.level, trd.code];
  if assigned(contractitem) then lsz:= max(1, contractitem^.lotsize) else lsz:= 1;

  trd.tradeno     := decodefillid(afilldetail.FillID);
  trd.orderno     := StrToInt64Def(afilldetail.OrderID, 0);
  trd.account     := afilldetail.TraderAccount;
  trd.buysell     := afilldetail.BuyOrSell;
  trd.quantity    := afilldetail.Lots;
  if TextToFloat(@afilldetail.Price, tmp, fvExtended) then trd.price:= tmp / lsz else trd.price:= 0;
  trd.value       := trd.price * trd.quantity * lsz;
  trd.tradetime   := decodedatetime(afilldetail.DateFilled, afilldetail.TimeFilled);

  trdset:= [trd_stock_id, trd_tradeno, trd_orderno, trd_tradetime, trd_level, trd_code,
            trd_buysell, trd_account, trd_price, trd_quantity, trd_value];

  Server_API.AddTradesRec(trd, trdset);
end;

procedure LoadStaticData;
var  i, count       : longint;
     contract       : ContractStruct;
     trader         : TraderAcctStruct;
     orderdetail    : OrderDetailStruct;
     filldetail     : FillStruct;
begin
  if assigned(contract_list) then contract_list.InitList;

  ptCountTraders(@count);
  for i:= 0 to count - 1 do
    if (ptGetTrader(i, @trader) = ptSuccess) then
      log('Avaliable account: "%s"; tradeable: %s', [trader.TraderAccount, trader.Tradable]);

  ptCountContracts(@count);
  for i:= 0 to count - 1 do begin
    if (ptGetContract(i, @contract) = ptSuccess) then AddSecurity(contract);
  end;

  if assigned(Server_API.OrdersBeginUpdate) then Server_API.OrdersBeginUpdate(GetPatsStockID, '');
  try
    ptCountOrders(@count);
    for i:= 0 to count - 1 do begin
      if (ptGetOrder(i, @orderdetail) = ptSuccess) then AddOrder(orderdetail);
    end;
  finally if assigned(Server_API.OrdersEndUpdate) then Server_API.OrdersEndUpdate(GetPatsStockID, ''); end;

  if assigned(Server_API.TradesBeginUpdate) then Server_API.TradesBeginUpdate(patsid, '');
  try
    ptCountFills(@count);
    for i:= 0 to count - 1 do
      if (ptGetFill(i, @filldetail) = ptSuccess) then begin
        if StrLComp(filldetail.OrderID, '0', sizeof(filldetail.OrderID)) <> 0 then begin
          if (ptGetOrderByID(@filldetail.OrderID, @orderdetail, 0) <> ptSuccess) then orderdetail.XrefP:= 0;
          AddTrade(filldetail, orderdetail.XrefP);
        end;
      end;
  finally if assigned(Server_API.TradesEndUpdate) then Server_API.TradesEndUpdate(patsid, ''); end;
end;

{ tLevelListIdx }

procedure tLevelListIdx.freeitem(item: pointer);
begin end;

function tLevelListIdx.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tLevelListIdx.compare(item1, item2: pointer): longint;
begin result:= CompareStr(pLevelItm(item1)^.level, pLevelItm(item2)^.level); end;

{ tLevelList }

constructor tLevelList.create;
begin
  inherited create;
  fIdx:= tLevelListIdx.create;
  fIdx.fDuplicates:= dupIgnore;
end;

destructor tLevelList.destroy;
begin
  if assigned(fIdx) then freeandnil(fIdx);
  inherited destroy;
end;

procedure tLevelList.freeitem(item: pointer);
begin
  if assigned(item) then begin
    if assigned(fIdx) then fIdx.remove(item);
    dispose(pLevelItm(item));
  end;
end;

function tLevelList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tLevelList.compare(item1, item2: pointer): longint;
begin result:= CompareStr(pLevelItm(item1)^.stockname, pLevelItm(item2)^.stockname); end;

function tLevelList.fGetByLevel(const alevel: tLevel): shortstring;
var sitm : tLevelItm;
    idx  : longint;
begin
  locklist;
  try
    sitm.level:= alevel;
    if assigned(fIdx) then with fIdx do begin
      if search(@sitm, idx) then result:= pLevelItm(items[idx])^.stockname else setlength(result, 0);
    end else setlength(result, 0);
  finally unlocklist; end;
end;

function tLevelList.fGetByStock(const astock: shortstring): tLevel;
var sitm : tLevelItm;
    idx  : longint;
begin
  locklist;
  try
    sitm.stockname:= astock;
    if search(@sitm, idx) then result:= pLevelItm(items[idx])^.level else setlength(result, 0);
  finally unlocklist; end;
end;

procedure tLevelList.fSetByLevel(const alevel: tLevel; const astock: shortstring);
begin fSetByStock(astock, alevel); end;

procedure tLevelList.fSetByStock(const astock: shortstring; const alevel: tLevel);
var sitm : tLevelItm;
    idx  : longint;
    itm  : pLevelItm;
begin
  if (length(astock) > 0) and (length(alevel) > 0) then begin
    locklist;
    try
      sitm.stockname:= astock;
      if not search(@sitm, idx) then begin
        itm:= new(pLevelItm);
        itm^.stockname:= astock;
        itm^.level:= alevel;
        insert(idx, itm);
        if assigned(fIdx) then fIdx.add(itm);
      end;
    finally unlocklist; end;
  end;
end;

procedure tLevelList.LoadFromIni(aIni: tIniFile; asection: ansistring);
var KeyList : tStringList;
    i       : longint;
begin
  if assigned(aini) then with aini do begin

    with locklist do try
      clear;
    finally unlocklist; end;

    KeyList := tStringList.Create;
    try
      ReadSection(asection, KeyList);
      for i:= 0 to KeyList.Count - 1 do byStock[keylist[i]]:= ReadString(asection, KeyList[I], '');
    finally KeyList.Free; end;
  end;
end;

{ tContractListIdx }

procedure tContractListIdx.freeitem(item: pointer);
begin end;

function tContractListIdx.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tContractListIdx.compare(item1, item2: pointer): longint;
begin
  result:= CompareStr(pContractItem(item1)^.level, pContractItem(item2)^.level);
  if (result = 0) then result:= CompareStr(pContractItem(item1)^.code, pContractItem(item2)^.code);
end;

{ tContractList }

constructor tContractList.create;
begin
  inherited create;
  fIdx:= tContractListIdx.create;
  fIdx.fDuplicates:= dupIgnore;
end;

destructor tContractList.destroy;
begin
  if assigned(fIdx) then freeandnil(fIdx);
  if assigned(fFilter) then freeandnil(fFilter);
  inherited destroy;
end;

procedure tContractList.freeitem(item: pointer);
begin if assigned(item) then dispose(pContractItem(item)); end;

function tContractList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tContractList.compare(item1, item2: pointer): longint;
begin
  result:= StrLComp(@pContractItem(item1)^.contract.ContractName, @pContractItem(item2)^.contract.ContractName, sizeof(pContractItem(item1)^.contract.ContractName));
  if (result = 0) then begin
    result:= StrLComp(@pContractItem(item1)^.contract.ContractDate, @pContractItem(item2)^.contract.ContractDate, sizeof(pContractItem(item1)^.contract.ContractDate));
    if (result = 0) then result:= StrLComp(@pContractItem(item1)^.contract.ExchangeName, @pContractItem(item2)^.contract.ExchangeName, sizeof(pContractItem(item1)^.contract.ExchangeName));
  end;
end;


function tContractList.RegisterContract(const acontract: ContractStruct; const alevel: tLevel; const acode: tCode; var alotsize: longint): boolean;
var sitm : tContractItem;
    idx  : longint;
    itm  : pContractItem;
    tmps : ansistring;
    f    : boolean;
begin
  result:= false;
  if (length(alevel) > 0) and (length(acode) > 0) then begin
    locklist;
    try
      with acontract do tmps:= format('%s\%s\%s', [ExchangeName, ContractName, ContractDate]);
      if assigned(fFilter) then begin
        alotsize:= strtointdef(fFilter.Values[tmps], 0);
        f:= (alotsize > 0);
      end else begin
        alotsize:= 1;
        f:= true;
      end;
      if f then begin
        sitm.contract:= acontract;
        if not search(@sitm, idx) then begin
          itm:= new(pContractItem);
          fillchar(itm^, sizeof(tContractItem), 0);
          itm^.level    := alevel;
          itm^.code     := acode;
          itm^.lotsize  := alotsize;
          itm^.contract := acontract;
          insert(idx, itm);
          if assigned(fIdx) then fIdx.add(itm);
          result:= true;
        end;
      end;
    finally unlocklist; end;
  end;
end;

function tContractList.fGetContract(const alevel: tLevel; const acode: tCode; var alotsize: longint): ContractStruct;
var sitm : tContractItem;
    idx  : longint;
begin
  locklist;
  try
    sitm.level:= alevel;
    sitm.code:= acode;
    if assigned(fIdx) then with fIdx do begin
      if search(@sitm, idx) then begin
        alotsize := pContractItem(items[idx])^.lotsize;
        result   := pContractItem(items[idx])^.contract;
      end else fillchar(result, sizeof(result), 0);
    end;
  finally unlocklist; end;
end;

function tContractList.fGetContractItem(const alevel: tLevel; const acode: tCode): pContractItem;
var sitm : tContractItem;
    idx  : longint;
begin
  result:= nil;
  locklist;
  try
    sitm.level:= alevel;
    sitm.code:= acode;
    if assigned(fIdx) then with fIdx do begin
      if search(@sitm, idx) then result:= pContractItem(items[idx]);
    end;
  finally unlocklist; end;
end;


procedure tContractList.InitList;
begin
  with locklist do try
    clear;
  finally unlocklist; end;
end;

procedure tContractList.LoadFromIni(aIni: tIniFile; asection: ansistring);
begin
  if assigned(aini) then with aini do begin
    if not assigned(fFilter) then fFilter:= tStringList.Create;
    if assigned(fFilter) then ReadSectionValues(asection, fFilter);
  end;
end;

{ tOrderList }

procedure tOrderList.freeitem(item: pointer);
begin if assigned(item) then dispose(pOrderListItm(item)); end;

function tOrderList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tOrderList.compare(item1, item2: pointer): longint;
begin result:= StrLComp(pOrderListItm(item1)^.orderid, pOrderListItm(item2)^.orderid, sizeof(OrderID)); end;

procedure tOrderList.push(aid: OrderIDPtr; var res: tSetOrderResult);
var itm : pOrderListItm;
    idx : longint;
begin
  locklist;
  try
    if not search(aid, idx) then begin
      itm:= new(pOrderListItm);
      StrLCopy(@pOrderListItm(itm)^.orderid, pAnsiChar(aid), sizeof(OrderID));
      pOrderListItm(itm)^.set_result:= res;
      insert(idx, itm);
    end;
  finally unlocklist; end;
end;

function tOrderList.pop(aid: OrderIDPtr; var res: tSetOrderResult): boolean;
var sitm : tOrderListItm;
    idx  : longint;
begin
  locklist;
  try
    StrLCopy(@sitm.orderid, pAnsiChar(aid), sizeof(OrderID));
    result:= search(@sitm, idx);
    if result then begin
      res:= pOrderListItm(items[idx])^.set_result;
      delete(idx);
    end;
  finally unlocklist; end;
end;

procedure tOrderList.InitList;
begin
  with locklist do try
    clear;
  finally unlocklist; end;
end;

initialization
  order_list:= tOrderList.Create;
  level_list:= tLevelList.Create;
  contract_list:= tContractList.Create;

finalization
  if assigned(contract_list) then freeandnil(contract_list);
  if assigned(level_list) then freeandnil(level_list);
  if assigned(order_list) then freeandnil(order_list);

end.