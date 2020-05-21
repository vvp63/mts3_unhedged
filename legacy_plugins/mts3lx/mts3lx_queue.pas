unit mts3lx_queue;

interface


uses {$ifdef MSWINDOWS}
        windows,
      {$else}
        cmem,
        cthreads,
      {$endif}
      dynlibs,
      sysutils,
      threads,
      sortedlist,
      classes,
      strings,      
      servertypes,
      postgres,
      mts3lx_common;

type  tQueueType  = (ev_type_order, ev_type_trade, ev_type_soresult,
                       ev_type_quots, ev_type_sec, ev_type_quoteTP, ev_type_command);


type pQueueItem = ^tQueueItem;
     tQueueItem = record
       evTime     : TDateTime;
       evType     : tQueueType;
       QItems     : array of tKotUpdateItem;
       case tQueueType of
         ev_type_order    : (evOrder    : tOrders);
         ev_type_trade    : (evTrade    : tTrades);
         ev_type_soresult : (evSoResult : tSetOrderResult);
         ev_type_quots    : (evQuots    : tKotUpdateHdr);
         ev_type_sec      : (evSec      : tSecurities);
         ev_type_quoteTP  : (evTPId     : Longint);
         ev_type_command  : (evCommand  : string[10]);
     end;


type tAllQueue = class (tCustomThreadList)
        procedure   freeitem(item: pointer); override;
     public
        procedure   push(const aevitem: tQueueItem);
        function    pop(var aevitem: tQueueItem)  : boolean;
        //  ≈сть ли в очереди запрос на котирование пары
        function    IsTPToQuote(atpid : longint)  : boolean;
     end;


type tEventHandler = class (tCustomThread)
       constructor create;
       procedure   execute; override;
       procedure    CheckMessages;
end;

procedure InitMTSQueue;
procedure DoneMTSQueue;
procedure TerminateHndl;

const
  AllQueue      :  tAllQueue              = nil;
  EventHandler  :  tEventHandler        = nil;


implementation

uses mts3lx_tp, mts3lx_securities, mts3lx_otmanager;

{ tAllQueue }

procedure tAllQueue.freeitem(item: pointer);
begin if assigned(item) then dispose(pQueueItem(item)); end;


function tAllQueue.pop(var aevitem: tQueueItem): boolean;
begin
  with locklist do try
    if (count > 0) then try
      aevitem:= pQueueItem(items[0])^; result:= true;
    finally delete(0); end  else result:= false;
  finally unlocklist; end;
end;

procedure tAllQueue.push(const aevitem: tQueueItem);
var item: pQueueItem;
begin
  with locklist do try
    item := new(pQueueItem); item^:= aevitem; add(item);
  finally unlocklist; end;
end;


function tAllQueue.IsTPToQuote(atpid: longint): boolean;
var i : longint;
begin
  result:=  false;
  with locklist do try
    for i:= 0 to count - 1 do with pQueueItem(items[i])^ do
      if (evType = ev_type_quoteTP) and (evTPId = atpid) then begin result:=  true; break; end;
  FileLog('IsTPToQuote %d %s', [atpid, BoolToStr(result, true)], 4);
  finally unlocklist; end;
end;





{ tEventHandler }



constructor tEventHandler.create;
begin
  inherited create(false);
  freeonterminate:= false;
  FileLog('QUEUE     :   EventHandler started', 0);
end;


procedure tEventHandler.CheckMessages;
var
    i   : longint;
    res : PPGresult;
    SL  : tStringList;
    vfrom, vmess  : string;
    vqueue  : tQueueItem;
begin
    //  check command message if necessary

    if (Now > (LastCommandTime + CommandCheckInterval * SecDelay)) then begin
      FileLog('QUEUE.EventHandler     :  Checking messages', [], 1);

      if (PQstatus(gPGConn) = CONNECTION_OK) then begin
        res := PQexec(gPGConn, PChar(format('SELECT public.getmessages(''%s'')', ['mts3'])));
        if (PQresultStatus(res) <> PGRES_TUPLES_OK) then log('MTS3LX_SECURITIES. GetTradeParams getmessages() error')
        else
          for i := 0 to PQntuples(res)-1 do begin
            SL :=  QueryResult(PQgetvalue(res, i, 0));
            if SL.Count > 2 then begin
              vfrom   :=    SL[1];
              vmess   :=    SL[2];
              FileLog('QUEUE CheckMessages from=%s  message=%s', [vfrom, vmess], 2);

              if (vfrom = 'monitor') and assigned(AllQueue) then begin
                vqueue.evTime:=  Now; vqueue.evType:= ev_type_command; vqueue.evCommand:= vmess;
                AllQueue.push(vqueue);
              end;

            end;
          end;
        PQclear(res);
        res := PQexec(gPGConn, PChar(format('SELECT public.delmessages(''%s'')', ['mts3'])));
        PQclear(res);
      end;

      LastCommandTime  :=  Now;
    end;
