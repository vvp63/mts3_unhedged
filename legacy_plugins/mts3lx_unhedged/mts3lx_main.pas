{$M+}

unit mts3lx_main;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$else}
        cmem,
        cthreads,
      {$endif}
      dynlibs,
      sysutils,
      classes,
      strings,
      fclinifiles,
      postgres,
      mts3lx_start,
      mts3lx_common,
      mts3lx_sheldue,
      mts3lx_securities,
      mts3lx_tp,
      mts3lx_queue,
      mts3lx_otmanager
      ;



function  MTS3_Init: longint; stdcall;
function  MTS3_DBConnect: longint; stdcall;
function  MTS3_DBDisconnect: longint; stdcall;
function  MTS3_Done: longint; stdcall;
function  MTS_ReloadMTS: longint; stdcall;


implementation


function  MTS3_Init: longint; stdcall;
begin

  DateSeparator := '-';
  ShortDateFormat := 'YYYY-MM-DD';
  LongTimeFormat := 'hh:nn:ss.zzz';

  log('MTS3_Init  : Initialization. Loading ' + gIniFileName);
  // Ini-file initialization
  gIniFile :=  TIniFile.Create(gIniFileName);

  MTS3_DBConnect;   //  Здесь же чтение инишника
  InitScheldue;
  InitMTSSec;
  InitMTSTP;
  InitOTManager;
  InitMTSQueue;

  FileLog('MTS3 Ini OK', 1);

  result:= 0;
end;


function  MTS3_Done: longint; stdcall;
begin
    DoneMTSQueue;
    DoneOTManager;
    DoneMTSTP;
    DoneMTSSec;
    DoneScheldue;
    MTS3_DBDisconnect;
    result:= 0;
end;


function  MTS_ReloadMTS: longint; stdcall;
begin
  FileLog('MTS3 Reload started', 1);
  DoneMTSQueue;
  DoneOTManager;
  DoneMTSTP;
  DoneMTSSec;
  DoneScheldue;
  InitScheldue;
  InitMTSSec;
  InitMTSTP;
  InitOTManager;
  InitMTSQueue;
  result:= 0;
end;


//  DB functions

function  MTS3_DBConnect: longint; stdcall;
var //vParamValue : string;
    pghost,pgport,pgoptions,pgtty,dbname,login,pwd : Pchar;
    vUserCount, i  : longint;
begin

  pghost := NiL;
  pgport := NiL;
  pgoptions := NiL;
  pgtty := NiL;
  dbName := NiL;
  login :=  NiL;
  pwd   :=  NiL;

  if assigned(gIniFile) then with gIniFile do begin
    pghost  :=  PChar(ReadString('db', 'host', ''));
    pgport  :=  PChar(ReadString('db', 'port', ''));
    dbName  :=  PChar(ReadString('db', 'dbname', ''));
    login   :=  PChar(ReadString('db', 'login', ''));
    pwd     :=  PChar(ReadString('db', 'pwd', ''));
    gLogLevel :=  StrToIntDef(ReadString('settings', 'loglevel', ''), 2);

    vUserCount        :=  StrToIntDef(ReadString('clientmessage', 'usercount', ''), 0);
    DefaultToId       :=  PChar(ReadString('clientmessage', 'clientid', ''));
    SetLength(DefaultToUser, vUserCount);
    for i:=low(DefaultToUser) to high(DefaultToUser) do
      DefaultToUser[i] :=  PChar(ReadString('clientmessage', format('clientuser%d', [i + 1]), ''));

  end;

  log('MTS3_DBConnect  : LogLevel = %d', [gLogLevel]);
  log('MTS3_DBConnect  : Try to connect to %s on %s:%s', [dbName, pghost, pgport]);
  gPGConn :=  PQsetdbLogin(pghost,pgport,pgoptions,pgtty,dbName,login,pwd);
  if (PQstatus(gPGConn) = CONNECTION_BAD) then log('MTS3_DBConnect  : No connection')
  else log('MTS3_DBConnect  : Connected');

  result:= 0;

end;


function  MTS3_DBDisconnect: longint; stdcall;
begin
  if assigned(gPGConn) then PQfinish(gPGConn);
  log('MTS3_DBDisconnect  : disonnected');
  result:= 0;
end;






end.
