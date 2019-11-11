{$i tterm_defs.pas}

unit tterm_pluginsupport;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$else}
        dynlibs,
      {$endif}
      classes, sysutils,
      {$ifdef MSWINDOWS}
        inifiles, versioncontrol,
      {$else}
        fclinifiles,
      {$endif}
      sortedlist,
      serverapi,
      tterm_api, tterm_common, tterm_logger, tterm_legacy_apis, tterm_apidef;

type  pPluginRegistryItem      = ^tPluginRegistryItem;
      tPluginRegistryItem      = record
        libhandle              : HModule;
        {$ifdef MSWINDOWS}
        ver                    : TFileVersionInfo;
        description            : string[128];
        {$endif}
        API                    : pDataSourceAPI;
      end;

      tPluginRegistry     = class(tCustomThreadList)
      public
        procedure   freeitem(item: pointer); override;
        function    extractitem(last: boolean): pointer;
      end;

const Plugin_Registry : tPluginRegistry = nil;

procedure LoadAndInstallPlugins(aexeinstance: HModule; ainifilename: pAnsiChar);
procedure FreePlugins;

function  GetPluginsCount: longint; stdcall;
function  GetPluginsHandles(buffer: pointer; buflen: longint): longint; stdcall;
function  GetPluginsProcAddressList(buffer: pointer; buflen: longint; procname: pAnsiChar): longint; stdcall;

implementation

{ tPluginRegistry }

procedure tPluginRegistry.freeitem(item: pointer);
var done : tUninitializeFunc;
begin
  if assigned(pPluginRegistryItem(item)) then with pPluginRegistryItem(item)^ do try
    if (libhandle <> 0) then try
      if assigned(API) then with API^ do begin
        log('shutting down plugin: %s', [plugname]);
        try
          DoneLegacyAPI(API);
          if (plugflags and plStockProvider = plStockProvider) then begin
            if assigned(stockAPI^.pl_Disconnect) then stockAPI^.pl_Disconnect;
          end;
        finally
          if assigned(pl_Done) then pl_Done;
        end;
      end else begin
        done:= getprocaddress(libhandle, PLG_Uninitialize);
        if assigned(done) then done();
      end;
      log_flush;
      sleep(1000);
    finally
      freelibrary(libhandle);
      log('library [%d] unloaded', [libhandle]);
      log_flush;
    end;
  finally dispose(pPluginRegistryItem(item)); end;
end;

function tPluginRegistry.extractitem(last: boolean): pointer;
var idx : longint;
begin
  result:= nil;
  locklist;
  try
    if (count > 0) then begin
      if last then idx:= count - 1 else idx:= 0;
      result:= items[idx];
      items[idx]:= nil;
      delete(idx);
    end;
  finally unlocklist; end;
end;

{ other functions }

procedure LoadAndInstallPlugins(aexeinstance: HModule; ainifilename: pAnsiChar);
var filemask : ansistring;
    sr       : tSearchRec;
    init     : tplgGetDllAPI;
    init2    : tInitializeFunc;
    init3    : tInitializeExFunc;
    sl       : tStringList;
    i        : longint;
    tmpname  : ansistring;
    tmpres   : boolean;
  function TryLoadPlugin(const afilename: ansistring): boolean;
  var hLib  : HModule;
      itm   : pPluginRegistryItem;
  begin
    result:= false;
    itm:= nil;
    chdir(ExtractFilePath(afilename));
    try
      hLib:= loadlibrary(pAnsiChar(afilename));
      if (hLib <> 0) then try
        log('library [%d] loaded', [hLib]);
        itm:= new(pPluginRegistryItem);
        fillchar(itm^, sizeof(itm^), 0);
        with itm^ do begin
          libhandle        := hLib;
          init             := getprocaddress(hLib, plg_getDllAPI);
          init2            := getprocaddress(hLib, PLG_Initialize);
          init3            := getprocaddress(hLib, PLG_InitializeEx);
          {$ifdef MSWINDOWS}
          ExtractVersionInfo(afilename, ver);
          description      := ExtractInfoKey(pAnsiChar(afilename), key_filedescription);
          {$endif}
          // initialization
          if assigned(init2) then begin
            result:= (init2(aexeinstance, ainifilename) = PLUGIN_OK);
            tmpres:= result;
          end else
          if assigned(init3) then begin
            result:= (init3(aexeinstance, hLib, pAnsiChar(afilename), ainifilename) = PLUGIN_OK);
            tmpres:= result;
          end else tmpres:= true;
          if tmpres and assigned(init) then begin
            API:= InitLegacyAPI(init(@Server_API));
            result:= assigned(API);
          end;
        end;
      except on e: exception do log('LOADPLUGIN: Exception: %s', [e.message]); end;
      if not result then begin
        log('ERROR: failed to load plugin: %s', [afilename]);
        if (hLib <> 0) then begin
          freelibrary(hLib);
          log('library [%d] unloaded', [hLib]);
        end;
        if assigned(itm) then dispose(itm);
      end else begin
        with Plugin_Registry.locklist do try
          add(itm);
          {$ifdef MSWINDOWS}
          with itm^.ver do log('plugin loaded: %s ver %d.%d.%d build: %d', [afilename, major, minor, release, build]);
          {$else}
          log('plugin loaded: %s', [afilename]);
          {$endif}
        finally unlocklist; end;
      end;
    finally chdir(ExeFilePath); end;
  end;
