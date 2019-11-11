{$i tterm_defs.pas}
{$i serverdefs.pas}

unit  legacy_transactions;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$else}
        baseunix,
      {$endif}
      sysutils, math,
      sortedlist,
      servertypes;

const trs_version_file_tag : array[0..7] of ansichar = 'VER.1.0'#0;

const trs_type_version     = 0;
      trs_type_order       = 1;
      trs_type_moveorder   = 2;
      trs_type_trscancel   = 3;

type  tTransactionVarData    = packed record
        case longint of
          trs_type_order     : (order: tOrder);
          trs_type_moveorder : (moveorder: tMoveOrder);
      end;

type  pTransactionData     = ^tTransactionData;
      tTransactionData     = packed record
        cbsize             : longint;
        trs_id             : int64;
        trs_type           : longint;
        trs_data           : tTransactionVarData;
        trs_comment        : shortstring;
      end;

type  pTransactionHeader   = ^tTransactionHeader;
      tTransactionHeader   = packed record
        cbsize             : longint;
        trs_id             : int64;
        trs_type           : longint;
        trs_data           : array[0..0] of byte;
      end;

const size_trs_version     = sizeof(tTransactionHeader) + sizeof(trs_version_file_tag) - 1;
      size_trs_order       = sizeof(tTransactionHeader) + sizeof(tOrder) - 1;
      size_trs_moveorder   = sizeof(tTransactionHeader) + sizeof(tMoveOrder) - 1;
      size_trs_cancel      = sizeof(tTransactionHeader) - 1;

type  tTransactionRegistry = class(tSortedThreadList)
      private
        fCurrentTrsID      : int64;
        fFileHandle        : THandle;
        fFileName          : ansistring;
        fVersionIsSet      : boolean;

        function    fGetDayOpenStatus: longint;
      protected
        function    get_transaction(const atrs_id: int64): pTransactionHeader;
        function    transaction_file_open: boolean;
        procedure   transaction_file_close;
        function    transaction_file_load: boolean;
        function    transaction_file_write(atrs: pTransactionHeader): boolean;
      public
        constructor create;
        destructor  destroy; override;
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;

        function    initializetransactions(const afilename: ansistring; aauto_open: boolean; const ainit_trs_id: int64): boolean;
        procedure   finalizetransactions;

        function    move_to_archive(const aarchivepath: ansistring; aauto_open: boolean): boolean;

        function    new_transaction(const order: tOrder): int64; overload;
        function    new_transaction(const moveorder: tMoveOrder): int64; overload;

        function    remove_transaction(const atrs_id: int64): boolean;

        function    search_transaction(const atrs_id: int64): pTransactionHeader;

        function    update_order(var aorder: tOrders): boolean;
        function    update_trade(var atrade: tTrades): boolean;

        property    DayOpenStatus: longint read fGetDayOpenStatus;
      end;

const transaction_registry : tTransactionRegistry = nil;

implementation

uses  tterm_logger, tterm_commonutils;

function cmpi64(a, b: int64): longint;
begin
  a:= a - b;
  if a < 0 then result:= -1 else
  if a > 0 then result:= 1  else result:= 0;
end;

{ tTransactionRegistry }

constructor tTransactionRegistry.create;
begin
  inherited create;
  capacity:= 30000;
  fCurrentTrsID:= 1;
  fFileHandle:= INVALID_HANDLE_VALUE;
  fVersionIsSet:= false;
end;

destructor tTransactionRegistry.destroy;
begin
  transaction_file_close;
  inherited destroy;
end;

procedure tTransactionRegistry.freeitem(item: pointer);
begin if assigned(item) then freemem(item); end;

function tTransactionRegistry.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tTransactionRegistry.compare(item1, item2: pointer): longint;
begin result:= cmpi64(pTransactionHeader(item1)^.trs_id, pTransactionHeader(item2)^.trs_id); end;

function tTransactionRegistry.fGetDayOpenStatus: longint;
const results : array[boolean] of longint = (dayWasClosed, dayWasOpened);
begin result:= results[(fFileHandle <> INVALID_HANDLE_VALUE)]; end;

