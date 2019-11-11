{$i bitmex_defs.pas}

library bitmex;

{$R *.res}

uses {$ifdef useexceptionhandler} ExcHandler, {$endif}
     windows, classes, sysutils, inifiles,
     ServerTypes, ServerAPI,
     classregistration, lowlevel, versioncontrol,
     bitmex_common, bitmex_commandparser, bitmex_tables,
     PATSINTF;

function  Init(memmgr: pMemoryManager): longint;                                   cdecl; forward;
function  Done: longint;                                                           cdecl; forward;

function  Connect: longint;                                                        cdecl; forward;
function  Disconnect: longint;                                                     cdecl; forward;

procedure SetOrder(order:tOrder; comment:tOrderComment; var res:tSetOrderResult);  cdecl; forward;
procedure MoveOrder(moveorder:tMoveOrder; comment:tOrderComment;
                    var res:tSetOrderResult);                                      cdecl; forward;
procedure OrderCommit(commitresult:byte; orderno:int64);                           cdecl; forward;
procedure DropOrder(order: int64; flags: longint;
                    astock_id: longint; const alevel: TLevel; const acode: TCode;
                    var res: tSetOrderResult);                                     cdecl; forward;

procedure AfterDayOpen;                                                            cdecl; forward;
procedure BeforeDayClose;                                                          cdecl; forward;
procedure ServerStatus(status:longint);                                            cdecl; forward;

function  PatsHook(params: pointer): longint;                                      cdecl; forward;

const patsapi : tStockAPI       = ( stock_count       : stockcount;
                                    stock_list        : @stocklst;
                                    pl_SetOrder       : SetOrder;
                                    pl_DropOrder      : DropOrder;
                                    pl_Connect        : Connect;
                                    pl_Disconnect     : Disconnect;
                                    pl_Hook           : PatsHook;
                                    ev_BeforeDayOpen  : nil;
                                    ev_AfterDayOpen   : AfterDayOpen;
                                    ev_BeforeDayClose : BeforeDayClose;
                                    ev_AfterDayClose  : nil;
                                    ev_OrderCommit    : OrderCommit;
                                    ev_ServerStatus   : ServerStatus;
                                    pl_MoveOrder      : MoveOrder);

      plugapi  : tDataSourceAPI = ( plugname          : patsplugname;
                                    plugflags         : plStockProvider;
                                    pl_Init           : Init;
                                    pl_Done           : Done;
                                    stockapi          : @patsapi);


type  tCmdInterface     = class(tCommandInterface)
      public
        procedure   syntaxerror; override;
      published
        function    connect: boolean;
        function    disconnect: boolean;
      end;

const command_interface : tCmdInterface = nil;

      connected_status  : boolean = false;
      logon_status      : boolean = false;

{ tCmdInterface }

procedure tCmdInterface.syntaxerror;
begin log('Incorrect command syntax: %s', [command]); end;

function tCmdInterface.connect: boolean;
begin
  bitmex.Connect;
  result:= true;
end;

function tCmdInterface.disconnect: boolean;
begin
  bitmex.Disconnect;
  result:= true;
end;

procedure DataDLComplete; stdcall;
begin
  log('DataDLComplete');
  LoadStaticData;
end;

procedure LogonStatus; stdcall; begin log('LogonStatus'); logon_status:= true; end;
procedure ForcedLogout; stdcall; begin log('ForcedLogout'); logon_status:= false; end;

procedure ContractAdded(ContractUpd: ContractUpdStructPtr); stdcall;
var contract : ContractStruct;
begin
//  log('Contract ADDED: %s %s %s', [ContractUpd^.ExchangeName, ContractUpd^.ContractName, ContractUpd^.ContractDate]);
  with ContractUpd^ do
    if (ptGetContractByName(@ExchangeName, @ContractName, @ContractDate, @contract) = ptSuccess) then AddSecurity(contract);
end;

