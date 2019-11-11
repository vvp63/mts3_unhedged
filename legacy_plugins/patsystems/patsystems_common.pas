{$i patsystems_defs.pas}

unit patsystems_common;

interface

uses  windows, classes, sysutils, math, 
      servertypes, serverapi,
      PATSINTF;

      
const patsplugname        = 'patsystems';

const patsid              = 7;
const patsstockname       = 'PATSYSTEMS';

const log_template        = 'PATSYSTEMS: %s';

const stockcount          = 1;

type  tPatsStockLst       = array[0..stockcount - 1] of tStockRec;

const stocklst            : tPatsStockLst = ((stock_id   : patsid;
                                              stock_name : patsstockname));

const intraday            : longint = 0;

const pluginfilename      : string = '.\patsystems.dll';
      pluginfilepath      : string = '.\';
      pluginininame       : string = '.\patsystems.ini';

const section_system      = 'system';
      section_connection  = 'connection';

const is_demo             : boolean = false;

var   Server_API          : tServerAPI;

function  GetPatsStockID: longint;

function  check_fail(aparam: longint; const amsg: string = ''): longint;

function  decodedatetime(const adate: Array8; const atime: Array6): tDateTime;
function  decodefillid(const afillid: FillIDStr): int64;

function  AdjustFilePath(const afilename, adesiredpath: string): string;

procedure Log (const event: string); overload;
procedure Log (const event: string; const params: array of const); overload;

function  GetModuleName(Module: HMODULE): string;

procedure DecodeCommaText(const Value: string; result: tStringList; adelimiter: char);

implementation

function GetPatsStockID: longint;
begin result:= stocklst[0].stock_id; end;

function check_fail(aparam: longint; const amsg: string = ''): longint;
begin
  result:= aparam;
  if (result <> ptSuccess) then log('error (%d): %s', [aparam, amsg]);
end;

function decodedatetime(const adate: Array8; const atime: Array6): tDateTime;
var a,b,c : longint;
    tmp   : ansistring;
begin
  SetString(tmp, pAnsiChar(@adate), 4); a:= StrToIntDef(tmp, 1900);
  SetString(tmp, pAnsiChar(@adate[4]), 2); b:= StrToIntDef(tmp, 1);
  SetString(tmp, pAnsiChar(@adate[6]), 2); c:= StrToIntDef(tmp, 1);
  result:= EncodeDate(a, b, c);

  SetString(tmp, pAnsiChar(@atime), 2); a:= StrToIntDef(tmp, 0);
  SetString(tmp, pAnsiChar(@atime[2]), 2); b:= StrToIntDef(tmp, 0);
  SetString(tmp, pAnsiChar(@atime[4]), 2); c:= StrToIntDef(tmp, 0);
  result:= result + EncodeTime(a, b, c, 0);
end;

function decodefillid(const afillid: FillIDStr): int64;
var i, j : longint;
    tmp  : ansistring;
begin
  j:= 0;
  setlength(tmp, sizeof(afillid));
  for i:= 0 to sizeof(afillid) - 1 do
    if (afillid[i] in ['0'..'9']) then begin
      inc(j); tmp[j]:= afillid[i];
    end;
  setlength(tmp, j);
  result:= StrToInt64Def(copy(tmp, max(0, length(tmp) - 14) + 1, 14), 0);
end;

function AdjustFilePath(const afilename, adesiredpath: string): string;
begin
  if length(extractfilepath(afilename)) = 0 then begin
    result:= adesiredpath + extractfilename(afilename);
  end else result:= afilename;
end;

procedure Log (const event: string);
begin if assigned(Server_API.LogEvent) then Server_API.LogEvent(pChar(format(log_template, [event]))); end;

procedure Log (const event: string; const params: array of const);
begin Log(format(event, params)); end;

function GetModuleName(Module: HMODULE): string;
var ModName: array[0..MAX_PATH] of char;
begin SetString(Result, ModName, GetModuleFileName(Module, ModName, SizeOf(ModName))); end;

procedure DecodeCommaText(const Value: string; result: tStringList; adelimiter: char);
var P, P1 : PChar;
    S     : string;
  function filter(const astr, pattern: string): string;
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
      P := PChar(Value);
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