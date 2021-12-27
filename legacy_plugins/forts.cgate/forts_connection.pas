{$i forts_defs.pas}
{__$define use_waitfor_for_threads}

unit forts_connection;

interface

uses  {$ifdef MSWINDOWS}
        windows, messages,
      {$else}
        threadmsg,
      {$endif}
      classes, sysutils, inifiles, math,
      classregistration, custom_threads, sortedlist, syncobj,
      servertypes,
      cgate, gateobjects,
      forts_types, forts_common, forts_transactions, forts_streams, forts_tables, forts_directory;

{$ifndef MSWINDOWS}
const WM_USER              = $0400;

type  PMessage = ^TMessage;
      TMessage = packed record
        Msg: Cardinal;
        case Integer of
          0: (  WParam: Longint;
                LParam: Longint;
                Result: Longint);
          1: (  WParamLo: Word;
                WParamHi: Word;
                LParamLo: Word;
                LParamHi: Word;
                ResultLo: Word;
                ResultHi: Word);
      end;
{$endif}

const WM_CONNECT           = WM_USER + 100;
      WM_DISCONNECT        = WM_USER + 101;
      WM_LISTTRANSACTIONS  = WM_USER + 102;
      WM_SETINITSTAGE      = WM_USER + 103;

const trs_action_name      : array[tOrderAction] of ansistring = ('SetOrder', 'MoveOrder', 'DropOrder');

type  tFortsDataStreamList = class(tCustomList)
      private
        FInitStage         : longint;
      public
        constructor create;
        procedure   freeitem(item: pointer); override;
        procedure   RegisterStream(AStream: tFORTSDataStream); virtual;
        procedure   UnregisterAllStreams; virtual;
        procedure   BeforeUpdate; virtual;
        procedure   AfterUpdate; virtual;
        procedure   Process(atimeout: longint); virtual;
        procedure   SetInitStage(astage: longint);
      end;

type  tFortsConnection     = class(tCustomThread)
      private
        FConnection        : tCGateConnection;
        FConnectionState   : tProcessStage;

        FWaitTimeout       : longint;

        FIniName           : ansistring;
        FConnString        : ansistring;
        FOpenParams        : ansistring;
        FConnName          : ansistring;

        procedure   Load;
      protected
        procedure   WMConnect(var Msg: TMessage); message WM_CONNECT;
        procedure   WMDisconnect(var Msg: TMessage); message WM_DISCONNECT;
        procedure   WMSetInitStage(var Msg: TMessage); message WM_SETINITSTAGE;

        procedure   BeforeProcessMessage; virtual;
        procedure   AfterProcessMessage; virtual;

        procedure   BeforeTerminate; virtual;

        procedure   DoLoad(aini: tIniFile); virtual;

        procedure   SetInitStage(anewstage: longint); virtual;

        property    Connection: tCGateConnection read FConnection;
      public
        constructor create(const AIniName, AConnSection: ansistring); virtual;
        procedure   ProcessThreadMessages;

        procedure   execute; override;

        property    ConnName: ansistring read FConnName;
        property    IniName: ansistring read FIniName;
        property    ConnectionState: tProcessStage read FConnectionState;
      end;

type  tFortsDataConnection = class(tFortsConnection)
      private
        FStreamList        : tFortsDataStreamList;

        procedure   RegisterStream(AStream: tFORTSDataStream);
      protected
        procedure   BeforeProcessMessage; override;
        procedure   AfterProcessMessage; override;
        procedure   BeforeTerminate; override;
        procedure   DoLoad(aini: tIniFile); override;
        procedure   SetInitStage(anewstage: longint); override;
      public
        destructor  destroy; override;
      end;

type  tTransactionList     = class(tSortedList)
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        function    GetItem(aitem: pointer; var QueueItem: tOrderQueueItem): boolean;
      end;

