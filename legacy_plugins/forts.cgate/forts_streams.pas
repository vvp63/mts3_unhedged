{$i forts_defs.pas}

unit forts_streams;

interface

uses  {$ifdef MSWINDOWS}
        windows, messages, 
      {$endif}
      sysutils, inifiles,
      classregistration, sortedlist,
      cgate, gateobjects,
      servertypes,
      forts_common;

type  pReplMsgDataHeader = ^tReplMsgDataHeader;
      tReplMsgDataHeader = record
        replID           : int64;
        replRev          : int64;
        replAct          : int64;
      end;

type  pFortsTableDescItm = ^tFortsTableDescItm;
      tFortsTableDescItm = record
        next             : pFortsTableDescItm;
        fldname          : pAnsiChar;
        fldaddr          : pointer;
        src_ofs          : longint;
        dest_ofs         : longint;
        cvt_func         : pointer;
      end;

type  tFORTSDataStream   = class;

      tFortsTable        = class(tObject)
      private
        FTableName       : ansistring;
        FStream          : tFORTSDataStream;
      public
        constructor Create(AOwner: tFORTSDataStream; const ATableName: ansistring); reintroduce; virtual;

        procedure   doLoad(AIni: TIniFile); virtual;

        procedure   BeforeUpdate; virtual;
        procedure   AfterUpdate; virtual;

        procedure   LifeNumChanged(lifenum: longint); virtual;
        procedure   LinkScheme(fields: pcg_field_desc); virtual;

        procedure   TransactionBegin; virtual;
        procedure   TransactionCommit; virtual;

        function    OnStreamData(adata: pAnsiChar): longint; virtual;
        function    OnStreamOnline: longint; virtual;
        function    OnClearDeleted(const arev: int64): longint; virtual;

        property    Stream: tFORTSDataStream read FStream;
        property    TableName: ansistring read FTableName;
      end;

      pFortsTableListItm = ^tFortsTableListItm;
      tFortsTableListItm = record
        tablename        : string[40];
        table            : tFortsTable;
      end;

      tFortsTableList    = class(tSortedList)
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
      private
        function    FGetTable(const ATableName: ansistring): tFortsTable;
      public
        function    RegisterTable(const ATableName: ansistring; ATable: tFortsTable): boolean;
        procedure   UnregisterTable(const ATableName: ansistring);

        procedure   LifeNumChanged(lifenum: longint);

        property    Tables[const ATableName: ansistring]: tFortsTable read FGetTable;
      end;

      tFORTSDataStream    = class(tCGateListener)
      private
        FStreamName       : ansistring;
        FStreamOpenParams : ansistring;
        FTableList        : tFortsTableList;
        FTableListByIdx   : array[byte] of tFortsTable;
        FTableLastRev     : array[byte] of int64;
        FReqInitStage     : longint;
        FNewInitStage     : longint;
        FCurrentLifeNum   : longint;
        FLastOpenTime     : longint;
      protected
        procedure   OnMsgOpen(var Msg: tcg_msg); message CG_MSG_OPEN;
        procedure   OnMsgClose(var Msg: tcg_msg); message CG_MSG_CLOSE;
        procedure   OnTrsBegin(var Msg: tcg_msg); message CG_MSG_TN_BEGIN;
        procedure   OnTrsCommit(var Msg: tcg_msg); message CG_MSG_TN_COMMIT;
        procedure   OnMsgStreamData(var Msg: tcg_msg_streamdata); message CG_MSG_STREAM_DATA;
        procedure   OnMsgOnline(var Msg: tcg_msg); message CG_MSG_P2REPL_ONLINE;
        procedure   OnClearDeleted(var Msg: tcg_msg); message CG_MSG_P2REPL_CLEARDELETED;
        procedure   OnClearLifenum(var Msg: tcg_msg); message CG_MSG_P2REPL_LIFENUM;
      public
        LastStreamState   : tProcessStage;

        constructor create(AOwner: tCGateConnection;
                           const astreamname, aparams, aopenparams: ansistring;
                           areq_stage, anew_stage: longint); reintroduce; virtual;
        destructor  destroy; override;

        function    open(const aopenparams: ansistring): longint; override;

        procedure   BeforeUpdate; virtual;
        procedure   AfterUpdate; virtual;

        function    RegisterTable(ATable: tFortsTable): boolean;
        procedure   UnregisterAllTables;

        property    StreamName: ansistring read FStreamName;
        property    StreamOpenParams: ansistring read FStreamOpenParams write FStreamOpenParams;
        property    RequiredInitStage: longint read FReqInitStage;
      end;

implementation

uses forts_connection;

{ tFortsTable }

