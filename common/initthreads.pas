{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

{$define use_ismultithread}

unit initthreads;

interface

{$ifndef use_ismultithread}
uses classes;
{$endif}

implementation

{$ifndef use_ismultithread}
type  tDummyThread = class(tthread)
        procedure execute; override;
      end;

procedure tDummyThread.execute;
begin end;
{$endif}

initialization
{$ifndef use_ismultithread}
  with tDummyThread.create(false) do begin
    waitfor; free;
  end;
{$else}
  IsMultiThread:= true;
{$endif}

end.