type  tFortsTrsReplyListener      = class(tCGateListener)
      private
        FTransactionList          : tTransactionList;
      protected
        procedure   OnMsgData(var Msg: tcg_msg_data); message CG_MSG_DATA;
      public
        constructor create(AOwner: tCGateConnection; const aparams: ansistring; ATrsList: tTransactionList); reintroduce; virtual;
      end;

type  tFortsTransactionConnection = class(tFortsConnection)
      private
        FTransactionList          : tTransactionList;

        FMessagePublisher         : tCGatePublisher;
        FReplyListener            : tCGateListener;

        FAddOrderName             : ansistring;
        FAddOrderMsg              : pcg_msg;
        FDelOrderName             : ansistring;
        FDelOrderMsg              : pcg_msg;
        FMoveOrderName            : ansistring;
        FMoveOrderMsg             : pcg_msg;

        FPubURL                   : ansistring;
        FReplyURL                 : ansistring;

        FLevel                    : TLevel;

        FMaxTrsAtOnce             : longint;

        FInitStage                : longint;
        FReqInitStage             : longint;
        FLocalIsins               : tLocalIsinByCode;

        FAccountGroup             : longint;

        function    StoreTransaction(QueueItem: pOrderQueueItem): pointer;
      protected
        procedure   WMListTransactions(var Msg: TMessage); message WM_LISTTRANSACTIONS;

        procedure   BeforeProcessMessage; override;
        procedure   AfterProcessMessage; override;
        procedure   BeforeTerminate; override;
        procedure   DoLoad(aini: tIniFile); override;
        procedure   SetInitStage(anewstage: longint); override;

        function    doSetOrder(amsg: pcg_msg; QueueItem: pOrderQueueItem): boolean;
        function    doMoveOrder(amsg: pcg_msg; QueueItem: pOrderQueueItem): boolean;
        function    doDropOrder(amsg: pcg_msg; QueueItem: pOrderQueueItem): boolean;
      public
      end;

type  tFortsConnectionList = class(tCustomThreadList)
        procedure   freeitem(item: pointer); override;
        procedure   RegisterConnection(AConnection: tFortsConnection); virtual;
        procedure   UnregisterAllConnections; virtual;
        procedure   BroadcastMessage(Msg, WParam, LParam: longint); virtual;
        procedure   PostMessage(const aname: ansistring; Msg, WParam, LParam: longint); virtual;
      end;

const connection_list   : tFortsConnectionList = nil;
      
implementation

{ tFortsDataStreamList }

constructor tFortsDataStreamList.create;
begin
  inherited create;
  FInitStage:= 0;
end;

procedure tFortsDataStreamList.freeitem(item: pointer);
begin if assigned(item) then TObject(item).free; end;

procedure tFortsDataStreamList.RegisterStream(AStream: tFORTSDataStream);
begin if assigned(AStream) then add(AStream); end;

procedure tFortsDataStreamList.UnregisterAllStreams;
begin clear; end;

procedure tFortsDataStreamList.BeforeUpdate;
var i : longint;
begin for i:= 0 to count - 1 do tFORTSDataStream(items[i]).BeforeUpdate; end;

procedure tFortsDataStreamList.AfterUpdate;
var i : longint;
begin for i:= 0 to count - 1 do tFORTSDataStream(items[i]).AfterUpdate; end;

procedure tFortsDataStreamList.Process(atimeout: longint);
var i      : longint;
begin
  for i:= 0 to count - 1 do with tFORTSDataStream(items[i]) do
    if (FInitStage >= RequiredInitStage) then process(atimeout, LastStreamState);
end;

procedure tFortsDataStreamList.SetInitStage(astage: Integer);
begin
  if (FInitStage < astage) then FInitStage:= astage;
end;

{ tFortsConnection }

constructor tFortsConnection.create(const AIniName, AConnSection: ansistring);
begin
  freeonterminate:= false;

  FConnection:= nil;
  FConnectionState:= psClose;

  FWaitTimeout:= 100;

  FIniName:= AIniName;
  FConnName:= AConnSection;
  
  setlength(FConnString, 0);
  setlength(FOpenParams, 0);

  inherited create(false);