end;



procedure tEventHandler.execute;
var aevitem, vqueue : tQueueItem;
    vtpid, vsecid, vexstep : longint;
begin

  while not terminated do try

    CheckMessages;

    if assigned(AllQueue) and AllQueue.pop(aevitem) then begin

      with aevitem do
        case evType of

        ev_type_sec     : begin

                            FileLog('QUEUE     :   Sec params %s',  [evSec.code], 4);
                            if assigned(SecList) and SecList.CheckFilter(evSec.code, evSec.level, evSec.stock_id) then
                              SecList.SetParams(evSec);

                            end;

       ev_type_quots   : begin
                            FileLog('QUEUE     :   Quots %s',  [evQuots.code], 4);
                            with evQuots do
                              if assigned(SecList) and SecList.CheckFilter(code, level, stock_id) then
                                SecList.ProcessQuote(evQuots, QItems);
                          end;
   
       ev_type_quoteTP : begin

                            FileLog('QUEUE     :   Quoting tradepair %d',  [evTPId], 4);
                            if Assigned(TPList) then TPList.QuoteTP(evTPId);

                          end;

        ev_type_order   : begin
                            with evOrder do
                              FileLog('QUEUE     :   Order %d[%d] %s %.6g/%d(%d) %s %s',
                                  [orderno, transaction, code, price, quantity, balance, buysell, status], 4);
                            if assigned(OTManager) then OTManager.AddOrderToDB(evOrder);
                          end;


        ev_type_trade     : begin
                              with evTrade do
                                FileLog('QUEUE     :   Trade [%d %d %d] %s %.6g/%d %s',
                                    [tradeno, orderno, transaction, code, price, quantity, buysell], 4);
                              if assigned(OTManager) then begin
                                vtpid := OTManager.AddTradeToDB(evTrade);
                                if assigned(TPList) then TPList.ReloadVols(vtpid);
                                if assigned(AllQueue) and (not AllQueue.IsTPToQuote(vtpid)) then begin
                                  vqueue.evTime:=  Now; vqueue.evType:= ev_type_quoteTP; vqueue.evTPId:=  vtpid;
                                  AllQueue.push(vqueue);
                                end;
                              end;
                            end;


        ev_type_soresult  : begin
                              with evSoResult do
                                FileLog('QUEUE     :   SoRes %d %d %d', [accepted, externaltrs, internalid], 4);
                                if ( (evSoResult.accepted = soRejected) or (evSoResult.accepted = soError) )
                                    and assigned(OTManager) then OTManager.SetOrderRejected(evSoResult.externaltrs, vtpid, vsecid);  
                            end;
                            

        ev_type_command   : begin

                              FileLog('QUEUE     :   Get command %s',  [evCommand], 3);
                              if evCommand = 'i' then
                                if assigned(TPList) then TPList.LoadAllParams;
                                  if assigned(TPList) and not TPList.LoadAllParams then
                                      msglog('Problems with TP params (Bdir > Binv)', []);
                              if evCommand = 'vol' then
                                if assigned(TPList) then TPList.ReloadVols(-1);

                            end;      

      end;

    end else sleep(0);

  except on e:exception do Filelog(' !!! EXCEPTION: QUEUE %s (step %d)', [e.message, vexstep], 0); end;

end;




//        ----------------------------------------------      //


procedure InitMTSQueue;
begin
  try
    AllQueue    := tAllQueue.create;
    EventHandler  := tEventHandler.create;
    FileLog('QUEUE     :   Started. Event handler started', 0);
  except on e:exception do Filelog(' !!! EXCEPTION: QUEUE %s', [e.message], 0); end;
end;


procedure DoneMTSQueue;
begin
  try
    FileLog('MTS3 DoneMTSQueue 0 (length %d)', [AllQueue.Count], 1);
    if assigned(AllQueue) then freeandnil(AllQueue);
    FileLog('MTS3 DoneMTSQueue 1', 1);
    TerminateHndl;
    FileLog('QUEUE     :   Finished', 0);
  except on e:exception do Filelog(' !!! EXCEPTION: QUEUE %s', [e.message], 0); end;
end;


procedure TerminateHndl;
begin
  if assigned(EventHandler) then try
    EventHandler.terminate;
    EventHandler.waitfor;
  finally
    FileLog('QUEUE     :   EventHandler terminated', 0);
    freeandnil(EventHandler);
  end;
end;





end.
