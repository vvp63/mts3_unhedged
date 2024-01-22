unit mts3lx_tp;


interface
                                                                                                                                    
uses {$ifdef MSWINDOWS}
        windows,
      {$else}
        cmem,
        cthreads,
      {$endif}
      dynlibs,
      math,
      sysutils,
      classes,
      strings,
      fclinifiles,
      postgres,
      sortedlist,
      servertypes,
      mts3lx_start,
      mts3lx_common,
      mts3lx_sheldue,
      mts3lx_securities,
      mts3lx_otmanager,
      mts3lx_queue;


type  pTPSec  = ^tTPSec;
      tTPSec = record
        SecId       : longint;
        Sec         : pSec;
        TPSecType   : string[5];    //B-Base, H-hedge, R-reverse hedge(for option), C-count like hedge but no not hedge, P - pricedriver and hedge, E - etalon
        Hedge_Kf    : real;
        Hedge_Kf_DB : real;
        PS2PS_Kf    : real;
        PD_Kf       : real;
        PDToSecId   : longint;
        Account     : tAccount;
        //  Количества
        Qty             : longint;
        QtyNeed         : longint;
        QtyBaseHedged   : longint;  //  Количество базового актива реально захеджированного данной бумагой
        //  Время последнего реджекта с биржи по бумаге
        LastRejTime   : TDateTime;
        //  По усреднению
        HasAvgVal     : boolean;
        AvgVal        : real;
        AvgKf         : real;
        AvgMaxDiff    : real;
        AvgMinDiff    : real;
        //  Последнее время заявки по бумаге
        LastOrderTime : TDateTime;
end;


type tTPTradeParams  = record
        DirectStatus    : Boolean;
        InverseStatus   : Boolean;
        BdirectDB       : Real;
        BinverseDB      : Real;
        Bdirect         : Real;
        Binverse        : Real;
        VolMax          : Longint;
        VolEliminated   : Longint;
        BVolChangeDir   : Real;
        BVolChangeInv   : Real;
        BSquareKf       : Real;
        BSquareKfInv    : Real;
        Vmin            : Longint;
        Vmax            : Longint;
        PLmax           : Longint;
        MaxVolBefore    : Longint;
        PSToMove        : Longint;
        VolToMove       : longint;
        HedgeMode       : char;
        Vunhedged       : longint;
        Kunhedged       : real;
        MMaxVol         : longint;    //  Максимальный объем хеджирования в рынок в терминах базового контракта
        MOrderDelay     : longint;    //  Задержка в секундах между хеджированием в маркет
        CashShift       : real;
        RIntPD          : longint;
        RIntPortf       : longint;
end;


type tTPSecList = class(tSortedList)
      procedure   freeitem(item: pointer); override;
      function    checkitem(item: pointer): boolean; override;
      function    compare(item1, item2: pointer): longint; override;
    private
      //  Получаем базовую бумагу пары
      function    GetBaseSec(var aSec : pTPSec) : boolean;
      //  Получаем количества бумаг из БД, возвращаем кол-во базовой бумаги
      function    GetQtys(atpid : longint; var vbasechanged : boolean)  : longint;
end;


type tTP = class(TObject)
        TPId            : longint;
        Name            : string[50];
        TPSecList       : tTPSecList;
        TPParams        : tTPTradeParams;
        LastClTime      : TDateTime;      //  Время вывода последнего базиса в клиент

 //       LastGetAVGTime  : TDateTime;      //  Время считывания последних средних значений
        LastRehPDTime     : TDateTime;      //  Время последнего рехеджа долларом
        LastRehPortfTime  : TDateTime;      //  Время последнего рехеджа портфеля

        PDHedgeActive     : boolean;


        constructor create(aid : longint; const aname  : string); overload;
      public
        //    Котирование - общий вход
        procedure   Quote;
      protected
        //    Считываем бумаги пары
        procedure   LoadSecList;
        //    Перечитываем коэффициенты дополняющих бумаг
        procedure   ReLoadSecListKf;
        //    Считываем торговые параметры пары
        function    LoadParams  : Boolean;
      private
        //    Хеджирование
        function    FullHedging(aBaseSec  : pTPSec) : boolean;
        //    Неполное Хеджирование
        function    NotFullHedging(aBaseSec  : pTPSec) : boolean;
        //    Котирование в прямую сторону
        procedure   DirectInverseQuote(aBuySell : char; aBaseSec  : pTPSec; var avol  : longint; var aprice : real; aonlydrop : boolean = false);
        //    Получаем прайсдрайвер бумаги
        function    GetSecPD(aSecId : longint)  : real;
        //    Получаем усредненный прайсдрайвер бумаги
   //     function    GetSecAvgPD(aSecId: longint): real;
        //   Расчет нужных значений для расчета базисов
        procedure   CountBValues(avol : longint; ashowquotes  : boolean;
                     var aAb, aBb, aAh, aBh, aEt : real;  var aAFull, aBFull : boolean; var aPS, aPD : real);
        //  Непосредственно расчет базисов
        procedure   CountB(avol : longint; ashowquotes  : boolean; var aA, aB, aEt : real;  var aAFull, aBFull, aEtFull : boolean);
        //  Проверка выполнения критериев
        function    CriteriaSatisfied(aV  : longint; aBuySell : char; var aPriceToSet : real) : boolean;
        //  Поиск объемов делением
        function    DefineVDevidingAlt(aVmin, aVmax  : longint; aBuySell : char; var aPriceToSet : real) :  longint;
        //  Пересчитываем базисы в соответствии с объемами
        procedure   RecountBwithV;
        //  Считаем необходимые количества для хеджа
        procedure   CountQtysNeed(aBaseSec: pTPSec; var aBaseQty : longint);
        //  считаем параметры направления
        procedure   DirectionParams(aBuySell : char; aBaseSec  : pTPSec; aprice : real;
                                       var avol : longint; var aBeforeFlag, aDIstatus : boolean);
        //  находятся ли цены на соседних позициях беж чужих заявок между ними (кроме первого  уровня)
        function    HaveLevelBetween(aBuySell : char; aBaseSec  : pTPSec; apriceNew, apriceOld  : real) : boolean;

  {
        //  Считываем и устанавливаем усредненные значения HedgeKf и ошибки
        procedure   SettingAVGKf;
        procedure   SettingAVGKf_PD;
        //  Расчет портфеля через усреднение
        procedure   SettingAVGKf_Portfolio;
        procedure   SettingAVGKf_RehedgePortf(aH, aE, aEPD : real);
        }

end;

type pTP  = ^tTP;


type tTPList = class(tSortedThreadList)
      procedure   freeitem(item: pointer); override;
      function    checkitem(item: pointer): boolean; override;
      function    compare(item1, item2: pointer): longint; override;
    public
      //    Считываем пары из БД
      procedure   LoadFromDB;
      //    Закидываем пары, содержащие бумагу в очередь на котирование
      procedure   TPQuoteToQueue(const acode: tCode; const alevel: tLevel; astockid: longint);
      //    Запускаем котирование выбранной пары
      procedure   QuoteTP(atpid : longint);
      //    Считываем параметры всех пар
      function    LoadAllParams : boolean;
      //  Пересчитать остатки по паре
      procedure   ReloadVols(atpid : longint);
      //  Установить время последнего отказа
      procedure   SetRejTime(atpid, asecid : longint);
