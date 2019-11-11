{__$define auto_create_ini}
{$J+}

unit gateobjects;

interface

{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

uses
      {$ifdef FPC}
        {$ifdef MSWINDOWS}windows,{$endif}
      {$else}windows,{$endif}
      {$ifdef auto_create_ini}classes,{$endif} sysutils,
      cgate;

type  tProcessStage    = (psProcess, psOpen, psOpening, psClose);

type  tSingleton = class
      protected
        class function _RefCount: plongint; virtual;
        class function _Ref: pointer; virtual;
        procedure AfterSingletonCreate; virtual;
        procedure BeforeSingletonDestroy; virtual;
      public
        class function NewInstance: TObject; override;
        procedure FreeInstance; override;
        class function RefCount: longint;
      end;

type  tCGateEnv        = class(tSingleton)
      private
      protected
        class function _RefCount: plongint; override;
        class function _Ref: pointer; override;
        procedure AfterSingletonCreate; override;
        procedure BeforeSingletonDestroy; override;
        function  GetEnvironmentSettings: ansistring; virtual;
      end;

      tCGateEnvClass   = class of tCGateEnv;

      tCGateObject     = class(tObject)
      private
        FEnvironment   : tCGateEnv;
        FHandle        : THandle;
        FParams        : ansistring;
      protected
        function    getstate: longint; virtual;
        function    getprotocol: ansistring; virtual;
      public
        constructor create(const aparams: ansistring); reintroduce; virtual;
        destructor  destroy; override;

        property    handle: THandle read FHandle;
        property    params: ansistring read FParams;
        property    state: longint read getstate;
        property    protocol: ansistring read getprotocol;
      end;

      tCGateConnection = class(tCGateObject)
      private
        FOpened        : boolean;
        FOpenParams    : ansistring;
      protected
        function    getstate: longint; override;
        function    createhandle: longint; virtual;
        function    freehandle: longint; virtual;
        function    processmessage(atimeout: longint): longint; virtual;
      public
        constructor create(const aparams: ansistring); override;
        destructor  destroy; override;
        function    open(const aopenparams: ansistring): longint; virtual;
        function    close: longint; virtual;
        function    process(atimeout: longint; var stage: tProcessStage): longint; virtual;

        property    openparams: ansistring read FOpenParams write FOpenParams;
        property    opened: boolean read FOpened;
      end;

      tCGateCustom = class(tCGateConnection)
      private
        FOwner         : tCGateObject;
      protected
        function    processmessage(atimeout: longint): longint; override;
      public
        constructor create(AOwner: tCGateConnection; const aparams: ansistring); reintroduce; virtual;
        function    process(atimeout: longint; var stage: tProcessStage): longint; override;
        function    getscheme: pcg_scheme_desc; virtual;
        procedure   idle; virtual;

        function    dumpmessage(amsg: pointer): ansistring;

        property    owner: tCGateObject read FOwner;
      end;

      tCGateListener = class(tCGateCustom)
      protected
        function    getstate: longint; override;
        function    createhandle: longint; override;
        function    freehandle: longint; override;
      public
        function    getscheme: pcg_scheme_desc; override;
        function    open(const aopenparams: ansistring): longint; override;
        function    close: longint; override;
      end;

