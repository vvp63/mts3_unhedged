{$i tterm_defs.pas}

unit tterm_legacy_apis;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$endif}
      sysutils,
      serverapi, servertypes,
      tterm_api;

type  tLegacyPluginCommandAction = (act_plg_connect, act_plg_disconnect, act_plg_hook);

var   stock_apis        : array[byte] of pStockAPI;

      news_apis_count   : longint = 0;
      news_apis         : array[byte] of pNewsAPI;

      event_apis_count  : longint = 0;
      event_apis        : array[byte] of pEventHandlerAPI;

      plugin_apis_count : longint = 0;
      plugin_apis       : array[byte] of pDataSourceAPI;

function  InitLegacyAPI(aapi: pDataSourceAPI): pDataSourceAPI;
procedure DoneLegacyAPI(aapi: pDataSourceAPI);

function  ExecuteLegacyPluginCommand(aaction: tLegacyPluginCommandAction; const aplugname, acommand: ansistring): boolean;
procedure ExecuteLegacyPluginEvent(aevent: longint);

procedure BroadcastTableEvent(aevent: longint; astock_id: longint; const alevel: tLevel);

function  GetLegacyAPIs(var apis: pointer; var acount: longint): longint; stdcall;

implementation

function InitLegacyAPI(aapi: pDataSourceAPI): pDataSourceAPI;
var i : longint;
begin
  result:= aapi;
  if assigned(result) then with result^ do begin
    plugin_apis[byte(plugin_apis_count)]:= result;
    inc(plugin_apis_count);

    if (plugflags and plStockProvider <> 0) and assigned(stockAPI) then begin
      for i:= 0 to stockAPI^.stock_count - 1 do
        stock_apis[byte(stockAPI^.stock_list^[i].stock_id)]:= stockAPI;
    end;

    if (plugflags and plNewsProvider <> 0) and assigned(newsAPI) then begin
      news_apis[byte(news_apis_count)]:= newsAPI;
      inc(news_apis_count);
    end;

    if (plugflags and plEventHandler <> 0) and assigned(eventAPI) then begin
      event_apis[byte(event_apis_count)]:= eventAPI;
      inc(event_apis_count);
    end;
  end;
end;

procedure DoneLegacyAPI(aapi: pDataSourceAPI);
var i : longint;
begin
  if assigned(aapi) then with aapi^ do begin
    for i:= 0 to plugin_apis_count - 1 do
      if plugin_apis[byte(i)] = aapi then plugin_apis[byte(i)]:= nil;

    if (plugflags and plStockProvider <> 0) and assigned(stockAPI) then begin
      for i:= 0 to stockAPI^.stock_count - 1 do
        stock_apis[byte(stockAPI^.stock_list^[i].stock_id)]:= nil;
    end;

    if (plugflags and plNewsProvider <> 0) and assigned(newsAPI) then begin
      for i:= 0 to news_apis_count - 1 do
        if (news_apis[byte(i)] = newsAPI) then news_apis[byte(i)]:= nil;
    end;

    if (plugflags and plEventHandler <> 0) and assigned(eventAPI) then begin
      for i:= 0 to event_apis_count - 1 do
        if (event_apis[byte(i)] = eventAPI) then event_apis[byte(i)]:= nil;
    end;
  end;
end;

function  ExecuteLegacyPluginCommand(aaction: tLegacyPluginCommandAction; const aplugname, acommand: ansistring): boolean;
var i   : longint;
    api : pDataSourceAPI;
begin
  result:= false;
  i:= 0;
  while (i < plugin_apis_count) do begin
    api:= plugin_apis[i];
    if assigned(api) and (CompareText(api^.plugname, aplugname) = 0) then begin
      if (api^.plugflags and plStockProvider <> 0) and assigned(api^.stockAPI) then begin
        result:= true;
        case aaction of
          act_plg_connect    : if (length(acommand) = 0) and assigned(api^.stockAPI^.pl_Connect) then api^.stockAPI^.pl_Connect else result:= false;
          act_plg_disconnect : if (length(acommand) = 0) and assigned(api^.stockAPI^.pl_Disconnect) then api^.stockAPI^.pl_Disconnect else result:= false;
          act_plg_hook       : if assigned(api^.stockAPI^.pl_Hook) then api^.stockAPI^.pl_Hook(pAnsiChar(acommand)) else result:= false;
        end;
      end;
      i:= plugin_apis_count;
    end else inc(i);
  end;
end;

procedure ExecuteLegacyPluginEvent(aevent: longint);
var i   : longint;
    api : pDataSourceAPI;
begin
  for i:= 0 to plugin_apis_count - 1 do begin
    api:= plugin_apis[i];
    if assigned(api) and (api^.plugflags and plStockProvider <> 0) and assigned(api^.stockAPI) then
      with api^.stockAPI^ do
        case aevent of
          evBeforeDayOpen  : if assigned(ev_BeforeDayOpen)  then ev_BeforeDayOpen;
          evAfterDayOpen   : begin
                               if assigned(ev_AfterDayOpen) then ev_AfterDayOpen;
                               if assigned(ev_ServerStatus) then ev_ServerStatus(dayWasOpened);
                             end;
          evBeforeDayClose : if assigned(ev_BeforeDayClose) then ev_BeforeDayClose;
          evAfterDayClose  : begin
                               if assigned(ev_AfterDayClose) then ev_AfterDayClose;
                               if assigned(ev_ServerStatus)  then ev_ServerStatus(dayWasClosed);
                             end;
        end;
  end;
end;

procedure BroadcastTableEvent(aevent: longint; astock_id: longint; const alevel: tLevel);
var i : longint;
begin
  for i:= 0 to event_apis_count - 1 do
    if assigned(event_apis[i]) then with event_apis[i]^ do
      if assigned(evTableUpdate) then evTableUpdate(aevent, astock_id, alevel);
end;

function  GetLegacyAPIs(var apis: pointer; var acount: longint): longint;
begin
  apis:= @plugin_apis; acount:= plugin_apis_count;
  result:=  PLUGIN_OK;
end;

exports
  GetLegacyAPIs name SRV_GetLegacyAPIs;

initialization
  fillchar(stock_apis, sizeof(stock_apis), 0);
  fillchar(news_apis, sizeof(news_apis), 0);
  fillchar(event_apis, sizeof(event_apis), 0);
  fillchar(plugin_apis, sizeof(plugin_apis), 0);

end.