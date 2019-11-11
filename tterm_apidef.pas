{$i tterm_defs.pas}

unit tterm_apidef;

interface

uses {$ifdef MSWINDOWS}
        windows,
     {$else}
        dynlibs,
     {$endif}
     servertypes, serverapi;

const Server_API        : tServerAPI = ( SetTrsResult          : nil; // srvSetTransactionResult;
                                         LogEvent              : nil; // srvLogEventPC;
                                         ReadBuf               : nil; // srvReadBuf;
                                         AddSecuritiesRec      : nil; // srvAddSecuritiesRec;
                                         GetSecuritiesRec      : nil; // srvGetSecuritiesRec;
                                         LockKotirovki         : nil; // srvKotirovkiLock;
                                         ClearKotirovkiTbl     : nil; // srvClearKotirovkiTbl;
                                         AddKotirovkiRec       : nil; // srvAddKotirovkiRec;
                                         UnlockKotirovki       : nil; // srvKotirovkiUnlock;
                                         AddOrdersRec          : nil; // srvAddOrdersRec;
                                         AddTradesRec          : nil; // srvAddTradesRec;
                                         AddAllTradesRec       : nil; // srvAddAllTradesRec;
                                         SetCommissBySec       : nil; // srvSetStockComissionBySec;
                                         SetAdditionalPrm      : nil; // srvSetStockAdditionalParams;
                                         GetLastNews           : nil; // srvGetLastNews;
                                         AddNewsRec            : nil; // srvAddNewsRec;
                                         SetClienLimit         : nil; // srvSetClientLimit;
                                         AddFirmsRec           : nil; // srvAddFirmsRec;
                                         AddSettleCodesRec     : nil; // srvAddSettleCodesRec;

                                         OrdersBeginUpdate     : nil; // srvOrdersLock;
                                         OrdersEndUpdate       : nil; // srvOrdersUnLock;
                                         TradesBeginUpdate     : nil; // srvTradesLock;
                                         TradesEndUpdate       : nil; // srvTradesUnLock;

                                         AllTradesBeginUpdate  : nil;
                                         AllTradesEndUpdate    : nil;
                                         SecuritiesBeginUpdate : nil;
                                         SecuritiesEndUpdate   : nil;

                                         GetAccount            : nil;
                                         GetAccountData        : nil;
                                         ReleaseAccount        : nil;

                                         Set_Order             : nil; // srvSetOrder;
                                         Drop_Order            : nil; // srvDropOrder;
                                         Set_SysOrder          : nil; // srvSetSystemOrder;

                                         SendUserMessage       : nil; // srvSendUserMessage;
                                         SendBroadcastMessage  : nil; // srvSendBroadcastMessage;

                                         SetSQLEventResult     : nil;

                                         Move_SysOrder         : nil; // srvMoveSystemOrder;
                                         Drop_OrderEx          : nil; // srvDropOrderEx
                                        );

implementation
//  {$ifndef MSWINDOWS}
//  uses tterm_logger;
//  {$endif}

initialization
//  {$ifdef MSWINDOWS}
  with Server_API do begin
    SetTrsResult            := getprocaddress(hInstance, srv_SetTransactionResult);
    LogEvent                := getprocaddress(hInstance, srv_LogEventPC);
    ReadBuf                 := getprocaddress(hInstance, srv_ReadBuf);
    AddSecuritiesRec        := getprocaddress(hInstance, srv_AddSecuritiesRec);
    GetSecuritiesRec        := getprocaddress(hInstance, srv_GetSecuritiesRec);
    LockKotirovki           := getprocaddress(hInstance, srv_KotirovkiLock);
    ClearKotirovkiTbl       := getprocaddress(hInstance, srv_ClearKotirovkiTbl);
    AddKotirovkiRec         := getprocaddress(hInstance, srv_AddKotirovkiRec);
    UnlockKotirovki         := getprocaddress(hInstance, srv_KotirovkiUnlock);
    AddOrdersRec            := getprocaddress(hInstance, srv_AddOrdersRec);
    AddTradesRec            := getprocaddress(hInstance, srv_AddTradesRec);
    AddAllTradesRec         := getprocaddress(hInstance, srv_AddAllTradesRec);

    SetCommissBySec         := getprocaddress(hInstance, srv_SetStockComissionBySec);
    SetAdditionalPrm        := getprocaddress(hInstance, srv_SetStockAdditionalParams);
    GetLastNews             := getprocaddress(hInstance, srv_GetLastNews);
    AddNewsRec              := getprocaddress(hInstance, srv_AddNewsRec);
    SetClienLimit           := getprocaddress(hInstance, srv_SetClientLimit);
    AddFirmsRec             := getprocaddress(hInstance, srv_AddFirmsRec);
    AddSettleCodesRec       := getprocaddress(hInstance, srv_AddSettleCodesRec);

    OrdersBeginUpdate       := getprocaddress(hInstance, srv_OrdersBeginUpdate);
    OrdersEndUpdate         := getprocaddress(hInstance, srv_OrdersEndUpdate);
    TradesBeginUpdate       := getprocaddress(hInstance, srv_TradesBeginUpdate);
    TradesEndUpdate         := getprocaddress(hInstance, srv_TradesEndUpdate);

    //AllTradesBeginUpdate    : nil;
    //AllTradesEndUpdate      : nil;
    //SecuritiesBeginUpdate   : nil;
    //SecuritiesEndUpdate     : nil;

    GetAccount              := getprocaddress(hInstance, srv_GetAccount);
    GetAccountData          := getprocaddress(hInstance, srv_GetAccountData);
    ReleaseAccount          := getprocaddress(hInstance, srv_ReleaseAccount);

    Set_Order               := getprocaddress(hInstance, srv_SetSystemOrder);
    Drop_Order              := getprocaddress(hInstance, srv_DropOrder);
    Set_SysOrder            := getprocaddress(hInstance, srv_SetSystemOrder);

    SendUserMessage         := getprocaddress(hInstance, srv_SendUserMessage);
    SendBroadcastMessage    := getprocaddress(hInstance, srv_SendBroadcastMessage);

    SetSQLEventResult       := getprocaddress(hInstance, srv_SetSQLEventResult);

    Move_SysOrder           := getprocaddress(hInstance, srv_MoveSystemOrder);
    Drop_OrderEx            := getprocaddress(hInstance, srv_DropOrderEx);
  end;
//  {$else}
//  with Server_API do begin
////    SetTrsResult            := getprocaddress(hInstance, srv_SetTransactionResult);
//    @LogEvent               := @legacy_logevent;
//  end;
//  {$endif}

end.