{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

{$ifndef FPC}
  {$define use_fastmm4}
{$endif}

{$define tterm}
{$define debuglog}
{$define filelog}
{$define enable_log_buffer}

