{$i terminal_defs.pas}

unit encoders;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$endif}
      classes, sysutils, math,
      servertypes, remotetypes, protodef, fields,
      lowlevel, sortedlist, itzip, rc5, queue, proto_out;

const minimum_compression_size = 4096;

//--- client encoders ------------------------------------------------

const SecuritiesNames     : array [0..43] of pAnsiChar =
      ( fld_Stock_ID,        fld_ShortName,        fld_Level,            fld_Code,             fld_HiBid,
        fld_LowOffer,        fld_InitPrice,        fld_MaxPrice,         fld_MinPrice,         fld_MeanPrice,
        fld_MeanType,        fld_Cnange,           fld_Value,            fld_Amount,           fld_LotSize,
        fld_FaceValue,       fld_LastDealPrice,    fld_LastDealSize,     fld_LastDealQty,      fld_LastDealTime,
        fld_gko_accr,        fld_gko_yield,        fld_gko_matdate,      fld_gko_cuponval,     fld_gko_nextcupon,
        fld_gko_cuponperiod, fld_BidDepth,         fld_OfferDepth,       fld_NumBids,          fld_NumOffers,
        fld_TradingStatus,   fld_ClosePrice,       fld_Gko_IssueSize,    fld_Gko_BuyBackPrice, fld_Gko_BuyBackDate,
        fld_PrevPrice,       fld_Fut_Deposit,      fld_Fut_Openedpos,    fld_MarketPrice,      fld_LimitPriceHigh,
        fld_LimitPriceLow,   fld_Decimals,         fld_PriceStep,        fld_StepPrice);

type  tSecuritiesEncoder  = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const KotirovkiNames      : array [0..6] of pAnsiChar =
      ( fld_Stock_ID,        fld_Level,            fld_Code,             fld_buysell,          fld_price,
        fld_quantity,        fld_gko_yield );

type  tKotirovkiEncoder   = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const AccountNames        : array [0..11] of pAnsiChar =
      ( fld_Account,         fld_Stock_ID,         fld_Code,             fld_Fact,             fld_Plan,
        fld_FactDebts,       fld_PlanDebts,        fld_Reserved,         fld_Res_pos,          fld_Res_ord,
        fld_NegVarMarg,      fld_CurVarMarg );

type  tAccountEncoder     = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const OrdersNames         : array [0..16] of pAnsiChar =
      ( fld_Stock_ID,        fld_Level,            fld_Code,             fld_OrderNo,          fld_Time,
        fld_Status,          fld_BuySell,          fld_Account,          fld_Price,            fld_Quantity,
        fld_Value,           fld_ClientId,         fld_Balance,          fld_Comment,          fld_Trs_ID,
        fld_InternalID,      fld_OrderType );

type  tOrdersEncoder      = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const TradesNames         : array [0..16] of pAnsiChar =
      ( fld_Stock_ID,        fld_TradeNo,          fld_OrderNo,          fld_Time,             fld_Level,
        fld_Code,            fld_BuySell,          fld_Account,          fld_Price,            fld_Quantity,
        fld_Value,           fld_Gko_Accr,         fld_Clientid,         fld_Comment,          fld_Trs_ID,
        fld_InternalID,      fld_TradeType );

type  tTradesEncoder      = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const AllTradesNames      : array [0..10] of pAnsiChar =
      ( fld_Stock_ID,        fld_TradeNo,          fld_Time,             fld_Level,            fld_Code,
        fld_Price,           fld_Quantity,         fld_Value,            fld_BuySell,          fld_RepoRate,
        fld_RepoTerm );

type  tAllTradesEncoder   = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const MarginLevelNames    : array [0..3] of pAnsiChar =
      ( fld_Account,         fld_FactLvl,          fld_PlanLvl,          fld_MinLvl );

type  tMarginLevelEncoder = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const MarginInfoNames     : array [0..2] of pAnsiChar =
      ( fld_NormLvl,         fld_WarnLvl,          fld_CritLvl );

type  tMarginInfoEncoder = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const TrsResultNames      : array [0..4] of pAnsiChar =
      ( fld_Trs_ID,          fld_ErrorCode,        fld_Quantity,         fld_Reserved,         fld_Message );

type  tTrsResultEncoder   = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const StockListNames      : array [0..2] of pAnsiChar =
      ( fld_Stock_ID,         fld_StockName,       fld_StockFlags );

type  tStockListEncoder   = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const LevelListNames      : array [0..5] of pAnsiChar =
      ( fld_Stock_ID,         fld_Level,           fld_MarketCode,       fld_LevelType,        fld_Default,
        fld_Description );

type  tLevelListEncoder   = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const AccountListNames    : array [0..6] of pAnsiChar =
      ( fld_Stock_ID,         fld_Account,         fld_AccountFlags,     fld_Description,      fld_NormLvl,
        fld_WarnLvl,          fld_CritLvl );

type  tAccountListEncoder = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const ReportNames         : array [0..19] of pAnsiChar =
      ( fld_key,              fld_StartDate,       fld_FinDate,          fld_FullName,         fld_Address,
        fld_PrcNDS,           fld_ShortName,       fld_Quantity,         fld_TradeNo,          fld_Time,
        fld_BuySell,          fld_Price,           fld_Summ,             fld_gko_accr,         fld_BKomiss,
        fld_SKomiss,          fld_MoveDate,        fld_Attrib,           fld_Comment,          fld_Code );

type  tReportEncoder      = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const ArcTradesNames      : array [0..7] of pAnsiChar =
      ( fld_Account,          fld_Stock_ID,        fld_Code,             fld_TradeNo,          fld_Time,
        fld_Price,            fld_Quantity,        fld_Gko_Accr );

type  tArcTradesEncoder   = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const StopOrdersNames     : array [0..14] of pAnsiChar =
      ( fld_Stock_ID,        fld_Level,            fld_Code,             fld_BuySell,          fld_Price,
        fld_Quantity,        fld_Account,          fld_Flags,            fld_Stop_ID,          fld_Time,
        fld_Status,          fld_StopType,         fld_StopPrice,        fld_ExpireDate,       fld_Comment );

type  tStopOrdersEncoder  = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const NewsNames           : array [0..4] of pAnsiChar =
      ( fld_News_ID,         fld_NewsProvider,     fld_Time,             fld_Subj,             fld_Text );

type  tNewsEncoder        = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const PingNames           : array [0..0] of pAnsiChar =
      ( fld_Trs_ID );

type  tPingEncoder        = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;

const ConsoleLogNames      : array [0..0] of pAnsiChar =
      ( fld_Message );

type  tConsoleLogEncoder   = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;

