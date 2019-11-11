{$i terminal_defs.pas}

unit  terminal_sys;

interface

uses  {$ifdef UNIX}
        {$ifdef use_cmem} cmem, {$endif}
        {$ifndef no_multi_thread} cthreads, {$endif}
      {$else}
        windows,
        {$ifdef use_fastmm4} FastMM4, {$endif}
        highrestimer,
      {$endif}
      sysutils;

implementation

{$ifndef UNIX}
var ResSet : ULONG;

initialization
  IsMultiThread:= true;
  NtSetTimerResolution(5000, true, @ResSet);
{$endif}

end.