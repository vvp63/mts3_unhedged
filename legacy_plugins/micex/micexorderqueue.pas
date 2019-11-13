{$I micexdefs.pas}

unit micexorderqueue;

interface

uses  windows, classes, sysutils, inifiles, math,
      sortedlist, threads, syncobj,
      servertypes, serverapi,
      MTETypes, MTEApi, MTEUtils,
      micexglobal, micexsubst;

type  tOrderAction       = (actSetOrder, actDropOrder);

type  pOrderQueueItem    = ^tOrderQueueItem;
      tOrderQueueItem    = record
        action           : tOrderAction;
        res              : tSetOrderResult;
        case tOrderAction of
          actSetOrder  : ( order    : tOrder;
                           comment  : tOrderComment;
                         );
          actDropOrder : ( orderno  : int64;
                           flags    : longint;
                           stock_id : longint;
                           level    : TLevel;
                           code     : TCode;
                         );
      end;

type  tOrdersQueue       = class;

      tTransactionThread = class(tCustomThread)
      private
        FEvent           : THandle;
        FQueue           : tOrdersQueue;
        FThreadCount     : plongint;
        FConnHandle      : longint;
        FSleeper         : tPreciseSleeper;
        FKeepAliveHandle : longint;
        FSetOrderTpl     : ansistring;
        FCCPBoards       : tStringList;
      protected
        procedure   doSetOrder(var QueueItem: tOrderQueueItem);
        procedure   doDropOrder(var QueueItem: tOrderQueueItem);
        procedure   doKeepAlive;
      public
        constructor create(aconnhandle: longint; var athreadcount: longint; var aevent: THandle; aqueue: tOrdersQueue; const asection: ansistring);
        destructor  destroy; override;
        procedure   execute; override;
      end;

      tTrsThreadList     = class(tCustomList)
        procedure   freeitem(item: pointer); override;
      end;

      tOrdersQueue       = class(tCustomThreadList)
      private
        FEvReady         : THandle;
        FThreadCount     : longint;
        FTrsThreads      : tTrsThreadList;
        procedure   DropWaitingOrder(var aqueueitem: tOrderQueueItem);
      protected
        function    GetOrderQueueItem(var aqueueitem: tOrderQueueItem): boolean;
      public
        constructor create;
        destructor  destroy; override;
        procedure   freeitem(item: pointer); override;
        function    AddNewOrder(const aorder: tOrder; const acomment: tOrderComment;
                                var ares: tSetOrderResult): boolean;
        function    AddDropOrder(aorderno: int64; aflags: longint;
                                 astock_id: longint; const alevel: TLevel; const acode: TCode;
                                 var ares: tSetOrderResult): boolean;
        function    AddTransactionConnection(ahandle: longint; const asection: ansistring): boolean;
        function    FreeTransactionConnections: boolean;
      end;

implementation

{ common functions }

function pricetopaddedstr(aprice, alen: longint): ansistring;
var apad: longint;
begin
  if (aprice >= 0) then apad:= alen else apad:= alen - 1;
  result:= format('%*.*d', [alen, apad, aprice]);
end;

procedure ParseStockReply(st: shortstring; strlist: tStringList);
var i  : longint;
    ns : shortstring;
    lc : char;
begin
  if assigned(strlist) then begin
    strlist.clear;
    i:= 1; ns:= ''; lc:= #0;
    while i<length(st) do begin
      if (st[i] in ['0'..'9']) then ns:= ns + st[i]
                               else if (lc in ['0'..'9']) then begin
                                      strlist.add(ns);
                                      setlength(ns, 0);
                                    end;
      lc:= st[i]; inc(i);
    end;
    if (length(ns) > 0) then strlist.add(ns);
  end;
end;

function  MTEErrorToStr (const mteerror: TMTEErrorMsg): ansistring;
begin setstring(result, pAnsiChar(@mteerror), min(strlen(pAnsiChar(@mteerror)), sizeof(mteerror))); end;

{ tTransactionThread }