end;

procedure tFortsConnection.WMConnect(var Msg: TMessage);
var i   : longint;
    slp : tPreciseSleeper;
begin
  if assigned(FConnection) then begin
    slp:= tPreciseSleeper.create(reconnect_timeout);
    try
      if (Msg.WParam = 0) then i:= reconnect_tries else i:= Msg.WParam;
      while not terminated and (FConnection.open(FOpenParams) <> CG_ERR_OK) and (i > 0) do begin
        FConnection.close;
        log('Connection %s failed; retry...', [FConnName]);
        dec(i);
        slp.reset;
        while not terminated and not slp.expired do sleep(10);
      end;
    finally slp.free; end;
  end else i:= 0;
  if not terminated then begin
    if (i > 0) then log('Connection %s opened successfully', [FConnName])
               else log('Unable to open connection %s', [FConnName]);
  end else log('Connection %s cancelled: thread terminated', [FConnName]);
end;

procedure tFortsConnection.WMDisconnect(var Msg: TMessage);
begin
  if assigned(FConnection) then begin
    try
      log('Closing connection: %s', [FConnName]);
      FConnection.close;
    except on e: exception do log('Unable to close connection: %s error: %s', [FConnName, e.message]); end;
  end else log('Unable to close connection: %s', [FConnName]);
end;

procedure tFortsConnection.WMSetInitStage(var Msg: TMessage);
begin SetInitStage(Msg.WParam); end;

procedure tFortsConnection.ProcessThreadMessages;
var msg    : TMsg;
begin while PeekMessage(Msg, 0, 0, 0, PM_REMOVE) do Dispatch(Msg.Message); end;

procedure tFortsConnection.AfterProcessMessage;
begin end;

procedure tFortsConnection.BeforeProcessMessage;
begin end;

procedure tFortsConnection.BeforeTerminate;
begin end;

procedure tFortsConnection.DoLoad(aini: tIniFile);
begin end;

procedure tFortsConnection.Load;
var ini : tIniFile;
begin
  ini:= tIniFile.Create(IniName);
  if assigned(ini) then with ini do try
    FConnString:= readstring (FConnName, 'conn_string', '');
    FOpenParams:= readstring (FConnName, 'open_params', '');
    FConnection:= tCGateConnection.create(FConnString);
    DoLoad(ini);
  finally free; end;
end;

procedure tFortsConnection.SetInitStage(anewstage: Integer);
begin end;

procedure tFortsConnection.execute;
var i : longint;
begin
  try
    Load;
    try
      while not terminated do try
        ProcessThreadMessages;
        if assigned(FConnection) and FConnection.opened then begin
          BeforeProcessMessage;
          try
            i:= 0;
            if (FConnection.process(FWaitTimeout, FConnectionState) = CG_ERR_OK) then
              while (i < 100) and (FConnection.process(0, FConnectionState) = CG_ERR_OK) do inc(i);
          finally
            AfterProcessMessage;
          end;
        end else sleep(10);
      except on e: exception do log('Connection: %s Exception: %s', [FConnName, e.message]); end;
    finally
      BeforeTerminate;
      if assigned(FConnection) then freeandnil(FConnection);
    end;
  except on e: exception do log('Connection: %s Thread terminated. Exception: %s', [FConnName, e.message]); end;
end;

{ tFortsDataConnection }

destructor tFortsDataConnection.destroy;
begin
  if assigned(FStreamList) then freeandnil(FStreamList);
  inherited destroy;
end;

procedure tFortsDataConnection.RegisterStream(AStream: tFORTSDataStream);
begin if assigned(FStreamList) then FStreamList.RegisterStream(AStream); end;

