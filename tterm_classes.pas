{$i tterm_defs.pas}

unit tterm_classes;

interface

uses  {$ifdef MSWINDOWS} windows, {$endif}
      classes, sysutils, math;

type  tStringQueue       = class(tObject)
      private
        fList            : tStringList;
        fMaxLen          : longint;
      private
        procedure   fSetMaxLen(alen: longint);
      public
        constructor create; virtual;
        destructor  destroy; override;
        function    push(const aitem: ansistring): boolean; virtual;
        function    pop(var res: boolean): ansistring; virtual;

        property    MaxLen: longint read fMaxLen write fSetMaxLen;
      end;

      tThreadStringQueue = class(tStringQueue)
      private
        fCSec       : tRtlCriticalSection;
      public
        constructor create; override;
        destructor  destroy; override;
        function    locklist: tThreadStringQueue; virtual;
        procedure   unlocklist; virtual;
        function    push(const aitem: ansistring): boolean; override;
        function    pop(var res: boolean): ansistring; override;
      end;


implementation

{ tStringQueue }

constructor tStringQueue.create;
begin
  inherited create;
  fList:= tStringList.create;
  fMaxLen:= 0;
end;

destructor tStringQueue.destroy;
begin
  if assigned(fList) then freeandnil(fList);
  inherited destroy;
end;

procedure tStringQueue.fSetMaxLen(alen: longint);
var res : boolean;
begin
  fMaxLen:= max(0, alen);
  while (fList.Count > fMaxLen) do pop(res);
end;

function tStringQueue.push(const aitem: ansistring): boolean;
var res : boolean;
begin
  fList.Add(aitem);
  if (fMaxLen > 0) then
    while (fList.Count > fMaxLen) do pop(res);
  result:= true;  
end;

function tStringQueue.pop(var res: boolean): ansistring;
begin
  res:= (fList.Count > 0);
  if res then begin
    result:= fList.strings[0];
    fList.delete(0);
  end else setlength(result, 0);
end;

{ tThreadStringQueue }

constructor tThreadStringQueue.create;
begin
  inherited create;
  {$ifdef MSWINDOWS}
  InitializeCriticalSection(fCSec);
  {$else}
  InitCriticalSection(fCSec);
  {$endif}
end;

destructor tThreadStringQueue.destroy;
begin
  {$ifdef MSWINDOWS}
  DeleteCriticalSection(fCSec);
  {$else}
  DoneCriticalSection(fCSec);
  {$endif}
  inherited destroy;
end;

function tThreadStringQueue.locklist: tThreadStringQueue;
begin
  EnterCriticalSection(fCSec);
  result:= Self;
end;

procedure tThreadStringQueue.unlocklist;
begin
  LeaveCriticalSection(fCSec);
end;

function tThreadStringQueue.push(const aitem: ansistring): boolean;
begin
  with locklist do try
    result:= inherited push(aitem);
  finally unlocklist; end;
end;

function tThreadStringQueue.pop(var res: boolean): ansistring;
begin
  with locklist do try
    result:= inherited pop(res);
  finally unlocklist; end;
end;

end.