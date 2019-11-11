{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

library mts3lx;

{$R *.res}

uses  {$ifdef UNIX}
        {$ifdef use_cmem} cmem, {$endif}
        {$ifndef no_multi_thread} cthreads, {$endif}
      {$else}
        windows,
        {$ifdef use_fastmm4} FastMM4, {$endif}
      {$endif}
      serverapi,
      mts3lx_start;

function getDllAPI(srvapi: pServerAPI): pDataSourceAPI; cdecl;
begin
  server_api:= srvapi;
  plugin_api:= @plugapi;
  if assigned(server_api) then begin
    @logproc:= @srvapi^.LogEvent;
    result:= plugin_api;
  end else result:= nil;
end;

exports  getDllAPI;

begin
  IsMultiThread:= true;
end.
