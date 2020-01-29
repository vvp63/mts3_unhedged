unit cmdparser;

interface

uses sysutils;

type  tCommandParser = class(tObject)
      private
        fCommandLine : string;
        fPreparsed   : array of string;
        fCount       : longint;
        fCurrentChar : longint;
        function    fEndOfLine: boolean;
        function    fGetNextChar: char;
        procedure   fSkipSpaces;
        function    fGetNextWord: string;
        procedure   fSetCommandLine(const avalue: string);
        function    fGetParamCount: longint;
        procedure   reset;
        procedure   parse;
      protected
        function    GetParameter(aindex: longint): string; virtual;
        function    GetParameterLowCase(aindex: longint): string;
      public
        constructor create(const acommandline: string); virtual;
        property    paramline: string read fCommandLine write fSetCommandLine;
        property    paramcount: longint read fCount;
        property    param[aindex: longint]: string read GetParameter;
        property    paramlow[aindex: longint]: string read GetParameterLowCase;
      end;

implementation

{ tCommandParser }

constructor tCommandParser.create(const acommandline: string);
begin
  inherited create;
  fSetCommandLine(acommandline);
end;

function tCommandParser.fEndOfLine: boolean;
begin result:= (fCurrentChar > length(fCommandLine)); end;

function tCommandParser.fGetNextChar:char;
begin
  if (fCurrentChar > 0) and (fCurrentChar <= length(fCommandLine)) then begin
    result:= fCommandLine[fCurrentChar];
    inc(fCurrentChar);
  end else result:= #0;
end;

procedure tCommandParser.fSkipSpaces;
var ch    : char;
    fquit : boolean;
begin
  fquit:= false;
  repeat
    ch:= fGetNextChar;
    case ch of
      ' ', #$9 : ;
      #0 : fquit:= true;
      else begin dec(fCurrentChar); fquit:= true; end;
    end;
  until fquit;
end;

function tCommandParser.fGetNextWord: string;
var ch : char;
begin
  setlength(result, 0);
  ch:= fGetNextChar;
  while not (ch in [' ', #$9, #$0]) do begin
    result:= result + ch;
    ch:= fGetNextChar;
  end;
  if not fEndOfLine then dec(fCurrentChar);
end;

procedure tCommandParser.fSetCommandLine(const avalue: string);
begin fCommandLine:= avalue; parse; end;

function tCommandParser.fGetParamCount: longint;
begin
  result:= 0;
  reset; fSkipSpaces;
  while not fEndOfLine do begin
    fGetNextWord;
    fSkipSpaces;
    inc(result);
  end;
end;

procedure tCommandParser.parse;
var aindex : longint;
begin
  fCount:= fGetParamCount;
  setlength(fPreparsed, fCount);
  aindex:= 0;
  reset;
  while not fEndOfLine and (aindex < fCount) do begin
    fSkipSpaces; fPreparsed[aindex]:= fGetNextWord;
    inc(aindex);
  end;
end;

procedure tCommandParser.reset;
begin fCurrentChar:= 1; end;

function tCommandParser.GetParameter(aindex: longint): string;
begin
  if (aindex >= 0) and (aindex < length(fPreparsed)) then result:= fPreparsed[aindex]
                                                     else setlength(result, 0);
end;

function tCommandParser.GetParameterLowCase(aindex: longint): string;
begin result:= lowercase(GetParameter(aindex)); end;

end.