constructor tTransactionThread.create(aconnhandle: longint; var athreadcount: longint; var aevent: THandle; aqueue: tOrdersQueue; const asection: ansistring);
var cname: ansistring;
begin
  inherited create(false);
  freeonterminate:= false;
  FConnHandle:= aconnhandle;
  FEvent:= aevent;
  FQueue:= aqueue;
  FThreadCount:= @athreadcount;
  FSleeper:= tPreciseSleeper.create(keepalivetimeout);
  FKeepAliveHandle:= -1;

  {$ifdef InterfaceV12}
  FSetOrderTpl:= '%-12.12s%s%sS%sP %-4.4s%-12.12s%.9d%.10d%-5.5s/%-5.5s/%-8.8s%.12d%-6.6s';
  {$else}
  FSetOrderTpl:= '%-12.12s%s%sS%sP%-4.4s%-12.12s%.9d%.10d%-5.5s/%-5.5s/%-8.8s%.12d'
  {$endif}

  cname:= format('%s\%s', [pluginpath, cfgname]);
  if fileexists(cname) then
    with tIniFile.create(cname) do try
      FSetOrderTpl := readstring(asection, 'ORDER_template', FSetOrderTpl);
      cname        := readstring(asection, 'CCPBoards',      '');
      if (length(cname) > 0) then begin
        FCCPBoards:= tStringList.Create;
        FCCPBoards.sorted:= true;
        FCCPBoards.CommaText:= cname;
      end;
    finally free; end;
end;

destructor tTransactionThread.destroy;
begin
  if (FConnHandle >= MTE_OK) then begin
    if (FKeepAliveHandle >= MTE_OK) then MTECloseTable(FConnHandle, FKeepAliveHandle);
    MTEDisconnect(FConnHandle);
  end;
  if assigned(FSleeper) then freeandnil(FSleeper);
  if assigned(FCCPBoards) then freeandnil(FCCPBoards);
  inherited destroy;
end;

procedure tTransactionThread.doSetOrder(var QueueItem: tOrderQueueItem);
var c1, c2      : char;
    paramstr    : ansistring;
    trsname     : ansistring;
    devider     : cardinal;
    errormsg    : TMTEErrorMsg;
    err         : longint;
    sl          : tStringList;
    lotsize     : cardinal;
    tmp1, tmp2  : ansistring;
    accnt       : tAccount;
    subid       : tClientID;
begin
  with QueueItem do begin
    with order do begin
      // make subsitiutions
      if assigned(subst_cid) then cid:= subst_cid.subst[cid];
      if assigned(subst_acc) then accnt:= subst_acc.subst[res.account]
                             else accnt:= res.account;
      subid:= copy(accnt, 9, 5);

      if assigned(FCCPBoards) and FCCPBoards.Find(level, err) then flags:= flags or opCCP;

      devider:= ExtractDivider(level, code, lotsize);
      if (flags and opMarketPrice) = opMarketPrice then begin c1:='M'; price:=0; end else c1:='L';
      case (flags and (opImmCancel or opWDRest)) of
        opImmCancel : c2:='N';
        opWDRest    : c2:='W';
        else          c2:=' ';
      end;

      if ((flags and opRepoDeal) <> 0) then begin
        if (reporate <> 0) then tmp1:= format('%.9d',[round(reporate*100)])   else setlength(tmp1, 0);
        if (price2   <> 0) then tmp2:= format('%.9d',[round(price2*devider)]) else setlength(tmp2, 0);
        paramstr:= format('%-12.12s%s%-4.4s%-12.12s%-12.12s%.9d%.10d%-5.5s/%-5.5s/%-8.8s%-10.10s%-3.3s%.12d%.9d%9.9s%9.9s',
                          [account, buysell, level, code, cfirmid, round(price * devider), quantity, cid, subid,
                           comment, match, settlecode, transaction, round(refundrate * 100), tmp1, tmp2]);
        trsname:= 'REPO_NEGDEAL';
      end else
      if ((flags and opRPSDeal) <> 0) then begin
        paramstr:= format('%-12.12s%s%-4.4s%-12.12s%-12.12s%.9d%.10d%-5.5s/%-5.5s/%-8.8s%-10.10s%-3.3s%.12d%-9.9s',
                          [account, buysell, level, code, cfirmid, round(price*devider), quantity, cid, subid, comment,
                           match, settlecode, transaction, '']);
        trsname:= 'NEGDEAL';
      end else
      {$ifdef EnableAuction}
      if ((flags and opAuct) <> 0) then begin
        paramstr:= format('%-12.12s%-4.4s%-12.12s%-5.5s/%-5.5s/%-8.8s%.16d',
                          [account, level, code, cid, subid, clientid, round(price * quantity * lotsize)]);
        trsname:=  'AUCTION_MKT_ORDER';
      end else
      {$endif}
      if ((flags and opCCP) <> 0) then begin
        paramstr:= format('%-12.12s%s%sS%sP %-4.4s%-12.12s%-9.9s%.10d%-5.5s/%-5.5s/%-8.8s                %.12d%8:-5.5s       ',
                          [account, buysell, c1, c2, level, code, pricetopaddedstr(round(price * devider), 9), quantity,
                           cid, subid, comment, transaction, '']);
        trsname:= 'CCP_REPO_ORDER';
      end else
      begin
