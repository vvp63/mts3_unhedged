UNIT crt32;

INTERFACE

USES Windows, Messages;

{$ifdef win32}

CONST
  MyCP            = 866;

  Black           = 0;
  Blue            = 1;
  Green           = 2;
  Cyan            = 3;
  Red             = 4;
  Magenta         = 5;
  Brown           = 6;
  LightGray       = 7;
  DarkGray        = 8;
  Gray            = DarkGray;
  LightBlue       = 9;
  LightGreen      = 10;
  LightCyan       = 11;
  LightRed        = 12;
  LightMagenta    = 13;
  Yellow          = 14;
  White           = 15;

  BW40            = 0;
  C40             = 1;
  BW80            = 2;
  C80             = 3;
  Mono            = 7;
  Last            = -1;

  CheckBreak      = True;
  CheckEOF        = True;
  DirectVideo     = True;
  CheckSnow       = False;

  FUNCTION WhereX : Integer;
  FUNCTION WhereY : Integer;
  PROCEDURE ClrEol;
  PROCEDURE ClrScr;
  PROCEDURE InsLine;
  PROCEDURE DelLine;
  PROCEDURE GotoXY(CONST x, y : Integer);
  PROCEDURE HighVideo;
  PROCEDURE LowVideo;
  PROCEDURE NormVideo;
  PROCEDURE TextBackground(CONST Color : Word);
  PROCEDURE TextColor(CONST Color : Word);
  PROCEDURE TextAttribut(CONST Color, Background : Word);
  PROCEDURE TextMode(CONST Mode : Word);
  PROCEDURE Delay(CONST ms : Integer);
  FUNCTION KeyPressed : Boolean;
  FUNCTION ReadKey : Char;
  PROCEDURE Win32ReadKey(var InputRec:tInputRecord);
  PROCEDURE Sound;
  PROCEDURE NoSound;
  PROCEDURE RestoreCrt;
  PROCEDURE ConsoleEnd;
  PROCEDURE FlushInputBuffer;
  FUNCTION Pipe : Boolean;
  FUNCTION FromPipe : Boolean;
  PROCEDURE Debugcrt;

VAR
  StdError : Text;
  WindMin : TCoord;
  WindMax : TCoord;
  ViewMax : TCoord;
  TextAttr : Word;
  LastMode : Word;
  SoundFrequenz : Integer;
  SoundDuration : Integer;

  hConsoleInput : THandle;
  hConsoleOutput : THandle;
  HConsoleError : THandle;

{$endif win32}

IMPLEMENTATION

{$ifdef win32}

USES SysUtils;

VAR
  StartAttr : Word;       // the attribute at start
  OldOCP : Integer;       // the start Output-Codepage
  OldCP : Integer;        // the start Input-Codepage
  CrtPipe : Boolean;      // is the output piped ?
  CrtInPipe : boolean;     // comes the Data from a pipe

(*
 * when you make new features to see the API-Records
 *)
PROCEDURE Debugcrt;
VAR
  Cbi : TConsoleScreenBufferInfo;
  t : Boolean;
  PROCEDURE WriteCbi(Cbi : TConsoleScreenBufferInfo);
  BEGIN
    WriteLn(StdError, Format('Size.X:      %3d Size.Y:     %3d  CursPos.X:    %3d  CursPos.Y:     %3d    Attr: %3d', 
                           [Cbi.dwSize.x, Cbi.dwSize.y, Cbi.dwCursorPosition.x, Cbi.dwCursorPosition.y, Cbi.wAttributes])); 
    Write(StdError,  Format('Window.left: %3d Window.Top: %3d  Window.Right: %3d  Window.Bottom: %3d ', 
                           [Cbi.srWindow.left, Cbi.srWindow.Top, Cbi.srWindow.Right, Cbi.srWindow.Bottom])); 
    WriteLn(StdError, Format('MaxWind.X %2d MaxWind.Y %2d', [Cbi.dwMaximumWindowSize.x, Cbi.dwMaximumWindowSize.y]));
  END; 