begin
  log('loading plugins...');
  if not assigned(Plugin_Registry) then Plugin_Registry:= tPluginRegistry.create;
  if assigned(Plugin_Registry) then begin
    {$ifdef MSWINDOWS}
    filemask:= format('%s%s*.dll', [ExeFilePath, IncludeTrailingBackslash(PluginPath)]);
    {$else}
    filemask:= format('%s%s*.so', [ExeFilePath, IncludeTrailingBackslash(PluginPath)]);
    {$endif}
    try
      if (findfirst(filemask, sysutils.faArchive or sysutils.faReadOnly, sr) = 0) then
        repeat
          tryloadplugin(format('%s%s%s', [ExeFilePath, IncludeTrailingBackslash(PluginPath), sr.name]));
        until (findnext(sr) <> 0);
    finally findclose(sr); end;
    with tIniFile.create(ainifilename) do try
      sl:= tStringList.create;
      try
        ReadSectionValues(LegacyPluginsSection, sl);
        for i:= 0 to sl.count - 1 do begin
          tmpname:= sl.Values[sl.Names[i]];
          if fileexists(tmpname) then tryloadplugin(ExpandFileName(tmpname))
                                 else log('WARNING: plugin %s not found', [tmpname]);
        end;
      finally sl.free; end;
    finally free; end;
  end;
end;

procedure FreePlugins;
var itm : pointer;
begin
  if assigned(Plugin_Registry) then try
     repeat
       itm:= Plugin_Registry.extractitem(true);
       if assigned(itm) then Plugin_Registry.freeitem(itm);
     until not assigned(itm);
  finally freeandnil(Plugin_Registry); end;
end;

function  GetPluginsCount: longint;
begin
  result:= 0;
  if assigned(Plugin_Registry) then with Plugin_Registry.locklist do try
    result:= count;
  finally unlocklist; end;
end;

function GetPluginsHandles(buffer: pointer; buflen: longint): longint; stdcall;
var i : longint;
  procedure setresult(var buf: pointer; var len: longint; avalue: HModule);
  type pHModule = ^HModule;
  begin
    if assigned(buf) then begin
      dec(len, sizeof(longint));
      if (len >= 0) then begin pHModule(buf)^:= avalue; inc(pAnsiChar(buf), sizeof(HModule)); end;
    end;
  end;
begin
  setresult(buffer, buflen, hInstance);
  result:= 1;
  if assigned(Plugin_Registry) then with Plugin_Registry.locklist do try
    inc(result, count);
    for i:= 0 to count - 1 do setresult(buffer, buflen, pPluginRegistryItem(items[i])^.libhandle);
  finally unlocklist; end;
end;

function  GetPluginsProcAddressList(buffer: pointer; buflen: longint; procname: pAnsiChar): longint; stdcall;
var i : longint;
    p : pointer;
  procedure setresult(var buf: pointer; var len: longint; avalue: pointer);
  type ppointer = ^pointer;
  begin
    if assigned(buf) then begin
      dec(len, sizeof(longint));
      if (len >= 0) then begin ppointer(buf)^:= avalue; inc(pAnsiChar(buf), sizeof(pointer)); end;
    end;
  end;
begin
  result:= 0;
  if assigned(Plugin_Registry) then with Plugin_Registry.locklist do try
    for i:= 0 to count - 1 do begin
      p:= getprocaddress(pPluginRegistryItem(items[i])^.libhandle, procname);
      if assigned(p) then begin
        inc(result);
        setresult(buffer, buflen, p);
      end;
    end;
  finally unlocklist; end;
end;

exports
  GetPluginsCount           name SRV_GetPluginsCount,
  GetPluginsHandles         name SRV_GetPluginsHandles,
  GetPluginsProcAddressList name SRV_GetPluginsProcAddressList;

initialization

finalization
  FreePlugins;

end.