unit protodef;
interface

{$A-}

uses  Crc32;

const protocolversion     = 20;                              // ������ ���������

const sgProtSign          = $61786F54;

const prfLogout           = $00000001;
      prfUserDropped      = $00000002;

const accAccessDenied     = $00;                             // ������������ ��� ��� ������
      accDuplicateUser    = $01;                             // ������������ ��� �� �����
      accUserAccepted     = $02;                             // ���������� �����������

const usrNormal           = $00;                             // ���������� ������������
      usrDemo             = $01;                             // ����-������������
      usrDisabled         = $02;                             // ������������ ����������
      usrExpired          = $04;                             // ����� �������� ������������ �������
      usrMarginEnable     = $08;                             // ��������� ������������ ������
      usrMonitor          = $10;                             // ������ �������� ��� ����������� ������� � ������� ������
      usrRemoteServer     = $20;                             // ��������� ������
      usrRepoAllowed      = $40;                             // ��������� ������ ���

const idMiscData          = $00;                             // not implemented

      idWaitSec           = $01;                             // tables
      idWaitOrders        = $03;
      idWaitTrades        = $04;
      idWaitAllTrades     = $05;
      idReport            = $06;
      idStockList         = $07;
      idKotUpdates        = $08;
      idTradesQuery       = $09;
      idNews              = $0a;
      idLevelList         = $0b;
      idClientLimits      = $0c;
      idAccountRests      = $0d;
      idLiquidList        = $0e;
      idFirmInfo          = $0f;
      idClientInfo        = $10;
      idServerReply       = $11;
      idClientQuery       = $12;
      idAccountList       = $13;
      idMessage           = $15;
      idTrsResult         = $16;
      idClientRC5Key      = $17;
      idMarginLevel       = $18;
      idTimeSync          = $19;
      idAccount           = $1a;
      idTrsQuery          = $1b;
      idMarginInfo        = $1c;
      idStopOrder         = $1d;
      idSettleCodes       = $1e;
      idIndividualLimits  = $1f;

      idPing              = $20;

      idQueryCon          = $30;                             // remote control only
//      idUsrChgStatus      = $31;
      idUserMessage       = $32;
      idOpenDay           = $33;
      idCloseDay          = $34;
      idServerStatus      = $35;

      idSetOrder          = $40;
      idReportQuery       = $41;
      idATradesQuery      = $42;
      idOrderBookQuery    = $43;
      idDropOrder         = $44;
//      idTradesQuery       = $45;
      idMoveOrder         = $46;    

      idTableDescr        = $ff;                             // table descriptor

const pfNoFlags           = $00;
      pfEncrypted         = $01;
      pfPacked            = $02;

const csOnline            = 0;
      csDisconnect        = 1;
      csTimeOut           = 2;
      csFrameError        = 3;
      csTerminated        = 4;
      csInvalidUser       = 5;
      csDuplicateUser     = 6;

const frmchkEnabled       = true;
      frmchkDisabled      = false;

const maxPwdLength        = 23;                              // ������������ ������ ������

type  pProtocolRec        = ^tProtocolRec;
      tProtocolRec        = packed record
        signature         : longint;
        tableid           : byte;
        rowcount          : word;
        datasize          : longint;
        flags             : byte;
      end;

type  tVerArray           = array [0..2] of byte;
      tClientVersion      = record
      case boolean of
       true               : ( major      : byte;
                              minor      : byte;
                              build      : byte);
       false              : (version     : tVerArray);
      end;

type  pClientInfo         = ^tClientInfo;
      tClientInfo         = record
       id                 : string[5];                       // ID ������������
       username           : string[20];                      // ��� ������������
       password           : array [0..3] of cardinal;        // ���������� ������
       version            : tClientVersion;                  // ������ �������
      end;

const protLoginMsg        = $00;
      protCloseConn       = $01;

type  tEncryptedPwd       = string[MaxPwdLength];

type  pHandshakeMsg       = ^tHandshakeMsg;
      tHandshakeMsg       = record
       case msgid         : byte of                          // id ���������
        protLoginMsg      : (version      : word;            // ������ �������
                             accresult    : byte;            // ��������� �����������
                             userflags    : byte);           // ������ ������������ � �������
        protCloseConn     : (closeflags   : longint);        // ��������� ���������
      end;

type  pTimeSync           = ^tTimeSync;
      tTimeSync           = record
       dt                 : tdatetime;
      end;

const connDefTimeOut      : longint               = 40000;

const protocolmsg         : array [1..6] of pChar = ('disconnect',
                                                     'timeout',
                                                     'framecheck error',
                                                     'thread terminated',
                                                     'incorrect login or password',
                                                     'duplicate user detected');

function  FillProtocolFrame(id, rc, itemsz, fl: longint): tProtocolRec;
function  FillProtocolFrameEx(id, rc, datasz, fl: longint): tProtocolRec;
procedure UpdateProtocolCRC(var frame: tProtocolRec);
function  CheckFrame(frame: tProtocolRec): boolean;

implementation

function FillProtocolFrame(id, rc, itemsz, fl: longint): tProtocolRec;
begin
  with result do begin
    signature:= sgProtSign;
    tableid:= id; rowcount:= rc;
    datasize:= rc * itemsz; flags:= fl;
    signature:= BufCRC32(result, sizeof(tProtocolRec));
  end;
end;

function FillProtocolFrameEx(id, rc, datasz, fl: longint): tProtocolRec;
begin
  with result do begin
    signature:= sgProtSign;
    tableid:= id; rowcount:= rc;
    datasize:= datasz; flags:= fl;
    signature:= BufCRC32(result, sizeof(tProtocolRec));
  end;
end;

procedure UpdateProtocolCRC(var frame: tProtocolRec);
begin
  frame.signature:= sgProtSign;
  frame.signature:= BufCRC32(frame, sizeof(tProtocolRec));
end;

function CheckFrame(frame: tProtocolRec): boolean;
var crc : longint;
begin
  with frame do begin crc:= signature; signature:= sgProtSign; end;
  result:= (BufCRC32(frame,sizeof(tProtocolRec)) = crc);
end;

end.