// "%-12.12s%s%sS%sP  %-4.4s%-12.12s%.9d%.10d0000000000%-5.5s/%-5.5s/%-8.8s                %.12d%-6.6s%8:-5.5s       "
        paramstr:= format(FSetOrderTpl,
                          [account, buysell, c1, c2, level, code, round(price * devider), quantity,
                           cid, subid, comment, transaction, '']);
//        paramstr:= format(FSetOrderTpl,
//                          [account, buysell, c1, c2, level, code, round(price * devider), quantity,
//                           cid, accnt, comment, transaction, '']);
        trsname:= 'ORDER';
      end;

      fillchar(errormsg, sizeof(TMTEErrorMsg), 0);
      try err:= MTEExecTrans(FConnHandle, pAnsiChar(trsname), pAnsiChar(paramstr), @ErrorMsg);
      except on e:exception do begin micexlog('EXECTRANS: Exception: %s', [e.message]); err:= MTE_TSMR; end; end;

      with res do begin
        TEReply:= MTEErrorToStr(errormsg); ExtNumber:=0;
        case err of
          MTE_OK   : try
                       sl:= tStringList.create;
                       try
                         ParseStockReply(TEReply, sl);
                         if (sl.count >= 2) then begin
                           accepted:= soAccepted;
                           ExtNumber:= strtoint64(sl.strings[1])
                         end else begin ExtNumber:= 0; accepted:= soError; end;
                       finally sl.free; end;
                     except
                       on e: exception do begin
                         micexlog('PARSERESULT: Exception: %s', [e.message]);
                         ExtNumber:= 0; accepted:= soError;
                       end;
                     end;
          {$ifndef no_SOError_on_MTETSMR}
          MTE_TSMR : accepted:= soError;
          {$endif}
          else       accepted:= soRejected;
        end;
        if (err < 0) then micexlog(format('MTE Result: %d', [err]));
      end;
    end;
    if assigned(Server_API.SetTrsResult) then Server_API.SetTrsResult(res);
  end;
end;

procedure tTransactionThread.doDropOrder(var QueueItem: tOrderQueueItem);
var err         : longint;
    errormsg    : TMTEErrorMsg;
    paramstr    : ansistring;
    trsname     : ansistring;
begin
  with QueueItem do begin
    if (flags and (opRPSDeal or opRepoDeal) = 0) then begin
      paramstr := format('%.12d', [orderno]);
      trsname  := 'WD_ORDER_BY_NUMBER';
    end else begin
      paramstr := format('%.12d            ', [orderno]);
      trsname  := 'WD_NEGDEAL';
    end;

    fillchar(errormsg, sizeof(TMTEErrorMsg), 0);
    try err:= MTEExecTrans(FConnHandle, pAnsiChar(trsname), pAnsiChar(paramstr), @errormsg);
    except on e: exception do begin micexlog('EXECTRANS: Exception: %s', [e.message]); err:= MTE_TSMR; end; end;

    with res do begin
      TEReply:= MTEErrorToStr(errormsg); ExtNumber:=0;
      case err of
        MTE_OK   : accepted:= soDropAccepted;
        {$ifndef no_SOError_on_MTETSMR}
        MTE_TSMR : accepted:= soError;
        {$endif}
        else       accepted:= soDropRejected;
      end;
    end;
    if assigned(Server_API.SetTrsResult) then Server_API.SetTrsResult(res);
  end;
end;

procedure tTransactionThread.doKeepAlive;
var heap : pMTEMsg;
begin
  try
    if FKeepAliveHandle < MTE_OK then begin
      FKeepAliveHandle:= MTEOpenTable(FConnHandle, 'TESYSTIME', '', openTableComplete, heap);
    end else begin
      MTEAddTable(FConnHandle, FKeepAliveHandle, 0);
      MTERefresh(FConnHandle, heap);
    end;
  except on e: exception do micexlog('EXECTRANS: Exception: %s', [e.message]); end;
end;

