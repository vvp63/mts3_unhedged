{$i terminal_defs.pas}

unit terminal_thread;

interface

uses  {$ifdef MSWINDOWS}
        windows, inifiles,
      {$else}
        fclinifiles,
      {$endif}
      classes, sysutils,
      custom_threads, sockobjects,
      terminal_common, terminal_server, terminal_client;

type  tTerminalThread = class(tCustomThread)
        procedure  execute; override;
      end;

const terminalthread  : tTerminalThread = nil;

procedure InitializeTerminalSupport;
procedure FinalizeTerminalSupport;

implementation

{ tTerminalThread }

procedure tTerminalThread.execute;
begin
  freeonterminate:= false;
  try
    if assigned(GlobalSocketList) then GlobalSocketList.polltimeout:= 10;

    with tIniFile.create(IniFileName) do try
      with tTerminalServer.create(IniFileName, SereverIniSection) do begin
        clientsocketclass:= tTerminalClient;
        if (bind(readinteger(SereverIniSection, 'port', 0)) = 0) then begin
          listen(readstring(SereverIniSection, 'allow_address', ''),
                 readstring(SereverIniSection, 'allow_mask',    ''))
        end else log(format('unable to bind port %d', [port]));
      end;
    finally free; end;

    while not terminated do ProcessSocketIO;

  except on e: exception do log('connections thread exception: %s', [e.message]); end;
  log('terminal thread exited...');
end;

{ misc functions }

procedure InitializeTerminalSupport;
begin
  try
    if assigned(terminalthread) then FinalizeTerminalSupport;
    if not assigned(terminalthread) then terminalthread:= tTerminalThread.Create(false);
  except on e: exception do log('init terminal server exception: %s', [e.message]); end;
end;

procedure FinalizeTerminalSupport;
begin
  try
    if assigned(terminalthread) then try
      terminalthread.terminate;
      terminalthread.WaitFor;
    finally freeandnil(terminalthread); end;
  except on e: exception do log('finalize terminal server exception: %s', [e.message]); end;
end;

initialization

finalization
  FinalizeTerminalSupport;

end.