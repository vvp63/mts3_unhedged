{$I micexdefs.pas}

unit micexthreads;

interface

uses  {$ifdef MSWINDOWS}
        windows, inifiles,
      {$else}
        fclinifiles,
      {$endif}
      classes, sysutils, math,
      servertypes, sortedlist, custom_threads, syncobj,
      MTETypes, MTEApi,
      micexglobal, micexorderqueue;

type  pBoardRec         = ^tBoardRec;
      tBoardRec         = record
        level           : tLevel;
      end;

type  tBoardRegistry    = class(tSortedThreadList)
        constructor create;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        procedure   registerboard(const alevel: tLevel);
        function    boardexists(const alevel: tLevel): boolean;
      end;

type  tTableDescList    = class(tCustomThreadList)
        procedure   freeitem(item: pointer); override;
      end;

type  tConnectionThread = class(tCustomThread)
      private
        fmax_tries      : longint;
        fSection        : ansistring;
        fConIniItem     : ansistring;
        fTrsIniItem     : ansistring;
        fBoards         : tBoardRegistry;
        fConnected      : boolean;
        fSleeper        : tPreciseSleeper;

        procedure   fSetDelayInterval(ainterval: longint);
      public
        datconnection   : longint;

        ConCsect        : tRTLCriticalSection;

        tablelist       : tTableDescList;
        alivechecker    : int64;

        OrdersQueue     : tOrdersQueue;

        connectionname  : ansistring;

        property    delayinterval: longint write fSetDelayInterval;
      protected
        function    getconnectionstring(const aSection, aIniItem: ansistring): ansistring;
        procedure   getconnectionstringlist(const aSection, aIniItem: ansistring; aconnstrings: tStringList);
        function    CreateConnection(const aconnectionstring, aconnectionid: ansistring; csect: pRTLCriticalSection): longint;
        procedure   DeleteConnection(var aconnection: longint; csect: pRTLCriticalSection);
      public
        constructor create(const aSection, aConIniItem, aTrsIniItem: ansistring; adelay: longint);
        destructor  destroy; override;

        procedure   connect; virtual;
        procedure   disconnect; virtual;

        function    boardexists(const alevel: tLevel): boolean;

        procedure   execute; override;

        property    Boards: tBoardRegistry read fBoards;
        property    Connected: boolean read fConnected;
      end;

implementation

uses micexint;

{ common functions }

procedure advancedreplace(var init: ansistring; const old, new: ansistring);
var ps : longint;
begin
  repeat
    ps:= pos(old, init);
    if (ps > 0) then begin delete(init, ps, length(old)); insert(new, init, ps); end;
  until (ps <= 0);
end;


{ tBoardRegistry }

constructor tBoardRegistry.create;
begin inherited create; fDuplicates:= dupIgnore; end;

procedure   tBoardRegistry.freeitem(item: pointer);
begin if assigned(item) then dispose(pBoardRec(item)); end;

function    tBoardRegistry.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function    tBoardRegistry.compare(item1, item2: pointer): longint;
begin result:= comparetext(pBoardRec(item1)^.level, pBoardRec(item2)^.level); end;

function    tBoardRegistry.boardexists(const alevel: tLevel): boolean;
var sitm : tBoardRec;
    idx  : longint;
begin
  sitm.level:= alevel;
  locklist;
  try result:= search(@sitm, idx);
  finally unlocklist; end;
end;

procedure   tBoardRegistry.registerboard(const alevel: tLevel);
var sitm : tBoardRec;
    itm  : pBoardRec;
    idx  : longint;
begin
  sitm.level:= alevel;
  locklist;
  try
    if not search(@sitm, idx) then begin
      itm:= new(pBoardRec);
      itm^.level:= alevel;
      add(itm);
    end;
  finally unlocklist; end;
end;

{ tTableDescList }

procedure tTableDescList.freeitem(item: pointer);
begin if assigned(item) then tTableDescriptor(item).free; end;

{ tConnectionThread }

constructor tConnectionThread.create;
begin
  inherited create(true);
  micexlog('Opening connection...');
  freeonterminate:= false;

  fConnected:= false;

  fBoards:= tBoardRegistry.create;

  {$ifdef FPC}
  InitCriticalSection(ConCsect);
  {$else}
  InitializeCriticalSection(ConCsect);
  {$endif}

  tablelist:= tTableDescList.Create;
  alivechecker:= 0;

  fSection:= aSection;
  fConIniItem:= aConIniItem;
  fTrsIniItem:= aTrsIniItem;

  fmax_tries:= 1;

  datconnection:= -1;

  OrdersQueue:= tOrdersQueue.create;
  fSleeper:= tPreciseSleeper.create(adelay);
end;

destructor tConnectionThread.destroy;
begin
  if assigned(tablelist) then
    with tablelist.locklist do try
      clear;
    finally tablelist.unlocklist; end;

  Disconnect;

  if assigned(OrdersQueue) then freeandnil(OrdersQueue);

  if assigned(tablelist) then freeandnil(tablelist);

  {$ifdef FPC}
  DoneCriticalSection(ConCsect);
  {$else}
  DeleteCriticalSection(ConCsect);
  {$endif}

  if assigned(fBoards) then freeandnil(fBoards);
  if assigned(fSleeper) then freeandnil(fSleeper);

  micexlog('connection thread finished.');
  inherited destroy;
end;

procedure tConnectionThread.fSetDelayInterval(ainterval: longint);
begin
  if assigned(fSleeper) then fSleeper.interval:= ainterval;
end;

