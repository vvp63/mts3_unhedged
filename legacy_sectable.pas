{$i tterm_defs.pas}
{$i serverdefs.pas}

unit legacy_sectable;

interface

uses  {$ifdef MSWINDOWS}
        windows, inifiles,
      {$else}
        fclinifiles,
      {$endif}
      classes, sysutils, 
      sortedlist,
      servertypes, serverapi,
      legacy_database;

type  tStockList         = class(tSortedThreadList)
      private
        function    addrecordcb(avalues: tStringList): boolean;
      public
        constructor create;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        procedure   InitializeStocks;
      end;

type  tLevelAttrList     = class(tSortedThreadList)
      private
        function    addrecordcb(avalues: tStringList): boolean;
      public
        constructor create;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        function    isUseFW(stock_id: longint; level: tLevel): boolean;
        procedure   InitializeLevelAttr;
      end;

type  tSecuritiesTable   = class(tSortedList)
        constructor create;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        function    Add(item: pSecurities; var fld: tSecuritiesSet): tSecurities; reintroduce; virtual;
        function    Get(var item: tSecurities; flds: tSecuritiesSet): boolean; virtual;
        function    Retr(astock_id: longint; alevel: tLevel; acode: tCode): tSecurities; virtual;
      end;

var   SecuritiesCritSect : tRtlCriticalSection;

const Securities         : tSecuritiesTable = nil;
      LevelAttr          : tLevelAttrList   = nil;
      StockList          : tStockList       = nil;

const marginsensivity    = 0.01; //0.005;

procedure srvAddSecuritiesRec(var struc: tSecurities; changedfields: tSecuritiesSet); cdecl;
function  srvGetSecuritiesRec(var struc: tSecurities; flds: tSecuritiesSet): boolean; cdecl;

function  srvSearchSecuritiesRec(stock_id: longint; level, code: ansistring): tSecurities; cdecl;

procedure srvUpdateSecurities(var sour, dest: tSecurities; var sourset, destset: tSecuritiesSet); cdecl;
procedure srvCleanupSecurities(var sour: tSecurities; const sourset: tSecuritiesSet); cdecl;

implementation

uses  tterm_logger, tterm_legacy_apis, tterm_common, tterm_commonutils;

