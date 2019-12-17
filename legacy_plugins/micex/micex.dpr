{$I micexdefs.pas}

library micex;

{$r *.res}

uses {$ifdef useexceptionhandler} ExcHandler, {$endif}
     {$ifdef usefastmm4} FastMM4, {$endif}
     {$ifdef UNIX} cmem, cthreads, {$endif}
     classes, sysutils,
     {$ifdef MSWINDOWS}
       windows, inifiles, versioncontrol,
     {$else}
       baseunix, fclinifiles,
     {$endif}
     servertypes, serverapi, classregistration,
     MTEApi,
     micexint, micextables, micexglobal, micexthreads, micexstats, micexorderqueue, micexsubst;

const  PLUGIN_ERROR                     = 0;
       PLUGIN_OK                        = 1;

function  Init(memmgr: pMemoryManager): longint;                                       cdecl; forward;
function  Done: longint;                                                               cdecl; forward;
function  Connect: longint;                                                            cdecl; forward;
function  Disconnect: longint;                                                         cdecl; forward;
procedure SetOrder(order: tOrder; comment: tOrderComment; var res: tSetOrderResult);   cdecl; forward;
procedure OrderCommit(commitresult: byte; orderno: int64);                             cdecl; forward;
procedure DropOrder(order: int64; flags: longint;
                    astock_id: longint; const alevel: TLevel; const acode: TCode;
                    var res: tSetOrderResult);                                         cdecl; forward;
function  MicexHook(params: pointer): longint;                                         cdecl; forward;

type  tConnList   = class(tThreadList)
        function  Get(aindex: longint; var acount: longint; aremove: boolean = false): pointer;
      end;

const stockcount                = 1;

type  tMicexStockLst            = array[0..stockcount - 1] of tStockRec;

const stocklst : tMicexStockLst = ((stock_id          : micexId;
                                    stock_name        : micexStockName));

      micexapi : tStockAPI      = ( stock_count       : stockcount;
                                    stock_list        : @stocklst;
                                    pl_SetOrder       : SetOrder;
                                    pl_DropOrder      : DropOrder;
                                    pl_Connect        : Connect;
                                    pl_Disconnect     : Disconnect;
                                    pl_Hook           : micexHook;
                                    ev_BeforeDayOpen  : nil;
                                    ev_AfterDayOpen   : nil;
                                    ev_BeforeDayClose : nil;
                                    ev_AfterDayClose  : nil;
                                    ev_OrderCommit    : OrderCommit;
                                    ev_ServerStatus   : nil;
                                    pl_MoveOrder      : nil;
                                    pl_DropOrderEx    : nil);

      plugapi  : tDataSourceAPI = ( plugname          : micexplugname;
                                    plugflags         : plStockProvider;
                                    pl_Init           : Init;
                                    pl_Done           : Done;
                                    stockapi          : @micexapi;
                                    newsAPI           : nil;
                                    eventAPI          : nil);

var   conn_list  : tConnList         = nil;

{ tConnList }

function tConnList.Get(aindex: longint; var acount: longint; aremove: boolean = false): pointer;
begin
  result:= nil;
  with locklist do try
    acount:= count;
    if (aindex >= 0) and (aindex < count) then begin
      result:= items[aindex];
      if aremove then delete(aindex);
    end;
  finally unlocklist; end;
end;


{ common functions }

function GetConnectionByBoard(const alevel: tLevel): tConnectionThread;
var i, cnt : longint;
    c      : tConnectionThread;
begin
  result:= nil; i:= 0;
  if assigned(conn_list) then
    repeat
      c:= conn_list.get(i, cnt);
      if assigned(c) and c.boardexists(alevel) then begin
        result:= c; i:= cnt;
      end else inc(i);
    until (i >= cnt);
end;

function Connected: boolean;
var cnt : longint;
begin
  cnt:= 0;
  if assigned(conn_list) then conn_list.Get(0, cnt) else cnt:= 0;
  result:= (cnt > 0);
end;

{ plugin functions }

function Init;
{$ifdef MSWINDOWS}
const ver : TFileVersionInfo = ( major: 0; minor: 0; release: 0; build: 0);
{$endif}
begin
  if not assigned(conn_list) then conn_list:= tConnList.Create;
  {$ifdef MSWINDOWS}
  pluginfilepath:= includetrailingbackslash(extractfilepath(GetModuleName(hInstance)));
  ExtractVersionInfo(ver);
  micexlog('MICEX plugin version %d.%d [%d]', [ver.major, ver.minor, ver.build]);
  {$else}
  micexlog('MICEX plugin');
  {$endif}
  result:= 0;
end;

function  InitEx(aexeinstance, alibinstance: HModule; alibname, ainifilename: pAnsiChar): longint; stdcall;
begin
  pluginfilename := expandfilename(alibname);
  pluginfilepath := includetrailingbackslash(extractfilepath(pluginfilename));
  cfgname        := changefileext(alibname, '.ini');
  micexlog('MICEX config file: %s', [cfgname]);

  result:= PLUGIN_OK;
end;

