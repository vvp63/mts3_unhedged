unit mts3lx_securities;

interface

uses {$ifdef MSWINDOWS}
        windows,
      {$else}
        cmem,
        cthreads,
      {$endif}
      dynlibs,
      sysutils,
      classes,
      strings,
      fclinifiles,
      postgres,
      sortedlist,
      servertypes,
      mts3lx_start,
      mts3lx_common;

//    Котировки



type pQuoteItem  = ^tQuoteItem;
     tQuoteItem  = record
       price              : real;
       quantity           : longint;
     end;

type pTradeParams = ^tTradeParams;
      tTradeParams  = record
        LotSize         :   longint;
        PriceStep       :   real;
        PriceDriver     :   real;
        ActiveTime      :   longint;
        VolOff          :   longint;
        Vmin            :   longint;
        Vmax            :   longint;
        Mlow            :   real;
        Mhigh           :   real;
        ForcedActivity  :   boolean;
      end;


type tQuote = class(tSortedList)
      direction   : smallint;   //  1 Ask, -1 Bid
      constructor create(adir  : smallint); overload;
      procedure   freeitem(item: pointer); override;
      function    checkitem(item: pointer): boolean; override;
      function    compare(item1, item2: pointer): longint; override;
      function    GetLog  : string;

    private
      procedure   AddQuote(aprice : real; aquantity : longint);
    public
      function    PriceToVol(avol : longint)  : real;
      function    MeanPrice(avoloff, aquantity  : longint) : real;
      //  Количество уровней и объем до указанной цены
      function    PLVolBefore(aprice : real; akf : longint; var avol  : longint)  : longint;
    end;

type pQuote   = ^tQuote;



//    Бумаги

type tSec  = class(TObject)
    SecurityId  : longint;
    code        : string[50];
    level       : string[10];
    stockid     : longint;
    Account     : tAccount;
    SecType     : string[1];
    Params      : tSecurities;
    Bid         : tQuote;
    Ask         : tQuote;
    TradeParams : tTradeParams;
    LastQuoteTime   : tdatetime;
    LastParamTime   : tdatetime;
    QuoteSaveTime   : tdatetime;

    constructor create(asecid : longint; const acode: tCode; const alevel: tLevel; astockid: longint;
                      const asectype : string; const aaccount : tAccount); overload;
    procedure   KillKross;
  public
    procedure LogSec;
    procedure LogQuotes;
    procedure GetTradeParams;
    function  BasePrice(avol  : longint; aquote : char; alastdeal : boolean = false) : real;
    function  AdditionPrice(avol: real; aquote: char; alastdeal : boolean = false) : real;
    function  IsActive(alog: boolean = true)  : boolean;
    function  NormalizePrice(aprice : real) : real;
end;

type pSec  = ^tSec;


//    Список бумаг

type tSecList = class(tSortedThreadList)
        constructor   create;
        procedure     freeitem(item: pointer); override;
        function      checkitem(item: pointer): boolean; override;
        function      compare(item1, item2: pointer): longint; override;
        function      CheckFilter(const acode: tCode; const alevel: tLevel; astockid: longint)  : boolean;
        procedure     SetParams(const aParams : tSecurities);
        procedure     ProcessQuote(aHeader  : tKotUpdateHdr; aItems : array of tKotUpdateItem);
     private
        procedure     LoadFromDB;
        function      GetSecurity(const acode: tCode; const alevel: tLevel; astockid: longint; var aSec  : tSec): boolean;
     public
        function      GetSecById(aid: longint)  : pSec;
end;


procedure InitMTSSec;
procedure DoneMTSSec;


const SecList     : tSecList = nil;


implementation

uses mts3lx_tp;


{ tQuote }

constructor tQuote.create(adir: smallint);
begin
  inherited create;
  direction :=  adir;
end;

function tQuote.checkitem(item: pointer): boolean;
begin
  result:=  assigned(item);
end;

