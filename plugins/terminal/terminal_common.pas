{$i terminal_defs.pas}

unit terminal_common;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$else}
        dynlibs,
      {$endif}
      sysutils,
      serverapi, tterm_api;

const PlugName  = 'terminal';

const {$ifdef MSWINDOWS}
      ExeFileName          : ansistring = 'terminal.dll';
      IniFileName          : ansistring = 'terminal.ini';
      {$else}
      ExeFileName          : ansistring = 'libterminal.so';
      IniFileName          : ansistring = 'libterminal.ini';
      {$endif}
      ExeFilePath          : ansistring = '.';

      SereverIniSection    : ansistring = 'server';

const server_api           : pServerAPI               = nil;
      plugin_api           : pDataSourceApi           = nil;

      srv_enumtables       : tEnumerateTables         = nil;
      srv_enumtablerecords : tEnumerateTableRecords   = nil;

      srv_getapis          : tGetLegacyAPIs           = nil;

      srvUpdateSecurities  : tsrvUpdateSecuritiesRec  = nil;
      srvCleanupSecurities : tsrvCleanupSecuritiesRec = nil;
      srvUpdateOrders      : tsrvUpdateOrders         = nil;
      srvCleanupOrders     : tsrvCleanupOrders        = nil;
      srvUpdateTrades      : tsrvUpdateTrades         = nil;
      srvCleanupTrades     : tsrvCleanupTrades        = nil;
      srvUpdateFirmsRec    : tsrvUpdateFirmsRec       = nil;


procedure log(const aevent: ansistring); overload;
procedure log(const aevent: ansistring; const aparams: array of const); overload;

implementation

procedure log(const aevent: ansistring; const aparams: array of const);
begin
  if assigned(server_api) and assigned(server_api^.LogEvent) then
    server_api^.LogEvent(pAnsiChar(format('TERMINAL: ' + aevent, aparams)));
end;

procedure log(const aevent: ansistring);
begin
  if assigned(server_api) and assigned(server_api^.LogEvent) then
    server_api^.LogEvent(pAnsiChar('TERMINAL: ' + aevent));
end;

end.