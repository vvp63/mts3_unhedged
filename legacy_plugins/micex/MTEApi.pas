{$ifdef FPC}
  {$mode DELPHI}
{$endif}

{$ifdef Unix}
  {$undef DYNAMIC_MTEAPI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit MTEApi;

{.$DEFINE DYNAMIC_MTEAPI}

interface

uses
  {$ifdef MSWINDOWS}Windows,{$endif}SysUtils, MTETypes;

type
  TMTESrlAddOn = (msaExecTransIP, msaGetExtData, msaConnStats, msaConnStatus,
    msaGetVersion, msaConnCerts, msaGetServInfo, msaSoftConnect, msaLogon,
    msaSelectBoards, msaGetExtDataRange, msaErrorMsgEx, msaStructure2,
    msaExecTransEx, msaGetTablesFromSnapshot, msaOpenTableAtSnapshot);
  TMTESrlAddOns = set of TMTESrlAddOn;

type
  TMTEExecTransIPProc = function (Idx: Integer; TransName, Params: PAnsiChar; ResultMsg: PMTEErrorMsg; ClientIP: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEGetExtDataProc = function (Idx: Integer; DataSetName, ExtFileName: PAnsiChar; var Msg: PMTEMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEConnectionStatsProc = function (Idx: Integer; var Stats: TMTEConnStats): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEConnectionStatusProc = function (Idx: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEGetVersionProc = function : PAnsiChar; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEConnectionCertsProc = function (Idx: Integer; MyCert, ServerCert: PMTEConnCertificate): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEGetServInfoProc = function (Idx: Integer; var ServInfo: PByte; var Len: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTESoftConnectProc = function (Params: PAnsiChar; ErrorMsg: PMTEErrorMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTELogonProc = function (Idx: Integer; sync_time: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTESelectBoardsProc = function (Idx: Integer; BoardList: PAnsiChar; ResultMsg: PMTEErrorMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEGetExtDataRangeProc = function (Idx: Integer; DataSetName, ExtFileName: PAnsiChar;
    DataOffset, DataSize: Cardinal; var Msg: PMTEMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEErrorMsgExProc = function (ErrCode: TMTEResult; Language: PAnsiChar): PAnsiChar; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEStructure2Proc = function (Idx: Integer; var Msg: PMTEMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEExecTransExProc = function (Idx: Integer; TransName, Params: PAnsiChar; ClientIp: Integer; var Reply: TMTEExecTransResult): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEGetTablesFromSnapshot = function (Idx: Integer; Snapshot: PByte; Len: Integer; var SnapTables: PMTESnapTables): Integer; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEOpenTableAtSnapshot = function (Idx: Integer; TableName, Params: PAnsiChar; Snapshot: PByte; SnapshotLen: Integer; var Msg: PMTEMsg): Integer; {$ifdef Unix}cdecl{$else}stdcall{$endif};

{$ifdef DYNAMIC_MTEAPI}
type
  TMTEConnectProc = function (Params: PAnsiChar; ErrorMsg: PMTEErrorMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEDisconnectProc = function(Idx: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEStructureProc = function (Idx: Integer; var Msg: PMTEMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEExecTransProc = function (Idx: Integer; TransName, Params: PAnsiChar; ResultMsg: PMTEErrorMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEOpenTableProc = function (Idx: Integer; TableName, Params: PAnsiChar; Complete: LongBool; var Msg: PMTEMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTECloseTableProc = function (Idx, HTable: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEAddTableProc = function (Idx, HTable, Ref: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTERefreshProc = function (Idx: Integer; var Msg: PMTEMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEErrorMsgProc = function (ErrCode: TMTEResult): PAnsiChar; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEFreeBufferProc = function (Idx: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTEGetSnapshotProc = function (Idx: Integer; var Snapshot: PByte; var Len: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
  TMTESetSnapshotProc = function (Idx: Integer; Snapshot: PByte; Len: Integer; ErrorMsg: PMTEErrorMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};

  PMTEApi = ^TMTEApi;
  TMTEApi = class
  private
    fDllHandle: HMODULE;
    fMTESrlAddons: TMTESrlAddOns;
    // begin of function pointers
    fMTEConnect: TMTEConnectProc;
    fMTEDisconnect: TMTEDisconnectProc;
    fMTEStructure: TMTEStructureProc;
    fMTEExecTrans: TMTEExecTransProc;
    fMTEOpenTable: TMTEOpenTableProc;
    fMTECloseTable: TMTECloseTableProc;
    fMTEAddTable: TMTEAddTableProc;
    fMTERefresh: TMTERefreshProc;
    fMTEErrorMsg: TMTEErrorMsgProc;
    fMTEFreeBuffer: TMTEFreeBufferProc;
    fMTEGetSnapshot: TMTEGetSnapshotProc;
    fMTESetSnapshot: TMTESetSnapshotProc;
    fMTEExecTransIP: TMTEExecTransIPProc;
    fMTEGetExtData: TMTEGetExtDataProc;
    fMTEConnectionStats: TMTEConnectionStatsProc;
    fMTEConnectionStatus: TMTEConnectionStatusProc;
    fMTEGetVersion: TMTEGetVersionProc;
    fMTEConnectionCerts: TMTEConnectionCertsProc;
    fMTEGetServInfo: TMTEGetServInfoProc;
    fMTESoftConnect: TMTESoftConnectProc;
    fMTELogon: TMTELogonProc;
    fMTESelectBoards: TMTESelectBoardsProc;
    fMTEGetExtDataRange: TMTEGetExtDataRangeProc;
    fMTEErrorMsgEx: TMTEErrorMsgExProc;
    fMTEStructure2: TMTEStructure2Proc;
    fMTEExecTransEx: TMTEExecTransExProc;
    fMTEGetTablesFromSnapshot: TMTEGetTablesFromSnapshot;
    fMTEOpenTableAtSnapshot: TMTEOpenTableAtSnapshot;
    // end of function pointers
  public
    constructor Create(const FileName: String);
    destructor Destroy; override;
    // obligatory functions
    property MTEConnect: TMTEConnectProc read fMTEConnect;
    property MTEDisconnect: TMTEDisconnectProc read fMTEDisconnect;
    property MTEStructure: TMTEStructureProc read fMTEStructure;
    property MTEExecTrans: TMTEExecTransProc read fMTEExecTrans;
    property MTEOpenTable: TMTEOpenTableProc read fMTEOpenTable;
    property MTECloseTable: TMTECloseTableProc read fMTECloseTable;
    property MTEAddTable: TMTEAddTableProc read fMTEAddTable;
    property MTERefresh: TMTERefreshProc read fMTERefresh;
    property MTEErrorMsg: TMTEErrorMsgProc read fMTEErrorMsg;
    property MTEFreeBuffer: TMTEFreeBufferProc read fMTEFreeBuffer;
    property MTEGetSnapshot: TMTEGetSnapshotProc read fMTEGetSnapshot;
    property MTESetSnapshot: TMTESetSnapshotProc read fMTESetSnapshot;
    // optional function
    property MTEExecTransIP: TMTEExecTransIPProc read fMTEExecTransIP;
    property MTEGetExtData: TMTEGetExtDataProc read fMTEGetExtData;
    property MTEConnectionStats: TMTEConnectionStatsProc read fMTEConnectionStats;
    property MTEConnectionStatus: TMTEConnectionStatusProc read fMTEConnectionStatus;
    property MTEGetVersion: TMTEGetVersionProc read fMTEGetVersion;
    property MTEConnectionCerts: TMTEConnectionCertsProc read fMTEConnectionCerts;
    property MTEGetServInfo: TMTEGetServInfoProc read fMTEGetServInfo;
    property MTESoftConnect: TMTESoftConnectProc read fMTESoftConnect;
    property MTELogon: TMTELogonProc read fMTELogon;
    property MTESelectBoards: TMTESelectBoardsProc read fMTESelectBoards;
    property MTEGetExtDataRange: TMTEGetExtDataRangeProc read fMTEGetExtDataRange;
    property MTEStructure2: TMTEStructure2Proc read fMTEStructure2;
    property MTEExecTransEx: TMTEExecTransExProc read fMTEExecTransEx;
    property MTEGetTablesFromSnapshot: TMTEGetTablesFromSnapshot read fMTEGetTablesFromSnapshot;
    property MTEOpenTableAtSnapshot: TMTEOpenTableAtSnapshot read fMTEOpenTableAtSnapshot;
    // helper function
    property GetMTESrlAddons: TMTESrlAddOns read fMTESrlAddons;
    function MTEErrorMsgEx(ErrCode: Integer; Language: PAnsiChar): PAnsiChar; stdcall;
  end;
{$else}
function MTEConnect(Params: PAnsiChar; ErrorMsg: PMTEErrorMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEDisconnect(Idx: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEStructure(Idx: Integer; var Msg: PMTEMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEExecTrans(Idx: Integer; TransName, Params: PAnsiChar; ResultMsg: PMTEErrorMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEOpenTable(Idx: Integer; TableName, Params: PAnsiChar; Complete: LongBool; var Msg: PMTEMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTECloseTable(Idx, HTable: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEAddTable(Idx, HTable, Ref: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTERefresh(Idx: Integer; var Msg: PMTEMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEErrorMsg(ErrCode: TMTEResult): PAnsiChar; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEFreeBuffer(Idx: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEGetSnapshot(Idx: Integer; var Snapshot: PByte; var Len: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTESetSnapshot(Idx: Integer; Snapshot: PByte; Len: Integer; ErrorMsg: PMTEErrorMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
// optional functions, depend on version of MTESRL.DLL
function MTEGetExtData(Idx: Integer; DataSetName, ExtFileName: PAnsiChar; var Msg: PMTEMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEExecTransIP(Idx: Integer; TransName, Params: PAnsiChar; ResultMsg: PMTEErrorMsg; ClientIP: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEConnectionStats(Idx: Integer; var Stats: TMTEConnStats): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEConnectionStatus(Idx: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEConnectionCerts(Idx: Integer; MyCert, ServerCert: PMTEConnCertificate): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEGetVersion: PAnsiChar; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEGetServInfo(Idx: Integer; var ServInfo: PByte; var Len: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTESelectBoards(Idx: Integer; BoardList: PAnsiChar; ResultMsg: PMTEErrorMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEGetExtDataRange(Idx: Integer; DataSetName, ExtFileName: PAnsiChar;
  DataOffset, DataSize: Cardinal; var Msg: PMTEMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEStructure2(Idx: Integer; var Msg: PMTEMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEExecTransEx(Idx: Integer; TransName, Params: PAnsiChar; ClientIp: Integer; var Reply: TMTEExecTransResult): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEGetTablesFromSnapshot(Idx: Integer; Snapshot: PByte; Len: Integer; var SnapTables: PMTESnapTables): Integer; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEOpenTableAtSnapshot(Idx: Integer; TableName, Params: PAnsiChar; Snapshot: PByte; SnapshotLen: Integer; var Msg: PMTEMsg): Integer; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEErrorMsgEx(ErrCode: TMTEResult; Language: PAnsiChar): PAnsiChar; {$ifdef Unix}cdecl{$else}stdcall{$endif};
// CMA compatibility functions
function MTESoftConnect(Params: PAnsiChar; ErrorMsg: PMTEErrorMsg): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTELogon(Idx: Integer; sync_time: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
// service functions
function GetMTESrlAddons: TMTESrlAddOns;
{$endif}

{$ifdef VisualBasic}
function MTEStructureVB(Idx: Integer; Buffer: PAnsiChar; var Len: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTEOpenTableVB(Idx: Integer; TableName, Params: PAnsiChar; Complete: LongBool; Buffer: PAnsiChar; var Len: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function MTERefreshVB(Idx: Integer; Buffer: PAnsiChar; var Len: Integer): TMTEResult; {$ifdef Unix}cdecl{$else}stdcall{$endif};
{$endif}

implementation

//{$ifdef FPC}uses DynLibs;{$endif}

const
  {$ifndef MSWINDOWS}
    {$ifdef CPUX64}
    micexdll = 'mtesrl64';
    {$else}
    micexdll = 'mtesrl';
    {$endif}
  {$else}
    {$ifdef CPUX64}
    micexdll = 'mtesrl64.dll';
    {$else}
    micexdll = 'mtesrl.dll'; 
    {$endif}
  {$endif}

{$ifdef DYNAMIC_MTEAPI}

{ TMTEApi }

resourcestring
  rsNoFunction = '%s function is not supported by MTESRL.DLL library';

constructor TMTEApi.Create(const FileName: string);
const
  sFunctions: array [0..27] of PAnsiChar = (
    'MTEConnect',
    'MTEDisconnect',
    'MTEStructure',
    'MTEExecTrans',
    'MTEOpenTable',
    'MTECloseTable',
    'MTEAddTable',
    'MTERefresh',
    'MTEErrorMsg',
    'MTEFreeBuffer',
    'MTEGetSnapshot',
    'MTESetSnapshot',
    'MTEExecTransIP',
    'MTEGetExtData',
    'MTEConnectionStats',
    'MTEConnectionStatus',
    'MTEGetVersion',
    'MTEConnectionCerts',
    'MTEGetServInfo',
    'MTESoftConnect',
    'MTELogon',
    'MTESelectBoards',
    'MTEGetExtDataRange',
    'MTEErrorMsgEx',
    'MTEStructure2',
    'MTEExecTransEx',
    'MTEGetTablesFromSnapshot',
    'MTEOpenTableAtSnapshot');

var
  S: String;
  P: PPointer; //^FARPROC;
  I: Integer;
begin
  S := FileName;
  if ExtractFilePath(FileName) = '' then S := ExtractFilePath(ParamStr(0))
  else S := ExtractFilePath(FileName);
  if ExtractFileName(FileName) = '' then S := IncludeTrailingPathDelimiter(S) + micexdll
  else S := S + ExtractFileName(FileName);

  fDllHandle := LoadLibrary(@S[1]);
  if fDllHandle = 0 then RaiseLastOSError;

  P := @@fMTEConnect;
  for I := Low(sFunctions) to High(sFunctions) do
  begin
    P^ := GetProcAddress(fDllHandle, sFunctions[I]);
    if (not Assigned(P^)) and (I < 12) then
      raise Exception.CreateFmt(rsNoFunction, [sFunctions[I]]);
    Inc(P);
  end;

  if Assigned(fMTEExecTransIP) then Include(fMTESrlAddons, msaExecTransIP);
  if Assigned(fMTEGetExtData) then Include(fMTESrlAddons, msaGetExtData);
  if Assigned(fMTEConnectionStats) then Include(fMTESrlAddons, msaConnStats);
  if Assigned(fMTEConnectionStatus) then Include(fMTESrlAddons, msaConnStatus);
  if Assigned(fMTEGetVersion) then Include(fMTESrlAddons, msaGetVersion);
  if Assigned(fMTEConnectionCerts) then Include(fMTESrlAddons, msaConnCerts);
  if Assigned(fMTEGetServInfo) then Include(fMTESrlAddons, msaGetServInfo);
  if Assigned(fMTESoftConnect) then Include(fMTESrlAddons, msaSoftConnect);
  if Assigned(fMTELogon) then Include(fMTESrlAddons, msaLogon);
  if Assigned(fMTESelectBoards) then Include(fMTESrlAddons, msaSelectBoards);
  if Assigned(fMTEGetExtDataRange) then Include(fMTESrlAddons, msaGetExtDataRange);
  if Assigned(fMTEErrorMsgEx) then Include(fMTESrlAddons, msaErrorMsgEx);
  if Assigned(fMTEStructure2) then Include(fMTESrlAddons, msaStructure2);
  if Assigned(fMTEExecTransEx) then Include(fMTESrlAddons, msaExecTransEx);
  if Assigned(fMTEGetTablesFromSnapshot) then Include(fMTESrlAddons, msaGetTablesFromSnapshot);
  if Assigned(fMTEOpenTableAtSnapshot) then Include(fMTESrlAddons, msaOpenTableAtSnapshot);
end;

destructor TMTEApi.Destroy;
begin
  if fDllHandle <> 0 then FreeLibrary(fDllHandle);
  inherited;
end;

function TMTEApi.MTEErrorMsgEx(ErrCode: TMTEResult; Language: PAnsiChar): PAnsiChar; stdcall;
begin
  if Assigned(fMTEErrorMsgEx) then
    Result := fMTEErrorMsgEx(ErrCode, Language)
  else
    Result := MTEErrorMsg(ErrCode);
end;

{$else}

function MTEConnect; external micexdll;
function MTEDisconnect; external micexdll;
function MTEStructure; external micexdll;
function MTEExecTrans; external micexdll;
function MTEOpenTable; external micexdll;
function MTECloseTable; external micexdll;
function MTEAddTable; external micexdll;
function MTERefresh; external micexdll;
function MTEErrorMsg; external micexdll;
function MTEFreeBuffer; external micexdll;
function MTEGetSnapshot; external micexdll;
function MTESetSnapshot; external micexdll;

{$ifdef VisualBasic}
function MTEStructureVB; external micexdll;
function MTEOpenTableVB; external micexdll;
function MTERefreshVB; external micexdll;
{$endif}

{$ifdef Unix}

var
  MTESrlAddons: TMTESrlAddOns = [
    msaExecTransIP, msaGetExtData, msaConnStats, msaConnStatus,
    msaGetVersion, {msaConnCerts,} msaGetServInfo, {msaSoftConnect,}
    {msaLogon,} msaSelectBoards, msaGetExtDataRange, msaErrorMsgEx,
    msaStructure2, msaExecTransEx
  ];

function MTEExecTransIP; external micexdll;
function MTEGetExtData; external micexdll;
function MTEConnectionStats; external micexdll;
function MTEConnectionStatus; external micexdll;
function MTEGetVersion; external micexdll;
function MTEConnectionCerts(Idx: Integer; MyCert, ServerCert: PMTEConnCertificate): TMTEResult;
begin
  Result := MTE_NOTIMPLEMENTED;
end;
function MTEGetServInfo; external micexdll;
function MTESoftConnect(Params: PAnsiChar; ErrorMsg: PMTEErrorMsg): TMTEResult;
begin
  Result := MTE_NOTIMPLEMENTED;
end;
function MTELogon(Idx: Integer; sync_time: Integer): TMTEResult;
begin
  Result := MTE_NOTIMPLEMENTED;
end;
function MTESelectBoards; external micexdll;
function MTEGetExtDataRange; external micexdll;
function MTEErrorMsgEx; external micexdll;
function MTEStructure2; external micexdll;
function MTEExecTransEx; external micexdll;
function MTEGetTablesFromSnapshot; external micexdll;
function MTEOpenTableAtSnapshot; external micexdll;

{$else}

var
  MTESrlAddons: TMTESrlAddOns = [];
  MTESrlLoaded: Boolean = False;

var
  _MTEExecTransIP: TMTEExecTransIPProc = nil;
  _MTEGetExtData: TMTEGetExtDataProc = nil;
  _MTEConnectionStats: TMTEConnectionStatsProc = nil;
  _MTEConnectionStatus: TMTEConnectionStatusProc = nil;
  _MTEGetVersion: TMTEGetVersionProc = nil;
  _MTEConnectionCerts: TMTEConnectionCertsProc = nil;
  _MTEGetServInfo: TMTEGetServInfoProc = nil;
  _MTESoftConnect: TMTESoftConnectProc = nil;
  _MTELogon: TMTELogonProc = nil;
  _MTESelectBoards: TMTESelectBoardsProc = nil;
  _MTEGetExtDataRange: TMTEGetExtDataRangeProc = nil;
  _MTEErrorMsgEx: TMTEErrorMsgExProc = nil;
  _MTEStructure2: TMTEStructure2Proc = nil;
  _MTEExecTransEx: TMTEExecTransExProc = nil;
  _MTEGetTablesFromSnapshot: TMTEGetTablesFromSnapshot = nil;
  _MTEOpenTableAtSnapshot: TMTEOpenTableAtSnapshot = nil;

resourcestring
  rsNoExecTransIP = 'MTEExecTransIP() function is not supported by MTESRL.DLL library';
  rsNoGetExtData  = 'MTEGetExtData() function is not supported by MTESRL.DLL library';
  rsNoGetServInfo = 'MTEGetServInfo() function is not supported by MTESRL.DLL library';
  rsNoSoftConnect = 'MTESoftConnect() function is not supported by MTESRL.DLL library';
  rsNoGetExtDataR = 'MTEGetExtDataRange() function is not supported by MTESRL.DLL library';
  rsNoStructure2  = 'MTEStructure2() function is not supported by MTESRL.DLL library';

procedure LoadMTESrl;
var
  H: THandle;
begin
  if not MTESrlLoaded then
  begin
    MTESrlLoaded := True;
    H := GetModuleHandle(micexdll);
    if H <> 0 then
    begin
      _MTEExecTransIP := GetProcAddress(H, 'MTEExecTransIP');
      _MTEGetExtData := GetProcAddress(H, 'MTEGetExtData');
      _MTEConnectionStats := GetProcAddress(H, 'MTEConnectionStats');
      _MTEConnectionStatus := GetProcAddress(H, 'MTEConnectionStatus');
      _MTEGetVersion := GetProcAddress(H, 'MTEGetVersion');
      _MTEConnectionCerts := GetProcAddress(H, 'MTEConnectionCerts');
      _MTEGetServInfo := GetProcAddress(H, 'MTEGetServInfo');
      _MTESoftConnect := GetProcAddress(H, 'MTESoftConnect');
      _MTELogon := GetProcAddress(H, 'MTELogon');
      _MTESelectBoards := GetProcAddress(H, 'MTESelectBoards');
      _MTEGetExtDataRange := GetProcAddress(H, 'MTEGetExtDataRange');
      _MTEErrorMsgEx := GetProcAddress(H, 'MTEErrorMsgEx');
      _MTEStructure2 := GetProcAddress(H, 'MTEStructure2');
      _MTEExecTransEx := GetProcAddress(H, 'MTEExecTransEx');
      _MTEGetTablesFromSnapshot := GetProcAddress(H, 'MTEGetTablesFromSnapshot');
      _MTEOpenTableAtSnapshot := GetProcAddress(H, 'MTEOpenTableAtSnapshot');

      if Assigned(_MTEExecTransIP) then Include(MTESrlAddons, msaExecTransIP);
      if Assigned(_MTEGetExtData) then Include(MTESrlAddons, msaGetExtData);
      if Assigned(_MTEConnectionStats) then Include(MTESrlAddons, msaConnStats);
      if Assigned(_MTEConnectionStatus) then Include(MTESrlAddons, msaConnStatus);
      if Assigned(_MTEGetVersion) then Include(MTESrlAddons, msaGetVersion);
      if Assigned(_MTEConnectionCerts) then Include(MTESrlAddons, msaConnCerts);
      if Assigned(_MTEGetServInfo) then Include(MTESrlAddons, msaGetServInfo);
      if Assigned(_MTESoftConnect) then Include(MTESrlAddons, msaSoftConnect);
      if Assigned(_MTELogon) then Include(MTESrlAddons, msaLogon);
      if Assigned(_MTESelectBoards) then Include(MTESrlAddons, msaSelectBoards);
      if Assigned(_MTEGetExtDataRange) then Include(MTESrlAddons, msaGetExtDataRange);
      if Assigned(_MTEErrorMsgEx) then Include(MTESrlAddons, msaErrorMsgEx);
      if Assigned(_MTEStructure2) then Include(MTESrlAddons, msaStructure2);
      if Assigned(_MTEExecTransEx) then Include(MTESrlAddons, msaExecTransEx);
      if Assigned(_MTEGetTablesFromSnapshot) then Include(MTESrlAddons, msaGetTablesFromSnapshot);
      if Assigned(_MTEOpenTableAtSnapshot) then Include(MTESrlAddons, msaOpenTableAtSnapshot);
    end;
  end;
end;

function MTEExecTransIP(Idx: Integer; TransName, Params: PAnsiChar; ResultMsg: PMTEErrorMsg; ClientIP: Integer): TMTEResult;
begin
  LoadMTESrl;
  if Assigned(_MTEExecTransIP) then
    Result := _MTEExecTransIP(Idx, TransName, Params, ResultMsg, ClientIp)
  else
  begin
    Result := MTE_TRANSREJECTED;
    if Assigned(ResultMsg) then
      StrLCopy(PAnsiChar(ResultMsg), PAnsiChar(AnsiString(rsNoExecTransIP)), SizeOf(TMTEErrorMsg));
  end;
end;

var
  TmpBuf: array [0..255] of AnsiChar;

function MTEGetExtData(Idx: Integer; DataSetName, ExtFileName: PAnsiChar; var Msg: PMTEMsg): TMTEResult;
begin
  LoadMTESrl;
  if Assigned(_MTEGetExtData) then
    Result := _MTEGetExtData(Idx, DataSetName, ExtFileName, Msg)
  else
  begin
    Result := MTE_TRANSREJECTED;
    if @Msg <> nil then begin
      PInteger(@TmpBuf)^ := Length(rsNoGetExtData);
      StrLCopy(PAnsiChar(@TmpBuf) + SizeOf(Integer), PAnsiChar(AnsiString(rsNoGetExtData)), SizeOf(TmpBuf) - SizeOf(Integer));
      Msg := @TmpBuf;
    end;
  end;
end;

function MTEGetExtDataRange(Idx: Integer; DataSetName, ExtFileName: PAnsiChar;
  DataOffset, DataSize: Cardinal; var Msg: PMTEMsg): TMTEResult;
begin
  LoadMTESrl;
  if Assigned(_MTEGetExtDataRange) then
    Result := _MTEGetExtDataRange(Idx, DataSetName, ExtFileName, DataOffset, DataSize, Msg)
  else
  begin
    Result := MTE_TRANSREJECTED;
    if @Msg <> nil then begin
      PInteger(@TmpBuf)^ := Length(rsNoGetExtDataR);
      StrLCopy(PAnsiChar(@TmpBuf) + SizeOf(Integer), PAnsiChar(AnsiString(rsNoGetExtDataR)), SizeOf(TmpBuf) - SizeOf(Integer));
      Msg := @TmpBuf;
    end;
  end;
end;

function MTEConnectionStats(Idx: Integer; var Stats: TMTEConnStats): TMTEResult;
begin
  LoadMTESrl;
  if Assigned(_MTEConnectionStats) then
    Result := _MTEConnectionStats(Idx, Stats)
  else
  begin
    Result := MTE_NOTIMPLEMENTED;
  end;
end;

function MTEConnectionStatus(Idx: Integer): TMTEResult;
begin
  LoadMTESrl;
  if Assigned(_MTEConnectionStatus) then
    Result := _MTEConnectionStatus(Idx)
  else
  begin
    Result := MTE_NOTIMPLEMENTED;
  end;
end;

function MTEGetVersion: PAnsiChar;
begin
  LoadMTESrl;
  if Assigned(_MTEGetVersion) then
    Result := _MTEGetVersion
  else
  begin
    Result := #0;
  end;
end;

function MTEConnectionCerts(Idx: Integer; MyCert, ServerCert: PMTEConnCertificate): TMTEResult;
begin
  LoadMTESrl;
  if Assigned(_MTEConnectionCerts) then
    Result := _MTEConnectionCerts(Idx, MyCert, ServerCert)
  else
  begin
    Result := MTE_NOTIMPLEMENTED;
  end;
end;

function MTEGetServInfo(Idx: Integer; var ServInfo: PByte; var Len: Integer): TMTEResult;
begin
  LoadMTESrl;
  if Assigned(_MTEGetServInfo) then
    Result := _MTEGetServInfo(Idx, ServInfo, Len)
  else
  begin
    Result := MTE_NOTIMPLEMENTED;
    if (@ServInfo <> nil) and (@Len <> nil) then begin
      StrLCopy(PAnsiChar(@TmpBuf), PAnsiChar(AnsiString(rsNoGetServInfo)), SizeOf(TmpBuf));
      ServInfo := @TmpBuf;
      Len := Length(rsNoGetServInfo);
    end;
  end;
end;

function MTESoftConnect(Params: PAnsiChar; ErrorMsg: PMTEErrorMsg): TMTEResult;
begin
  LoadMTESrl;
  if Assigned(_MTESoftConnect) then
    Result := _MTESoftConnect(Params, ErrorMsg)
  else
  begin
    Result := MTE_CONFIG;
    if Assigned(ErrorMsg) then
      StrLCopy(PAnsiChar(ErrorMsg), PAnsiChar(AnsiString(rsNoSoftConnect)), SizeOf(TMTEErrorMsg));
  end;
end;

function MTELogon(Idx: Integer; sync_time: Integer): TMTEResult;
begin
  LoadMTESrl;
  if Assigned(_MTELogon) then
    Result := _MTELogon(Idx, sync_time)
  else
    Result := MTE_NOTIMPLEMENTED;
end;

function MTESelectBoards(Idx: Integer; BoardList: PAnsiChar; ResultMsg: PMTEErrorMsg): TMTEResult;
begin
  LoadMTESrl;
  if Assigned(_MTESelectBoards) then
    Result := _MTESelectBoards(Idx, BoardList, ResultMsg)
  else
    Result := MTE_NOTIMPLEMENTED;
end;

function MTEErrorMsgEx(ErrCode: TMTEResult; Language: PAnsiChar): PAnsiChar;
begin
  LoadMTESrl;
  if Assigned(_MTEErrorMsgEx) then
    Result := _MTEErrorMsgEx(ErrCode, Language)
  else
    Result := MTEErrorMsg(ErrCode);
end;

function MTEStructure2(Idx: Integer; var Msg: PMTEMsg): TMTEResult;
begin
  LoadMTESrl;
  if Assigned(_MTEStructure2) then
    Result := _MTEStructure2(Idx, Msg)
  else
  begin
    Result := MTE_NOTIMPLEMENTED;
    if @Msg <> nil then begin
      PInteger(@TmpBuf)^ := Length(rsNoStructure2);
      StrLCopy(PAnsiChar(@TmpBuf) + SizeOf(Integer), PAnsiChar(AnsiString(rsNoStructure2)), SizeOf(TmpBuf) - SizeOf(Integer));
      Msg := @TmpBuf;
    end;
  end;
end;

function MTEExecTransEx(Idx: Integer; TransName, Params: PAnsiChar; ClientIp: Integer;
  var Reply: TMTEExecTransResult): TMTEResult;
begin
  LoadMTESrl;
  if Assigned(_MTEExecTransEx) then
    Result := _MTEExecTransEx(Idx, TransName, Params, ClientIp, Reply)
  else begin
    if @Reply <> nil then begin
      Reply.ReplyCount := 0;
      Reply.Replies := nil;
    end;
    Result := MTE_TRANSREJECTED;
  end;
end;

function MTEGetTablesFromSnapshot(Idx: Integer; Snapshot: PByte; Len: Integer; var SnapTables: PMTESnapTables): Integer;
begin
  LoadMTESrl;
  if Assigned(_MTEGetTablesFromSnapshot) then
    Result := _MTEGetTablesFromSnapshot(Idx, Snapshot, Len, SnapTables)
  else begin
    if @SnapTables <> nil then SnapTables := nil;
    Result := MTE_NOTIMPLEMENTED;
  end;
end;

function MTEOpenTableAtSnapshot(Idx: Integer; TableName, Params: PAnsiChar; Snapshot: PByte; SnapshotLen: Integer; var Msg: PMTEMsg): Integer;
begin
  LoadMTESrl;
  if Assigned(_MTEOpenTableAtSnapshot) then
    Result := _MTEOpenTableAtSnapshot(Idx, TableName, Params, Snapshot, SnapshotLen, Msg)
  else begin
    if @Msg <> nil then Msg := nil;
    Result := MTE_NOTIMPLEMENTED;
  end;
end;

{$endif}

function GetMTESrlAddons: TMTESrlAddOns;
begin
  {$ifndef Unix}LoadMTESrl;{$endif}
  Result := MTESrlAddons;
end;

{$endif DYNAMIC_MTEAPI}

end.

