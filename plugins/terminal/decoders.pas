{$i terminal_defs.pas}

unit decoders;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$endif}
      classes, sysutils,
      servertypes, remotetypes, protodef, fields,
      lowlevel, crc32, itzip, rc5, sortedlist, proto_in;

const ps_ERR_NOTENCRYPTED = ps_ERR_TABLEID + 1;
      ps_ERR_UNSUPPORTED  = ps_ERR_TABLEID + 2;
      ps_ERR_UNCOMPLETE   = ps_ERR_TABLEID + 3;
      ps_ERR_NULLBUF      = ps_ERR_TABLEID + 4;

type  tSendKotirovkiProc  = procedure (add: byte; SecId: tSecIdent) of object;
      tSetOrderProc       = procedure (var order: tOrder; const acomment:ansistring) of object;
      tSetStopOrderProc   = procedure (var stoporder: tStopOrder; const acomment:ansistring) of object;
      tDropOrderProc      = procedure (var droporder: tDropOrder) of object;
      tReportQueryProc    = procedure (var reportquery: tReportQuery) of object;
      tSendTradesProc     = procedure (aaccount: tAccount; astock_id: longint; acode: tCode; aquantity: longint) of object;
      tSendAllAllTrdProc  = procedure (add: byte; const boardid: tBoardIdent; atradeno: int64) of object;
      tSendMessageProc    = procedure (const atext:ansistring; isencrypted:boolean) of object;
      tTrsQueryProc       = procedure (trscount: longint; trsids: pTrsQuery) of object;
      tSendPingProc       = procedure (id: longint) of object;
      tNewsQueryProc      = procedure (id: longint; dt: tDateTime; querytype: longint) of object;
      tMoveOrderProc      = procedure (var moveorder: tMoveOrder) of object;

type  tCommonBufDecoder   = class (TIncomingBufferDecoder)
       fSendKotirovkiProc : tSendKotirovkiProc;
       fSetOrderProc      : tSetOrderProc;
       fSetStopOrderProc  : tSetStopOrderProc;
       fDropOrderProc     : tDropOrderProc;
       fReportQueryProc   : tReportQueryProc;
       fSendTradesProc    : tSendTradesProc;
       fSendAllAllTrdProc : tSendAllAllTrdProc;
       fSendMessageProc   : tSendMessageProc;
       fTrsQueryProc      : tTrsQueryProc;
       fSendPingProc      : tSendPingProc;
       fNewsQueryProc     : tNewsQueryProc;
       fMoveOrderProc     : tMoveOrderProc;
      protected
       procedure   SetSendKotirovkiProc (aSendKotirovkiProc: tSendKotirovkiProc); virtual;
       procedure   SetSetOrderProc (aSetOrderProc: tSetOrderProc); virtual;
       procedure   SetSetStopOrderProc (aSetStopOrderProc: tSetStopOrderProc); virtual;
       procedure   SetDropOrderProc (aDropOrderProc: tDropOrderProc); virtual;
       procedure   SetReportQueryProc (aReportQueryProc: tReportQueryProc); virtual;
       procedure   SetSendTradesProc (aSendTradesProc: tSendTradesProc); virtual;
       procedure   SetSendAllAllTrdProc (aSendAllAllTrdProc: tSendAllAllTrdProc); virtual;
       procedure   SetSendMessageProc (aSendMessageProc: tSendMessageProc); virtual;
       procedure   SetTrsQueryProc (aTrsQueryProc: tTrsQueryProc); virtual;
       procedure   SetSendPingProc (aSendPingProc: tSendPingProc); virtual;
       procedure   SetNewsQueryProc (aNewsQueryProc: tNewsQueryProc); virtual;
       procedure   SetMoveOrderProc (aMoveOrderProc: tMoveOrderProc); virtual;
      public
       hdr                : tProtocolRec;
       currenttrs         : int64;
       property    SendKotirovkiProc: tSendKotirovkiProc read fSendKotirovkiProc write SetSendKotirovkiProc;
       property    SetOrderProc: tSetOrderProc read fSetOrderProc write SetSetOrderProc;
       property    SetStopOrderProc: tSetStopOrderProc read fSetStopOrderProc write SetSetStopOrderProc;
       property    DropOrderProc: tDropOrderProc read fDropOrderProc write SetDropOrderProc;
       property    ReportQueryProc: tReportQueryProc read fReportQueryProc write SetReportQueryProc;
       property    SendTradesProc: tSendTradesProc read fSendTradesProc write SetSendTradesProc;
       property    SendAllAllTrdProc: tSendAllAllTrdProc read fSendAllAllTrdProc write SetSendAllAllTrdProc;
       property    SendMessageProc: tSendMessageProc read fSendMessageProc write SetSendMessageProc;
       property    TrsQueryProc: tTrsQueryProc read fTrsQueryProc write SetTrsQueryProc;
       property    SendPingProc: tSendPingProc read fSendPingProc write SetSendPingProc;
       property    NewsQueryProc: tNewsQueryProc read fNewsQueryProc write SetNewsQueryProc;
       property    MoveOrderProc: tMoveOrderProc read fMoveOrderProc write SetMoveOrderProc;
      end;

//--- old style buffer decoder ---------------------------------------

type  tOldBufDecoder      = class (tCommonBufDecoder)
      public
       function    ParseBuffer (Buffer: pAnsiChar; BufLen: longint): longint; override;
      end;

//--- buffer decoder -------------------------------------------------

const fieldKotCount       = 4;

const fldr_kot_type       = 1;    fldr_kot_stock_id   = 2;
      fldr_kot_level      = 3;    fldr_kot_code       = 4;

const KotFields           : array[0..fieldKotCount-1] of tFields = (
       (code: fldr_kot_type;      field: fld_Type),
       (code: fldr_kot_stock_id;  field: fld_Stock_ID),
       (code: fldr_kot_level;     field: fld_Level),
       (code: fldr_kot_code;      field: fld_Code));

type  fld_kot_fields      = (flds_kot_add, flds_kot_stock_id, flds_kot_level, flds_kot_code);
      fld_kot_set         = set of fld_kot_fields;

const all_kot_fields      : fld_kot_set = [flds_kot_add, flds_kot_stock_id, flds_kot_level, flds_kot_code];

type  tKotQueryDecoder    = class (tDecoder)
      private
       fDecoder           : tCommonBufDecoder;
       fSendKotirovkiProc : tSendKotirovkiProc;
       fadd               : byte;
       fSecId             : tSecIdent;
       fStatus            : fld_kot_set;
      public
       constructor Create (aDecoder: tCommonBufDecoder; aSendKotirovkiProc: tSendKotirovkiProc); reintroduce; virtual;
       function    GetField (FieldNum: longint): PFields; override;
       function    RecUpdated: longint; override;
       function    UpdateValue (Code: longint; Buffer: pAnsiChar): longint; override;
      end;

