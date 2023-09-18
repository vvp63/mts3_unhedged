unit mts3lx_otmanager;

interface

uses {$ifdef MSWINDOWS}
        windows,
      {$else}
        cmem,
        cthreads,
      {$endif}
      dynlibs,
      sysutils,
      classes,
      strings,
      fclinifiles,
      postgres,
      sortedlist,
      servertypes,
      serverapi,
      mts3lx_start,
      mts3lx_common,
      mts3lx_securities;

type tOTManager = class(tObject)
        //  Добавляем сделку в бд
        function      AddTradeToDB(atrade : tTrades)  : longint;
        //  Добавляем заявку в БД
        procedure     AddOrderToDB(aorder : tOrders);
        //  Ставим новую заявку
        function      SetMyOrder(atpid : longint; asec : pSec; aaccount : tAccount; abuysell  : char; aprice  : real; aquantity : longint; amode : char = 'V'{ amarket : boolean = false})  : longint;
        //  Снимаем заявку
        function      DropOrder(atrsid  : longint; aorderno : int64; asec : pSec; aaccount : tAccount) : boolean;
        //  Передвигаем заявку
        function      MoveMyOrder(aorderno : int64; atpid, atrsid : longint; asec : pSec; aaccount : tAccount; abuysell  : char; aprice  : real; aquantity : longint)  : longint;
        //  Находим активные заявки по паре, бумаге и направлению
        function      HasActive(abuysell  : char; atpid, aSecId  : longint;
                           var aprice  : real; var aquantity : longint; var aorderno  : int64; var adroptime  : TDateTime)  : longint;
        //  Отмечаем что заявка отклонена
        procedure     SetOrderRejected(atrsid  : longint; var atpid, asecid  : longint);
end;

procedure InitOTManager;
procedure DoneOTManager;


const OTManager     : tOTManager = nil;


implementation

uses mts3lx_queue;

{ tOTManager }

procedure tOTManager.AddOrderToDB(aorder: tOrders);
begin
  with aorder do try
    if (stock_id > 0) and (stock_id < 10) then begin

      PGQueryMy('SELECT public.addupdateorder(%d, %d, %d, ''%s'', ''%s'', %d, ''%s'', ''%s'', ''%s'', ''%s'', %.6g, %d, %.6g, ''%s'', %d, ''%s'', ''%s'', ''%s'')',
                        [transaction, internalid, stock_id, level, code, orderno, FormatDateTime('yyyymmdd hh:nn:ss', ordertime),
                        status, buysell, account, price, quantity, value, clientid, balance, ' ', settlecode, comment], true);

      FileLog('tOTManager.AddOrderToDB     :   %d[%d] %s %.6g/%d(%d) %s %s',
                                  [orderno, transaction, code, price, quantity, balance, buysell, status], 2);
    end;
  except on e:exception do Filelog(' !!! EXCEPTION: tOTManager.AddOrderToDB %s', [e.message], 0); end;
end;


function tOTManager.AddTradeToDB(atrade: tTrades)  : longint;
var   i     : longint;
      res   : PPGresult;
      SL    : tStringList;
begin
  result:=  0;
  with atrade do try
    if (stock_id > 0) and (stock_id < 10) then begin

      res := PGQueryMy('SELECT public.addupdatetrade(%d, %d, %d, ''%s'', ''%s'', %d, %d, ''%s'', ''%s'', ''%s'', %.6g, %d, %.6g, %g, ''%s'', ''%s'', ''%s'', ''%s'')',
                        [transaction, internalid, stock_id, level, code, tradeno, orderno, FormatDateTime('yyyymmdd hh:nn:ss', tradetime),
                       buysell, account, price, quantity, value, accr, clientid, ' ', settlecode, comment], true);

      if (PQresultStatus(res) = PGRES_TUPLES_OK) then for i := 0 to PQntuples(res)-1 do begin
        SL :=  QueryResult(PQgetvalue(res, i, 0));
        if SL.Count > 0 then result:=  StrToIntDef(SL[0], 0);
      end;

      FileLog('tOTManager.AddTradeToDB     :   [%d %d %d] %s %.6g/%d %s   TPID = %d',
                                  [tradeno, orderno, transaction, code, price, quantity, buysell, Result], 2);
    end;
  except on e:exception do Filelog(' !!! EXCEPTION: tOTManager.AddTradeToDB %s', [e.message], 0); end;
end;



function tOTManager.HasActive(abuysell: char; atpid, aSecId: longint;
                                  var aprice: real; var aquantity: longint; var aorderno  : int64; var adroptime  : TDateTime): longint;
var   i     : longint;
      res   : PPGresult;
      SL    : tStringList;
      vppos : longint;