      tCGatePublisher = class(tCGateCustom)
      protected
        function    getstate: longint; override;
        function    createhandle: longint; override;
        function    freehandle: longint; override;
      public
        function    getscheme: pcg_scheme_desc; override;
        function    open(const aopenparams: ansistring): longint; override;
        function    close: longint; override;
        function    msg_new(id_type: longint; id: pointer): pcg_msg;
        function    msg_free(amsgptr: pcg_msg): longint;
        function    msg_post(amsgptr: pcg_msg; aflags: longint): longint;
      end;

const EnvironmentSettings      : ansistring = 'ini=application.ini;subsystems=mq,replclient';
      EnvironmentSettingsClass : tCGateEnvClass = tCGateEnv;

function cg_log_debug(const fmt: string; const args: array of const): longint;
function cg_log_info(const fmt: string; const args: array of const): longint;
function cg_log_error(const fmt: string; const args: array of const): longint;

implementation

var   SCSect : TRTLCriticalSection;

function cg_log_debug(const fmt: string; const args: array of const): longint;
begin result:= cg_log_debugstr(PAnsiChar(ansistring(format(fmt, args)))); end;

function cg_log_info(const fmt: string; const args: array of const): longint;
begin result:= cg_log_infostr(PAnsiChar(ansistring(format(fmt, args)))); end;

function cg_log_error(const fmt: string; const args: array of const): longint;
begin result:= cg_log_errorstr(PAnsiChar(ansistring(format(fmt, args)))); end;

{$ifdef auto_create_ini}
procedure DecodeCommaText(const value: ansistring; result: tStringList; adelimiter: ansichar);
var P, P1 : PAnsiChar;
    S     : ansistring;
  function filter(const astr, pattern: ansistring): ansistring;
  var i, j : longint;
  begin
    setlength(result, length(astr));
    j:= 0;
    for i:= 1 to length(astr) do
      if (pos(astr[i], pattern) = 0) then begin
        inc(j); result[j]:= astr[i];
      end;
    setlength(result, j);
  end;
begin
  if assigned(result) then begin
    result.BeginUpdate;
    try
      result.Clear;
      P := PAnsiChar(Value);
      while P^ in [#1..#31] do P := CharNext(P);
      while P^ <> #0 do
      begin
        if P^ = '"' then
          S := AnsiExtractQuotedStr(P, '"')
        else
        begin
          P1 := P;
          while (P^ >= ' ') and (P^ <> adelimiter) do P := CharNext(P);
          SetString(S, P1, P - P1);
        end;
        result.Add(filter(S, '"'));
        while P^ in [#1..#31] do P := CharNext(P);
        if P^ = adelimiter then
          repeat
            P := CharNext(P);
          until not (P^ in [#1..#31]);
      end;
    finally
      result.EndUpdate;
    end;
  end;
end;
{$endif}

function MessageCallback(hconn: THandle; hlistener: THandle; msg: pcg_msg; data: pointer): longint; cdecl;
begin
  if assigned(data) then tObject(data).Dispatch(msg^);
  result:= CG_ERR_OK;
end;

{ tSingleton }

class function tSingleton.NewInstance: TObject;
begin
  EnterCriticalSection(SCSect);
  try
    if not Assigned(pointer(_Ref^)) then begin
      pointer(_Ref^):= inherited NewInstance;
      tSingleton(_Ref^).AfterSingletonCreate;
    end;
    Result:= tObject(_Ref^);
    Inc(_RefCount^);
  finally LeaveCriticalSection(SCSect); end;
end;

procedure tSingleton.FreeInstance;
begin
  EnterCriticalSection(SCSect);
  try
    Dec(_RefCount^);
    if (_RefCount^ = 0 ) then begin
      tSingleton(_Ref^).BeforeSingletonDestroy;
      pointer(_Ref^):= nil;
      inherited FreeInstance;
    end;
  finally LeaveCriticalSection(SCSect); end;
end;

class function tSingleton._RefCount: plongint;
const ref_count: longint = 0;
begin result:= @ref_count; end;

class function tSingleton._Ref: pointer;
const ref: pointer = nil;
begin result:= @ref; end;

class function tSingleton.RefCount: longint;
begin result:= _RefCount^; end;

procedure tSingleton.AfterSingletonCreate;
begin end;

procedure tSingleton.BeforeSingletonDestroy;
begin end;

{ tCGateEnv }

class function tCGateEnv._Ref: pointer;
const ref: pointer = nil;
begin result:= @ref; end;

class function tCGateEnv._RefCount: plongint;
const ref_count: longint = 0;
begin result:= @ref_count; end;

procedure tCGateEnv.AfterSingletonCreate;
{$ifdef auto_create_ini}
var sl      : tStringList;
    ininame : ansistring;
{$endif}    
begin
  {$ifdef auto_create_ini}
  sl:= tStringList.Create;
  try
    DecodeCommaText(EnvironmentSettings, sl, ';');
    ininame:= sl.Values['ini'];
    if (length(ininame) > 0) then
      CloseHandle(CreateFile(PAnsiChar(ininame),
                             GENERIC_READ or GENERIC_WRITE,
                             FILE_SHARE_READ,
                             nil,
                             OPEN_ALWAYS,
                             FILE_ATTRIBUTE_NORMAL,
                             0));
  finally sl.free; end;
  {$endif}
  cg_env_open(pAnsiChar(GetEnvironmentSettings));
end;

procedure tCGateEnv.BeforeSingletonDestroy;
begin cg_env_close; end;

function tCGateEnv.GetEnvironmentSettings: ansistring;
begin result:= EnvironmentSettings; end;

{ tCGateObject }

constructor tCGateObject.create(const aparams: ansistring);
begin
  inherited create;
  FEnvironment:= tCGateEnv(EnvironmentSettingsClass.NewInstance);
  FEnvironment.Create;
  FParams:= aparams;
end;

destructor tCGateObject.destroy;
begin
  if assigned(FEnvironment) then freeandnil(FEnvironment);
  inherited destroy;
end;

function tCGateObject.getstate: longint;
begin result:= -1; end;

function tCGateObject.getprotocol: ansistring;
var i : longint;
begin
  i:= pos('://', FParams);
  if (i > 0) then result:= copy(FParams, 1, i - 1) else setlength(result, 0);
end;

{ tCGateConnection }

constructor tCGateConnection.create(const aparams: ansistring);
begin
  inherited create(aparams);
  FOpened:= false;
  createhandle;
end;

destructor tCGateConnection.destroy;
begin
  Close;
  freehandle;
  inherited destroy;
end;

function tCGateConnection.open(const aopenparams: ansistring): longint;
begin
  FOpenParams:= aopenparams;
  if (FHandle <> 0) and not FOpened then begin
    result:= cg_conn_open(FHandle, pAnsiChar(aopenparams));
    FOpened:= (result = CG_ERR_OK);
  end else result:= CG_ERR_INTERNAL;
end;

function tCGateConnection.close: longint;
begin
  if (FHandle <> 0) and FOpened then begin
    result:= cg_conn_close(FHandle);
    FOpened:= false;
  end else result:= CG_ERR_INTERNAL;
end;

function tCGateConnection.getstate: longint;
begin if (FHandle <> 0) then cg_conn_getstate(FHandle, result) else result:= -1; end;

function tCGateConnection.process(atimeout: longint; var stage: tProcessStage): longint;
begin
  stage:= psProcess;
  case state of
    CG_STATE_ERROR   : begin
                         stage:= psClose;
                         result:= close;
                       end;
    CG_STATE_CLOSED  : begin
                         stage:= psOpen;
                         result:= open(FOpenParams);
                       end;
    CG_STATE_ACTIVE  : result:= processmessage(aTimeOut);
    CG_STATE_OPENING : begin
                         stage:= psOpening;
                         result:= processmessage(aTimeOut);
                       end;
    else               result:= CG_ERR_INTERNAL;
  end;
end;

function tCGateConnection.createhandle: longint;
begin if (FHandle = 0) then result:= cg_conn_new(pAnsiChar(params), FHandle) else result:= CG_ERR_INTERNAL; end;

function tCGateConnection.freehandle: longint;
begin
  if (FHandle <> 0) then begin
    result:= cg_conn_destroy(FHandle);
    FHandle:= 0;
  end else result:= CG_ERR_INTERNAL;
end;

function tCGateConnection.processmessage(atimeout: longint): longint;
begin
  if (FHandle <> 0) then result:= cg_conn_process(FHandle, aTimeOut, nil)
                    else result:= CG_ERR_INTERNAL;
end;

{ tCGateCustom }

constructor tCGateCustom.create(AOwner: tCGateConnection; const aparams: ansistring);
begin
  FOwner:= AOwner;
  inherited create(aparams);
end;

function tCGateCustom.process(atimeout: longint; var stage: tProcessStage): longint;
begin
  result:= inherited process(atimeout, stage);
  if (result = CG_ERR_OK) then Idle;
end;

function tCGateCustom.processmessage(atimeout: Integer): longint;
begin result:= CG_ERR_OK; end;

function tCGateCustom.getscheme: pcg_scheme_desc;
begin result:= nil; end;

procedure tCGateCustom.idle;
begin end;

function tCGateCustom.dumpmessage(amsg: pointer): ansistring;
var len: size_t;
begin
  cg_msg_dump(amsg, getscheme, nil, len);
  setlength(result, len - 1);
  cg_msg_dump(amsg, getscheme, @result[1], len);
end;

{ tCGateListener }

function tCGateListener.getscheme: pcg_scheme_desc;
begin
  result:= nil;
  if (FHandle <> 0) then cg_lsn_getscheme(FHandle, result);
end;

function tCGateListener.open(const aopenparams: ansistring): longint;
begin
  FOpenParams:= aopenparams;
  if (FHandle <> 0) and not FOpened then begin
    result:= cg_lsn_open(FHandle, pAnsiChar(aopenparams));
    FOpened:= (result = CG_ERR_OK);
  end else result:= CG_ERR_INTERNAL;
end;

function tCGateListener.close: longint;
begin
  if (FHandle <> 0) and FOpened then begin
    result:= cg_lsn_close(FHandle);
    FOpened:= false;
  end else result:= CG_ERR_INTERNAL;
end;

function tCGateListener.getstate: longint;
begin if (FHandle <> 0) then cg_lsn_getstate(FHandle, result) else result:= -1; end;

function tCGateListener.createhandle: longint;
begin
  if assigned(FOwner) and (FHandle = 0) then begin
    result:= cg_lsn_new(FOwner.FHandle, pAnsiChar(params), @MessageCallback, Self, FHandle);
  end else result:= CG_ERR_INTERNAL;
end;

function tCGateListener.freehandle: longint;
begin
  if (FHandle <> 0) then begin
    result:= cg_lsn_destroy(FHandle);
    FHandle:= 0;
  end else result:= CG_ERR_INTERNAL;
end;

{ tCGatePublisher }

function tCGatePublisher.getscheme: pcg_scheme_desc;
begin
  result:= nil;
  if (FHandle <> 0) then cg_pub_getscheme(FHandle, result);
end;

function tCGatePublisher.open(const aopenparams: ansistring): longint;
begin
  FOpenParams:= aopenparams;
  if (FHandle <> 0) and not FOpened then begin
    result:= cg_pub_open(FHandle, pAnsiChar(aopenparams));
    FOpened:= (result = CG_ERR_OK);
  end else result:= CG_ERR_INTERNAL;
end;

function tCGatePublisher.close: longint;
begin
  if (FHandle <> 0) and FOpened then begin
    result:= cg_pub_close(FHandle);
    FOpened:= false;
  end else result:= CG_ERR_INTERNAL;
end;

function tCGatePublisher.getstate: longint;
begin if (FHandle <> 0) then cg_pub_getstate(FHandle, result) else result:= -1; end;

function tCGatePublisher.createhandle;
begin
  if assigned(FOwner) and (FHandle = 0) then begin
    result:= cg_pub_new(FOwner.FHandle, pAnsiChar(params), FHandle);
  end else result:= CG_ERR_INTERNAL;
end;

function tCGatePublisher.freehandle: longint;
begin
  if (FHandle <> 0) then begin
    result:= cg_pub_destroy(FHandle);
    FHandle:= 0;
  end else result:= CG_ERR_INTERNAL;
end;

function tCGatePublisher.msg_new(id_type: longint; id: pointer): pcg_msg;
begin
  if (FHandle <> 0) then begin
    if (cg_pub_msgnew(FHandle, id_type, id, result) <> CG_ERR_OK) then result:= nil;
  end else result:= nil;
end;

function tCGatePublisher.msg_free(amsgptr: pcg_msg): longint;
begin
  if (FHandle <> 0) then begin
    result:= cg_pub_msgfree(FHandle, amsgptr);
  end else result:= CG_ERR_INTERNAL;
end;

function tCGatePublisher.msg_post(amsgptr: pcg_msg; aflags: longint): longint;
begin
  if (FHandle <> 0) then begin
    result:= cg_pub_post(FHandle, amsgptr, aflags);
  end else result:= CG_ERR_INTERNAL;
end;

initialization
  {$ifdef MSWINDOWS}
  InitializeCriticalSection(SCSect);
  {$else}
  InitCriticalSection(SCSect);
  {$endif}

finalization
  {$ifdef MSWINDOWS}
  DeleteCriticalSection(SCSect);
  {$else}
  DoneCriticalSection(SCSect);
  {$endif}

end.