procedure tTransactionThread.execute;
var QueueItem : tOrderQueueItem;
begin
  InterLockedIncrement(fThreadCount^);
  try
    while not terminated do begin
      WaitForSingleObject(FEvent, 500);
      if not terminated and assigned(FQueue) then
        if FQueue.GetOrderQueueItem(QueueItem) then begin
          repeat
            case QueueItem.action of
              actSetOrder  : doSetOrder(QueueItem);
              actDropOrder : doDropOrder(QueueItem);
            end;
          until not FQueue.GetOrderQueueItem(QueueItem);
          if assigned(FSleeper) then FSleeper.reset;
        end else begin
          if keepalive then
            if assigned(FSleeper) and FSleeper.expired then begin
              doKeepAlive;
              FSleeper.reset;
            end;
        end;
    end;
  finally InterLockedDecrement(fThreadCount^); end;
end;

{ tTrsThreadList }

procedure tTrsThreadList.freeitem(item: pointer);
begin
  if assigned(item) then
    with tTransactionThread(item) do try
      terminate; waitfor;
    finally freeandnil(item); end;
end;

{ tOrdersQueue }

constructor tOrdersQueue.create;
begin
  inherited create;
  FThreadCount:= 0;
  FEvReady:= CreateEvent(nil, False, False, nil);
  FTrsThreads:= tTrsThreadList.create;
end;

destructor tOrdersQueue.destroy;
var aitem : tOrderQueueItem;
begin
  if assigned(FTrsThreads) then freeandnil(FTrsThreads);
  while getorderqueueitem(aitem) do DropWaitingOrder(aitem);
  if (FEvReady <> 0) then CloseHandle(FEvReady);
  inherited destroy;
end;

procedure tOrdersQueue.freeitem(item: pointer);
begin if assigned(item) then dispose(pOrderQueueItem(item)); end;

procedure tOrdersQueue.DropWaitingOrder(var aqueueitem: tOrderQueueItem);
begin
  with aqueueitem do
    if (action = actSetOrder) then try
       with res do begin accepted:= soRejected; ExtNumber:= 0; TEReply:= 'MICEX: Module shutdown in progress'; end;
    finally if assigned(Server_API.SetTrsResult) then Server_API.SetTrsResult(res); end;
end;

function tOrdersQueue.AddNewOrder(const aorder: tOrder; const acomment: tOrderComment; var ares: tSetOrderResult): boolean;
var itm : pOrderQueueItem;
begin
  result:= false;
  if (FThreadCount > 0) then begin
    itm:= new(pOrderQueueItem);
    with itm^ do begin
      action:= actSetOrder;
      res:= ares;
      order:= aorder;
      comment:= acomment;
    end;
    with locklist do try
      add(itm);
    finally unlocklist; end;
    SetEvent(FEvReady);
    with ares do begin accepted := soUnknown; ExtNumber:= 0; TEReply:= ''; end;
    result:= true;
  end else begin
    with ares do begin accepted := soRejected; ExtNumber:= 0; TEReply:= 'MICEX: No transaction threads!'; end;
  end;
end;

function tOrdersQueue.AddDropOrder(aorderno: int64; aflags: longint; astock_id: longint; const alevel: TLevel; const acode: TCode; var ares: tSetOrderResult): boolean;
var itm : pOrderQueueItem;
begin
  result:= false;
  if (FThreadCount > 0) then begin
    itm:= new(pOrderQueueItem);
    with itm^ do begin
      action:= actDropOrder;
      res:= ares;
      orderno:= aorderno;
      flags:= aflags;
      stock_id:= astock_id;
      level:= alevel;
      code:= acode;
    end;
    with locklist do try
      add(itm);
    finally unlocklist; end;
    SetEvent(FEvReady);
    with ares do begin accepted := soAccepted; ExtNumber:= 0; TEReply:= ''; end;
    result:= true;
  end else begin
    with ares do begin accepted := soRejected; ExtNumber:= 0; TEReply:= 'MICEX: No transaction threads!'; end;
  end;
end;

function tOrdersQueue.GetOrderQueueItem(var aqueueitem: tOrderQueueItem): boolean;
begin
  result:= false;
  with locklist do try
    if (count > 0) then try
      aqueueitem:= pOrderQueueItem(items[0])^;
      result:= true;
    finally delete(0); end;
  finally unlocklist; end;
end;

function tOrdersQueue.AddTransactionConnection(ahandle: longint; const asection: ansistring): boolean;
var thread : tTransactionThread;
begin
  result:= false;
  if (ahandle >= MTE_OK) and assigned(FTrsThreads) then begin
    thread:= tTransactionThread.create(ahandle, FThreadCount, FEvReady, Self, asection);
    FTrsThreads.add(thread);
    result:= true;
  end;
end;

function tOrdersQueue.FreeTransactionConnections: boolean;
begin
  if assigned(FTrsThreads) then begin
    FTrsThreads.clear;
    result:= true;
  end else result:= false;
end;

end.
