{$i tterm_defs.pas}

unit tterm_common;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$endif}
      sysutils,
      tterm_utils;

const {$ifdef MSWINDOWS}
      ExeFileName            : ansistring = 'ttermengine.dll';
      IniFileName            : ansistring = 'ttermengine.ini';
      {$else}
      ExeFileName            : ansistring = 'libttermengine.so';
      IniFileName            : ansistring = 'libttermengine.ini';
      {$endif}
      ExeFilePath            : ansistring = '.';
      PluginPath             : ansistring = 'plugins';
      ArchivePath            : ansistring = 'archive';

      LegacyPluginsSection   : ansistring = 'legacy-plugins';

      LegacySettings         : ansistring = 'legacy';
      itm_database           : ansistring = 'database';

      auto_open_day          : boolean    = true;
      transactions_file_name : ansistring = 'transactions.dat';

      store_all_trades       : boolean    = true;

      initial_transaction_id : int64      = 1;

{$ifndef MSWINDOWS}
type  PCoord                 = ^TCoord;
      TCoord                 = packed record
        X                    : Smallint;
        Y                    : Smallint;
      end;
{$endif}

const consolesize            : tCoord = (x:96; y:25);

var   memorymanager          : TMemoryManager;

implementation

var   tmpname : ansistring;

initialization
  tmpname     := ExpandFileName(paramstr(0));
  {$ifdef MSWINDOWS}
  ExeFileName := ExtractFileName(tmpname);
  IniFileName := ChangeFileExt(tmpname, '.ini');
  ExeFilePath := IncludeTrailingBackSlash(ExtractFilePath(tmpname));
  {$else}
  ExeFileName := ExtractFileName(tmpname);
  IniFileName := ChangeFileExt(tmpname, '.ini');
  ExeFilePath := IncludeTrailingBackSlash(ExtractFilePath(tmpname));
  {$endif}

finalization
  setlength(tmpname, 0);

end.