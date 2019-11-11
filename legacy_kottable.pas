{$i tterm_defs.pas}
{$i serverdefs.pas}

unit legacy_kottable;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$endif}
      sysutils, math,
      sortedlist,
      servertypes, serverapi,
      legacy_sectable;

const kot_prealloccount = 120;

type  pKotCollItm     = ^tKotCollItm;
      tKotCollItm     = record
       buf            : pAnsiChar;
       buflen         : longint;
      end;

type  tKotCollector   = class(tSortedList)
       constructor create;
       procedure   freeitem(item: pointer); override;
       function    checkitem(item: pointer): boolean; override;
       function    compare(item1, item2: pointer): longint; override;
       procedure   add(var struc: tKotirovki; headeronly: boolean); reintroduce; virtual;
      end;

type  tKotirovkiTable = class(tSortedList)
       constructor create;
       procedure   freeitem(item: pointer); override;
       function    checkitem(item: pointer): boolean; override;
       function    compare(item1, item2: pointer): longint; override;
       procedure   add(var struc: tKotirovki); reintroduce; virtual;
       procedure   filteritems(var struc: tKotirovki; flags: longint);
      end;

type  tKotirovkiRng   = class(tSortedList)
       ffilter        : ansichar;
       flotsize       : currency;
       constructor create(afilter: char; alotsize: currency);
       procedure   freeitem(item: pointer); override;
       function    checkitem(item: pointer): boolean; override;
       function    compare(item1, item2: pointer): longint; override;
       function    pricebyquantity(aqty: currency): currency;
       function    quantitybyprice(aprice: currency): currency;
       procedure   logrng;
      end;

var   KotirovkiCritSect  : tRtlCriticalSection;
      Kotirovki          : tKotirovkiTable;
      KotColl            : tKotCollector;

function  getPriceByQuantity(astock_id: longint; const alevel: tLevel; const acode: tCode; abuysell: ansichar; aqty: currency): currency;
function  getSimplePriceByQuantity(const asec: tSecurities; abuysell: ansichar; aqty: currency): currency;
function  getQuantityByPrice(astock_id: longint; const alevel: tLevel; const acode: tCode; abuysell: ansichar; aprice: currency): currency;

procedure srvKotirovkiLock; cdecl;
procedure srvClearKotirovkiTbl(var struc: tKotirovki; flags: longint); cdecl;
procedure srvAddKotirovkiRec(var struc: tKotirovki); cdecl;
procedure srvKotirovkiUnlock; cdecl;

implementation

uses tterm_logger, tterm_legacy_apis;

constructor tKotCollector.create;
begin inherited create; fduplicates:= dupIgnore; end;

procedure tKotCollector.freeitem;
begin
  if assigned(item) then begin
    with pKotCollItm(item)^ do if assigned(buf) then freemem(buf);
    dispose(pKotCollItm(item));
  end;
end;

function tKotCollector.checkitem;
begin result:=true; end;

function tKotCollector.compare;
var a, b : pKotUpdateHdr;
begin
  a:= pKotUpdateHdr(pKotCollItm(item1)^.buf);
  b:= pKotUpdateHdr(pKotCollItm(item2)^.buf);
  result:= a^.stock_id - b^.stock_id;
  if (result = 0) then begin
    result:= CompareText(a^.level, b^.level);
    if (result = 0) then result:= CompareText(a^.code, b^.code);
  end;
end;

procedure tKotCollector.add(var struc: tKotirovki; headeronly: boolean);
const hdr    : tKotUpdateHdr = (stock_id: 0; level: ''; code: ''; kotcount: 0);
      itm    : tKotCollItm   = (buf: @hdr; buflen: sizeof(tKotUpdateHdr));
var   idx    : longint;
      newitm : pKotCollItm;
      pos    : longint;
begin
  with struc do begin hdr.stock_id:= stock_id; hdr.level:= level; hdr.code:= code; end;

  if not search(@itm, idx) then begin
    newitm:= new(pKotCollItm);
    with newitm^ do begin
      buflen:=sizeof(tKotUpdateHdr) + kot_prealloccount * sizeof(tKotUpdateItem);
      buf:= allocmem(buflen);
      with pKotUpdateHdr(buf)^ do begin
        stock_id:= struc.stock_id; level:= struc.level; code:= struc.code; kotcount:= 0;
      end;
    end;
    insert(idx, newitm);
  end;

  if (idx >= 0) and not headeronly then begin
    if (upcase(struc.buysell) in ['B', 'S']) then
      with pKotCollItm(items[idx])^ do begin
        pos:= sizeof(tKotUpdateHdr) + pKotUpdateHdr(buf)^.kotcount * sizeof(tKotUpdateItem);
        if (pos >= buflen) then begin
          inc(buflen, kot_prealloccount * sizeof(tKotUpdateItem));
          reallocmem(buf, buflen);
        end;
        with pKotUpdateItem(@buf[pos])^ do begin
          buysell:= struc.buysell; price:= struc.price; quantity:= struc.quantity; gko_yield:= struc.gko_yield;
        end;
        inc(pKotUpdateHdr(buf)^.kotcount);
      end;
  end;
