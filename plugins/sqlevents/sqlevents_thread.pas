{$define usesqlmonitorreply}
{$define usemarginregistry}

unit sqlevents_thread;

interface

uses  windows, classes, sysutils,
      threads,
      servertypes, protodef, serverapi,
      mmfSendReceive,
      tterm_api, 
      sqlevents_common;

const SQL_EventError      = -1;
      SQL_NewMoves        = 1;
      SQL_AccountChanged  = 2;
      SQL_IndLimitChanged = 3;

type  TSQLEventThread     = class(tCustomThread)
      private
        FResStream        : TResultBuilder;
        FCommandList      : tStringList;
        FCommunicator     : tMMFCommunicator;
        FEnableEvents     : boolean;
      protected
        procedure   execute; override;
        procedure   processevent(aresstream: tResultBuilder; const acode, aparam: ansistring); virtual;
      public
        constructor create;
        destructor  destroy; override;
        procedure   terminate; override;

        property    EnableEvents: boolean read FEnableEvents write FEnableEvents;
      end;

const SQLEventThread : TSQLEventThread = nil;

function plgSetSQLEventResult(aresulthandle: pointer; adata: pAnsiChar; adatasize: longint): longint; stdcall;

procedure InitSQLMonitor;
procedure DoneSQLMonitor;

implementation

type  tSQLCodeItem = record
        strcode    : ansistring;
        intcode    : longint;
      end;

const SQLCodes     : array[0..2] of tSQLCodeItem =
        ((strcode: 'SQL_NewMoves';        intcode: SQL_NewMoves;       ),
         (strcode: 'SQL_AccountChanged';  intcode: SQL_AccountChanged; ),
         (strcode: 'SQL_IndLimitChanged'; intcode: SQL_IndLimitChanged;));

function TranslateCode(const acode: ansistring): longint;
var i : longint;
  function IsNumber(const acode: ansistring): boolean;
  var i : longint;
  begin
    result:= true; i:= 1;
    while (i <= length(acode)) do
      if not (acode[i] in ['0'..'9']) then begin
        i:= length(acode) + 1;
        result:= false;
      end else inc(i);
  end;
begin
  if IsNumber(acode) then begin
    result:= strtointdef(acode, SQL_EventError);
  end else begin
    result:= SQL_EventError;
    i:= low(SQLCodes);
    while (i <= high(SQLCodes)) do
      if (comparetext(acode, SQLCodes[i].strcode) = 0) then begin
        i:= high(SQLCodes) + 1;
        result:= SQLCodes[i].intcode;
      end else inc(i);
  end;
end;

function plgSetSQLEventResult(aresulthandle: pointer; adata: pAnsiChar; adatasize: longint): longint;
begin
  result:= PLUGIN_ERROR;
  if assigned(aresulthandle) then
    if assigned(SQLEventThread) and (SQLEventThread.FResStream = aresulthandle) then try
      with tResultBuilder(aresulthandle) do begin
        clear;
        if assigned(adata) then begin
          write(adata^, adatasize);
          result:= PLUGIN_OK;
        end;
      end;
    except on e: exception do log('Exception: %s', [e.message]); end;
end;

{ TSQLEventThread }

constructor TSQLEventThread.create;
begin
  inherited create(false);
  freeonterminate:= false;

  FCommandList:= tStringList.create;

  FCommunicator:= tMMFCommunicator.create;
  if not FCommunicator.CreateServer then log('Unable to initialize SQL communication server');

  FEnableEvents := false;
end;

destructor TSQLEventThread.destroy;
begin
  if assigned(FCommunicator) then freeandnil(FCommunicator);
  if assigned(FCommandList) then freeandnil(FCommandList);
  inherited destroy;
end;