end;


const TPList     : tTPList = nil;

procedure InitMTSTP;
procedure DoneMTSTP;




implementation

//uses SimpleADO2, Classes, Math, DateUtils;

{ tTPSecList }

function tTPSecList.checkitem(item: pointer): boolean;
begin
  result:=  assigned(item);
end;

function tTPSecList.compare(item1, item2: pointer): longint;
begin
  result:=  pTPSec(item1)^.SecId - pTPSec(item2)^.SecId;
end;

procedure tTPSecList.freeitem(item: pointer);
begin
  if assigned(item) then dispose(pTPSec(item));
end;



function tTPSecList.GetBaseSec(var aSec: pTPSec): boolean;
var i :longint;
begin
  result:=  false; aSec :=  nil;
  for i:=0 to Count-1 do with pTPSec(items[i])^ do
    if TPSecType = 'B' then begin
      result:=  true; aSec:=  pTPSec(items[i]); break;
    end;
end;

function tTPSecList.GetQtys(atpid : longint; var vbasechanged : boolean)  : longint;
var vtpsec        :tTPSec;
    idx, vqtyold  : longint;
      i     : longint;
      res   : PPGresult;
      SL    : tStringList;
begin

  result:=  0; vbasechanged:= false;
  try
    res := PGQueryMy('SELECT public.gettpqtys(%d)', [atpid]);
    if (PQresultStatus(res) = PGRES_TUPLES_OK) then for i := 0 to PQntuples(res)-1 do begin
      SL :=  QueryResult(PQgetvalue(res, i, 0));
      if SL.Count > 1 then begin
        vtpsec.SecId  :=  StrToIntDef(SL[0], 0);
        if search(@vtpsec, idx) then with pTPSec(Items[idx])^ do begin
          vqtyold:= Qty;
          Qty :=  StrToIntDef(SL[1], 0);
          Filelog('tTPSecList.GetQtys %d %s %d', [atpid, Sec^.code, Qty], 4);
          if (TPSecType = 'B') then begin Result := Qty; vbasechanged:= (Qty <> vqtyold); end;
        end;
      end;;
    end;
  except on e:exception do Filelog(' !!! EXCEPTION: tTPSecList.GetQtys %s', [e.message], 0); end;

end;





{ tTP }


constructor tTP.create(aid: longint; const aname: string);
begin
  TPId:=  aid; Name:= aname;
  TPSecList :=  tTPSecList.create;
end;



procedure tTP.LoadSecList;
var vpTPSec : pTPSec;
      i     : longint;
      res   : PPGresult;
      SL    : tStringList;
begin

  try
    TPSecList.clear;

    res := PGQueryMy('SELECT public.gettpseclist(%d)', [TPId]);
    if (PQresultStatus(res) = PGRES_TUPLES_OK) then for i := 0 to PQntuples(res)-1 do begin
      SL :=  QueryResult(PQgetvalue(res, i, 0));
      if SL.Count > 6 then begin
          new(vpTPSec);
          with vpTPSec^ do begin
            SecId         :=  StrToIntDef(SL[0], 0);
            If Assigned(SecList) then Sec:= SecList.GetSecById(SecId);
            TPSecType     :=  SL[1];
            Hedge_Kf_DB   :=  StrToFloatDef(SL[2], 0);
            Hedge_Kf      :=  Hedge_Kf_DB;
            PD_Kf         :=  StrToFloatDef(SL[3], 0);
            PDToSecId     :=  StrToIntDef(SL[4], 0);
            Account       :=  SL[5];
            PS2PS_Kf      :=  StrToFloatDef(SL[6], 0);
            Qty           :=  0;
            LastRejTime   :=  0;
            HasAvgVal     :=  false;
            AvgVal        :=  0;
            AvgKf         :=  0;
            AvgMaxDiff    :=  0;
            AvgMinDiff    :=  0;
          end;
          if assigned(vpTPSec^.Sec) then TPSecList.add(vpTPSec);
      end;
    end;

  except on e:exception do Filelog(' !!! EXCEPTION: tTP.LoadSecList %s', [e.message], 0); end;

end;


procedure tTP.ReLoadSecListKf;
var vsecid, i : longint;
    vhedgekf  : real;
      res   : PPGresult;
      SL    : tStringList;
      j     : longint;
begin

  with TPSecList do try

    res := PGQueryMy('SELECT public.gettpseclist(%d)', [TPId]);
    if (PQresultStatus(res) = PGRES_TUPLES_OK) then for j := 0 to PQntuples(res)-1 do begin
      SL :=  QueryResult(PQgetvalue(res, j, 0));
      if SL.Count > 6 then begin
        vsecid    :=  StrToIntDef(SL[0], 0);
        vhedgekf  :=  StrToFloatDef(SL[2], 0);
        for i:=0 to Count-1 do with pTPSec(items[i])^ do if SecId = vsecid then Hedge_Kf  :=  vhedgekf;
      end;
    end;

    for i:=0 to Count-1 do with pTPSec(items[i])^ do Filelog('tTP.ReLoadSecListKf %d %d = %.6g', [TPId, SecId, Hedge_Kf], 1);
    
  except on e:exception do Filelog(' !!! EXCEPTION: tTP.ReLoadSecListKf %s', [e.message], 0); end;

end;



function tTP.LoadParams  : Boolean;
var vbd, vbi  : real;
      i     : longint;
      res   : PPGresult;
      SL    : tStringList;
begin

  result:=  true;
  with TPParams do try

    res := PGQueryMy('SELECT public.gettpparams(%d)', [TPId]);
    if (PQresultStatus(res) = PGRES_TUPLES_OK) then for i := 0 to PQntuples(res)-1 do begin
      SL :=  QueryResult(PQgetvalue(res, i, 0));
      if SL.Count > 21 then begin

        DirectStatus    :=  (SL[3] = '1');
        InverseStatus   :=  (SL[4] = '1');
        vbd:= BdirectDB; vbi:= BinverseDB;
        BdirectDB       :=  StrToFloatDef(SL[5], 0);
        BinverseDB      :=  StrToFloatDef(SL[6], 0);
        if (BdirectDB >= BinverseDB) then begin
          BdirectDB:= vbd; BinverseDB:= vbi; Result:=  false;
          msglog('TP %d Params Error BDirect >= BInverse', [TPId]);
        end;
        VolMax          :=  StrToIntDef(SL[7], 0);
        VolEliminated   :=  StrToIntDef(SL[8], 0);
        BVolChangeDir   :=  StrToFloatDef(SL[9], 0);
        BVolChangeInv   :=  StrToFloatDef(SL[10], 0);
        BSquareKf       :=  StrToFloatDef(SL[11], 0);
        BSquareKfInv    :=  StrToFloatDef(SL[12], 0);

        Vmin            :=  StrToIntDef(SL[13], 0);
        Vmax            :=  StrToIntDef(SL[14], 0);
        PLmax           :=  StrToIntDef(SL[15], 0);
        MaxVolBefore    :=  StrToIntDef(SL[16], 0);
        PSToMove        :=  StrToIntDef(SL[17], 0);
        VolToMove       :=  StrToIntDef(SL[18], 0);
        HedgeMode       :=  (SL[19])[1];
        CashShift       :=  StrToFloatDef(SL[20], 0);

        RIntPD          :=  StrToIntDef(SL[21], 0);
        RIntPortf       :=  StrToIntDef(SL[22], 0);

        Vunhedged       :=  StrToIntDef(SL[23], 0);
        Kunhedged       :=  StrToFloatDef(SL[24], 0);

        MMaxVol         :=  StrToIntDef(SL[25], 0);
        MOrderDelay     :=  StrToIntDef(SL[26], 0);

      end;
    end;

  except on e:exception do Filelog(' !!! EXCEPTION: tTP.LoadParams %s', [e.message], 0); end;