procedure tFortsDataConnection.DoLoad(aini: tIniFile);
const warning_string  = 'Load %s failed: %s exception: %s';
var   j, k            : longint;
      objclass        : tObjectClass;
      obj2, obj3      : tObject;
      feedlist        : tStringList;
      tabllist        : tStringList;
      strm, tbl       : ansistring;
begin
  if not assigned(FStreamList) then FStreamList:= tFortsDataStreamList.create;
  if assigned(FStreamList) then begin
    FStreamList.clear;
    with aini do begin
      feedlist:= tStringList.create;
      tabllist:= tStringList.create;
      try
        // создаем датастримы
        DecodeCommaText(readstring (ConnName, 'datastreams', ''), feedlist, ';');
        for j:= 0 to feedlist.Count - 1 do begin
          strm:= feedlist[j];
          objclass:= get_class(readstring(strm, 'type', ''));
          if assigned(objclass) then try
            obj2:= objclass.NewInstance;
            if assigned(obj2) then begin
              if obj2 is tFortsDataStream then begin
                tFortsDataStream(obj2).create(FConnection,
                                              strm,
                                              readstring (strm, 'conn_string',    ''),
                                              readstring (strm, 'open_params',    'mode=snapshot+online'),
                                              readinteger(strm, 'req_init_stage', 0),
                                              readinteger(strm, 'set_init_stage', 0));
                try
                  // создаем таблицы
                  DecodeCommaText(readstring (strm, 'tables', ''), tabllist, ';');
                  for k:= 0 to tabllist.Count - 1 do begin
                    tbl:= tabllist[k];
                    objclass:= get_class(tbl);
                    if assigned(objclass) then try
                      obj3:= objclass.NewInstance;
                      if assigned(obj3) then begin
                        if obj3 is tFortsTable then begin
                          tFortsTable(obj3).Create(tFortsDataStream(obj2), tbl);
                          if tFortsDataStream(obj2).RegisterTable(tFortsTable(obj3)) then tFortsTable(obj3).DoLoad(AIni);
                        end else obj3.FreeInstance;
                      end;
                    except on e: exception do log(warning_string, ['table', tbl, e.message]); end;
                  end;

                finally RegisterStream(tFortsDataStream(obj2)); end;
              end else obj2.FreeInstance;
            end;
          except on e: exception do log(warning_string, ['datafeed', strm, e.message]); end;
        end;
      finally
        feedlist.free;
        tabllist.free;
      end;
    end;
  end;
end;

procedure tFortsDataConnection.BeforeProcessMessage;
begin if assigned(FStreamList) then FStreamList.BeforeUpdate; end;

procedure tFortsDataConnection.AfterProcessMessage;
begin
  if assigned(FStreamList) then begin
    FStreamList.Process(0);
    FStreamList.AfterUpdate;
  end;  
end;

procedure tFortsDataConnection.BeforeTerminate;
begin
  if assigned(FStreamList) then try
    FStreamList.UnregisterAllStreams;
  finally freeandnil(FStreamList); end;
end;

procedure tFortsDataConnection.SetInitStage(anewstage: Integer);
begin if assigned(FStreamList) then FStreamList.SetInitStage(anewstage); end;

{ tTransactionList }

procedure tTransactionList.freeitem(item: pointer);
begin if assigned(item) then dispose(pOrderQueueItem(item)); end;

function tTransactionList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tTransactionList.compare(item1, item2: pointer): longint;
begin
  if (pAnsiChar(item1) < pAnsiChar(item2)) then result:= -1 else
  if (pAnsiChar(item1) > pAnsiChar(item2)) then result:= 1 else result:= 0;
end;

function tTransactionList.GetItem(aitem: pointer; var QueueItem: tOrderQueueItem): boolean;
var idx: longint;
begin
  result:= search(aitem, idx);
  if result then begin
    QueueItem:= pOrderQueueItem(aitem)^;
    delete(idx);
  end;
end;

{ tFortsTrsReplyListener }