begin
  result:=  0; aquantity:=  0; aprice:= 0; aorderno:= 0; adroptime:=  0;
  try
    res := PGQueryMy('SELECT public.getactiveorders(%d, %d, ''%s'')', [atpid, aSecId, abuysell]);
    if (PQresultStatus(res) = PGRES_TUPLES_OK) then for i := 0 to PQntuples(res)-1 do begin
      SL :=  QueryResult(PQgetvalue(res, i, 0));
      if SL.Count > 4 then begin

        Result    :=  StrToIntDef(SL[0], 0);
        aprice    :=  StrToFloatDef(SL[1], 0);
        aquantity :=  StrToIntDef(SL[2], 0);
        aorderno  :=  StrToInt64Def(SL[3], 0);
        vppos:= pos('.', SL[4]);
        adroptime :=  StrToDateTime(copy(SL[4], 2, vppos - 2)) + StrToIntDef(copy(SL[4], vppos + 1, 3), 0) * SecDelay / 1000;
        //StrToDateTime(copy(SL[4], 2, length(SL[4]) - 6)); //StrToDateTime(SL[4]);
      end;

    end;
  except on e:exception do Filelog(' !!! EXCEPTION: tOTManager.HasActive %s', [e.message], 0); end;
end;


function tOTManager.SetMyOrder(atpid: longint; asec: pSec; aaccount : tAccount; abuysell: char; aprice: real; aquantity: longint; amode : char = 'V' {amarket : boolean = false}): longint;
var vorder        : tOrder;
    vsetresult    : tSetOrderResult;
    vtransid      : longint;
    vqueueitem    : tQueueItem;
    vexstep       : longint;
    vextext       : string;
      i     : longint;
      res   : PPGresult;
      SL    : tStringList;
begin

  result:=  0; vtransid:= 0; vexstep  :=  0;
  try

    if assigned(asec) then
      if (aprice > 0) and (aquantity > 0) and
          ((asec^.stockid <> 4) or ((aprice >= asec^.Params.limitpricelow) and (aprice <= asec^.Params.limitpricehigh))) then begin

        if assigned(Server_API) then begin

          res := PGQueryMy('SELECT public.addmyorder(%d, %d, ''%s'', %g, %d)',
                  [atpid, asec^.SecurityId, abuysell, aprice, aquantity]);
          if (PQresultStatus(res) = PGRES_TUPLES_OK) then for i := 0 to PQntuples(res)-1 do begin
            SL :=  QueryResult(PQgetvalue(res, i, 0));
            if SL.Count > 0 then vtransid:=  StrToIntDef(SL[0], 0);
          end;

          filelog('tOTManager.SetMyOrder [%d %s] %s %s %d/%.6g TRSid=%d Mode=%s',
              [atpid, asec^.code, aaccount, abuysell, aquantity, aprice, vtransid, amode], 1);

          if (vtransid > 0) and ((aprice > 0) or (amode = 'M')) and (aquantity > 0) then begin
            with vorder do begin
              transaction := vtransid;
              stock_id    := asec^.stockid;
              level       := asec^.level;
              code        := asec^.code;
              buysell     := abuysell;
              price       := aprice;
              quantity    := aquantity;
              account     := aaccount;
              flags       := opNormal;
              if amode = 'M' then flags :=  opMarketPrice;
              if amode = 'I' then begin
                 if (stock_id = 1) then flags :=  opImmCancel else flags :=  opMarketPrice;
              end;
              cid         := Copy(account, 0, 5);
              cfirmid     := '';
              match       := '';
              settlecode  := '';
              refundrate  := 0;
              reporate    := 0;
              price2      := 0;
           {   vextext  :=  format('%d %d %s %s %s %.6g %d %s %d %s',
                                [transaction, stock_id,level,code,buysell,price, quantity,account, flags, cid]);
              filelog('tOTManager.SetMyOrder Info %s', [vextext], 1);  }
            end;


            if assigned(Server_API^.Set_SysOrder) and Server_API^.Set_SysOrder(vorder, pChar(''), vsetresult) then result:=  vtransid
              else begin
                with vqueueitem do begin
                  evTime:=  now; evType:= ev_type_soresult; evSoResult:=  vsetresult;
                end;
                if assigned(AllQueue) then AllQueue.push(vqueueitem);
              end;
          end else
              filelog('tOTManager.SetMyOrder TransactionId, quantity or price < 0', [], 3);
            
        end;

      end else filelog('tOTManager.SetMyOrder price or quantity out of limit %s %.6g %d (%.6g - %.6g)',
                      [asec^.code, aprice, aquantity, asec^.Params.limitpricelow, asec^.Params.limitpricehigh], 3);

  except on e:exception do Filelog(' !!! EXCEPTION: SetMyOrder %s (step %d %s)', [e.message, vexstep, vextext], 0); end;

end;