end;



procedure tTP.Quote;
var   vA, vB, vEt           : real;
      vBFull, vAFull, vEtFull        : boolean;
      vstatus               : char;
      vPriceS, vPriceB      : real;
      vVolS, vVolB          : longint;
      vBaseSec              : pTPSec;
      vinday, vactinday     : boolean;
      vfullhedged           : boolean;

begin

  FileLog('QS [%d %s]',  [TPId, Name], 1);

  if (PDReloadKfCommand = TPId) then begin
    ReLoadSecListKf;
    PDReloadKfCommand :=  0;
    msglog(TmpFromid, TmpFromuser, 'HedgeKf for TP %d reloaded', [TPId]);
  end;

  if (StartHedgePDCommand = TPId) then begin
    PDHedgeActive     :=  true;
    StartHedgePDCommand :=  0;
    msglog(TmpFromid, TmpFromuser, 'Started PD hedge for TP %d', [TPId]);
  end;

  if (StopHedgePDCommand = TPId) then begin
    PDHedgeActive     :=  false;
    StopHedgePDCommand :=  0;
    msglog(TmpFromid, TmpFromuser, 'Stoped PD hedge for TP %d', [TPId]);
  end;

  //  Забираем новые усредненные коэффициенты
  //SettingAVGKf;

  CountB(TPParams.Vmin, true, vA, vB, vEt, vAFull, vBFull, vEtFull);

   
  vstatus:= #$54;
  if not vAFull and not vBFull then vstatus:= #$43
  else begin
    if not vBFull then vstatus:= #$4F;
    if not vAFull then vstatus:= #$46;
  end;

  //  Выводим в клиент если время пришло


  if (Now > (LastClTime + ClientMessagesDelay * SecDelay)) then begin
    MTSOutputStockAll(Name, format('TP_%d', [TPId]), RoundTo(vA, -1), RoundTo(vB, -1),
                                RoundTo(TPParams.Bdirect, -1), RoundTo(TPParams.Binverse, -1),
                                RoundTo(vEt, -1), RoundTo((vA + vB) / 2 - vEt, -1), vstatus, Now);
    FileLog('--- tTP.Quote     :   Output [%d %s] Dir=%.6g Inv=%.6g Et=%.6g', [TPId, Name, vA, vB, vEt], 1);
    LastClTime  :=  Now;
  end;
   

  vVolB :=  0; vVolS:=  0; vinday:= false; vactinday:=  false;
  if assigned(TradeScheldue) then with TradeScheldue do begin
    vinday:=  GlobalTradeSessionStarted and IsInDay(Now);
    vactinday:= GlobalTradeSessionStarted and IsActiveInDay(Now);
  end;

  if TPSecList.GetBaseSec(vBaseSec) and assigned(vBaseSec) then begin

    if gGlobalHedgeStatus and vinday then begin
      if (TPParams.HedgeMode <> 'N') or (not vactinday) then vfullhedged:= FullHedging(vBaseSec) else vfullhedged:= NotFullHedging(vBaseSec);
    end else vfullhedged:= false;

    FileLog('Q gtss=%s ghs=%s id=%s ida=%s HM=%s fh=%s',
          [BoolToStr(GlobalTradeSessionStarted, true), BoolToStr(gGlobalHedgeStatus, true), BoolToStr(vinday, true),
          BoolToStr(vactinday, true), TPParams.HedgeMode, BoolToStr(vfullhedged, true)], 3);

    DirectInverseQuote('S', vBaseSec, vVolS, vPriceS, not (vactinday and vfullhedged));
    DirectInverseQuote('B', vBaseSec, vVolB, vPriceB, not (vactinday and vfullhedged));
  end;
     
  FileLog('QR [%d %s]  S=%.6g(%d)  B=%.6g(%d) day=%s(%s)',
              [TPId, Name, vPriceS, vVolS, vPriceB, vVolB, BoolToStr(vinday, true), BoolToStr(vactinday, true)], 1);
            

end;




procedure tTP.DirectInverseQuote(aBuySell : char; aBaseSec  : pTPSec; var avol  : longint; var aprice : real; aonlydrop : boolean = false);
var
  vtransid, vquantity     : longint;
  vprice                  : real;
  vorderno                : int64;
  vdroptime               : TDateTime;
  vBeforeFlag, vDIstatus  : boolean;
  vMoveByPrice            : boolean;
begin

  try

    if not(aonlydrop) then begin
      avol :=   DefineVDevidingAlt(TPParams.Vmin, TPParams.Vmax, aBuySell, aprice);
      aprice  :=  aBaseSec^.Sec^.NormalizePrice(aprice);
      DirectionParams(aBuySell, aBaseSec, aprice, avol, vBeforeFlag, vDIstatus);
    end;

    FileLog('DI [%d %s] %s (onlydrop = %s) Need set order V=%d Price=%.6g',
                  [TPId, Name, aBuySell, BoolToStr(aonlydrop, true), avol, aprice], 2);
    vtransid:=  0;

    if assigned(OTManager) then vtransid:=  OTManager.HasActive(aBuySell, TPId, aBaseSec^.SecId, vprice, vquantity, vorderno, vdroptime);

    if (vtransid > 0) then begin
      filelog('DI [%d %s] %s Order exists %d %d %.6g/%d   lastdropat %s',
                        [TPId, Name, aBuySell, vtransid, vorderno, vprice, vquantity, FormatDateTime('hh:mm:ss.zzz', vdroptime)], 2);
      vMoveByPrice:=  HaveLevelBetween(aBuySell, aBaseSec, vprice, aprice) and
                      (abs(aprice - vprice) >= TPParams.PSToMove * aBaseSec^.Sec^.Params.pricestep);
      if (not gGlobalOrderStatus) or (aonlydrop) or (not vDIStatus) or (not vBeforeFlag)
                or vMoveByPrice or (abs(avol - vquantity) >= TPParams.VolToMove) or (avol <= 0) then begin
        //  Надо снимать или передвигать заявку
        filelog('DI [%d %s] %s Need to drop or remove order %d %d (%.6g/%d) (%.6g/%d) status=%s distatus=%s',
                    [TPId, Name, aBuySell, vtransid, vorderno, vprice, vquantity, aprice, avol,
                     BoolToStr(gGlobalOrderStatus, true), BoolToStr(vDIStatus, true)], 3);
        if (vorderno > 0) and ( (now - vdroptime) > 0.3 * SecDelay) and assigned(OTManager) then begin
          if (avol > 0) and (aprice > 0) and vMoveByPrice and vDIStatus and vBeforeFlag
                              then OTManager.MoveMyOrder(vorderno, TPId, vtransid, aBaseSec^.Sec, aBaseSec^.Account, aBuySell, aprice, avol)       //  перестановка
                              else OTManager.DropOrder(vtransid, vorderno, aBaseSec^.Sec, aBaseSec^.Account);                            //  снятие
        end;
      end;

    end else begin

      filelog('DI [%d %s] %s No active orders.  %s lastrejtime=%s',
                [TPId, Name, aBuySell, aBaseSec^.Sec.code, FormatDateTime('dd.mm.yyyy hh:nn:ss.zzz', aBaseSec^.LastRejTime)], 2);

      if gGlobalOrderStatus and (not aonlydrop) and vDIStatus and vBeforeFlag
            and (avol > 0) and ( (now - aBaseSec^.LastRejTime) > 1 * SecDelay) then begin
        if assigned(OTManager) then OTManager.SetMyOrder(TPId, aBaseSec^.Sec, aBaseSec^.Account, aBuySell, aprice, avol);
      end;

    end;

  except on e:exception do FileLog('MTS3LX_TP !!! EXCEPTION: DirectInverseQuote %s', [e.message], 0); end

