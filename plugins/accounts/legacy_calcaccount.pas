{$i serverdefs.pas}

unit legacy_calcaccount;

interface

uses  windows, classes, sysutils,
      servertypes, sortedlist, lowlevel,
      legacy_accounts,
      accountsupport_common;

type  pResourceLimit     = ^tResourceLimit;
      tResourceLimit     = record
        stock_id         : longint;
        code             : tCode;
        limit            : currency;
      end;

type  tResLimitHolder    = class(tSortedList)
        constructor create;
        procedure   freeitem(item:pointer); override;
        function    checkitem(item:pointer):boolean; override;
        function    compare(item1,item2:pointer):longint; override;
        procedure   add(astock_id: longint; const acode: tCode; avalue: currency); reintroduce;
        function    getlimit(astock_id: longint; const acode: tCode): currency;
      end;

type  tCalculatedAccount = class(tBaseAccount)
      private
        fIndLimits       : tResLimitHolder;
      protected
        function    searchadditem(astock_id: longint; acode: ansistring): pAccountParams; override;
        function    getindividuallimit(stock_id: longint; const code: tCode): currency; override;
        function    getindividuallimitcount: longint; override;
      public
        constructor create(const aaccount: tAccount; aaccdata: tStockAccListItm); override;
        destructor  destroy; override;
        procedure   add(item: pointer); override;
        function    dogetaccountsums: tAccountParams; override;
        procedure   calculatemarginglevel(var mlvl: tMarginLevel); override;
        procedure   update(acc: tBaseAccount; ufact, uplan: boolean); override;
        function    debtstatus: tDebtStatus; override;
        procedure   updateregistry; override;
        function    getaccountdata(var adatasize: longint): pAnsiChar; override;
        function    getrestsqueueitem: pQueueData; override;
        function    getlimitsqueueitem: pQueueData; override;
        procedure   initmargininfo; override;
        procedure   initindividuallimits; override;

        function    AddTrade(var atrade: tTrades; afields: tTradesSet; alotsize: longint): boolean; override;
      end;

implementation

{ tResLimitHolder }

constructor tResLimitHolder.create;
begin inherited create; fDuplicates:= dupIgnore; end;

procedure tResLimitHolder.freeitem(item:pointer);
begin if assigned(item) then dispose(pResourceLimit(item)); end;

function tResLimitHolder.checkitem(item:pointer):boolean;
begin result:= assigned(item); end;

function tResLimitHolder.compare(item1,item2:pointer):longint;
begin
  result:= pResourceLimit(item1)^.stock_id - pResourceLimit(item2)^.stock_id;
  if (result = 0) then result:= comparetext(pResourceLimit(item1)^.code, pResourceLimit(item2)^.code);
end;

procedure tResLimitHolder.add(astock_id: longint; const acode: tCode; avalue: currency);
var itm  : tResourceLimit;
    nitm : pResourceLimit;
    idx  : longint;
begin
  itm.stock_id:= astock_id; itm.code:= acode;
  if not search(@itm, idx) then begin
    nitm:= new(pResourceLimit);
    with nitm^ do begin stock_id:= astock_id; code:= acode; limit:= avalue; end;
    insert(idx, nitm);
  end else pResourceLimit(items[idx])^.limit:= avalue;
end;

function tResLimitHolder.getlimit(astock_id: longint; const acode: tCode): currency;
var itm  : tResourceLimit;
    idx  : longint;
begin
  itm.stock_id:= astock_id; itm.code:= acode;
  if search(@itm, idx) then result:= pResourceLimit(items[idx])^.limit else result:= 0;
end;

{ tCalculatedAccount }

constructor tCalculatedAccount.create(const aaccount: tAccount; aaccdata: tStockAccListItm);
begin
  inherited create(aaccount, aaccdata);
  fIndLimits:= tResLimitHolder.create;
  initindividuallimits;
end;

destructor  tCalculatedAccount.destroy;
begin
  if assigned(fIndLimits) then freeandnil(fIndLimits);
  inherited destroy;
end;

procedure tCalculatedAccount.add;
//var tmp : tLevel;
begin
  with pAccountParams(item)^ do
    if (CompareText(code, 'MONEY') = 0) then begin stock_id:= 0; isliquid:= true; end
                                        else isliquid:= false; //LiquidList.isLiquid(stock_id, code, liquidlevel, tmp);
  inherited add(item);
