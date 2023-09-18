unit mts3lx_sheldue;

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
      mts3lx_start,
      mts3lx_common;

type  pScheldueItem = ^tScheldueItem;
      tScheldueItem  = record
        Id            : longint;
        StartTime     : real;
        StopTime      : real;
        SecBeforeStop : real;
end;


type tScheldueList = class(tSortedList)
      procedure   freeitem(item: pointer); override;
      function    checkitem(item: pointer): boolean; override;
      function    compare(item1, item2: pointer): longint; override;
    public
      procedure   LoadScheldue;
      function    IsInDay(atime : TDateTime)  : boolean;
      function    IsActiveInDay(atime : TDateTime)  : boolean;
      function    IsInDayToAvg(atime: TDateTime): boolean;
      function    DayStartTime  : TDateTime;
end;


const     TradeScheldue   : tScheldueList   = nil;

procedure InitScheldue;
procedure DoneScheldue;


implementation



{ tTPSecList }

function tScheldueList.checkitem(item: pointer): boolean;
begin result:=  assigned(item); end;

function tScheldueList.compare(item1, item2: pointer): longint;
begin result:=  pScheldueItem(item1)^.Id - pScheldueItem(item2)^.Id; end;


procedure tScheldueList.freeitem(item: pointer);
begin if assigned(item) then dispose(pScheldueItem(item)); end;


function tScheldueList.IsActiveInDay(atime: TDateTime): boolean;
var i : longint;
    vtime : real;
begin
  result:=  false; vtime:=  frac(atime);
  for i:= 0 to Count-1 do with pScheldueItem(items[i])^ do
    if (vtime >= StartTime) and (vtime <= (StopTime - SecBeforeStop)) then begin
      Result:=  true; break;
    end;
end;

function tScheldueList.IsInDay(atime: TDateTime): boolean;
var i : longint;
    vtime : real;
begin
  result:=  false; vtime:=  frac(atime);
  for i:= 0 to Count-1 do with pScheldueItem(items[i])^ do
    if (vtime >= StartTime) and (vtime <= StopTime) then begin
      Result:=  true; break;
    end;
end;


function tScheldueList.IsInDayToAvg(atime: TDateTime): boolean;
var i : longint;
    vtime : real;
begin
  result:=  false; vtime:=  frac(atime);
  for i:= 0 to Count-1 do with pScheldueItem(items[i])^ do
    if (vtime >= StartTime + 10 * SecDelay) and (vtime <= StopTime - 10 * SecDelay) then begin
      Result:=  true; break;
    end;
end;

function tScheldueList.DayStartTime: TDateTime;
var i : longint;
begin
  Result:=  1;
  for i:= 0 to Count-1 do with pScheldueItem(items[i])^ do If (StartTime < Result) Then Result:=  StartTime;
end;




procedure tScheldueList.LoadScheldue;
var vpscheldue  : pScheldueItem;
    res : PPGresult;
    i, j    : longint;
    SL      : tStringList;
begin
  FileLog('MTS3LX_SHELDUE. LoadScheldue');
  clear;
  if (PQstatus(gPGConn) = CONNECTION_OK) then begin
  res := PQexec(gPGConn, 'SELECT public.gettradescheldue()');
    if (PQresultStatus(res) <> PGRES_TUPLES_OK) then log('MTS3LX_SHELDUE. LoadScheldue  : gettradescheldue() error')
    else 
      for i := 0 to PQntuples(res)-1 do begin
        SL :=  QueryResult(PQgetvalue(res, i, 0));
        if SL.Count > 3 then begin
        new(vpscheldue);
        with vpscheldue^ do begin
          Id            :=  StrToIntDef(SL[0], 0);
          StartTime     :=  frac(StrToDateTime(copy(SL[1], 2, length(SL[1]) - 2)));
          StopTime      :=  frac(StrToDateTime(copy(SL[2], 2, length(SL[2]) - 2)));
          SecBeforeStop :=  StrToIntDef(SL[3], 0) * SecDelay;
        end;
        add(vpscheldue);
        end;
      end;
    PQclear(res);

    for i:= 0 to Count-1 do with pScheldueItem(items[i])^ do
      FileLog('MTS3LX_SHELDUE. LoadScheldue   :   %d %.8g-%.8g  %.8g', [Id, StartTime, StopTime, SecBeforeStop], 2);

  end;


end;


//    -----------------------------------

procedure InitScheldue;
begin
  TradeScheldue:= tScheldueList.create;
  if assigned(TradeScheldue) then TradeScheldue.LoadScheldue;
  log('MTS3LX_SHELDUE. Started');
end;


procedure DoneScheldue;
begin
  if assigned(TradeScheldue) then freeandnil(TradeScheldue);
  log('MTS3LX_SHELDUE. Finished');
end;



end.