procedure srvUpdateSecurities(var sour, dest: tSecurities; var sourset, destset: tSecuritiesSet);
begin
 with dest do begin
  if (sec_shortname        in sourset) and (shortname<>sour.shortname)               then begin shortname:=sour.shortname;               include(destset,sec_shortname);        end;
  if (sec_hibid            in sourset) and (hibid<>sour.hibid)                       then begin hibid:=sour.hibid;                       include(destset,sec_hibid);            end;
  if (sec_lowoffer         in sourset) and (lowoffer<>sour.lowoffer)                 then begin lowoffer:=sour.lowoffer;                 include(destset,sec_lowoffer);         end;
  if (sec_initprice        in sourset) and (initprice<>sour.initprice)               then begin initprice:=sour.initprice;               include(destset,sec_initprice);        end;
  if (sec_maxprice         in sourset) and (maxprice<>sour.maxprice)                 then begin maxprice:=sour.maxprice;                 include(destset,sec_maxprice);         end;
  if (sec_minprice         in sourset) and (minprice<>sour.minprice)                 then begin minprice:=sour.minprice;                 include(destset,sec_minprice);         end;
  if (sec_meanprice        in sourset) and (meanprice<>sour.meanprice)               then begin meanprice:=sour.meanprice;               include(destset,sec_meanprice);        end;
  if (sec_meantype         in sourset) and (meantype<>sour.meantype)                 then begin meantype:=sour.meantype;                 include(destset,sec_meantype);         end;
  if (sec_change           in sourset) and (change<>sour.change)                     then begin change:=sour.change;                     include(destset,sec_change);           end;
  if (sec_value            in sourset) and (value<>sour.value)                       then begin value:=sour.value;                       include(destset,sec_value);            end;
  if (sec_amount           in sourset) and (amount<>sour.amount)                     then begin amount:=sour.amount;                     include(destset,sec_amount);           end;
  if (sec_lotsize          in sourset) and (lotsize<>sour.lotsize)                   then begin lotsize:=sour.lotsize;                   include(destset,sec_lotsize);          end;
  if (sec_facevalue        in sourset) and (facevalue<>sour.facevalue)               then begin facevalue:=sour.facevalue;               include(destset,sec_facevalue);        end;
  if (sec_lastdealprice    in sourset) and (lastdealprice<>sour.lastdealprice)       then begin lastdealprice:=sour.lastdealprice;       include(destset,sec_lastdealprice);    end;
  if (sec_lastdealsize     in sourset) and (lastdealsize<>sour.lastdealsize)         then begin lastdealsize:=sour.lastdealsize;         include(destset,sec_lastdealsize);     end;
  if (sec_lastdealqty      in sourset) and (lastdealqty<>sour.lastdealqty)           then begin lastdealqty:=sour.lastdealqty;           include(destset,sec_lastdealqty);      end;
  if (sec_lastdealtime     in sourset) and (lastdealtime<>sour.lastdealtime)         then begin lastdealtime:=sour.lastdealtime;         include(destset,sec_lastdealtime);     end;
  if (sec_gko_accr         in sourset) and (gko_accr<>sour.gko_accr)                 then begin gko_accr:=sour.gko_accr;                 include(destset,sec_gko_accr);         end;
  if (sec_gko_yield        in sourset) and (gko_yield<>sour.gko_yield)               then begin gko_yield:=sour.gko_yield;               include(destset,sec_gko_yield);        end;
  if (sec_gko_matdate      in sourset) and (gko_matdate<>sour.gko_matdate)           then begin gko_matdate:=sour.gko_matdate;           include(destset,sec_gko_matdate);      end;
  if (sec_gko_cuponval     in sourset) and (gko_cuponval<>sour.gko_cuponval)         then begin gko_cuponval:=sour.gko_cuponval;         include(destset,sec_gko_cuponval);     end;
  if (sec_gko_nextcupon    in sourset) and (gko_nextcupon<>sour.gko_nextcupon)       then begin gko_nextcupon:=sour.gko_nextcupon;       include(destset,sec_gko_nextcupon);    end;
  if (sec_gko_cuponperiod  in sourset) and (gko_cuponperiod<>sour.gko_cuponperiod)   then begin gko_cuponperiod:=sour.gko_cuponperiod;   include(destset,sec_gko_cuponperiod);  end;
  if (sec_biddepth         in sourset) and (biddepth<>sour.biddepth)                 then begin biddepth:=sour.biddepth;                 include(destset,sec_biddepth);         end;
  if (sec_offerdepth       in sourset) and (offerdepth<>sour.offerdepth)             then begin offerdepth:=sour.offerdepth;             include(destset,sec_offerdepth);       end;
  if (sec_numbids          in sourset) and (numbids<>sour.numbids)                   then begin numbids:=sour.numbids;                   include(destset,sec_numbids);          end;
  if (sec_numoffers        in sourset) and (numoffers<>sour.numoffers)               then begin numoffers:=sour.numoffers;               include(destset,sec_numoffers);        end;
  if (sec_tradingstatus    in sourset) and (tradingstatus<>sour.tradingstatus)       then begin tradingstatus:=sour.tradingstatus;       include(destset,sec_tradingstatus);    end;
  if (sec_closeprice       in sourset) and (closeprice<>sour.closeprice)             then begin closeprice:=sour.closeprice;             include(destset,sec_closeprice);       end;
  if (sec_srv_field        in sourset) and (srv_field<>sour.srv_field)               then begin srv_field:=sour.srv_field;               include(destset,sec_srv_field);        end;
  if (sec_gko_issuesize    in sourset) and (gko_issuesize<>sour.gko_issuesize)       then begin gko_issuesize:=sour.gko_issuesize;       include(destset,sec_gko_issuesize);    end;
  if (sec_gko_buybackprice in sourset) and (gko_buybackprice<>sour.gko_buybackprice) then begin gko_buybackprice:=sour.gko_buybackprice; include(destset,sec_gko_buybackprice); end;
  if (sec_gko_buybackdate  in sourset) and (gko_buybackdate<>sour.gko_buybackdate)   then begin gko_buybackdate:=sour.gko_buybackdate;   include(destset,sec_gko_buybackdate);  end;
  if (sec_prev_price       in sourset) and (prev_price<>sour.prev_price)             then begin prev_price:=sour.prev_price;             include(destset,sec_prev_price);       end;
  if (sec_fut_deposit      in sourset) and (fut_deposit<>sour.fut_deposit)           then begin fut_deposit:=sour.fut_deposit;           include(destset,sec_fut_deposit);      end;
  if (sec_fut_openedpos    in sourset) and (fut_openedpos<>sour.fut_openedpos)       then begin fut_openedpos:=sour.fut_openedpos;       include(destset,sec_fut_openedpos);    end;
  if (sec_marketprice      in sourset) and (marketprice<>sour.marketprice)           then begin marketprice:=sour.marketprice;           include(destset,sec_marketprice);      end;
  if (sec_limitpricehigh   in sourset) and (limitpricehigh<>sour.limitpricehigh)     then begin limitpricehigh:=sour.limitpricehigh;     include(destset,sec_limitpricehigh);   end;
  if (sec_limitpricelow    in sourset) and (limitpricelow<>sour.limitpricelow)       then begin limitpricelow:=sour.limitpricelow;       include(destset,sec_limitpricelow);    end;
  if (sec_decimals         in sourset) and (decimals<>sour.decimals)                 then begin decimals:=sour.decimals;                 include(destset,sec_decimals);         end;
  if (sec_pricestep        in sourset) and (pricestep<>sour.pricestep)               then begin pricestep:=sour.pricestep;               include(destset,sec_pricestep);        end;
  if (sec_stepprice        in sourset) and (stepprice<>sour.stepprice)               then begin stepprice:=sour.stepprice;               include(destset,sec_stepprice);        end;
 end;