constructor tFortsTrsReplyListener.create(AOwner: tCGateConnection; const aparams: ansistring; ATrsList: tTransactionList);
begin
  inherited Create(AOwner, aparams);
  FTransactionList:= ATrsList;
end;

procedure tFortsTrsReplyListener.OnMsgData(var Msg: tcg_msg_data);
var QueueItem : tOrderQueueItem;
    res_code  : longint;
    penalty   : longint;
    {$ifdef measure_transaction_costs}
    endcount  : int64;
    {$endif}
begin
  {$ifdef measure_transaction_costs}
  endcount:= GetMksCount;
  {$endif}

  {$ifdef FPC}
  if assigned(FTransactionList) and FTransactionList.GetItem(msg.user_id.user_ptr, QueueItem) then begin
  {$else}
  if assigned(FTransactionList) and FTransactionList.GetItem(pointer(msg.user_id.user_id), QueueItem) then begin
  {$endif}
    with QueueItem do begin
      case msg.msg_id of
        99  : with pFORTS_MSG99(msg.data)^, res do begin
                TEReply   := ansistring(message);
                penalty   := penalty_remain;
                accepted  := soRejected;
                SetFortsTimePenalty(penalty);
              end;
        100 : with pFORTS_MSG100(msg.data)^, res do begin
                TEReply   := ansistring(message);
                accepted  := soRejected;
              end;
        101,
        179 : with pFORTS_MSG101(msg.data)^, res do begin
                ExtNumber := order_id;
                res_code  := code;
                Quantity  := order.quantity;
                TEReply   := ansistring(message);
                if (res_code = 0) then accepted:= soAccepted else accepted:= soRejected;
              end;
        102,
        177 : with pFORTS_MSG102(msg.data)^, res do begin
                ExtNumber := orderno;
                res_code  := code;
                Quantity  := amount;
                TEReply   := ansistring(message);
                if (res_code = 0) then accepted:= soDropAccepted else accepted:= soDropRejected;
              end;
        105,
        176 : with pFORTS_MSG105(msg.data)^, res do begin
                res_code  := code;
                TEReply   := ansistring(message);
//                Quantity  := moveorder.new_quantity;
                ExtNumber := order_id1;
                if (res_code = 0) then accepted:= soAccepted else accepted:= soRejected;
              end;
        else begin
               res.TEReply:= format('Unexpected reply ID: %d', [msg.msg_id]);
               res.accepted:= soError;
               log('AsyncReply: Unexpected reply ID: %d', [msg.msg_id]);
             end;
      end;
      if assigned(Server_API.SetTrsResult) then Server_API.SetTrsResult(res);
      {$ifdef measure_transaction_costs}
      log('Trs timing (%s) id: %d is: %d', [trs_action_name[action], trs_id, (endcount - startcount)]);
      {$endif}
    end;
  end else log('AsyncReply: Unable to find transaction: %.8x', [msg.user_id.user_id]);
end;

{ tFortsTransactionConnection }

procedure tFortsTransactionConnection.DoLoad(aini: tIniFile);
const pub_id : longint = 0;
var   pubid  : longint;
begin
  FInitStage       := 0;

  with aini do begin
    FLevel         :=        readstring  (ConnName, 'board',             level_futures);

    if use_account_groups then FAccountGroup:= readinteger (ConnName, 'accountgroup', 0) else FAccountGroup:= 0;

    FPubURL        :=        readstring  (ConnName, 'pub_conn_string',   'p2mq://FORTS_SRV;category=FORTS_MSG');
    FReplyURL      :=        readstring  (ConnName, 'reply_conn_string', 'p2mqreply://');

    FWaitTimeout   := max(0, readinteger (ConnName, 'timeout',           1));
    FMaxTrsAtOnce  := max(1, readinteger (ConnName, 'groupcount',        10));

    FAddOrderName  :=        readstring  (ConnName, 'setorder',          'AddOrder');
    FDelOrderName  :=        readstring  (ConnName, 'droporder',         'DelOrder');
    FMoveOrderName :=        readstring  (ConnName, 'moveorder',         'MoveOrder');

    FReqInitStage  :=        readinteger (ConnName, 'req_init_stage',    0);
  end;

  FTransactionList:= tTransactionList.create;

  pubid:= interlockedincrement(pub_id);
  FMessagePublisher:= tCGatePublisher.create(FConnection, format('%s;name=pub%.3d', [FPubURL, pubid]));
  FReplyListener:= tFortsTrsReplyListener.create(FConnection, format('%s;ref=pub%.3d', [FReplyURL, pubid]), FTransactionList);

  if assigned(forts_transaction_queue) then forts_transaction_queue.RegisterReceiverThread(FLevel, FAccountGroup);
