unit remotetypes;
interface

{$A-}

type  pConnectionInfo = ^tConnectionInfo;
      tConnectionInfo = record
       id             : string[5];
       username       : string[20];
       flags          : longint;
       realname       : string[50];
      end;

type  pUserMessage    = ^tUserMessage;
      tUserMessage    = record
       id             : string[5];
       username       : string[20];
       dt             : tDateTime;
      end;

type  pServerStatus   = ^tServerStatus;
      tServerStatus   = record
       opendaystatus  : longint;
       timesync       : tdatetime;       
      end;

implementation

end.