end;

procedure srvCleanupSecurities(var sour: tSecurities; const sourset: tSecuritiesSet);
begin
 with sour do begin
  if not (sec_shortname        in sourset) then setlength(shortname, 0);
  if not (sec_hibid            in sourset) then hibid           := -1;
  if not (sec_lowoffer         in sourset) then lowoffer        := -1;
  if not (sec_initprice        in sourset) then initprice       := -1;
  if not (sec_maxprice         in sourset) then maxprice        := -1;
  if not (sec_minprice         in sourset) then minprice        := -1;
  if not (sec_meanprice        in sourset) then meanprice       := -1;
  if not (sec_meantype         in sourset) then meantype        := $ff;
  if not (sec_change           in sourset) then change          := -1;
  if not (sec_value            in sourset) then value           := -1;
  if not (sec_amount           in sourset) then amount          := -1;
  if not (sec_lotsize          in sourset) then lotsize         := 0;
  if not (sec_facevalue        in sourset) then facevalue       := -1;
  if not (sec_lastdealprice    in sourset) then lastdealprice   := -1;
  if not (sec_lastdealsize     in sourset) then lastdealsize    := -1;
  if not (sec_lastdealqty      in sourset) then lastdealqty     := -1;
  if not (sec_lastdealtime     in sourset) then lastdealtime    := 0;
  if not (sec_gko_accr         in sourset) then gko_accr        := -1;
  if not (sec_gko_yield        in sourset) then gko_yield       := 0;
  if not (sec_gko_matdate      in sourset) then gko_matdate     := 0;
  if not (sec_gko_cuponval     in sourset) then gko_cuponval    := -1;
  if not (sec_gko_nextcupon    in sourset) then gko_nextcupon   := 0;
  if not (sec_gko_cuponperiod  in sourset) then gko_cuponperiod := 0;
  if not (sec_biddepth         in sourset) then biddepth        := -1;
  if not (sec_offerdepth       in sourset) then offerdepth      := -1;
  if not (sec_numbids          in sourset) then numbids         := -1;
  if not (sec_numoffers        in sourset) then numoffers       := -1;
  if not (sec_tradingstatus    in sourset) then tradingstatus   := #0;
  if not (sec_closeprice       in sourset) then closeprice      := -1;
  if not (sec_srv_field        in sourset) then setlength(srv_field, 0);
  if not (sec_gko_issuesize    in sourset) then gko_issuesize    := -1;
  if not (sec_gko_buybackprice in sourset) then gko_buybackprice := -1;
  if not (sec_gko_buybackdate  in sourset) then gko_buybackdate  := 0;
  if not (sec_prev_price       in sourset) then prev_price       := -1;
  if not (sec_fut_deposit      in sourset) then fut_deposit      := -1;
  if not (sec_fut_openedpos    in sourset) then fut_openedpos    := -1;
  if not (sec_marketprice      in sourset) then marketprice      := -1;
  if not (sec_limitpricehigh   in sourset) then limitpricehigh   := -1;
  if not (sec_limitpricelow    in sourset) then limitpricelow    := -1;
  if not (sec_decimals         in sourset) then decimals         := -1;
  if not (sec_pricestep        in sourset) then pricestep        := -1;
  if not (sec_stepprice        in sourset) then stepprice        := -1;
 end;