const ClientLimitNames    : array[0..10] of pAnsiChar =
      ( fld_Account,         fld_Stock_ID,         fld_Code,             fld_OldLimit,         fld_StartLimit,
        fld_Free,            fld_Reserved,         fld_Res_pos,          fld_Res_ord,          fld_NegVarMarg,
        fld_CurVarMarg );

type  tClientLimitEncoder = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const AccountRestsNames   : array[0..4] of pAnsiChar =
      ( fld_Account,         fld_Stock_ID,         fld_Code,             fld_Fact,             fld_MeanPrice );

type  tAccRestsEncoder    = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const LiquidListNames     : array[0..2] of pAnsiChar =
      ( fld_Stock_ID,         fld_Level,           fld_Code );

type  tLiquidListEncoder  = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const FirmInfoNames       : array[0..3] of pAnsiChar =
      ( fld_Stock_ID,         fld_Firm_ID,         fld_Description,      fld_Status );

type  tFirmInfoEncoder    = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const SettleCodesNames       : array[0..4] of pAnsiChar =
      ( fld_Stock_ID,         fld_SettleCode,      fld_Description,      fld_SettleDate1,
        fld_SettleDate2 );

type  tSettleCodesEncoder    = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const IndLimitsNames         : array[0..3] of pAnsiChar =
      ( fld_Account,          fld_Stock_ID,         fld_Code,            fld_StartLimit );

type  tIndLimitsEncoder      = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;

//--- remote control encoders ----------------------------------------

const ConnInfoNames       : array [0..3] of pAnsiChar =
      ( fld_ClientId,        fld_UserName,         fld_Flags,            fld_RealName );

type  tConnInfoEncoder    = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const SrvStatusNames      : array [0..1] of pAnsiChar =
      ( fld_Flags,           fld_Time );

type  tSrvStatusEncoder   = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


const UserMsgNames        : array [0..3] of pAnsiChar =
      ( fld_ClientId,        fld_UserName,         fld_Time,             fld_Message );

type  tUserMsgEncoder     = class(tEncoderStream)
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pAnsiChar; datasize: longint); override;
      end;


type  tUniversalEncoder   = class(tEncoderStream)
        procedure   startencode(internalid: byte); override;
        procedure   stopencode(key: pKey); override;
        procedure   generatedescriptor; override;
        procedure   encoderow(item: pansichar; datasize: longint); override;
      end;

//--- encoder registry -----------------------------------------------

type  pEncRegistryItm     = ^tEncRegistryItm;
      tEncRegistryItm     = record
        id                : longint;
        encoder           : tEncoderStream;
      end;

type  tEncoderRegistry    = class(tSortedList)
      private
        fbuffer           : tMemoryStream;
      public
        constructor create(abuf: tMemoryStream);
        procedure   freeitem(item: pointer); override;
        function    checkitem(item: pointer): boolean; override;
        function    compare(item1, item2: pointer): longint; override;
        procedure   add(id: longint; data: pAnsiChar; datasize: longint); reintroduce; virtual;
        procedure   stopencode(key: pKey);
      end;

implementation

procedure tSecuritiesEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idWaitSec;
      tablename : pAnsiChar = tbl_Securities;
begin
  StartEncode(idTableDescr);
  write(tableid, sizeof(byte));
  write(tablename^,strlen(tablename)+1);
  for i:= low(SecuritiesNames) to high(SecuritiesNames) do write(SecuritiesNames[i]^, strlen(SecuritiesNames[i]) + 1);
  StopEncode(nil);
end;

procedure tSecuritiesEncoder.encoderow;
var   mask      : int64;
      spos,pos  : longint;
begin
 if assigned(item) then with pSecuritiesItem(item)^ do 
  if not (secset=[sec_stock_id,sec_level,sec_code]) then begin
   inc(frame.rowcount);
   spos:=position; mask:= 0;
   write(mask, 6);
   with sec do begin
                                                 mask := mask or $000000000001; writevalue([stock_id]);
    if sec_shortname in secset        then begin mask := mask or $000000000002; writevalue([shortname]);        end;
                                                 mask := mask or $000000000004; writevalue([level]);
                                                 mask := mask or $000000000008; writevalue([code]);
    if sec_hibid in secset            then begin mask := mask or $000000000010; writevalue([hibid]);            end;
    if sec_lowoffer in secset         then begin mask := mask or $000000000020; writevalue([lowoffer]);         end;
    if sec_initprice in secset        then begin mask := mask or $000000000040; writevalue([initprice]);        end;
    if sec_maxprice in secset         then begin mask := mask or $000000000080; writevalue([maxprice]);         end;
    if sec_minprice in secset         then begin mask := mask or $000000000100; writevalue([minprice]);         end;
    if sec_meanprice in secset        then begin mask := mask or $000000000200; writevalue([meanprice]);        end;
    if sec_meantype in secset         then begin mask := mask or $000000000400; writevalue([meantype]);         end;
    if sec_change in secset           then begin mask := mask or $000000000800; writevalue([change]);           end;
    if sec_value in secset            then begin mask := mask or $000000001000; writevalue([value]);            end;
    if sec_amount in secset           then begin mask := mask or $000000002000; writevalue([amount]);           end;
    if sec_lotsize in secset          then begin mask := mask or $000000004000; writevalue([lotsize]);          end;
    if sec_facevalue in secset        then begin mask := mask or $000000008000; writevalue([facevalue]);        end;
    if sec_lastdealprice in secset    then begin mask := mask or $000000010000; writevalue([lastdealprice]);    end;
    if sec_lastdealsize in secset     then begin mask := mask or $000000020000; writevalue([lastdealsize]);     end;
    if sec_lastdealqty in secset      then begin mask := mask or $000000040000; writevalue([lastdealqty]);      end;
    if sec_lastdealtime in secset     then begin mask := mask or $000000080000;
                                                 writevalue([formatdatetime(stddtformat,lastdealtime)]);      end;
    if sec_gko_accr in secset         then begin mask := mask or $000000100000; writevalue([gko_accr]);         end;
    if sec_gko_yield in secset        then begin mask := mask or $000000200000; writevalue([gko_yield]);        end;
    if sec_gko_matdate in secset      then begin mask := mask or $000000400000;
                                                 writevalue([formatdatetime(stddtformat,gko_matdate)]);       end;
    if sec_gko_cuponval in secset     then begin mask := mask or $000000800000; writevalue([gko_cuponval]);     end;
    if sec_gko_nextcupon in secset    then begin mask := mask or $000001000000;
                                                 writevalue([formatdatetime(stddtformat,gko_nextcupon)]);     end;
    if sec_gko_cuponperiod in secset  then begin mask := mask or $000002000000; writevalue([gko_cuponperiod]);  end;
    if sec_biddepth in secset         then begin mask := mask or $000004000000; writevalue([biddepth]);         end;
    if sec_offerdepth in secset       then begin mask := mask or $000008000000; writevalue([offerdepth]);       end;
    if sec_numbids in secset          then begin mask := mask or $000010000000; writevalue([numbids]);          end;
    if sec_numoffers in secset        then begin mask := mask or $000020000000; writevalue([numoffers]);        end;
    if sec_tradingstatus in secset    then begin mask := mask or $000040000000; writevalue([tradingstatus]);    end;
    if sec_closeprice in secset       then begin mask := mask or $000080000000; writevalue([closeprice]);       end;
    if sec_gko_issuesize in secset    then begin mask := mask or $000100000000; writevalue([gko_issuesize]);    end;
    if sec_gko_buybackprice in secset then begin mask := mask or $000200000000; writevalue([gko_buybackprice]); end;
    if sec_gko_buybackdate in secset  then begin mask := mask or $000400000000;
                                                 writevalue([formatdatetime(stddtformat,gko_buybackdate)]);   end;
    if sec_prev_price in secset       then begin mask := mask or $000800000000; writevalue([prev_price]);       end;
    if sec_fut_deposit in secset      then begin mask := mask or $001000000000; writevalue([fut_deposit]);      end;
    if sec_fut_openedpos in secset    then begin mask := mask or $002000000000; writevalue([fut_openedpos]);    end;
    if sec_marketprice in secset      then begin mask := mask or $004000000000; writevalue([marketprice]);      end;
    if sec_limitpricehigh in secset   then begin mask := mask or $008000000000; writevalue([limitpricehigh]);   end;
    if sec_limitpricelow in secset    then begin mask := mask or $010000000000; writevalue([limitpricelow]);    end;
    if sec_decimals  in secset        then begin mask := mask or $020000000000; writevalue([decimals]);         end;
    if sec_pricestep in secset        then begin mask := mask or $040000000000; writevalue([pricestep]);        end;
    if sec_stepprice in secset        then begin mask := mask or $080000000000; writevalue([stepprice]);        end;
   end;
   pos:= position; seek(spos, soFromBeginning); write(mask, 6); seek(pos, soFromBeginning);
  end;