constructor tFortsTable.Create(AOwner: tFORTSDataStream; const ATableName: ansistring);
begin
  inherited create;
  FStream:= AOwner;
  FTableName:= ATableName;
  log('table: %s', [ATableName]);
end;

procedure tFortsTable.doLoad(AIni: TIniFile);
begin end;

procedure tFortsTable.BeforeUpdate;
begin end;

procedure tFortsTable.AfterUpdate;
begin end;

procedure tFortsTable.LifeNumChanged(lifenum: longint);
begin end;

procedure tFortsTable.LinkScheme(fields: pcg_field_desc);
begin end;

procedure tFortsTable.TransactionBegin;
begin end;

procedure tFortsTable.TransactionCommit;
begin end;

function tFortsTable.OnStreamData(adata: pAnsiChar): longint;
begin result:= CG_ERR_OK; end;

function tFortsTable.OnStreamOnline: longint;
begin result:= CG_ERR_OK; end;

function tFortsTable.OnClearDeleted(const arev: int64): longint;
begin result:= CG_ERR_OK; end;

{ tFortsTableList }

procedure tFortsTableList.freeitem(item: pointer);
begin
  if assigned(item) then begin
    with pFortsTableListItm(item)^ do
      if assigned(table) then table.free;
    dispose(pFortsTableListItm(item));
  end;
end;

function tFortsTableList.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tFortsTableList.compare(item1, item2: pointer): longint;
begin result:= comparetext(pFortsTableListItm(item1)^.tablename, pFortsTableListItm(item2)^.tablename); end;

function tFortsTableList.RegisterTable(const ATableName: ansistring; ATable: tFortsTable): boolean;
var sitm : tFortsTableListItm;
    idx  : longint;
    itm  : pFortsTableListItm;
begin
  if assigned(ATable) then begin
    sitm.tablename:= ATableName;
    if not search(@sitm, idx) then begin
      itm:= new(pFortsTableListItm);
      with itm^ do begin
        TableName:= ATableName;
        Table:= ATable;
      end;
      insert(idx, itm);
    end else with pFortsTableListItm(items[idx])^ do begin
      if assigned(Table) then Table.free;
      Table:= ATable;
    end;
    result:= true;
  end else result:= false;
end;

procedure tFortsTableList.UnregisterTable(const ATableName: ansistring);
var sitm : tFortsTableListItm;
    idx  : longint;
begin
  sitm.tablename:= ATableName;
  if search(@sitm, idx) then delete(idx);
end;

function tFortsTableList.FGetTable(const ATableName: ansistring): tFortsTable;
var sitm : tFortsTableListItm;
    idx  : longint;
begin
  sitm.tablename:= ATableName;
  if search(@sitm, idx) then result:= pFortsTableListItm(items[idx])^.table else result:= nil;
end;

procedure tFortsTableList.LifeNumChanged(lifenum: longint);
var idx  : longint;
begin
  for idx:= 0 to count - 1 do
    with pFortsTableListItm(items[idx])^ do
      if assigned(table) then table.LifeNumChanged(lifenum);
end;

{ tFORTSStream }

constructor tFORTSDataStream.create(AOwner: tCGateConnection;
                                    const astreamname, aparams, aopenparams: ansistring;
                                    areq_stage, anew_stage: longint);
begin
  inherited create(AOwner, aparams);
  FStreamName:= astreamname;
  FStreamOpenParams:= aopenparams;
  openparams:= aopenparams;
  fillchar(FTableListByIdx, sizeof(FTableListByIdx), 0);
  fillchar(FTableLastRev, sizeof(FTableLastRev), 0);
  FTableList:= tFortsTableList.Create;
  LastStreamState:= psClose;
  FReqInitStage:= areq_stage;
  FNewInitStage:= anew_stage;
  FCurrentLifeNum:= 0;
  FLastOpenTime:= GetMksCount div 1000;
end;

destructor tFortsDataStream.Destroy;
begin
  Close;
  UnregisterAllTables;
  inherited Destroy;
end;

function tFORTSDataStream.open(const aopenparams: ansistring): longint;
begin
  if abs((GetMksCount div 1000) - cardinal(FLastOpenTime)) > 1000 then begin
    log('Opening stream: %s; (re)open params: %s', [StreamName, aopenparams]);
    result:= inherited open(aopenparams);
  end else result:= CG_ERR_OK;
end;

procedure tFORTSDataStream.BeforeUpdate;
var i : longint;
begin
  if assigned(FTableList) then with FTableList do
    for i:= 0 to count - 1 do with pFortsTableListItm(items[i])^ do
      if assigned(table) then table.BeforeUpdate;
end;

