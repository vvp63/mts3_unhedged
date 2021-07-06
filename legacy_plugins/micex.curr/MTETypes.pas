{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit MTETypes;

interface

const BUFFER_SIZE       = 64000;

const MTE_OK            =  0;
      MTE_CONFIG        = -1;
      MTE_SRVUNAVAIL    = -2;
      MTE_LOGERROR      = -3;
      MTE_TSMR          = -8;

type  TTEFieldType      = (ftChar, ftInteger, ftFixed, ftFloat, ftDate, ftTime);

type  tErrorMsg         = array [1..255] of ansichar;

type  PMTEErrorMsg      = ^TMTEErrorMsg;
      TMTEErrorMsg      = array [0..255] of AnsiChar;

type  pMTEMsg           = ^tMTEMsg;
      tMTEMsg           = record
        DataLen         : cardinal;
        Data            : array [1..BUFFER_SIZE] of ansichar;
      end;

const openTableComplete = true;
      openTablePartial  = false;

implementation

end.