function tTransactionRegistry.new_transaction(const order: tOrder): int64;
var itm : pAnsiChar;
    sz  : longint;
begin
  sz:= size_trs_order;
  itm:= allocmem(sz);
  with pTransactionHeader(itm)^ do begin
    cbsize:= sz;
    trs_type:= trs_type_order;
    system.move(order, trs_data, sizeof(order));
    locklist;
    try
      result:= fCurrentTrsID;
      trs_id:= result; inc(fCurrentTrsID);
      insert(count, itm);
      if not transaction_file_write(pTransactionHeader(itm)) then log('ERROR: Error saving transaction (order)!');
    finally unlocklist; end;
  end;
end;

function tTransactionRegistry.new_transaction(const moveorder: tMoveOrder): int64;
var itm : pAnsiChar;
    sz  : longint;
begin
  sz:= size_trs_moveorder;
  itm:= allocmem(sz);
  with pTransactionHeader(itm)^ do begin
    cbsize:= sz;
    trs_type:= trs_type_moveorder;
    system.move(moveorder, trs_data, sizeof(moveorder));
    locklist;
    try
      result:= fCurrentTrsID;
      trs_id:= result; inc(fCurrentTrsID);
      insert(count, itm);
      if not transaction_file_write(pTransactionHeader(itm)) then log('ERROR: Error saving transaction (moveorder)!');
    finally unlocklist; end;
  end;
end;

function tTransactionRegistry.remove_transaction(const atrs_id: int64): boolean;
var sitm : tTransactionHeader;
    idx  : longint;
begin
  sitm.cbsize:= size_trs_cancel;
  sitm.trs_id:= atrs_id;
  sitm.trs_type:= trs_type_trscancel;
  locklist;
  try
    result:= search(@sitm, idx);
    if result then delete(idx);
    if not transaction_file_write(@sitm) then log('ERROR: Error saving transaction (cancel transaction)!');
  finally unlocklist; end;
end;

function tTransactionRegistry.get_transaction(const atrs_id: int64): pTransactionHeader;
var sitm : tTransactionHeader;
    idx  : longint;
begin
  sitm.trs_id:= atrs_id;
  if search(@sitm, idx) then result:= pTransactionHeader(items[idx]) else result:= nil;
end;

function tTransactionRegistry.search_transaction(const atrs_id: int64): pTransactionHeader;
begin
  locklist;
  try result:= get_transaction(atrs_id);
  finally unlocklist; end;
end;

{   // order params recovery
    intid:= struc.transaction;
    ExecSQL(q, 'exec GetOrderParamsByTrsNo @trsno=%d', [intid], false);
    if not q.eof then begin
      struc.account     := q.fields[0].asstring;
      struc.clientid    := struc.account;
      astatus           := format('%s ',[q.fields[1].asstring])[1];
      abalance          := q.fields[2].ascurrency;
      struc.comment     := q.fields[3].asstring; if (length(struc.comment) > 0) then include(changedfields, ord_comment);
      notvalid          := (length(q.fields[4].asstring) = 0);
      struc.transaction := q.fields[5].asinteger;
      struc.internalid  := q.fields[6].asinteger;
     end;
}

function tTransactionRegistry.update_order(var aorder: tOrders): boolean;
var trs : pTransactionHeader;
begin
  locklist;
  try
    trs:= get_transaction(aorder.transaction);
    if assigned(trs) then with trs^ do begin
      case trs_type of
        trs_type_order     : with pOrder(@trs_data)^ do begin
                               aorder.account     := account;
                               aorder.clientid    := cid;
                               aorder.internalid  := aorder.transaction;
                               aorder.transaction := transaction;
//                               aorder.comment     := ''; // restore original comment here!!!
                             end;
        trs_type_moveorder : with pMoveOrder(@trs_data)^ do begin
                               aorder.account     := account;
                               aorder.clientid    := cid;
                               aorder.internalid  := aorder.transaction;
                               aorder.transaction := transaction;
//                               aorder.comment     := ''; // restore original comment here!!!
                             end;
      end;
    end;
    result:= assigned(trs);
  finally unlocklist; end;
end;