end;

// -------------------------------------------------------------------

procedure tKotirovkiEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idKotUpdates;
      tablename : pAnsiChar = tbl_Kotirovki;
begin
 StartEncode(idTableDescr);
 write(tableid, sizeof(byte));
 write(tablename^,strlen(tablename)+1);
 for i:=low(KotirovkiNames) to high(KotirovkiNames) do write(KotirovkiNames[i]^,strlen(KotirovkiNames[i])+1);
 StopEncode(nil);
end;

procedure tKotirovkiEncoder.encoderow;
var   i,idx : longint;
const hm    : byte = $7;
      dm    : byte = $78;
begin
  if assigned(item) then with pKotUpdateHdr(item)^ do begin
    inc(frame.rowcount);
    write(hm,sizeof(byte));
    writevalue([stock_id,level,code]);
    idx:=sizeof(tKotUpdateHdr);
    for i:=0 to kotcount-1 do begin
      write(dm,sizeof(byte));
      with pKotUpdateItem(@item[idx])^ do writevalue([buysell,price,quantity,gko_yield]);
      inc(idx,sizeof(tKotUpdateItem));
    end;
  end;
end;

// -------------------------------------------------------------------

procedure tAccountEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idAccount;
      tablename : pAnsiChar = tbl_Account;
begin
 StartEncode(idTableDescr);
 write(tableid, sizeof(byte));
 write(tablename^,strlen(tablename)+1);
 for i:=low(AccountNames) to high(AccountNames) do write(AccountNames[i]^,strlen(AccountNames[i])+1);
 StopEncode(nil);
end;

procedure tAccountEncoder.encoderow;
var   i,idx     : longint;
      pos, spos : longint;
      mask      : word;
const hm        : word = $1;

begin
  if assigned(item) then with pAccountBuf(item)^ do begin
    inc(frame.rowcount);
    write(hm, sizeof(word));
    writevalue([account]);
    idx:= sizeof(tAccountBuf);
    for i:= 0 to rowcount - 1 do begin
      spos:= position; mask:= 0; write(mask, sizeof(word));
      with pAccountRow(@item[idx])^ do begin
                                                mask:= mask or $0002; writevalue([stock_id]);
                                                mask:= mask or $0004; writevalue([code]);
        if acc_fact        in fields then begin mask:= mask or $0008; writevalue([fact]);       end;
        if acc_plan        in fields then begin mask:= mask or $0010; writevalue([plan]);       end;
        if acc_fdbt        in fields then begin mask:= mask or $0020; writevalue([fdbt]);       end;
        if acc_pdbt        in fields then begin mask:= mask or $0040; writevalue([pdbt]);       end;
        if acc_reserved    in fields then begin mask:= mask or $0080; writevalue([reserved]);   end;
        if acc_res_pos     in fields then begin mask:= mask or $0100; writevalue([res_pos]);    end;
        if acc_res_ord     in fields then begin mask:= mask or $0200; writevalue([res_ord]);    end;
        if acc_negvarmarg  in fields then begin mask:= mask or $0400; writevalue([negvarmarg]); end;
        if acc_curvarmarg  in fields then begin mask:= mask or $0800; writevalue([curvarmarg]); end;
      end;
      pos:= position; seek(spos, soFromBeginning); write(mask, sizeof(word)); seek(pos, soFromBeginning);
      inc(idx, sizeof(tAccountRow));
    end;
  end;
end;

// -------------------------------------------------------------------

procedure tOrdersEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idWaitOrders;
      tablename : pAnsiChar = tbl_Orders;
begin
 StartEncode(idTableDescr);
 write(tableid, sizeof(byte));
 write(tablename^,strlen(tablename)+1);
 for i:=low(OrdersNames) to high(OrdersNames) do write(OrdersNames[i]^,strlen(OrdersNames[i])+1);
 StopEncode(nil);
end;

procedure tOrdersEncoder.encoderow;
var mask      : longint;
    spos,pos  : longint;