function tConnectionThread.getconnectionstring(const aSection, aIniItem: ansistring): ansistring;
begin
  setlength(result, 0);
  if fileexists(cfgname) then begin
    with tIniFile.create(cfgname) do try
      result     :=     ReadString  (aSection, aIniItem, '');
      fmax_tries := max(ReadInteger ('connections', 'max_tries', 1), 1);
    finally free; end;
    if length(result) > 0 then begin
      advancedreplace(result, '\n', #13);
      advancedreplace(result, '\r', #10);
    end;
  end;
end;

procedure tConnectionThread.getconnectionstringlist(const aSection, aIniItem: ansistring; aconnstrings: tStringList);
var cname : ansistring;
    i     : longint;
    sl    : tStringList;
begin
  if assigned(aconnstrings) and (length(aIniItem) > 0) then begin
    if fileexists(cfgname) then begin
      sl:= tStringList.create;
      try
        with tIniFile.create(cfgname) do try
          fmax_tries := max(ReadInteger ('connections', 'max_tries', 1), 1);
          if sectionexists(aSection) then begin
            readsection(aSection, sl);
            for i:= 0 to sl.count - 1 do
              if (pos(lowercase(aIniItem), lowercase(sl[i])) = 1) then begin
                cname:= ReadString (aSection, sl[i], '');
                if length(cname) > 0 then begin
                  advancedreplace(cname, '\n', #13);
                  advancedreplace(cname, '\r', #10);
                  aconnstrings.add(cname);
                end;
              end;
          end;
        finally free; end;
      finally sl.free; end;
    end;
  end;
end;

function tConnectionThread.CreateConnection(const aconnectionstring, aconnectionid: ansistring; csect: pRTLCriticalSection): longint;
var err : TMTEErrorMsg;
    i   : longint;
begin
  result:= -1;
  if (length(aconnectionstring) > 0) then begin
    if assigned(csect) then EnterCriticalSection(csect^);
    try
      i:= 0;
      while (i < fmax_tries) and (result < MTE_OK) do begin
        fillchar(err, sizeof(err), 0);
        result:= MTEConnect(pAnsiChar(aconnectionstring), @err);
        if (result >= MTE_OK) then begin
          fillchar(err, sizeof(err), 0);
          MTEExecTrans(result, 'CHANGE_LANGUAGE', 'E', @err);
          micexlog('try: %d connection %s opened successfully.', [i, aconnectionid]);
        end else micexlog('try: %d connection %s opened: %d Reply: %s', [i, aconnectionid, result, trim(err)]);
        inc(i);
      end;
    finally if assigned(csect) then LeaveCriticalSection(csect^); end;
  end;
end;

procedure tConnectionThread.DeleteConnection(var aconnection: longint; csect: pRTLCriticalSection);
begin
  if (aconnection >= MTE_OK) then begin
    if assigned(csect) then EnterCriticalSection(csect^);
    try
      MTEDisconnect(aconnection); aconnection:= -1;
    finally if assigned(csect) then LeaveCriticalSection(csect^); end;
  end;
end;

procedure tConnectionThread.connect;
var sl : tStringList;
    i  : longint;
begin
  try
    Disconnect;
    if (datconnection < MTE_OK) then datconnection:= CreateConnection(getconnectionstring(fSection, fConIniItem), connectionname, @ConCsect);
    if assigned(OrdersQueue) then begin
      sl:= tStringList.create;
      try
        getconnectionstringlist(fSection, fTrsIniItem, sl);
        for i:= 0 to sl.count - 1 do
          OrdersQueue.AddTransactionConnection(CreateConnection(sl[i], format('%s/trs%d', [connectionname, i]), nil), fSection);
      finally sl.free; end;
    end;
    fConnected:= (datconnection >= MTE_OK);
  except on e: exception do micexlog('exception while connecting (%s): %s', [connectionname, e.message]); end;
end;

procedure tConnectionThread.disconnect;
begin
  try
    if (datconnection >= MTE_OK) then DeleteConnection(datconnection, @ConCsect);
    if assigned(OrdersQueue) then OrdersQueue.FreeTransactionConnections;
    fConnected:= false;
  except on e: exception do micexlog('exception while disconnecting (%s): %s', [connectionname, e.message]); end;
end;

function  tConnectionThread.boardexists(const alevel: tLevel): boolean;
begin result:= assigned(fBoards) and fBoards.boardexists(alevel); end;

procedure tConnectionThread.execute;
var i, errcode : longint;
begin
  try
    Connect;
    while not terminated do begin
      if assigned(fSleeper) then fSleeper.reset;
      if not terminated and (datconnection >= MTE_OK) and assigned(tablelist) then begin
        with tablelist.locklist do try
          for i:= 0 to count - 1 do with tTableDescriptor(items[i]) do begin
            if not terminated then try
              if not opened then begin errcode:= open;   if errcode < MTE_OK then micexlog('Opening failed: %s code: %d', [tablename, errcode]); end
                            else begin errcode:= update; if errcode < MTE_OK then micexlog('Update failed: %s code: %d', [tablename, errcode]); end;
            except on e: exception do micexlog('CONNECTION: %s Table: %s Exception: %s', [connectionname, tablename, e.message]); end;
          end;
        finally tablelist.unlocklist; end;
      end;
      if not terminated then begin
        if assigned(fSleeper) then begin
          while not fSleeper.expired do sleep(1);
        end else sleep(50);
        inc(alivechecker);
      end;
    end;
    micexlog('CONNECTION: %s terminated!', [connectionname]);
  except on e:exception do micexlog('CONNECTION: %s Exception: %s', [connectionname, e.message]); end;
end;

end.