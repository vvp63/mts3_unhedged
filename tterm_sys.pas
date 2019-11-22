{$i tterm_defs.pas}

unit  tterm_sys;

interface

uses  {$ifdef UNIX}
        {$ifdef use_cmem} cmem, {$endif}
        {$ifndef no_multi_thread} cthreads, initthreads; {$endif}
      {$else}
        windows,
        {$ifdef use_fastmm4} FastMM4, {$endif}
        highrestimer;
      {$endif}

implementation

var ResSet : ULONG;

initialization
  {$ifndef UNIX}
  IsMultiThread:= true;
  NtSetTimerResolution(5000, true, @ResSet);
  {$endif}

end.