end;



procedure tTP.DirectionParams(aBuySell: char; aBaseSec: pTPSec; aprice : real;
                                 var avol: longint; var aBeforeFlag, aDIstatus : boolean);
var   vBorderVol, vDirKf    : longint;
      vplbefore, vvolbefore : longint;
begin
  //  Определяем параметры направления
  if (aBaseSec^.Sec^.SecType <> 'I') then begin
    if aBuySell = 'S' then begin
      vBorderVol  :=  TPParams.VolMax; vDirKf:= 1; aDIStatus:=  TPParams.DirectStatus;
      vplbefore   := aBaseSec^.Sec^.Ask.PLVolBefore(aprice, 1, vvolbefore);
    end else begin
      vBorderVol  :=  TPParams.VolEliminated; vDirKf:= -1; aDIStatus:=  TPParams.InverseStatus;
      vplbefore   := aBaseSec^.Sec^.Bid.PLVolBefore(aprice, -1, vvolbefore);
    end;
    avol  :=  Min(avol, vDirKf * (vBorderVol + aBaseSec^.Qty) );   //  Ограничиваем объем
  end else begin
    vplbefore:= 0;  avol:= 0; aBeforeFlag:=  false; aDIstatus:= false; vBorderVol:= 0;
  end;

  if (vplbefore <= TPParams.PLmax) and (vvolbefore <= TPParams.MaxVolBefore) then aBeforeFlag:= true else aBeforeFlag:= false;
  FileLog('MTS3LX_TP. DirectionParams [%d %s] DIstatus=%s BeforeFlag=%s  (%d %d) (%d %d)  Vol=%d Border=%d',
                [TPId, Name, BoolToStr(aDIstatus, true), BoolToStr(aBeforeFlag, true), vplbefore,
                  TPParams.PLmax, vvolbefore, TPParams.MaxVolBefore, avol, vBorderVol], 3);
end;


function tTP.HaveLevelBetween(aBuySell: char; aBaseSec: pTPSec;   apriceNew, apriceOld: real): boolean;
var   vvolbefore, vDirKf, vPLnew, vPLold   : longint;
begin
  result:=  false; vDirKf:= 0; vPLnew:= 0; vPLold:= 0;
  if (aBaseSec^.Sec^.SecType <> 'I') then begin

    if (apriceNew <> apriceOld) then begin
      //  Определяем параметры направления
      if aBuySell = 'S' then begin
        vDirKf:= 1;
        vPLnew   := aBaseSec^.Sec^.Ask.PLVolBefore(apriceNew, 1, vvolbefore);
        vPLold   := aBaseSec^.Sec^.Ask.PLVolBefore(apriceOld, 1, vvolbefore);
      end else begin
        vDirKf:= -1;
        vPLnew   := aBaseSec^.Sec^.Bid.PLVolBefore(apriceNew, -1, vvolbefore);
        vPLold   := aBaseSec^.Sec^.Bid.PLVolBefore(apriceOld, -1, vvolbefore);
      end;

      if (vDirKf * (apriceNew - apriceOld) > 0) then begin
        //  Ставим дальше чем было
        //if abs(vPLnew - vPLold) > 1 then result:= true;
        result:=  true;     //  Когда отходим назад - переставляем даже внутри уровня
      end else begin
        //  Ставим ближе чем было
        if (abs(vPLold - vPLnew) > 0) or (vPLold = 0) then result:= true;
      end;
    end;

  end;

  FileLog('MTS3LX_TP. HaveLevelBetween [%d %s] %s %s (%.6g-%.6g) %d %d %d  result=%s',
                [TPId, Name, aBuySell, aBaseSec^.Sec.code,
                apriceNew, apriceOld, vDirKf, vPLnew, vPLold, BoolToStr(Result, true)], 4);

end;



function tTP.FullHedging(aBaseSec: pTPSec): boolean;
var i, vvol   : longint;
    vprice    : real;
    vbuysell  : char;
    vtransid, vqtytmp, vbaseqty : longint;
    vpricetmp         : real;
    vorderno          : int64;
    vdroptime         : TDateTime;
    vmaxvol           : longint;