end;

procedure tFortsTransactionConnection.SetInitStage(anewstage: longint);
begin
  if (anewstage > FInitStage) then begin
    FInitStage:= anewstage;
    if not assigned(FLocalIsins) then FLocalIsins:= tLocalIsinByCode.create;
    if assigned(FLocalIsins) then FLocalIsins.load(isin_list);
  end;
end;

procedure tFortsTransactionConnection.BeforeTerminate;
begin
  if assigned(FReplyListener) then freeandnil(FReplyListener);
  if assigned(FMessagePublisher) then begin
    if assigned(FAddOrderMsg) then FMessagePublisher.msg_free(fAddOrderMsg);
    if assigned(FDelOrderMsg) then FMessagePublisher.msg_free(FDelOrderMsg);
    if assigned(FMoveOrderMsg) then FMessagePublisher.msg_free(FMoveOrderMsg);
    freeandnil(FMessagePublisher);
  end;
  if assigned(FTransactionList) then freeandnil(FTransactionList);
  if assigned(FLocalIsins) then freeandnil(FLocalIsins);
  if assigned(forts_transaction_queue) then forts_transaction_queue.UnregisterReceiverThread(FLevel, FAccountGroup);
end;

procedure tFortsTransactionConnection.WMListTransactions(var Msg: TMessage);
var i   : longint;
    itm : pOrderQueueItem;
begin
  if assigned(FTransactionList) then
    for i:= 0 to FTransactionList.Count - 1 do begin
      itm:= FTransactionList.Items[i];
      if assigned(itm) then with itm^ do
        log('connection: %s transaction: %d action: %s', [ConnName, trs_id, trs_action_name[action]]);
    end;
end;

procedure tFortsTransactionConnection.BeforeProcessMessage;
var QueueItem : pOrderQueueItem;
    msg       : pcg_msg;
    cnt       : longint;
    fill_res  : boolean;
    idx       : pointer;