procedure tQuote.freeitem(item: pointer);
begin
  if assigned(item) then dispose(pQuoteItem(item));
end;

function tQuote.compare(item1, item2: pointer): longint;
var vCompVal : longint;
begin
  vCompVal  :=  0;
  if (pQuoteItem(item1)^.price > pQuoteItem(item2)^.price) then vCompVal  :=  1;
  if (pQuoteItem(item1)^.price < pQuoteItem(item2)^.price) then vCompVal  :=  -1;
  result:=  direction * vCompVal;

  //result:=  direction * CompareValue(pQuoteItem(item1)^.price, pQuoteItem(item2)^.price);
  
end;


procedure tQuote.AddQuote(aprice: real; aquantity: longint);
var vpQuoteItem   : pQuoteItem;
begin
  new(vpQuoteItem);
  with pQuoteItem(vpQuoteItem)^ do begin
    quantity:=  aquantity; price:=  aprice;
  end;
  add(vpQuoteItem);
end;

function tQuote.GetLog: string;
var i : longint;
begin
  result:=  format('[%d] ', [Count]);
  for i:= 0 to min(QuoteLogLength, Count) - 1 do
      with pQuoteItem(items[i])^ do result:= result + format('%.6g/%d ', [price, quantity]);
end;

//  Цена к объему
function tQuote.PriceToVol(avol: longint): real;
var i, vvol : longint;
begin
  result:=  -1; vvol:=  0;
  for i:= 0 to Count - 1 do begin
    inc(vvol, pQuoteItem(items[i])^.quantity);
    if (vvol > avol) then begin
      result:= pQuoteItem(items[i])^.price; break;
    end;
  end;
  FileLog('Quote.PriceToVol %d (%d) = %.6g', [avol, vvol, Result], 4);
end;


function tQuote.MeanPrice(avoloff, aquantity: longint): real;
var vrestmp : real;
    i, vvoloffed, vvolcounted, vcurrvol, vvoluse  : longint;
begin
  result:=  -1; vrestmp:=  0; vvoloffed:=  0; vvolcounted:=  0;
  for i:= 0 to Count - 1 do begin
    vcurrvol:=  pQuoteItem(items[i])^.quantity;
    if (vvoloffed < avoloff) then begin
      vvoluse:= min(vcurrvol, avoloff - vvoloffed);
      inc(vvoloffed, vvoluse);
      dec(vcurrvol, vvoluse);
    end;
    if (vvoloffed >= avoloff) then begin
      vvoluse:= min(vcurrvol, aquantity - vvolcounted);
      vrestmp:= vrestmp + vvoluse * pQuoteItem(items[i])^.price;
      inc(vvolcounted, vvoluse);
    end;
    if (vvolcounted = aquantity) and (aquantity > 0) then Result:=  vrestmp / aquantity;
  end;
  FileLog('Quote.MeanPrice %d %d (%d %d) = %.6g', [avoloff, aquantity, vvoloffed, vvolcounted, Result], 4);
end;

function tQuote.PLVolBefore(aprice: real; akf: longint; var avol: longint): longint;
var i : longint;
begin
  result:=  0; avol:= 0;
  for i:= 0 to Count - 1 do with pQuoteItem(items[i])^ do
    if (aprice - price) * akf > 1e-10 then begin
      inc(Result); inc(avol, quantity);
    end;
  FileLog('tQuote.PLVolBefore %.6g %d = %d %d', [aprice, akf, Result, avol], 4);
end;

{ tSec }

constructor tSec.create(asecid  : longint; const acode: tCode; const alevel: tLevel; astockid: longint; const asectype : string; const aaccount : tAccount);
begin
  inherited create;
  SecurityId  :=  asecid;
  code    :=  acode;
  level   :=  alevel;
  stockid :=  astockid;
  SecType :=  asectype;
  Account :=  aaccount;
  Bid     :=  tQuote.create(-1);
  Ask     :=  tQuote.create(1);
  LastQuoteTime :=  0;
  LastParamTime :=  0;
  QuoteSaveTime :=  0;
