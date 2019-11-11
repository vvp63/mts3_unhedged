{$i tterm_defs.pas}

unit tterm_tables;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$endif}
      sysutils,
      servertypes, protodef,
      tterm_api, tterm_logger;

function EnumerateTables(aref: pointer; acallback: tEnumerateTableRecFunc): longint; stdcall;
function EnumerateTableRecords(aref: pointer; atable_id, aexpected_recsize: longint; aparams: pAnsiChar; aparamsize: longint; acallback: tEnumerateTableRecFunc): longint; stdcall;

implementation

uses legacy_sectable, legacy_kottable, legacy_orderstable, legacy_tradestable, legacy_repotables, legacy_accounts, legacy_alltrdtable;

type  ttable_desc     = record
        table_id      : longint;
        table_name    : pAnsiChar;
        table_recsize : longint;
      end;

const tables_desc : array[0..9] of ttable_desc = 
  ((table_id : idWaitSec;       table_name : 'securities';  table_recsize : sizeof(tSecuritiesItem)),
   (table_id : idStockList;     table_name : 'stocks';      table_recsize : sizeof(tStockRow)),
   (table_id : idLevelList;     table_name : 'levels';      table_recsize : sizeof(tLevelAttrItem)),
   (table_id : idKotUpdates;    table_name : 'orderbook';   table_recsize : 0),
   (table_id : idWaitOrders;    table_name : 'orders';      table_recsize : sizeof(tOrdCollItm)),
   (table_id : idWaitTrades;    table_name : 'trades';      table_recsize : sizeof(tTrdCollItm)),
   (table_id : idFirmInfo;      table_name : 'firms';       table_recsize : sizeof(tFirmItem)),
   (table_id : idAccountList;   table_name : 'accounts';    table_recsize : sizeof(tStockAccListItm)),
   (table_id : idSettleCodes;   table_name : 'settlecodes'; table_recsize : sizeof(tSettleCodes)),
   (table_id : idWaitAllTrades; table_name : 'alltrades';   table_recsize : sizeof(tAllTrades))
   );

function EnumerateTables(aref: pointer; acallback: tEnumerateTableRecFunc): longint; stdcall;
var i : longint;
begin
  if assigned(acallback) then begin
    for i:= low(tables_desc) to high(tables_desc) do with tables_desc[i] do
      if (acallback(aref, table_id, table_name, 0, nil, table_recsize) <> PLUGIN_OK) then break;
    result:= PLUGIN_OK;
  end else result:= PLUGIN_ERROR;
end;

function EnumerateTableRecords(aref: pointer; atable_id, aexpected_recsize: longint; aparams: pAnsiChar; aparamsize: longint; acallback: tEnumerateTableRecFunc): longint; stdcall;
var i, start : longint;
    alltrds  : tAllTradesStorage;
    itm      : pointer;
