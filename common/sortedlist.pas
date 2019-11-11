{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit sortedlist;

interface

uses  {$ifdef MSWINDOWS} windows, {$endif}
      classes, sysutils;

type  tDuplicates       = (dupAccept, dupIgnore, dupReplace);

type  tCustomList       = class(tList)
       procedure   clear; override;
       procedure   freeitem(item:pointer); virtual; abstract;
       procedure   freeall; virtual;
       procedure   delete(index:longint); virtual;
       procedure   remove(item:pointer); virtual;
       function    extract(item:pointer):pointer; virtual;
      end;

type  tCustomThreadList = class(tCustomList)
       CSect            : TRTLCriticalSection;
       constructor create;
       destructor  destroy; override;
       function    locklist:tCustomThreadList; virtual;
       procedure   unlocklist; virtual;
      end;

type  tSortedList       = class(tCustomList)
       fDuplicates      : tDuplicates;
       constructor create;
       function    checkitem(item:pointer):boolean; virtual; abstract;
       function    compare(item1,item2:pointer):longint; virtual; abstract;
       function    search(item:pointer; var index:longint):boolean; virtual;
       procedure   add(item:pointer); virtual;
       procedure   insert(index:longint; item:pointer); virtual;
      end;

type  tSortedThreadList = class(tSortedList)
       CSect            : tRTLCriticalSection;
       constructor create;
       destructor  destroy; override;
       function    locklist:tSortedThreadList; virtual;
       procedure   unlocklist; virtual;
      end;

type  pIdentifiedString  = ^tIdentifiedString;
      tIdentifiedString  = record
       StringId          : longint;
       StringText        : string;
      end;

type  tIdentStringList   = class (tSortedList)
      protected
       function    GetString(index:longint):string; virtual;
       function    GetIndex(const astr: string): longint;
      public
       constructor create;
       procedure   freeitem(item:pointer); override;
       function    checkitem(item:pointer):boolean; override;
       function    compare(item1,item2:pointer):longint; override;
       procedure   add(aid:longint; const atext:string); reintroduce; virtual;
       procedure   loadfromresource(root: longint); virtual;

       property    strings[index:longint]:string read GetString; default;
       property    indexes[const astr: string]: longint read GetIndex;
      end;

implementation

procedure tCustomList.clear;
var i : longint;
begin for i:=0 to count-1 do freeitem(items[i]); inherited clear; end;

procedure tCustomList.freeall;
begin clear; end;

procedure tCustomList.delete;
begin freeitem(items[index]); inherited delete(index); end;

procedure tCustomList.remove;
begin freeitem(item); inherited remove(item); end;

function tCustomList.extract;
var i : longint;
begin
 i:=indexof(item);
 if i>=0 then begin
  result:=item;
  inherited delete(i);
  notify(result, lnExtracted);
 end else result:=nil;
end;

//--------------------------------------------------------------------

constructor tCustomThreadList.create;
begin
 inherited create;
 {$ifdef MSWINDOWS}
 InitializeCriticalSection(CSect);
 {$else}
 InitCriticalSection(CSect);
 {$endif}
end;

destructor tCustomThreadList.destroy;
begin
 {$ifdef MSWINDOWS}
 DeleteCriticalSection(CSect);
 {$else}
 DoneCriticalSection(CSect);
 {$endif}
 inherited destroy;
end;

function tCustomThreadList.locklist;
begin
 EnterCriticalSection(CSect);
 result:=self;
end;

procedure tCustomThreadList.unlocklist;
begin
 LeaveCriticalSection(CSect);
end;

//--------------------------------------------------------------------

constructor tSortedList.create;
begin
 inherited create;
 fduplicates:=dupAccept;
end;

function tSortedList.search;
var l,h,i,c : longint;
begin
 result:=false;
 l:=0;
 h:=count-1;
 while l<=h do begin
   i:=(l+h) shr 1;
   c:=compare(items[i],item);
   if c<0 then l:=i+1
   else begin
     h:=i-1;
     if c=0 then begin
       result:=true;
       if (fDuplicates=dupIgnore) or (fDuplicates=dupReplace) then l:=i;
     end;// if
   end; // if
 end;// while
 index:=l;
end;

procedure tSortedList.add;
var index : longint;
begin
 if checkitem(item) then begin
  if search(item,index) then begin
   case fDuplicates of
    dupAccept  : insert(index, item);
    dupIgnore  : freeitem(item);
    dupReplace : begin freeitem(items[index]); items[index]:=item; end;
   end;
  end else insert(index, item);
 end else freeitem(item);
end;

procedure tSortedList.insert;
begin
 if checkitem(item) then inherited insert(index, item);
end;

//--------------------------------------------------------------------

constructor tSortedThreadList.create;
begin
 inherited create;
 {$ifdef MSWINDOWS}
 InitializeCriticalSection(CSect);
 {$else}
 InitCriticalSection(CSect);
 {$endif}
end;

destructor tSortedThreadList.destroy;
begin
 {$ifdef MSWINDOWS}
 DeleteCriticalSection(CSect);
 {$else}
 DoneCriticalSection(CSect);
 {$endif}
 inherited destroy;
end;

function tSortedThreadList.locklist;
begin
 EnterCriticalSection(CSect);
 result:=self;
end;

procedure tSortedThreadList.unlocklist;
begin
 LeaveCriticalSection(CSect);
end;

//--------------------------------------------------------------------

constructor tIdentStringList.create;
begin inherited create; fDuplicates:= dupIgnore; end;

procedure tIdentStringList.freeitem(item: pointer);
begin if assigned(item) then dispose(pIdentifiedString(item)); end;

function tIdentStringList.checkitem(item: pointer): boolean;
begin result:= true; end;

function tIdentStringList.compare(item1, item2: pointer): longint;
begin result:= pIdentifiedString(item1)^.StringId - pIdentifiedString(item2)^.StringId; end;

function tIdentStringList.GetString(index: Integer): string;
var itm : tIdentifiedString;
    idx : longint;
begin
 itm.StringId:= index;
 if search(@itm, idx) then result:= pIdentifiedString(items[idx])^.StringText
                      else setlength(result, 0);
end;

function tIdentStringList.GetIndex(const astr: string): longint;
var i : longint;
begin
  result:= -1;
  i:= 0;
  while (i < count) do with pIdentifiedString(items[i])^ do
    if (AnsiCompareText(StringText, astr) = 0) then begin
      result:= StringId;
      i:= count;
    end else inc(i);
end;

procedure tIdentStringList.add(aid: Integer; const atext: string);
var itm : pIdentifiedString;
    idx : longint;
begin
 itm:= new(pIdentifiedString);
 itm^.StringId:= aid;
 if not search(itm, idx) then begin itm^.StringText:= atext; insert(idx, itm); end
                         else dispose(itm);
end;

procedure tIdentStringList.loadfromresource(root: longint);
begin end;

end.
