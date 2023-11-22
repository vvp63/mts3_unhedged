{$M+}

unit mts3lx_common;


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
      fclinifiles,
      filedump,
      postgres,
      serverapi,
      servertypes,
      tterm_api,
      tterm_commandparser,
      mts3lx_start,
      mts3lx_logger
      ;


const {$ifdef MSWINDOWS}
      ExeFileName          : ansistring = 'mts3lx.dll';
      {$else}
      ExeFileName          : ansistring = 'libmts3lx.so';
      {$endif}
      ExeFilePath          : ansistring = '.';

const 
      gIniFileName  : string      = 'mts3lx.ini';
      gIniFile      : TIniFile    = nil;
      gPGConn       : PPGConn     = nil;

const
      gLogFileTempl : string      = 'mts3lx_%s.log';
      gLogFileName  : string      = 'mts3lx_.log';
      gLogLevel     : longint     = 2;

const
      SecInDay                  : longint       = 86400;
      SecDelay                  : real          = 1.15740740e-5;
      ClientMessagesDelay       : real          = 1;
      ReloadApproveCode         : longint       = -1;
      QuoteSaveDelay            : longint       = 10;

const

      MTSStockLevel             : tLevel        = 'MTS2';       // идентификатор   (в сервера старый, поэтому MTS2)
      MTSStockID :  longint       = 128;

const
      QuoteLogLength            : longint       = 5;

const
      PDReloadKfCommand         : longint       = 0;

const
  DefaultToId               : string        = '';

var
  DefaultToUser             : array of string;      



const
  gGlobalOrderStatus        : boolean       = false;
  gGlobalHedgeStatus        : boolean       = false;
  gUseHedgePD               : boolean       = true;
  GlobalTradeSessionStarted : boolean       = false;        // торгова€ сесси€ сервера открыта

const
  GlobalConnected           : boolean       = false;

const
  LastCommandTime           : tDateTime      = 0;            //  ѕоследнее врем€ проверки сообщений
  CommandCheckInterval      : longint       = 3;





procedure log(const alogstr: string);   overload;
procedure log(const alogstr: string; const aparams  : array of const);  overload;

procedure msglog (atoid, atouser: string; str: string; const params: array of const); overload;
procedure msglog (str: string; const params: array of const); overload;

procedure MTSOutputStockAll(const aparamname, aparamcode: string;
                            adir, ainv, adirs, ainvs, adirft, ainvft: real; acode : char; ropttime : TDateTime);

procedure FileLog(aStr : string; aParam  : array of const; aLogLevel : longint); overload;
procedure FileLog(aStr : string; aLogLevel : longint); overload;
procedure FileLog(aStr : string); overload;
function QueryResult(const aRes : string) : tStringList;
function PrepareDateFromTS(const aDt  : string)  : string;
function PGQueryMy(aStr : string)  : PPGresult;  overload;
function PGQueryMy(aStr : string; aParam  : array of const; aLog  : boolean = false)  : PPGresult;  overload;


function Min(const a, b : longint)  : longint; overload;
function Min(const a, b : real)  : real; overload;

function Max(const a, b : longint)  : longint; overload;
function Max(const a, b : real)  : real; overload;


implementation



procedure log(const alogstr: string);  overload;
begin
  if assigned(logproc) then logproc(pAnsiChar(format(plugname + ': %s', [alogstr])));
  FileLog('[T] ' + alogstr);
end;


procedure log(const alogstr: string; const aparams  : array of const);  overload;
begin log(format(alogstr, aparams)); end;


procedure msglog (atoid, atouser: string; str: string; const params: array of const); overload;
var i : longint;
begin
  if (length(atoid) = 0) then atoid:= DefaultToId;
  if length(atoid) <> 0 then
    if (length(atouser) = 0) then begin
      for i:= low(DefaultToUser) to high(DefaultToUser) do
        if (length(DefaultToUser[i]) <> 0) and assigned(server_api) and assigned(server_api^.SendUserMessage) then
          server_api^.SendUserMessage(pchar(atoid), pchar(DefaultToUser[i]), pchar(format(str, params)));
    end else begin
      if assigned(server_api) and assigned(server_api^.SendUserMessage) then
        server_api^.SendUserMessage(pchar(atoid), pchar(atouser), pchar(format(str, params)));
    end;
    Log(str, params);