procedure ContractDeleted(Contract: ContractUpdStructPtr); stdcall;
begin
//  log('Contract DELETED: %s %s %s', [Contract^.ExchangeName, Contract^.ContractName, Contract^.ContractDate]);
end;

procedure HostLinkStateChange(Data: LinkStateStructPtr); stdcall;
begin log('HostLinkStateChange: %d to %d', [Data^.OldState, Data^.NewState]); connected_status:= (Data^.NewState = 3); end;
procedure PriceLinkStateChange(Data: LinkStateStructPtr); stdcall;
begin log('PriceLinkStateChange: %d to %d', [Data^.OldState, Data^.NewState]); end;

procedure MessageCB(MsgID: MsgIDPtr); stdcall;
begin log('MESSAGE: %s', [MsgID^]); end;

procedure OrderCB(Order: OrderUpdStructPtr); stdcall;
var res         : tSetOrderResult;
    orderdetail : OrderDetailStruct;
begin
  with Order^ do begin
    log('ORDER: id:%s old:%s status:%d seq:%d type:%d', [OrderID, OldOrderID, OrderStatus, OFSeqNumber, OrderTypeId]);
    case OrderStatus of
      ptQueued   : if assigned(order_list) and order_list.pop(@OldOrderID, res) then order_list.push(@OrderID, res);
      ptSent     : if assigned(order_list) and order_list.pop(@OldOrderID, res) then order_list.push(@OrderID, res);
      ptRejected : if assigned(order_list) and order_list.pop(@OldOrderID, res) then begin
                     with res do begin TEReply:= 'Order rejected!'; ExtNumber:= 0; accepted:= soRejected; end;
                     if assigned(Server_API.SetTrsResult) then Server_API.SetTrsResult(res);
                   end;
      else         begin
                     if assigned(order_list) and order_list.pop(@OldOrderID, res) then begin
                       with res do begin TEReply:= 'Order accepted!'; ExtNumber:= StrToInt64Def(OrderID, 0); accepted:= soAccepted; end;
                       if assigned(Server_API.SetTrsResult) then Server_API.SetTrsResult(res);
                     end;
                     if (ptGetOrderByID(@OrderID, @orderdetail, OFSeqNumber) = ptSuccess) then begin
                       if assigned(Server_API.OrdersBeginUpdate) then Server_API.OrdersBeginUpdate(GetPatsStockID, '');
                       try AddOrder(orderdetail);
                       finally if assigned(Server_API.OrdersEndUpdate) then Server_API.OrdersEndUpdate(GetPatsStockID, ''); end;
                     end else log('ptGetOrderByID failed!');
                   end;
    end;
  end;
end;

procedure FillCB(Fill: FillUpdStructPtr); stdcall;
var filldetail  : FillStruct;
    orderdetail : OrderDetailStruct;
begin
  with Fill^ do begin
    log('FILL: order:%s id: %s', [OrderID, FillID]);
    if (ptGetFillByID(@FillID, @filldetail) = ptSuccess) then begin
      if (ptGetOrderByID(@OrderID, @orderdetail, 0) <> ptSuccess) then orderdetail.XrefP:= 0;

      if assigned(Server_API.TradesBeginUpdate) then Server_API.TradesBeginUpdate(patsid, '');
      try AddTrade(filldetail, orderdetail.XrefP);
      finally if assigned(Server_API.TradesEndUpdate) then Server_API.TradesEndUpdate(patsid, ''); end;
    end;
  end;
end;

procedure StatusChange(Status: StatusUpdStructPtr); stdcall;
begin with Status^ do log('StatusChange: %s %s %s status: %d', [ExchangeName, ContractName, ContractDate, Status]); end;


{ plugin functions }

function  Init (memmgr: pMemoryManager): longint;
const ver : TFileVersionInfo = ( major: 0; minor: 0; release: 0; build: 0);
var   ApplicID, ApplicVersion : ansistring;
      License                 : ansistring;
      EnableMask              : longint;
      ini                     : tIniFile;
      ClientType              : ansichar;