function tOTManager.DropOrder(atrsid  : longint; aorderno : int64; asec : pSec; aaccount : tAccount) : boolean;
var vdrop : tDropOrder;
begin
  result:=  false;
  if assigned(Server_API) and assigned(Server_API^.Drop_Order) then begin
    with vdrop do begin
      transaction :=  atrsid;
      stock_id    :=  asec^.stockid;
      count       :=  1;
      orders[1]   :=  aorderno;
    end;

    PGQueryMy('SELECT public.setdroptime(%d, ''%s'')', [atrsid, FormatDateTime('yyyymmdd hh:nn:ss', now)]);
    {
    with tQuery.create do try
      ExecuteQuery('exec SetDropTime %d, ''%s''', [atrsid, FormatDateTime('yyyymmdd hh:nn:ss', now)]);
    finally free; end;  }
    result:=  Server_API^.Drop_Order(aaccount, vdrop);
  end;
  filelog('tOTManager.DropOrder %d %d %s (%s) = %s', [atrsid, aorderno, asec^.code, aaccount, BoolToStr(Result, true)], 1);
end;


function tOTManager.MoveMyOrder(aorderno: int64; atpid, atrsid: longint;  asec: pSec; aaccount : tAccount; abuysell: char; aprice: real; aquantity: longint): longint;
var vtransid      : longint;
    vsetresult    : tSetOrderResult;
    vmoveorder    : tMoveOrder;
    vqueueitem    : tQueueItem;
      i     : longint;
      res   : PPGresult;
      SL    : tStringList;
begin
  result:=  0; vtransid:= 0;

  if assigned(asec) then
    if (aprice >= asec^.Params.limitpricelow) and (aprice <= asec^.Params.limitpricehigh) then begin

      if assigned(Server_API) then begin

          res := PGQueryMy('SELECT public.addmyorder(%d, %d, ''%s'', %g, %d)',
                    [atpid, asec^.SecurityId, abuysell, aprice, aquantity]);
          if (PQresultStatus(res) = PGRES_TUPLES_OK) then for i := 0 to PQntuples(res)-1 do begin
            SL :=  QueryResult(PQgetvalue(res, i, 0));
            if SL.Count > 0 then vtransid:=  StrToIntDef(SL[0], 0);
          end;

        filelog('tOTManager.MoveMyOrder %d [%d %s] %s %s %d/%.6g TRSid=%d',
                [aorderno, atpid, asec^.code, aaccount, abuysell, aquantity, aprice, vtransid], 1);

        if vtransid > 0 then begin

          with vmoveorder do begin
           transaction  :=  vtransid;
           stock_id     :=  asec^.stockid;
           level        :=  asec^.level;
           code         :=  asec^.code;
           orderno      :=  aorderno;
           new_price    :=  aprice;
           new_quantity :=  aquantity;
           account      :=  aaccount;
           flags        :=  opNormal;
           cid          :=  Copy(account, 0, 5);
          end;

          if assigned(Server_API^.Move_SysOrder) then begin
            PGQueryMy('SELECT public.setdroptime(%d, ''%s'')', [atrsid, FormatDateTime('yyyymmdd hh:nn:ss', now)]);
            Server_API^.Move_SysOrder(vmoveorder, vsetresult);
            result:=  vtransid;
          end else begin
            with vqueueitem do begin
              evTime:=  now; evType:= ev_type_soresult; evSoResult:=  vsetresult;
            end;
            if assigned(AllQueue) then AllQueue.push(vqueueitem);
          end;
          
        end;

      end;

    end else filelog('tOTManager.MoveMyOrder price out of limit %s %.6g (%.6g - %.6g)',
                    [asec^.code, aprice, asec^.Params.limitpricelow, asec^.Params.limitpricehigh], 3);

end;



procedure tOTManager.SetOrderRejected(atrsid  : longint; var atpid, asecid  : longint);
var   i     : longint;
      res   : PPGresult;
      SL    : tStringList;
begin
  atpid:= 0;  asecid:=  0;
  res := PGQueryMy('SELECT public.setorderrejected(%d)', [atrsid], true);
  if (PQresultStatus(res) = PGRES_TUPLES_OK) then for i := 0 to PQntuples(res)-1 do begin
    SL :=  QueryResult(PQgetvalue(res, i, 0));
    if SL.Count > 1 then begin
      atpid   :=    StrToIntDef(SL[0], 0);
      asecid  :=    StrToIntDef(SL[1], 0);
    end;
  end;
  {
  with tQuery.create do try
    OpenQuery('exec SetOrderRejected %d', [atrsid]);
    if not eof then begin
      atpid   :=    fields[0].AsInteger;
      asecid  :=    fields[1].AsInteger;
    end;
  finally free; end;   }
end;


//      ---------------------------------   //


procedure InitOTManager;
begin
  OTManager :=  tOTManager.Create;
end;

procedure DoneOTManager;
begin
  if assigned(OTManager) then freeandnil(OTManager);
end;







end.
