{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit  micexsubst;

interface

uses  {$ifdef MSWINDOWS}
        windows, inifiles,
      {$else}
        fclinifiles,
      {$endif}
      classes, sysutils, 
      sortedlist;

type  pSubstPair = ^tSubstPair;
      tSubstPair = record
        sour     : ansistring;
        dest     : ansistring;
      end;

type  tSubstList  = class(tSortedThreadList)
      private
        function    fGetSubst(const asour: ansistring): ansistring;
        procedure   fSetSubst(const asour, adest: ansistring);
      public
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;

        procedure   load(aini: tIniFile; const asection: ansistring);

        property    subst[const asour: ansistring]: ansistring read fGetSubst write fSetSubst;
      end;

      tFilterList = class(tStringList)
      private
        CSect     : TRTLCriticalSection;
        fMaxLen   : longint;
      public
        constructor create;
        destructor  destroy; override;

        function    locklist: tFilterList; virtual;
        procedure   unlocklist; virtual;

        procedure   load(aini: tIniFile; const asection: ansistring; amaxlen: longint);
        function    exists(const avalue: ansistring): boolean;
      end;

implementation

{ tSubstList }

procedure tSubstList.freeitem(item: pointer);
begin if assigned(item) then dispose(pSubstPair(item)); end;

function tSubstList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tSubstList.compare(item1, item2: pointer): longint;
begin result:= AnsiCompareText(pSubstPair(item1)^.sour, pSubstPair(item2)^.sour); end;

function tSubstList.fGetSubst(const asour: ansistring): ansistring;
var sitm : tSubstPair;
    idx  : longint;
begin
  if (count > 0) then begin
    sitm.sour:= asour;
    locklist;
    try
      if search(@sitm, idx) then result:= pSubstPair(items[idx])^.dest else result:= asour;
    finally unlocklist; end;
  end else result:= asour;
end;

procedure tSubstList.fSetSubst(const asour, adest: ansistring);
var sitm : tSubstPair;
    itm  : pSubstPair;
    idx  : longint;
begin
  sitm.sour:= asour;
  locklist;
  try
    if not search(@sitm, idx) then begin
      itm:= new(pSubstPair);
      itm^.sour:= asour;
      itm^.dest:= adest;
      insert(idx, itm);
    end else pSubstPair(items[idx])^.dest:= adest;
  finally unlocklist; end;
end;

procedure tSubstList.load(aini: tIniFile; const asection: ansistring);
var sl  : tStringList;
    i   : longint;
    key : ansistring;
begin
  locklist;
  try clear;
  finally unlocklist; end;
  if assigned(aini) then begin
    sl:= tStringList.Create;
    try
      aini.ReadSection(asection, sl);
      for i:= 0 to sl.Count - 1 do begin
        key:= sl[i];
        subst[key]:= aini.ReadString(asection, key, '');
      end;
    finally sl.free; end;
  end;
end;

{ tFilterList }

constructor tFilterList.create;
begin
  inherited create;
  fMaxLen:= 0;
  sorted:= true;
  duplicates:= classes.dupIgnore;
  {$ifdef MSWINDOWS}
  InitializeCriticalSection(CSect);
  {$else}
  InitCriticalSection(CSect);
  {$endif}
end;

destructor tFilterList.destroy;
begin
  {$ifdef MSWINDOWS}
  DeleteCriticalSection(CSect);
  {$else}
  DoneCriticalSection(CSect);
  {$endif}
  inherited destroy;
end;

function tFilterList.locklist: tFilterList;
begin
  EnterCriticalSection(CSect);
  result:= Self;
end;

procedure tFilterList.unlocklist;
begin
  LeaveCriticalSection(CSect);
end;

procedure tFilterList.load(aini: tIniFile; const asection: ansistring; amaxlen: longint);
var sl  : tStringList;
    i   : longint;
    key : ansistring;
begin
  fmaxlen:= amaxlen;
  locklist;
  try
    clear;
    if assigned(aini) then begin
      sl:= tStringList.Create;
      try
        aini.ReadSection(asection, sl);
        for i:= 0 to sl.Count - 1 do begin
          key:= sl[i];
          add(copy(aini.ReadString(asection, key, ''), 1, fmaxlen));
        end;
      finally sl.free; end;
    end;
  finally unlocklist; end;
end;

function tFilterList.exists(const avalue: ansistring): boolean;
var idx : longint;
begin
  locklist;
  try
    result:= find(copy(avalue, 1, fmaxLen), idx);
  finally unlocklist; end;  
end;


end.