begin
 if assigned(item) then with pOrdCollItm(item)^ do
  if not (ordset=[ord_stock_id,ord_orderno]) then begin
   inc(frame.rowcount);
   spos:=position; mask:=0;
   write(mask,3);
   with ord do begin
                                          mask := mask or $000001; writevalue([stock_id]);
    if ord_level     in ordset then begin mask := mask or $000002; writevalue([level]);          end;
    if ord_code      in ordset then begin mask := mask or $000004; writevalue([code]);           end;
                                          mask := mask or $000008; writevalue([orderno]);
    if ord_ordertime in ordset then begin mask := mask or $000010;
                                          writevalue([formatdatetime(stddtformat,ordertime)]);   end;
    if ord_status    in ordset then begin mask := mask or $000020; writevalue([status]);         end;
    if ord_buysell   in ordset then begin mask := mask or $000040; writevalue([buysell]);        end;
    if ord_account   in ordset then begin mask := mask or $000080; writevalue([account]);        end;
    if ord_price     in ordset then begin mask := mask or $000100; writevalue([price]);          end;
    if ord_quantity  in ordset then begin mask := mask or $000200; writevalue([quantity]);       end;
    if ord_value     in ordset then begin mask := mask or $000400; writevalue([value]);          end;
    if ord_clientid  in ordset then begin mask := mask or $000800; writevalue([clientid]);       end;
    if ord_balance   in ordset then begin mask := mask or $001000; writevalue([balance]);        end;
    if ord_comment   in ordset then begin mask := mask or $002000; writevalue([comment]);        end;
                                          mask := mask or $004000; writevalue([transaction]);
                                          mask := mask or $008000; writevalue([internalid]);
    if ord_ordertype in ordset then begin mask := mask or $010000; writevalue([ordertype]);      end;
   end;
   pos:= position; seek(spos, soFromBeginning); write(mask, 3); seek(pos, soFromBeginning);
  end;
end;

// -------------------------------------------------------------------

procedure tTradesEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idWaitTrades;
      tablename : pAnsiChar = tbl_Trades;
begin
 StartEncode(idTableDescr);
 write(tableid, sizeof(byte));
 write(tablename^,strlen(tablename)+1);
 for i:=low(TradesNames) to high(TradesNames) do write(TradesNames[i]^,strlen(TradesNames[i])+1);
 StopEncode(nil);
end;

procedure tTradesEncoder.encoderow;
var mask      : longint;
    spos,pos  : longint;
begin
 if assigned(item) then with pTrdCollItm(item)^ do
  if not (Trdset=[trd_stock_id,trd_tradeno]) then begin
   inc(frame.rowcount);
   spos:=position; mask:=0;
   write(mask,3);
   with trd do begin
                                          mask := mask or $000001; writevalue([stock_id]);
                                          mask := mask or $000002; writevalue([tradeno]);
    if trd_orderno   in trdset then begin mask := mask or $000004; writevalue([orderno]);          end;
    if trd_tradetime in trdset then begin mask := mask or $000008;
                                          writevalue([formatdatetime(stddtformat,tradetime)]);     end;
    if trd_level     in trdset then begin mask := mask or $000010; writevalue([level]);            end;
    if trd_code      in trdset then begin mask := mask or $000020; writevalue([code]);             end;
    if trd_buysell   in trdset then begin mask := mask or $000040; writevalue([buysell]);          end;
    if trd_account   in trdset then begin mask := mask or $000080; writevalue([account]);          end;
    if trd_price     in trdset then begin mask := mask or $000100; writevalue([price]);            end;
    if trd_quantity  in trdset then begin mask := mask or $000200; writevalue([quantity]);         end;
    if trd_value     in trdset then begin mask := mask or $000400; writevalue([value]);            end;
    if trd_accr      in trdset then begin mask := mask or $000800; writevalue([accr]);             end;
    if trd_clientid  in trdset then begin mask := mask or $001000; writevalue([clientid]);         end;
    if trd_comment   in trdset then begin mask := mask or $002000; writevalue([comment]);          end;
                                          mask := mask or $004000; writevalue([transaction]);
                                          mask := mask or $008000; writevalue([internalid]);
    if trd_tradetype in trdset then begin mask := mask or $010000; writevalue([tradetype]);        end;
   end;
   pos:= position; seek(spos, soFromBeginning); write(mask, 3); seek(pos, soFromBeginning);
  end;
end;

// -------------------------------------------------------------------

procedure tAllTradesEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idWaitAllTrades;
      tablename : pAnsiChar = tbl_AllTrades;
begin
 StartEncode(idTableDescr);
 write(tableid, sizeof(byte));
 write(tablename^,strlen(tablename)+1);
 for i:=low(AllTradesNames) to high(AllTradesNames) do write(AllTradesNames[i]^,strlen(AllTradesNames[i])+1);
 StopEncode(nil);
end;

procedure tAllTradesEncoder.encoderow;
const dm : word = $07ff;
begin
 if assigned(item) then with pAllTrades(item)^ do begin
  inc(frame.rowcount);
  write(dm,sizeof(dm));
  writevalue([stock_id,tradeno,formatdatetime(stddtformat,tradetime),level,code,price,quantity,value,buysell,reporate,repoterm]);
 end;
end;

// -------------------------------------------------------------------

procedure tMarginLevelEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idMarginLevel;
      tablename : pAnsiChar = tbl_MarginLevel;
begin
 StartEncode(idTableDescr);
 write(tableid, sizeof(byte));
 write(tablename^,strlen(tablename)+1);
 for i:=low(MarginLevelNames) to high(MarginLevelNames) do write(MarginLevelNames[i]^,strlen(MarginLevelNames[i])+1);
 StopEncode(nil);
end;

procedure tMarginLevelEncoder.encoderow;
const dm  : byte = $0f;
 function round3dgt(var r:real):extended;
 const prc = 100000;
 begin result:=round(r*prc)/prc; end;
begin
 if assigned(item) then with pMarginLevel(item)^ do begin
  inc(frame.rowcount);
  write(dm,sizeof(byte));
  writevalue([account,round3dgt(factlvl),round3dgt(planlvl),round3dgt(minlvl)]);
 end;
end;

// -------------------------------------------------------------------

procedure tMarginInfoEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idMarginInfo;
      tablename : pAnsiChar = tbl_MarginInfo;
begin
 StartEncode(idTableDescr);
 write(tableid, sizeof(byte));
 write(tablename^,strlen(tablename)+1);
 for i:=low(MarginInfoNames) to high(MarginInfoNames) do write(MarginInfoNames[i]^,strlen(MarginInfoNames[i])+1);
 StopEncode(nil);
end;

procedure tMarginInfoEncoder.encoderow;
const dm : byte = $07;
begin
 if assigned(item) then with pMarginInfo(item)^ do begin
  inc(frame.rowcount);
  write(dm,sizeof(byte));
  writevalue([normal,warning,critical]);
 end;
end;

// -------------------------------------------------------------------

procedure tTrsResultEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idTrsResult;
      tablename : pAnsiChar = tbl_TrsResult;
