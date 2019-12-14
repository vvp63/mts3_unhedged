{$i terminal_defs.pas}

unit queue;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$endif}
      sysutils,
      servertypes, protodef,
      lowlevel, sortedlist,
      terminal_common;

type  tQueue            = class(tSortedThreadList)
        constructor create;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer):boolean; override;
        procedure   insertlast(idx: longint; item: pointer);
        function    compare(item1, item2: pointer):longint; override;
        procedure   queue(itm: pQueueData); overload; virtual;
        procedure   queue(var buf; aid, asize: longint); overload; virtual;
        procedure   add(item: pointer); override;
      end;

implementation

constructor tQueue.create;
begin inherited create; fDuplicates:=dupAccept; end;

procedure tQueue.freeitem;
begin
  if assigned(item) then begin
    with pQueueData(item)^ do if assigned(data) then freemem(data, size);
    dispose(pQueueData(item));
  end;
end;

function tQueue.checkitem;
begin result:= true; end;

procedure tQueue.insertlast(idx: longint; item: pointer);
begin
  while (idx < count) and (compare(items[idx], item) = 0) do inc(idx);
  insert(idx, item);
end;

function tQueue.compare;
var a, b : pAnsiChar;
begin
  result:= pQueueData(item1)^.id - pQueueData(item2)^.id;
  if (result = 0) then begin
    a:= pQueueData(item1)^.data; b:= pQueueData(item2)^.data;
    if assigned(a) and assigned(b) then
      case pQueueData(item1)^.id of
        idWaitSec          : begin
                               result:= pSecuritiesItem(a)^.sec.stock_id - pSecuritiesItem(b)^.sec.stock_id;
                               if (result = 0) then begin
                                 result:= comparetext(pSecuritiesItem(a)^.sec.level, pSecuritiesItem(b)^.sec.level);
                                 if (result = 0) then result:= comparetext(pSecuritiesItem(a)^.sec.code, pSecuritiesItem(b)^.sec.code);
                               end;
                             end;
        idKotUpdates       : begin
                               result:=pKotUpdateHdr(a)^.stock_id - pKotUpdateHdr(b)^.stock_id;
                               if (result = 0) then begin
                                 result:=comparetext(pKotUpdateHdr(a)^.level, pKotUpdateHdr(b)^.level);
                                 if (result = 0) then result:= comparetext(pKotUpdateHdr(a)^.code, pKotUpdateHdr(b)^.code);
                               end;
                             end;
        idAccount          : result:= comparetext(pAccountBuf(a)^.account, pAccountBuf(b)^.account);
        idMarginLevel      : result:= comparetext(pMarginLevel(a)^.account, pMarginLevel(b)^.account);
        idWaitAllTrades    : begin
                               result:= pAllTrades(a)^.stock_id - pAllTrades(b)^.stock_id;
                               if (result = 0) then result:= cmpi64(pAllTrades(a)^.tradeno, pAllTrades(b)^.tradeno);
                             end;
        idWaitOrders       : begin
                               result:= pOrdCollItm(a)^.ord.stock_id - pOrdCollItm(b)^.ord.stock_id;
                               if (result = 0) then result:= cmpi64(pOrdCollItm(a)^.ord.orderno, pOrdCollItm(b)^.ord.orderno);
                             end;
        idWaitTrades       : begin
                               result:= pTrdCollItm(a)^.trd.stock_id - pTrdCollItm(b)^.trd.stock_id;
                               if (result = 0) then begin
                                 result:= cmpi64(pTrdCollItm(a)^.trd.tradeno, pTrdCollItm(b)^.trd.tradeno);
                                 if (result = 0) then result:= byte(pTrdCollItm(a)^.trd.buysell) - byte(pTrdCollItm(b)^.trd.buysell);
                               end;
                             end;
        idTradesQuery      : begin
                               result:= comparetext(pArcTradeBuf(a)^.account, pArcTradeBuf(b)^.account);
                               if (result = 0) then begin
                                 result:= pArcTradeBuf(a)^.stock_id - pArcTradeBuf(b)^.stock_id;
                                 if (result = 0) then result:= comparetext(pArcTradeBuf(a)^.code, pArcTradeBuf(b)^.code);
                               end;
                             end;
        idStopOrder        : result:= cmpi64(pStopOrders(a)^.stopid, pStopOrders(b)^.stopid);
        idNews             : result:= pNewsHeader(a)^.id - pNewsHeader(b)^.id;
        idPing             : result:= plongint(a)^ - plongint(b)^;
        idConsoleLog       : result:= plongint(a)^ - plongint(b)^;
        idClientLimits     : begin
                               result:= comparetext(pClientLimitItem(a)^.limit.account, pClientLimitItem(b)^.limit.account);
                               if (result = 0) then begin
                                 result:= pClientLimitItem(a)^.limit.stock_id - pClientLimitItem(b)^.limit.stock_id;
                                 if (result = 0) then result:= comparetext(pClientLimit(a)^.code, pClientLimit(b)^.code);
                               end;
                             end;
        idAccountRests     : result:= comparetext(pAccountRestsBuf(a)^.account, pAccountRestsBuf(b)^.account);
        idFirmInfo         : begin
                               result:= pFirmItem(a)^.firm.stock_id - pFirmItem(b)^.firm.stock_id;
                               if (result = 0) then result:= comparetext(pFirmItem(a)^.firm.firmid, pFirmItem(b)^.firm.firmid);
                             end;
        idSettleCodes      : begin
                               result:= pSettleCodes(a)^.stock_id - pSettleCodes(b)^.stock_id;
                               if (result = 0) then result:= comparetext(pSettleCodes(a)^.settlecode, pSettleCodes(b)^.settlecode);
                             end;
        idAccountList      : result:= comparetext(pAccountListItm(a)^.account, pAccountListItm(b)^.account);
        idIndividualLimits : result:= comparetext(pIndLimitsBuf(a)^.account, pIndLimitsBuf(b)^.account);
      end;
  end;