procedure tFORTSDataStream.AfterUpdate;
var i : longint;
begin
  if assigned(FTableList) then with FTableList do
    for i:= 0 to count - 1 do with pFortsTableListItm(items[i])^ do
      if assigned(table) then table.AfterUpdate;
end;

function tFortsDataStream.RegisterTable(ATable: tFortsTable): boolean;
begin
  result:= assigned(FTableList) and assigned(ATable) and FTableList.RegisterTable(ATable.TableName, ATable); end;

procedure tFortsDataStream.UnregisterAllTables;
begin
  fillchar(FTableListByIdx, sizeof(FTableListByIdx), 0);
  if assigned(FTableList) then FTableList.Clear;
end;

procedure tFORTSDataStream.OnMsgOpen(var Msg: tcg_msg);
var scheme  : pcg_scheme_desc;
    msgdesc : pcg_message_desc;
    tbl     : tFortsTable;
    idx     : longint;
begin
  fillchar(FTableListByIdx, sizeof(FTableListByIdx), 0);
  scheme:= getscheme;
  if assigned(scheme) then begin
    idx:= 0;
    msgdesc:= scheme^.messages;
    while assigned(msgdesc) do begin
      if assigned(FTableList) then begin
        tbl:= FTableList.Tables[msgdesc^.name];
        if assigned(tbl) then begin
          tbl.LinkScheme(msgdesc^.fields);
          FTableListByIdx[byte(idx)]:= tbl;
        end;
      end;
      inc(idx);
      msgdesc:= msgdesc^.next;
    end;
  end else log('Error stream: %s GetScheme failed', [FStreamName]);
end;

procedure tFORTSDataStream.OnMsgClose(var Msg: tcg_msg);
var tmpstr : ansistring;
    i      : byte;
begin
  tmpstr:= format('%s;lifenum=%d', [StreamOpenParams, FCurrentLifeNum]);
  for i:= low(FTableListByIdx) to high(FTableListByIdx) do
    if assigned(FTableListByIdx[i]) and (FTableLastRev[i] > 0) then
      tmpstr:= format('%s;rev.%s=%d', [tmpstr, FTableListByIdx[i].TableName, FTableLastRev[i]]);
  openparams:= tmpstr;
end;

procedure tFORTSDataStream.OnTrsBegin(var Msg: tcg_msg);
var i : longint;
begin
  if assigned(FTableList) then with FTableList do
    for i:= 0 to count - 1 do with pFortsTableListItm(items[i])^ do
      if assigned(table) then table.TransactionBegin;
end;

procedure tFORTSDataStream.OnTrsCommit(var Msg: tcg_msg);
var i : longint;
begin
  if assigned(FTableList) then with FTableList do
    for i:= 0 to count - 1 do with pFortsTableListItm(items[i])^ do
      if assigned(table) then table.TransactionCommit;
end;

procedure tFORTSDataStream.OnMsgStreamData(var Msg: tcg_msg_streamdata);
var tbl     : tFortsTable;
begin
  if (msg.msg_type = CG_MSG_STREAM_DATA) then begin
    if assigned(msg.data) then FTableLastRev[msg.msg_index]:= pReplMsgDataHeader(msg.data)^.replRev;
    tbl:= FTableListByIdx[msg.msg_index];
    if assigned(tbl) and assigned(msg.data) then tbl.OnStreamData(msg.data);
  end;
end;

procedure tFORTSDataStream.OnMsgOnline(var Msg: tcg_msg);
var i : longint;
begin
  for i:= 0 to FTableList.Count - 1 do with pFortsTableListItm(FTableList.items[i])^ do
    if assigned(table) then table.OnStreamOnline;
  if (FNewInitStage <> 0) then begin
    log('Stream: %s; Posting new init stage: %d', [StreamName, FNewInitStage]);
    if assigned(connection_list) then connection_list.BroadcastMessage(WM_SETINITSTAGE, FNewInitStage, 0);
  end;
end;

procedure tFORTSDataStream.OnClearDeleted(var Msg: tcg_msg);
var tbl     : tFortsTable;
begin
  if assigned(msg.data) then with pcg_data_cleardeleted(msg.data)^ do begin
    tbl:= FTableListByIdx[table_idx];
    if assigned(tbl) then tbl.OnClearDeleted(table_rev);
  end;
end;

procedure tFORTSDataStream.OnClearLifenum(var Msg: tcg_msg);
begin
  if assigned(msg.data) then begin
    FCurrentLifeNum:= plongint(msg.data)^;
    if assigned(FTableList) then FTableList.LifeNumChanged(FCurrentLifeNum);
  end;
end;

initialization
  register_class([tFortsDataStream]);

end.