begin
  result:= 1;
  ExtractVersionInfo(ver);
  log('plugin version %d.%d [%d]', [ver.major, ver.minor, ver.build]);
  try
    command_interface:= tCmdInterface.Create;

    ptSetClientPath(pAnsiChar(pluginfilepath));

    ini:= tIniFile.create(pluginininame);
    try
      with ini do begin
        ApplicID        :=  readstring(section_system,   'AppID',           '');
        ApplicVersion   :=  readstring(section_system,   'AppVersion',      '');
        License         :=  readstring(section_system,   'License',         '');
        EnableMask      := readinteger(section_system,   'EnableMask',       0);
        ClientType      := (readstring(section_system,   'ClientType',      'C') + 'C')[1];
      end;
      if assigned(level_list) then level_list.LoadFromIni(ini, 'levels');
      if ini.sectionexists('contracts') and assigned(contract_list) then contract_list.LoadFromIni(ini, 'contracts');
    finally ini.free; end;

    is_demo:= (ClientType = 'D');
    check_fail(ptInitialise(ClientType, ptAPIversion, pAnsiChar(ApplicID), pAnsiChar(ApplicVersion), pAnsiChar(License), true), 'ptInitialise');

    check_fail(ptRegisterCallback(ptDataDLComplete, @DataDLComplete), 'ptRegisterCallback: ptDataDLComplete');
    check_fail(ptRegisterCallback(ptLogonStatus, @LogonStatus), 'ptRegisterCallback: ptLogonStatus');
    check_fail(ptRegisterCallback(ptForcedLogout, @ForcedLogout), 'ptRegisterCallback: ptForcedLogout');

    check_fail(ptRegisterContractCallback(ptContractAdded, @ContractAdded), 'ptRegisterContractCallback: ContractAdded');
    check_fail(ptRegisterContractCallback(ptContractDeleted, @ContractDeleted), 'ptRegisterContractCallback: ContractDeleted');

    check_fail(ptRegisterLinkStateCallback(ptHostLinkStateChange, @HostLinkStateChange), 'ptRegisterLinkStateCallback: HostLinkStateChange');
    check_fail(ptRegisterLinkStateCallback(ptPriceLinkStateChange, @PriceLinkStateChange), 'ptRegisterLinkStateCallback: PriceLinkStateChange');

    check_fail(ptRegisterMsgCallback(ptMessage, @MessageCB), 'ptRegisterMsgCallback');

    check_fail(ptRegisterOrderCallback(ptOrder, @OrderCB), 'ptRegisterOrderCallback');

    check_fail(ptRegisterFillCallback(ptFill, @FillCB), 'ptRegisterFillCallback');

    check_fail(ptRegisterPriceCallback(ptPriceUpdate, @PriceUpdate), 'ptRegisterPriceCallback');
    check_fail(ptRegisterDOMCallback(ptDOMUpdate, @DOMUpdate), 'ptRegisterDOMCallback');

    check_fail(ptRegisterStatusCallback(ptStatusChange, @StatusChange), 'ptRegisterStatusCallback');

    check_fail(ptSetPriceAgeCounter(0), 'ptSetPriceAgeCounter');

    ptEnable(EnableMask);

    result:= 0;
  except on e: exception do log('Init exception: %s', [e.message]); end;
end;

function  Done: longint;
begin
  try
    ptDisconnect();
    ptLogoff();
    if assigned(command_interface) then freeandnil(command_interface);
    log('Done');
  except on e: exception do log('Done exception: %s', [e.message]); end;
  result:= 0;
end;