// --------------------------------------------

const fieldOrderCount     = 17;

const fldr_ord_trs        = 1;    fldr_ord_stock_id   = 2;
      fldr_ord_level      = 3;    fldr_ord_code       = 4;
      fldr_ord_buysell    = 5;    fldr_ord_price      = 6;
      fldr_ord_quantity   = 7;    fldr_ord_account    = 8;
      fldr_ord_flags      = 9;    fldr_ord_comment    = 10;
      fldr_ord_client_id  = 11;   fldr_ord_cfirmid    = 12;
      fldr_ord_match      = 13;   fldr_ord_settle     = 14;

      fldr_ord_refundrate = 15;
      fldr_ord_reporate   = 16;
      fldr_ord_price2     = 17;

const OrdFields           : array[0..fieldOrderCount-1] of tFields = (
      (code: fldr_ord_trs;        field: fld_Trs_ID),
      (code: fldr_ord_stock_id;   field: fld_Stock_ID),
      (code: fldr_ord_level;      field: fld_Level),
      (code: fldr_ord_code;       field: fld_Code),
      (code: fldr_ord_buysell;    field: fld_BuySell),
      (code: fldr_ord_price;      field: fld_Price),
      (code: fldr_ord_quantity;   field: fld_Quantity),
      (code: fldr_ord_account;    field: fld_Account),
      (code: fldr_ord_flags;      field: fld_Flags),
      (code: fldr_ord_comment;    field: fld_Comment),
      (code: fldr_ord_client_id;  field: fld_ClientID),
      (code: fldr_ord_cfirmid;    field: fld_CFirmID),
      (code: fldr_ord_match;      field: fld_Match),
      (code: fldr_ord_settle;     field: fld_SettleCode),
      (code: fldr_ord_refundrate; field: fld_RefundRate),
      (code: fldr_ord_reporate;   field: fld_RepoRate),
      (code: fldr_ord_price2;     field: fld_Price2));

type  fld_ord_fields      = (flds_ord_trs, flds_ord_stock_id, flds_ord_level, flds_ord_code, flds_ord_buysell,
                             flds_ord_price, flds_ord_quantity, flds_ord_account, flds_ord_flags, flds_ord_comment,
                             flds_ord_client_id, flds_ord_cfirmid, flds_ord_match, flds_ord_settle,
                             flds_ord_refundrate, flds_ord_reporate, flds_ord_price2);
      fld_ord_set         = set of fld_ord_fields;

const all_ord_fields      : fld_ord_set = [flds_ord_trs, flds_ord_stock_id, flds_ord_level, flds_ord_code, flds_ord_buysell,
                                           flds_ord_price, flds_ord_quantity, flds_ord_account, flds_ord_flags];

type  tSetOrdDecoder      = class (tDecoder)
      private
       fDecoder           : tCommonBufDecoder;
       fSetOrderProc      : tSetOrderProc;
       fOrder             : tOrder;
       fStatus            : fld_ord_set;
       fcomment           : ansistring;
      public
       constructor Create (aDecoder: tCommonBufDecoder; aSetOrderProc: tSetOrderProc); reintroduce; virtual;
       function    GetField (FieldNum: longint): PFields; override;
       procedure   StartParse; override;
       function    RecUpdated: longint; override;
       function    UpdateValue (Code: longint; Buffer: pAnsiChar): longint; override;
      end;

// --------------------------------------------

const fieldStopOrderCount = 13;

const fldr_stop_trs       = 1;    fldr_stop_stock_id  = 2;
      fldr_stop_level     = 3;    fldr_stop_code      = 4;
      fldr_stop_buysell   = 5;    fldr_stop_price     = 6;
      fldr_stop_quantity  = 7;    fldr_stop_account   = 8;
      fldr_stop_flags     = 9;    fldr_stop_stoptype  = 10;
      fldr_stop_stopprice = 11;   fldr_stop_expire    = 12;
      fldr_stop_comment   = 13;

const StopFields          : array[0..fieldStopOrderCount-1] of tFields = (
      (code: fldr_ord_trs;        field: fld_Trs_ID),
      (code: fldr_ord_stock_id;   field: fld_Stock_ID),
      (code: fldr_ord_level;      field: fld_Level),
      (code: fldr_ord_code;       field: fld_Code),
      (code: fldr_ord_buysell;    field: fld_BuySell),
      (code: fldr_ord_price;      field: fld_Price),
      (code: fldr_ord_quantity;   field: fld_Quantity),
      (code: fldr_ord_account;    field: fld_Account),
      (code: fldr_ord_flags;      field: fld_Flags),
      (code: fldr_stop_stoptype;  field: fld_StopType),
      (code: fldr_stop_stopprice; field: fld_StopPrice),
      (code: fldr_stop_expire;    field: fld_ExpireDate),
      (code: fldr_stop_comment;   field: fld_Comment));

type  fld_stop_fields     = (flds_stop_trs, flds_stop_stock_id, flds_stop_level, flds_stop_code, flds_stop_buysell,
                             flds_stop_price, flds_stop_quantity, flds_stop_account, flds_stop_flags, flds_stop_stoptype,
                             flds_stop_stopprice, flds_stop_expire, flds_stop_comment);
      fld_stop_set        = set of fld_stop_fields;

const all_stop_fields     : fld_stop_set = [flds_stop_trs, flds_stop_stock_id, flds_stop_level, flds_stop_code, flds_stop_buysell,
                                            flds_stop_price, flds_stop_quantity, flds_stop_account, flds_stop_flags, flds_stop_stoptype,
                                            flds_stop_stopprice, flds_stop_expire];

type  tSetStopOrdDecoder  = class (tDecoder)
      private
       fDecoder           : tCommonBufDecoder;
       fSetStopOrderProc  : tSetStopOrderProc;
       fStopOrder         : tStopOrder;
       fStatus            : fld_stop_set;
       fComment           : ansistring;
      public
       constructor Create (aDecoder: tCommonBufDecoder; aSetStopOrderProc: tSetStopOrderProc); reintroduce; virtual;
       function    GetField (FieldNum: longint): PFields; override;
       function    RecUpdated: longint; override;
       function    UpdateValue (Code: longint; Buffer: pAnsiChar): longint; override;
      end;

// --------------------------------------------

const fieldRepQueryCount  = 3;

const fldr_rep_account    = 1;    fldr_rep_sdate      = 2;
      fldr_rep_fdate      = 3;

const RepFields           : array[0..fieldRepQueryCount-1] of tFields = (
      (code: fldr_rep_account;    field: fld_Account),
      (code: fldr_rep_sdate;      field: fld_StartDate),
      (code: fldr_rep_fdate;      field: fld_FinDate));


type  fld_rep_fields      = (flds_rep_account, flds_rep_sdate, flds_rep_fdate);
      fld_rep_set         = set of fld_rep_fields;

