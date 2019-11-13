{$ifdef FPC}
  {$mode DELPHI}
{$endif}

{$ifndef Unix}
  {$define MSWINDOWS}
{$endif}

unit MTETypes;

interface

{$ifdef MSWINDOWS}
uses
  Windows;
{$endif}

type
  TMTEResult = Integer;

const
  // Коды ошибок, возвращаемые функциями MTExxxx
  MTE_OK             = 0;
  MTE_CONFIG         = -1;
  MTE_SRVUNAVAIL     = -2;
  MTE_LOGERROR       = -3;
  MTE_INVALIDCONNECT = -4;
  MTE_NOTCONNECTED   = -5;
  MTE_WRITE          = -6;
  MTE_READ           = -7;
  MTE_TSMR           = -8;
  MTE_NOMEMORY       = -9;
  MTE_ZLIB           = -10;
  MTE_PKTINPROGRESS  = -11;
  MTE_PKTNOTSTARTED  = -12;
  MTE_FATALERROR		 = -13; // new CMA error code, previously was MTE_LOGON for TEServer
  MTE_INVALIDHANDLE  = -14;
  MTE_DSROFF         = -15;
  MTE_UNKNOWN        = -16;
  MTE_BADPTR         = -17;
  MTE_WRONGPARAM		 = -17; // CMA synonim for MTE_BADPTR
  MTE_TRANSREJECTED  = -18;
  MTE_REJECTION		   = -18; // CMA synonim for MTE_TRANSREJECTED
  // CMA error codes
  MTE_TEUNAVAIL		   = -19; // new CMA error code, previously was MTE_TOOSLOWCONNECT for TEServer
  MTE_NOTLOGGEDIN    = -20; // new CMA error code, previously was MTE_CRYPTO_ERROR for TEServer
  MTE_WRONGVERSION   = -21; // new CMA error code, previously was MTE_THREAD_ERROR for TEServer
  // MICEX Bridge errors again
  MTE_LOGON          = -30; // previously was -13, changed for CMA compatibility
  MTE_TOOSLOWCONNECT = -31; // previously was -19, changed for CMA compatibility
  MTE_CRYPTO_ERROR   = -32; // previously was -20, changed for CMA compatibility
  MTE_THREAD_ERROR   = -33; // previously was -21, changed for CMA compatibility
  MTE_NOTIMPLEMENTED = -34;
  MTE_ABANDONED      = -35; // MTExxx() call was interrupted by asynchronous MTEDisconnect()

  // do not forget to modify MTE_LAST_ERROR when new error codes added!!!
  MTE_LAST_ERROR     = MTE_ABANDONED;

const
  // Атрибуты входных и выходных полей
  ffKey       = $01;              // Ключевое поле
  ffSecCode   = $02;              // Поле содержит код инструмента
  ffNotNull   = $04;              // Поле не может быть пустым
  ffVarBlock  = $08;              // Поле входит в группу полей, которые могут повторяться несколько раз
  ffSharp     = $80;              // empty value can be encoded as sharp (#)

  ffFixedMask = $30;
  ffFixed1    = $10;              // Модификатор для поля типа fiFixed: Decimals должно быть 1, а не 2
  ffFixed3    = $20;              // Модификатор для поля типа fiFixed: Decimals должно быть 3, а не 2
  ffFixed4    = $30;              // Модификатор для поля типа fiFixed: Decimals должно быть 4, а не 2

  // Атрибуты таблиц
  tfUpdateable    = $01;          // Обновляемая
  tfClearOnUpdate = $02;          // Очищать при обновлении
  tfOrderBook     = $04;          // Таблица типа "котировки"

type
  TTEFieldType = (ftChar, ftInteger, ftFixed, ftFloat, ftDate, ftTime);
  TTEEnumKind = (ekCheck, ekGroup, ekCombo);