end;

function tCalculatedAccount.searchadditem;
var itm : pAccountParams;
    idx : longint;
//    tmp : tLevel;
begin
  itm:= new(pAccountParams); fillchar(itm^, sizeof(tAccountParams), 0);
  with itm^ do begin
    code:= acode;
    if (comparetext(acode, 'MONEY') <> 0) then stock_id:= astock_id;
  end;
  if search(itm, idx) then begin
    result:= items[idx];
    dispose(pAccountParams(itm));
  end else begin
    with itm^ do isliquid:= (stock_id = 0); //((stock_id = 0) or (assigned(LiquidList) and LiquidList.isLiquid(stock_id, code, liquidlevel, tmp)));
    insert(idx,itm);
    result:=itm;
  end;
end;

function tCalculatedAccount.getindividuallimit(stock_id: longint; const code: tCode): currency;
begin if assigned(fIndLimits) then result:= fIndLimits.getlimit(stock_id, code) else result:= 0; end;

function tCalculatedAccount.getindividuallimitcount: longint;
begin if assigned(fIndLimits) then result:= fIndLimits.count else result:= 0; end;

function tCalculatedAccount.dogetaccountsums;
var bs,typ           : string[1];
    fclientid        : tclientid;
    i                : longint;
    turnover         : currency;
    planturnover     : currency;
    dealvalue        : currency;
    dealsumm         : currency;
    dealkomis        : currency;