const all_rep_fields      : fld_rep_set = [flds_rep_account, flds_rep_sdate, flds_rep_fdate];

type  tReportQueryDecoder = class (tDecoder)
      private
       fDecoder           : tCommonBufDecoder;
       fReportQueryProc   : tReportQueryProc;
       fReportQuery       : tReportQuery;
       fStatus            : fld_rep_set;
      public
       constructor Create (aDecoder: tCommonBufDecoder; aReportQueryProc: tReportQueryProc); reintroduce; virtual;
       function    GetField (FieldNum: longint): PFields; override;
       function    RecUpdated: longint; override;
       function    UpdateValue (Code: longint; Buffer: pAnsiChar): longint; override;
      end;

// --------------------------------------------

const fieldMsgCount       = 1;

const fldr_msg_text       = 1;

const MsgFields           : array[0..fieldMsgCount-1] of tFields = (
      (code: fldr_msg_text;       field: fld_Message));

type  tMessagesDecoder    = class (tDecoder)
      private
       fDecoder           : tCommonBufDecoder;
       fSendMessageProc   : tSendMessageProc;
       fMessage           : ansistring;
       fCanSend           : boolean;
      public
       constructor Create (aDecoder: tCommonBufDecoder; aSendMessageProc: tSendMessageProc); reintroduce; virtual;
       function    GetField (FieldNum: longint): PFields; override;
       function    RecUpdated: longint; override;
       function    UpdateValue (Code: longint; Buffer: pAnsiChar): longint; override;
      end;

// --------------------------------------------

const fieldPingCount      = 1;

const fldr_ping_id        = 1;

const PingFields          : array[0..fieldPingCount-1] of tFields = (
      (code: fldr_ping_id;        field: fld_Trs_ID));

type  tPingDecoder        = class (tDecoder)
      private
       fDecoder           : tCommonBufDecoder;
       fSendPingProc      : tSendPingProc;
       id                 : longint;
      public
       constructor Create (aDecoder: tCommonBufDecoder; aSendPingProc: tSendPingProc); reintroduce; virtual;
       function    GetField (FieldNum: longint): PFields; override;
       function    RecUpdated: longint; override;
       function    UpdateValue (Code: longint; Buffer: pAnsiChar): longint; override;
       procedure   EndParse (var ParseErrorCode: longint); override;
      end;

// --------------------------------------------

const fieldATrdQueryCount = 4;

const fldr_atrd_add       = 1;    fldr_atrd_stock_id  = 2;
      fldr_atrd_level     = 3;    fldr_atrd_tradeno   = 4;

const ATrdFields          : array[0..fieldATrdQueryCount-1] of tFields = (
      (code: fldr_atrd_add;       field: fld_Type),
      (code: fldr_atrd_stock_id;  field: fld_Stock_ID),
      (code: fldr_atrd_level;     field: fld_Level),
      (code: fldr_atrd_tradeno;   field: fld_TradeNo));

type  fld_atrd_fields     = (flds_atrd_type, flds_atrd_stock_id, flds_atrd_level, flds_atrd_tradeno);
      fld_atrd_set        = set of fld_atrd_fields;

const all_atrd_fields     : fld_atrd_set = [flds_atrd_type, flds_atrd_stock_id, flds_atrd_level, flds_atrd_tradeno];

type  tATrdQueryDecoder   = class (tDecoder)
      private
       fDecoder           : tCommonBufDecoder;
       fSendAllAllTrdProc : tSendAllAllTrdProc;
       fatrdadd           : byte;
       fatrdboardid       : tBoardIdent;
       fatrdtradeno       : int64;
       fStatus            : fld_atrd_set;
      public
       constructor Create (aDecoder: tCommonBufDecoder; aSendAllAllTrdProc: tSendAllAllTrdProc); reintroduce; virtual;
       function    GetField (FieldNum: longint): PFields; override;
       function    RecUpdated: longint; override;
       function    UpdateValue (Code: longint; Buffer: pAnsiChar): longint; override;
      end;

// --------------------------------------------

const fieldTrdQueryCount  = 4;

const fldr_trd_account    = 1;    fldr_trd_stock_id   = 2;
      fldr_trd_code       = 3;    fldr_trd_quantity   = 4;

const TrdFields           : array[0..fieldTrdQueryCount-1] of tFields = (
      (code: fldr_trd_account;    field: fld_Account),
      (code: fldr_trd_stock_id;   field: fld_Stock_ID),
      (code: fldr_trd_code;       field: fld_Code),
      (code: fldr_trd_quantity;   field: fld_Quantity));

type  fld_trd_fields      = (flds_trd_account, flds_trd_stock_id, flds_trd_code, flds_trd_quantity);
      fld_trd_set         = set of fld_trd_fields;

const all_trd_fields      : fld_trd_set = [flds_trd_account, flds_trd_stock_id, flds_trd_code, flds_trd_quantity];

type  tTrdQueryDecoder    = class (tDecoder)
      private
       fDecoder           : tCommonBufDecoder;
       fSendTradesProc    : tSendTradesProc;
       faccount           : tAccount;
       fstock_id          : longint;
       fcode              : tCode;
       fquantity          : longint;
       fStatus            : fld_trd_set;
      public
       constructor Create (aDecoder: tCommonBufDecoder; aSendTradesProc: tSendTradesProc); reintroduce; virtual;
       function    GetField (FieldNum: longint): PFields; override;
       function    RecUpdated: longint; override;
       function    UpdateValue (Code: longint; Buffer: pAnsiChar): longint; override;
      end;

// --------------------------------------------

const fieldDOrdCount      = 4;

const fldr_dord_trs       = 1;    fldr_dord_stock_id  = 2;
      fldr_dord_flags     = 3;    fldr_dord_orderno   = 4;

const DOrdFields          : array[0..fieldDOrdCount-1] of tFields = (
      (code: fldr_dord_trs;       field: fld_Trs_ID),
      (code: fldr_dord_stock_id;  field: fld_Stock_ID),
      (code: fldr_dord_flags;     field: fld_Flags),
      (code: fldr_dord_orderno;   field: fld_OrderNo));

type  fld_dord_fields     = (flds_dord_trs, flds_dord_stock_id, flds_dord_flags, flds_dord_orderno);
      fld_dord_set        = set of fld_dord_fields;

const all_dord_fields     = [flds_dord_trs, flds_dord_stock_id, flds_dord_flags];

type  tDropOrderDecoder   = class (tDecoder)
       fDecoder           : tCommonBufDecoder;
       fDropOrderProc     : tDropOrderProc;
       fdroporder         : tDropOrder;
       fStatus            : fld_dord_set;
      public
       constructor Create (aDecoder: tCommonBufDecoder; aDropOrderProc: tDropOrderProc); reintroduce; virtual;
       function    GetField (FieldNum: longint): PFields; override;
       procedure   StartParse; override;
       function    RecUpdated: longint; override;
       function    UpdateValue (Code: longint; Buffer: pAnsiChar): longint; override;
       procedure   EndParse (var ParseErrorCode: longint); override;
      end;

