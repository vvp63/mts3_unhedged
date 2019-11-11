unit accountsupport_common;

interface

uses  windows, sysutils,
      serverapi, tterm_api;

const PlugName  = 'accountsupport';

const ExeFileName          : ansistring = 'accountsupport.dll';
      IniFileName          : ansistring = 'accountsupport.ini';
      ExeFilePath          : ansistring = '.\';

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

function  GetModuleName(Module: HMODULE): ansistring;

implementation

var tmpname : ansistring;

procedure log(const aevent: ansistring; const aparams: array of const);
begin
  if assigned(server_api) and assigned(server_api^.LogEvent) then
    server_api^.LogEvent(pAnsiChar(format('ACCOUNTS: ' + aevent, aparams)));
end;

procedure log(const aevent: ansistring);
begin
  if assigned(server_api) and assigned(server_api^.LogEvent) then
    server_api^.LogEvent(pAnsiChar('ACCOUNTS: ' + aevent));
end;

function GetModuleName(Module: HMODULE): ansistring;
var ModName: array[0..MAX_PATH] of char;
begin SetString(Result, ModName, GetModuleFileName(Module, ModName, SizeOf(ModName))); end;

initialization
  tmpname     := GetModuleName(hinstance);
  ExeFileName := ExtractFileName(tmpname);
  IniFileName := ChangeFileExt(ExpandFileName(tmpname), '.ini');
  ExeFilePath := IncludeTrailingBackSlash(ExtractFilePath(ExpandFileName(tmpname)));

  srv_enumtables       := GetProcAddress(0, SRV_EnumerateTables);
  srv_enumtablerecords := GetProcAddress(0, SRV_EnumerateTableRecords);

  srv_getapis          := GetProcAddress(0, SRV_GetLegacyAPIs);

  srvUpdateSecurities  := GetProcAddress(0, srv_UpdateSecuritiesRec);
  srvCleanupSecurities := GetProcAddress(0, srv_CleanupSecuritiesRec);
  srvUpdateOrders      := GetProcAddress(0, srv_UpdateOrders);
  srvCleanupOrders     := GetProcAddress(0, srv_CleanupOrders);
  srvUpdateTrades      := GetProcAddress(0, srv_UpdateTrades);
  srvCleanupTrades     := GetProcAddress(0, srv_CleanupTrades);
  srvUpdateFirmsRec    := GetProcAddress(0, srv_UpdateFirmsRec);

end.