end;

procedure tQueue.queue(itm: pQueueData);
var idx    : longint;
    aitem  : pQueueData;
begin
  if assigned(itm) then begin
    locklist;
    try
      if search(itm, idx) then begin
        aitem:= items[idx];
        case itm^.id of
          idWaitSec           : begin
                                  if assigned(srvUpdateSecurities) then
                                    srvUpdateSecurities  ( pSecuritiesItem(itm^.data)^.sec,       pSecuritiesItem(aitem^.data)^.sec,
                                                           pSecuritiesItem(itm^.data)^.secset,    pSecuritiesItem(aitem^.data)^.secset );
                                  freeitem(itm);
                                end;
          idWaitOrders        : begin
                                  if assigned(srvUpdateOrders) then
                                    srvUpdateOrders    ( pOrdCollItm(itm^.data)^.ord,           pOrdCollItm(aitem^.data)^.ord,
                                                         pOrdCollItm(itm^.data)^.ordset,        pOrdCollItm(aitem^.data)^.ordset );
                                  freeitem(itm);
                                end;
          idWaitTrades        : begin
                                  if assigned(srvUpdateTrades) then
                                    srvUpdateTrades    ( pTrdCollItm(itm^.data)^.trd,           pTrdCollItm(aitem^.data)^.trd,
                                                         pTrdCollItm(itm^.data)^.trdset,        pTrdCollItm(aitem^.data)^.trdset );
                                  freeitem(itm);
                                end;
//          idClientLimits      : begin
//                                  srvUpdateClientLimit ( pClientLimitItem(itm^.data)^.limit,    pClientLimitItem(aitem^.data)^.limit,
//                                                         pClientLimitItem(itm^.data)^.limitset, pClientLimitItem(aitem^.data)^.limitset,
//                                                                                                pClientLimitItem(aitem^.data)^.limitset);
//                                  freeitem(itm);
//                                end;
          idFirmInfo          : begin
                                  if assigned(srvUpdateFirmsRec) then
                                    srvUpdateFirmsRec  ( pFirmItem(itm^.data)^.firm,            pFirmItem(aitem^.data)^.firm,
                                                         pFirmItem(itm^.data)^.firmset,         pFirmItem(aitem^.data)^.firmset,
                                                                                                pFirmItem(aitem^.data)^.firmset);
                                  freeitem(itm);
                                end;
          idNews,
          idStopOrder,
          idKotUpdates,
          idAccount,
          idAccountRests,
          idIndividualLimits,
          idAccountList,
          idMarginLevel,
          idWaitAllTrades,
          idSettleCodes,
          idTradesQuery       : begin delete(idx); insert(idx,itm); end;
          idMarginInfo        : freeitem(itm);
          idStockList,
          idMessage           : insertlast(idx, itm);
          else                  insert(idx, itm);
        end;
      end else begin
        case itm^.id of
          idWaitSec           : if assigned(srvCleanupSecurities) then
                                  srvCleanupSecurities ( pSecuritiesItem(itm^.data)^.sec, pSecuritiesItem(itm^.data)^.secset );
          idWaitOrders        : if assigned(srvCleanupOrders) then
                                  srvCleanupOrders     ( pOrdCollItm(itm^.data)^.ord, pOrdCollItm(itm^.data)^.ordset );
          idWaitTrades        : if assigned(srvCleanupTrades) then
                                  srvCleanupTrades     ( pTrdCollItm(itm^.data)^.trd, pTrdCollItm(itm^.data)^.trdset );
        end;
        insert(idx,itm);
      end;
    finally unlocklist; end;
  end;
end;

procedure tQueue.queue(var buf; aid, asize: longint);
var itm    : pQueueData;
begin
  itm:= new(pQueueData);
  with itm^ do begin id:= aid; size:= asize; data:= allocmem(size); system.move(buf, data^, size); end;
  queue(itm);
end;

procedure tQueue.add;
begin queue(pQueueData(item)); end;

end.