// --------------------------------------------

const fieldTrsCount       = 1;

const fldr_trs_trs        = 1;

const TrsFields           : array[0..fieldTrsCount-1] of tFields = (
      (code: fldr_trs_trs;        field: fld_Trs_ID));

type  tTrsQueryDecoder    = class (tDecoder)
      private
       fDecoder           : tCommonBufDecoder;
       fTrsQueryProc      : tTrsQueryProc;
       fTrsList           : array of int64;
       fTrsCount          : longint;
      public
       constructor Create (aDecoder: tCommonBufDecoder; aTrsQueryProc: tTrsQueryProc); reintroduce; virtual;
       function    GetField (FieldNum: longint): PFields; override;
       procedure   StartParse; override;
       function    RecUpdated: longint; override;
       function    UpdateValue (Code: longint; Buffer: pAnsiChar): longint; override;
       procedure   EndParse (var ParseErrorCode: longint); override;
      end;

// --------------------------------------------

const fieldNewsCount      = 3;

const fldr_news_id        = 1;    fldr_news_time      = 2;
      fldr_query_type     = 3;

const NewsFields          : array[0..fieldNewsCount-1] of tFields = (
      (code: fldr_news_id;        field: fld_News_ID),
      (code: fldr_news_time;      field: fld_Time),
      (code: fldr_query_type;     field: fld_NewsQryType));

type  tNewsQueryDecoder   = class (tDecoder)
      private
       fDecoder           : tCommonBufDecoder;
       fNewsQueryProc     : tNewsQueryProc;
       fid, fqt           : longint;
       fdt                : tdatetime;
      public
       constructor Create (aDecoder: tCommonBufDecoder; aNewsQueryProc: tNewsQueryProc); reintroduce; virtual;
       function    GetField (FieldNum: longint): PFields; override;
       procedure   StartParse; override;
       function    RecUpdated: longint; override;
       function    UpdateValue (Code: longint; Buffer: pAnsiChar): longint; override;
      end;

// --------------------------------------------

const  fieldMoveOrdCount  = 10;

const  fldr_mov_trs       = 1;    fldr_mov_stock_id  = 2;
       fldr_mov_level     = 3;    fldr_mov_code      = 4;
       fldr_mov_orderno   = 5;    fldr_mov_price     = 6;
       fldr_mov_quantity  = 7;    fldr_mov_account   = 8;
       fldr_mov_flags     = 9;    fldr_mov_cid       = 10;

const  MoveOrderFields    : array[0..fieldMoveOrdCount - 1] of tFields = (
       (code: fldr_mov_trs;      field: fld_Trs_ID),
       (code: fldr_mov_stock_id; field: fld_Stock_ID),
       (code: fldr_mov_level;    field: fld_Level),
       (code: fldr_mov_code;     field: fld_Code),
       (code: fldr_mov_orderno;  field: fld_OrderNo),
       (code: fldr_mov_price;    field: fld_Price),
       (code: fldr_mov_quantity; field: fld_Quantity),
       (code: fldr_mov_account;  field: fld_Account),
       (code: fldr_mov_flags;    field: fld_Flags),
       (code: fldr_mov_cid;      field: fld_ClientID));

type  tMoveOrderDecoder   = class (tDecoder)
      private
       fDecoder           : tCommonBufDecoder;
       fMoveOrderProc     : tMoveOrderProc;
       fmoveorder         : tMoveOrder;
      public
       constructor Create (aDecoder: tCommonBufDecoder; aMoveOrderProc: tMoveOrderProc); reintroduce; virtual;
       function    GetField (FieldNum: longint): PFields; override;
       procedure   StartParse; override;
       function    RecUpdated: longint; override;
       function    UpdateValue (Code: longint; Buffer: pAnsiChar): longint; override;
      end;

// --------------------------------------------

type  tNewBufDecoder      = class (tCommonBufDecoder)
      protected
       procedure   SetSendKotirovkiProc (aSendKotirovkiProc: tSendKotirovkiProc); override;
       procedure   SetSetOrderProc (aSetOrderProc: tSetOrderProc); override;
       procedure   SetSetStopOrderProc (aSetStopOrderProc: tSetStopOrderProc); override;
       procedure   SetDropOrderProc (aDropOrderProc: tDropOrderProc); override;
       procedure   SetReportQueryProc (aReportQueryProc: tReportQueryProc); override;
       procedure   SetSendTradesProc (aSendTradesProc: tSendTradesProc); override;
       procedure   SetSendAllAllTrdProc (aSendAllAllTrdProc: tSendAllAllTrdProc); override;
       procedure   SetSendMessageProc (aSendMessageProc: tSendMessageProc); override;
       procedure   SetTrsQueryProc (aTrsQueryProc: tTrsQueryProc); override;
       procedure   SetSendPingProc (aSendPingProc: tSendPingProc); override;
       procedure   SetNewsQueryProc (aNewsQueryProc: tNewsQueryProc); override;
       procedure   SetMoveOrderProc (aMoveOrderProc: tMoveOrderProc); override;
      public
       function    ParseBuffer (Buffer: pAnsiChar; BufLen: longint): longint; override;
      end;

implementation

uses terminal_common;

procedure tCommonBufDecoder.SetDropOrderProc;     begin fDropOrderProc:= aDropOrderProc; end;
procedure tCommonBufDecoder.SetReportQueryProc;   begin fReportQueryProc:= aReportQueryProc; end;
procedure tCommonBufDecoder.SetSendAllAllTrdProc; begin fSendAllAllTrdProc:= aSendAllAllTrdProc; end;
procedure tCommonBufDecoder.SetSendKotirovkiProc; begin fSendKotirovkiProc:= aSendKotirovkiProc; end;
procedure tCommonBufDecoder.SetSendMessageProc;   begin fSendMessageProc:= aSendMessageProc; end;
procedure tCommonBufDecoder.SetSendPingProc;      begin fSendPingProc:= aSendPingProc; end;
procedure tCommonBufDecoder.SetSendTradesProc;    begin fSendTradesProc:= aSendTradesProc; end;
procedure tCommonBufDecoder.SetSetOrderProc;      begin fSetOrderProc:= aSetOrderProc; end;
procedure tCommonBufDecoder.SetSetStopOrderProc;  begin fSetStopOrderProc:= aSetStopOrderProc; end;
procedure tCommonBufDecoder.SetTrsQueryProc;      begin fTrsQueryProc:= aTrsQueryProc; end;
procedure tCommonBufDecoder.SetNewsQueryProc;     begin fNewsQueryProc:= aNewsQueryProc; end;
procedure tCommonBufDecoder.SetMoveOrderProc;     begin fMoveOrderProc:= aMoveOrderProc; end;

