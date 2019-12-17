{$i terminal_defs.pas}

library terminal;

{$R *.res}

uses  terminal_sys,
      {$ifdef MSWINDOWS}
        windows,
      {$else}
        dynlibs,   
      {$endif}
      classes, sysutils,
      servertypes, serverapi, protodef,
      tterm_api,
      terminal_common, terminal_thread, terminal_client;

function  Init(memmgr: pMemoryManager): longint;   cdecl; forward;
function  Done: longint;                           cdecl; forward;

procedure SecArrived(var sec: tSecurities; changedfields: TSecuritiesSet); cdecl; forward;
procedure KotirArrived(kotirdata: pointer);                                cdecl; forward;
procedure OrderArrived(var order: tOrders; fields: tOrdersSet);            cdecl; forward;
procedure TradesArrived(var trade: tTrades; fields: tTradesSet);           cdecl; forward;
procedure TransactionRes(var aresult: tSetOrderResult);                    cdecl; forward;
procedure AccountUpdated(var aaccount: tAccount);                          cdecl; forward;
procedure UserMessage(aFromID, aFromUserName, aText: pAnsiChar);           cdecl; forward;
procedure LogEvent(aevent: pAnsiChar);                                     cdecl; forward;

const ev_api  : tEventHandlerAPI = (  evSecArrived     : SecArrived;
                                      evAllTrdArrived  : nil;
                                      evKotirArrived   : KotirArrived;
                                      evOrderArrived   : OrderArrived;
                                      evTradesArrived  : TradesArrived;
                                      evTransactionRes : TransactionRes;
                                      evAccountUpdated : AccountUpdated;
                                      evSQLServerEvent : nil;
                                      evUserMessage    : UserMessage;
                                      evTableUpdate    : nil;
                                      evLogEvent       : LogEvent);

      plugapi : tDataSourceApi   = (  plugname         : PlugName;
                                      plugflags        : plEventHandler;
                                      pl_Init          : Init;
                                      pl_Done          : Done;
                                      stockapi         : nil;
                                      newsapi          : nil;
                                      eventapi         : @ev_api);

function Init(memmgr: pMemoryManager): longint;
begin result:= 0; end;

function  InitEx(aexeinstance, alibinstance: HModule; alibname, ainifilename: pAnsiChar): longint; stdcall;
const section_system = 'system';
begin
  ExeFileName := expandfilename(alibname);
  ExeFilePath := includetrailingbackslash(extractfilepath(ExeFileName));
  IniFileName := changefileext(ExeFileName, '.ini');

  srv_enumtables       := GetProcAddress(aexeinstance, SRV_EnumerateTables);
  srv_enumtablerecords := GetProcAddress(aexeinstance, SRV_EnumerateTableRecords);

  srv_getapis          := GetProcAddress(aexeinstance, SRV_GetLegacyAPIs);

  srvUpdateSecurities  := GetProcAddress(aexeinstance, srv_UpdateSecuritiesRec);
  srvCleanupSecurities := GetProcAddress(aexeinstance, srv_CleanupSecuritiesRec);
  srvUpdateOrders      := GetProcAddress(aexeinstance, srv_UpdateOrders);
  srvCleanupOrders     := GetProcAddress(aexeinstance, srv_CleanupOrders);
  srvUpdateTrades      := GetProcAddress(aexeinstance, srv_UpdateTrades);
  srvCleanupTrades     := GetProcAddress(aexeinstance, srv_CleanupTrades);
  srvUpdateFirmsRec    := GetProcAddress(aexeinstance, srv_UpdateFirmsRec);

  InitializeTerminalSupport;

  log('Terminal support started ok', []);

  result:= PLUGIN_OK;
end;


function Done: longint;
begin
  log('terminal done being called...');
  try
    FinalizeTerminalSupport;
    log('Terminal support shutdown complete...');
  except on e: exception do log('Terminal support shutdown exception: %s', [e.message]); end;
  log('terminal done ok!');
  result:= 0;
end;

procedure SecArrived(var sec: tSecurities; changedfields: TSecuritiesSet);
var secitm : tSecuritiesItem;
begin
  secitm.sec:= sec; secitm.secset:= changedfields;
  if assigned(ConnectedClients) then ConnectedClients.broadcast_data(secitm, idWaitSec, sizeof(secitm));
end;

procedure KotirArrived(kotirdata: pointer);
var sz : longint;
begin
  if assigned(ConnectedClients) and assigned(kotirdata) then begin
    sz:= pKotUpdateHdr(kotirdata)^.kotcount * sizeof(tKotUpdateItem) + sizeof(tKotUpdateHdr);
    ConnectedClients.broadcast_data(kotirdata^, idKotUpdates, sz);
  end;
end;

procedure OrderArrived(var order: tOrders; fields: tOrdersSet);
var orditm : tOrdCollItm;
begin
  orditm.ord:= order; orditm.ordset:= fields;
  if assigned(ConnectedClients) then ConnectedClients.broadcast_data(orditm, idWaitOrders, sizeof(orditm));
end;

procedure TradesArrived(var trade: tTrades; fields: tTradesSet);
var trditm : tTrdCollItm;
begin
  trditm.trd:= trade; trditm.trdset:= fields;
  if assigned(ConnectedClients) then ConnectedClients.broadcast_data(trditm, idWaitTrades, sizeof(trditm));
end;

procedure TransactionRes(var aresult: tSetOrderResult);
begin
  if assigned(ConnectedClients) then with ConnectedClients, aresult do
    case accepted of
      soAccepted      : send_transaction_result(clientid, username, externaltrs, errSetOrderOK, inttostr(extnumber), quantity, reserved);
      soRejected      : send_transaction_result(clientid, username, externaltrs, errStockReply, TEReply, quantity, reserved);
      soUnknown       : ;
      soDropAccepted  : send_transaction_result(clientid, username, externaltrs, errDropOrderOK, inttostr(extnumber), quantity, reserved);
      soDropRejected  : send_transaction_result(clientid, username, externaltrs, errStockReply, TEReply, quantity, reserved);
      soError         : ;
    end;
end;

procedure AccountUpdated(var aaccount: tAccount);
begin
  if assigned(ConnectedClients) then ConnectedClients.account_updated(aaccount);
end;

procedure UserMessage(aFromID, aFromUserName, aText: pAnsiChar);
var clientid: tClientID;
begin
  if assigned(ConnectedClients) and assigned(atext) then begin
    clientid:= strpas(aFromID);
    if (length(clientid) > 0) then ConnectedClients.send_data(clientid, strpas(aFromUserName), atext^, idMessage, strlen(atext) + 1)
                              else ConnectedClients.broadcast_data(atext^, idMessage, strlen(atext) + 1);
  end;
end;

procedure LogEvent(aevent: pAnsiChar);
begin loghandler(aevent); end;

function getDllAPI(srvapi: pServerAPI): pDataSourceAPI; cdecl;
begin
  server_api:= srvapi;
  plugin_api:= @plugapi;
  if assigned(server_api) then result:= @plugapi else result:= nil;
end;

exports   getDllAPI,
          InitEX    name 'plg_initialize_ex';

begin
  {$ifdef FPC}
  DefaultFormatSettings.DecimalSeparator:= '.';
  DefaultFormatSettings.TimeSeparator:= ':';
  {$else}
  DecimalSeparator:= '.'; timeseparator:= ':';
  {$endif}
end.