begin
  fclientid:= account;

  if (length(fClientId) > 0) then begin
    clear;

    try
      turnover:= 0; planturnover:= 0;

      //--- инициализация ----------------------------------------------
      nullitem(searchadditem(0, 'MONEY'));

      //--- состояние на начало дня ------------------------------------
{
      ExecSQL(q, 'exec AccountRests @account=''%s'', @day=''%s''',
              [account, FormatDateTime('mm/dd/yyyy', date)], false);
      while not q.eof do begin
        with searchadditem(q.fields[0].asinteger, q.fields[1].asstring)^ do begin
          ostatok:= q.fields[2].ascurrency; fact:= ostatok;
          if (ostatok < 0) then begin sumdebts:= abs(ostatok); maxdebts:= sumdebts; end;
          if (q.fieldcount >= 4) then ostatokprice:= q.fields[3].ascurrency;
        end;
        q.next;
      end;
}
      //--- расчет фактических остатков --------------------------------
{
      ExecSQL(q, 'exec calcfact @account=''%s'', @factturnover=%.2f', [account,turnover], false);
      while not q.eof do begin
        bs        := q.fields[3].asstring + ' ';
        dealvalue := q.fields[4].ascurrency;
        dealsumm  := q.fields[5].ascurrency;
        dealkomis := q.fields[6].ascurrency + q.fields[7].ascurrency;
        typ       := q.fields[8].asstring + ' ';
        case upcase(typ[1]) of
          'D' : begin
                  //--- добавление бумаги в портфель ------------------------------
                  with searchadditem(q.fields[0].asinteger, q.fields[2].asstring)^ do begin
                    case upcase(bs[1]) of
                      'B' : begin
                              fbuy     := fbuy     + dealvalue;
                              fact     := fact     + dealvalue;
                            end;
                      'S' : begin
                              fsell    := fsell    + dealvalue;
                              sumdebts := sumdebts + minimize(fact, dealvalue);
                              fact     := fact     - dealvalue;
                            end;
                    end;
                    maxdebts := maxcurr(maxcurr(maxdebts, -1 * fact), 0);
                  end;
                  //--- расчет фактического остатка по деньгам --------------------
                  with searchadditem(0, 'MONEY')^ do begin
                    fkomis   := fkomis   + dealkomis;
                    case upcase(bs[1]) of
                      'B' : begin
                              fbuy     := fbuy     + dealsumm;
                              sumdebts := sumdebts + minimize(fact, dealsumm + dealkomis);
                              fact     := fact     - dealsumm - dealkomis;
                            end;
                      'S' : begin
                              fsell    := fsell    + dealsumm;
                              sumdebts := sumdebts + minimize(fact + dealsumm, dealkomis);
                              fact     := fact     + dealsumm - dealkomis;
                            end;
                    end;
                    maxdebts := maxcurr(maxcurr(maxdebts, -1 * fact), 0);
                  end;
                end;
          'M' : with searchadditem(q.fields[0].asinteger, q.fields[2].asstring)^ do begin
                  case upcase(bs[1]) of
                    'B' : begin
                            addition := addition + dealsumm;
                            fact     := fact     + dealsumm;
                          end;
                    'S' : begin
                            addition := addition - dealsumm;
                            sumdebts := sumdebts + minimize(fact, dealsumm);
                            fact     := fact     - dealsumm;
                          end;
                  end;
                  maxdebts := maxcurr(maxcurr(maxdebts, -1 * fact), 0);
                end;
        end;
        q.next;
      end;
}
      //--- расчет плановых остатков -----------------------------------
{
      ExecSQL(q, 'exec calcplan @account=''%s'', @planturnover=%.2f', [account,planturnover], false);
      while not q.eof do begin
        bs        := q.fields[3].asstring + ' ';
        dealvalue := q.fields[4].ascurrency;
        dealsumm  := q.fields[5].ascurrency;
        dealkomis := q.fields[6].ascurrency + q.fields[7].ascurrency;
        //--- добавление бумаги в портфель ------------------------------
        with searchadditem(q.fields[0].asinteger, q.fields[2].asstring)^ do begin
          pkomis   := pkomis + dealkomis;
          case upcase(bs[1]) of
           'B' : begin
                   pbuy  := pbuy  + dealvalue;
                   if isliquid then lpbuym  := lpbuym + dealsumm
                               else nlbuym  := nlbuym + dealsumm;
                 end;
           'S' : begin
                   psell := psell + dealvalue;
                   if isliquid then lpsellm := lpsellm + dealsumm;
                 end;
          end;
        end;
        //--- расчет планового остатка по деньгам
        with searchadditem(0, 'MONEY')^ do begin
          pkomis   := pkomis + dealkomis;
          case upcase(bs[1]) of
           'B' : begin
                   ekomis   := ekomis + dealkomis;
                   pbuy     := pbuy   + dealsumm;
                   if isliquid then lpbuym  := lpbuym + dealsumm
                               else nlbuym  := nlbuym + dealsumm;
                 end;
           'S' : begin
                   psell    := psell  + dealsumm;
                   if isliquid then lpsellm := lpsellm + dealsumm;
                   if (dealkomis - dealsumm > 0) then ekomis := ekomis + (dealkomis - dealsumm);
                 end;
          end;
        end;
        q.next;
      end;
}
      //--- расчет остатков --------------------------------------------
      for i:=0 to count-1 do with pAccountParams(items[i])^ do begin
        if (stock_id = 0) then begin
          afact    := ostatok + addition + fsell - fbuy - fkomis;
          aplan    := afact + psell - pbuy - pkomis;
          maxpdbts := maxcurr(maxcurr(maxdebts, -1 * (afact - pbuy - ekomis)), 0);
        end else begin
          afact    := ostatok + addition - fsell + fbuy;
          aplan    := afact - psell + pbuy;
          maxpdbts := maxcurr(maxcurr(maxdebts, -1 * (afact - psell)), 0);
        end;
        fact:=maxcurr(afact,0); fdbt:=abs(mincurr(afact,0));
        plan:=maxcurr(aplan,0); pdbt:=abs(mincurr(aplan,0));
      end;

    except on e:exception do log('Exception: %s', [e.message]); end;
  end;

  result:= searchadditem(0, 'MONEY')^;
end;

procedure tCalculatedAccount.calculatemarginglevel(var mlvl: tMarginLevel);
begin
  with mlvl do begin
    account:= self.account;
    factlvl:= 1; planlvl:= 1; minlvl:= 1;
    marginstate:= marginNormal;
    planlvlb:= 1; planlvls:= 1; planlvlmid:= 1; planlvlbn:= 1;
  end;
end;

procedure tCalculatedAccount.update;
var i,j,c : longint;
    itm   : pAccountParams;
