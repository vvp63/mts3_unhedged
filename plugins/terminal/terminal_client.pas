{$i terminal_defs.pas}

unit  terminal_client;

interface

uses  {$ifdef MSWINDOWS}
        windows, inifiles,
      {$else}
        unix, linux, fclinifiles,
      {$endif}
      classes, sysutils, 
      sockobjects, sortedlist,
      servertypes, serverapi, protodef, proto_in, proto_out, encoders, decoders, queue,
      tterm_api,
      terminal_common, terminal_classes, terminal_server, terminal_client_obj;

const usrLogSubscribed    = $0100;

type  tTerminalClient     = class(tTerminalClientSock)
      private
        fbufferdecoder    : tCommonBufDecoder;
        fEncoderRegistry  : tEncoderRegistry;
        fQueue            : tQueue;
        fLastSendTime     : int64;
        fSecFlags         : tSecFlags;
        fAccList          : tAccountList;
        fChangedAccounts  : tChangedAccountList;
        fAlltradesCounter : longint;
        fTempBuffer       : tMemoryStream;
        fIdleDelay        : cardinal;
      protected
        procedure   onPingReceive(aid: longint);
        procedure   onUserMessageReceive(const atext: ansistring; isencrypted: boolean);
        procedure   onKotirReqReceive(add: byte; secid: tSecIdent);
        procedure   onSetOrderReceive(var setorder: tOrder; const acomment: ansistring);
        procedure   onSetStopOrderReceive(var stoporder:tStopOrder; const acomment: ansistring);
        procedure   onDropOrderReceive(var droporder: tDropOrder);
        procedure   onReportQueryReceive(var reportquery: tReportQuery);
        procedure   onSendTradesReceive(aaccount: tAccount; astock_id: longint; acode: tCode; aquantity: longint);
        procedure   onSendAllAllTradesReceive(add: byte; const boardid: tBoardIdent; atradeno: int64);
        procedure   onTrsQueryReceive(trscount: longint; trsids: pTrsQuery);
        procedure   onNewsQueryReceive(aid: longint; adt: tDateTime; aquerytype: longint);
        procedure   onMoveOrderReceive(var moveorder: tMoveOrder);
      public
        constructor create(ahandle: TSocket); override;
        destructor  destroy; override;

        procedure   queuedata(var abuf; aid, asize: longint);
        procedure   account_updated(const aaccount: tAccount);

        function    check_user: byte; override;

        procedure   on_client_login; override;
        procedure   on_message(const aframe: tProtocolRec; amessage: pAnsiChar; amsgsize: longint); override;

        function    on_enumerate_tablerows(atable_id: longint; abuf: pAnsiChar; abufsize: longint; aparams: pAnsiChar; aparamsize: longint): longint;

        procedure   process_client_queue;
        procedure   process_changed_accounts;

        procedure   idle; override;

        property    DataQueue: tQueue read fQueue;
        property    SecFlags: tSecFlags read fSecFlags;
      end;

type  tConnectedClients   = class(tCustomThreadList)
        procedure   freeitem(item: pointer); override;

        procedure   broadcast_data(var abuf; aitemid, adatasize: longint);
        procedure   broadcast_data_masked(var abuf; aitemid, adatasize: longint; ausermask, auserflags: longint);
        procedure   send_data(const aid: tClientID; const auser: tUserName; var abuf; aitemid, adatasize: longint);
        procedure   send_transaction_result(const aid: tClientId; const auser: tUserName;
                                            const atrs: int64; acode: byte; const amsg: shortstring;
                                            const aquantity, areserved: int64);
        procedure   account_updated(const aaccount: tAccount);
      end;

const ConnectedClients    : tConnectedClients = nil;
      ServerLog           : tThreadStringQueue = nil;

function  loghandler(logstr: pAnsiChar): longint;

implementation

const min_temp_size       = 16384;
      log_str_bufsize     = 4096;

