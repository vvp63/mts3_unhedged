unit forts_commandparser;

interface

uses {$ifdef MSWINDOWS}
       windows,
     {$endif}  
     sysutils;

type  tCommandMethod    = function: boolean of object;

type  tCommandInterface = class(tObject)
      private
        fcmd        : string;
        idx         : longint;
        fquit       : boolean;
        fmethodname : string;
      protected
        function    GetNextChar:char;
        procedure   SkipSpaces;
        function    GetNextWord:string;
        function    RestLine:string;
        function    CheckEoln: boolean;
      public
        function    processcommand(const acommand: string): boolean; virtual;
        procedure   syntaxerror; virtual; 
        property    command: string read fcmd;
      end;

implementation

{ tCommandInterface }

function tCommandInterface.CheckEoln: boolean;
begin SkipSpaces; result:= fquit; end;

function tCommandInterface.GetNextChar: char;
begin
  result:= #0;
  if (idx <= length(fcmd)) then begin
    result:= fcmd[idx];
    inc(idx);
  end else fquit:= true;
end;

function tCommandInterface.GetNextWord: string;
var ch : char;
begin
  result:= ''; ch:= GetNextChar;
  while not fquit and (ch <> ' ') do begin
    result:= result + ch; ch:= GetNextChar;
  end;
  if not fquit then dec(idx);
end;

function tCommandInterface.RestLine: string;
begin result:= copy(fcmd, idx, length(fcmd) - idx + 1); end;

procedure tCommandInterface.SkipSpaces;
begin
  while not fquit and (GetNextChar = ' ') do;
  if not fquit then dec(idx);
end;

function  tCommandInterface.processcommand(const acommand: string): boolean;
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

end.