begin
 StartEncode(idTableDescr);
 write(tableid, sizeof(byte));
 write(tablename^, strlen(tablename) + 1);
 for i:=low(TrsResultNames) to high(TrsResultNames) do write(TrsResultNames[i]^, strlen(TrsResultNames[i]) + 1);
 StopEncode(nil);
end;

procedure tTrsResultEncoder.encoderow;
var   strlen : longint;
      mask   : byte;
begin
 if assigned(item) then with pTrsResult(item)^ do begin
  inc(frame.rowcount);
  mask:= $0F;
  strlen:= datasize - sizeof(tTrsResult); if strlen > 0 then mask:= mask or $10;
  write(mask,sizeof(byte));
  writevalue([transaction, errcode, quantity, reserved]);
  if strlen > 0 then writevalue([pAnsiChar(@item[sizeof(tTrsResult)])]);
 end;
end;

// -------------------------------------------------------------------

procedure tStockListEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idStockList;
      tablename : pAnsiChar = tbl_StockList;
begin
 StartEncode(idTableDescr);
 write(tableid, sizeof(byte));
 write(tablename^,strlen(tablename)+1);
 for i:=low(StockListNames) to high(StockListNames) do write(StockListNames[i]^,strlen(StockListNames[i])+1);
 StopEncode(nil);
end;

procedure tStockListEncoder.encoderow;
const dm : byte = $7;
begin
 if assigned(item) then with pStockRow(item)^ do begin
  inc(frame.rowcount);
  write(dm,sizeof(byte));
  writevalue([stock_id,stock_name,stock_flags]);
 end;
end;

// -------------------------------------------------------------------

procedure tLevelListEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idLevelList;
      tablename : pAnsiChar = tbl_LevelList;
begin
 StartEncode(idTableDescr);
 write(tableid, sizeof(byte));
 write(tablename^,strlen(tablename)+1);
 for i:=low(LevelListNames) to high(LevelListNames) do write(LevelListNames[i]^,strlen(LevelListNames[i])+1);
 StopEncode(nil);
end;

procedure tLevelListEncoder.encoderow;
const dm : byte = $3f;
begin
 if assigned(item) then with pLevelAttrItem(item)^ do begin
  inc(frame.rowcount);
  write(dm,sizeof(byte));
  writevalue([stock_id, level, marketcode, leveltype, default, description]);
 end;
end;

// -------------------------------------------------------------------

procedure tAccountListEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idAccountList;
      tablename : pAnsiChar = tbl_AccountList;
begin
 StartEncode(idTableDescr);
 write(tableid, sizeof(byte));
 write(tablename^,strlen(tablename)+1);
 for i:=low(AccountListNames) to high(AccountListNames) do write(AccountListNames[i]^,strlen(AccountListNames[i])+1);
 StopEncode(nil);
end;

procedure tAccountListEncoder.encoderow;
const dm : byte = $7f;
begin
 if assigned(item) then with pAccountListItm(item)^ do begin
  inc(frame.rowcount);
  write(dm,sizeof(byte));
  writevalue([stock_id, account, flags, descr, margininfo.normal, margininfo.warning, margininfo.critical]);
 end;
end;

// -------------------------------------------------------------------

procedure tReportEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idReport;
      tablename : pAnsiChar = tbl_Report;
begin
  StartEncode(idTableDescr);
  write(tableid, sizeof(byte));
  write(tablename^, strlen(tablename) + 1);
  for i:= low(ReportNames) to high(ReportNames) do write(ReportNames[i]^, strlen(ReportNames[i]) + 1);
  StopEncode(nil);
end;

procedure tReportEncoder.encoderow;
var   i     : longint;
const hdrm  : longint = $1 or $2  or $4  or $8     or $10    or $20;
      initm : longint = $1 or $40 or $80 or $80000;
      dealm : longint = $1 or $40 or $80 or $100   or $200   or $400   or $800 or $1000 or $2000 or $4000 or $8000 or $40000 or $80000;
      movem : longint = $1 or $40 or $80 or $10000 or $20000 or $40000 or $80000;
begin
  if assigned(item) then with pReportHeader(item)^ do begin
    inc(frame.rowcount);
    write(hdrm,3);
    writevalue([0,formatdatetime(stddtformat,sdat),formatdatetime(stddtformat,fdat),fullname,address,prcnds]);
    for i:= 0 to rowcount - 1 do with pReportRow(item + sizeof(tReportHeader) + i * sizeof(tReportRow))^ do begin
      case trstype of
        'S' : begin
                write(initm,3); writevalue([1,shortname]);
                if stock_id = 0 then writevalue([price]) else writevalue([quantity]);
                writevalue([code]);
              end;
        'D' : begin
                write(dealm,3);
                writevalue([2, shortname, quantity, dealid, formatdatetime(stddtformat, dt), buysell, price, value,
                            nkd, brokerkommiss, stockkommiss, comment, code]);
              end;
        'M' : begin
                write(movem,3); writevalue([3,shortname]);
                if stock_id = 0 then writevalue([price]) else writevalue([quantity]);
                writevalue([formatdatetime(stddtformat,dt),buysell,comment, code]);
              end;
      end;
    end;
  end;
end;

// -------------------------------------------------------------------

procedure tArcTradesEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idTradesQuery;
      tablename : pAnsiChar = tbl_ArcTrades;
begin
 StartEncode(idTableDescr);
 write(tableid, sizeof(byte));
 write(tablename^,strlen(tablename)+1);
 for i:=low(ArcTradesNames) to high(ArcTradesNames) do write(ArcTradesNames[i]^,strlen(ArcTradesNames[i])+1);
 StopEncode(nil);
end;

procedure tArcTradesEncoder.encoderow;
var   i, idx : longint;
const hm     : byte = $7;
      dm     : byte = $f8;
begin
 if assigned(item) then with pArcTradeBuf(item)^ do begin
  inc(frame.rowcount);
  write(hm,sizeof(byte));
  writevalue([account,stock_id,code]);
  idx:=sizeof(tArcTradeBuf);
  for i:=0 to rowcount-1 do begin
   write(dm,sizeof(byte));
   with pArcTradeRow(@item[idx])^ do writevalue([tradeno,formatdatetime(stddtformat,tradetime),price,quantity,accr]);
   inc(idx,sizeof(tArcTradeRow));
  end;
 end;
end;

// -------------------------------------------------------------------

procedure tStopOrdersEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idStopOrder;
      tablename : pAnsiChar = tbl_StopOrders;