function GetMksCount: int64;
{$ifndef MSWINDOWS}
var t : timeval;
{$endif}
begin
{$ifdef MSWINDOWS}
  result := int64(GetTickCount) * 1000;
{$else}
  fpgettimeofday(@t, nil);
  result := (int64(t.tv_sec) * 1000000) + t.tv_usec;
{$endif}
end;

function  logstringtoqueue(astr: pAnsiChar; abuf: pAnsiChar; alen: longint): longint;
const log_id : longint = 0;
begin
  inc(log_id); if (log_id < 0) then log_id:= 0;
  result:= 0;
  if assigned(astr) and assigned(abuf) and (alen > sizeof(longint)) then begin
    plongint(abuf)^:= log_id;
    astr:= strlcopy(abuf + sizeof(longint), astr, alen - sizeof(longint));
    result:= sizeof(longint) + strlen(astr) + 1; // include trailing #0
  end;
end;

function  loghandler(logstr: pAnsiChar): longint;
var buf : array[0..log_str_bufsize - 1] of ansichar;
    len : longint;
begin
  if assigned(logstr) then begin
    if assigned(ServerLog) then ServerLog.push(logstr);
    if assigned(ConnectedClients) then begin
      len:= logstringtoqueue(logstr, @buf, sizeof(buf));
      if (len > 0) then ConnectedClients.broadcast_data_masked(buf, idConsoleLog, len, usrLogSubscribed, usrLogSubscribed);
    end;
  end;
  result:= PLUGIN_OK;
end;

function local_enumtablerecords(aref: pointer; atable_id, aexpected_recsize: longint; aparams: pAnsiChar; aparamsize: longint; acallback: tEnumerateTableRecFunc): longint;
var buf    : array[0..log_str_bufsize - 1] of ansichar;
    i, len : longint;
begin
  case atable_id of
    idConsoleLog : if assigned(acallback) and assigned(ServerLog) then begin
                     with ServerLog.locklist do try
                       result:= PLUGIN_OK;
                       i:= 0;
                       while (result = PLUGIN_OK) and (i < count) do begin
                         len:= logstringtoqueue(pAnsiChar(strings[i]), @buf, sizeof(buf));
                         result:= acallback(aref, atable_id, @buf, len, aparams, aparamsize);
                         inc(i);
                       end;
                     finally ServerLog.unlocklist; end;
                   end else result:= PLUGIN_ERROR;
    else           result:= PLUGIN_ERROR;
  end;
end;

function enumtablerecords_callback(aref: pointer; atable_id: longint; abuf: pAnsiChar; abufsize: longint; aparams: pAnsiChar; aparamsize: longint): longint; stdcall;
begin
  if assigned(aref) then result:= tTerminalClient(aref).on_enumerate_tablerows(atable_id, abuf, abufsize, aparams, aparamsize)
                    else result:= PLUGIN_ERROR;
end;

{ tTerminalClient }

constructor tTerminalClient.create(ahandle: TSocket);
begin
  inherited create(ahandle);
  fEncoderRegistry:= tEncoderRegistry.create(temp_buffer);
  fSecFlags:= tSecFlags.create;
  fAccList:= tAccountList.create;
  fChangedAccounts:= tChangedAccountList.create;
  fQueue:= tQueue.create;
  fTempBuffer:= tMemoryStream.create;
  fLastSendTime:= GetMksCount div 1000;
  fIdleDelay:= 100;
end;

destructor tTerminalClient.destroy;
begin
  if assigned(ConnectedClients) then
    with ConnectedClients.locklist do try remove(Self);
    finally unlocklist; end;

  if assigned(fbufferdecoder) then freeandnil(fbufferdecoder);

  if assigned(fTempBuffer) then freeandnil(fTempBuffer);
  if assigned(fQueue) then freeandnil(fQueue);
  if assigned(fChangedAccounts) then freeandnil(fChangedAccounts);
  if assigned(fAccList) then freeandnil(fAccList);
  if assigned(fSecFlags) then freeandnil(fSecFlags);
  if assigned(fEncoderRegistry) then freeandnil(fEncoderRegistry);

  inherited destroy;
end;

