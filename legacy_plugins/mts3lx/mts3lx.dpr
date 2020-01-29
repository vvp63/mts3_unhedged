{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

{$M+}

{$ifdef MSWINDOWS}
  {$define plg_new_style}
{$endif}

library mts3lx;

{$R *.res}


uses  {$ifdef MSWINDOWS}
        windows,
      {$else}
        cmem,
        cthreads,
      {$endif}
      dynlibs,
      sysutils,
      serverapi,
      tterm_api,
      tterm_commandparser,
      mts3lx_main,
      mts3lx_start,
      mts3lx_sheldue,
      mts3lx_securities ,
      mts3lx_tp,
      mts3lx_logger;





function getDllAPI(srvapi: pServerAPI): pDataSourceAPI; cdecl;
begin
    server_api:= srvapi;
    plugin_api:= @plugapi;
    if assigned(server_api) then begin
      @logproc:= @srvapi^.LogEvent;
      result:= plugin_api;
    end else result:= nil;
end;



exports   getDllAPI               name 'getDllAPI',
          InitEX                  name 'plg_initialize_ex',
          ProcessUserCommand      name 'PLG_ProcessUserCommand';


var command : string  = '';
    quit    : boolean = false;

begin

  {$ifdef FPC}
  DefaultFormatSettings.DecimalSeparator:= '.';
  DefaultFormatSettings.TimeSeparator:= ':';
  {$else}
  DecimalSeparator:= '.'; timeseparator:= ':';
  {$endif}

  IsMultiThread:= true;


end.