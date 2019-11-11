{$i forts_defs.pas}

unit forts_common;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$else}
        unix, linux, 
      {$endif}
      classes, sysutils,
      servertypes, serverapi;
      
const fortsplugname       = 'forts';

const fortsid             = 4;
const fortsstockname      = 'ФОРТС';

const level_futures       = 'FUTU';
      level_index         = 'RTSI';

const stockcount          = 1;

type  tFortsStockLst      = array[0..stockcount - 1] of tStockRec;

const stocklst            : tFortsStockLst = ((stock_id   : fortsid;
                                               stock_name : fortsstockname));

const intraday            : longint    = 0;

      reconnect_tries     : longint    = 3;
      reconnect_timeout   : longint    = 1000;

      log_stream_state    : boolean    = false;

      use_account_groups  : boolean    = false;

const fortsbrokercode     : ansistring = '';

const pluginfilename      : ansistring = '.\forts.dll';
      pluginfilepath      : ansistring = '.\';
      pluginininame       : ansistring = '.\forts.ini';

      gatewayinifilename  : ansistring = 'P2ClientGate.ini';
      gatewaytblchema     : ansistring = 'forts_scheme.ini';
      gatewaymsgschema    : ansistring = 'forts_scheme_messages.ini';

      cgate_env_params    : ansistring = '';

const flag_InDopSession   = $00000001; // 1 - инструмент торгуется в доп. сессии (вечером и/или утром), 0 - нет (возможно, только в основную).
      flag_Marging        = $00000002; // 1 - Маржируемый, 0 - с уплатой премии.
      flag_Spot           = $00000004; // 1 - спот,0 - нет.
      flag_MainSpot       = $00000008; // 1 - главный спот, 0 - нет.
      flag_Anonymous      = $00000010; // 1 - торгуется анонимно, 0 - нет. (Анонимно - т.е. допускаются обычные заявки)
      flag_NoAnonimous    = $00000020; // 1 - торгуется Неанонимно, 0 - нет.(Неанонимно - т.е. только внесистемные заявки)
      flag_InMainSession  = $00000040; // 1 - Торгуется в основную сессию, 0 - нет

var   Server_API          : tServerAPI;

function  GetFortsStockID: longint;
function  fortssign(asign: longint; aflag: longint): boolean;
function  CommentToTrsNo(const acomment: ansistring): longint;
function  ClientCodeToAccount(const alevel: tLevel; const aclientcode: ansistring): ansistring;

function  AdjustFilePath(const afilename, adesiredpath: ansistring): ansistring;

procedure Log (const event: ansistring); overload;
procedure Log (const event: ansistring; const params: array of const); overload;

{$ifdef MSWINDOWS}
function  GetModuleName(Module: HMODULE): ansistring;
{$endif}
function  GetMksCount: int64;
function  GetCPUClock: int64;

function  _StrToFloatDef(const str: ansistring; Default: extended): extended;
function  _StrToDateTime(const str: ansistring): tDateTime;

procedure DecodeCommaText(const Value: ansistring; result: tStringList; adelimiter: ansichar);
procedure DecodePCharCommaText(Value: pAnsiChar; result: tStringList; adelimiter: AnsiChar);

implementation

function GetFortsStockID: longint;
begin result:= stocklst[0].stock_id; end;

function fortssign(asign: longint; aflag: longint): boolean;
begin result:= (asign and aflag <> 0); end;

function  CommentToTrsNo (const acomment: ansistring): longint;
begin
 try if (length(acomment) > 0) then result:= strtointdef(acomment, -1) else result:=-1;
 except on e:exception do result:=-1; end;
end;

function  ClientCodeToAccount(const alevel: tLevel; const aclientcode: ansistring): ansistring;
{$ifndef use_full_client_code_in_account}
var cod : ansistring;
{$endif}
begin
  {$ifdef use_full_client_code_in_account}
  result:= format('%s%s', [alevel, aclientcode]);
  {$else}
  cod:= copy(aclientcode, 5, 3);             
  if (length(cod) = 0) then cod:= '000';
  result:= format('%s%s', [alevel, cod]);
  {$endif}
end;


function AdjustFilePath(const afilename, adesiredpath: ansistring): ansistring;
begin
  if length(extractfilepath(afilename)) = 0 then begin
    result:= adesiredpath + extractfilename(afilename);
  end else result:= afilename;
end;

procedure Log (const event: ansistring);
begin if assigned(Server_API.LogEvent) then Server_API.LogEvent(pAnsiChar(format('FORTS: %s',[event]))); end;

procedure Log (const event: ansistring; const params: array of const);
begin Log(format(event, params)); end;

{$ifdef MSWINDOWS}
function GetModuleName(Module: HMODULE): ansistring;
var ModName: array[0..MAX_PATH] of char;
begin SetString(Result, ModName, GetModuleFileName(Module, ModName, SizeOf(ModName))); end;
{$endif}

function GetMksCount: int64;
{$ifndef MSWINDOWS}
var t : timeval;
{$endif}
begin
{$ifdef MSWINDOWS}
  result := int64(GetTickCount) * 1000;
{$else}
  fpgettimeofday(@t, nil);
  result := (int64(t.tv_sec) * 1000000) + t.tv_usec;
{$endif}
end;

function GetCPUClock: int64;
{$ifndef MSWINDOWS}
var t : timeval;
{$endif}
begin
{$ifdef MSWINDOWS}
  QueryPerformanceCounter(result);
{$else}
  fpgettimeofday(@t, nil);
  result := (int64(t.tv_sec) * 1000000) + t.tv_usec;
{$endif}
end;

function _StrToFloatDef(const str: ansistring; Default: extended): extended;
begin if not TextToFloat(pAnsiChar(str), Result, fvExtended) then Result:= Default; end;

function _StrToDateTime(const str: ansistring): tDateTime;
var y, m, d, h, n, s : word;
begin
  y:= strtointdef(copy(str, 1, 4), 0);
  m:= strtointdef(copy(str, 6, 2), 0);
  d:= strtointdef(copy(str, 9, 2), 0);
  h:= strtointdef(copy(str, 12, 2), 0);
  n:= strtointdef(copy(str, 15, 2), 0);
  s:= strtointdef(copy(str, 18, 2), 0);
  result:= EncodeDate(y, m, d) + EncodeTime(h, n, s, 0);
end;

{$ifndef MSWINDOWS}
function CharNext(apc: pAnsiChar): pAnsiChar;
begin
  result:= apc;
  if assigned(result) and (result^ <> #0) then inc(result);
end;
{$endif}

procedure DecodeCommaText(const Value: ansistring; result: tStringList; adelimiter: AnsiChar);
begin DecodePCharCommaText(PAnsiChar(Value), result, adelimiter); end;

procedure DecodePCharCommaText(Value: pAnsiChar; result: tStringList; adelimiter: AnsiChar);
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
      P := Value;
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

end.