begin

  result:=  true;
  CountQtysNeed(aBaseSec, vbaseqty);

  if assigned(TPSecList) then with TPSecList do
  for i:= 0 to Count - 1 do with pTPSec(items[i])^ do if (Sec^.SecType <> 'I') then begin
    if (QtyNeed <> Qty) and (TPSecType <> 'B') and (TPSecType <> 'C') and ((TPSecType <> 'P') OR PDHedgeActive) then begin
      if (QtyNeed > Qty) then begin
        vvol:=  QtyNeed - Qty; vbuysell:=  'B'; vprice:=  Sec.Ask.PriceToVol(vvol);
        if (Sec.SecType = 'F') and (TPParams.HedgeMode = 'M') then vprice:=  Sec.Params.limitpricehigh;
      end else begin
        vvol:=  Qty - QtyNeed; vbuysell:=  'S'; vprice:=  Sec.Bid.PriceToVol(vvol);
        if (Sec.SecType = 'F') and (TPParams.HedgeMode = 'M') then vprice:=  Sec.Params.limitpricelow;
      end;
      FileLog('FullHedging [%d %s] %s Qty=%d QtyNeed=%d Vol=%d BS=%s price=%.6g  %s lastrejtime=%s',
                      [TPId, Name, Sec^.code, Qty, QtyNeed, vvol, vbuysell, vprice,
                      aBaseSec^.Sec.code, FormatDateTime('dd.mm.yyyy hh:nn:ss.zzz', aBaseSec^.LastRejTime)], 2);
      vtransid:=  0;
      if (TPParams.MMaxVol > 0) and (vvol > 0) then begin
          //  Ограничиваем объем заявки
        vmaxvol :=  max(round(TPParams.MMaxVol * Hedge_kf), 1);
        if (vvol > vmaxvol) then vvol := vmaxvol;
        FileLog('FullHedging [%d %s] %s   MaxVolLimit = %d (%d %.6g) Vol=%d',
                      [TPId, Name, Sec^.code, vmaxvol, TPParams.MMaxVol, Hedge_kf, vvol], 3);
      end;


      if assigned(OTManager) then vtransid:=  OTManager.HasActive(vbuysell, TPId, SecId, vpricetmp, vqtytmp, vorderno, vdroptime);
      if (vtransid > 0) then begin
        filelog('FullHedging [%d %s] %s HedgeOrder exists %d %d %.6g/%d lastdrop=%s',
                      [TPId, Name, vbuysell, vtransid, vorderno, vpricetmp, vqtytmp, FormatDateTime('hh:mm:ss.zzz', vdroptime)], 3);
        if (vorderno > 0) and ( (now - vdroptime) > 2 * SecDelay) and assigned(OTManager) then OTManager.DropOrder(vtransid, vorderno, Sec, Account);
      end else begin
       // if TPParams.HedgeMode = 'M' then vmarket:=  true else vmarket:= false;
        if (TPParams.MOrderDelay > 0) and (now - aBaseSec^.LastOrderTime < TPParams.MOrderDelay * SecDelay) then begin
          FileLog('FullHedging [%d %s] %s   Limit by time (%d sec). Last time = %s',
                      [TPId, Name, Sec^.code, TPParams.MOrderDelay, FormatDateTime('hh:mm:ss.zzz', LastOrderTime)], 3);
        end else begin
          if ( (now - aBaseSec^.LastRejTime) > 2 * SecDelay) and assigned(OTManager) then OTManager.SetMyOrder(TPId, Sec, Account, vBuySell, vprice, vvol, TPParams.HedgeMode);
          LastOrderTime :=  now;
        end;

      end;
      result:=  false;

    end;

  end;

end;


function tTP.NotFullHedging(aBaseSec: pTPSec): boolean;
var i, vvol, vbaseqty, vvolm   : longint;
    vprice    : real;
    vbuysell, vordtype            : char;
    vstransid, vbtransid, vsqtytmp, vbqtytmp  : longint;
    vspricetmp, vbpricetmp        : real;
    vsorderno, vborderno          : int64;
    vsdroptime, vbdroptime        : TDateTime;
    vordex                        : boolean;
begin

  FileLog('NotFullHedging start %s', [aBaseSec^.Sec^.code], 3);
  result:=  true;
  CountQtysNeed(aBaseSec, vbaseqty);

  if assigned(TPSecList) then with TPSecList do begin

    for i:= 0 to Count - 1 do with pTPSec(items[i])^ do begin
        if (TPSecType = 'P') and (PDHedgeActive) and (QtyNeed <> Qty) then result:= false;
        if (TPSecType = 'H') and (abs(vbaseqty - QtyBaseHedged) > TPParams.Vunhedged) then result:= false;
    end;


    for i:= 0 to Count - 1 do with pTPSec(items[i])^ do
      if ((TPSecType = 'H') or ((TPSecType = 'P') and PDHedgeActive)) and (QtyNeed <> Qty) then begin
        if (QtyNeed > Qty) then begin
          vvol:=  QtyNeed - Qty; vbuysell:=  'B';
          if (TPSecType = 'P') then vprice:=  Sec.Params.limitpricehigh
                  else vprice:=  Sec.Ask.PriceToVol(0) - Sec.TradeParams.PriceStep;
        end else begin
          vvol:=  Qty - QtyNeed; vbuysell:=  'S';
          if (TPSecType = 'P') then vprice:=  Sec.Params.limitpricelow
                  else vprice:=  Sec.Bid.PriceToVol(0) + Sec.TradeParams.PriceStep;
        end;
        FileLog('NotFullHedging [%d %s] %s Qty=%d QtyNeed=%d Vol=%d BS=%s price=%.6g  %s lastrejtime=%s',
                        [TPId, Name, Sec^.code, Qty, QtyNeed, vvol, vbuysell, vprice,
                        aBaseSec^.Sec.code, FormatDateTime('dd.mm.yyyy hh:nn:ss.zzz', aBaseSec^.LastRejTime)], 2);

        //  Ищем заявки по данной бумаге
        vstransid:=  0;
        if assigned(OTManager) then vstransid:=  OTManager.HasActive('S', TPId, SecId, vspricetmp, vsqtytmp, vsorderno, vsdroptime);
        vbtransid:=  0;
        if assigned(OTManager) then vbtransid:=  OTManager.HasActive('B', TPId, SecId, vbpricetmp, vbqtytmp, vborderno, vbdroptime);

        vordex  := false;
        //  Снимаем заявки, не соответствующие условиям, если такие есть
        if (vstransid > 0) then begin
          vordex  :=  true;
          filelog('NotFullHedging [%d %s] Sell (%s) HedgeOrder exists %d %d %.6g/%d (need %.6g/%d) (%d %d %d) lastdrop=%s',
                        [TPId, Name, vbuysell, vstransid, vsorderno, vspricetmp, vsqtytmp, vprice, vvol,
                         vbaseqty, QtyBaseHedged, TPParams.Vunhedged, FormatDateTime('hh:mm:ss.zzz', vsdroptime)], 3);
          if (TPSecType = 'P') or ((vbuysell <> 'S') or (abs(vprice - vspricetmp) > 1e-10) or (vvol <> vsqtytmp) or (abs(vbaseqty - QtyBaseHedged) > TPParams.Vunhedged)) then
            if (vsorderno > 0) and ( (now - vsdroptime) > SecDelay) and assigned(OTManager) then OTManager.DropOrder(vstransid, vsorderno, Sec, Account);
        end;

        if (vbtransid > 0) then begin
          vordex  :=  true;
          filelog('NotFullHedging [%d %s] Buy (%s) HedgeOrder exists %d %d %.6g/%d (need %.6g/%d) (%d %d %d) lastdrop=%s',
                        [TPId, Name, vbuysell, vbtransid, vborderno, vbpricetmp, vbqtytmp, vprice, vvol,
                         vbaseqty, QtyBaseHedged, TPParams.Vunhedged, FormatDateTime('hh:mm:ss.zzz', vbdroptime)], 3);
          if (TPSecType = 'P') or ((vbuysell <> 'B') or (abs(vprice - vbpricetmp) > 1e-10) or (vvol <> vbqtytmp) or (abs(vbaseqty - QtyBaseHedged) > TPParams.Vunhedged)) then
            if (vborderno > 0) and ( (now - vbdroptime) > SecDelay) and assigned(OTManager) then OTManager.DropOrder(vbtransid, vborderno, Sec, Account);
        end;

        vordtype  :=  'V';
        if not vordex and (vvol > 0) then begin
          filelog('NotFullHedging [%d %s] %s (%s) unhedged. Vol base=%d bh=%d Vunh=%d   Diff=%d',
                  [TPId, Name, Sec^.code, TPSecType, vbaseqty, QtyBaseHedged, TPParams.Vunhedged, abs(vbaseqty - QtyBaseHedged)], 3);
          if (TPSecType <> 'P') and (abs(vbaseqty - QtyBaseHedged) > TPParams.Vunhedged) then begin
            vordtype  :=  'M';
            vvolm  :=  round(vvol * TPParams.Kunhedged);
            if (vvolm > 0) then vvol := vvolm else vvol := 1;
            if (Sec.SecType = 'F') and (vbuysell = 'B') then vprice:=  Sec.Params.limitpricehigh;
            if (Sec.SecType = 'F') and (vbuysell = 'S') then vprice:=  Sec.Params.limitpricelow;
            filelog('NotFullHedging [%d %s] %s unhedged. Vol for market = %d', [TPId, Name, Sec^.code, vvol], 3);
          end;
          if (TPSecType = 'P') then vordtype  :=  'M';
          if assigned(OTManager) then OTManager.SetMyOrder(TPId, Sec, Account, vbuysell, vprice, vvol, vordtype);
        end;

      end;

  end;