begin
  result:= PLUGIN_ERROR;
  if assigned(acallback) then try
    case atable_id of
      idWaitSec       : if (aexpected_recsize = sizeof(tSecuritiesItem)) and assigned(securities) then begin
                          EnterCriticalSection(SecuritiesCritSect);
                          try
                            for i:= 0 to securities.count - 1 do
                              if (acallback(aref, atable_id, securities.items[i], sizeof(tSecuritiesItem), nil, 0) <> PLUGIN_OK) then break;
                            result:= PLUGIN_OK;
                          finally LeaveCriticalSection(SecuritiesCritSect); end;
                        end;
      idStockList     : if (aexpected_recsize = sizeof(tStockRow)) and assigned(StockList) then begin
                          StockList.locklist;
                          try
                            for i:= 0 to StockList.count - 1 do
                              if (acallback(aref, atable_id, StockList.items[i], sizeof(tStockRow), nil, 0) <> PLUGIN_OK) then break;
                            result:= PLUGIN_OK;
                          finally StockList.unlocklist; end;
                        end;
      idLevelList     : if (aexpected_recsize = sizeof(tLevelAttrItem)) and assigned(LevelAttr) then begin
                          LevelAttr.locklist;
                          try
                            for i:= 0 to LevelAttr.count - 1 do
                              if (acallback(aref, atable_id, LevelAttr.items[i], sizeof(tLevelAttrItem), nil, 0) <> PLUGIN_OK) then break;
                            result:= PLUGIN_OK;
                          finally LevelAttr.unlocklist; end;
                        end;
      idKotUpdates    : if assigned(Kotirovki) then begin
                          EnterCriticalSection(KotirovkiCritSect);
                          try
                            with tKotCollector.create do try
                              if assigned(aparams) and (aparamsize = sizeof(tKotirovki)) then begin
                                if Kotirovki.search(aparams, i) then repeat
                                  add(pKotirovki(Kotirovki.items[i])^, false);
                                  inc(i);
                                until (i >= Kotirovki.count) or (Kotirovki.compare(aparams, Kotirovki.items[i]) <> 0);
                              end else begin
                                for i:= 0 to Kotirovki.count - 1 do
                                  add(pKotirovki(Kotirovki.items[i])^, false);
                              end;
                              for i:= 0 to count - 1 do with pKotCollItm(items[i])^ do
                                if (acallback(aref, atable_id, buf, buflen, nil, 0) <> PLUGIN_OK) then break;
                              result:= PLUGIN_OK;
                            finally free; end;
                          finally LeaveCriticalSection(KotirovkiCritSect); end;
                        end;
      idWaitOrders    : if (aexpected_recsize = sizeof(tOrdCollItm)) and assigned(orders) then begin
                          EnterCriticalSection(OrdersCritSect);
                          try
                            for i:= 0 to orders.count - 1 do
                              if (acallback(aref, atable_id, orders.items[i], sizeof(tOrdCollItm), nil, 0) <> PLUGIN_OK) then break;
                            result:= PLUGIN_OK;
                          finally LeaveCriticalSection(OrdersCritSect); end;
                        end;
      idWaitTrades    : if (aexpected_recsize = sizeof(tTrdCollItm)) and assigned(trades) then begin
                          EnterCriticalSection(TradesCritSect);
                          try
                            for i:= 0 to trades.count - 1 do
                              if (acallback(aref, atable_id, trades.items[i], sizeof(tTrdCollItm), nil, 0) <> PLUGIN_OK) then break;
                            result:= PLUGIN_OK;
                          finally LeaveCriticalSection(TradesCritSect); end;
                        end;
      idFirmInfo      : if (aexpected_recsize = sizeof(tFirmItem)) and assigned(FirmsTable) then begin
                          EnterCriticalSection(FirmsCritSect);
                          try
                            for i:= 0 to FirmsTable.count - 1 do
                              if (acallback(aref, atable_id, FirmsTable.items[i], sizeof(tFirmItem), nil, 0) <> PLUGIN_OK) then break;
                            result:= PLUGIN_OK;
                          finally LeaveCriticalSection(FirmsCritSect); end;
                        end;
      idAccountList   : if (aexpected_recsize = sizeof(tStockAccListItm)) and assigned(StockAccountList) then begin
                          if assigned(aparams) and (aparamsize = sizeof(tAccount)) then begin
                            itm:= StockAccountList.accountdata[pAccount(aparams)^];
                            if assigned(itm) then acallback(aref, atable_id, itm, sizeof(tStockAccListItm), nil, 0);
                            result:= PLUGIN_OK;
                          end else begin
                            StockAccountList.locklist;
                            try
                              for i:= 0 to StockAccountList.count - 1 do
                                if (acallback(aref, atable_id, StockAccountList.items[i], sizeof(tStockAccListItm), nil, 0) <> PLUGIN_OK) then break;
                              result:= PLUGIN_OK;
                            finally StockAccountList.unlocklist; end;
                          end;
                        end;
      idSettleCodes   : if (aexpected_recsize = sizeof(tSettleCodes)) and assigned(SettleCodesTable) then begin
                          EnterCriticalSection(SettleCodesCritSect);
                          try
                            for i:= 0 to SettleCodesTable.count - 1 do
                              if (acallback(aref, atable_id, SettleCodesTable.items[i], sizeof(tSettleCodes), nil, 0) <> PLUGIN_OK) then break;
                            result:= PLUGIN_OK;
                          finally LeaveCriticalSection(SettleCodesCritSect); end;
                        end;
      idWaitAllTrades : if (aexpected_recsize = sizeof(tAllTrades)) then begin
                          if assigned(aparams) and (aparamsize = sizeof(tAllTrades)) then begin
                            EnterCriticalSection(AllTradesCritSect);
                            try
                              alltrds:= AllTradesRegistry.storagebyalltrade(pAllTrades(aparams)^, start);
                              if assigned(alltrds) then
                                for i:= start to alltrds.count - 1 do
                                  if (acallback(aref, atable_id, alltrds.items[i], sizeof(tAllTrades), nil, 0) <> PLUGIN_OK) then break;
                              result:= PLUGIN_OK;
                            finally LeaveCriticalSection(AllTradesCritSect); end;
                          end; // enum ALL Alltrades is not supported!!!
                        end;
    end;
  except on e:exception do log('ENUMTABLEREC: Exception: %s', [e.message]); end;
end;

exports
  EnumerateTables       name SRV_EnumerateTables,
  EnumerateTableRecords name SRV_EnumerateTableRecords;

end.