end;

{ tStockList }

constructor tStockList.create;
begin inherited create; fduplicates:=dupIgnore; end;

procedure tStockList.freeitem(item: pointer);
begin if assigned(item) then dispose(pStockRow(item)); end;

function tStockList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tStockList.compare(item1, item2: pointer): longint;
begin result:= pStockRow(item1)^.stock_id - pStockRow(item2)^.stock_id; end;

function tStockList.addrecordcb(avalues: tStringList): boolean;
var itm : pStockRow;
begin
  result:= assigned(avalues) and (avalues.count >= 3);
  if result then begin
    itm:= new(pStockRow);
    with itm^ do begin
      stock_id    := strtointdef(avalues[0], 0);
      stock_name  := avalues[1];
      stock_flags := strtointdef(avalues[2], 0);
    end;
    add(itm);
  end;
end;

procedure tStockList.InitializeStocks;
begin
  locklist;
  try
    if not db_enumeratetablerecords('stocks', addrecordcb) then log('ERROR: Stock list initialization error');
  finally unlocklist; end;
end;

{ tLevelAttrList }

constructor tLevelAttrList.create;
begin inherited create; fduplicates:=dupIgnore; end;

procedure tLevelAttrList.freeitem(item: pointer);
begin if assigned(item) then dispose(pLevelAttrItem(item)); end;

function tLevelAttrList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tLevelAttrList.compare(item1, item2: pointer): longint;
begin
  result:= pLevelAttrItem(item1)^.stock_id - pLevelAttrItem(item2)^.stock_id;
  if (result = 0) then result:= CompareText(pLevelAttrItem(item1)^.level, pLevelAttrItem(item2)^.level);
end;

function  tLevelAttrList.isUseFW(stock_id: longint; level: tLevel): boolean;
var itm : tLevelAttrItem;
    idx : longint;
begin
  itm.stock_id:= stock_id; itm.level:= level;
  locklist;
  try
    if search(@itm,idx) then begin result:= pLevelAttrItem(items[idx])^.usefacevalue; end
                        else begin result:= false; log('ADDSEC: No such board: %s in accboards', [level]); end;
  finally unlocklist; end;
end;

function  tLevelAttrList.addrecordcb(avalues: tStringList): boolean;
var itm : pLevelAttrItem;
begin
  result:= assigned(avalues) and (avalues.count >= 7);
  if result then begin
    itm:= new(pLevelAttrItem);
    with itm^ do begin
      stock_id     := strtointdef(avalues[0], 0);
      level        := avalues[1];
      marketcode   := avalues[2];
      usefacevalue := (strtointdef(avalues[3], 0) > 0);
      leveltype    := strtointdef(avalues[4], 0);
      default      := strtointdef(avalues[5], 0);
      description  := avalues[6];
    end;
    add(itm);
  end;
end;

procedure tLevelAttrList.InitializeLevelAttr;
begin
  locklist;
  try
    if not db_enumeratetablerecords('accboards', addrecordcb) then log('ERROR: Level list initialization error');
  finally unlocklist; end;
end;

{ tSecuritiesTable }

constructor tSecuritiesTable.create;
begin inherited create; fduplicates:= dupIgnore; end;

procedure tSecuritiesTable.freeitem(item: pointer);
begin if assigned(item) then dispose(pSecuritiesItem(item)); end;

function tSecuritiesTable.checkitem(item: pointer): boolean;
begin result:= true; end;

function tSecuritiesTable.compare(item1, item2: pointer): longint;
begin
  result:= pSecuritiesItem(item1)^.sec.stock_id - pSecuritiesItem(item2)^.sec.stock_id;
  if (result = 0) then begin
    result:= comparetext(pSecuritiesItem(item1)^.sec.level, pSecuritiesItem(item2)^.sec.level);
    if (result = 0) then result:= comparetext(pSecuritiesItem(item1)^.sec.code, pSecuritiesItem(item2)^.sec.code);
  end;
end;