begin
  idx:= nil; cnt:= FMaxTrsAtOnce;
  msg:= nil; fill_res:= false;
  if assigned(forts_transaction_queue) then
    repeat
      QueueItem:= forts_transaction_queue.PeekOrderQueueItem(FLevel, FAccountGroup);
      if assigned(QueueItem) then try
        if assigned(FMessagePublisher) and (FMessagePublisher.state = CG_STATE_ACTIVE) then begin
          case QueueItem^.action of
            actSetOrder  : begin
                             if not assigned(FAddOrderMsg) then FAddOrderMsg:= FMessagePublisher.msg_new(CG_KEY_NAME, pAnsiChar(FAddOrderName));
                             msg:= FAddOrderMsg;
                             fill_res:= doSetOrder(msg, QueueItem);
                           end;
            actMoveOrder : begin
                             if not assigned(FMoveOrderMsg) then FMoveOrderMsg:= FMessagePublisher.msg_new(CG_KEY_NAME, pAnsiChar(FMoveOrderName));
                             msg:= FMoveOrderMsg;
                             fill_res:= doMoveOrder(msg, QueueItem);
                           end;
            actDropOrder : begin
                             if not assigned(FDelOrderMsg) then FDelOrderMsg:= FMessagePublisher.msg_new(CG_KEY_NAME, pAnsiChar(FDelOrderName));
                             msg:= FDelOrderMsg;
                             fill_res:= doDropOrder(msg, QueueItem);
                           end;
          end;

          if assigned(msg) and fill_res then begin
            idx := StoreTransaction(QueueItem);
            {$ifdef FPC}
            pcg_msg_data(msg)^.user_id.user_ptr:= idx;
            {$else}
            pcg_msg_data(msg)^.user_id.user_id:= longint(idx);
            {$endif}
            {$ifdef measure_transaction_costs}
            QueueItem^.startcount:= GetMksCount;
            {$endif}
            if (FMessagePublisher.msg_post(msg, CG_PUB_NEEDREPLY) <> CG_ERR_OK) then begin
              log('Connection: %s MessagePost: %s', [ConnName, errPostError]);
              with QueueItem^.res do begin accepted:= soRejected; ExtNumber:= 0; TEReply:= errPostError; end;
              if assigned(Server_API.SetTrsResult) then Server_API.SetTrsResult(QueueItem^.res);
              idx:= nil;
            end;
          end else begin
            log('Connection: %s MessageNew: %s', [ConnName, errMessageError]);
            with QueueItem^.res do begin accepted:= soRejected; ExtNumber:= 0; TEReply:= errMessageError; end;
            if assigned(Server_API.SetTrsResult) then Server_API.SetTrsResult(QueueItem^.res);
          end;
        end else begin
          log('Connection: %s Publisher: %s', [ConnName, errPublisherError]);
          with QueueItem^.res do begin accepted:= soRejected; ExtNumber:= 0; TEReply:= errPublisherError; end;
          if assigned(Server_API.SetTrsResult) then Server_API.SetTrsResult(QueueItem^.res);
        end;
      finally
        if not assigned(idx) then dispose(QueueItem);
        msg:= nil;
      end;
      dec(cnt);
    until not assigned(QueueItem) or (cnt <= 0);
end;

procedure tFortsTransactionConnection.AfterProcessMessage;
var stage: tProcessStage;
begin
  if assigned(FMessagePublisher) then FMessagePublisher.process(0, stage);
  if assigned(FReplyListener) then FReplyListener.process(0, stage);
end;

function tFortsTransactionConnection.doSetOrder(amsg: pcg_msg; QueueItem: pOrderQueueItem): boolean;
var ls  : longint;
    itm : pIsinListItem;
begin
  result:= false;
  if assigned(amsg) and assigned(QueueItem) and assigned(FLocalIsins) then with QueueItem^, pAddOrder(amsg^.data)^ do begin
    itm:= FLocalIsins.isin[order.code];
    if assigned(itm) then begin
      if fortssign(itm^.signs, flag_Spot) then ls:= 1 else ls:= itm^.lsz;

      if (length(fortsbrokercode) > 0) then strplcopy(broker_code, fortsbrokercode, sizeof(broker_code) - 1);

      isin_id := itm^.isin_id;
//      strplcopy(isin, order.code, sizeof(isin) - 1);
      strplcopy(client_code, system.copy(order.account, 5, max(length(order.account) - 4, 0)), sizeof(client_code) - 1);

      if (order.flags and opWDRest <> 0) then begin
        type_ := 2;
      end else
      if (order.flags and opImmCancel <> 0) then begin
        type_ := 3;
      end else begin
        type_ := 1;
      end;

      case upcase(order.buysell) of
        'B' : dir := 1;
        'S' : dir := 2;
      end;

      amount:= order.quantity;
      strplcopy(price, format('%.5f', [order.price * ls]), sizeof(price) - 1);
//      comment     := '';
//      broker_to   := '';
      ext_id:= order.transaction;
//      du          := 0;
//      date_exp    := '';
//      hedge       := 0;

      result:= true;
    end;
  end;