BEGIN
  t := GetConsoleScreenBufferInfo(hConsoleInput, Cbi); 
  TextColor(White);
  WriteLn(StdError, Format('InputBuffer(%d)', [hConsoleInput]), t); 
  TextColor(DarkGray); 
  WriteCbi(Cbi); 
  WriteLn(StdError);
  t := GetConsoleScreenBufferInfo(hConsoleOutput, Cbi);
  TextColor(White); 
  WriteLn(StdError, Format('OuputBuffer(%d)', [hConsoleOutput]), t); 
  TextColor(DarkGray); 
  WriteCbi(Cbi); 
  WriteLn(StdError); 
  t := GetConsoleScreenBufferInfo(HConsoleError, Cbi); 
  TextColor(White); 
  WriteLn(StdError, Format('ErrorBuffer(%d)', [HConsoleError]), t); 
  TextColor(DarkGray); 
  WriteCbi(Cbi); 
  WriteLn(StdError); 
  NormVideo; 
END; 

{*  
 * Choose one of these line or remove it work with fully ANSI or OEM code
 * for the win32 API's
 *
 * when you Convertet old DOS-Application the first line may be right
 * try and find out :-)
 *}
PROCEDURE OEMCode;
begin
  if AreFileApisANSI then SetFileApisToOEM;
//  if not AreFileApisANSI then SetFileApisToANSI;
end;

PROCEDURE ClrEol;
VAR tC : TCoord;
  Len, Nw : Cardinal;
  Cbi : TConsoleScreenBufferInfo;
BEGIN
  GetConsoleScreenBufferInfo(hConsoleOutput, Cbi);
  Len := Cbi.dwSize.x-Cbi.dwCursorPosition.x;
  tC.x := Cbi.dwCursorPosition.x;
  tC.y := Cbi.dwCursorPosition.y;
  FillConsoleOutputAttribute(hConsoleOutput, TextAttr, Len, tC, Nw);
  FillConsoleOutputCharacter(hConsoleOutput, ' ', Len, tC, Nw); 
END; 

PROCEDURE ClrScr;
VAR tC : TCoord; 
  Nw : Cardinal;
  Cbi : TConsoleScreenBufferInfo;
BEGIN
  GetConsoleScreenBufferInfo(hConsoleOutput, Cbi);
  tC.x := 0;
  tC.y := 0;
  FillConsoleOutputAttribute(hConsoleOutput, TextAttr, Cbi.dwSize.x*Cbi.dwSize.y, tC, Nw);
  FillConsoleOutputCharacter(hConsoleOutput, ' ', Cbi.dwSize.x*Cbi.dwSize.y, tC, Nw);
  SetConsoleCursorPosition(hConsoleOutput, tC);
END; 

FUNCTION WhereX : Integer;
VAR Cbi : TConsoleScreenBufferInfo;
BEGIN
  GetConsoleScreenBufferInfo(hConsoleOutput, Cbi); 
  Result := TCoord(Cbi.dwCursorPosition).x+1
END; 

FUNCTION WhereY : Integer; 
VAR Cbi : TConsoleScreenBufferInfo; 
BEGIN
  GetConsoleScreenBufferInfo(hConsoleOutput, Cbi); 
  Result := TCoord(Cbi.dwCursorPosition).y+1
END;

PROCEDURE GotoXY(CONST x, y : Integer); 
VAR Coord : TCoord; 
BEGIN
  Coord.x := x-1; 
  Coord.y := y-1; 
  SetConsoleCursorPosition(hConsoleOutput, Coord)
END;

PROCEDURE InsLine; 
VAR
 Cbi : TConsoleScreenBufferInfo; 
 sSR : TSmallRect;
 Coord : TCoord; 
 CI : TCharInfo; 
 Nw : Cardinal; 