begin
 StartEncode(idTableDescr);
 write(tableid, sizeof(byte));
 write(tablename^,strlen(tablename)+1);
 for i:=low(StopOrdersNames) to high(StopOrdersNames) do write(StopOrdersNames[i]^,strlen(StopOrdersNames[i])+1);
 StopEncode(nil);
end;

procedure tStopOrdersEncoder.encoderow;
const dm  : word = $7fff;
begin
 if assigned(item) then with pStopOrders(item)^ do begin
  inc(frame.rowcount);
  write(dm,sizeof(word));
  writevalue([stoporder.order.stock_id,stoporder.order.level,stoporder.order.code,stoporder.order.buysell,
              stoporder.order.price,stoporder.order.quantity,stoporder.order.account,stoporder.order.flags,
              stopid,formatdatetime(stddtformat,stoptime),status,stoporder.stoptype,stoporder.stopprice,
              formatdatetime(stddtformat,stoporder.expiredatetime),comment]);
 end;
end;

// -------------------------------------------------------------------

procedure tNewsEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idNews;
      tablename : pAnsiChar = tbl_News;
begin
 StartEncode(idTableDescr);
 write(tableid, sizeof(byte));
 write(tablename^,strlen(tablename)+1);
 for i:=low(NewsNames) to high(NewsNames) do write(NewsNames[i]^,strlen(NewsNames[i])+1);
 StopEncode(nil);
end;

procedure tNewsEncoder.encoderow;
var   pos, spos : longint;
      mask      : byte;
begin
 if assigned(item) then with pNewsHeader(item)^ do begin
  inc(frame.rowcount);
  spos:= position; mask:= 1;
  write(mask,sizeof(byte));

  writevalue([id]);
  if nws_newsprovider in newsfields then begin mask:= mask or $2; writevalue([news_id]);                              end;
  if nws_newstime     in newsfields then begin mask:= mask or $4; writevalue([formatdatetime(stddtformat,newstime)]); end;
  if (subjlen > 0)    then begin mask:= mask or  $8; writevalue([pAnsiChar(@item[sizeof(tNewsHeader)])]);                 end;
  if (textlen > 0)    then begin mask:= mask or $10; writevalue([pAnsiChar(@item[sizeof(tNewsHeader) + subjlen])]);       end;

  pos:= position; seek(spos, soFromBeginning); write(mask, sizeof(byte)); seek(pos, soFromBeginning);
 end;
end;

// -------------------------------------------------------------------

procedure tPingEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idPing;
      tablename : pAnsiChar = tbl_ping;
begin
  StartEncode(idTableDescr);
  write(tableid, sizeof(byte));
  write(tablename^,strlen(tablename)+1);
  for i:= low(PingNames) to high(PingNames) do write(PingNames[i]^, strlen(PingNames[i]) + 1);
  StopEncode(nil);
end;

procedure tPingEncoder.encoderow(item: pAnsiChar; datasize: longint);
const dm : byte = 1;
begin
  if assigned(item) then begin
    inc(frame.rowcount);
    write(dm,sizeof(byte));
    writevalue([plongint(item)^]);
  end;
end;

// -------------------------------------------------------------------

procedure tConsoleLogEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idConsoleLog;
      tablename : pAnsiChar = tbl_consolelog;
begin
  StartEncode(idTableDescr);
  write(tableid, sizeof(byte));
  write(tablename^,strlen(tablename)+1);
  for i:= low(ConsoleLogNames) to high(ConsoleLogNames) do write(ConsoleLogNames[i]^, strlen(ConsoleLogNames[i]) + 1);
  StopEncode(nil);
end;

procedure tConsoleLogEncoder.encoderow(item: pAnsiChar; datasize: longint);
const dm : byte = 1;
begin
  if assigned(item) then begin
    inc(frame.rowcount);
    write(dm,sizeof(byte));
    writevalue([pAnsiChar(item + sizeof(longint))]);
  end;
end;

// -------------------------------------------------------------------

procedure tClientLimitEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idClientLimits;
      tablename : pAnsiChar = tbl_ClientLimits;
begin
 StartEncode(idTableDescr);
 write(tableid, sizeof(byte));
 write(tablename^,strlen(tablename)+1);
 for i:=low(ClientLimitNames) to high(ClientLimitNames) do write(ClientLimitNames[i]^,strlen(ClientLimitNames[i])+1);
 StopEncode(nil);
end;

procedure tClientLimitEncoder.encoderow;
var mask      : word;
    pos, spos : longint;
begin
 if assigned(item) then with pClientLimitItem(item)^ do begin
  inc(frame.rowcount);
  spos:= position; mask:= 0;
  write(mask, sizeof(word));
  with limit do begin
                                            mask:= mask or $0001; writevalue([account]);
                                            mask:= mask or $0002; writevalue([stock_id]);
                                            mask:= mask or $0004; writevalue([code]);
   if lim_oldlimit   in limitset then begin mask:= mask or $0008; writevalue([oldlimit]);   end;
   if lim_startlimit in limitset then begin mask:= mask or $0010; writevalue([startlimit]); end;
   if lim_free       in limitset then begin mask:= mask or $0020; writevalue([free]);       end;
   if lim_reserved   in limitset then begin mask:= mask or $0040; writevalue([reserved]);   end;
   if lim_res_pos    in limitset then begin mask:= mask or $0080; writevalue([res_pos]);    end;
   if lim_res_ord    in limitset then begin mask:= mask or $0100; writevalue([res_ord]);    end;
   if lim_negvarmarg in limitset then begin mask:= mask or $0200; writevalue([negvarmarg]); end;
   if lim_curvarmarg in limitset then begin mask:= mask or $0400; writevalue([curvarmarg]); end;
  end;
  pos:= position; seek(spos, soFromBeginning); write(mask, sizeof(word)); seek(pos, soFromBeginning);
 end;
end;

// -------------------------------------------------------------------

procedure tAccRestsEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idAccountRests;
      tablename : pAnsiChar = tbl_AccountRests;
begin
 StartEncode(idTableDescr);
 write(tableid, sizeof(byte));
 write(tablename^,strlen(tablename)+1);
 for i:=low(AccountRestsNames) to high(AccountRestsNames) do write(AccountRestsNames[i]^,strlen(AccountRestsNames[i])+1);
 StopEncode(nil);
end;

procedure tAccRestsEncoder.encoderow;
var   i, idx : longint;
const hm     : byte = $01;
      dm     : byte = $1e;
begin
 if assigned(item) then with pAccountRestsBuf(item)^ do begin
  inc(frame.rowcount);
  write(hm, sizeof(byte));
  writevalue([account]);
  idx:= sizeof(tAccountRestsBuf);
  for i:= 0 to rowcount - 1 do begin
   write(dm,sizeof(byte));
   with pAccountRestsRow(@item[idx])^ do writevalue([stock_id, code, fact, avgprice]);
   inc(idx,sizeof(tAccountRestsRow));
  end;
 end;
