{$i tterm_defs.pas}

unit tterm_utils;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$endif}
      sysutils;

function  max(a, b: longint): longint;
function  min(a, b: longint): longint;

{$ifdef MSWINDOWS}
function  GetModuleName(Module: HMODULE): string;
{$endif}

function  GetFileDate(const filename: string): TDateTime;

implementation

function max(a, b: longint): longint;
begin if a > b then result:= a else result:= b; end;

function min(a, b: longint): longint;
begin if a < b then result:= a else result:= b; end;

// возвращает имя файла по хендлу модуля в строке
{$ifdef MSWINDOWS}
function GetModuleName(Module: HMODULE): string;
var ModName: array[0..MAX_PATH] of char;
begin SetString(Result, ModName, GetModuleFileName(Module, ModName, SizeOf(ModName))); end;
{$endif}

// возвращает дату и время создания файла

function  GetFileDate(const filename: string): TDateTime;
var SearchRec: TSearchRec;
begin
  Result := 0;
  if (FindFirst(ExpandFileName(FileName), faAnyFile, SearchRec) = 0) then Result := FileDateToDateTime(SearchRec.Time);
  FindClose(SearchRec);
end;

end.