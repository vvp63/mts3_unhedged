unit versioncontrol;

interface

uses  windows, classes, sysutils;

const key_originalfilename : pchar = 'StringFileInfo\040904E4\OriginalFilename';
      key_fileversion      : pchar = 'StringFileInfo\040904E4\FileVersion';
      key_filedescription  : pchar = 'StringFileInfo\040904E4\FileDescription';

type  PFileVersionInfo = ^TFileVersionInfo;
      TFileVersionInfo = record
        major          : longint;
        minor          : longint;
        release        : longint;
        build          : longint;
      end;

function ExtractVersionInfo(var AVersion: TFileVersionInfo): boolean; overload;
function ExtractVersionInfo(const afilename: string; var AVersion: TFileVersionInfo): boolean; overload;

function ExtractInfoKey(afilename, akeyname: pChar): string;

implementation

function GetModuleName(Module: HMODULE): string;
var ModName: array[0..MAX_PATH] of char;
begin SetString(Result, ModName, GetModuleFileName(Module, ModName, SizeOf(ModName))); end;

function ExtractVersionInfo(var AVersion: TFileVersionInfo): boolean; overload;
begin result:= ExtractVersionInfo(GetModuleName(HInstance), AVersion); end;

function ExtractVersionInfo(const afilename: string; var AVersion: TFileVersionInfo): boolean; overload;
var   BuffSize, Len  : cardinal;
      Buff, Value    : PChar;
      i              : longint;
      tmp            : string;
begin
  result:= false;
  BuffSize := GetFileVersionInfoSize(pchar(afilename), BuffSize);
  if (BuffSize > 0) then begin
    Buff := allocmem(BuffSize);
    try
      if GetFileVersionInfo(pchar(afilename), 0, BuffSize, Buff) then
        if VerQueryValue(Buff, key_fileversion, Pointer(Value), Len) then try
          if (len > 0) then begin
            setlength(tmp, len);
            for i:= 0 to len - 1 do
              if (value[i] <> '.') then tmp[i+1]:= value[i] else tmp[i+1]:= ',';
            with tStringList.create do try
              commatext:= tmp;
              if (count = 4) then begin
                with AVersion do begin
                  major   := strtoint(strings[0]);
                  minor   := strtoint(strings[1]);
                  release := strtoint(strings[2]);
                  build   := strtoint(strings[3]);
                end;
                result:= true;
              end;
            finally free; end;
          end;
        except end;
    finally freemem(Buff, BuffSize); end;
  end;
end;

function ExtractInfoKey(afilename, akeyname: pChar): string;
var   BuffSize, Len  : cardinal;
      Buff, Value    : PChar;
begin
  setlength(result, 0);
  BuffSize := GetFileVersionInfoSize(afilename, BuffSize);
  if (BuffSize > 0) then begin
    Buff := allocmem(BuffSize);
    try
      if GetFileVersionInfo(afilename, 0, BuffSize, Buff) then
        if VerQueryValue(Buff, akeyname, Pointer(Value), Len) then
          if (len > 0) then setstring(result, Value, len - 1);
    finally freemem(Buff, BuffSize); end;
  end;
end;


end.
