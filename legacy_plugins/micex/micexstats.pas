{$I micexdefs.pas}

unit micexstats;

interface

uses  windows, sysutils, inifiles,
      lowlevel, sortedlist,
      servertypes,
      micexglobal;

type  pStatsInfoRec   = ^tStatsInfoRec;
      tStatsInfoRec   = record
        stock_id      : longint;
        level         : tLevel;
        code          : tCode;
        lastdt        : tDateTime;
        lastprice     : currency;
        lastqty       : int64;
      end;

type  tStatsCollector = class(tSortedThreadList)
      private
        fEnabled      : boolean;
        procedure   SetEnabled(AEnabled: boolean);
      public
        constructor create(AEnabled: boolean);
        procedure   freeitem(item:pointer); override;
        function    checkitem(item:pointer):boolean; override;
        function    compare(item1,item2:pointer):longint; override;

        procedure   setstats(astock_id: longint; const alevel: tLevel; const acode: tCode;
                             const alastdt: tDateTime; const alastprice: currency; const alastqty: int64);
        procedure   outputstats;

        property    enabled: boolean read fEnabled write SetEnabled;
      end;

const statscollector : tStatsCollector = nil;

procedure EnableStatsCollector(AEnable: boolean);
procedure SetAlltradesStats(const alltrades: tAllTrades);
procedure OutputStats;

implementation

const stats_bv : array[boolean] of string = ('disabled', 'enabled');

{ tStatsCollector }

constructor tStatsCollector.create(AEnabled: boolean);
begin
  inherited create;
  fDuplicates:= dupIgnore;
  fEnabled:= AEnabled;
end;

procedure tStatsCollector.freeitem(item: pointer);
begin if assigned(item) then dispose(pStatsInfoRec(item)); end;

function tStatsCollector.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tStatsCollector.compare(item1, item2: pointer): longint;
begin
  result:= pStatsInfoRec(item1)^.stock_id - pStatsInfoRec(item2)^.stock_id;
  if result = 0 then result:= comparetext(pStatsInfoRec(item1)^.level, pStatsInfoRec(item2)^.level);
end;

procedure tStatsCollector.SetEnabled(AEnabled: boolean);
begin
  if (fEnabled <> AEnabled) then try
    if AEnabled then begin
      locklist;
      try clear;
      finally unlocklist; end;
    end;
  finally fEnabled:= AEnabled; end;
end;

procedure tStatsCollector.setstats(astock_id: Integer; const alevel: tLevel; const acode: tCode;
                                   const alastdt: tDateTime; const alastprice: currency; const alastqty: int64);
var itm  : pStatsInfoRec;
    idx  : longint;
    sitm : tStatsInfoRec;
begin
  if fEnabled then begin
    sitm.stock_id:= astock_id; sitm.level:= alevel;
    locklist;
    try
      if search(@sitm, idx) then begin
        with pStatsInfoRec(items[idx])^ do begin
          if (lastdt < alastdt) then begin
            code      := acode;
            lastdt    := alastdt;
            lastprice := alastprice;
            lastqty   := alastqty;
          end;
        end;
      end else begin
        itm:= new(pStatsInfoRec);
        with itm^ do try
          stock_id  := astock_id;
          level     := alevel;
          code      := acode;
          lastdt    := alastdt;
          lastprice := alastprice;
          lastqty   := alastqty;
        finally insert(idx, itm); end;
      end;
    finally unlocklist; end;
  end;
end;

procedure tStatsCollector.outputstats;
var   i  : longint;
begin
  locklist;
  try
    if (count > 0) then begin
      micexlog('statistics: %s', [stats_bv[fEnabled]]);
      for i:= 0 to count - 1 do with pStatsInfoRec(items[i])^ do
        micexlog('brd: %s dt: %s  itm: %s/%.3f/%d',
                 [level, formatdatetime('mm/dd hh:nn:ss', lastdt), code, lastprice, lastqty]);
    end else micexlog('statistics: %s; no stats collected', [stats_bv[fEnabled]]);
  finally unlocklist; end;
end;

{common functions}

procedure EnableStatsCollector(AEnable: boolean);
begin
  if assigned(statscollector) then begin
    statscollector.enabled:= AEnable;
  end else begin
    if AEnable then statscollector:= tStatsCollector.create(AEnable);
  end;
  micexlog('statistics: %s', [stats_bv[(assigned(statscollector) and statscollector.enabled)]]);
end;

procedure SetAlltradesStats(const alltrades: tAllTrades);
begin
  if assigned(statscollector) then
    with alltrades do statscollector.setstats(stock_id, level, code, tradetime, price, quantity);
end;

procedure OutputStats;
begin if assigned(statscollector) then statscollector.outputstats else micexlog('statistics: disabled'); end;

initialization

finalization
  if assigned(statscollector) then freeandnil(statscollector);

end.