function  Connect: longint;
const yes_no             : array[boolean] of char = ('N', 'Y');
var   ls                 : LogonStruct;
      priceaddress       : ansistring;
      priceport          : ansistring;
      hostaddress        : ansistring;
      hostport           : ansistring;
      uid, pass, newpass : ansistring;
      reports            : boolean;
      res                : longint;
  function wait_status_change(var atrigger: boolean; atimeout: cardinal): boolean;
  var tc : cardinal;
  begin
    tc:= cardinal(GetTickCount) + atimeout;
    while not atrigger and (GetTickCount < tc) do sleep(100);
    result:= atrigger;
  end;
begin
  result:= 1;

  connected_status:= false;
  logon_status:= false;

  try
    with tIniFile.create(pluginininame) do try
      priceaddress  :=   readstring(section_connection, 'price_address', '');
      priceport     :=   readstring(section_connection, 'price_port',    '');
      hostaddress   :=   readstring(section_connection, 'host_address',  '');
      hostport      :=   readstring(section_connection, 'host_port',     '');
      uid           :=   readstring(section_connection, 'user_id',       '');
      pass          :=   readstring(section_connection, 'password',      '');
      newpass       :=   readstring(section_connection, 'new_password',  '');
      reports       := (readinteger(section_connection, 'reports',       0) <> 0);
    finally free; end;

    check_fail(ptSetHostHandShake(10, 3000), 'ptSetHostHandShake');
    check_fail(ptSetHostReconnect(10), 'ptSetHostReconnect');
    check_fail(ptSetPriceAddress(pAnsiChar(priceaddress), pAnsiChar(priceport)), 'ptSetPriceAddress');
    check_fail(ptSetHostAddress(pAnsiChar(hostaddress), pAnsiChar(hostport)), 'ptSetHostAddress');
    check_fail(ptSetPriceReconnect(10), 'ptSetPriceReconnect');
    check_fail(ptSetInternetUser(#0), 'ptSetInternetUser');
    check_fail(ptNotifyAllMessages('Y'), 'ptNotifyAllMessages');
    //now we have set up the params we need for processing depending
    //on whether it a demo api or a live api (onto a test system) fire up the API for real

    check_fail(ptReady(), 'ptReady');
    check_fail(ptSuperTASEnabled(), 'ptSuperTASEnabled');

    wait_status_change(connected_status, 30000);
    sleep(1000);

    //now the host link is started login!
    //you should not login before the link is connected
    strplcopy(ls.UserID, uid, sizeof(ls.UserID) - 1);
    strplcopy(ls.Password, pass, sizeof(ls.Password) - 1);
    strplcopy(ls.NewPassword, newpass, sizeof(ls.NewPassword) - 1);
    ls.Reset:= yes_no[true];
    ls.Reports:= yes_no[reports];

    res:= ptLogon(@ls);
    if res = ptSuccess then begin
      if wait_status_change(logon_status, 30000) then begin
//      LoadStaticData;
        log('Connected ok');
        result:= 0;
      end else log('Logon failed or timeout expired');
    end else check_fail(res, 'ptLogon');
  except on e: exception do log('Connect exception: %s', [e.message]); end;
end;

function Disconnect: longint;
begin
  ptDisconnect();
  result:= 0;
end;

procedure SetOrder (order: tOrder; comment: tOrderComment; var res: tSetOrderResult);
var contract : ContractStruct;
    neworder : NewOrderStruct;
    orderid  : OrderIDStr;
    lsz      : longint;
begin
  if assigned(contract_list) then begin
    contract:= contract_list.contracts[order.level, order.code, lsz];
    if (strlen(@contract.ContractName) > 0) then begin
      fillchar(neworder, sizeof(neworder), 0);

      StrPLCopy(@neworder.TraderAccount, order.account, sizeof(neworder.TraderAccount));
      if (order.flags and opMarketPrice <> 0) then begin
        StrPLCopy(@neworder.OrderType, 'Market', sizeof(neworder.OrderType));
      end else begin
        StrPLCopy(@neworder.OrderType, 'Limit', sizeof(neworder.OrderType));
      end;
      StrLCopy(@neworder.ExchangeName, @contract.ExchangeName, sizeof(neworder.ExchangeName));
      StrLCopy(@neworder.ContractName, @contract.ContractName, sizeof(neworder.ContractName));
      StrLCopy(@neworder.ContractDate, @contract.ContractDate, sizeof(neworder.ContractDate));
      neworder.BuyOrSell:= order.buysell;
      StrPLCopy(@neworder.Price, FloatToStr(order.price * lsz), sizeof(neworder.Price));
      neworder.Lots:= order.quantity;
      neworder.OpenOrClose:= ' ';
      neworder.XrefP:= order.transaction;

      if (ptAddOrder(@neworder, @orderid) = ptSuccess) then begin
        if assigned(order_list) then order_list.push(@orderid, res);
        with res do begin accepted:= soUnknown; ExtNumber:= 0; TEReply:= ''; end;
      end else begin
        with res do begin accepted:= soRejected; ExtNumber:= 0; TEReply:= 'BITMEX: Failed to place order!'; end;
      end;

    end else with res do begin
      accepted:= soRejected; ExtNumber:= 0; TEReply:= 'BITMEX: Invalid instrument!';
    end;
  end else with res do begin
    accepted:= soRejected; ExtNumber:= 0; TEReply:= 'BITMEX: Internal error!';
  end;
end;

procedure MoveOrder(moveorder:tMoveOrder; comment:tOrderComment; var res:tSetOrderResult);
begin
  with res do begin
    accepted:= soRejected; ExtNumber:= 0; TEReply:= 'BITMEX: MoveOrder is not supported!';
  end;
end;

procedure OrderCommit (commitresult: byte; orderno: int64);
begin end;

procedure DropOrder (order: int64; flags: longint;
                     astock_id: longint; const alevel: TLevel; const acode: TCode;
                     var res: tSetOrderResult);
var order_id : OrderID;
begin
  StrPLCopy(@order_id, IntToStr(order), sizeof(OrderID));
  if (ptCancelOrder(@order_id) = ptSuccess) then begin
    with res do begin
      accepted:= soAccepted; ExtNumber:= 0; TEReply:= '';
    end;
  end else begin
    with res do begin
      accepted:= soRejected; ExtNumber:= 0; TEReply:= 'BITMEX: Unable to drop order!';
    end;
  end;
end;

procedure AfterDayOpen;
begin
  interlockedexchange(intraday, 1);
end;

procedure BeforeDayClose;
begin interlockedexchange(intraday, 0); end;

procedure ServerStatus (status: longint);
begin interlockedexchange(intraday, longint(status and (dayWasOpened or dayWasClosed) = dayWasOpened)); end;

function  PatsHook (params: pointer): longint;
begin
  if assigned(command_interface) and assigned(params) then
    if not command_interface.processcommand(pChar(params)) then log('Unknown command: %s', [pChar(params)]);
  result:= 0;
end;

function  getDllAPI(srvapi: pServerAPI): pDataSourceAPI; cdecl;
begin
  Server_API := srvapi^;
  result     := @plugapi;
end;

const section_system = 'system';

procedure DllHandler(reason: longint);
begin
  case reason of
    DLL_PROCESS_ATTACH : begin
                           decimalseparator := '.';

                           pluginfilename := expandfilename(GetModuleName(hInstance));
                           pluginfilepath := includetrailingbackslash(extractfilepath(pluginfilename));
                           pluginininame  := changefileext(pluginfilename, '.ini');

                           if fileexists(pluginininame) then
                             with tIniFile.create(pluginininame) do try
                               stocklst[0].stock_id :=  readinteger(section_system, 'stock_id',          GetpatsStockID);
                               // load system settings
                             finally free; end;
                         end;
    DLL_PROCESS_DETACH : ;
  end;
end;


exports   getDllAPI;

begin
  IsMultiThread:= true;

  DllProc:= @DllHandler;
  DllHandler(DLL_PROCESS_ATTACH);

end.