function tSecuritiesTable.Add(item: pSecurities; var fld: tSecuritiesSet): tSecurities;
var idx     : integer;
    itm     : pSecuritiesItem;
    tempset : tSecuritiesSet;
begin
  if assigned(item) then begin
    if search(item, idx) then begin
      with pSecuritiesItem(items[idx])^ do try
        tempset:= [sec_stock_id, sec_level, sec_code];
        srvUpdateSecurities(item^, sec, fld, tempset);
        secset:= secset + tempset;
      finally result:= sec; fld:= tempset; end;
    end else begin
      itm:= new(pSecuritiesItem);
      with itm^ do try
        sec:= item^;
        secset:= fld;
        srvCleanupSecurities(sec, fld);
      finally result:= sec; end;
      insert(idx, itm);
    end;
  end else fillchar(result, sizeof(result), 0);
end;

function tSecuritiesTable.Get(var item: tSecurities; flds: tSecuritiesSet): boolean;
var i : integer;
begin
  result:= false;
  i:= 0;
  while (not result) and (i < count) do begin
    if assigned(items[i]) then begin
      result:= true;
      with pSecuritiesItem(items[i])^, sec do begin
        if sec_stock_id in flds         then if stock_id<>item.stock_id                 then result:= false;
        if sec_shortname in flds        then if shortname<>item.shortname               then result:= false;
        if sec_level in flds            then if level<>item.level                       then result:= false;
        if sec_code in flds             then if code<>item.code                         then result:= false;
        if sec_hibid in flds            then if hibid<>item.hibid                       then result:= false;
        if sec_lowoffer in flds         then if lowoffer<>item.lowoffer                 then result:= false;
        if sec_initprice in flds        then if initprice<>item.initprice               then result:= false;
        if sec_maxprice in flds         then if maxprice<>item.maxprice                 then result:= false;
        if sec_minprice in flds         then if minprice<>item.minprice                 then result:= false;
        if sec_meanprice in flds        then if meanprice<>item.meanprice               then result:= false;
        if sec_meantype in flds         then if meantype<>item.meantype                 then result:= false;
        if sec_change in flds           then if change<>item.change                     then result:= false;
        if sec_value in flds            then if value<>item.value                       then result:= false;
        if sec_amount in flds           then if amount<>item.amount                     then result:= false;
        if sec_lotsize in flds          then if lotsize<>item.lotsize                   then result:= false;
        if sec_facevalue in flds        then if facevalue<>item.facevalue               then result:= false;
        if sec_lastdealprice in flds    then if lastdealprice<>item.lastdealprice       then result:= false;
        if sec_lastdealsize in flds     then if lastdealsize<>item.lastdealsize         then result:= false;
        if sec_lastdealqty in flds      then if lastdealqty<>item.lastdealqty           then result:= false;
        if sec_lastdealtime in flds     then if lastdealtime<>item.lastdealtime         then result:= false;
        if sec_gko_accr in flds         then if gko_accr<>item.gko_accr                 then result:= false;
        if sec_gko_yield in flds        then if gko_yield<>item.gko_yield               then result:= false;
        if sec_gko_matdate in flds      then if gko_matdate<>item.gko_matdate           then result:= false;
        if sec_gko_cuponval in flds     then if gko_cuponval<>item.gko_cuponval         then result:= false;
        if sec_gko_nextcupon in flds    then if gko_nextcupon<>item.gko_nextcupon       then result:= false;
        if sec_gko_cuponperiod in flds  then if gko_cuponperiod<>item.gko_cuponperiod   then result:= false;
        if sec_biddepth in flds         then if biddepth<>item.biddepth                 then result:= false;
        if sec_offerdepth in flds       then if offerdepth<>item.offerdepth             then result:= false;
        if sec_numbids in flds          then if numbids<>item.numbids                   then result:= false;
        if sec_numoffers in flds        then if numoffers<>item.numoffers               then result:= false;
        if sec_tradingstatus in flds    then if tradingstatus<>item.tradingstatus       then result:= false;
        if sec_closeprice in flds       then if closeprice<>item.closeprice             then result:= false;
        if sec_srv_field in flds        then if srv_field<>item.srv_field               then result:= false;
        if sec_gko_issuesize in flds    then if gko_issuesize<>item.gko_issuesize       then result:= false;
        if sec_gko_buybackprice in flds then if gko_buybackprice<>item.gko_buybackprice then result:= false;
        if sec_gko_buybackdate in flds  then if gko_buybackdate<>item.gko_buybackdate   then result:= false;
        if sec_prev_price in flds       then if prev_price<>item.prev_price             then result:= false;
        if sec_fut_deposit in flds      then if fut_deposit<>item.fut_deposit           then result:= false;
        if sec_fut_openedpos in flds    then if fut_openedpos<>item.fut_openedpos       then result:= false;
        if sec_marketprice in flds      then if marketprice<>item.marketprice           then result:= false;
        if sec_limitpricehigh in flds   then if limitpricehigh<>item.limitpricehigh     then result:= false;
        if sec_limitpricelow in flds    then if limitpricelow<>item.limitpricelow       then result:= false;
        if sec_decimals  in flds        then if decimals<>item.decimals                 then result:= false;
        if sec_pricestep in flds        then if pricestep<>item.pricestep               then result:= false;
        if sec_stepprice in flds        then if stepprice<>item.stepprice               then result:= false;

        if result then item:= sec;
      end;
    end;
    inc(i);
  end;