end;

// -------------------------------------------------------------------

procedure tLiquidListEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idLiquidList;
      tablename : pAnsiChar = tbl_LiquidList;
begin
  StartEncode(idTableDescr);
  write(tableid, sizeof(byte));
  write(tablename^,strlen(tablename)+1);
  for i:=low(LiquidListNames) to high(LiquidListNames) do write(LiquidListNames[i]^,strlen(LiquidListNames[i])+1);
  StopEncode(nil);
end;

procedure tLiquidListEncoder.encoderow;
const dm : byte = $07;
begin
  if assigned(item) then with pLiquidListItem(item)^ do begin
    inc(frame.rowcount);
    write(dm,sizeof(byte));
    writevalue([stock_id, level, code]);
  end;
end;

// -------------------------------------------------------------------

procedure tFirmInfoEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idFirmInfo;
      tablename : pAnsiChar = tbl_FirmList;
begin
 StartEncode(idTableDescr);
 write(tableid, sizeof(byte));
 write(tablename^,strlen(tablename)+1);
 for i:=low(FirmInfoNames) to high(FirmInfoNames) do write(FirmInfoNames[i]^,strlen(FirmInfoNames[i])+1);
 StopEncode(nil);
end;

procedure tFirmInfoEncoder.encoderow;
var   pos, spos : longint;
      mask      : byte;
begin
 if assigned(item) then with pFirmItem(item)^ do begin
  inc(frame.rowcount);
  spos:= position; mask:= 0;
  write(mask, sizeof(byte));

                                        mask:= $3;         writevalue([firm.stock_id, firm.firmid]);
  if fid_firmname in firmset then begin mask:= mask or $4; writevalue([firm.firmname]); end;
  if fid_status   in firmset then begin mask:= mask or $8; writevalue([firm.status]);   end;

  pos:= position; seek(spos, soFromBeginning); write(mask, sizeof(byte)); seek(pos, soFromBeginning);
 end;
end;

// -------------------------------------------------------------------

procedure tSettleCodesEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idSettleCodes;
      tablename : pAnsiChar = tbl_SettleCodes;
begin
 StartEncode(idTableDescr);
 write(tableid, sizeof(byte));
 write(tablename^,strlen(tablename)+1);
 for i:=low(SettleCodesNames) to high(SettleCodesNames) do write(SettleCodesNames[i]^,strlen(SettleCodesNames[i])+1);
 StopEncode(nil);
end;

procedure tSettleCodesEncoder.encoderow;
const dm : byte = $1f;
begin
  if assigned(item) then with pSettleCodes(item)^ do begin
    inc(frame.rowcount);
    write(dm,sizeof(byte));
    writevalue([stock_id, settlecode, description, formatdatetime(stddtformat,settledate1), formatdatetime(stddtformat,settledate2)]);
  end;
end;

// -------------------------------------------------------------------

procedure tIndLimitsEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idIndividualLimits;
      tablename : pAnsiChar = tbl_IndividualLimits;
begin
  StartEncode(idTableDescr);
  write(tableid, sizeof(byte));
  write(tablename^,strlen(tablename)+1);
  for i:=low(IndLimitsNames) to high(IndLimitsNames) do write(IndLimitsNames[i]^,strlen(IndLimitsNames[i])+1);
  StopEncode(nil);
end;

procedure tIndLimitsEncoder.encoderow;
var   i, idx : longint;
const hm     : byte = $01;
      dm     : byte = $0e;
begin
  if assigned(item) then with pIndLimitsBuf(item)^ do begin
    inc(frame.rowcount);
    write(hm, sizeof(byte));
    writevalue([account]);
    idx:= sizeof(tIndLimitsBuf);
    for i:= 0 to rowcount - 1 do begin
      write(dm,sizeof(byte));
      with pIndLimitsRow(@item[idx])^ do writevalue([stock_id, code, limit]);
      inc(idx,sizeof(tIndLimitsRow));
    end;
  end;
end;

// -------------------------------------------------------------------

procedure tConnInfoEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idQueryCon;
      tablename : pAnsiChar = tbl_ConnectionInfo;
begin
  StartEncode(idTableDescr);
  write(tableid, sizeof(byte));
  write(tablename^, strlen(tablename) + 1);
  for i:= low(ConnInfoNames) to high(ConnInfoNames) do write(ConnInfoNames[i]^, strlen(ConnInfoNames[i]) + 1);
  StopEncode(nil);
end;

procedure tConnInfoEncoder.encoderow;
const dm1 : byte = $7;
      dm2 : byte = $0f;
begin
  if assigned(item) then with pConnectionInfo(item)^ do begin
    inc(frame.rowcount);
    if length(realname) = 0 then begin write(dm1, sizeof(byte)); writevalue([id, username, flags]); end
                            else begin write(dm2, sizeof(byte)); writevalue([id, username, flags, realname]); end;
  end;
end;

// -------------------------------------------------------------------

procedure tSrvStatusEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idServerStatus;
      tablename : pAnsiChar = tbl_ServerStatus;
begin
  StartEncode(idTableDescr);
  write(tableid, sizeof(byte));
  write(tablename^, strlen(tablename)+1);
  for i:= low(SrvStatusNames) to high(SrvStatusNames) do write(SrvStatusNames[i]^, strlen(SrvStatusNames[i]) + 1);
  StopEncode(nil);
end;

procedure tSrvStatusEncoder.encoderow;
const dm : byte = $3;
begin
  if assigned(item) then with pServerStatus(item)^ do begin
    inc(frame.rowcount);
    write(dm, sizeof(byte));
    writevalue([opendaystatus, formatdatetime(stddtformat, timesync)]);
  end;
end;

// -------------------------------------------------------------------

procedure tUserMsgEncoder.generatedescriptor;
var   i         : longint;
const tableid   : byte  = idUserMessage;
      tablename : pAnsiChar = tbl_UserMessage;
begin
  StartEncode(idTableDescr);
  write(tableid, sizeof(byte));
  write(tablename^, strlen(tablename) + 1);
  for i:= low(UserMsgNames) to high(UserMsgNames) do write(UserMsgNames[i]^, strlen(UserMsgNames[i])+1);
  StopEncode(nil);
end;

