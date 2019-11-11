unit ansioem;

interface

function ANSIToOEM(const ANSIStr: string): string;
function OEMToANSI(const OEMStr: string): string;

procedure ANSIToOEMBuf(abuf: pAnsiChar; abuflen: longint);

function ANSIToOEMChar(ach: char): char;
function OEMToANSIChar(ach: char): char;


implementation

function ANSIToOEM;
var i : integer;
begin
  result:= ANSIStr;
  for i:= 1 to length(result) do
    case result[i] of
      #192..#239 : dec(result[i], 64);
      #240..#255 : dec(result[i], 16);
    end;
end;

function OEMToANSI;
var i : integer;
begin
  result:= OEMStr;
  for i:= 1 to length(result) do
    case result[i] of
      #224..#239 : inc(result[i], 16);
      #128..#175 : inc(result[i], 64);
    end;
end;

procedure ANSIToOEMBuf(abuf: pAnsiChar; abuflen: longint);
begin
  if assigned(abuf) then
    while (abuflen > 0) do begin
      case abuf^ of
        #192..#239 : dec(abuf^, 64);
        #240..#255 : dec(abuf^, 16);
      end;
      inc(abuf);
      dec(abuflen);
    end;
end;

function ANSIToOEMChar(ach: char): char;
begin
  result:= ach;
  case result of
    #192..#239 : dec(result, 64);
    #240..#255 : dec(result, 16);
  end;
end;

function OEMToANSIChar(ach: char): char;
begin
  result:= ach;
  case result of
    #224..#239 : inc(result, 16);
    #128..#175 : inc(result, 64);
  end;
end;


end.