{   // trade params recovery
    ExecSQL(q, 'exec GetOrderParamsByTrsNo @trsno=%d', [intid], false);
    if not q.eof then begin
      struc.account     := q.fields[0].asstring;
      struc.clientid    := struc.account;
      struc.comment     := q.fields[3].asstring; if (length(struc.comment) > 0) then include(changedfields, trd_comment);
      struc.transaction := q.fields[5].asinteger;
      struc.internalid  := q.fields[6].asinteger;
      if not (trd_tradetype in changedfields) then begin
        struc.tradetype := format('%sN', [q.fields[7].asstring])[1];
        include(changedfields, trd_tradetype);
      end;
      addflag           := true;
    end;
}

function tTransactionRegistry.update_trade(var atrade: tTrades): boolean;
var trs : pTransactionHeader;
begin
  locklist;
  try
    trs:= get_transaction(atrade.transaction);
    if assigned(trs) then with trs^ do begin
      case trs_type of
        trs_type_order     : with pOrder(@trs_data)^ do begin
                               atrade.account     := account;
                               atrade.clientid    := cid;
                               atrade.internalid  := atrade.transaction;
                               atrade.transaction := transaction;
//                               atrade.comment     := ''; // restore original comment here!!!
                             end;
        trs_type_moveorder : with pMoveOrder(@trs_data)^ do begin
                               atrade.account     := account;
                               atrade.clientid    := cid;
                               atrade.internalid  := atrade.transaction;
                               atrade.transaction := transaction;
//                               atrade.comment     := ''; // restore original comment here!!!
                             end;
      end;
    end;
    result:= assigned(trs);
  finally unlocklist; end;
end;

procedure tTransactionRegistry.transaction_file_close;
begin
  if (fFileHandle <> INVALID_HANDLE_VALUE) then begin
    {$ifdef MSWINDOWS}
    fileclose(fFileHandle);
    {$else}
    fpClose(fFileHandle);
    {$endif}
    fFileHandle:= INVALID_HANDLE_VALUE;
    fVersionIsSet:= false;
  end;
end;

