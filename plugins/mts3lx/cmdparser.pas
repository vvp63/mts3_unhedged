unit cmdparser;

interface

uses sysutils;

type  tCommandParser = class(tObject)
      private
        fCommandLine : ansistring;
        fPreparsed   : array of ansistring;
        fCount       : longint;
        fCurrentChar : longint;
        function    fEndOfLine: boolean;
        function    fGetNextChar: char;
        procedure   fSkipSpaces;
        function    fGetNextWord: ansistring;
        procedure   fSetCommandLine(const avalue: ansistring);
        function    fGetParamCount: longint;
        procedure   reset;
        procedure   parse;
      protected
        function    GetParameter(aindex: longint): ansistring; virtual;
        function    GetParameterLowCase(aindex: longint): ansistring;
      public
        constructor create(const acommandline: ansistring); virtual;
        property    paramline: ansistring read fCommandLine write fSetCommandLine;
        property    paramcount: longint read fCount;
        property    param[aindex: longint]: ansistring read GetParameter;
        property    paramlow[aindex: longint]: ansistring read GetParameterLowCase;
      end;

implementation

{ tCommandParser }

constructor tCommandParser.create(const acommandline: ansistring);
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

function tCommandParser.fGetNextWord: ansistring;
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

procedure tCommandParser.fSetCommandLine(const avalue: ansistring);
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

function tCommandParser.GetParameter(aindex: longint): ansistring;
begin
  if (aindex >= 0) and (aindex < length(fPreparsed)) then result:= fPreparsed[aindex]
                                                     else setlength(result, 0);
end;

function tCommandParser.GetParameterLowCase(aindex: longint): ansistring;
begin result:= lowercase(GetParameter(aindex)); end;

end.