end;





procedure tTP.CountQtysNeed(aBaseSec: pTPSec; var aBaseQty : longint);
var i, j, vPDToSecId, vqty, vbaseqty: longint;

begin
  vPDToSecId:=  0; vqty:= 0; vbaseqty := 0;
  if assigned(TPSecList) then with TPSecList do begin
    for i:= 0 to Count - 1 do with pTPSec(items[i])^ do begin
      if TPSecType = 'H' then QtyNeed:= -Round(aBaseSec^.Qty * Hedge_Kf);
      if TPSecType = 'R' then QtyNeed:= Round(aBaseSec^.Qty * Hedge_Kf);
      if (TPSecType = 'B') or (TPSecType = 'C') then begin QtyNeed:= Qty; vbaseqty := Qty; end;
      FileLog('MTS3LX_TP. CountQtysNeed [%d %s] %s QtyNeed=%d Qty=%d  %s', [TPId, Name, Sec^.code, QtyNeed, Qty, TPSecType], 4);
    end;
    for i:= 0 to Count - 1 do with pTPSec(items[i])^ do begin
      if TPSecType = 'P' then begin
        vPDToSecId:=  PDToSecId; vqty:= 0;
        with TPSecList do for j:= 0 to Count - 1 do with pTPSec(items[j])^ do if SecId = vPDToSecId then vqty:= QtyNeed;
        QtyNeed :=  -Round(vqty * Hedge_Kf);
      end;
      if (TPSecType = 'H') and (Hedge_Kf <> 0) then QtyBaseHedged := -Round(Qty / Hedge_Kf) else QtyBaseHedged := 0;
      FileLog('MTS3LX_TP. CountQtysNeed [%d %s] %s QtyNeed=%d Qty=%d QtyBaseHedged=%d  %s (%d %d)',
                        [TPId, Name, Sec^.code, QtyNeed, Qty, QtyBaseHedged, TPSecType, vPDToSecId, vqty], 3);
    end;
  end;
  aBaseQty := vbaseqty;

end;



function  tTP.CriteriaSatisfied(aV  : longint; aBuySell : char; var aPriceToSet : real) : boolean;
var vAb, vBb, vAh, vBh, vEt  : real;
    vAFull, vBFull      : boolean;
    vPS, vPD, vBasis    : real;
begin
  Result:=  false; aPriceToSet:=  0; vBasis:= 0;
  CountBValues(aV, false, vAb, vBb, vAh, vBh, vEt, vAFull, vBFull, vPS, vPD);
  if (vPS > 0) and (vPD > 0) then begin
    if (aBuySell = 'S') then begin
      if vAFull then begin
        vBasis  :=  vAh - vAb * vPD / vPS;
        Result  :=  (vBasis <= TPParams.Bdirect);
        aPriceToSet :=  Round((vAh - TPParams.Bdirect) / vPD) * vPS;
      end
    end else begin
      if vBFull then begin
        vBasis  :=  vBh - vBb * vPD / vPS;
        Result  :=  (vBasis >= TPParams.Binverse);
        aPriceToSet :=  Round((vBh - TPParams.Binverse) / vPD) * vPS;
      end
    end;
  end;
  FileLog('MTS3LX_TP.CriteriaSatisfied [%d %s] V=%d BuySell=%s Basis=%.6g  result=%s(%.6g)',
            [TPId, Name, aV, aBuySell, vBasis, BoolToStr(result, true), aPriceToSet], 3);
end;





function tTP.DefineVDevidingAlt(aVmin, aVmax: longint; aBuySell : char; var aPriceToSet : real): longint;
var vGood, vBad   : longint;
    vTmpPrice     : real;
begin
  vBad:= aVmax + 1; vGood:=  aVMin;
  CriteriaSatisfied(aVmin, aBuySell, aPriceToSet);
  CriteriaSatisfied(aVmax, aBuySell, vTmpPrice);
  if (abs(vTmpPrice - aPriceToSet) < 1e-10) then vGood:= aVmax else vBad:= aVmax;
  if (vGood >= aVmin) and (vGood < aVmax) then
    while true do begin
      if (abs(vBad - vGood) < 2) then break;
      Result:=  round( (vBad + vGood) / 2);
      FileLog('MTS3LX_TP.DefineVDevidingAlt try [%d %s] BuySell=%s Vbad=%d vGood=%d  TryingV=%d', [TPId, Name, aBuySell, vBad, vGood, Result], 3);
      CriteriaSatisfied(result, aBuySell, vTmpPrice);
      if (abs(vTmpPrice - aPriceToSet) < 1e-10) then vGood:= result else vBad:= Result;
    end;
  Result:=  vGood;
  FileLog('MTS3LX_TP.DefineVDevidingAlt [%d %s] BuySell=%s Vmin=%d Vmax=%d Vbad=%d  result=%d(%.6g)',
      [TPId, Name, aBuySell, aVmin, aVmax, vBad, Result, aPriceToSet], 1);
end;




procedure tTP.CountB(avol : longint; ashowquotes  : boolean; var aA, aB, aEt : real;  var aAFull, aBFull, aEtFull : boolean);
var   vAb, vBb, vAh, vBh, vEt : real;
      vPS, vPD                : real;
      vBFull, vAFull          : boolean;
begin
  CountBValues(avol, ashowquotes, vAb, vBb, vAh, vBh, vEt, vAFull, vBFull, vPS, vPD);
  aA  :=  0; aB :=  0; aAFull:= false; aBFull:= false; aEtFull:=  false;
  if (vPS > 0) then begin
    if (vAb > 0) and vAFull then begin aA :=  vAh - vAb * vPD / vPS; aAFull:= true; end;
    if (vBb > 0) and vBFull then begin aB :=  vBh - vBb * vPD / vPS; aBFull:= true; end;
    if (vAb > 0) and (vBb > 0) and (vEt > 0) then begin aEt := vEt - (vAb + vBb) / 2 * vPD / vPS; aEtFull :=  true; end;
  end;
  FileLog('CountB [%d %s] V=%d  Ask(%s)=%.6g  Bid(%s)=%.6g  Et=%.4g  CS=%.4g',
        [TPId, Name, avol, BoolToStr(aAFull, true), aA, BoolToStr(aBFull, true), aB, aEt, TPParams.CashShift], 3);
