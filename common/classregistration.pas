{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit classregistration;

interface

uses  {$ifdef MSWINDOWS} windows, {$endif}
      sysutils,
      sortedlist;

type  tObjectClass        = class of TObject;

type  pObjectClassListItm = ^tObjectClassListItm;
      tObjectClassListItm = record
        classvar          : tObjectClass;
        classalias        : ansistring;
      end;

      tObjectClassList    = class(tSortedThreadList)
        procedure freeitem(item: pointer); override;
        function  checkitem(item: pointer): boolean; override;
        function  compare(item1, item2: pointer): longint; override;
      end;

function  register_class(const aclassvar: tObjectClass; const aclassalias: ansistring): boolean; overload;
function  register_class(const aclassvar: tObjectClass): boolean; overload;
procedure register_class(const aclassvararray: array of tObjectClass); overload;
procedure register_class(const aclassvar: tObjectClass; const aclassaliases: array of ansistring); overload;

function  get_class(const aclassalias: ansistring): tObjectClass;

procedure unregister_class(const aclassvar: tObjectClass);

implementation

const class_list : tObjectClassList = nil;

{ tObjectClassList }

procedure tObjectClassList.freeitem(item: pointer);
begin if assigned(item) then dispose(pObjectClassListItm(item)); end;

function tObjectClassList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tObjectClassList.compare(item1, item2: pointer): longint;
begin result:= ansicomparetext(pObjectClassListItm(item1)^.classalias, pObjectClassListItm(item2)^.classalias); end;

{ procedures and functions }

function  register_class(const aclassvar: tObjectClass; const aclassalias: string): boolean;
var sitm : tObjectClassListItm;
    idx  : longint;
    itm  : pObjectClassListItm;
begin
  result:= false;
  sitm.classvar:= nil;
  if assigned(class_list) and assigned(aclassvar) then begin
    if (length(aclassalias) <> 0) then sitm.classalias:= aclassalias else sitm.classalias:= aclassvar.ClassName;
    with class_list.locklist do try
      if not search(@sitm, idx) then begin
        itm:= new(pObjectClassListItm);
        itm^.classvar:= aclassvar;
        itm^.classalias:= sitm.classalias;
        insert(idx, itm);
        result:= true;
      end;
    finally class_list.unlocklist; end;
  end;
end;

function  register_class(const aclassvar: tObjectClass): boolean;
begin result:= assigned(aclassvar) and register_class(aclassvar, aclassvar.ClassName); end;

procedure register_class(const aclassvararray: array of tObjectClass);
var i : longint;
begin
  if (length(aclassvararray) > 0) then
    for i:= low(aclassvararray) to high(aclassvararray) do register_class(aclassvararray[i]);
end;

procedure register_class(const aclassvar: tObjectClass; const aclassaliases: array of ansistring);
var i : longint;
begin
  if assigned(aclassvar) then begin
    if length(aclassaliases) > 0 then begin
      for i:= low(aclassaliases) to high(aclassaliases) do register_class(aclassvar, aclassaliases[i]);
    end else register_class(aclassvar);
  end
end;

function  get_class(const aclassalias: ansistring): tObjectClass;
var sitm : tObjectClassListItm;
    idx  : longint;
begin
  result:= nil;
  if assigned(class_list) then
    with class_list.locklist do try
      sitm.classvar:= nil; sitm.classalias:= aclassalias;
      if search(@sitm, idx) then result:= pObjectClassListItm(items[idx])^.classvar;
    finally class_list.unlocklist; end;
end;

procedure unregister_class(const aclassvar: tObjectClass);
var i : longint;
begin
  if assigned(class_list) then
    with class_list.locklist do try
      for i:= count - 1 downto 0 do
        if (pObjectClassListItm(items[i])^.classvar = aclassvar) then delete(i);
    finally class_list.unlocklist; end;
end;

initialization
  class_list:= tObjectClassList.create;

finalization
  if assigned(class_list) then freeandnil(class_list);

end.