procedure tUserMsgEncoder.encoderow;
const dm  : byte = $0f;
var   msg : pAnsiChar;
begin
  if assigned(item) then with pUserMessage(item)^ do begin
    inc(frame.rowcount);
    write(dm, sizeof(byte));
    if datasize > sizeof(tUserMessage) then msg:= @item[sizeof(tUserMessage)] else msg:= nil;
    writevalue([id, username, formatdatetime(stddtformat, dt), msg]);
  end;
end;

{ tUniversalEncoder }

procedure tUniversalEncoder.startencode(internalid: byte);
begin
  encoding:= true;

  frame.tableid:= internalid;
  frame.flags:= pfNoFlags;
  frame.rowcount:= 0;
  frameposition:= Position;
  write(frame, sizeof(frame));

  startposition:= Position;
end;

procedure tUniversalEncoder.stopencode(key: pKey);
var destlen, tmp : longint;
begin
  destlen:= max(0, position - startposition);
  if assigned(internal_buffer) and enablecompression and (destlen >= fmincompsize) then begin
    tmp:= StreamCompress(pAnsiChar(memory) + startposition, destlen, internal_buffer);
    if (tmp > 0) then begin
      destlen:= tmp;
      setsize(startposition + destlen);
      frame.flags:= frame.flags or pfPacked;
    end;
  end;
  if assigned(key) then begin
    destlen:= calculatelen(destlen);
    setsize(startposition + destlen);
    rc5encryptbuf(pAnsiChar(memory) + startposition, destlen, key);
    frame.flags:= frame.flags or pfEncrypted;
  end;
  frame.datasize:= destlen;
  updateprotocolcrc(frame);
  pProtocolRec(pAnsiChar(memory) + frameposition)^:= frame;
  seek(0, soFromEnd);
  encoding:= false;
end;

procedure tUniversalEncoder.encoderow(item: pansichar; datasize: longint);
begin if assigned(item) then begin inc(frame.rowcount); write(item^,datasize); end; end;

procedure tUniversalEncoder.generatedescriptor;
begin end;

// -------------------------------------------------------------------

constructor tEncoderRegistry.create(abuf: tMemoryStream);
begin
  inherited create;
  fDuplicates:= dupIgnore;
  fbuffer:= abuf;
end;

procedure tEncoderRegistry.freeitem(item: pointer); 
begin
  if assigned(item) then with pEncRegistryItm(item)^ do begin
    if assigned(encoder) then encoder.free;
    dispose(pEncRegistryItm(item));
  end;
end;

function tEncoderRegistry.checkitem(item: pointer): boolean; 
begin result:= true; end;

function tEncoderRegistry.compare(item1, item2: pointer): longint;
begin result:= pEncRegistryItm(item1)^.id - pEncRegistryItm(item2)^.id; end;

procedure tEncoderRegistry.add(id: longint; data: pAnsiChar; datasize: longint);
var itm  : tEncRegistryItm;
    idx  : longint;
    aitm : pEncRegistryItm;
    aenc : tEncoderStream;
begin
  if (assigned(data) and (datasize > 0)) or (not assigned(data) and (datasize = 0)) then begin
    itm.id:= id;
    if not search(@itm,idx) then begin
      try
        case id of
          idWaitSec          : aenc := tSecuritiesEncoder.create  (minimum_compression_size, fbuffer);
          idKotUpdates       : aenc := tKotirovkiEncoder.create   (minimum_compression_size, fbuffer);
          idAccount          : aenc := tAccountEncoder.create     (minimum_compression_size, fbuffer);
          idWaitOrders       : aenc := tOrdersEncoder.create      (minimum_compression_size, fbuffer);
          idWaitTrades       : aenc := tTradesEncoder.create      (minimum_compression_size, fbuffer);
          idWaitAllTrades    : aenc := tAllTradesEncoder.create   (minimum_compression_size, fbuffer);
          idMarginLevel      : aenc := tMarginLevelEncoder.create (minimum_compression_size, fbuffer);
          idMarginInfo       : aenc := tMarginInfoEncoder.create  (minimum_compression_size, fbuffer);
          idTrsResult        : aenc := tTrsResultEncoder.create   (minimum_compression_size, fbuffer);
          idReport           : aenc := tReportEncoder.create      (minimum_compression_size, fbuffer);
          idTradesQuery      : aenc := tArcTradesEncoder.create   (minimum_compression_size, fbuffer);
          idStopOrder        : aenc := tStopOrdersEncoder.create  (minimum_compression_size, fbuffer);
          idStockList        : aenc := tStockListEncoder.create   (minimum_compression_size, fbuffer);
          idAccountList      : aenc := tAccountListEncoder.create (minimum_compression_size, fbuffer);
          idQueryCon         : aenc := tConnInfoEncoder.create    (minimum_compression_size, fbuffer);
          idServerStatus     : aenc := tSrvStatusEncoder.create   (minimum_compression_size, fbuffer);
          idUserMessage      : aenc := tUserMsgEncoder.create     (minimum_compression_size, fbuffer);
          idNews             : aenc := tNewsEncoder.create        (minimum_compression_size, fbuffer);
          idLevelList        : aenc := tLevelListEncoder.create   (minimum_compression_size, fbuffer);
          idPing             : aenc := tPingEncoder.create        (minimum_compression_size, nil);
          idConsoleLog       : aenc := tConsoleLogEncoder.create  (minimum_compression_size, fbuffer);
          idClientLimits     : aenc := tClientLimitEncoder.create (minimum_compression_size, fbuffer);
          idAccountRests     : aenc := tAccRestsEncoder.create    (minimum_compression_size, fbuffer);
          idFirmInfo         : aenc := tFirmInfoEncoder.create    (minimum_compression_size, fbuffer);
          idSettleCodes      : aenc := tSettleCodesEncoder.create (minimum_compression_size, fbuffer);
          idIndividualLimits : aenc := tIndLimitsEncoder.create   (minimum_compression_size, fbuffer);
          else                 aenc := tUniversalEncoder.create   (minimum_compression_size, fbuffer);
        end;
        if assigned(aenc) then aenc.generatedescriptor;
      except aenc:= nil; end;

      if assigned(aenc) then begin
        aitm:= new(pEncRegistryItm);
        aitm^.id:= id; aitm^.encoder:= aenc;
        insert(idx, aitm);
      end;
    end else aenc:= pEncRegistryItm(items[idx])^.encoder;

    if assigned(aenc) then begin
      if not aenc.encoding then aenc.startencode(id);
      aenc.encoderow(data, datasize);
    end;
  end;
end;

procedure tEncoderRegistry.stopencode(key: pKey);
var i : longint;
begin
  for i:= 0 to count - 1 do
    with pEncRegistryItm(items[i])^ do
      if assigned(encoder) and encoder.encoding then encoder.stopencode(key);
end;

end.