begin
  i:=0; j:=0;
  while j<acc.count do begin
    if i<count then begin
      c:=compare(items[i],acc.items[j]);
      if c<0 then begin
        repeat delete(i);
        until (i>=count) or (compare(items[i],acc.items[j])>=0);
      end else
      if c>0 then begin
        itm:=new(pAccountParams);
        itm^:=pAccountParams(acc.items[j])^;
        insert(i,itm);
        inc(i); inc(j);
      end else begin
        with pAccountParams(items[i])^ do begin
          if ufact then begin
            ostatok      := pAccountParams(acc.items[j])^.ostatok;
            addition     := pAccountParams(acc.items[j])^.addition;
            fbuy         := pAccountParams(acc.items[j])^.fbuy;
            fsell        := pAccountParams(acc.items[j])^.fsell;
            fkomis       := pAccountParams(acc.items[j])^.fkomis;
            fact         := pAccountParams(acc.items[j])^.fact;
            afact        := pAccountParams(acc.items[j])^.afact;
            fdbt         := pAccountParams(acc.items[j])^.fdbt;
            maxdebts     := pAccountParams(acc.items[j])^.maxdebts;
            sumdebts     := pAccountParams(acc.items[j])^.sumdebts;
            ostatokprice := pAccountParams(acc.items[j])^.ostatokprice;
          end;
          if uplan then begin
            pbuy         := pAccountParams(acc.items[j])^.pbuy;
            psell        := pAccountParams(acc.items[j])^.psell;
            lpbuym       := pAccountParams(acc.items[j])^.lpbuym;
            nlbuym       := pAccountParams(acc.items[j])^.nlbuym;
            lpsellm      := pAccountParams(acc.items[j])^.lpsellm;
            pkomis       := pAccountParams(acc.items[j])^.pkomis;
            ekomis       := pAccountParams(acc.items[j])^.ekomis;
            plan         := pAccountParams(acc.items[j])^.plan;
            aplan        := pAccountParams(acc.items[j])^.aplan;
            pdbt         := pAccountParams(acc.items[j])^.pdbt;
            maxpdbts     := pAccountParams(acc.items[j])^.maxpdbts;
          end;
        end;
        inc(i); inc(j);
      end;
    end else begin
      itm:=new(pAccountParams);
      itm^:=pAccountParams(acc.items[j])^;
      insert(i,itm);
      inc(i); inc(j);
    end;
  end;
  while i<count do delete(i);
end;

function tCalculatedAccount.debtstatus;
var i : longint;
begin
  i:= 0;
  with result do begin
    now:= false; inpast:= false;
    haslimits:= assigned(fIndLimits) and (fIndLimits.count > 0);
  end;
  while (i < count) and not (result.now and result.inpast) do with pAccountParams(items[i])^ do begin
    if (stock_id = 0) then begin
      if (afact - pbuy - ekomis < 0) then result.now := true;
    end else begin
      if (afact - psell < 0) then result.now := true;
    end;
    if not result.now then begin
      {$ifdef enablemoneymarging}
      if (stock_id <> 0) and (maxpdbts > 0) then result.inpast := true;
      {$else}
      if (maxpdbts > 0) then result.inpast := true;
      {$endif}
    end else result.inpast := true;
    inc(i);
  end;
end;

procedure tCalculatedAccount.updateregistry;
begin
//  if registered then with debtstatus do begin
//    if now                        then mainmarginregistry.add(self) else mainmarginregistry.remove(self);
//    if now or inpast or haslimits then historyregistry.add(self);
//  end;
end;

function tCalculatedAccount.getaccountdata(var adatasize: longint): pAnsiChar;
var i, j   : longint;
    accbuf : tAccountBuf;
    accrow : tAccountRow;
begin
  result:= nil;
  adatasize:= 0;
  if assigned(databuffer) then begin
    j:= Count * sizeof(tAccountRow) + sizeof(tAccountBuf);
    if (databuffer.Size < j) then databuffer.SetSize(j * 2);
    databuffer.seek(0, soFromBeginning);
    accbuf.account:= self.account;
    accbuf.rowcount:= 0;
    databuffer.write(accbuf, sizeof(accbuf));
    j:= 0;
    for i:= 0 to count - 1 do with pAccountParams(items[i])^ do
      if (stock_id = 0) or (plan <> 0) or (fact <> 0) or (pdbt <> 0) or (fdbt <> 0) then begin
        accrow.fields   := [acc_stock_id, acc_code, acc_fact, acc_plan, acc_fdbt, acc_pdbt];
        accrow.stock_id := stock_id;
        accrow.code     := code;
        accrow.fact     := fact;
        accrow.plan     := plan;
        accrow.fdbt     := fdbt;
        accrow.pdbt     := pdbt;
        databuffer.write(accrow, sizeof(accrow));
        inc(j);
      end;
    result:= databuffer.memory;
    adatasize:= databuffer.position;
    if (j > 0) then pAccountBuf(result)^.rowcount:= j;
  end;
