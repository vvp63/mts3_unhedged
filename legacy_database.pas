{$i tterm_defs.pas}
{$i serverdefs.pas}

unit legacy_database;

interface

uses  {$ifdef MSWINDOWS}
        windows, inifiles,
      {$else}
        fclinifiles,
      {$endif}
      classes, sysutils,
      tterm_common, tterm_commonutils;

type  tEnumRecordsCallback = function(sl: tStringList): boolean of object;

const databasename : ansistring = '.\database.ini';

function db_initialize: boolean;
function db_enumeratetablerecords(const atablename: ansistring; acallback: tEnumRecordsCallback): boolean;

implementation

uses tterm_logger;

function db_initialize: boolean;
begin
  with tIniFile.Create(IniFileName) do try
    databasename:= ExpandFileName(ReadString(LegacySettings, itm_database, databasename));
  finally free; end;
  result:= fileexists(databasename);
  if not result then setlength(databasename, 0);
  log('database filename: %s', [databasename]);
end;

function db_enumeratetablerecords(const atablename: ansistring; acallback: tEnumRecordsCallback): boolean;
var sl, vl : tStringList;
    i, j   : longint;
    tmp    : ansistring;
begin
  result:= assigned(acallback) and (length(databasename) > 0);
  if result then
    with tIniFile.Create(databasename) do try
      result:= SectionExists(atablename);
      if result then begin
        sl:= tStringList.Create;
        vl:= tStringList.Create;
        try
          ReadSectionValues(atablename, sl);
          i:= 0;
          while (i < sl.count) do begin
            tmp:= sl[i];
            j:= ansipos('=', tmp);
            if (j > 0) then tmp:= copy(tmp, j + 1, length(tmp));
            DecodeCommaText(tmp, vl, ';');
            if acallback(vl) then inc(i) else i:= sl.count;
          end;
        finally sl.free; vl.free; end;
      end;
    finally free; end;
end;

end.