end;

function tSecuritiesTable.Retr(astock_id: longint; alevel: tLevel; acode: tCode): tSecurities;
var idx : longint;
    itm : tSecuritiesItem;
begin
  itm.secset:= [];
  with itm.sec do begin stock_id:= astock_id; level:= alevel; code:= acode; end;
  if search(@itm, idx) then result:= pSecuritiesItem(items[idx])^.sec else fillchar(result, sizeof(tSecurities), 0);
end;

procedure srvAddSecuritiesRec(var struc: tSecurities; changedfields: tSecuritiesSet);
var sec  : tSecuritiesItem;
    i    : longint;
begin
  try
    with struc do
      if LevelAttr.isUseFW(stock_id, level) then begin
        if (facevalue = 0) then facevalue:= 1;
      end else facevalue:= 1;

    EnterCriticalSection(SecuritiesCritSect);
    with sec do try
      sec:= securities.add(@struc, changedfields);
      secset:= changedfields;
    finally LeaveCriticalSection(SecuritiesCritSect); end;

    for i:= 0 to event_apis_count - 1 do
      if assigned(event_apis[i]) then with event_apis[i]^ do
        if assigned(evSecArrived) then evSecArrived(sec.sec, sec.secset);

  except on e:exception do log('SRVADDSEC: Exception: %s',[e.message]); end;
end;

function srvGetSecuritiesRec(var struc: tSecurities; flds: tSecuritiesSet): boolean;
begin
  result:= false;
  try
    EnterCriticalSection(SecuritiesCritSect);
    try
      if flds = [sec_stock_id, sec_level, sec_code] then begin
        struc:= securities.Retr(struc.stock_id, struc.level, struc.code);
        result:= (struc.stock_id <> 0);
      end else result:= securities.Get(struc, flds);
    finally LeaveCriticalSection(SecuritiesCritSect); end;
  except on e:exception do log('SRVGETSEC: Exception: %s', [e.message]); end;
end;

function srvSearchSecuritiesRec(stock_id: longint; level, code: ansistring): tSecurities;
begin
  EnterCriticalSection(SecuritiesCritSect);
  try result:= securities.Retr(stock_id, level, code);
  finally LeaveCriticalSection(SecuritiesCritSect); end;
end;

exports
  srvAddSecuritiesRec  name srv_AddSecuritiesRec,
  srvGetSecuritiesRec  name srv_GetSecuritiesRec,
  srvUpdateSecurities  name srv_UpdateSecuritiesRec,
  srvCleanupSecurities name srv_CleanupSecuritiesRec;

initialization
  {$ifdef MSWINDOWS}
  InitializeCriticalSection(SecuritiesCritSect);
  {$else}
  InitCriticalSection(SecuritiesCritSect);
  {$endif}
  Securities:= tSecuritiesTable.Create;
  LevelAttr:= tLevelAttrList.create;
  StockList:= tStockList.create;

finalization
  if assigned(StockList) then freeandnil(StockList);
  if assigned(LevelAttr) then freeandnil(LevelAttr);
  if assigned(Securities) then freeandnil(Securities);
  {$ifdef MSWINDOWS}
  DeleteCriticalSection(SecuritiesCritSect);
  {$else}
  DoneCriticalSection(SecuritiesCritSect);
  {$endif}

end.