end;

function tCalculatedAccount.getrestsqueueitem;
var i   : longint;
    lst : tList;
begin
  result:= nil;
{
  lst:= tList.create;
  try
    for i:= 0 to count - 1 do
      if assigned(items[i]) then with pAccountParams(items[i])^ do
        if (ostatok <> 0) then lst.add(items[i]);
    with lst do
      if (count > 0) then begin
        result:= new(pQueueData);
        with result^ do begin
          id   := idAccountRests;
          cnt  := 1;
          size := sizeof(tAccountRestsBuf) + count * sizeof(tAccountRestsRow);
          data := allocmem(size);
          pAccountRestsBuf(data)^.account:= account;
          pAccountRestsBuf(data)^.rowcount:= count;
          for i:= 0 to count - 1 do with pAccountRestsRow(@data[sizeof(tAccountRestsBuf) + i *sizeof(tAccountRestsRow)])^ do begin
            stock_id := pAccountParams(items[i])^.stock_id;
            code     := pAccountParams(items[i])^.code;
            fact     := pAccountParams(items[i])^.ostatok;
            avgprice := pAccountParams(items[i])^.ostatokprice;
          end;
        end;
      end;
  finally lst.free; end;
}
end;

function tCalculatedAccount.getlimitsqueueitem: pQueueData;
var i : longint;
begin
  result:= nil;
{
  if assigned(fIndLimits) then begin
    result:= new(pQueueData);
    with fIndLimits, result^ do begin
      id   := idIndividualLimits;
      cnt  := 1;
      size := sizeof(tIndLimitsBuf) + count * sizeof(tIndLimitsRow);
      data := allocmem(size);
      pIndLimitsBuf(data)^.account:= account; pIndLimitsBuf(data)^.rowcount:= count;
      for i:= 0 to count - 1 do with pIndLimitsRow(@data[sizeof(tIndLimitsBuf) + i * sizeof(tIndLimitsRow)])^ do begin
        stock_id := pResourceLimit(items[i])^.stock_id;
        code     := pResourceLimit(items[i])^.code;
        limit    := pResourceLimit(items[i])^.limit;
      end;
    end;
  end;
}
end;

procedure tCalculatedAccount.initmargininfo;
begin
  inherited initmargininfo;
  // no individual margin limits now  
end;

procedure tCalculatedAccount.initindividuallimits;
begin
  // no individual limits now
end;

function tCalculatedAccount.AddTrade(var atrade: tTrades; afields: tTradesSet; alotsize: longint): boolean;
begin
  result:= inherited AddTrade(atrade, afields, alotsize);
  if result then begin
    //--- добавление бумаги в портфель ------------------------------
    with searchadditem(atrade.stock_id, atrade.code)^ do begin
      case upcase(atrade.buysell) of
        'B' : begin
                fbuy     := fbuy     + atrade.quantity * alotsize;
                afact    := afact    + atrade.quantity * alotsize;
              end;
        'S' : begin
                fsell    := fsell    + atrade.quantity * alotsize;
                sumdebts := sumdebts + minimize(afact, atrade.quantity * alotsize);
                afact    := afact    - atrade.quantity * alotsize;
              end;
      end;
      maxdebts := maxcurr(maxcurr(maxdebts, -1 * fact), 0);
      fact := maxcurr(afact, 0); fdbt := abs(mincurr(afact, 0));
      plan := maxcurr(aplan, 0); pdbt := abs(mincurr(aplan, 0));
    end;
    //--- расчет фактического остатка по деньгам --------------------
    with searchadditem(0, 'MONEY')^ do begin
      case upcase(atrade.buysell) of
        'B' : begin
                fbuy     := fbuy     + atrade.value;
                afact    := afact    - atrade.value;
              end;
        'S' : begin
                fsell    := fsell    + atrade.value;
                sumdebts := sumdebts + minimize(afact, atrade.value);
                afact    := afact    + atrade.value;
              end;
      end;
      maxdebts := maxcurr(maxcurr(maxdebts, -1 * fact), 0);
      fact := maxcurr(afact, 0); fdbt := abs(mincurr(afact, 0));
      plan := maxcurr(aplan, 0); pdbt := abs(mincurr(aplan, 0));
    end;
  end;
end;

end.
