{__$define use_wrapper}

{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit snappy;

interface

{$ifdef FPC}
  {$ifdef CPU32}
    type size_t = cardinal;
  {$else}
    {$ifdef CPU64}
      {$define GATE64}
      type size_t = QWord;
    {$else}
      PLATFORM IS NOT SUPPORTED
    {$endif}
  {$endif}
  {$ifdef UNIX}
    type THandle = size_t;
  {$endif}
{$else}
  type size_t = cardinal;
  {$A+}
{$endif}

{$ifdef MSWINDOWS}
  {$ifdef CPU64}
const    SnappyLib = 'snappy64.dll';
  {$else}
const    SnappyLib = 'snappy.dll';
  {$endif}
{$else}
  {$ifdef use_wrapper}
  const    SnappyLib = 'snappy-wrapper';
  {$else}
  const    SnappyLib = 'snappy';
  {$endif}
{$endif}

function SnappyRawUncompress(src: pointer; srclen: size_t; dest: pointer; var destlen: size_t): longint; cdecl;
procedure SnappyRawCompress(src: pointer; srclen: size_t; dest: pointer; var destlen: size_t); cdecl;

implementation

{$ifdef use_wrapper}
function SnappyRawUncompress; cdecl; external SnappyLib name 'RawUncompress';
{$else}
  {$ifdef UNIX}
function SnappyRawUncompress; external SnappyLib name 'snappy_uncompress';
  {$else}
function SnappyRawUncompress; external SnappyLib name 'RawUncompress';
  {$endif}
{$endif}

{$ifdef use_wrapper}
function SnappyRawCompress; cdecl; external SnappyLib name 'RawCompress';
{$else}
  {$ifdef UNIX}
function SnappyRawCompress; external SnappyLib name 'snappy_compress';
  {$else}
function SnappyRawCompress; external SnappyLib name 'RawCompress';
  {$endif}
{$endif}

end.