end;

procedure msglog (str: string; const params: array of const); overload;
begin msglog('', '', str, params); end;



procedure MTSOutputStockAll(const aparamname, aparamcode: string;
                            adir, ainv, adirs, ainvs, adirft, ainvft: real; acode : char; ropttime : TDateTime);
var sec : tSecurities;
begin
  if GlobalConnected and assigned(server_api) and assigned(server_api^.AddSecuritiesRec) then begin
    fillchar(sec, sizeof(sec), 0);
    with sec do begin
      stock_id      :=  MTSStockID;
      level         :=  MTSStockLevel;
      code          :=  aparamcode;
      shortname     :=  aparamname;
      hibid         :=  adir;
      lowoffer      :=  ainv;
      initprice     :=  adirs;
      meanprice     :=  ainvs;
      prev_price    :=  adirft;
      lastdealprice :=  ainvft;
      tradingstatus :=  acode;
      lastdealtime  :=  ropttime;
    end;
    server_api^.AddSecuritiesRec(sec, [sec_stock_id, sec_level, sec_code, sec_shortname, sec_hibid, sec_lowoffer, sec_initprice,
                                       sec_meanprice, sec_tradingstatus, sec_lastdealtime, sec_prev_price, sec_lastdealprice]);

  end;
end;



procedure FileLog(aStr : string; aParam  : array of const; aLogLevel : longint);
var vStr  : string;
    i     : longint;
begin
  vStr:= ''; for i:= 1 to aLogLevel do vStr:= vStr + '  ';
  if (aLogLevel <= gLogLevel) then begin
    LogFileWrite(Format(vStr + aStr, aParam));//advanceddumpbuf(gLogFileTempl, Format(aStr, aParam), nil, 0);
  end;
end;

procedure FileLog(aStr : string; aLogLevel : longint); overload;
begin FileLog(aStr, [], aLogLevel); end;

procedure FileLog(aStr : string); overload;
begin FileLog(aStr, 0); end;


function PGQueryMy(aStr : string)  : PPGresult;  overload;
begin if (PQstatus(gPGConn) = CONNECTION_OK) then result:=  PQexec(gPGConn, PChar(aStr)) else result:=  nil; end;


function PGQueryMy(aStr : string; aParam  : array of const; aLog  : boolean = false)  : PPGresult;  overload;
var vStr  : string;
begin
  vStr  := format(aStr, aParam);
  if (aLog) then FileLog('PGQueryMy:    %s', [vStr], 1);
  result:= PGQueryMy(vStr);
end;



function QueryResult(const aRes : string) : tStringList;
var vStr  : string;
    vp : longint;
    fl    : boolean;
begin
  result    :=  tStringList.Create;
  vStr      :=  aRes;
  if (vStr[1] = '(') then vStr:=  copy(vStr, 2, length(vStr) - 1);
  if (vStr[length(vStr)] = ')') then vStr:=  copy(vStr, 1, length(vStr) - 1);
  fl:=  false;
  while not fl do begin
    vp:=  pos(',', vStr);
    if (vp > 0) then begin
      result.Add(copy(vStr, 1, vp - 1));
      vStr:=  Copy(vStr, vp + 1, length(vStr) - vp);
    end else begin
      fl:= true;
      result.Add(vStr);
    end;
  end;
end;

function PrepareDateFromTS(const aDt  : string)  : string;
begin
  result:=  '';
  if (length(aDT) > 12) then
    result  :=  copy(aDt, 9, 2) + '-' + copy(aDt, 9, 2)
end;


function Min(const a, b : longint)  : longint; overload;
begin if a < b then result:= a else result:= b; end;

function Min(const a, b : real)  : real; overload;
begin if a < b then result:= a else result:= b; end;

function Max(const a, b : longint)  : longint; overload;
begin if a > b then result:= a else result:= b; end;

function Max(const a, b : real)  : real; overload;
begin if a > b then result:= a else result:= b; end;


end.