function tTerminalClient.check_user: byte;
begin
  // check user (accDuplicateUser)
  result:= accUserAccepted;
end;

procedure tTerminalClient.on_client_login;
begin
  with ClientInfo, version do begin
    log('Client connected: %s version: %d.%d.%d', [ClientName, major, minor, build]);

    if NewDecoder then fbufferdecoder := tNewBufDecoder.create
                  else fbufferdecoder := tOldBufDecoder.create;
  end;

  if assigned(inifile) then with inifile do begin
    fIdleDelay:= readinteger(format('user:%s', [ClientName]), 'delay', 100);
  end;

  if assigned(ConnectedClients) then
    with ConnectedClients.locklist do try
      add(Self);
    finally unlocklist; end;

  if assigned(inifile) then fAccList.initializeaccountlist(inifile, inifile.readstring(format('user:%s', [ClientName]), 'accounts', ''));

  with fbufferdecoder do begin
    SendKotirovkiProc  := onKotirReqReceive;
    SetOrderProc       := onSetOrderReceive;
    SetStopOrderProc   := onSetStopOrderReceive;
    DropOrderProc      := onDropOrderReceive;
    ReportQueryProc    := onReportQueryReceive;
    SendTradesProc     := onSendTradesReceive;
    SendAllAllTrdProc  := onSendAllAlltradesReceive;
    SendMessageProc    := onUserMessageReceive;
    TrsQueryProc       := onTrsQueryReceive;
    SendPingProc       := onPingReceive;
    NewsQueryProc      := onNewsQueryReceive;
    MoveOrderProc      := onMoveOrderReceive;
  end;
  fbufferdecoder.init;

  if assigned(srv_enumtablerecords) then begin
    srv_enumtablerecords(Self, idStockList,   sizeof(tStockRow),       nil, 0, @enumtablerecords_callback);
    srv_enumtablerecords(Self, idLevelList,   sizeof(tLevelAttrItem),  nil, 0, @enumtablerecords_callback);
    srv_enumtablerecords(Self, idWaitSec,     sizeof(tSecuritiesItem), nil, 0, @enumtablerecords_callback);
    srv_enumtablerecords(Self, idWaitOrders,  sizeof(tOrdCollItm),     nil, 0, @enumtablerecords_callback);
    srv_enumtablerecords(Self, idWaitTrades,  sizeof(tTrdCollItm),     nil, 0, @enumtablerecords_callback);
    srv_enumtablerecords(Self, idFirmInfo,    sizeof(tFirmItem),       nil, 0, @enumtablerecords_callback);
    srv_enumtablerecords(Self, idSettleCodes, sizeof(tSettleCodes),    nil, 0, @enumtablerecords_callback);
  end;

  fAccList.enumerate(on_enumerate_tablerows);

  if (UserFlags and usrServerAdmin = usrServerAdmin) then begin
    local_enumtablerecords(Self, idConsoleLog, 0, nil, 0, @enumtablerecords_callback);
    UserFlags:= UserFlags or usrLogSubscribed;
  end;
end;

procedure tTerminalClient.on_message(const aframe: tProtocolRec; amessage: pAnsiChar; amsgsize: Integer);
var trsres : tTrsResult;
begin
  if assigned(fbufferdecoder) then begin
    with trsres do begin transaction:= 0; quantity:= -1; reserved:= 0; end;
    fbufferdecoder.hdr:= aframe;
    case fbufferdecoder.ParseBuffer(amessage, amsgsize) of
      ps_ERR_CRC          : begin
                              trsres.errcode:= errDecryptFail;
                              queuedata(trsres, idTrsResult, sizeof(trsres));
                              log('%s: Invalid packet crc, dropping...', [ClientName]);
                            end;
      ps_ERR_BUFLEN       : log('%s: Invalid packet length, dropping...', [ClientName]);
      ps_ERR_NOTENCRYPTED : begin
                              with trsres do begin transaction:= fbufferdecoder.currenttrs; errcode:= errNotEncrypted; end;
                              queuedata(trsres, idTrsResult, sizeof(trsres));
                              log('%s: Request is not encrypted, dropping packet.', [ClientName]);
                            end;
      ps_ERR_TABLEID      : log('Unsupported table id: %d', [aframe.tableid]);
      ps_ERR_UNSUPPORTED  : log('Unsupported client query id: %d', [aframe.tableid]);
      ps_ERR_UNCOMPLETE   : begin
                              with trsres do begin transaction:= fbufferdecoder.currenttrs; errcode:= errIncompleteTrs; end;
                              queuedata(trsres, idTrsResult, sizeof(trsres));
                              log('Uncomplete query. More fields required.');
                            end;
      ps_ERR_NULLBUF      : ; // error while decrypting or decompressing buffer
    end;
  end;