function tTransactionRegistry.transaction_file_open: boolean;
begin
  transaction_file_close;
  if (length(fFileName) > 0) then
    {$ifdef MSWINDOWS}
    fFileHandle:= createfile(pAnsiChar(fFileName), GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ,
                             nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    {$else}
    fFileHandle:= fpOpen(pAnsiChar(fFileName), O_RdWr or O_Creat);
    {$endif}
  result:= (fFileHandle <> INVALID_HANDLE_VALUE);
  fVersionIsSet:= false;
end;

function tTransactionRegistry.transaction_file_load: boolean;
const file_read_error        = 'ERROR: Invalid transaction file!';
      file_version_missmatch = 'ERROR: Invalid transaction file version!';
var   sitm    : tTransactionHeader;
      idx     : longint;
      recsize : longint;
      itm     : pAnsiChar;
begin
  result:= false;
  if (fFileHandle <> INVALID_HANDLE_VALUE) then try
    locklist;
    try
      while (fileread(fFileHandle, recsize, sizeof(recsize)) = sizeof(recsize)) do
        case recsize of
          size_trs_version   : begin
                                 itm:= allocmem(recsize);
                                 pTransactionHeader(itm)^.cbsize:= recsize;
                                 dec(recsize, sizeof(recsize));
                                 try
                                   if (fileread(fFileHandle, (itm + sizeof(recsize))^, recsize) = recsize) then begin
                                     fVersionIsSet:= CompareMem(@pTransactionHeader(itm)^.trs_data, @trs_version_file_tag, sizeof(trs_version_file_tag));
                                     if not fVersionIsSet then raise Exception.Create(file_version_missmatch);
                                   end else raise Exception.Create(file_read_error);
                                 finally freemem(itm); end;
                               end;
          size_trs_order,
          size_trs_moveorder : begin
                                 itm:= allocmem(recsize);
                                 pTransactionHeader(itm)^.cbsize:= recsize;
                                 dec(recsize, sizeof(recsize));
                                 if (fileread(fFileHandle, (itm + sizeof(recsize))^, recsize) = recsize) then begin
                                   fCurrentTrsID:= math.max(fCurrentTrsID, pTransactionHeader(itm)^.trs_id + 1);
                                   if not search(itm, idx) then insert(idx, itm) else freemem(itm);
                                 end else begin
                                   freemem(itm);
                                   raise Exception.Create(file_read_error);
                                 end;
                               end;
          size_trs_cancel    : begin
                                 dec(recsize, sizeof(recsize));
                                 if (fileread(fFileHandle, (pAnsiChar(@sitm) + sizeof(recsize))^, recsize) = recsize) then begin
                                   fCurrentTrsID:= math.max(fCurrentTrsID, sitm.trs_id + 1);
                                   if search(@sitm, idx) then delete(idx);
                                 end else raise Exception.Create(file_read_error);
                               end;
          else                 raise Exception.Create(file_read_error);
        end;
      log('Transactions init ok; %d active records loaded; Current ID: %d', [count, fCurrentTrsID]);
      result:= true;
    finally unlocklist; end;
  except on e: exception do log(e.message); end;
end;

function tTransactionRegistry.transaction_file_write(atrs: pTransactionHeader): boolean;
const verhdr : tTransactionHeader = ( cbsize: size_trs_version; trs_id: 0; trs_type: trs_type_version; );
begin
  result:= false;
  if assigned(atrs) and (fFileHandle <> INVALID_HANDLE_VALUE) then begin
    if not fVersionIsSet then begin
      filewrite(fFileHandle, verhdr, sizeof(verhdr) - 1);
      filewrite(fFileHandle, trs_version_file_tag, sizeof(trs_version_file_tag));
      fVersionIsSet:= true;
    end;
    result:= (filewrite(fFileHandle, atrs^, atrs^.cbsize) = atrs^.cbsize);
  end;
end;

function tTransactionRegistry.initializetransactions(const afilename: ansistring; aauto_open: boolean; const ainit_trs_id: int64): boolean;
begin
  result:= true;
  fCurrentTrsID:= math.max(fCurrentTrsID, ainit_trs_id);
  if (length(afilename) > 0) then begin
    fFileName:= afilename;
    if fileexists(fFileName) or aauto_open then begin
      result:= transaction_file_open;
      if result then result:= transaction_file_load;
    end else result:= false;
  end;
end;

procedure tTransactionRegistry.finalizetransactions;
begin transaction_file_close; end;

function  tTransactionRegistry.move_to_archive(const aarchivepath: ansistring; aauto_open: boolean): boolean;
var newpath : ansistring;
    newname : ansistring;
    oldext  : ansistring;
    sz      : int64;
    i       : longint;
begin
  locklist;
  try
    if (fFileHandle <> INVALID_HANDLE_VALUE) then begin
      sz:= fileseek(fFileHandle, 0, 2);
      transaction_file_close;
      if (sz > 0) then begin
        try
          newpath:= IncludeTrailingBackSlash(aarchivepath) + IncludeTrailingBackSlash(FormatDateTime('yyyy"-"mm"-"dd', now));
          result:= ForceDirectories(newpath);
          if result then begin
            i:= 0;
            repeat
              oldext:= ExtractFileExt(fFileName);
              newname:= newpath + ChangeFileExt(ExtractFileName(fFileName), format('.%.3d%s', [i, oldext]));
              inc(i);
            until not fileexists(newname);
            {$ifdef MSWINDOWS}
            result:= MoveFileEx(pAnsiChar(fFileName), pAnsiChar(newname), MOVEFILE_REPLACE_EXISTING or MOVEFILE_COPY_ALLOWED);
            {$else}
            result:= RenameFile (fFileName, newname);
            {$endif}
          end;
        finally
          if aauto_open then transaction_file_open;
          if (fFileHandle <> INVALID_HANDLE_VALUE) then fileseek(fFileHandle, 0, 2);
        end;
      end else begin
        deletefile(fFileName);
        result:= true;
      end;
    end else result:= false;
  finally unlocklist; end;
end;

initialization
  transaction_registry:= tTransactionRegistry.create;

finalization
  if assigned(transaction_registry) then freeandnil(transaction_registry);

end.