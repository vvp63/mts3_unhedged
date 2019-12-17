{$i terminal_defs.pas}

unit  terminal_sys;

interface

uses  {$ifdef UNIX}
        cmem, cthreads,
      {$else}
        windows,
        {$ifdef use_fastmm4} FastMM4, {$endif}
        highrestimer,
      {$endif}
      sysutils;

implementation

{$ifndef UNIX}
var ResSet : ULONG;
{$endif}

initialization
  IsMultiThread:= true;
{$ifndef UNIX}
  NtSetTimerResolution(5000, true, @ResSet);
{$endif}

end.