end;



procedure tSec.LogSec;
begin
  FileLog('%s quote %g', [code, Params.lastdealprice], 3);
end;

procedure tSec.KillKross;
var va, vb    : tQuoteItem;
    vaq, vbq  : longint;
begin
  if assigned(Ask) and assigned(Bid) then
  while (Ask.Count > 0) and (Bid.Count > 0) do begin
    va  :=  pQuoteItem(Ask.Items[0])^;  vaq:= va.quantity;
    vb  :=  pQuoteItem(Bid.Items[0])^;  vbq:= vb.quantity;
    if va.price <= vb.price then begin
      if vaq > vbq then begin dec(pQuoteItem(Ask.Items[0])^.quantity, vbq); Bid.delete(0); end;
      if vaq < vbq then begin dec(pQuoteItem(Bid.Items[0])^.quantity, vaq); Ask.delete(0); end;
      if vaq = vbq then begin Ask.delete(0); Bid.delete(0); end;
    end else break;
  end;

end;


procedure tSec.LogQuotes;
var vas, vbs  : string;
begin
  if assigned(Ask) then vas:= Ask.GetLog else vas:= '';
  if assigned(Bid) then vbs:= Bid.GetLog else vbs:= '';
  FileLog('%s Bid %s Ask %s', [code, vbs, vas], 3);
end;

procedure tSec.GetTradeParams;
var
    i   : longint;
    res : PPGresult;
    SL  : tStringList;
begin
  try
    if (PQstatus(gPGConn) = CONNECTION_OK) then begin
    res := PQexec(gPGConn, PChar(format('SELECT public.getsecparams(%d)', [SecurityId])));
      if (PQresultStatus(res) <> PGRES_TUPLES_OK) then log('MTS3LX_SECURITIES. GetTradeParams getsecparams() error')
      else
        for i := 0 to PQntuples(res)-1 do begin
          SL :=  QueryResult(PQgetvalue(res, i, 0));
          if SL.Count > 9 then with TradeParams do begin
            LotSize         :=    StrToIntDef(SL[0], 0);
            PriceStep       :=    StrToFloatDef(SL[1], 0);
            PriceDriver     :=    StrToFloatDef(SL[2], 0);
            ActiveTime      :=    StrToIntDef(SL[3], 0);
            VolOff          :=    StrToIntDef(SL[4], 0);
            Vmin            :=    StrToIntDef(SL[5], 0);
            Mhigh           :=    StrToFloatDef(SL[6], 0);
            Vmax            :=    StrToIntDef(SL[7], 0);
            Mlow            :=    StrToFloatDef(SL[8], 0);
            IF StrToIntDef(SL[9], 0) = 0 then ForcedActivity  :=  false else ForcedActivity  :=  true;
          end;
        end;
      PQclear(res);
    end;
    filelog('MTS3LX_SECURITIES. GetTradeParams %s(%d) %d %.6g', [code, SecurityId, TradeParams.LotSize, TradeParams.PriceStep], 3);
  except on e:exception do Filelog(' !!! EXCEPTION: GetTradeParams %s', [e.message], 0); end;

end;

{
function tSec.IsTradeActive: boolean;
begin
  result := ( (Now - LastParamTime) < TradeParams.ActiveTime / SecInDay) and ( (Now - LastQuoteTime) < TradeParams.ActiveTime / SecInDay);
end;

   }