BEGIN
  GetConsoleScreenBufferInfo(hConsoleOutput, Cbi);
  Coord := Cbi.dwCursorPosition;
  sSR.left := 0;
  sSR.Top := Coord.y;
  sSR.Right := Cbi.srWindow.Right;
  sSR.Bottom := Cbi.srWindow.Bottom;
  CI.AsciiChar := ' ';
  CI.Attributes := Cbi.wAttributes;
  Coord.x := 0;
  Coord.y := Coord.y+1;
  ScrollConsoleScreenBuffer(hConsoleOutput, sSR, NIL, Coord, CI);
  Coord.y := Coord.y-1;
  FillConsoleOutputAttribute(hConsoleOutput, TextAttr, Cbi.dwSize.x*Cbi.dwSize.y, Coord, Nw);
END; 

PROCEDURE DelLine;
VAR
 Cbi : TConsoleScreenBufferInfo; 
 sSR : TSmallRect; 
 Coord : TCoord; 
 CI : TCharInfo;
 Nw : Cardinal; 
BEGIN
  GetConsoleScreenBufferInfo(hConsoleOutput, Cbi); 
  Coord := Cbi.dwCursorPosition; 
  sSR.left := 0; 
  sSR.Top := Coord.y+1; 
  sSR.Right := Cbi.srWindow.Right; 
  sSR.Bottom := Cbi.srWindow.Bottom; 
  CI.AsciiChar := ' '; 
  CI.Attributes := Cbi.wAttributes; 
  Coord.x := 0; 
  Coord.y := Coord.y;
  ScrollConsoleScreenBuffer(hConsoleOutput, sSR, NIL, Coord, CI); 
  FillConsoleOutputAttribute(hConsoleOutput, TextAttr, Cbi.dwSize.x*Cbi.dwSize.y, Coord, Nw); 
END; 

PROCEDURE TextBackground(CONST Color : Word);
BEGIN
  LastMode := TextAttr; 
  TextAttr := (Color SHL 4) OR (TextAttr AND $f);
  SetConsoleTextAttribute(hConsoleOutput, TextAttr);
END;

PROCEDURE TextColor(CONST Color : Word);
BEGIN
  LastMode := TextAttr;
  TextAttr := (Color AND $f) OR (TextAttr AND $f0);
  SetConsoleTextAttribute(hConsoleOutput, TextAttr);
END;

PROCEDURE RestoreCrt;
BEGIN
  Normvideo;
END;

PROCEDURE TextMode(CONST Mode : Word);
BEGIN
  TextAttribut(Mode, Mode);
END;

PROCEDURE TextAttribut(CONST Color, Background : Word);
BEGIN
  LastMode := TextAttr;
  TextAttr := (Color AND $f) OR (Background SHL 4);
  SetConsoleTextAttribute(hConsoleOutput, TextAttr);
END;

PROCEDURE HighVideo;
BEGIN
  LastMode := TextAttr;
  TextAttr := TextAttr OR $8;
  SetConsoleTextAttribute(hConsoleOutput, TextAttr);
END;

PROCEDURE LowVideo;
BEGIN
  LastMode := TextAttr;
  TextAttr := TextAttr AND $f7;
  SetConsoleTextAttribute(hConsoleOutput, TextAttr);
END;

PROCEDURE NormVideo;
BEGIN
  LastMode := TextAttr;
  TextAttr := StartAttr;
  SetConsoleTextAttribute(hConsoleOutput, TextAttr);
END;

PROCEDURE FlushInputBuffer;
BEGIN
  FlushConsoleInputBuffer(hConsoleInput)
END;

FUNCTION KeyPressed : Boolean;
VAR NumberOfEvents : Cardinal;
BEGIN
  GetNumberOfConsoleInputEvents(hConsoleInput, NumberOfEvents);
  Result := NumberOfEvents > 0;
END;

FUNCTION ReadKey : Char;
VAR
  NumRead  : Cardinal;
  InputRec : TInputRecord;