// -------------------------------------------------------------------

function tOldBufDecoder.ParseBuffer;
var msgtext : ansistring;
    i       : longint;
begin
 result:= ps_OK;
 with hdr do
  case tableid of
   idClientQuery  : if assigned(buffer) and (datasize >= sizeof(tClientQuery)) then begin
                     with pClientQuery(buffer)^ do
                      case msgid of
                       msgKot         : if assigned(fSendKotirovkiProc) then fSendKotirovkiProc(add, SecId);
                       msgSetOrd      : if (hdr.flags and pfEncrypted > 0) then begin
                                         if assigned(fSetOrderProc) then fSetOrderProc(setorder, '');
                                        end else begin
                                         currenttrs:= setorder.transaction;
                                         result:= ps_ERR_NOTENCRYPTED;
                                        end;
                       msgEditOrd     : result:= ps_ERR_UNSUPPORTED;
                       msgDropOrd     : if (hdr.flags and pfEncrypted > 0) then begin
                                         if assigned(fDropOrderProc) then fDropOrderProc(droporder);
                                        end else begin
                                         currenttrs:= droporder.transaction;
                                         result:= ps_ERR_NOTENCRYPTED;
                                        end;
                       msgQueryReport : if assigned(fReportQueryProc)   then fReportQueryProc(ReportQuery);
                       msgQueryTrades : if assigned(fSendTradesProc)    then with TradesQuery do fSendTradesProc(account, stock_id, code, quantity);
                       msgAllTradesReq: if assigned(fSendAllAllTrdProc) then fSendAllAllTrdProc(atrdadd, atrdboardid, atrdtradeno);
                       else             log('Unsupported client query id');
                      end;
                    end else result:= ps_ERR_BUFLEN;
   idStopOrder    : if assigned(buffer) and (datasize >= sizeof(tStopOrder)) then begin
                     if (hdr.flags and pfEncrypted > 0) then begin
                      if assigned(fSetStopOrderProc) then fSetStopOrderProc(pStopOrder(buffer)^, '');
                     end else begin
                      currenttrs:= pStopOrder(buffer)^.order.transaction;
                      result:= ps_ERR_NOTENCRYPTED;
                     end;
                    end else result:= ps_ERR_BUFLEN;
   idMessage      : if assigned(buffer) and (datasize > 0) and assigned(fSendMessageProc) then begin
                     i:=0; setlength(msgtext, datasize);
                     while (i < datasize) and (buffer[i] <> #0) do begin msgtext[i+1]:=buffer[i]; inc(i); end;
                     setlength(msgtext, i);
                     fSendMessageProc(msgtext, (hdr.flags and pfEncrypted > 0));
                    end;
   idTrsQuery     : if assigned(buffer) and (datasize >= rowcount*sizeof(int64)) then begin
                     if assigned(fTrsQueryProc) then fTrsQueryProc(rowcount, pTrsQuery(buffer));
                    end else result:= ps_ERR_BUFLEN;
   idPing         : if assigned(fSendPingProc) then fSendPingProc(0);
  end;
end;

// -------------------------------------------------------------------

constructor tKotQueryDecoder.Create;
begin inherited create(fieldKotCount); fDecoder:= aDecoder; fSendKotirovkiProc:= aSendKotirovkiProc; fStatus:= []; end;

function tKotQueryDecoder.GetField; begin result:= @KotFields[FieldNum]; end;

function tKotQueryDecoder.RecUpdated;
begin
 fDecoder.currenttrs:= 0;
 if assigned(fSendKotirovkiProc) and (fStatus = all_kot_fields) then begin
  fSendKotirovkiProc(fAdd, fSecId);
  result:= ps_OK;
 end else result:= ps_ERR_UNCOMPLETE;
 fStatus:= [];
end;

function tKotQueryDecoder.UpdateValue;
begin
  result:= -1;
  try
   case Code of
    fldr_kot_type      : begin include(fStatus, flds_kot_add); fadd:= _StrToInt (Buffer); end;
    fldr_kot_stock_id  : begin include(fStatus, flds_kot_stock_id); fSecId.stock_id:= _StrToInt (Buffer); end;
    fldr_kot_level     : begin include(fStatus, flds_kot_level); fSecId.level:= Buffer; end;
    fldr_kot_code      : begin include(fStatus, flds_kot_code); fSecId.code:= Buffer; end;
   end;
   result:= Length (Buffer);
  except on e: exception do log('KOTPARSE: position: %d code: %d exception: %s', [position, code, e.message]); end;
end;

// -------------------------------------------------------------------

constructor tSetOrdDecoder.Create;
begin inherited create(fieldOrderCount); fDecoder:= aDecoder; fSetOrderProc:= aSetOrderProc; fStatus:= []; end;

function tSetOrdDecoder.GetField; begin result:= @OrdFields[FieldNum]; end;

function tSetOrdDecoder.RecUpdated;
begin
  try
    if (flds_ord_trs in fStatus) then fDecoder.currenttrs:= forder.transaction else fDecoder.currenttrs:= 0;
    if not (flds_ord_comment in fStatus) then setlength(fcomment, 0);
    if assigned(fSetOrderProc) and (fStatus >= all_ord_fields) then begin
      if (fDecoder.hdr.flags and pfEncrypted <> 0) then begin
        if not (flds_ord_client_id in fStatus) then setlength(fOrder.cid, 0);
       fSetOrderProc(fOrder, fcomment);
        result:= ps_OK;
      end else result:= ps_ERR_NOTENCRYPTED;
    end else result:= ps_ERR_UNCOMPLETE;
  finally
    fillchar(fOrder, sizeof(fOrder), 0);
    fStatus:= [];
  end;
end;

procedure tSetOrdDecoder.StartParse;
begin fillchar(fOrder, sizeof(fOrder), 0); fStatus:= []; end;

function tSetOrdDecoder.UpdateValue;
begin
  result:= -1;
  try
   case Code of
    fldr_ord_trs        : begin include(fStatus, flds_ord_trs);        forder.transaction:= _StrToInt64(Buffer); end;
    fldr_ord_stock_id   : begin include(fStatus, flds_ord_stock_id);   forder.stock_id:= _StrToInt(Buffer);      end;
    fldr_ord_level      : begin include(fStatus, flds_ord_level);      forder.level:= Buffer;                    end;
    fldr_ord_code       : begin include(fStatus, flds_ord_code);       forder.code:= Buffer;                     end;
    fldr_ord_buysell    : if length(Buffer) > 0 then begin
                                include(fStatus, flds_ord_buysell);    forder.buysell:= Buffer[0];
                          end;
    fldr_ord_price      : begin include(fStatus, flds_ord_price);      forder.price:= _StrToFloat(Buffer);       end;
    fldr_ord_quantity   : begin include(fStatus, flds_ord_quantity);   forder.quantity:= _StrToInt(Buffer);      end;
    fldr_ord_account    : begin include(fStatus, flds_ord_account);    forder.account:= Buffer;                  end;
    fldr_ord_flags      : begin include(fStatus, flds_ord_flags);      forder.flags:= _StrToInt(Buffer);         end;
    fldr_ord_comment    : begin include(fStatus, flds_ord_comment);    fcomment:= Buffer;                        end;
    fldr_ord_client_id  : begin include(fStatus, flds_ord_client_id);  forder.cid:= Buffer;                      end;
    fldr_ord_cfirmid    : begin include(fStatus, flds_ord_cfirmid);    forder.cfirmid:= Buffer;                  end;
    fldr_ord_match      : begin include(fStatus, flds_ord_match);      forder.match:= Buffer;                    end;
    fldr_ord_settle     : begin include(fStatus, flds_ord_settle);     forder.settlecode:= Buffer;               end;
    fldr_ord_refundrate : begin include(fStatus, flds_ord_refundrate); forder.refundrate:= _StrToFloat(Buffer);  end;
    fldr_ord_reporate   : begin include(fStatus, flds_ord_reporate);   forder.reporate:= _StrToFloat(Buffer);    end;
    fldr_ord_price2     : begin include(fStatus, flds_ord_price2);     forder.price2:= _StrToFloat(Buffer);      end;
   end;
   result:= Length (Buffer);
  except on e: exception do log('ORDERPARSE: position: %d code: %d exception: %s', [position, code, e.message]); end;
end;

// -------------------------------------------------------------------

constructor tSetStopOrdDecoder.Create;
begin inherited create(fieldStopOrderCount); fDecoder:= aDecoder; fSetStopOrderProc:= aSetStopOrderProc; fStatus:= []; end;

function tSetStopOrdDecoder.GetField; begin result:= @StopFields[FieldNum]; end;

function tSetStopOrdDecoder.RecUpdated;
begin
  try
    if (flds_stop_trs in fStatus) then fDecoder.currenttrs:= fstoporder.order.transaction else fDecoder.currenttrs:= 0;
    if not (flds_stop_comment in fStatus) then setlength(fcomment, 0);
    if assigned(fSetStopOrderProc) and (fStatus >= all_stop_fields) then begin
      if (fDecoder.hdr.flags and pfEncrypted <> 0) then begin
        fSetStopOrderProc(fStopOrder, fcomment);
        result:= ps_OK;
      end else result:= ps_ERR_NOTENCRYPTED;
    end else result:= ps_ERR_UNCOMPLETE;
  finally
    fillchar(fStopOrder, sizeof(fStopOrder), 0);
    fStatus:= [];
  end;
end;

function tSetStopOrdDecoder.UpdateValue;
begin
  result:= -1;
  try
   case Code of
    fldr_stop_trs      : begin include(fStatus, flds_stop_trs); fstoporder.order.transaction:= _StrToInt64(Buffer); end;
    fldr_stop_stock_id : begin include(fStatus, flds_stop_stock_id); fstoporder.order.stock_id:= _StrToInt(Buffer); end;
    fldr_stop_level    : begin include(fStatus, flds_stop_level); fstoporder.order.level:= Buffer; end;
    fldr_stop_code     : begin include(fStatus, flds_stop_code); fstoporder.order.code:= Buffer; end;
    fldr_stop_buysell  : if length(Buffer) > 0 then begin include(fStatus, flds_stop_buysell); fstoporder.order.buysell:= Buffer[0]; end;
    fldr_stop_price    : begin include(fStatus, flds_stop_price); fstoporder.order.price:= _StrToFloat(Buffer); end;
    fldr_stop_quantity : begin include(fStatus, flds_stop_quantity); fstoporder.order.quantity:= _StrToInt(Buffer); end;
    fldr_stop_account  : begin include(fStatus, flds_stop_account); fstoporder.order.account:= Buffer; end;
    fldr_stop_flags    : begin include(fStatus, flds_stop_flags); fstoporder.order.flags:= _StrToInt(Buffer); end;
    fldr_stop_stoptype : begin include(fStatus, flds_stop_stoptype); fstoporder.stoptype:= _StrToInt(Buffer); end;
    fldr_stop_stopprice: begin include(fStatus, flds_stop_stopprice); fstoporder.stopprice:= _StrToFloat(Buffer); end;
    fldr_stop_expire   : begin include(fStatus, flds_stop_expire); fstoporder.expiredatetime:= _StrToDateTime(Buffer); end;
    fldr_stop_comment  : begin include(fStatus, flds_stop_comment); fcomment:= Buffer; end;
   end;
   result:= Length (Buffer);
  except on e: exception do log('STOPORDERPARSE: position: %d code: %d exception: %s', [position, code, e.message]); end;
end;

// -------------------------------------------------------------------

constructor tReportQueryDecoder.Create;
begin inherited create(fieldRepQueryCount); fDecoder:= aDecoder; fReportQueryProc:= aReportQueryProc; fStatus:= []; end;

function tReportQueryDecoder.GetField; begin result:= @RepFields[FieldNum]; end;

function tReportQueryDecoder.RecUpdated;
begin
 fDecoder.currenttrs:= 0;
 if assigned(fReportQueryProc) and (fStatus = all_rep_fields) then begin
  fReportQueryProc(fReportQuery);
  result:= ps_OK;
 end else result:= ps_ERR_UNCOMPLETE;
 fStatus:= [];
end;

function tReportQueryDecoder.UpdateValue;
begin
  result:= -1;
  try
   case Code of
    fldr_rep_account   : begin include(fStatus, flds_rep_account); fReportQuery.account:= Buffer; end;
    fldr_rep_sdate     : begin include(fStatus, flds_rep_sdate); fReportQuery.sdate:= _StrToDateTime(Buffer); end;
    fldr_rep_fdate     : begin include(fStatus, flds_rep_fdate); fReportQuery.fdate:= _StrToDateTime(Buffer); end;
   end;
   result:= Length (Buffer);
  except on e: exception do log('REPQUERYPARSE: position: %d code: %d exception: %s', [position, code, e.message]); end;
end;

// -------------------------------------------------------------------

constructor tMessagesDecoder.Create;
begin inherited create(fieldMsgCount); fDecoder:= aDecoder; fSendMessageProc:= aSendMessageProc; fCanSend:= false; end;

function tMessagesDecoder.GetField; begin result:= @MsgFields[FieldNum]; end;

function tMessagesDecoder.RecUpdated;
begin
 fDecoder.currenttrs:= 0;
 if assigned(fSendMessageProc) and fCanSend then begin
  fSendMessageProc(fMessage, false);
  result:= ps_OK;
 end else result:= ps_ERR_UNCOMPLETE;
 fCanSend:= false;
end;

function tMessagesDecoder.UpdateValue;
begin
  result:= -1;
  try
   if assigned(Buffer) then begin
    if code = fldr_msg_text then begin fMessage:= Buffer; fCanSend:= true; end;
    result:= Length (Buffer);
   end else result:= -1; 
  except on e: exception do log('MESSAGEPARSE: position: %d code: %d exception: %s', [position, code, e.message]); end;
end;

// -------------------------------------------------------------------

constructor tPingDecoder.Create;
begin inherited create(fieldPingCount); fDecoder:= aDecoder; fSendPingProc:= aSendPingProc; id:= 0; end;

function tPingDecoder.GetField; begin result:= @PingFields[FieldNum]; end;

function tPingDecoder.RecUpdated;
begin if assigned(fSendPingProc) and (id <> 0) then fSendPingProc(id); result:=ps_OK; end;

procedure tPingDecoder.EndParse;
begin if assigned(fSendPingProc) and (id = 0) then fSendPingProc(id); id:= 0; end;

function tPingDecoder.UpdateValue;
begin
  try
    if assigned(Buffer) then begin
      if code = fldr_ping_id then id:= _StrToInt(Buffer);
      result:= Length(Buffer);
    end else result:= -1;
  except on e: exception do result:= -1; end;
end;

// -------------------------------------------------------------------

constructor tATrdQueryDecoder.Create;
begin inherited create(fieldATrdQueryCount); fDecoder:= aDecoder; fSendAllAllTrdProc:= aSendAllAllTrdProc; fStatus:= []; end;

function tATrdQueryDecoder.GetField; begin result:= @ATrdFields[FieldNum]; end;

function tATrdQueryDecoder.RecUpdated;
begin
 fDecoder.currenttrs:= 0;
 if assigned(fSendAllAllTrdProc) and (fStatus = all_atrd_fields) then begin
  fSendAllAllTrdProc(fatrdadd, fatrdboardid, fatrdtradeno);
   result:= ps_OK;
 end else result:= ps_ERR_UNCOMPLETE;
 fStatus:= [];
end;

function tATrdQueryDecoder.UpdateValue;
begin
  result:= -1;
  try
   case Code of
    fldr_atrd_add      : begin include(fStatus, flds_atrd_type); fatrdadd:= _StrToInt(Buffer); end;
    fldr_atrd_stock_id : begin include(fStatus, flds_atrd_stock_id); fatrdboardid.stock_id:= _StrToInt(Buffer); end;
    fldr_atrd_level    : begin include(fStatus, flds_atrd_level); fatrdboardid.level:= Buffer; end;
    fldr_atrd_tradeno  : begin include(fStatus, flds_atrd_tradeno); fatrdtradeno:= _StrToInt64(Buffer); end;
   end;
   result:= Length (Buffer);
  except on e: exception do log('ATRDQUERYPARSE: position: %d code: %d exception: %s', [position, code, e.message]); end;
end;

// -------------------------------------------------------------------

constructor tTrdQueryDecoder.Create;
begin inherited create(fieldTrdQueryCount); fDecoder:= aDecoder; fSendTradesProc:= aSendTradesProc; fStatus:= []; end;

function tTrdQueryDecoder.GetField; begin result:= @TrdFields[FieldNum]; end;

function tTrdQueryDecoder.RecUpdated;
begin
 fDecoder.currenttrs:= 0;
 if assigned(fSendTradesProc) and (fStatus = all_trd_fields) then begin
  fSendTradesProc(faccount, fstock_id, fcode, fquantity);
  result:= ps_OK;
 end else result:= ps_ERR_UNCOMPLETE;
 fStatus:= [];
end;

function tTrdQueryDecoder.UpdateValue;
begin
  result:= -1;
  try
   case Code of
    fldr_trd_account   : begin include(fStatus, flds_trd_account); faccount:= Buffer; end;
    fldr_trd_stock_id  : begin include(fStatus, flds_trd_stock_id); fstock_id:= _StrToInt(Buffer); end;
    fldr_trd_code      : begin include(fStatus, flds_trd_code); fcode:= Buffer; end;
    fldr_trd_quantity  : begin include(fStatus, flds_trd_quantity); fquantity:= _StrToInt(Buffer); end;
   end;
   result:= Length (Buffer);
  except on e: exception do log('TRDQUERYPARSE: position: %d code: %d exception: %s', [position, code, e.message]); end;
end;

// -------------------------------------------------------------------

constructor tDropOrderDecoder.Create;
begin inherited create(fieldDOrdCount); fDecoder:= aDecoder; fDropOrderProc:= aDropOrderProc; fStatus:= []; end;

function tDropOrderDecoder.GetField;  begin result:= @DOrdFields[FieldNum]; end;
procedure tDropOrderDecoder.StartParse; begin fDecoder.currenttrs:= 0; fStatus:= []; fdroporder.count:= 0; end;
function tDropOrderDecoder.RecUpdated; begin result:= ps_OK; end;

function tDropOrderDecoder.UpdateValue;
begin
  result:= -1;
  try
   case Code of
    fldr_dord_trs      : with fdroporder do begin include(fStatus, flds_dord_trs); transaction:= _StrToInt64(Buffer); fDecoder.currenttrs:= transaction; end;
    fldr_dord_stock_id : begin include(fStatus, flds_dord_stock_id); fdroporder.stock_id:= _StrToInt(Buffer); end;
    fldr_dord_flags    : begin include(fStatus, flds_dord_flags); fdroporder.dropflags:=_StrToInt(Buffer); end;
    fldr_dord_orderno  : with fdroporder do begin
                          include(fStatus, flds_dord_orderno);
                          if (count < maxDropOrders) then begin inc(count); orders[count]:= _StrToInt64(Buffer); end;
                         end;
   end;
   result:= Length (Buffer);
  except on e: exception do log('DROPORDPARSE: position: %d code: %d exception: %s', [position, code, e.message]); end;
end;

procedure tDropOrderDecoder.EndParse;
begin
 if (ParseErrorCode = ps_OK) then
  if assigned(fDropOrderProc) and (fStatus >= all_dord_fields) then begin
   if (fDecoder.hdr.flags and pfEncrypted <> 0) then fDropOrderProc(fdroporder)
                                                else ParseErrorCode:= ps_ERR_NOTENCRYPTED;
  end else ParseErrorCode:= ps_ERR_UNCOMPLETE;
end;

// -------------------------------------------------------------------

constructor tTrsQueryDecoder.Create;
begin inherited create(fieldTrsCount); fDecoder:= aDecoder; fTrsQueryProc:= aTrsQueryProc; setlength(fTrsList, 10); end;

function tTrsQueryDecoder.GetField;  begin result:= @TrsFields[FieldNum]; end;
procedure tTrsQueryDecoder.StartParse; begin fDecoder.currenttrs:= 0; setlength(fTrsList, 10); fTrsCount:= 0; end;
function tTrsQueryDecoder.RecUpdated; begin result:= ps_OK; end;

function tTrsQueryDecoder.UpdateValue;
begin
  result:= -1;
  try
   if (code = fldr_trs_trs) then begin
    if (length(fTrsList) > fTrsCount) then setlength(fTrsList, length(fTrsList)+10);
    fTrsList[fTrsCount]:= _StrToInt64(Buffer);
    inc(fTrsCount);
   end;
   result:= Length (Buffer);
  except on e: exception do log('TRSQUERYPARSE: position: %d code: %d exception: %s', [position, code, e.message]); end;
end;

procedure tTrsQueryDecoder.EndParse;
begin
 if (ParseErrorCode = ps_OK) then
  if assigned(fTrsQueryProc) and (fTrsCount > 0) then fTrsQueryProc(fTrsCount, @fTrsList[0]) else ParseErrorCode:= ps_ERR_UNCOMPLETE;
end;

// -------------------------------------------------------------------

constructor tNewsQueryDecoder.Create;
begin inherited create(fieldNewsCount); fDecoder:= aDecoder; fNewsQueryProc:= aNewsQueryProc; end;

function tNewsQueryDecoder.GetField;  begin result:= @NewsFields[FieldNum]; end;
procedure tNewsQueryDecoder.StartParse; begin fid:= 0; fqt:= 0; fdt:= now; end;
function tNewsQueryDecoder.RecUpdated;
begin
 result:= ps_OK;
 if assigned(fNewsQueryProc) then fNewsQueryProc(fid, fdt, fqt);
 fid:= 0; fqt:= 0; fdt:= now;
end;

function tNewsQueryDecoder.UpdateValue;
begin
  result:= -1;
  try
   case Code of
    fldr_news_id       : fid:= _StrToInt(Buffer);
    fldr_news_time     : fdt:= _StrToDateTime(Buffer);
    fldr_query_type    : fqt:= _StrToInt(Buffer);
   end;
   result:= Length (Buffer);
  except on e: exception do log('NEWSQUERYPARSE: position: %d code: %d exception: %s', [position, code, e.message]); end;
end;

// -------------------------------------------------------------------

constructor tMoveOrderDecoder.Create(aDecoder: tCommonBufDecoder; aMoveOrderProc: tMoveOrderProc);
begin inherited create(fieldMoveOrdCount); fDecoder:= aDecoder; fMoveOrderProc:= aMoveOrderProc; end;

function tMoveOrderDecoder.GetField(FieldNum: Integer): PFields; begin result:= @MoveOrderFields[FieldNum]; end;
procedure tMoveOrderDecoder.StartParse; begin fillchar(fmoveorder, sizeof(tMoveOrder), 0); end;

function tMoveOrderDecoder.RecUpdated: longint;
begin
 result:= ps_OK;
 if assigned(fMoveOrderProc) then fMoveOrderProc(fmoveorder);
end;

function tMoveOrderDecoder.UpdateValue(Code: longint; Buffer: pAnsiChar): longint;
begin
  result:= -1;
  try
    case Code of
      fldr_mov_trs       : fmoveorder.transaction:= _StrToInt64(Buffer);
      fldr_mov_stock_id  : fmoveorder.stock_id:= _StrToInt(Buffer);
      fldr_mov_level     : fmoveorder.level:= Buffer;
      fldr_mov_code      : fmoveorder.code:= Buffer;
      fldr_mov_orderno   : fmoveorder.orderno:= _StrToInt64(Buffer);
      fldr_mov_price     : fmoveorder.new_price:= _StrToFloat(Buffer);
      fldr_mov_quantity  : fmoveorder.new_quantity:= _StrToInt(Buffer);
      fldr_mov_account   : fmoveorder.account:= Buffer;
      fldr_mov_flags     : fmoveorder.flags:= _StrToInt(Buffer);
      fldr_mov_cid       : fmoveorder.cid:= Buffer;
    end;
    result:= Length (Buffer);
  except on e: exception do log('MOVEORDERPARSE: position: %d code: %d exception: %s', [position, code, e.message]); end;
end;

// -------------------------------------------------------------------

procedure tNewBufDecoder.SetSendKotirovkiProc; begin RegisterDecoder(tbl_KotQuery, tKotQueryDecoder.Create(Self, aSendKotirovkiProc)); end;
procedure tNewBufDecoder.SetSetOrderProc;      begin RegisterDecoder(tbl_SetOrder, tSetOrdDecoder.Create(Self, aSetOrderProc)); end;
procedure tNewBufDecoder.SetSetStopOrderProc;  begin RegisterDecoder(tbl_SetStopOrder, tSetStopOrdDecoder.Create(Self, aSetStopOrderProc)); end;
procedure tNewBufDecoder.SetDropOrderProc;     begin RegisterDecoder(tbl_DropOrder, tDropOrderDecoder.Create(Self, aDropOrderProc)); end;
procedure tNewBufDecoder.SetReportQueryProc;   begin RegisterDecoder(tbl_ReportQuery, tReportQueryDecoder.Create(Self, aReportQueryProc)); end;
procedure tNewBufDecoder.SetSendMessageProc;   begin RegisterDecoder(tbl_UserMessage, tMessagesDecoder.Create(Self, aSendMessageProc)); end;
procedure tNewBufDecoder.SetSendPingProc;      begin RegisterDecoder(tbl_Ping, tPingDecoder.Create(Self, aSendPingProc)); end;
procedure tNewBufDecoder.SetSendTradesProc;    begin RegisterDecoder(tbl_TradesQuery, tTrdQueryDecoder.Create(Self, aSendTradesProc)); end;
procedure tNewBufDecoder.SetSendAllAllTrdProc; begin RegisterDecoder(tbl_AllTradesQuery, tATrdQueryDecoder.Create(Self, aSendAllAllTrdProc)); end;
procedure tNewBufDecoder.SetTrsQueryProc;      begin RegisterDecoder(tbl_TrsQuery,  tTrsQueryDecoder.Create(Self, aTrsQueryProc));  end;
procedure tNewBufDecoder.SetNewsQueryProc;     begin RegisterDecoder(tbl_NewsQuery,  tNewsQueryDecoder.Create(Self, aNewsQueryProc));  end;
procedure tNewBufDecoder.SetMoveOrderProc;     begin RegisterDecoder(tbl_MoveOrder,  tMoveOrderDecoder.Create(Self, aMoveOrderProc));  end;
function  tNewBufDecoder.ParseBuffer;          begin if assigned(buffer) then result:= inherited ParseBuffer(buffer, buflen) else result:= ps_ERR_NULLBUF; end;

end.