end;

function tFortsTransactionConnection.doMoveOrder(amsg: pcg_msg; QueueItem: pOrderQueueItem): boolean;
var ls  : longint;
    itm : pIsinListItem;
begin
  result:= false;
  if assigned(amsg) and assigned(QueueItem) and assigned(FLocalIsins) then with QueueItem^, pMoveOrder(amsg^.data)^ do begin
    itm:= FLocalIsins.isin[order.code];
    if assigned(itm) then begin
      if fortssign(itm^.signs, flag_Spot) then ls:= 1 else ls:= itm^.lsz;

      isin_id   := itm^.isin_id;
      if (length(fortsbrokercode) > 0) then strplcopy(broker_code, fortsbrokercode, sizeof(broker_code) - 1);

      regime    := moveorder.flags;
      order_id1 := moveorder.orderno;
      amount1   := moveorder.new_quantity;
      strplcopy(price1, format('%.5f', [moveorder.new_price * ls]), sizeof(price1) - 1);
      ext_id1   := moveorder.transaction;

      order_id2 := 0;
      amount2   := 0;
      price2    := '';
      ext_id2   := 0;

      result:= true;
    end;
  end;
end;

function tFortsTransactionConnection.doDropOrder(amsg: pcg_msg; QueueItem: pOrderQueueItem): boolean;
var itm : pIsinListItem;
begin
  result:= false;
  if assigned(amsg) and assigned(QueueItem) then with QueueItem^, pDelOrder(amsg^.data)^ do begin
    itm:= FLocalIsins.isin[code];
    if assigned(itm) then begin
      if (length(fortsbrokercode) > 0) then strplcopy(broker_code, fortsbrokercode, sizeof(broker_code) - 1);
      order_id := orderno;
      isin_id  := itm^.isin_id;
      result:= true;
    end;
  end;
end;

function tFortsTransactionConnection.StoreTransaction(QueueItem: pOrderQueueItem): pointer;
begin
  if assigned(FTransactionList) then begin
    FTransactionList.add(QueueItem);
    result:= QueueItem;
  end else result:= nil;
end;

{ tFortsConnectionList }

procedure tFortsConnectionList.BroadcastMessage(Msg, WParam, LParam: longint);
var i : longint;
begin
  locklist;
  try
    for i:= 0 to count - 1 do
      with tFortsConnection(items[i]) do
        if not PostThreadMessage(ThreadID, Msg, WParam, LParam) then log('Unable to post thread (id:%.8x) message: [%.8x, %d, %d]', [ThreadID, Msg, WParam, LParam])
  finally unlocklist; end;
end;

procedure tFortsConnectionList.PostMessage(const aname: ansistring; Msg, WParam, LParam: Integer);
var i : longint;
begin
  locklist;
  try
    i:= 0;
    while (i < Count) do
      with tFortsConnection(items[i]) do
        if (comparetext(aname, ConnName) = 0) then begin
          PostThreadMessage(ThreadID, Msg, WParam, LParam);
          i:= Self.Count;
        end else inc(i);
  finally unlocklist; end;
end;

procedure tFortsConnectionList.freeitem(item: pointer);
begin
  {$ifdef use_waitfor_for_threads}
  if assigned(item) then try
    with tFortsConnection(item) do begin terminate; waitfor; end;
  finally
    tFortsConnection(item).free;
  end;
  {$else}
  if assigned(item) then tFortsConnection(item).free;
  {$endif}
end;

procedure tFortsConnectionList.RegisterConnection(AConnection: tFortsConnection);
begin
  if assigned(AConnection) then begin
    locklist;
    try
      add(AConnection);
    finally unlocklist; end;
  end;
end;

procedure tFortsConnectionList.UnregisterAllConnections;
begin
  locklist;
  try
    clear;
  finally unlocklist; end;
end;

initialization
  register_class([tFortsDataConnection, tFortsTransactionConnection]);

end.