end;

//--------------------------------------------------------------------

constructor tKotirovkiTable.create;
begin inherited create; fduplicates:=dupAccept; end;

procedure tKotirovkiTable.freeitem;
begin if assigned(item) then dispose(pKotirovki(item)); end;

function tKotirovkiTable.checkitem;
begin result:=true; end;

function tKotirovkiTable.compare;
begin
  result:= pKotirovki(item1)^.stock_id - pKotirovki(item2)^.stock_id;
  if result = 0 then begin
    result:= CompareText(pKotirovki(item1)^.level, pKotirovki(item2)^.level);
    if result = 0 then result:= CompareText(pKotirovki(item1)^.code, pKotirovki(item2)^.code);
  end;
end;

procedure tKotirovkiTable.add;
var itm : pKotirovki;
begin itm:=new(pKotirovki); itm^:=struc; inherited add(itm); end;

procedure tKotirovkiTable.FilterItems;
var   idx : longint;
begin
  case flags of
    clrByStruct  : if search(@struc,idx) then
                     repeat delete(idx); until (idx >= count) or (compare(@struc, items[idx])<>0);
    clrByStockId : for idx:= count - 1 downto 0 do
                     if (pKotirovki(items[idx])^.stock_id = struc.stock_id) then delete(idx);
    clrByLevel   : for idx:= count - 1 downto 0 do
                     if (pKotirovki(items[idx])^.stock_id = struc.stock_id) and
                        (CompareText(pKotirovki(items[idx])^.level, struc.level) = 0) then delete(idx);
  end;
end;

//--------------------------------------------------------------------

function getPriceByQuantity;
var kr    : tKotirovkiRng;
    kot   : tKotirovki;
    idx   : longint;
    sign  : currency;
begin
  if (aqty > 0) then sign:= 1 else sign:= -1;
  aqty:= abs(aqty);
  if aqty > 0 then begin
    with kot do begin stock_id:= astock_id; level:= alevel; code:= acode; end;
    with srvSearchSecuritiesRec(astock_id, alevel, acode) do
      if stock_id <> 0 then begin
        kr:= tKotirovkiRng.create(abuysell, max(1, lotsize));
        try
          EnterCriticalSection(KotirovkiCritSect);
          try
            with Kotirovki do
              if search(@kot, idx) then
                repeat kr.add(items[idx]); inc(idx);
                until (idx >= count) or (compare(@kot, items[idx]) <> 0);
            if (kr.count > 0) then result:= kr.pricebyquantity(aqty)
                              else result:= lastdealprice * aqty;
          finally LeaveCriticalSection(KotirovkiCritSect); end;
        finally kr.free; end;
      end else begin
        log('PRICEBYQTY: Unable to locate security: %d/%s/%s', [astock_id, alevel, acode]);
        result:= 0;
      end;
    result:= result * sign;
  end else result:= 0;
end;

function getSimplePriceByQuantity;
begin
  if (asec.stock_id <> 0) then with asec do begin
    case upcase(abuysell) of
      'B' : if (lowoffer > 0)        then result:= aqty * lowoffer         else
            if (lastdealprice > 0)   then result:= aqty * lastdealprice    else
            if (prev_price > 0)      then result:= aqty * prev_price       else result:= aqty * closeprice;
      'S' : if (hibid > 0)           then result:= aqty * hibid            else
            if (lastdealprice > 0)   then result:= aqty * lastdealprice    else
            if (prev_price > 0)      then result:= aqty * prev_price       else result:= aqty * closeprice;
      else  result:= 0;
    end;
  end else result:= 0;
end;

function  getQuantityByPrice;
var kr  : tKotirovkiRng;
    kot : tKotirovki;
    idx : longint;
begin
  if aprice > 0 then begin
    with kot do begin stock_id:= astock_id; level:= alevel; code:= acode; end;
    with srvSearchSecuritiesRec(astock_id, alevel, acode) do
      if stock_id <> 0 then begin
        kr:= tKotirovkiRng.create(abuysell, 1);
        try
          EnterCriticalSection(KotirovkiCritSect);
          try
            with Kotirovki do
              if search(@kot,idx) then
                repeat kr.add(items[idx]); inc(idx);
                until (idx >= count) or (compare(@kot, items[idx]) <> 0);
            if (kr.count>0) then result:= trunc(kr.quantitybyprice(aprice) / lotsize) * lotsize
                            else result:= 0;
          finally LeaveCriticalSection(KotirovkiCritSect); end;
        finally kr.free; end;
      end else begin
        log('QTYBYPRICE: Unable to locate security: %d/%s/%s', [astock_id, alevel, acode]);
        result:= 0;
      end;
  end else result:= 0;