function Done;
begin
  if connected then Disconnect;
  if assigned(conn_list) then freeandnil(conn_list);
  result:= 0;
end;

function Connect;
const results   : array[boolean] of longint = (1, 0);
      resultstr : array[0..1] of ansistring = ('Connected OK.', 'Error starting MICEX.');
var   sl, tl    : tStringList;
      i, j, num : longint;
      conn      : tConnectionThread;
      tblclass  : tObjectClass;
      tbl       : tObject;
      secname   : ansistring;
      conndelay : longint;
      inifile   : tIniFile;
      filter_len: longint;
  function check_section(const asection: ansistring): boolean;
  const known_sec : array[0..4] of ansistring = ('common', 'connections', 'subst_cid', 'subst_acc', 'filter');
  var   i         : longint;
  begin
    result:= true;
    for i:= low(known_sec) to high(known_sec) do
      result:= result and (ansicomparetext(asection, known_sec[i]) <> 0);
  end;
begin
  if not connected then begin
    micexlog('Starting MICEX');

    inifile:= tIniFile.Create(cfgname);
    with inifile do try
      EnableStatsCollector((readinteger('common', 'stats', 0) <> 0));

      synchronizetime:= (readinteger('common', 'synchronizetime', 0) <> 0);
      synchourdelta:= readinteger('common', 'hourtimedelta', synchourdelta);

      keepalive:= (readinteger('common', 'keepalive', longint(keepalive)) <> 0);
      keepalivetimeout:= readinteger('common', 'keepalivetimeout', keepalivetimeout);

      if (readinteger('common', 'enable_subst', 0) <> 0) then begin
        if not assigned(subst_cid) then subst_cid:= tSubstList.create;
        subst_cid.load(inifile, 'subst_cid');

        if not assigned(subst_acc) then subst_acc:= tSubstList.create;
        subst_acc.load(inifile, 'subst_acc');
      end;

      filter_len:= readinteger('common', 'enable_filter', 0);
      if (filter_len > 0) then begin
        if not assigned(brokerrefs) then brokerrefs:= tFilterList.create;
        brokerrefs.load(inifile, 'filter', filter_len);
      end;

      orderbooktable:= readstring('common', 'orderbooktable', orderbooktable);

      if assigned(conn_list) then begin
        sl:= tStringList.create;
        tl:= tStringList.create;
        try
          num:= 0;
          readsections(sl);
          for i:= 0 to sl.count - 1 do begin
            secname:= sl[i];
            if check_section(secname) then begin
              conndelay:= readinteger(secname, 'delay', defaultdelay);
              conn:= tConnectionThread.create(secname, 'data', 'trs', conndelay);
              try
                inc(num);
                conn.connectionname:= readstring(secname, 'name', format('connection%d', [num]));
                tl.CommaText:= readstring(secname, 'tables', '');
                if (tl.Count > 0) then
                  with conn.tablelist.locklist do try
                    for j:= 0 to tl.count - 1 do begin
                      tblclass:= get_class(tl[j]);
                      if assigned(tblclass) then try
                        tbl:= tblclass.NewInstance;
                        if assigned(tbl) then begin
                          if tbl is tTableDescriptor then begin
                            tTableDescriptor(tbl).create(conn, @conn.ConCsect);
                            conn.tablelist.add(tbl);
                          end else tbl.FreeInstance;
                        end;
                      except on e: exception do micexlog('Addtable failed for table: %s', [tl[j]]); end;
                    end;
                  finally conn.tablelist.unlocklist; end;
              finally
                conn_list.Add(conn);
                conn.resume;
              end;
            end;
          end;
        finally
          freeandnil(tl);
          freeandnil(sl);
        end;
      end;

    finally free; end;

    sleep(1000);

    if assigned(conn_list) then conn_list.Get(0, i) else i:= 0;

    result:= results[(i > 0)];
    micexlog(resultstr[result]);
  end else begin
    micexlog('Already connected! Disconnect first...');
    result:= 1;
  end;
end;

function Disconnect;
var kot : tKotirovki;
    c   : tConnectionThread;
    cnt : longint;
begin
  if assigned(conn_list) then
    repeat
      c:= conn_list.Get(0, cnt, true);
      if assigned(c) then with c do begin
        micexlog('Disconnecting thread: %s', [c.connectionname]);
        terminate; waitfor; free;
      end;
    until (cnt = 0);
  kot.stock_id:= micexId;
  Server_API.LockKotirovki;
  try Server_API.ClearKotirovkiTbl(kot, clrByStockid);
  finally Server_API.UnlockKotirovki; end;
  result:= 0;
  micexlog('Disconnected OK.');
end;

procedure SetOrder (order: tOrder; comment: tOrderComment; var res: tSetOrderResult);
var aconnection : tConnectionThread;
begin
  {$ifdef UseSetOrderFlag}setorderflag:= true;{$endif}
  aconnection:= GetConnectionByBoard(order.level);
  if assigned(aconnection) then begin
    if assigned(aconnection.OrdersQueue) then begin
      aconnection.OrdersQueue.AddNewOrder(order, comment, res);
    end else with res do begin
      accepted:=soRejected; ExtNumber:=0; TEReply:= 'MICEX: Unable to queue request!';
    end;
  end else with res do begin
    accepted:= soRejected; ExtNumber:= 0; TEReply:= 'MICEX: No connection to stock or invalid security!';
  end;
  if (res.Accepted <> soUnknown) and assigned(Server_API.SetTrsResult) then Server_API.SetTrsResult(res);