end;


procedure tTP.CountBValues(avol : longint; ashowquotes  : boolean;
                     var aAb, aBb, aAh, aBh, aEt : real;  var aAFull, aBFull : boolean; var aPS, aPD : real);
var   i, vLotSize           : longint;
      vTmpStr               : string;
      vATmp, vBTmp          : real;
      vPDPS, vEPS           : real;
      vPDfound, vToAvg      : boolean;
      vAvgToadd             : real;
begin
  aAb:= 0; aBb:=  0; aAh:=  TPParams.CashShift;  aBh:= TPParams.CashShift;
  aBFull:=  true; aAFull:=  true;
  aPD :=  1; vPDfound :=  false; aPS  := 1;
  vTmpStr := '';
  if assigned(TradeScheldue) then vToAvg:=  TradeScheldue.IsInDayToAvg(Now) else vToAvg:= false;

  if assigned(TPSecList) then with TPSecList do begin

    for i:= 0 to Count - 1 do with pTPSec(Items[i])^ do begin

      if Sec^.IsActive(ashowquotes) then begin

        vAvgToadd:=   Sec.Params.lastdealprice;

        if ashowquotes then if (Sec^.SecType <> 'I') or (TPSecType = 'C') then Sec^.LogQuotes else Sec^.LogSec;

        //  Базовая бумага
        if TPSecType  = 'B' then begin
          vLotSize  := Sec^.TradeParams.LotSize;
          if ( (Sec^.stockid = 4) or (Sec^.stockid = 5) ) then vLotSize :=  1;
          vATmp :=  Sec^.BasePrice(avol, 'A') * vLotSize; if (vATmp > 0) then aAb  :=  vATmp;
          vBTmp :=  Sec^.BasePrice(avol, 'B') * vLotSize; if (vBTmp > 0) then aBb  :=  vBTmp;
          if not vPDfound then aPD :=  GetSecPD(SecId);
          aPS  :=  Sec^.TradeParams.PriceStep;
          vTmpStr :=  Format('Ask=%g Bid=%.6g PS=%.6g PD=%.6g', [aAb, aBb, aPS, aPD]);
        end;

        //  Эталонная бумага
        if TPSecType  = 'E' then begin
          vEPS  :=  GetSecPD(SecId);
          aEt   :=  Sec^.BasePrice(avol, 'A') * vEPS * Hedge_Kf;
          vAvgToadd :=  vAvgToadd * vEPS;
          vTmpStr :=  Format('Et=%.6g PSEt=%.6g  Hk=%.6g  EToAvg=%.6g', [aEt, vEPS, Hedge_Kf, vAvgToadd]);
        end;

        //  Дополняющая бумага
        if (TPSecType  = 'H') or (TPSecType  = 'R') or (TPSecType = 'C') then begin
          vPDPS:= Sec^.TradeParams.LotSize;
          if Sec^.TradeParams.PriceStep > 0 then vPDPS:=  vPDPS * GetSecPD(SecId) / Sec^.TradeParams.PriceStep;

          if (TPSecType <> 'R') then begin
            vATmp :=  vPDPS * Sec^.AdditionPrice(Hedge_Kf * avol, 'A', (TPSecType = 'C'));
            vBTmp :=  vPDPS * Sec^.AdditionPrice(Hedge_Kf * avol, 'B', (TPSecType = 'C'));
          end else begin
            vATmp :=  vPDPS * Sec^.AdditionPrice(Hedge_Kf * avol, 'B');
            vBTmp :=  vPDPS * Sec^.AdditionPrice(Hedge_Kf * avol, 'A');
          end;

          if (vATmp > 0) then aAh   :=  aAh + Hedge_Kf * PS2PS_Kf * vATmp else aAFull :=  false;
          if (vBTmp > 0) then aBh   :=  aBh + Hedge_Kf * PS2PS_Kf * vBTmp else aBFull :=  false;

          vTmpStr   :=  Format('Ask(%s)=%.6g Bid(%s)=%.6g  PD/PS=%.4g HedgeKf=%.4g  PS2PS_Kf=%.4g',
                [BoolToStr(aAFull, true), vATmp, BoolToStr(aBFull, true), vBTmp, vPDPS, Hedge_Kf, PS2PS_Kf]);
        end;
        if (TPSecType  = 'P') then vTmpStr:=  '';

        FileLog('CountBVal [%d %s]  %s %s %s  %s', [TPId, Name, Sec^.code, Sec^.SecType, TPSecType, vTmpStr], 4);
      end else begin
        FileLog('CountBVal [%d %s]  %s is not active', [TPId, Name, Sec^.code], 4);
        aBFull:=  false; aAFull:=  false;
      end;
    end;

  end;

  if (aPS = 0) then aPS:= 1;
  FileLog('CountBVal [%d %s]  Ask(%s)=%.6g %.6g  Bid(%s)=%.6g %.6g  Et=%.4g  PS=%.4g PD=%.4g',
            [TPId, Name, BoolToStr(aAFull, true), aAb, aAh, BoolToStr(aBFull, true), aBb, aBh, aEt, aPS, aPD], 3);

end;



function tTP.GetSecPD(aSecId: longint): real;
var
    i                 : longint;
    vPDOwn, vPDtrans  : real;
begin
  vPDtrans:=  0; vPDOwn:= 0;
  if assigned(TPSecList) then with TPSecList do
    for i:= 0 to Count - 1 do with pTPSec(Items[i])^ do begin
      if (TPSecType = 'P') and (PDToSecId = aSecId) then begin
        if (Sec^.Params.hibid > 0) and (Sec^.Params.lowoffer > 0)
          then vPDtrans:= (Sec^.Params.hibid + Sec^.Params.lowoffer) / 2 * PD_Kf
          else vPDtrans:= Sec^.Params.lastdealprice * PD_Kf;
      end;
      if SecId = aSecId then
        if (TPSecType <> 'C') then vPDOwn:= Sec^.TradeParams.PriceDriver else vPDOwn:= Sec^.TradeParams.PriceStep;
    end;
  if vPDtrans > 0 then Result:= vPDtrans else
    if vPDOwn > 0 then Result:= vPDOwn else result:=  1;
  FileLog('MTS3LX_TP. GetSecPD %d TransPD=%.4g  OwnPD=%g', [aSecId, vPDtrans, vPDOwn], 4);
end;





procedure tTP.RecountBwithV;
var vSec  : pTPSec;
  //  vVolChange, vsquareshift  : real;
