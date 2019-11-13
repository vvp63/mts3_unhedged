{$I micexdefs.pas}

unit micexglobal;

interface

uses  Windows, SysUtils, Math, 
      LowLevel, {UnixTime, }SortedList,
      ServerAPI, ServerTypes,
      micexsubst;

const micexId            = 1;
const micexplugname      = 'micex';
const micexStockName     = 'ллба';

{$ifdef UseSecList}
type  pSecListItm        = ^tSecListItm;
      tSecListItm        = record
        level            : tLevel;
        code             : tCode;
        lotsize          : longint;
        decimals         : longint;
      end;

type  tSecList           = class(tSortedThreadList)
        constructor create;
        procedure   freeitem(item:pointer); override;
        function    checkitem(item:pointer):boolean; override;
        function    compare(item1,item2:pointer):longint; override;
        function    add(alevel:tLevel; acode:tCode):pSecListItm; reintroduce; virtual;
        function    getitem(var aitem:tSecListItm):boolean; virtual;
        function    getlotsize(alevel:tLevel; acode:tCode):longint; virtual;
      end;
{$endif}

const cfgname            : pChar         = 'micex.ini';
      enablestats        : boolean       = false;

      synchronizetime    : boolean       = false;
      synchourdelta      : longint       = 0;

      keepalive          : boolean       = true;
      keepalivetimeout   : longint       = 10000;

      subst_cid          : tSubstList    = nil;
      subst_acc          : tSubstList    = nil;

      brokerrefs         : tFilterList   = nil;

      orderbooktable     : string        = 'ORDERBOOK';

const defaultdelay       : longint       = 50;
                                         
{$ifdef UseSecList}                      
const seclist            : tSecList      = nil;
{$endif}                                 

{$ifdef UseSetOrderFlag}
const setorderflag       : boolean       = false;
{$endif}

var   Server_API         : tServerAPI;

const pluginpath         : string        = '';

procedure MicexLog(const event: string); overload;
procedure MicexLog(const event: string; const params: array of const); overload;

procedure MicexSynchronizeTime(amicextime: tDateTime);

function ExtractDivider(const alevel: tLevel; const acode: tCode): cardinal; overload;
function ExtractDivider(const alevel: tLevel; const acode: tCode; var alotsize: cardinal): cardinal; overload;

function GetModuleName(Module: HMODULE): string;

implementation

{ tSecList }

{$ifdef UseSecList}
constructor tSecList.create;
begin inherited create; fDuplicates:= dupIgnore; end;

procedure tSecList.freeitem;
begin if assigned(item) then dispose(pSecListItm(item)); end;

function tSecList.checkitem;
begin result:= true; end;

function tSecList.compare;
begin
  result:= CompareText(pSecListItm(item1)^.level, pSecListItm(item2).level);
  if result = 0 then result:= CompareText(pSecListItm(item1)^.code, pSecListItm(item2).code);
end;

function tSecList.add;
var idx  : longint;
    sitm : tSecListItm;
begin
  locklist;
  try
    sitm.level:= alevel; sitm.code:= acode;
    if not search(@sitm, idx) then begin
      result:= new(pSecListItm); fillchar(result^, sizeof(tSecListItm), 0);
      with result^ do begin level:= alevel; code:= acode; end;
      insert(idx, result);
    end else result:= items[idx];
  finally unlocklist; end;
end;

function tSecList.getitem;
var idx : longint;
begin
  locklist;
  try
    result:= search(@aitem, idx); if result then aitem:= pSecListItm(items[idx])^;
  finally unlocklist; end;
end;

function tSecList.getlotsize;
var idx : longint;
    itm : tSecListItm;
begin
 locklist;
 try
   itm.level:= alevel; itm.code:= acode;
   if search(@itm, idx) then result:= max(pSecListItm(items[idx])^.lotsize, 1) else result:= 1;
 finally unlocklist; end;
end;
{$endif}

{ common functions }

procedure MicexLog(const event: string);
begin if assigned(Server_API.LogEvent) then Server_API.LogEvent(pChar(format('MICEX: %s',[event]))); end;

procedure MicexLog(const event: string; const params: array of const);
begin if assigned(Server_API.LogEvent) then Server_API.LogEvent(pChar(format('MICEX: ' + event, params))); end;


procedure MicexSynchronizeTime(amicextime: tDateTime);
var systime : TSystemTime;
begin
  amicextime:= amicextime + (synchourdelta / 24);
  DateTimeToSystemTime(amicextime, systime);
  SetLocalTime(systime);
end;


function ExtractDivider(const alevel: tLevel; const acode: tCode): cardinal;
var asec : tSecurities;
begin
  with asec do begin stock_id:= micexId; level:= alevel; code:= acode; end;
  try
    if assigned(Server_API.GetSecuritiesRec) and
       Server_API.GetSecuritiesRec(asec,[sec_stock_id,sec_level,sec_code]) then result:= max(strtoint(asec.srv_field), 1)
                                                                           else result:= 1;
  except on e:exception do result:= 1; end;
end;

function ExtractDivider(const alevel: tLevel; const acode: tCode; var alotsize: cardinal): cardinal;
var asec : tSecurities;
begin
  with asec do begin stock_id:= micexId; level:= alevel; code:= acode; end;
  try
    if assigned(Server_API.GetSecuritiesRec) and
       Server_API.GetSecuritiesRec(asec,[sec_stock_id,sec_level,sec_code]) then begin
      result:= max(strtoint(asec.srv_field), 1); alotsize:= max(asec.lotsize, 1);
    end else begin
      result:= 1; alotsize:= 1;
    end;
  except on e:exception do begin result:= 1; alotsize:= 1; end; end;
end;

function GetModuleName(Module: HMODULE): string;
var ModName: array[0..MAX_PATH] of char;
begin SetString(Result, ModName, GetModuleFileName(Module, ModName, SizeOf(ModName))); end;

initialization
{$ifdef UseSecList}
  seclist:= tSecList.create;
{$endif}

finalization
{$ifdef UseSecList}
  if assigned(seclist) then freeandnil(seclist);
{$endif}
  if assigned(subst_cid) then freeandnil(subst_cid);
  if assigned(subst_acc) then freeandnil(subst_acc);
  if assigned(brokerrefs) then freeandnil(brokerrefs);

end.