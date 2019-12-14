{$i tterm_defs.pas}

unit tterm_commandparser;

interface

uses  {$ifdef MSWINDOWS}
        windows, messages,
      {$endif}
      sysutils;

type  tCommandMethod         = function: boolean of object;

type  tCommandInterfaceClass = class of tCommandInterface;

      tCommandInterface      = class(tObject)
      private
        fcmd                 : ansistring;
        idx                  : longint;
        fquit                : boolean;
        fmethodname          : ansistring;
      protected
        function    GetNextChar: ansichar;
        procedure   SkipSpaces;
        function    GetNextWord: ansistring;
        function    RestLine: ansistring;
        function    CheckEoln: boolean;
      public
        constructor create; virtual;
        procedure   processmessagequeue;
        function    processcommand(const acommand: ansistring): boolean; virtual;
        procedure   syntaxerror; virtual;
        property    command: ansistring read fcmd;
      end;

const commandinterface : tCommandInterface = nil;

procedure initcommandinterface(ACommandInterfaceClass: tCommandInterfaceClass);

procedure processmessagehandler; stdcall;

implementation

{ tCommandInterface }

constructor tCommandInterface.create;
begin
  inherited create;
end;

function tCommandInterface.CheckEoln: boolean;
begin SkipSpaces; result:= fquit; end;

function tCommandInterface.GetNextChar: ansichar;
begin
  result:= #0;
  if (idx <= length(fcmd)) then begin
    result:= fcmd[idx];
    inc(idx);
  end else fquit:= true;
end;

function tCommandInterface.GetNextWord: ansistring;
var ch : char;
begin
  result:= ''; ch:= GetNextChar;
  while not fquit and (ch <> ' ') do begin
    result:= result + ch; ch:= GetNextChar;
  end;
  if not fquit then dec(idx);
end;

function tCommandInterface.RestLine: ansistring;
begin result:= copy(fcmd, idx, length(fcmd) - idx + 1); end;

procedure tCommandInterface.SkipSpaces;
begin
  while not fquit and (GetNextChar = ' ') do;
  if not fquit then dec(idx);
end;

procedure tCommandInterface.processmessagequeue;
{$ifdef MSWINDOWS}
var msg : TMsg;
{$endif}
begin
  {$ifdef MSWINDOWS}
  while PeekMessage (Msg, 0, 0, 0, PM_REMOVE) do begin
    Dispatch(Msg.Message);

    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
  {$else}
  sleep(1);
  {$endif}
end;

function  tCommandInterface.processcommand(const acommand: ansistring): boolean;
var method: tMethod;
begin
  result:= false;

  fquit:= false; idx:= 1;
  fcmd:= acommand;

  if length(fcmd) > 0 then begin
    SkipSpaces;
    fmethodname:= GetNextWord;

    if length(fmethodname) > 0 then begin
      method.code:= Self.MethodAddress(fmethodname);
      method.data:= Self;
      if assigned(method.code) then result:= tCommandMethod(method);
    end;
  end;
end;

procedure tCommandInterface.syntaxerror;
begin end;

{ common functions }

procedure initcommandinterface(ACommandInterfaceClass: tCommandInterfaceClass);
var obj : tObject;
begin
  if assigned(commandinterface) then freeandnil(commandinterface);
  if assigned(ACommandInterfaceClass) then begin
    obj:= ACommandInterfaceClass.NewInstance;
    if (obj is tCommandInterface) then begin
      tCommandInterface(obj).create;
      commandinterface:= tCommandInterface(obj);
    end else obj.freeinstance;
  end;
end;

procedure processmessagehandler;
begin if assigned(commandinterface) then commandinterface.processmessagequeue; end;

initialization

finalization
  if assigned(commandinterface) then freeandnil(commandinterface);

end.