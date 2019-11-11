{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

{$ifndef FPC}
  {$define use_fastmm4}
{$endif}
