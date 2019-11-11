{$i terminal_defs.pas}

unit  terminal_client_obj;

interface

uses  {$ifdef MSWINDOWS}
        windows, inifiles,
      {$else}
        fclinifiles,
      {$endif}
      classes, sysutils,
      sortedlist,
      servertypes, protodef, 
      tterm_api, 
      terminal_commonutils;

type  tEnumTableRows    = function(atable_id: longint; abuf: pAnsiChar; abufsize: longint; aparams: pAnsiChar; aparamsize: longint): longint of object;
      
type  tSecFlags         = class(tSortedThreadList)
      private
        procedure   fSetSecFlags(const asecid: tSecIdent; aflag: longint; avalue: boolean);
        function    fGetSecFlags(const asecid: tSecIdent; aflag: longint): boolean;
        procedure   fSetSecLastTrade(const asecid: tSecIdent; alasttrade: int64);
        function    fGetSecLastTrade(const asecid: tSecIdent): int64;
      public
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        function    checkbykothdr(const akothdr: tKotUpdateHdr): boolean; virtual;
        function    checkbyalltrade(const aalltrd: tAllTrades): boolean; virtual;

        property    secflags[const asecid: tSecIdent; aflag: longint]: boolean read fGetSecFlags write fSetSecFlags;
        property    seclasttrade[const asecid: tSecIdent]: int64 read fGetSecLastTrade write fSetSecLastTrade;
      end;

type  tAccountList        = class(tSortedThreadList)
        constructor create;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        procedure   initializeaccountlist(aini: tIniFile; const aaccounts: ansistring);
        procedure   enumerate(acallback: tEnumTableRows);
        function    exists(const aaccount: tAccount): boolean;
      end;

type  tChangedAccountList = class(tSortedThreadList)
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        procedure   addaccount(const aaccount: tAccount);
      end;

implementation

{ tSecFlags }

procedure tSecFlags.freeitem(item: pointer);
begin if assigned(item) then dispose(pSecFlagsItm(item)); end;

function tSecFlags.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tSecFlags.compare(item1, item2: pointer): longint;
begin
  result:= pSecFlagsItm(item1)^.secid.stock_id - pSecFlagsItm(item2)^.secid.stock_id;
  if (result = 0) then begin
    result:= CompareText(pSecFlagsItm(item1)^.secid.level, pSecFlagsItm(item2)^.secid.level);
    if (result = 0) then result:= CompareText(pSecFlagsItm(item1)^.secid.code, pSecFlagsItm(item2)^.secid.code);
  end;
end;

function tSecFlags.fGetSecFlags(const asecid: tSecIdent; aflag: longint): boolean;
var itm    : tSecFlagsItm;
    idx    : longint;
begin
  locklist;
  try
    itm.secid:= asecid;
    result:= search(@itm, idx);
    if result then result:=((pSecFlagsItm(items[idx])^.flags and aflag) > 0);
  finally unlocklist; end;
end;

procedure tSecFlags.fSetSecFlags(const asecid: tSecIdent; aflag: longint; avalue: boolean);
var itm    : tSecFlagsItm;
    idx    : longint;
    newitm : pSecFlagsItm;
begin
  locklist;
  try
    itm.secid:= asecid;
    if not search(@itm, idx) then begin
      if avalue then begin
        newitm:= new(pSecFlagsItm);
        with newitm^ do begin secid:= asecid; flags:= aflag; lasttradeno:= 0; end;
        insert(idx, newitm);
      end;
    end else begin
      with pSecFlagsItm(items[idx])^ do begin
        if avalue then flags:= flags or aflag else flags:= flags and (not aflag);
        if (flags = 0) then delete(idx);
      end;
    end;
  finally unlocklist; end;
end;

function tSecFlags.checkbykothdr(const akothdr: tKotUpdateHdr): boolean;
var secid : tSecIdent;
begin
  with secid do begin stock_id:= aKotHdr.stock_id; level:= aKotHdr.level; code:= aKotHdr.code; end;
  result:= secflags[secid, sfSendKot];
end;

function tSecFlags.fGetSecLastTrade(const asecid: tSecIdent): int64;
begin result:= 0; end;

procedure tSecFlags.fSetSecLastTrade(const asecid: tSecIdent; alasttrade: int64);
begin end;

function tSecFlags.checkbyalltrade(const aalltrd: tAllTrades): boolean;
begin result:= false; end;

{ tAccountList }

constructor tAccountList.create;
begin
  inherited create;
  fduplicates:= dupReplace;
end;

procedure tAccountList.freeitem(item: pointer);
begin if assigned(item) then dispose(pAccountListItm(item)); end;

function tAccountList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tAccountList.compare(item1, item2: pointer): longint;
begin result:= CompareText(pAccountListItm(item1)^.account, pAccountListItm(item2)^.account); end;

procedure tAccountList.initializeaccountlist(aini: tIniFile; const aaccounts: ansistring);
var sl     : tStringList;
    i      : longint;
    itm    : pAccountListItm;
    tmpstr : ansistring;
begin
  if assigned(aini) then begin
    sl:= tStringList.create;
    locklist;
    try
      DecodeCommaText(aaccounts, sl, ';');
      for i:= 0 to sl.count - 1 do begin
        tmpstr:= format('account:%s', [sl[i]]);
        itm:= new(pAccountListItm);
        itm^.stock_id := aini.readinteger(tmpstr, 'stockid',     0);
        itm^.account  := aini.readstring (tmpstr, 'account',     sl[i]);
        itm^.flags    := aini.readinteger(tmpstr, 'flags',       0);
        fillchar(itm^.margininfo, sizeof(itm^.margininfo), 0);
        itm^.descr    := aini.readstring (tmpstr, 'description', '');
        add(itm);
      end;
    finally
      unlocklist; 
      sl.free;
    end;
  end;  
end;

procedure tAccountList.enumerate(acallback: tEnumTableRows);
var i : longint;
begin
  if assigned(acallback) then begin
    locklist;
    try
      for i:= 0 to count - 1 do
        if (acallback(idAccountList, items[i], sizeof(tAccountListItm), nil, 0) <> PLUGIN_OK) then break;
    finally unlocklist; end;
  end;
end;

function tAccountList.exists(const aaccount: tAccount): boolean;
var sitm : tAccountListItm;
    idx  : longint;
begin
  locklist;
  try
    sitm.account:= aaccount;
    result:= search(@sitm, idx);
  finally unlocklist; end;
end;

{ tChangedAccountList }

procedure tChangedAccountList.freeitem(item: pointer);
begin if assigned(item) then dispose(pAccount(item)); end;

function tChangedAccountList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tChangedAccountList.compare(item1, item2: pointer): longint;
begin result:= AnsiCompareText(pAccount(item1)^, pAccount(item2)^); end;

procedure tChangedAccountList.addaccount(const aaccount: tAccount);
var itm : pAccount;
    idx : longint;
begin
  locklist;
  try
    if not search(@aaccount, idx) then begin
      itm:= new(pAccount);
      itm^:= aaccount;
      insert(idx, itm);
    end;
  finally unlocklist; end;
end;

end.