end;

procedure tTerminalClient.queuedata(var abuf; aid, asize: longint);
begin
  if assigned(fQueue) then begin
    fQueue.locklist;
    try
      fQueue.queue(abuf, aid, asize);
    finally fQueue.unlocklist; end;
  end;
end;

procedure tTerminalClient.account_updated(const aaccount: tAccount);
begin if assigned(fAccList) and fAccList.exists(aaccount) then fChangedAccounts.addaccount(aaccount); end;

procedure tTerminalClient.onPingReceive(aid: longint);
begin queuedata(aid, idPing, sizeof(aid)); end;

procedure tTerminalClient.onUserMessageReceive(const atext: ansistring; isencrypted: boolean);
type pptrarray = ^tptrarray;
     tptrarray = array[0..0] of pDataSourceAPI;
var  apis      : pptrarray;
     i, count  : longint;
begin
  log('%s: Received message: "%s"', [ClientName, atext]);
  if assigned(srv_getapis) and (srv_getapis(pointer(apis), count) = PLUGIN_OK) then begin
    for i:= 0 to count - 1 do
      if assigned(apis^[i]) and (apis^[i] <> plugin_api) then
        if (apis^[i]^.plugflags and plEventHandler <> 0) then with apis^[i]^ do
          if assigned(eventAPI) and assigned(eventAPI^.evUserMessage) then
            eventAPI^.evUserMessage(pAnsiChar(ansistring(ClientInfo.id)), pAnsiChar(ansistring(ClientInfo.username)), pAnsiChar(atext));
  end;
end;

procedure tTerminalClient.onKotirReqReceive(add: byte; secid: tSecIdent);
var kot : tKotirovki;
begin
  if assigned(fSecFlags) then fSecFlags.secflags[secid, sfSendKot]:= (add = sfAddToList);
  case add of
    sfAddToList,
    sfSendOnly    : begin
                      with kot do begin stock_id:= secid.stock_id; level:= secid.level; code:= secid.code; end;
                      if assigned(srv_enumtablerecords) then
                        srv_enumtablerecords(Self, idKotUpdates, 0, @kot, sizeof(kot), @enumtablerecords_callback);
                    end;
  end;
end;

procedure tTerminalClient.onSetOrderReceive(var setorder: tOrder; const acomment: ansistring);
var res : tSetOrderResult;
begin
  try
    fillchar(res, sizeof(res), 0);
    if (length(setorder.cid) = 0) then setorder.cid:= ClientInfo.id;
    res.clientid:= ClientInfo.id;
    res.username:= ClientInfo.username;
    res.internalid:= 0;
    res.externaltrs:= setorder.transaction;
    if assigned(server_api) then server_api^.Set_Order(setorder, pAnsiChar(acomment), res);
  except on e: exception do log('SETORDER: Exception: %s', [e.message]); end;
end;

procedure tTerminalClient.onSetStopOrderReceive(var stoporder:tStopOrder; const acomment: ansistring);
begin log('STOPORDERS ARE NOT SUPPORTED!'); end;

procedure tTerminalClient.onDropOrderReceive(var droporder: tDropOrder);
begin
  try
    if assigned(server_api) then server_api^.Drop_Order('', droporder);
  except on e: exception do log('DROPORDER: Exception: %s', [e.message]); end;
end;

