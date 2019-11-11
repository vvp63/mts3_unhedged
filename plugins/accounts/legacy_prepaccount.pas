{$i serverdefs.pas}

unit legacy_prepaccount;

interface

uses  windows, classes, sysutils,
      servertypes, sortedlist, lowlevel,
      accountsupport_common, 
      legacy_accounts;

type  tPreparedAccount = class(tBaseAccount)
      public
       function    dogetaccountsums: tAccountParams; override;
       procedure   calculatemarginglevel(var mlvl: tMarginLevel); override;
       procedure   update(acc: tBaseAccount; ufact, uplan: boolean); override;
       procedure   updateregistry; override;
       function    getaccountdata(var adatasize: longint): pAnsiChar;
       function    getrestsqueueitem: pQueueData; override;
      end;

implementation

function tPreparedAccount.dogetaccountsums;
var   fclientid        : tclientid;
      bs,typ           : string[1];
      idx, i           : longint;
      item             : pClientLimitItem;
      dealvalue        : currency;
      slimit           : tClientLimitItem;
begin
  fclientid:= account;

  if length(fClientId)>0 then begin
    clear;
      try
        //--- инициализация начальных лимитов ----------------------------
        nullitem(searchadditem(0, 'MONEY'));

        //--- лимиты -----------------------------------------------------
{
        EnterCriticalSection(LimitsCritSect);
        try
          slimit.limit.account:= account;
          with limits do begin
            search(@slimit, idx);
            if (idx >= 0) then
              while (idx < count) and (comparetext(account, pClientLimitItem(items[idx])^.limit.account) = 0) do begin
                item:= pClientLimitItem(items[idx]);
                if assigned(item) then with searchadditem(item^.limit.stock_id, item^.limit.code)^ do begin
                  ostatok    := item^.limit.startlimit;
                  afact      := item^.limit.free;
                  reserved   := item^.limit.reserved;
                  res_pos    := item^.limit.res_pos;
                  res_ord    := item^.limit.res_ord;
                  negvarmarg := item^.limit.negvarmarg;
                  curvarmarg := item^.limit.curvarmarg;
                end;
                inc(idx);
              end;
          end;
        finally LeaveCriticalSection(LimitsCritSect); end;
}
        //--- состояние на начало дня по бумагам -------------------------
{
        ExecSQL(q, 'exec AccountRests @account=''%s'', @day=''%s''',
                [account, FormatDateTime('mm/dd/yyyy', date)], false);
        while not q.eof do begin
          if (comparetext(q.fields[1].asstring, 'MONEY') <> 0) then
            with searchadditem(q.fields[0].asinteger, q.fields[1].asstring)^ do begin
              ostatok:= q.fields[2].ascurrency; fact:= ostatok;
              if (ostatok < 0) then begin sumdebts:= abs(ostatok); maxdebts:= sumdebts; end;
            end;
          q.next;
        end;
}
        //--- расчет фактических остатков --------------------------------
{
        ExecSQL(q,'exec calcfact @account=''%s'', @factturnover=0',[account],false);
        while not q.eof do begin
          bs        := q.fields[3].asstring + ' ';
          dealvalue := q.fields[4].ascurrency;
          typ       := q.fields[8].asstring + ' ';
          //--- добавление бумаги в портфель ------------------------------
          case upcase(typ[1]) of
            'D' : with searchadditem(q.fields[0].asinteger, q.fields[2].asstring)^ do begin
                    case upcase(bs[1]) of
                      'B' : begin
                              fbuy     := fbuy     + dealvalue;
                              fact     := fact     + dealvalue;
                            end;
                      'S' : begin
                              fsell    := fsell    + dealvalue;
                              fact     := fact     - dealvalue;
                            end;
                    end;
                  end;
            'M' : with searchadditem(q.fields[0].asinteger, q.fields[2].asstring)^ do begin
                    case upcase(bs[1]) of
                     'B' : begin
                             addition := addition + dealvalue;
                             fact     := fact     + dealvalue;
                           end;
                     'S' : begin
                             addition := addition - dealvalue;
                             fact     := fact     - dealvalue;
                           end;
                    end;
                  end;
          end;
          q.next;
        end;
}
        //--- расчет плановых остатков -----------------------------------
{
        ExecSQL(q,'exec calcplan @account=''%s'', @planturnover=0',[account],false);
        while not q.eof do begin
          bs        := q.fields[3].asstring + ' ';
          dealvalue := q.fields[4].ascurrency;
          //--- добавление бумаги в портфель ------------------------------
          with searchadditem(q.fields[0].asinteger, q.fields[2].asstring)^ do begin
            case upcase(bs[1]) of
              'B' : pbuy  := pbuy  + dealvalue;
              'S' : psell := psell + dealvalue;
            end;
          end;
          q.next;
        end;
}
        //--- расчет остатков --------------------------------------------
        for i:=0 to count-1 do with pAccountParams(items[i])^ do begin
          if (stock_id <> 0) then begin
            afact    := ostatok + addition - fsell + fbuy;
            aplan    := afact - psell + pbuy;
          end;
          fact:=maxcurr(afact,0); fdbt:=abs(mincurr(afact,0));
          plan:=maxcurr(aplan,0); pdbt:=abs(mincurr(aplan,0));
        end;

      except on e:exception do log('Exception: %s', [e.message]); end;
  end;
