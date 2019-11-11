{$i tterm_defs.pas}
{$i serverdefs.pas}

unit  legacy_misc_api;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$endif}
      sysutils, math,
      serverapi, servertypes,
      tterm_api;

procedure srvSetCommissBySec(astock_id: longint; alevel: tLevel; acode: tCode; aprc: real; afs: currency); cdecl;

procedure srvSetAdditionalPrm(astock_id: longint; aparams: pAnsiChar); cdecl;

procedure srvGetLastNews(news_id: longint; var lastdt: tdatetime; var lastno: int64); cdecl;
function  srvAddNewsRec(news_id: longint; news_no: int64; news_time: tdatetime; title, text: pAnsiChar): longint; cdecl;

procedure srvSetClientLimit(var struc: tClientLimit; changedfields: tLimitsSet); cdecl;

function  srvSendUserMessage(aToID, aToUserName, aText: pAnsiChar): boolean; cdecl;
function  srvSendBroadcastMessage(aflags: longint; aText: pAnsiChar): boolean; cdecl;

function  srvSetSQLEventResult(aresulthandle: pointer; adata: pAnsiChar; adatasize: longint): boolean; cdecl;

implementation

uses  tterm_logger, tterm_legacy_apis, tterm_pluginsupport;

procedure srvSetCommissBySec(astock_id: longint; alevel: tLevel; acode: tCode; aprc: real; afs: currency); cdecl;
begin end;

procedure srvSetAdditionalPrm(astock_id: longint; aparams: pAnsiChar); cdecl;
begin end;

procedure srvGetLastNews(news_id: longint; var lastdt: tdatetime; var lastno: int64); cdecl;
begin lastdt:= date; lastno:= 0; end;

function  srvAddNewsRec(news_id: longint; news_no: int64; news_time: tdatetime; title, text: pAnsiChar): longint; cdecl;
begin log('NEWS: %s', [title]); result:= 0; end;

procedure srvSetClientLimit(var struc: tClientLimit; changedfields: tLimitsSet); cdecl;
begin end;

function  srvSendUserMessage(aToID, aToUserName, aText: pansichar): boolean; cdecl;
var i : longint;
begin
  for i:= 0 to event_apis_count - 1 do
    if assigned(event_apis[i]) then with event_apis[i]^ do
      if assigned(evUserMessage) then evUserMessage(aToID, aToUserName, aText);
  result:= true;    
end;

function  srvSendBroadcastMessage(aflags: longint; aText: pansichar): boolean; cdecl;
begin result:= srvSendUserMessage(nil, nil, atext); end;

function  srvSetSQLEventResult(aresulthandle: pointer; adata: pAnsiChar; adatasize: longint): boolean; cdecl;
var procs : array of pointer;
    count : longint;
begin
  result:= false;
  setlength(procs, GetPluginsCount);
  if (length(procs) > 0) then begin
    count:= min(GetPluginsProcAddressList(@procs[0], length(procs) * sizeof(pointer), PLG_SetSQLEventResult), length(procs));
    while (count > 0) do begin
      result:= result or (tSetSQLEventResult(procs[count - 1])(pointer(aresulthandle), adata, adatasize) <> PLUGIN_ERROR);
      dec(count);
    end;
  end;
end;

exports
  srvSetCommissBySec      name srv_SetStockComissionBySec,

  srvSetAdditionalPrm     name srv_SetStockAdditionalParams,

  srvGetLastNews          name srv_GetLastNews,
  srvAddNewsRec           name srv_AddNewsRec,

  srvSetClientLimit       name srv_SetClientLimit,

  srvSendUserMessage      name srv_SendUserMessage,
  srvSendBroadcastMessage name srv_SendBroadcastMessage,

  srvSetSQLEventResult    name srv_SetSQLEventResult;


end.