procedure tTerminalClient.onReportQueryReceive(var reportquery: tReportQuery);
begin log('REPORTS ARE NOT SUPPORTED!'); end;
procedure tTerminalClient.onSendTradesReceive(aaccount: tAccount; astock_id: longint; acode: tCode; aquantity: longint);
begin log('TRADEREQUEST IS NOT SUPPORTED!'); end;

procedure tTerminalClient.onSendAllAllTradesReceive(add: byte; const boardid: tBoardIdent; atradeno: int64);
var trd   : tAllTrades;
    secid : tSecIdent;
begin
  fillchar(secid, sizeof(secid), 0);
  with secid do begin stock_id:= boardid.stock_id; level:= boardid.level; end;
  if assigned(fSecFlags) then fSecFlags.secflags[secid, sfSendAllTrades]:= (add = sfAddToList);
  case add of
    sfAddToList,
    sfSendOnly    : begin
                      fillchar(trd, sizeof(trd), 0);
                      with trd do begin stock_id:= secid.stock_id; level:= secid.level; tradeno:= atradeno; end;
                      fAlltradesCounter:= 0;
                      if assigned(srv_enumtablerecords) then
                        srv_enumtablerecords(Self, idWaitAllTrades, sizeof(tAllTrades), @trd, sizeof(trd), @enumtablerecords_callback);
                    end;
  end;
end;

procedure tTerminalClient.onTrsQueryReceive(trscount: longint; trsids: pTrsQuery);
begin log('TRANSACTION QUERY IS NOT SUPPORTED!'); end;
procedure tTerminalClient.onNewsQueryReceive(aid: longint; adt: tDateTime; aquerytype: longint);
begin log('NEWS QUERY IS NOT SUPPORTED!'); end;
procedure tTerminalClient.onMoveOrderReceive(var moveorder: tMoveOrder);
begin log('MOVEORDER IS NOT SUPPORTED!'); end;

function tTerminalClient.on_enumerate_tablerows(atable_id: longint; abuf: pAnsiChar; abufsize: longint; aparams: pAnsiChar; aparamsize: longint): longint;
var secid : tSecIdent;
begin
  result:= PLUGIN_OK;
  case atable_id of
    idAccountList   : begin
                        queuedata(abuf^, atable_id, abufsize);
                        if (abufsize = sizeof(tAccountListItm)) and assigned(fChangedAccounts) then
                          fChangedAccounts.addaccount(pAccountListItm(abuf)^.account);
                      end;
    idWaitAllTrades : if assigned(abuf) and (abufsize = sizeof(tAllTrades)) then begin
                        queuedata(abuf^, atable_id, abufsize);
                        if assigned(fSecFlags) then begin
                          fillchar(secid, sizeof(secid), 0);
                          with pAllTrades(abuf)^ do begin
                            secid.stock_id:= stock_id;
                            secid.level:= level;
                          end;
                          fSecFlags.seclasttrade[secid]:= pAllTrades(abuf)^.tradeno;
                        end;
                        inc(fAlltradesCounter);
                        if (fAlltradesCounter >= 1000) then result:= PLUGIN_ERROR;
                      end else result:= PLUGIN_ERROR;
    else              queuedata(abuf^, atable_id, abufsize);
  end;
end;

procedure tTerminalClient.process_changed_accounts;
var i, sz, actlen : longint;
    res           : boolean;
begin
  if assigned(server_api) and assigned(fTempBuffer) and assigned(fChangedAccounts) then with fChangedAccounts do begin
    locklist;
    try
      if (fTempBuffer.Size < min_temp_size) then fTempBuffer.SetSize(min_temp_size);
      for i:= 0 to count - 1 do begin
        sz:= fTempBuffer.Size;
        res:= server_api^.GetAccountData(pAccount(items[i])^, sz, fTempBuffer.Memory^, actlen);
        if (actlen > sz) then begin
          sz:= actlen * 2;
          fTempBuffer.SetSize(sz);
          res:= server_api^.GetAccountData(pAccount(items[i])^, sz, fTempBuffer.Memory^, actlen);
        end;
        if res then queuedata(fTempBuffer.Memory^, idAccount, actlen);
      end;
      clear;
    finally unlocklist; end;
  end;