end;

procedure tPreparedAccount.calculatemarginglevel;
begin
  with mlvl do begin
    account:= self.account;
    factlvl:= 1; planlvl:= 1; minlvl:= 1;
    marginstate:= marginNormal;
    planlvlb:= 1; planlvls:= 1; planlvlmid:= 1; planlvlbn:= 1;
  end;
end;

procedure tPreparedAccount.update;
var i,j,c : longint;
    itm   : pAccountParams;
begin
  i:=0; j:=0;
  while j<acc.count do begin
    if i<count then begin
      c:=compare(items[i],acc.items[j]);
      if c<0 then begin
        repeat delete(i);
        until (i>=count) or (compare(items[i],acc.items[j])>=0);
      end else
      if c>0 then begin
        itm:=new(pAccountParams);
        itm^:=pAccountParams(acc.items[j])^;
        insert(i,itm);
        inc(i); inc(j);
      end else begin
        with pAccountParams(items[i])^ do begin
          if ufact then begin
            ostatok      := pAccountParams(acc.items[j])^.ostatok;
            addition     := pAccountParams(acc.items[j])^.addition;
            fbuy         := pAccountParams(acc.items[j])^.fbuy;           
            fsell        := pAccountParams(acc.items[j])^.fsell;          
            fkomis       := pAccountParams(acc.items[j])^.fkomis;         
            fact         := pAccountParams(acc.items[j])^.fact;           
            afact        := pAccountParams(acc.items[j])^.afact;          
            fdbt         := pAccountParams(acc.items[j])^.fdbt;           
            maxdebts     := pAccountParams(acc.items[j])^.maxdebts;       
            sumdebts     := pAccountParams(acc.items[j])^.sumdebts;
            ostatokprice := pAccountParams(acc.items[j])^.ostatokprice;
            reserved     := pAccountParams(acc.items[j])^.reserved;
            res_pos      := pAccountParams(acc.items[j])^.res_pos;
            res_ord      := pAccountParams(acc.items[j])^.res_ord;
            negvarmarg   := pAccountParams(acc.items[j])^.negvarmarg;
            curvarmarg   := pAccountParams(acc.items[j])^.curvarmarg;
          end;
          if uplan then begin
            pbuy     := pAccountParams(acc.items[j])^.pbuy;           
            psell    := pAccountParams(acc.items[j])^.psell;          
            lpbuym   := pAccountParams(acc.items[j])^.lpbuym;         
            nlbuym   := pAccountParams(acc.items[j])^.nlbuym;         
            lpsellm  := pAccountParams(acc.items[j])^.lpsellm;        
            pkomis   := pAccountParams(acc.items[j])^.pkomis;         
            ekomis   := pAccountParams(acc.items[j])^.ekomis;         
            plan     := pAccountParams(acc.items[j])^.plan;           
            aplan    := pAccountParams(acc.items[j])^.aplan;          
            pdbt     := pAccountParams(acc.items[j])^.pdbt;           
            maxpdbts := pAccountParams(acc.items[j])^.maxpdbts;       
          end;
        end;
        inc(i); inc(j);
      end;
    end else begin
      itm:=new(pAccountParams);
      itm^:=pAccountParams(acc.items[j])^;
      insert(i,itm);
      inc(i); inc(j);
    end;
  end;
  while i<count do delete(i);