procedure TSQLEventThread.execute;
begin
  try
    FResStream:= TResultBuilder.create;
    try
      if assigned(FCommunicator) then FCommunicator.SetConvReady;
      while not Terminated do
        if not Terminated and assigned(FCommunicator) then try
          if assigned(FCommandList) and FCommunicator.WaitDataIsReady(10000) then try
            FResStream.clear;
            FCommunicator.MMFReceiveData(FCommandList, mmfDataNameReceive);
            if not Terminated then begin
              {$ifdef usesqlmonitorreply}
              try
              {$endif}
                if (FCommandList.count >= 2) then processevent(FResStream, FCommandList[0], FCommandList[1])
                                             else log('Received less than 2 parameters');
              {$ifdef usesqlmonitorreply}
              finally FCommunicator.MMFSendData(FResStream, mmfDataNameSend); end;
              {$endif}
            end;
          finally
            FCommandList.clear;
            {$ifdef usesqlmonitorreply}
            FCommunicator.SetConvReady;
            {$endif}
          end;
        except
          on e: Exception do begin
            log('Conversation error: %s', [e.message]);
            FCommunicator.ResetServer;
            sleep(10);
          end;
        end;
    finally freeandnil(FResStream); end;
  except on e: Exception do log('Exception: %s', [e.message]); end;
end;

procedure TSQLEventThread.terminate;
begin
  inherited terminate;
  if assigned(FCommunicator) then FCommunicator.CancelWaiting;
end;

procedure TSQLEventThread.processevent(aresstream: tResultBuilder; const acode, aparam: ansistring);
type pptrarray  = ^tptrarray;
     tptrarray  = array[0..0] of pDataSourceAPI;
var  apis       : pptrarray;
     i, count   : longint;
var  handled    : boolean;
     faccount   : tAccount;
begin
  handled:= false;

  // execute plugin event
  apis:= nil;
  if assigned(srv_getapis) and (srv_getapis(pointer(apis), count) = PLUGIN_OK) then begin
    i:= 0;
    while not handled and (i < count) do begin
      if assigned(apis^[i]) and (apis^[i] <> plugin_api) then
        if (apis^[i]^.plugflags and plEventHandler <> 0) then with apis^[i]^ do
          if assigned(eventAPI) and assigned(eventAPI^.evSQLServerEvent) then
            handled:= eventAPI^.evSQLServerEvent(pAnsiChar(acode), pAnsiChar(aparam), longint(aresstream));
      inc(i);
    end;
  end else count:= 0;

  // server-specific events
  if FEnableEvents then begin
    if not handled then
      case TranslateCode(acode) of
        SQL_NewMoves        : try
                                log('New moves arrived for account: %s', [aparam]);
                                faccount:= aparam;

                                // some obsolete code was here
                                // ...

                                // execute plugin event
                                if assigned(apis) then
                                  for i:= 0 to count - 1 do
                                    if assigned(apis^[i]) and (apis^[i] <> plugin_api) then
                                      if (apis^[i]^.plugflags and plEventHandler <> 0) then with apis^[i]^ do
                                        if assigned(eventAPI) and assigned(eventAPI^.evAccountUpdated) then eventAPI^.evAccountUpdated(faccount);
                              except on e:exception do log('Calc moves: Exception: %s', [e.message]); end;
        SQL_AccountChanged  : log('Account information changed for account: %s; OBSOLETE FUNCTION!', [aparam]);
        SQL_IndLimitChanged : log('Individual margin limits changed for account: %s; OBSOLETE FUNCTION!', [aparam]);
        else                log('Event: code: %s param: "%s" was not processed by server', [acode, aparam]);
      end;
  end else log('Event processing suspended', [aparam]);
end;

procedure InitSQLMonitor;
begin SQLEventThread:= TSQLEventThread.create; end;

procedure DoneSQLMonitor;
begin
  if assigned(SQLEventThread) then with SQLEventThread do try
    terminate; waitfor;
  finally freeandnil(SQLEventThread); end;
  log('SQL Monitor terminated.');
end;

exports
  plgSetSQLEventResult name PLG_SetSQLEventResult;

end.