end;

procedure tTerminalClient.process_client_queue;
var i      : longint;
begin
  if assigned(fQueue) and assigned(fEncoderRegistry) then begin
    with fQueue do begin
      locklist;
      try
        for i:= 0 to count - 1 do
          with pQueueData(items[i])^ do fEncoderRegistry.add(id, data, size);
        clear;
      finally unlocklist; end;
    end;
    with fEncoderRegistry do begin
      stopencode(@out_key);
      for i:= 0 to count - 1 do with pEncRegistryItm(items[i])^ do
        if assigned(encoder) then out_buf.writestream(encoder, true);
    end;
  end;
end;

procedure tTerminalClient.idle;
begin
  process_changed_accounts;
  if (out_buf.size = 0) and (((GetMksCount div 1000) - fLastSendTime) > fIdleDelay) then begin
    process_client_queue;
    fLastSendTime:= GetMksCount div 1000;
  end;
  inherited idle;
end;

{ tConnectedClients }

procedure tConnectedClients.freeitem(item: pointer);
begin end;

procedure tConnectedClients.broadcast_data(var abuf; aitemid, adatasize: longint);
var i : longint;
begin
  locklist;
  try
    for i:= 0 to count - 1 do with tTerminalClient(items[i]) do
      case aitemid of
        idKotUpdates : if assigned(SecFlags) and SecFlags.checkbykothdr(tKotUpdateHdr(abuf)) then queuedata(abuf, aitemid, adatasize);
        else           queuedata(abuf, aitemid, adatasize);
      end;
  finally unlocklist; end;
end;

procedure tConnectedClients.broadcast_data_masked(var abuf; aitemid, adatasize: longint; ausermask, auserflags: longint);
var i : longint;
begin
  locklist;
  try
    for i:= 0 to count - 1 do with tTerminalClient(items[i]) do
      if (UserFlags and ausermask = auserflags) then queuedata(abuf, aitemid, adatasize);
  finally unlocklist; end;
end;

procedure tConnectedClients.send_data(const aid: tClientID; const auser: tUserName; var abuf; aitemid, adatasize: longint);
var i : longint;
begin
  locklist;
  try
    i:= 0;
    while (i < count) do with tTerminalClient(items[i]) do begin
      if (ClientInfo.id = aid) and
         ((length(auser) = 0) or (ClientInfo.username = auser)) then queuedata(abuf, aitemid, adatasize);
      inc(i);
    end;
  finally unlocklist; end;
end;

procedure tConnectedClients.send_transaction_result(const aid: tClientId; const auser: tUserName;
                                                    const atrs: int64; acode: byte; const amsg: shortstring;
                                                    const aquantity, areserved: int64);
type tExtTrsResult = packed record
       res         : tTrsResult;
       msg         : array[0..255] of ansichar;
     end;
var sz     : longint;
    trsres : tExtTrsResult;
begin
  fillchar(trsres, sizeof(trsres), 0);
  with trsres.res do begin transaction:= atrs; errcode:= acode; quantity:= aquantity; reserved:= areserved; end;
  sz:= length(amsg);
  if (length(amsg) > 0) then begin
    system.move(amsg[1], trsres.msg, sz);
    trsres.msg[sz]:= #0;
  end;
  inc(sz, sizeof(tExtTrsResult) + 1);
  send_data(aid, auser, trsres, idTrsResult, sz);
end;

procedure tConnectedClients.account_updated(const aaccount: tAccount);
var i : longint;
begin
  locklist;
  try
    for i:= 0 to count - 1 do tTerminalClient(items[i]).account_updated(aaccount);
  finally unlocklist; end;
end;

initialization
  ConnectedClients:= tConnectedClients.create;
  ServerLog:= tThreadStringQueue.create;
  ServerLog.MaxLen:= 256;

finalization
  if assigned(ServerLog) then freeandnil(ServerLog);
  if assigned(ConnectedClients) then freeandnil(ConnectedClients);

end.