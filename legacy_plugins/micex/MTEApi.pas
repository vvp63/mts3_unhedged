{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit MTEApi;

interface

uses  {$ifdef MSWINDOWS} windows, {$endif}
      MTETypes;

const {$ifndef MSWINDOWS}
        {$ifdef CPUX64}
        micexdll = 'mtesrl64';
        {$else}
        micexdll = 'mtesrl';
        {$endif}
      {$else}
        {$ifdef CPUX64}
        micexdll = 'mtesrl64.dll';
        {$else}
        micexdll = 'mtesrl.dll';
        {$endif}
      {$endif}

{ Функции библиотеки mtesrl.dll }
function  MTEConnect    (Params,ErrorMsg:PAnsiChar):Integer;                                                   {$ifdef Unix}cdecl{$else}stdcall{$endif};
function  MTEDisconnect (Idx:Integer):Integer;                                                                 {$ifdef Unix}cdecl{$else}stdcall{$endif};
function  MTEStructure  (Idx:Integer; var Msg:PMTEMsg):Integer;                                                {$ifdef Unix}cdecl{$else}stdcall{$endif};
function  MTEOpenTable  (Idx:Integer; TableName,Params:PAnsiChar; Complete:LongBool; var Msg:PMTEMsg):Integer; {$ifdef Unix}cdecl{$else}stdcall{$endif};
function  MTEAddTable   (Idx,HTable,Ref:Integer):Integer;                                                      {$ifdef Unix}cdecl{$else}stdcall{$endif};
function  MTERefresh    (Idx:Integer; var Msg:PMTEMsg):integer;                                                {$ifdef Unix}cdecl{$else}stdcall{$endif};
function  MTECloseTable (Idx,HTable:integer):integer;                                                          {$ifdef Unix}cdecl{$else}stdcall{$endif};
function  MTEExecTrans  (Idx:integer; TransName,Params,ResultMsg:PAnsiChar):integer;                           {$ifdef Unix}cdecl{$else}stdcall{$endif};

function  MTEErrorToStr (const mteerror: tErrorMsg): string;

implementation

function  MTEConnect;    external micexdll;
function  MTEDisconnect; external micexdll;
function  MTEStructure;  external micexdll;
function  MTEOpenTable;  external micexdll;
function  MTEAddTable;   external micexdll;
function  MTERefresh;    external micexdll;
function  MTECloseTable; external micexdll;
function  MTEExecTrans;  external micexdll;

function  MTEErrorToStr (const mteerror: tErrorMsg): string;
var i, j : longint;
begin
  setlength(result, sizeof(mteerror));
  i:= low(mteerror); j:= 0;
  while (i <= high(mteerror)) do
    if (mteerror[i] <> #0) then begin inc(j); result[j]:= mteerror[i]; inc(i); end else i:= high(mteerror) + 1;
  setlength(result, j);
end;

end.