end;

procedure tPreparedAccount.updateregistry;
begin end;

function tPreparedAccount.getaccountdata(var adatasize: longint): pAnsiChar;
var i, j   : longint;
    accbuf : tAccountBuf;
    accrow : tAccountRow;
begin
  result:= nil;
  adatasize:= 0;
  if assigned(databuffer) then begin
    j:= Count * sizeof(tAccountRow) + sizeof(tAccountBuf);
    if (databuffer.Size < j) then databuffer.SetSize(j * 2);
    databuffer.seek(0, soFromBeginning);
    accbuf.account:= self.account;
    accbuf.rowcount:= 0;
    databuffer.write(accbuf, sizeof(accbuf));
    j:= 0;
    for i:= 0 to count - 1 do with pAccountParams(items[i])^ do
      if (stock_id = 0) or (plan <> 0) or (fact <> 0) or (pdbt <> 0) or (fdbt <> 0) then begin
        accrow.fields     := [acc_stock_id, acc_code, acc_fact, acc_plan, acc_fdbt, acc_pdbt, acc_curvarmarg];
        accrow.stock_id   := stock_id;
        accrow.code       := code;
        accrow.fact       := fact;
        accrow.plan       := plan;
        accrow.fdbt       := fdbt;
        accrow.pdbt       := pdbt;
        accrow.curvarmarg := curvarmarg;
        if (stock_id = 0) then begin
          accrow.fields     := accrow.fields + [acc_reserved, acc_res_pos, acc_res_ord, acc_negvarmarg];
          accrow.reserved   := reserved;
          accrow.res_pos    := res_pos;
          accrow.res_ord    := res_ord;
          accrow.negvarmarg := negvarmarg;
        end;
        databuffer.write(accrow, sizeof(accrow));
        inc(j);
      end;
    result:= databuffer.memory;
    adatasize:= databuffer.position;
    if (j > 0) then pAccountBuf(result)^.rowcount:= j;
  end;
end;

function tPreparedAccount.getrestsqueueitem;
var i   : longint;
    lst : tList;
begin
  result:= nil;
{
  lst:= tList.create;
  try
    for i:= 0 to count - 1 do
      if assigned(items[i]) then with pAccountParams(items[i])^ do
        if (ostatok <> 0) then lst.add(items[i]);
    with lst do
      if (count > 0) then begin
        result:= new(pQueueData);
        with result^ do begin
          id   := idAccountRests;
          cnt  := 1;
          size := sizeof(tAccountRestsBuf) + count * sizeof(tAccountRestsRow);
          data := allocmem(size);
          pAccountRestsBuf(data)^.account:= account; pAccountRestsBuf(data)^.rowcount:= count;
          for i:= 0 to count - 1 do with pAccountRestsRow(@data[sizeof(tAccountRestsBuf) + i *sizeof(tAccountRestsRow)])^ do begin
            stock_id := pAccountParams(items[i])^.stock_id;
            code     := pAccountParams(items[i])^.code;
            fact     := pAccountParams(items[i])^.ostatok;
            avgprice := 0;
          end;
        end;
      end;
  finally lst.free; end;
}  
end;

end.