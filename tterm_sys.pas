{$i tterm_defs.pas}

unit  tterm_sys;

interface

uses  {$ifdef UNIX}
        cmem, cthreads, initthreads;
      {$else}
        windows,
        {$ifdef use_fastmm4} FastMM4, {$endif}
        highrestimer;
      {$endif}

implementation

{$ifndef UNIX}
var ResSet : ULONG;

initialization
  IsMultiThread:= true;
  NtSetTimerResolution(5000, true, @ResSet);
{$endif}

end.