end;

//--------------------------------------------------------------------

constructor tKotirovkiRng.create;
begin
  inherited create;
  fduplicates:= dupIgnore;
  flotsize:= alotsize;
  case upcase(afilter) of
    'B' : ffilter:= 'S';
    'S' : ffilter:= 'B';
    else  ffilter:= #0;
  end;
end;

procedure tKotirovkiRng.freeitem; begin end;

function tKotirovkiRng.checkitem;
begin result:= (pKotirovki(item)^.buysell = ffilter); end;

function tKotirovkiRng.compare;
var delta : real;
begin
 delta:= pKotirovki(item1)^.price - pKotirovki(item2)^.price;
 if delta < 0 then result:= -1 else
 if delta > 0 then result:=  1 else result:= 0;
 if ffilter = 'B' then result:= result * -1;
end;

function tKotirovkiRng.pricebyquantity;
var idx : longint;
begin
  result:= 0;
  if count > 0 then begin
    idx:= 0;
    while (aqty > 0) and (idx < count) do
      with pKotirovki(items[idx])^ do begin
        if (quantity*flotsize<=aqty) then begin result:= result + price * quantity * flotsize; aqty:= aqty - quantity * flotsize; end
                                     else begin result:= result + price * aqty; aqty:= 0; end;
        inc(idx);
      end;
    if (aqty>0) then result:= result + pKotirovki(items[count-1])^.price * aqty;
  end;
  {$ifdef debugmode} if StartDebugMode then logrng; {$endif}
end;

function tKotirovkiRng.quantitybyprice;
var idx : longint;
    sum : currency;
begin
  idx:= 0; result:= 0;
  while (aprice > 0) and (idx < count) do
    with pKotirovki(items[idx])^ do begin
      sum:= price * quantity * flotsize;
      if (sum<=aprice) then begin result:= result + quantity * flotsize;   aprice:= aprice - sum; end
                       else begin result:= result + trunc(aprice / price); aprice:= 0; end;
      inc(idx);
    end;
  {$ifdef debugmode} if StartDebugMode then logrng; {$endif}
end;

procedure tKotirovkiRng.logrng;
var   i       : longint;
const framech : array [boolean] of char = ('|', '+');
begin
  try
    log('LOGKOTRANGE: filter: %s  lotsize: %.0f',[ffilter, flotsize]);
    for i:=0 to count-1 do with pKotirovki(items[i])^ do
      log('LOGKOTRANGE: %s %d/%s/%s   %s   %d/%.5f',
          [framech[(i = 0) or (i = count-1)], stock_id, level, code, buysell, quantity, price]);
  except on e:exception do log('LOGKOTRANGE: Exception: %s',[e.message]); end;
end;

//--------------------------------------------------------------------

procedure srvKotirovkiLock;
begin
  EnterCriticalSection(KotirovkiCritSect);
  KotColl.clear;
end;

procedure srvClearKotirovkiTbl;
begin
  Kotirovki.FilterItems(struc, flags);
  if (flags = clrByStruct) then KotColl.add(struc, true);
end;

procedure srvAddKotirovkiRec;
begin
  Kotirovki.Add(struc);
  KotColl.add(struc, false);
end;

procedure srvKotirovkiUnlock;
var i,j  : integer;
begin
  try
    if (KotColl.count > 0) then begin
      for i:= 0 to event_apis_count - 1 do
        if assigned(event_apis[i]) then with event_apis[i]^ do
          if assigned(evKotirArrived) then
            for j:= 0 to KotColl.count - 1 do evKotirArrived(pKotCollItm(KotColl.items[j])^.buf);
    end;
  finally LeaveCriticalSection(KotirovkiCritSect); end;
end;

exports
  srvKotirovkiLock     name srv_KotirovkiLock,
  srvClearKotirovkiTbl name srv_ClearKotirovkiTbl,
  srvAddKotirovkiRec   name srv_AddKotirovkiRec,
  srvKotirovkiUnlock   name srv_KotirovkiUnlock;

initialization
  {$ifdef MSWINDOWS}
  InitializeCriticalSection(KotirovkiCritSect);
  {$else}
  InitCriticalSection(KotirovkiCritSect);
  {$endif}
  Kotirovki:= tKotirovkiTable.create;
  KotColl:= tKotCollector.create;

finalization
  if assigned(KotColl) then freeandnil(KotColl);
  if assigned(Kotirovki) then begin
    Kotirovki.FreeAll;
    freeandnil(Kotirovki);
  end;
  {$ifdef MSWINDOWS}
  DeleteCriticalSection(KotirovkiCritSect);
  {$else}
  DoneCriticalSection(KotirovkiCritSect);
  {$endif}

end.
