{$i forts_defs.pas}

unit forts_directory;

interface

uses  {$ifdef MSWINDOWS}
        windows, 
      {$endif}
      sysutils, math,
      sortedlist, syncobj, //unixtime,
      servertypes, serverapi,
      forts_common;

type  pSessionListItm  = ^tSessionListItm;
      tSessionListItm  = record
        recrev         : int64;
        sess_id        : longint;
        state          : longint;
        clstate        : longint;
      end;

type  tSessionList     = class(tSortedThreadList)
      private
        function    fGetState(asess_id: longint): longint;
        function    fGetClState(asess_id: longint): longint;
      public
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;

        procedure   addsession(const arev: int64; asess_id, astate, aclstate: longint);

        procedure   clearbyrev(const arev: int64);

        procedure   Cleanup;

        property    state[asess_id: longint]: longint read fGetState;
        property    clstate[asess_id: longint]: longint read fGetClState;
      end;

type  pIsinListItem    = ^tIsinListItem;
      tIsinListItem    = record
        isin_id        : longint;
        lsz            : longint;
//        is_limited     : boolean;
        signs          : longint;
        level          : tLevel;
        code           : tCode;
      end;

type  tIsinList        = class(tSortedThreadList)
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;

        function    SearchAddItem(aisin_id: longint): pIsinListItem;

        procedure   Cleanup;
      end;

      tLocalIsinList   = class(tSortedList)
      private
        function    fGetItem(aisin_id: longint): pIsinListItem;
        function    fGetCode(aindex: longint): tCode;
      public
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;

        procedure   load(asource: tIsinList);

        property    isin[asisn_id: longint]: pIsinListItem read fGetItem;
        property    codes[aindex: longint]: tCode read fGetCode;
      end;

      tLocalIsinByCode = class(tLocalIsinList)
      private
        function    fGetItem(const acode: tCode): pIsinListItem;
      public
        function    compare(item1, item2: pointer): longint; override;

        property    isin[const acode: tCode]: pIsinListItem read fGetItem;
      end;

const isin_list        : tIsinList         = nil;
      session_list     : tSessionList      = nil;

procedure DirectoryCleanUp;

implementation

{ tSessionList }

procedure tSessionList.freeitem(item: pointer);
begin if assigned(item) then dispose(pSessionListItm(item)); end;

function tSessionList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tSessionList.compare(item1, item2: pointer): longint;
begin result:= pSessionListItm(item1)^.sess_id - pSessionListItm(item2)^.sess_id; end;

procedure tSessionList.clearbyrev(const arev: int64);
var i : longint;
begin for i:= count - 1 downto 0 do if (pSessionListItm(items[i])^.recrev < arev) then delete(i); end;

procedure tSessionList.Cleanup;
begin
  locklist;
  try
    clear;
  finally unlocklist; end;
end;

procedure tSessionList.addsession(const arev: int64; asess_id, astate, aclstate: longint);
var sitm : tSessionListItm;
    idx  : longint;
    itm  : pSessionListItm;
begin
  sitm.sess_id:= asess_id;
  locklist;
  try
    if search(@sitm, idx) then begin
      with pSessionListItm(items[idx])^ do begin
        recrev:= arev; state:= astate; clstate:= aclstate;
      end;
    end else begin
      itm:= new(pSessionListItm);
      with itm^ do begin
        recrev:= arev; sess_id:= asess_id; state:= astate; clstate:= aclstate;
      end;
      insert(idx, itm);
    end;
  finally unlocklist; end;
end;

function tSessionList.fGetState(asess_id: longint): longint;
var sitm : tSessionListItm;
    idx  : longint;
begin
  result:= -1;
  sitm.sess_id:= asess_id;
  locklist;
  try
    if search(@sitm, idx) then result:= pSessionListItm(items[idx])^.state;
  finally unlocklist; end;
end;

