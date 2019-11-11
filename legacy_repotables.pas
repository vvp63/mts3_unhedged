{$i tterm_defs.pas}
{$i serverdefs.pas}

unit legacy_repotables;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$else}
        unix,
      {$endif}
      sysutils,
      servertypes, serverapi, protodef,
      sortedlist;

type  tFirmsTable   = class(tSortedList)
        constructor create;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        function    add(var item: tFirmIdent; var changedfields: tFirmSet): tFirmIdent; reintroduce; virtual;
      end;

type  tSettleCodesTable = class(tSortedList)
        constructor create;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        procedure   add(var item: tSettleCodes); reintroduce; virtual;
      end;

var   FirmsCritSect       : tRtlCriticalSection;
      SettleCodesCritSect : tRtlCriticalSection;

const FirmsTable          : tFirmsTable = nil;
      SettleCodesTable    : tSettleCodesTable = nil;

procedure srvUpdateFirmsRec(var sour, dest: tFirmIdent; var sourset, destset, changes: tFirmSet); cdecl;

procedure srvAddFirmsRec(var struc: tFirmIdent; changedfields: tFirmSet); cdecl;
procedure srvAddSettleCodesRec(var struc: tSettleCodes); cdecl;

implementation

uses  tterm_logger, tterm_legacy_apis;

procedure srvUpdateFirmsRec(var sour, dest: tFirmIdent; var sourset, destset, changes: tFirmSet);
begin
  with dest do begin
    stock_id:= sour.stock_id; firmid:= sour.firmid;
    if (fid_firmname in sourset) and (not (fid_firmname in destset) or (firmname<>sour.firmname)) then begin firmname:= sour.firmname; include(changes, fid_firmname); end;
    if (fid_status   in sourset) and (not (fid_status   in destset) or (status<>sour.status))     then begin status:= sour.status;     include(changes, fid_status);   end;
    changes:= changes + [fid_stock_id, fid_firmid];
  end;
end;

{ tFirmsTable }

constructor tFirmsTable.create;
begin
  inherited create;
  fDuplicates:= dupIgnore;
end;

procedure tFirmsTable.freeitem(item: pointer);
begin if assigned(item) then dispose(pFirmItem(item)); end;

function tFirmsTable.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tFirmsTable.compare(item1, item2: pointer): longint;
begin
  result:= pFirmItem(item1)^.firm.stock_id - pFirmItem(item2)^.firm.stock_id;
  if (result = 0) then result:= comparetext(pFirmItem(item1)^.firm.firmid, pFirmItem(item2)^.firm.firmid);
end;

function tFirmsTable.add(var item: tFirmIdent; var changedfields: tFirmSet): tFirmIdent;
var sitm    : tFirmItem;
    itm     : pFirmItem;
    idx     : longint;
    changes : tFirmSet;
begin
  sitm.firm:= item;
  if search(@sitm, idx) then begin
    with pFirmItem(items[idx])^ do try
      changes:= [];
      srvUpdateFirmsRec(item, firm, changedfields, firmset, changes);
      firmset:= firmset + changes;
    finally result:= firm; changedfields:= changes; end;
  end else begin
    itm:= new(pFirmItem);
    fillchar(itm^, sizeof(tFirmItem), 0);
    with itm^ do try
      firmset:= [];
      srvUpdateFirmsRec(item, firm, changedfields, firmset, firmset);
      insert(idx, itm);
    finally result:= firm; changedfields:= firmset; end;
  end;
end;

{ tSettleCodesTable }

constructor tSettleCodesTable.create;
begin
  inherited create;
  fDuplicates:= dupIgnore;
end;

procedure tSettleCodesTable.freeitem(item: pointer);
begin if assigned(item) then dispose(pSettleCodes(item)); end;

function tSettleCodesTable.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tSettleCodesTable.compare(item1, item2: pointer): longint;
begin
  result:= pSettleCodes(item1)^.stock_id - pSettleCodes(item2)^.stock_id;
  if (result = 0) then result:= comparetext(pSettleCodes(item1)^.settlecode, pSettleCodes(item2)^.settlecode);
end;

procedure tSettleCodesTable.add(var item: tSettleCodes);
var itm : pSettleCodes;
    idx : longint;
begin
  if not search(@item, idx) then begin
    itm:= new(pSettleCodes);
    itm^:= item;
    insert(idx, itm);
  end else pSettleCodes(items[idx])^:= item;
end;

//--------------------------------------------------------------------

procedure srvAddFirmsRec(var struc: tFirmIdent; changedfields: tFirmSet);
var frmitm  : tFirmItem;
//    updflag : boolean;
//    idx     : longint;
begin
  try
//    updflag:= false;
    EnterCriticalSection(FirmsCritSect);
    try
      if assigned(FirmsTable) then begin
        frmitm.firmset:= changedfields;
        frmitm.firm:= FirmsTable.add(struc, frmitm.firmset);
//        updflag:= (frmitm.firmset - [fid_stock_id, fid_firmid] <> []);
      end;
    finally LeaveCriticalSection(FirmsCritSect); end;
{
    if updflag then
      with ClientRegistry.LockList do try
        for idx:= 0 to count - 1 do
          with pClientIdRec(items[idx])^.cHandle do
            if (stocks.getflags(struc.stock_id) and stockWork <> 0) and
               ((usrconnflags and usrRepoAllowed) <> 0) then QueueData(frmitm, idFirmInfo, sizeof(tFirmItem));
      finally ClientRegistry.UnLockList; end;
}
  except on e: exception do log('ADDFIRM: Exception: %s', [e.message]); end;
end;

procedure srvAddSettleCodesRec(var struc: tSettleCodes);
//var idx : longint;
begin
  try
    EnterCriticalSection(SettleCodesCritSect);
    try
      if assigned(settlecodestable) then settlecodestable.add(struc);
    finally LeaveCriticalSection(SettleCodesCritSect); end;
{
    with ClientRegistry.LockList do try
      for idx:= 0 to count - 1 do
        with pClientIdRec(items[idx])^.cHandle do
          if (stocks.getflags(struc.stock_id) and stockWork <> 0) and
             ((usrconnflags and usrRepoAllowed) <> 0) then QueueData(struc, idSettleCodes, sizeof(tSettleCodes));
    finally ClientRegistry.UnLockList; end;
}
  except on e: exception do log('ADDSETTLECODE: Exception: %s', [e.message]); end;
end;

exports
  srvUpdateFirmsRec       name srv_UpdateFirmsRec,
  
  srvAddFirmsRec          name srv_AddFirmsRec,
  srvAddSettleCodesRec    name srv_AddSettleCodesRec;

initialization
  {$ifdef MSWINDOWS}
  InitializeCriticalSection(SettleCodesCritSect);
  InitializeCriticalSection(FirmsCritSect);
  {$else}
  InitCriticalSection(SettleCodesCritSect);
  InitCriticalSection(FirmsCritSect);
  {$endif}
  FirmsTable:= tFirmsTable.create;
  SettleCodesTable:= tSettleCodesTable.create;

finalization
  if assigned(FirmsTable)       then freeandnil(FirmsTable);
  if assigned(SettleCodesTable) then freeandnil(SettleCodesTable);
  {$ifdef MSWINDOWS}
  DeleteCriticalSection(FirmsCritSect);
  DeleteCriticalSection(SettleCodesCritSect);
  {$else}
  DoneCriticalSection(FirmsCritSect);
  DoneCriticalSection(SettleCodesCritSect);
  {$endif}

end.