BEGIN
  WHILE NOT (ReadConsoleInput(hConsoleInput,InputRec,1,NumRead)) OR
       (InputRec.EventType <> KEY_EVENT) OR
        NOT (InputRec.Event.KeyEvent.bKeyDown) DO Sleep(1);
  Result := InputRec.Event.KeyEvent.AsciiChar;
END;

PROCEDURE Win32ReadKey;
VAR NumRead  : Cardinal;
BEGIN
  WHILE NOT (ReadConsoleInput(hConsoleInput,InputRec,1,NumRead)) OR
       (InputRec.EventType <> KEY_EVENT) OR
        NOT (InputRec.Event.KeyEvent.bKeyDown) DO Sleep(1);
END;

PROCEDURE Delay(CONST ms : Integer);
BEGIN
  Sleep(ms);  // use less processtime as a timer
END;

PROCEDURE Sound;
BEGIN
  Windows.Beep(SoundFrequenz, SoundDuration);
END;

PROCEDURE NoSound;
BEGIN
  Windows.Beep(SoundFrequenz, 0);
END;

PROCEDURE ConsoleEnd;
BEGIN
END;

FUNCTION Pipe : Boolean;
BEGIN
  Result := CrtPipe;
END;

FUNCTION FromPipe : Boolean;
BEGIN
  Result := CrtInPipe;
END;

{  the Startroutine "Init" set all important things e.g.
   - save the old Codepage and Colors
   - create a StdError-Handle near Output and Input (normal handle)
   - check if the output is going to a pipe
   - check witch Country is your OS for the Routine ConsoleEnd
   - set the default SoundDuration and Soundfrequenz
   - set the focus to the Console
}
PROCEDURE Init;
VAR
  Cbi : TConsoleScreenBufferInfo;
  tC  : TCoord;
BEGIN
 SetActiveWindow(0);
 OEMCode;
 hConsoleInput := GetStdHandle(STD_INPUT_HANDLE);
 hConsoleOutput := GetStdHandle(STD_OUTPUT_HANDLE);
 HConsoleError := GetStdHandle(STD_ERROR_HANDLE);
 CrtInPipe := getfiletype(hConsoleInput) = FILE_TYPE_PIPE;
 AssignFile(StdError, '');
 ReWrite(StdError);
 TTextRec(StdError).Handle := HConsoleError;
 IF GetConsoleScreenBufferInfo(hConsoleOutput, Cbi) THEN
 BEGIN
   TextAttr := Cbi.wAttributes;
   StartAttr := Cbi.wAttributes;
   LastMode  := Cbi.wAttributes;
   tC.x := Cbi.srWindow.left+1;
   tC.y := Cbi.srWindow.Top+1;
   WindMin := tC;
   ViewMax := Cbi.dwSize;
   tC.x := Cbi.srWindow.Right+1;
   tC.y := Cbi.srWindow.Bottom+1;
   WindMax := tC;
   CrtPipe := False;
 END ELSE CrtPipe := True;
 SoundFrequenz := 1000;
 SoundDuration := -1;
 OldOCP := GetConsoleOutputCP;
 OldCP := GetConsoleCP;
 SetConsoleOutputCP(MyCP);
 SetConsoleCP(MyCP)
END;

INITIALIZATION
 Init;

FINALIZATION
 normvideo;                        // restore the color
 CloseFile(StdError);              // close StdError
 SetConsoleOutputCP(OldOCP);       // restore the OutputCodepage
 SetConsoleCP(OldCP);              // restore the inputCodepage

 if (hConsoleInput <> INVALID_HANDLE_VALUE)  then closehandle(hConsoleInput);
 if (hConsoleOutput <> INVALID_HANDLE_VALUE) then closehandle(hConsoleOutput);
 if (hConsoleError <> INVALID_HANDLE_VALUE)  then closehandle(hConsoleError);

{$endif win32}

END.