function tSessionList.fGetClState(asess_id: Integer): longint;
var sitm : tSessionListItm;
    idx  : longint;
begin
  result:= -1;
  sitm.sess_id:= asess_id;
  locklist;
  try
    if search(@sitm, idx) then result:= pSessionListItm(items[idx])^.clstate;
  finally unlocklist; end;
end;

{ tIsinList }

procedure tIsinList.freeitem(item: pointer);
begin if assigned(item) then dispose(pIsinListItem(item)); end;

function tIsinList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tIsinList.compare(item1, item2: pointer): longint;
begin result:= pIsinListItem(item1)^.isin_id - pIsinListItem(item2)^.isin_id; end;

procedure tIsinList.Cleanup;
begin
  locklist;
  try
    clear;
  finally unlocklist; end;
end;

function tIsinList.SearchAddItem(aisin_id: longint): pIsinListItem;
var sitm : tIsinListItem;
    idx  : longint;
begin
  sitm.isin_id:= aisin_id;
  locklist;
  try
    if not search(@sitm, idx) then begin
      result:= new(pIsinListItem);
      fillchar(result^, sizeof(tIsinListItem), 0);
      result^.isin_id:= aisin_id;
      insert(idx, result);
    end else result:= pIsinListItem(items[idx]);
  finally unlocklist; end;
end;

{ common functions }

procedure DirectoryCleanUp;
var kot   : tKotirovki;
begin
  // cleanup isin list
  if assigned(isin_list) then isin_list.Cleanup;

  // cleanup server kotirovki table
  kot.stock_id:= GetFortsStockID;
  if assigned(Server_API.LockKotirovki) then Server_API.LockKotirovki;
  try if assigned(Server_API.ClearKotirovkiTbl) then Server_API.ClearKotirovkiTbl(kot, clrByStockid);
  finally if assigned(Server_API.UnlockKotirovki) then Server_API.UnlockKotirovki; end;

  // cleanup session list
  if assigned(session_list) then session_list.Cleanup;
end;

{ tLocalIsinList }

procedure tLocalIsinList.freeitem(item: pointer);
begin if assigned(item) then dispose(pIsinListItem(item)); end;

function tLocalIsinList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tLocalIsinList.compare(item1, item2: pointer): longint;
begin result:= pIsinListItem(item1)^.isin_id - pIsinListItem(item2)^.isin_id; end;

function tLocalIsinList.fGetItem(aisin_id: longint): pIsinListItem;
var sitm : tIsinListItem;
    idx  : longint;
begin
  sitm.isin_id:= aisin_id;
  if search(@sitm, idx) then result:= pIsinListItem(items[idx]) else result:= nil;
end;

function tLocalIsinList.fGetCode(aindex: Integer): tCode;
begin result:= pIsinListItem(items[aindex])^.code; end;

procedure tLocalIsinList.load(asource: tIsinList);
var i   : longint;
    itm : pIsinListItem;
begin
  clear;
  if assigned(asource) then with asource do begin
    locklist;
    try
      for i:= 0 to count - 1 do begin
        itm:= new(pIsinListItem);
        itm^:= pIsinListItem(items[i])^;
        self.add(itm);
      end;
    finally unlocklist; end;
  end;
end;

{ tLocalIsinByCode }

function tLocalIsinByCode.compare(item1, item2: pointer): longint;
begin result:= AnsiCompareText(pIsinListItem(item1)^.code, pIsinListItem(item2)^.code); end;

function tLocalIsinByCode.fGetItem(const acode: tCode): pIsinListItem;
var sitm : tIsinListItem;
    idx  : longint;
begin
  sitm.code:= acode;
  if search(@sitm, idx) then result:= pIsinListItem(items[idx]) else result:= nil;
end;

initialization
  isin_list:= tIsinList.create;
  session_list:= tSessionList.create;

finalization
  if assigned(isin_list) then freeandnil(isin_list);
  if assigned(session_list) then freeandnil(session_list);

end.