begin
  if TPSecList.GetBaseSec(vSec) then
    with TPParams do begin
    
      if vSec^.Qty <= 0 then begin
        Bdirect   :=  BdirectDB + BVolChangeDir * vSec^.Qty - abs(BSquareKf * vSec^.Qty * vSec^.Qty);
        Binverse  :=  BinverseDB + BVolChangeInv * vSec^.Qty - abs(BSquareKfInv * vSec^.Qty * vSec^.Qty);
      end;

      if vSec^.Qty > 0 then begin
        Bdirect   :=  BdirectDB + BVolChangeDir * vSec^.Qty + abs(BSquareKf * vSec^.Qty * vSec^.Qty);
        Binverse  :=  BinverseDB + BVolChangeInv * vSec^.Qty + abs(BSquareKfInv * vSec^.Qty * vSec^.Qty);
      end;

      Filelog('tTP.RecountBwithV [%d %s] (%.4g %.4g)  DB (%.4g %.4g) (%.4g %.8g)  (%.4g %.8g)  Qty=%d',
        [TPId, Name, Bdirect, Binverse, BdirectDB, BinverseDB,
         BVolChangeDir, BSquareKf, BVolChangeInv, BSquareKfInv, vSec^.Qty], 4);

    end;

end;








{ tTPList }

function tTPList.checkitem(item: pointer): boolean;
begin
  result:=  assigned(item);
end;

function tTPList.compare(item1, item2: pointer): longint;
begin
  result:=  pTP(item1)^.TPId - pTP(item2)^.TPId;
end;

procedure tTPList.freeitem(item: pointer);
begin
  if assigned(item) then try
    freeandnil(pTP(item)^.TPSecList);
  finally dispose(pTP(item));  end;
end;

procedure tTPList.LoadFromDB;
var
    vTP   : tTP;
    vpTP  : pTP;
    i     : longint;
    res   : PPGresult;
    SL    : tStringList;
begin
  locklist;
  try
    clear;
    if (PQstatus(gPGConn) = CONNECTION_OK) then begin
    res := PQexec(gPGConn, 'SELECT public.gettplist()');
      if (PQresultStatus(res) <> PGRES_TUPLES_OK) then log('MTS3LX_TP. LoadFromDB gettplist() error')
      else
        for i := 0 to PQntuples(res)-1 do begin
          SL :=  QueryResult(PQgetvalue(res, i, 0));
          if SL.Count > 1 then begin
              vTP  :=  tTP.Create(StrToIntDef(SL[0], 0), SL[1]);
              with vTP do FileLog('MTS3LX_TP. LoadFromDB Adding  %d %s', [TPId, Name], 1);
              new(vpTP); vpTP^  :=  vTP; add(vpTP);
          end;
        end;
      PQclear(res);
    end;
  finally unlocklist; end;
  FileLog('MTS3LX_TP. LoadFromDB %d tradepairs Loaded', [Count], 1);
end;



procedure tTPList.TPQuoteToQueue(const acode: tCode; const alevel: tLevel; astockid: longint);
var i, j        : longint;
    vsecinlist  : boolean;
    vqueue      : tQueueItem;
begin

  with locklist do try
    for i:= 0 to Count - 1 do with pTP(Items[i])^ do begin
      vsecinlist  :=  false;
      with TPSecList do
        for j:= 0 to Count - 1 do with pTPSec(Items[j])^.Sec^ do
          if (code = acode) and (level = alevel) and (stockid = astockid) then begin
            vsecinlist:=  true; break;
          end;
      if vsecinlist and assigned(AllQueue) and (not AllQueue.IsTPToQuote(TPId)) then begin
        vqueue.evTime:=  Now; vqueue.evType:= ev_type_quoteTP; vqueue.evTPId:=  TPId;
        AllQueue.push(vqueue);
      end;
    end;
  finally unlocklist; end;

end;



procedure tTPList.QuoteTP(atpid: longint);
var i : longint;
begin
  with locklist do try
    for i:= 0 to Count - 1 do if pTP(Items[i])^.TPId = atpid then pTP(Items[i])^.Quote;
  finally unlocklist; end;
end;



function  tTPList.LoadAllParams : boolean;
var i       : longint;
begin
  result:=  true;
  with locklist do try
    for i:= 0 to TPList.Count - 1 do with pTP(TPList.Items[i])^ do begin
      if not LoadParams then Result:= false;
      RecountBwithV;
      FileLog('MTS3LX_TP. LoadAllParams %d %s', [TPId, Name], 3);
    end;
  finally unlocklist; end;
end;


procedure tTPList.ReloadVols(atpid: longint);
var i, vvol   : longint;
    vchanged  : boolean;
begin
  with locklist do try
    for i:= 0 to Count - 1 do with pTP(Items[i])^ do if ( (TPId = atpid) or (atpid = -1)) then begin
      vvol:=  TPSecList.GetQtys(TPId, vchanged);
      RecountBwithV;
  //  TODO  unblock

      if vchanged then begin
        if (-vvol >= TPParams.VolMax) then msglog('TP %d (%s) VolMax(%d) reached', [TPId, Name, TPParams.VolMax]);
        if (vvol >= -TPParams.VolEliminated) then msglog('TP %d (%s) VolEliminated(%d) reached', [TPId, Name, TPParams.VolEliminated]);
      end;

    end;
  finally unlocklist; end;
end;


procedure tTPList.SetRejTime(atpid, asecid: longint);
var i, j : longint;
begin

  with locklist do try
    for i:= 0 to Count - 1 do with pTP(Items[i])^ do if TPId = atpid then
      with TPSecList do for j:= 0 to Count - 1 do with pTPSec(Items[j])^ do
        if SecId = asecid then begin
          LastRejTime:= 0;
          filelog('tTPList.SetRejTime %d %d = %s', [atpid, asecid, FormatDateTime('dd.mm.yyyy hh:nn:ss.zzz', LastRejTime)], 4);
        end;
  finally unlocklist; end;

end;



//  -------------------------------




procedure InitMTSTP;
var i : longint;
    vDayBegin : TDateTime;
begin
  try
    TPList:= tTPList.create;
    if assigned(TPList) then TPList.LoadFromDB;
    if assigned(TradeScheldue) then vDayBegin:=  Trunc(Now) + TradeScheldue.DayStartTime else vDayBegin:= Now;
    if (vDayBegin < Now) then vDayBegin:= Now;

    for i:= 0 to TPList.Count - 1 do with pTP(TPList.Items[i])^ do begin
      FileLog('MTS3LX_TP. InitMTSTP %d %s  DayBeg=%.6g', [TPId, Name, vDayBegin], 3);
      LastClTime      :=  0;

      LastRehPDTime     :=  vDayBegin;
      LastRehPortfTime  :=  vDayBegin;

      PDHedgeActive     :=  true;

      LoadSecList;
      LoadParams;
      TPList.ReloadVols(TPId);
    end;
    log('MTS3LX_TP   :   Started');
  except on e:exception do FileLog('MTS3LX_TP !!! EXCEPTION: TP %s', [e.message], 0); end;
end;



procedure DoneMTSTP;
begin
   if assigned(TPList) then freeandnil(TPList);
   log('MTS3LX_TP   :   Finished');
end;






end.