type
  PMTEErrorMsg = ^TMTEErrorMsg;
  TMTEErrorMsg = array [0..255] of AnsiChar;
  TServerName = array [0..63] of AnsiChar;

  PMTEMsg = ^TMTEMsg;
  TMTEMsg = record
    DataLen: Longword;
    Data: record end;
  end;

  PMTERow = ^TMTERow;
  TMTERow = packed record
    FldCount: Byte;
    RowLen: Integer;
    RowData: record end;
  end;

  PMTETable = ^TMTETable;
  TMTETable = packed record
    Ref: Integer;
    RowCount: Integer;
    TblData: TMTERow;
  end;

  PMTETables = ^TMTETables;
  TMTETables = packed record
    TblCount: Integer;
    Tables: TMTETable;
  end;

  {$ifdef MSWINDOWS}
  TMTEMemBlk =  record
    len: Longint;              {*< размер буфера }
    buf: Pointer;              {*< буфер }
  end;
  PMTEMemBlk = ^TMTEMemBlk;

  TMTECertAltName = packed record
    Subject: PAnsiChar;
    OrganizationName: PAnsiChar;    {*< Наименование организации (WIN1251). }
    Surname: PAnsiChar;             {*< Ф.И.О владельца сертификата (WIN1251). }
    Description: PAnsiChar;         {*< Описание. }
  end;

  PMTEConnCertificate = ^TMTEConnCertificate;
  TMTEConnCertificate = packed record
    Owner,
    Issuer: TMTECertAltName;
    ValidFrom,
    ValidTo: TSystemTime;
    PrivateValidFrom: TSystemTime;
    PrivateValidTo: TSystemTime;
    CertType: Integer;    // one of CERTTYPE_xxxx constants
    CertExpired: Integer; // 0 - valid certificate, 1 - certificate or private key expired
    CertRevoked: Integer; // 0 - valid certificate, 1 - certificate revoked
    CertEncoded: TMTEMemBlk; // certificate data in DER-format
  end;
  {$else}
  PMTEConnCertificate = Pointer;
  {$endif}

const
  // connection property flags
  ZLIB_COMPRESSED   = 1;  // ZLIB compression turned on
  FLAG_ENCRYPTED    = 2;  // encryption turned on
  FLAG_SIGNING_ON   = 4;  // digital signature in use
  FLAG_RECONNECTING = 8;  // reconnect in progress

  // certificate types
  CERTTYPE_UNKNOWN  = 0;
  CERTTYPE_VALIDATA = 1;
  CERTTYPE_OPENSSL  = 2;

type
  PMTEConnStats = ^TMTEConnStats;
  TMTEConnStats = packed record
    Size: Integer;
    Properties: Longword;
    SentPackets: Longword;
    RecvPackets: Longword;
    SentBytes: Longword;
    RecvBytes: Longword;
    // fields added in version 2
    ServerIpAddress: Longword;
    ReconnectCount: Integer;
    SentUncompressed: Longword;
    RecvUncompressed: Longword;
    ServerName: TServerName;
    // fields added in version 3
    TsmrPacketSize: Longword;
    TsmrSent: Longword;
    TsmrRecv: Longword;
  end;

  TMTEConnStats_v2 = packed record
    Size: Integer;
    Properties: Longword;
    SentPackets: Longword;
    RecvPackets: Longword;
    SentBytes: Longword;
    RecvBytes: Longword;
    // fields added in version 2
    ServerIpAddress: Longword;
    ReconnectCount: Integer;
    SentUncompressed: Longword;
    RecvUncompressed: Longword;
    ServerName: TServerName;
  end;

  TMTEConnStats_v1 = packed record
    Size: Integer;
    Properties: Longword;
    SentPackets: Longword;
    RecvPackets: Longword;
    SentBytes: Longword;
    RecvBytes: Longword;
  end;

  PMTEServInfo = ^TMTEServInfo;
  TMTEServInfo = packed record
    Connected_To_MICEX: Integer;
    Session_Id: Integer;
    MICEX_Sever_Name: array [0..32] of AnsiChar;
    Version_Major: Byte;
    Version_Minor: Byte;
    Version_Build: Byte;
    Beta_version: Byte;
    Debug_flag: Byte;
    Test_flag: Byte;
    Start_Time: Integer;
    Stop_Time_Min: Integer;
    Stop_Time_Max: Integer;
    Next_Event: Integer;
    Event_Date: Integer;
    Boards: record end;
  end;

  // MTEExecTransEx structures

  TMTETransParam = record
    Name: PAnsiChar;
    Value: PAnsiChar;
  end;

  PMTETransParams = ^TMTETransParams;
  TMTETransParams = array [0..999999] of TMTETransParam;

  TMTETransReply = record
    ErrCode: TMTEResult;
    MsgCode: Integer;
    MsgText: PAnsiChar;
    ParamCount: Integer;
    Params: PMTETransParams;
  end;

  PMTETransReplies = ^TMTETransReplies;
  TMTETransReplies = array [0..999999] of TMTETransReply;

  PMTEExecTransResult = ^TMTEExecTransResult;
  TMTEExecTransResult = record
    ReplyCount: Longword;
    Replies: PMTETransReplies;
  end;

  TMTESnapTable = record
    HTable: Integer;         // Handle of table
    TableName: PAnsiChar;    // char, Zero-byte terminated, Table Name
    Params: PAnsiChar;       // char, Zero-byte terminated, Parameters provided on open table
  end;

  PMTESnapTables = ^TMTESnapTables;
  TMTESnapTables = array [0..999999] of TMTESnapTable;

implementation

end.