function  tSec.AdditionPrice(avol: real; aquote: char; alastdeal : boolean = false) : real;
begin
  Result:=  -1;
  if (SecType = 'I') or alastdeal then Result  :=  Params.lastdealprice
  else
  with TradeParams do begin
    if avol >= 0 then begin
      if (aquote = 'A') then Result :=  Ask.MeanPrice(Min(Vmin + round(avol * mLow), Vmax), Max(1, round((Mhigh + 1) * avol)));
      if (aquote = 'B') then Result :=  Bid.MeanPrice(Min(Vmin + round(avol * mLow), Vmax), Max(1, round((Mhigh + 1) * avol)));
    end else begin
      if (aquote = 'A') then Result :=  Bid.MeanPrice(Min(Vmin + round(-avol * mLow), Vmax), Max(1, -round((Mhigh + 1) * avol)));
      if (aquote = 'B') then Result :=  Ask.MeanPrice(Min(Vmin + round(-avol * mLow), Vmax), Max(1, -round((Mhigh + 1) * avol)));
    end;
  end;
end;


function  tSec.BasePrice(avol: longint; aquote: char; alastdeal : boolean = false) : real;
begin
  if (SecType = 'I') or alastdeal then Result  :=  Params.lastdealprice
  else
  with TradeParams do begin
    result :=  LotSize;
    if (aquote = 'A') then Result :=  result * Ask.PriceToVol(VolOff + avol);
    if (aquote = 'B') then Result :=  result * Bid.PriceToVol(VolOff + avol);
  end;
end;

function tSec.IsActive(alog: boolean = true): boolean;
begin
  if TradeParams.ForcedActivity OR
    (
       ( (SecType = 'I') or ( (Now - LastQuoteTime) < TradeParams.ActiveTime * SecDelay) ) and
       ( (Now - LastParamTime) < TradeParams.ActiveTime * SecDelay) and
       (Params.lotsize = TradeParams.LotSize) and
       ( (SecType = 'I') or (SecType = 'O') or (stockid = 1) or
          ( (Params.lastdealprice > Params.limitpricelow) and (Params.lastdealprice < Params.limitpricehigh) ) )
    ) then
    result:=  true else result:=  false;    

  if alog then FileLog('tSec.IsActive %s = %s (Forced = %s) (%.6g %.6g %.6g) %d %d  last=%.6g (%d %.6g - %.6g)',
          [code, BoolToStr(Result, true), BoolToStr(TradeParams.ForcedActivity, true), Now, LastQuoteTime, LastParamTime,
          Params.lotsize, TradeParams.LotSize, Params.lastdealprice, stockid, Params.limitpricelow, Params.limitpricehigh], 3);
end;


function tSec.NormalizePrice(aprice: real): real;
begin
  result:=  0;
  if (Params.lotsize > 0) and (Params.pricestep > 0) then begin
      result:=  Round(aprice / Params.lotsize / Params.pricestep) * Params.pricestep;
  end;
  FileLog('tSec.NormalizePrice %.6g (%d %.6g) = %.6g', [aprice, Params.lotsize, Params.pricestep, Result], 3);
end;

{ tSecList }

constructor tSecList.create;
begin
  inherited create;
  fDuplicates:= dupReplace;
end;

function tSecList.checkitem(item: pointer): boolean;
begin
  result:=  assigned(item);
end;

function tSecList.compare(item1, item2: pointer): longint;
begin
  result:= pSec(item1)^.stockid - pSec(item2)^.stockid;
  if (result = 0) then begin
    result:= comparetext(pSec(item1)^.level, pSec(item2)^.level);
    if (result = 0) then result:= comparetext(pSec(item1)^.code, pSec(item2)^.code);
  end;
end;


procedure tSecList.freeitem(item: pointer);
begin
  if assigned(item) then dispose(pSec(item));
end;




procedure tSecList.LoadFromDB;
var vSec  : tSec;
    vpSec : pSec;
    i     : longint;
    res : PPGresult;
    SL      : tStringList;