end;

procedure OrderCommit (commitresult: byte; orderno: int64);
begin
  {$ifdef UseSetOrderFlag}setorderflag:= false;{$endif}
end;

procedure DropOrder (order: int64; flags: longint; astock_id: longint; const alevel: TLevel; const acode: TCode; var res: tSetOrderResult);
var aconnection : tConnectionThread;
begin
  aconnection:= GetConnectionByBoard(alevel);
  if assigned(aconnection) then begin
    if assigned(aconnection.OrdersQueue) then begin
      aconnection.OrdersQueue.AddDropOrder(order, flags, astock_id, alevel, acode, res);
    end else with res do begin
      accepted:=soRejected; ExtNumber:=0; TEReply:= 'MICEX: Unable to queue request!';
    end;
  end else with res do begin
    accepted:=soRejected; ExtNumber:=0; TEReply:='MICEX: No connection to stock or invalid security!';
  end;
end;

function micexHook (params: pointer): longint;
var st     : string;
    i, cnt : longint;
    c      : tConnectionThread;
  function normalizestr(astr: pChar): string;
  begin
    result:= trim(astr);
    while (pos('  ', result) > 0) do delete(result, pos('  ', result), 1);
  end;
  procedure checkconn(conn: tConnectionThread; const conname: string);
  var i  : longint;
      f  : boolean;
  const maxcheckwait = 600;
  begin
    if assigned(conn) then begin
      conn.alivechecker:= 0; i:= 0; f:= true;
      while (i < maxcheckwait) do begin
        if assigned(conn) then begin
          if (conn.alivechecker > 0) then begin
            micexlog('Connection via %s alive', [conname]);
            i:= maxcheckwait; f:= false;
          end else begin
            inc(i); sleep(100);
          end;
        end else begin
          micexlog('Connection via %s just closed', [conname]);
          i:= maxcheckwait; f:= false;
        end;
      end;
      if f then micexlog('Connection via %s seems to be dead!', [conname]);
    end else micexlog('Connection via %s is not established', [conname]);
  end;
  procedure listconn(conn:tConnectionThread; const conname:string);
  var i : longint;
  begin
    if assigned(conn) then begin
      micexlog('tables associated with connection via %s', [conname]);
      with conn.tablelist.locklist do try
        for i:=0 to count-1 do with tTableDescriptor(items[i]) do
          micexlog('%d table: %s desc: %s', [i, tablename, tabledesc]);
      finally conn.tablelist.unlocklist; end;
    end else micexlog('Connection via %s is not established', [conname]);
  end;
begin
  result:=0;
  if assigned(params) then begin
    setlength(st, 0);
    try st:= normalizestr(pChar(params));
    except on e:exception do micexlog('EXECHOOK: Exception: %s',[e.message]); end;
    if (comparetext(st, 'REINIT') = 0) then begin
//      micexlog('ReInitializing orders and trades tables...');
      micexlog('ReInitializing not implemented!')
    end else
    if (comparetext(st, 'STATUS') = 0) then begin
      micexlog('Connection status:');
      i:= 0;
      repeat
        c:= conn_list.get(i, cnt);
        if assigned(c) then listconn(c, c.connectionname);
        inc(i);
      until not assigned(c);
      micexlog('Ok!');
    end else
    if (comparetext(st, 'CHECK') = 0) then begin
      micexlog('Warning: Checking may take up to 2 minutes...');
      i:= 0;
      repeat
        c:= conn_list.get(i, cnt);
        if assigned(c) then checkconn(c, c.connectionname);
        inc(i);
      until not assigned(c);
      micexlog('Check complete!');
    end else
    if (comparetext(st, 'STAT ON') = 0) then begin
      EnableStatsCollector(true);
    end else
    if (comparetext(st, 'STAT OFF') = 0) then begin
      EnableStatsCollector(false);
    end else
    if (comparetext(st, 'STAT') = 0) then begin
      outputstats;
    end else begin
      micexlog('Unknown command: "%s"', [st]);
      micexlog('Command list: CHECK, STATUS, REINIT, STAT [<none>/ON/OFF]');
    end;
  end else micexlog('EXECHOOK: invalid parameters');
end;

function getDllAPI(srvapi: pServerAPI): pDataSourceAPI; cdecl;
begin
  Server_API := srvapi^;
  result     := @plugapi;
end;

exports getDllAPI name 'getDllAPI',
        InitEX    name 'plg_initialize_ex';

begin
  IsMultiThread:= true;
  {$ifdef FPC}
  DefaultFormatSettings.DecimalSeparator:= '.';
  {$else}
  DecimalSeparator:= '.';
  {$endif}
end.