begin
  locklist;
  try
    if (PQstatus(gPGConn) = CONNECTION_OK) then begin
    res := PQexec(gPGConn, 'SELECT public.getseclist()');
      if (PQresultStatus(res) <> PGRES_TUPLES_OK) then log('MTS3LX_SECURITIES. LoadFromDB getseclist() error')
      else
        for i := 0 to PQntuples(res)-1 do begin
          SL :=  QueryResult(PQgetvalue(res, i, 0));
          if SL.Count > 5 then begin
            vSec  :=  tSec.Create(StrToIntDef(SL[0], 0), SL[1], SL[2], StrToIntDef(SL[3], 0), SL[4], SL[5]);
            with vSec do FileLog('MTS3LX_SECURITIES. LoadFromDB   : Adding   %s %s/%d Added', [code, level, stockid], 2);
            new(vpSec); vpSec^  :=  vSec; add(vpSec);
          end;
        end;
      PQclear(res);
    end;
    for i:= 0 to Count - 1 do pSec(items[i])^.GetTradeParams;
  finally unlocklist; end;
  FileLog('MTS3LX_SECURITIES. LoadFromDB  %d Securities Loaded', [Count], 1);

end;


function tSecList.GetSecurity(const acode: tCode; const alevel: tLevel; astockid: longint; var aSec  : tSec): boolean;
var vSec  : tSec;
    idx   : longint;
begin
  vSec:=  tSec.Create;
  with vSec do try
    code:=  acode; level:=  alevel; stockid:= astockid;
    result:= search(@vSec, idx);
    if result then aSec:=  pSec(items[idx])^ else aSec :=  nil;;
  finally free; end;
end;


procedure tSecList.SetParams(const aParams: tSecurities);
var vSec : tSec;
begin

  with locklist, aParams do try
    if GetSecurity(code, level, stock_id, vSec) and assigned(vSec) then
    with vSec do begin
      Params :=  aParams;
      LastParamTime :=  Now;
      if (Now > QuoteSaveTime + SecDelay * QuoteSaveDelay) then begin
        PGQueryMy('SELECT public.addupdatecurrentquote(''%s'', %g, %g)', [code, Params.lastdealprice, Params.fut_deposit]);
        QuoteSaveTime :=  Now;
      end;
    end;
  finally unlocklist; end;

end;

procedure tSecList.ProcessQuote(aHeader  : tKotUpdateHdr; aItems : array of tKotUpdateItem);
var vSec      : tSec;
    i         : longint;
begin
  with locklist, aHeader do try
    if GetSecurity(code, level, stock_id, vSec) and assigned(vSec) then
    with vSec do begin
      Bid.clear; Ask.clear;
      for i:= low(aItems) to high(aItems) do with aItems[i] do begin
        if buysell = 'B' then Bid.AddQuote(price, quantity);
        if buysell = 'S' then Ask.AddQuote(price, quantity);
      end;
      if assigned(TPList) then TPList.TPQuoteToQueue(code, level, stockid);
      LastQuoteTime :=  Now;
      FileLog('MTS3LX_SECURITIES. Processed Quotes   %s %s/%d Length %d %d', [code, level, stockid, Ask.Count, Bid.Count], 4);
    end;
  finally unlocklist; end;

end;


function tSecList.CheckFilter(const acode: tCode; const alevel: tLevel; astockid: longint): boolean;
var vSec  : tSec;
begin
  result:=  GetSecurity(acode, alevel, astockid, vSec);
end;

function tSecList.GetSecById(aid: longint): pSec;
var i : longint;
begin
  result:=  nil;
  for i:= 0 to Count-1 do
    if (pSec(items[i])^.SecurityId = aid) then begin
      Result:=  pSec(items[i]); break;
    end;
end;



//    --------------------



procedure InitMTSSec;
begin
  try
    SecList:= tSecList.create;
    if assigned(SecList) then SecList.LoadFromDB;
    log('SECURITIES   :   Started');
  except on e:exception do Filelog(' !!! EXCEPTION: SECURITIES %s', [e.message], 0); end;

end;


procedure DoneMTSSec;
begin
   if assigned(SecList) then freeandnil(SecList);
   log('SECURITIES   :   Finished');
end;




end.
