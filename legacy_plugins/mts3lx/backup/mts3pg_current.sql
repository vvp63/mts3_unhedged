/*
 Navicat Premium Data Transfer

 Source Server         : Aquila
 Source Server Type    : PostgreSQL
 Source Server Version : 100010
 Source Host           : localhost:5432
 Source Catalog        : MTS3pg
 Source Schema         : public

 Target Server Type    : PostgreSQL
 Target Server Version : 100010
 File Encoding         : 65001

 Date: 08/12/2020 11:41:27
*/


-- ----------------------------
-- Sequence structure for messages_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "public"."messages_id_seq";
CREATE SEQUENCE "public"."messages_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 2147483647
START 1
CACHE 1;

-- ----------------------------
-- Sequence structure for myorders_transactionid_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "public"."myorders_transactionid_seq";
CREATE SEQUENCE "public"."myorders_transactionid_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 2147483647
START 1
CACHE 1;

-- ----------------------------
-- Table structure for Finres_History
-- ----------------------------
DROP TABLE IF EXISTS "public"."Finres_History";
CREATE TABLE "public"."Finres_History" (
  "date" timestamp(6),
  "tpid" int4,
  "finres" float8,
  "value" float8
)
;

-- ----------------------------
-- Table structure for accounts
-- ----------------------------
DROP TABLE IF EXISTS "public"."accounts";
CREATE TABLE "public"."accounts" (
  "id" int4 NOT NULL,
  "account" varchar(20) COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for balance
-- ----------------------------
DROP TABLE IF EXISTS "public"."balance";
CREATE UNLOGGED TABLE "public"."balance" (
  "tpid" int4 NOT NULL,
  "securityid" int4 NOT NULL,
  "quantity" int4 NOT NULL,
  "lasttradeno" int8 NOT NULL,
  "value" float4
)
;

-- ----------------------------
-- Table structure for currentquotes
-- ----------------------------
DROP TABLE IF EXISTS "public"."currentquotes";
CREATE TABLE "public"."currentquotes" (
  "quoedate" timestamp(6),
  "code" varchar(20) COLLATE "pg_catalog"."default",
  "lastdealprice" float8,
  "fut_deposit" float8
)
;

-- ----------------------------
-- Table structure for messages
-- ----------------------------
DROP TABLE IF EXISTS "public"."messages";
CREATE TABLE "public"."messages" (
  "Id" int4 DEFAULT nextval('messages_id_seq'::regclass),
  "messtime" timestamp(6),
  "from" varchar(20) COLLATE "pg_catalog"."default",
  "to" varchar(20) COLLATE "pg_catalog"."default",
  "message" varchar(255) COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for myorders
-- ----------------------------
DROP TABLE IF EXISTS "public"."myorders";
CREATE UNLOGGED TABLE "public"."myorders" (
  "transactionid" int4 NOT NULL DEFAULT nextval('myorders_transactionid_seq'::regclass),
  "settime" timestamp(6) NOT NULL,
  "tpid" int4 NOT NULL,
  "securityid" int4 NOT NULL,
  "buysell" varchar(1) COLLATE "pg_catalog"."default" NOT NULL,
  "price" float4 NOT NULL,
  "quantity" int4 NOT NULL,
  "status" varchar(1) COLLATE "pg_catalog"."default" NOT NULL,
  "dropattempttime" timestamp(6),
  "answertimefloat" float8 NOT NULL,
  "settimefloat" float8 NOT NULL,
  "answertime" timestamp(6)
)
;

-- ----------------------------
-- Table structure for myorders_dropped
-- ----------------------------
DROP TABLE IF EXISTS "public"."myorders_dropped";
CREATE UNLOGGED TABLE "public"."myorders_dropped" (
  "transactionid" int4 NOT NULL,
  "settime" timestamp(6) NOT NULL,
  "tpid" int4 NOT NULL,
  "securityid" int4 NOT NULL,
  "buysell" varchar(1) COLLATE "pg_catalog"."default" NOT NULL,
  "price" float4 NOT NULL,
  "quantity" int4 NOT NULL,
  "status" varchar(1) COLLATE "pg_catalog"."default" NOT NULL,
  "dropattempttime" timestamp(6),
  "answertimefloat" float8 NOT NULL,
  "settimefloat" float8 NOT NULL,
  "answertime" timestamp(6)
)
;

-- ----------------------------
-- Table structure for offtrades
-- ----------------------------
DROP TABLE IF EXISTS "public"."offtrades";
CREATE UNLOGGED TABLE "public"."offtrades" (
  "code" varchar(50) COLLATE "pg_catalog"."default",
  "tpid" int4 NOT NULL,
  "tradeno1" int8 NOT NULL,
  "tradeno2" int8 NOT NULL,
  "offtime" timestamp(6),
  "qtyoff" int4,
  "offresult" float8
)
;

-- ----------------------------
-- Table structure for orders
-- ----------------------------
DROP TABLE IF EXISTS "public"."orders";
CREATE UNLOGGED TABLE "public"."orders" (
  "transaction" int4,
  "internalid" int4,
  "stockid" int4,
  "level" varchar(20) COLLATE "pg_catalog"."default",
  "code" varchar(20) COLLATE "pg_catalog"."default",
  "orderno" int8 NOT NULL,
  "ordertime" timestamp(6),
  "status" varchar(1) COLLATE "pg_catalog"."default",
  "buysell" varchar(1) COLLATE "pg_catalog"."default" NOT NULL,
  "account" varchar(20) COLLATE "pg_catalog"."default",
  "price" float4,
  "quantity" int4,
  "value" float4,
  "clientid" varchar(5) COLLATE "pg_catalog"."default",
  "balance" int4,
  "ordertype" varchar(1) COLLATE "pg_catalog"."default",
  "settlecode" varchar(3) COLLATE "pg_catalog"."default",
  "comment" varchar(30) COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for orders_dropped
-- ----------------------------
DROP TABLE IF EXISTS "public"."orders_dropped";
CREATE UNLOGGED TABLE "public"."orders_dropped" (
  "transaction" int4,
  "internalid" int4,
  "stockid" int4,
  "level" varchar(20) COLLATE "pg_catalog"."default",
  "code" varchar(20) COLLATE "pg_catalog"."default",
  "orderno" int8 NOT NULL,
  "ordertime" timestamp(6),
  "status" varchar(1) COLLATE "pg_catalog"."default",
  "buysell" varchar(1) COLLATE "pg_catalog"."default" NOT NULL,
  "account" varchar(20) COLLATE "pg_catalog"."default",
  "price" float4,
  "quantity" int4,
  "value" float4,
  "clientid" varchar(5) COLLATE "pg_catalog"."default",
  "balance" int4,
  "ordertype" varchar(1) COLLATE "pg_catalog"."default",
  "settlecode" varchar(3) COLLATE "pg_catalog"."default",
  "comment" varchar(30) COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for out_balanceontime
-- ----------------------------
DROP TABLE IF EXISTS "public"."out_balanceontime";
CREATE TABLE "public"."out_balanceontime" (
  "tpid" int4,
  "securityid" int4,
  "quantity" int4,
  "quote" float8
)
;

-- ----------------------------
-- Table structure for out_getactiveorders
-- ----------------------------
DROP TABLE IF EXISTS "public"."out_getactiveorders";
CREATE TABLE "public"."out_getactiveorders" (
  "Transactionid" int4,
  "Price" float4,
  "balance" int4,
  "orderno" int8,
  "SetTime" timestamp(6)
)
;

-- ----------------------------
-- Table structure for out_getseclist
-- ----------------------------
DROP TABLE IF EXISTS "public"."out_getseclist";
CREATE TABLE "public"."out_getseclist" (
  "SecurityId" int4,
  "code" varchar(50) COLLATE "pg_catalog"."default",
  "level" varchar(50) COLLATE "pg_catalog"."default",
  "stockid" int4,
  "SecType" varchar(1) COLLATE "pg_catalog"."default",
  "account" varchar(20) COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for out_getsecparams
-- ----------------------------
DROP TABLE IF EXISTS "public"."out_getsecparams";
CREATE TABLE "public"."out_getsecparams" (
  "lotsize" int4 NOT NULL,
  "pricestep" float8 NOT NULL,
  "pricedriver" float8 NOT NULL,
  "activetime" int4,
  "voloff" int4 NOT NULL,
  "vmin" int4 NOT NULL,
  "mhigh" float8 NOT NULL,
  "vmax" int4 NOT NULL,
  "mlow" float8 NOT NULL,
  "forcedactivity" bit(1) NOT NULL
)
;

-- ----------------------------
-- Table structure for out_gettpqtys
-- ----------------------------
DROP TABLE IF EXISTS "public"."out_gettpqtys";
CREATE TABLE "public"."out_gettpqtys" (
  "securityid" int4,
  "quantity" int4
)
;

-- ----------------------------
-- Table structure for out_gettpseclist
-- ----------------------------
DROP TABLE IF EXISTS "public"."out_gettpseclist";
CREATE TABLE "public"."out_gettpseclist" (
  "sec_id" int4 NOT NULL,
  "sec_type" varchar(1) COLLATE "pg_catalog"."default",
  "hedge_kf" float4,
  "pd_kf" float4,
  "pdtosecid" int4,
  "account" varchar(20) COLLATE "pg_catalog"."default",
  "p2p_kf" float8
)
;

-- ----------------------------
-- Table structure for out_messages
-- ----------------------------
DROP TABLE IF EXISTS "public"."out_messages";
CREATE TABLE "public"."out_messages" (
  "messtime" timestamp(6),
  "from" varchar(20) COLLATE "pg_catalog"."default",
  "message" varchar(255) COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for out_setorderrejected
-- ----------------------------
DROP TABLE IF EXISTS "public"."out_setorderrejected";
CREATE TABLE "public"."out_setorderrejected" (
  "tpid" int4,
  "securityid" int4
)
;

-- ----------------------------
-- Table structure for securities
-- ----------------------------
DROP TABLE IF EXISTS "public"."securities";
CREATE TABLE "public"."securities" (
  "securityid" int4 NOT NULL,
  "code" varchar(50) COLLATE "pg_catalog"."default" NOT NULL,
  "level" varchar(50) COLLATE "pg_catalog"."default",
  "stockid" int4,
  "accountid" int4 NOT NULL,
  "sectype" varchar(1) COLLATE "pg_catalog"."default" NOT NULL,
  "lotsize" int4 NOT NULL,
  "pricestep" float8 NOT NULL,
  "pricedriver" float8 NOT NULL,
  "activetime" int4,
  "voloff" int4 NOT NULL,
  "vmin" int4 NOT NULL,
  "mhigh" float8 NOT NULL,
  "vmax" int4 NOT NULL,
  "mlow" float8 NOT NULL,
  "pdps_def" float8 NOT NULL,
  "forcedactivity" bit(1) NOT NULL
)
;

-- ----------------------------
-- Table structure for tp
-- ----------------------------
DROP TABLE IF EXISTS "public"."tp";
CREATE TABLE "public"."tp" (
  "tpid" int4 NOT NULL,
  "name" varchar(50) COLLATE "pg_catalog"."default" NOT NULL,
  "isactive" bit(1) NOT NULL,
  "directstatus" bit(1) NOT NULL,
  "inversestatus" bit(1) NOT NULL,
  "bdirect" float8 NOT NULL,
  "binverse" float8 NOT NULL,
  "volmax" int4 NOT NULL,
  "voleliminated" int4 NOT NULL,
  "bvolchange" float8 NOT NULL,
  "bvolchangeinv" float8 NOT NULL,
  "bsquarekf" float8 NOT NULL,
  "bsquarekfinv" float8 NOT NULL,
  "vmin" int4 NOT NULL,
  "vmax" int4 NOT NULL,
  "plmax" int4 NOT NULL,
  "maxvolbefore" int4 NOT NULL,
  "pstomove" int4 NOT NULL,
  "voltomove" int4 NOT NULL,
  "hedgemode" varchar(1) COLLATE "pg_catalog"."default" NOT NULL,
  "cashshift" float8 NOT NULL,
  "rintpd" int4 NOT NULL,
  "rintportf" int4 NOT NULL
)
;

-- ----------------------------
-- Table structure for tp_basis_count
-- ----------------------------
DROP TABLE IF EXISTS "public"."tp_basis_count";
CREATE TABLE "public"."tp_basis_count" (
  "TPId" int4 NOT NULL,
  "IsActive" bit(1),
  "Ticker" varchar(50) COLLATE "pg_catalog"."default",
  "PDTicker" varchar(50) COLLATE "pg_catalog"."default",
  "Kf" float4,
  "ExpirationDate" timestamp(6),
  "RepoPerc" numeric(255,4),
  "DiscountPerc" numeric(255,4),
  "DivSumm" numeric(255,4),
  "Spread" numeric(255)
)
;

-- ----------------------------
-- Table structure for tp_sec
-- ----------------------------
DROP TABLE IF EXISTS "public"."tp_sec";
CREATE TABLE "public"."tp_sec" (
  "tp_id" int4 NOT NULL,
  "sec_id" int4 NOT NULL,
  "accountid" int4 NOT NULL,
  "sec_type" varchar(1) COLLATE "pg_catalog"."default" NOT NULL,
  "hedge_kf" float4 NOT NULL,
  "pd_kf" float4 NOT NULL,
  "pdtosecid" int4 NOT NULL,
  "p2p_kf" float8 NOT NULL
)
;

-- ----------------------------
-- Table structure for trades
-- ----------------------------
DROP TABLE IF EXISTS "public"."trades";
CREATE UNLOGGED TABLE "public"."trades" (
  "transaction" int4,
  "internalid" int4,
  "stockid" int4,
  "level" varchar(20) COLLATE "pg_catalog"."default",
  "code" varchar(20) COLLATE "pg_catalog"."default",
  "tradeno" int8 NOT NULL,
  "orderno" int8 NOT NULL,
  "tradetime" timestamp(6),
  "buysell" varchar(1) COLLATE "pg_catalog"."default" NOT NULL,
  "account" varchar(20) COLLATE "pg_catalog"."default",
  "price" float4,
  "quantity" int4,
  "value" float4,
  "accr" float4,
  "clientid" varchar(5) COLLATE "pg_catalog"."default",
  "tradetype" varchar(1) COLLATE "pg_catalog"."default",
  "settlecode" varchar(3) COLLATE "pg_catalog"."default",
  "comment" varchar(30) COLLATE "pg_catalog"."default",
  "_tpid" int4,
  "qtyoff" int4 DEFAULT 0
)
;

-- ----------------------------
-- Table structure for tradescheldue
-- ----------------------------
DROP TABLE IF EXISTS "public"."tradescheldue";
CREATE TABLE "public"."tradescheldue" (
  "id" int4 NOT NULL,
  "starttime" timestamp(6) NOT NULL,
  "stoptime" timestamp(6) NOT NULL,
  "secstopbefore" int4 NOT NULL
)
;

-- ----------------------------
-- Function structure for AddUpdateBalance
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."AddUpdateBalance"("atradeno" int8, "atransaction" int4, "acode" varchar, "aquantity" int4, "avalue" float4);
CREATE OR REPLACE FUNCTION "public"."AddUpdateBalance"("atradeno" int8, "atransaction" int4, "acode" varchar, "aquantity" int4, "avalue" float4)
  RETURNS "pg_catalog"."int4" AS $BODY$
	DECLARE	vTPId				int;
	DECLARE	vSecurityId	int;
	DECLARE vOldQty     int;
BEGIN

	vTPId = (select TPId FROM MyOrders WHERE TransactionId	=	atransaction);
	vTPId = COALESCE(vTPId, 0);
	UPDATE Trades SET _TPId = vTPId WHERE tradeno = atradeno;
	vSecurityId	= (select SecurityId	FROM Securities WHERE code = acode);
	vOldQty = (SELECT Quantity FROM public.Balance WHERE TPId = vTPId AND SecurityId = vSecurityId);
	vOldQty = COALESCE(vOldQty, 0);
	
	--	Balances Update or Insert
	UPDATE public.Balance SET Quantity = Quantity + aquantity, LastTradeNo = atradeno
	WHERE TPId = vTPId AND SecurityId = vSecurityId;

	IF NOT FOUND THEN
		INSERT INTO public.Balance
           (TPId, SecurityId, Quantity, LastTradeNo, "value")
		VALUES
			(vTPId, vSecurityId, aquantity, atradeno, 0);
	END IF;
	--	Balances Update or Insert END	
	
	
	-- Values Update or Insert
	
	IF (vOldQty = 0) THEN
		UPDATE public.Balance SET "value" = (CASE WHEN (aquantity > 0) THEN avalue ELSE -avalue END) WHERE TPId = vTPId AND SecurityId = vSecurityId;
	END IF;	

	IF (vOldQty > 0) THEN
		IF (aquantity >= 0) THEN 
			UPDATE public.Balance SET "value" = COALESCE("value", 0) + avalue WHERE TPId = vTPId AND SecurityId = vSecurityId;	
		ELSE
			IF ((vOldQty + aquantity) >= 0) THEN
			  UPDATE public.Balance SET "value" = COALESCE("value", 0) * (vOldQty + aquantity) / vOldQty WHERE TPId = vTPId AND SecurityId = vSecurityId;
			ELSE
				UPDATE public.Balance SET "value" = -avalue * (vOldQty + aquantity) / aquantity WHERE TPId = vTPId AND SecurityId = vSecurityId;
			END IF;	
		END IF;
	END IF;
	
	IF (vOldQty < 0) THEN
		IF (aquantity <= 0) THEN 
			UPDATE public.Balance SET "value" = COALESCE("value", 0) - avalue WHERE TPId = vTPId AND SecurityId = vSecurityId;	
		ELSE
			IF ((vOldQty + aquantity) <= 0) THEN
			  UPDATE public.Balance SET "value" = COALESCE("value", 0) * (vOldQty + aquantity) / vOldQty WHERE TPId = vTPId AND SecurityId = vSecurityId;
			ELSE
				UPDATE public.Balance SET "value" = avalue * (vOldQty + aquantity) / aquantity WHERE TPId = vTPId AND SecurityId = vSecurityId;
			END IF;	
		END IF;
	END IF;	
	
	
	-- Values Update or Insert END	
	
	
			 
	RETURN 1;
	

	
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for Arch_All
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."Arch_All"();
CREATE OR REPLACE FUNCTION "public"."Arch_All"()
  RETURNS "pg_catalog"."void" AS $BODY$
	DECLARE "vdt"	TIMESTAMP;
	BEGIN
    
		"vdt" = NOW();
		PERFORM "FR_FormDaily"(CURRENT_DATE);
		PERFORM "Arch_balance"(vdt);
		PERFORM "Arch_myorders"(vdt);
		PERFORM "Arch_orders"(vdt);
		PERFORM "Arch_trades"(vdt);


	RETURN;
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for Arch_balance
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."Arch_balance"("vts" timestamp);
CREATE OR REPLACE FUNCTION "public"."Arch_balance"("vts" timestamp=now())
  RETURNS "pg_catalog"."void" AS $BODY$BEGIN

		INSERT INTO "Arch".balance(
			tpid
			,securityid
			,quantity
			,lasttradeno
			,"quote"
			,arch_time
		)
		(
			SELECT
					b.tpid
					,b.securityid
					,b.quantity
					,b.lasttradeno
					,q.lastdealprice
					,vts
			FROM "public".balance AS b LEFT JOIN "public".securities AS s ON (b.securityid = s.securityid)
			LEFT JOIN "public".currentquotes AS q ON (s.code = q.code)
		);

	RETURN;
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for Arch_myorders
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."Arch_myorders"("vts" timestamp);
CREATE OR REPLACE FUNCTION "public"."Arch_myorders"("vts" timestamp=now())
  RETURNS "pg_catalog"."void" AS $BODY$BEGIN
	
		INSERT INTO "Arch".myorders (
			transactionid
			,settime
			,tpid
			,securityid
			,buysell
			,price
			,quantity
			,status
			,dropattempttime
			,answertimefloat
			,settimefloat
			,answertime
			,archtime
		)
		(
			SELECT
					transactionid
					,settime
					,tpid
					,securityid
					,buysell
					,price
					,quantity
					,status
					,dropattempttime
					,answertimefloat
					,settimefloat
					,answertime
					,vts
				FROM "public".myorders
		);
		
		INSERT INTO "Arch".myorders (
			transactionid
			,settime
			,tpid
			,securityid
			,buysell
			,price
			,quantity
			,status
			,dropattempttime
			,answertimefloat
			,settimefloat
			,answertime
			,archtime
		)
		(
			SELECT
					transactionid
					,settime
					,tpid
					,securityid
					,buysell
					,price
					,quantity
					,status
					,dropattempttime
					,answertimefloat
					,settimefloat
					,answertime
					,vts
				FROM "public".myorders_dropped
		);		
		
		DELETE FROM "public".myorders;
		

	RETURN;
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for Arch_offtrades
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."Arch_offtrades"("vts" timestamp);
CREATE OR REPLACE FUNCTION "public"."Arch_offtrades"("vts" timestamp=now())
  RETURNS "pg_catalog"."void" AS $BODY$BEGIN

		INSERT INTO "Arch".offtrades (
			code
			,tpid
			,tradeno1
			,tradeno2
			,offtime
			,qtyoff
			,offresult
			,arch_time)
		(SELECT		code
							,tpid
							,tradeno1
							,tradeno2
							,offtime
							,qtyoff
							,offresult
							,vts
		FROM "public".offtrades
		);		
		
		DELETE FROM "public".offtrades;

	RETURN;
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for Arch_orders
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."Arch_orders"("vts" timestamp);
CREATE OR REPLACE FUNCTION "public"."Arch_orders"("vts" timestamp=now())
  RETURNS "pg_catalog"."void" AS $BODY$BEGIN
	
	
		INSERT INTO "Arch".orders
           ("transaction"
           ,internalid
           ,stockid
           ,"level"
           ,code
           ,orderno
           ,ordertime
           ,status
           ,buysell
           ,account
           ,price
           ,quantity
           ,"value"
           ,clientid
           ,balance
           ,ordertype
           ,settlecode
           ,"comment"
					 ,arch_time)
	 (SELECT "transaction"
           ,internalid
           ,stockid
           ,"level"
           ,code
           ,orderno
           ,ordertime
           ,status
           ,buysell
           ,account
           ,price
           ,quantity
           ,"value"
           ,clientid
           ,balance
           ,ordertype
           ,settlecode
           ,"comment"
					 ,vts
				FROM "public".orders
	 );
	 
	 DELETE FROM "public".orders;


	 INSERT INTO "Arch".orders
           ("transaction"
           ,internalid
           ,stockid
           ,"level"
           ,code
           ,orderno
           ,ordertime
           ,status
           ,buysell
           ,account
           ,price
           ,quantity
           ,"value"
           ,clientid
           ,balance
           ,ordertype
           ,settlecode
           ,"comment"
					 ,arch_time)
	 (SELECT "transaction"
           ,internalid
           ,stockid
           ,"level"
           ,code
           ,orderno
           ,ordertime
           ,status
           ,buysell
           ,account
           ,price
           ,quantity
           ,"value"
           ,clientid
           ,balance
           ,ordertype
           ,settlecode
           ,"comment"
					 ,vts
				FROM "public".orders_dropped
	 );
	 
	 DELETE FROM "public".orders_dropped;


	RETURN;
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for Arch_trades
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."Arch_trades"("vts" timestamp);
CREATE OR REPLACE FUNCTION "public"."Arch_trades"("vts" timestamp=now())
  RETURNS "pg_catalog"."void" AS $BODY$
	BEGIN
	
		INSERT INTO "Arch".trades
					("transaction"
           ,internalid
           ,stockid
           ,"level"
           ,code
					 ,tradeno
           ,orderno
           ,tradetime
           ,buysell
           ,account
           ,price
           ,quantity
           ,"value"
           ,accr
           ,clientid
           ,tradetype
           ,settlecode
           ,"comment"
					 ,"_tpid"
					 ,arch_time)
		(SELECT "transaction"
           ,internalid
           ,stockid
           ,"level"
           ,code
					 ,tradeno
           ,orderno
           ,tradetime
           ,buysell
           ,account
           ,price
           ,quantity
           ,"value"
           ,accr
           ,clientid
           ,tradetype
           ,settlecode
           ,"comment" 
					 ,"_tpid"
					 ,vts
		FROM "public".trades);
		
		DELETE FROM "public".trades;

	RETURN;
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for FR_BalanceToNow
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."FR_BalanceToNow"();
CREATE OR REPLACE FUNCTION "public"."FR_BalanceToNow"()
  RETURNS TABLE("tpid" int4, "securityid" int4, "quantity" int4, "quote" float8, "code" varchar, "lotsize" int4, "Val" float8) AS $BODY$ 
			SELECT b.tpid, b.securityid, b.quantity, q.lastdealprice AS "quote", s.code, s.lotsize, b.quantity * q.lastdealprice * s.lotsize AS "Val"
											FROM "public".balance AS b LEFT JOIN "public".securities AS s ON (b.securityid = s.securityid)
											LEFT JOIN "public".currentquotes AS q ON (s.code = q.code)		
   $BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- Function structure for FR_BalanceToTime
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."FR_BalanceToTime"("adatetime" timestamp);
CREATE OR REPLACE FUNCTION "public"."FR_BalanceToTime"("adatetime" timestamp)
  RETURNS TABLE("tpid" int4, "securityid" int4, "quantity" int4, "quote" float8, "code" varchar, "lotsize" int4, "Val" float8) AS $BODY$ 
		SELECT b.tpid,b.securityid, b.quantity, b."quote", s.code, s.lotsize, b.quantity * b."quote" * s.lotsize AS "Val" 
			FROM "Arch".balance AS b LEFT JOIN "public".securities AS s ON (b.securityid = s.securityid)
									WHERE (b.arch_time = (SELECT "FR_GetBalanceTime"(adatetime)));				
   $BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- Function structure for FR_FormDaily
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."FR_FormDaily"("vdt" timestamp);
CREATE OR REPLACE FUNCTION "public"."FR_FormDaily"("vdt" timestamp=now())
  RETURNS "pg_catalog"."void" AS $BODY$
DECLARE vtp RECORD;
DECLARE vfr float;
DECLARE vval float;
DECLARE vdtend timestamp;

	BEGIN
		
		vdtend = vdt + interval '1 day';
    FOR vtp IN
       SELECT tpid, "name" FROM "public".tp WHERE isactive = B'1'
    LOOP
			--SELECT SUM(fullprofit) INTO STRICT vfr FROM "FR_RevalAndTradesToDate"(vtp.tpid, vdt, vdtend);
			SELECT SUM(fullprofit) INTO STRICT vfr FROM "FR_RevalAndTradesToNow"(vtp.tpid, vdt);
			SELECT SUM("Val") INTO STRICT vval FROM "FR_BalanceToTime"(vdtend) WHERE tpid = vtp.tpid AND securityid < 1000 ;
		
			RAISE NOTICE 'TP % (%) fr=%  val=%', vtp.tpid, vtp.name, vfr, vval;
			INSERT INTO "public"."Finres_History"("date", "tpid", finres, "value")
					VALUES(vdt, vtp.tpid, COALESCE(vfr, 0), COALESCE(vval, 0));
    END LOOP;


	RETURN;
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for FR_GetBalanceTime
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."FR_GetBalanceTime"("v_balancetime" timestamp);
CREATE OR REPLACE FUNCTION "public"."FR_GetBalanceTime"("v_balancetime" timestamp)
  RETURNS "pg_catalog"."timestamp" AS $BODY$
	DECLARE r TIMESTAMP;
	DECLARE tc int;
	BEGIN
		SELECT COUNT(*) into strict tc FROM  "Arch".balance WHERE arch_time < v_balancetime;
		IF (tc = 0) THEN
			r = '19700101';
		ELSE
			SELECT t1.arch_time into strict r FROM
				(
				SELECT t.arch_time, ROW_NUMBER() OVER (ORDER BY arch_time DESC) AS n FROM
					(
					select distinct arch_time FROM "Arch".balance WHERE arch_time < v_balancetime
					) AS t
				) AS t1
			WHERE t1.n = 1;
		END IF;
		
	RETURN r;
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for FR_RevalAndTradesToDate
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."FR_RevalAndTradesToDate"("atpid" int4, "adt1" timestamp, "adt2" timestamp);
CREATE OR REPLACE FUNCTION "public"."FR_RevalAndTradesToDate"("atpid" int4, "adt1" timestamp, "adt2" timestamp)
  RETURNS TABLE("sec_id" int4, "code" varchar, "lotsize" int4, "qty1" int4, "quote1" float8, "qty2" int4, "quote2" float8, "reval" numeric, "qtybuy" int8, "valbuy" numeric, "qtysell" int8, "valsell" numeric, "tradeprofit" numeric, "fullprofit" numeric) AS $BODY$ 
	SELECT tr.*, COALESCE(tb."qty", 0), COALESCE(tb."val", 0), COALESCE(ts."qty", 0), COALESCE(ts."val", 0), (COALESCE(ts."val", 0) - COALESCE(tb."val", 0)) AS "tradeprofit", COALESCE(tr."reval", 0) + (COALESCE(ts."val", 0) - COALESCE(tb."val", 0)) AS "fullprofit" FROM
		(SELECT * FROM "public"."FR_RevalToDate"(atpid, adt1, adt2)) AS tr
		LEFT JOIN
		(
			SELECT "code", COALESCE(SUM(quantity), 0) AS Qty, COALESCE(SUM("value"), 0)::numeric AS Val FROM "Trades_All"
				WHERE buysell = 'B' AND "_tpid" = atpid AND "tradetime" > adt1 AND "tradetime" < adt2 GROUP BY "code"		
		) AS tb ON (tr.code = tb.code)
		LEFT JOIN
		(
			SELECT "code", COALESCE(SUM(quantity), 0) AS Qty, COALESCE(SUM("value"), 0)::numeric AS Val FROM "Trades_All"
				WHERE buysell = 'S' AND "_tpid" = atpid AND "tradetime" > adt1 AND "tradetime" < adt2 GROUP BY "code"		
		) AS ts ON (tr.code = ts.code)	
	ORDER BY tr.sec_id	
							
   $BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- Function structure for FR_RevalAndTradesToNow
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."FR_RevalAndTradesToNow"("atpid" int4, "adt1" timestamp);
CREATE OR REPLACE FUNCTION "public"."FR_RevalAndTradesToNow"("atpid" int4, "adt1" timestamp)
  RETURNS TABLE("sec_id" int4, "code" varchar, "lotsize" int4, "qty1" int4, "quote1" float8, "qty2" int4, "quote2" float8, "reval" numeric, "qtybuy" int8, "valbuy" numeric, "qtysell" int8, "valsell" numeric, "tradeprofit" numeric, "fullprofit" numeric) AS $BODY$ 
	SELECT tr.*, COALESCE(tb."qty", 0), COALESCE(tb."val", 0), COALESCE(ts."qty", 0), COALESCE(ts."val", 0), (COALESCE(ts."val", 0) - COALESCE(tb."val", 0)) AS "tradeprofit", COALESCE(tr."reval", 0) + (COALESCE(ts."val", 0) - COALESCE(tb."val", 0)) AS "fullprofit" FROM
		(SELECT * FROM "public"."FR_RevalToNow"(atpid, adt1)) AS tr
		LEFT JOIN
		(
			SELECT "code", COALESCE(SUM(quantity), 0) AS Qty, COALESCE(SUM("value"), 0)::numeric AS Val FROM "Trades_All"--"public".trades
				WHERE buysell = 'B' AND "_tpid" = atpid AND "tradetime" > adt1 GROUP BY "code"		
		) AS tb ON (tr.code = tb.code)
		LEFT JOIN
		(
			SELECT "code", COALESCE(SUM(quantity), 0) AS Qty, COALESCE(SUM("value"), 0)::numeric AS Val FROM "Trades_All"--"public".trades
				WHERE buysell = 'S' AND "_tpid" = atpid AND "tradetime" > adt1 GROUP BY "code"		
		) AS ts ON (tr.code = ts.code)	
	ORDER BY tr.sec_id	
							
   $BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- Function structure for FR_RevalToDate
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."FR_RevalToDate"("atpid" int4, "adt1" timestamp, "adt2" timestamp);
CREATE OR REPLACE FUNCTION "public"."FR_RevalToDate"("atpid" int4, "adt1" timestamp, "adt2" timestamp)
  RETURNS TABLE("sec_id" int4, "code" varchar, "lotsize" int4, "qty1" int4, "quote1" float8, "qty2" int4, "quote2" float8, "reval" numeric) AS $BODY$ 
SELECT t.*, (t.lotsize * (t.quantity2 * t.quote2 - t.quantity1 * t.quote1))::numeric(16,0) AS Reval FROM
			 (
				 SELECT 
						tp.sec_id,
						s.code,
						s.lotsize,
						COALESCE(b1.quantity, 0) AS quantity1,
						COALESCE(b1.quote, 0) AS quote1,
						COALESCE(b2.quantity, 0) AS quantity2,
						COALESCE(b2.quote, 0) AS quote2
					 FROM (((tp_sec tp
						 LEFT JOIN securities s ON ((tp.sec_id = s.securityid)))
						 LEFT JOIN (SELECT * FROM "public"."FR_BalanceToTime"(adt1)) b1 ON ((tp.tp_id = b1.tpid) AND (tp.sec_id = b1.securityid)))
						 LEFT JOIN (SELECT * FROM "public"."FR_BalanceToTime"(adt2)) b2 ON ((tp.tp_id = b2.tpid) AND (tp.sec_id = b2.securityid)))
					WHERE (tp.tp_id = atpid)
				) AS t
		ORDER BY t.sec_id
							
   $BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- Function structure for FR_RevalToNow
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."FR_RevalToNow"("atpid" int4, "adt1" timestamp);
CREATE OR REPLACE FUNCTION "public"."FR_RevalToNow"("atpid" int4, "adt1" timestamp)
  RETURNS TABLE("sec_id" int4, "code" varchar, "lotsize" int4, "qty1" int4, "quote1" float8, "qty2" int4, "quote2" float8, "reval" numeric) AS $BODY$ 
SELECT t.*, (t.lotsize * (t.quantity2 * t.quote2 - t.quantity1 * t.quote1))::numeric(16,0) AS Reval FROM
			 (
				 SELECT 
						tp.sec_id,
						s.code,
						s.lotsize,
						COALESCE(b1.quantity, 0) AS quantity1,
						COALESCE(b1.quote, 0) AS quote1,
						COALESCE(b2.quantity, 0) AS quantity2,
						COALESCE(b2.quote, 0) AS quote2
					 FROM (((tp_sec tp
						 LEFT JOIN securities s ON ((tp.sec_id = s.securityid)))
						 LEFT JOIN (SELECT * FROM "public"."FR_BalanceToTime"(adt1)) b1 ON ((tp.tp_id = b1.tpid) AND (tp.sec_id = b1.securityid)))
						 LEFT JOIN (SELECT * FROM "public"."FR_BalanceToNow"()) b2 ON ((tp.tp_id = b2.tpid) AND (tp.sec_id = b2.securityid)))
					WHERE (tp.tp_id = atpid)
				) AS t
		ORDER BY t.sec_id
							
   $BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- Function structure for FR_SumRevalDateToDate
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."FR_SumRevalDateToDate"("atpid" int4, "adt1" timestamp, "adt2" timestamp);
CREATE OR REPLACE FUNCTION "public"."FR_SumRevalDateToDate"("atpid" int4, "adt1" timestamp, "adt2" timestamp)
  RETURNS "pg_catalog"."float8" AS $BODY$ 
		DECLARE r float;
	BEGIN
	
		SELECT SUM(t1.Reval) INTO STRICT r FROM
		(
			SELECT t.*, t.lotsize * (t.quantity2 * t.quote2 - t.quantity1 * t.quote1) AS Reval FROM
			 (
				 SELECT tp.tp_id,
						tp.sec_id,
						s.code,
						s.lotsize,
						COALESCE(b1.quantity, 0) AS quantity1,
						COALESCE(b1.quote, 0) AS quote1,
						COALESCE(b2.quantity, 0) AS quantity2,
						COALESCE(b2.quote, 0) AS quote2
					 FROM (((tp_sec tp
						 LEFT JOIN securities s ON ((tp.sec_id = s.securityid)))
						 LEFT JOIN (SELECT * FROM "public"."FR_BalanceToTime"(adt1)) b1 ON ((tp.tp_id = b1.tpid) AND (tp.sec_id = b1.securityid)))
						 LEFT JOIN (SELECT * FROM "public"."FR_BalanceToTime"(adt2)) b2 ON ((tp.tp_id = b2.tpid) AND (tp.sec_id = b2.securityid)))
					WHERE (tp.tp_id = atpid)
				) AS t
			) AS t1;

		RETURN r;
	
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for FR_SumRevalDateToNow
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."FR_SumRevalDateToNow"("atpid" int4, "adt1" timestamp);
CREATE OR REPLACE FUNCTION "public"."FR_SumRevalDateToNow"("atpid" int4, "adt1" timestamp)
  RETURNS "pg_catalog"."float8" AS $BODY$ 
		DECLARE r float;
	BEGIN
	
		SELECT SUM(t1.Reval) INTO STRICT r FROM
		(
			SELECT t.*, t.lotsize * (t.quantity2 * t.quote2 - t.quantity1 * t.quote1) AS Reval FROM
			 (
				 SELECT tp.tp_id,
						tp.sec_id,
						s.code,
						s.lotsize,
						COALESCE(b1.quantity, 0) AS quantity1,
						COALESCE(b1.quote, 0) AS quote1,
						COALESCE(b2.quantity, 0) AS quantity2,
						COALESCE(b2.quote, 0) AS quote2
					 FROM (((tp_sec tp
						 LEFT JOIN securities s ON ((tp.sec_id = s.securityid)))
						 LEFT JOIN (SELECT * FROM "public"."FR_BalanceToTime"(adt1)) b1 ON ((tp.tp_id = b1.tpid) AND (tp.sec_id = b1.securityid)))
						 LEFT JOIN (SELECT * FROM "public"."FR_BalanceToNow"()) b2 ON ((tp.tp_id = b2.tpid) AND (tp.sec_id = b2.securityid)))
					WHERE (tp.tp_id = atpid)
				) AS t
			) AS t1;

		RETURN r;
	
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for SeparateDroppedOrders
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."SeparateDroppedOrders"();
CREATE OR REPLACE FUNCTION "public"."SeparateDroppedOrders"()
  RETURNS "pg_catalog"."void" AS $BODY$ BEGIN

		DROP TABLE IF EXISTS _To_Separate;

		CREATE TEMP TABLE _To_Separate AS	
			(SELECT orderno, "transaction" FROM "public".orders WHERE status IN ('W', 'M') AND ordertime < (NOW() - make_time(0, 10, 0)));
	
	-- Dropping orders
	
		INSERT INTO "public".orders_dropped
		 (SELECT * FROM "public".orders WHERE orderno IN (SELECT orderno FROM _To_Separate));
		 
	  DELETE FROM "public".orders WHERE orderno IN (SELECT orderno FROM _To_Separate);
		
	-- Dropping myorders
		
		INSERT INTO "public".myorders_dropped
		 (SELECT * FROM "public".myorders WHERE status = 'C' AND transactionid IN (SELECT "transaction" FROM _To_Separate));		
		 
		DELETE FROM "public".myorders WHERE status = 'C' AND transactionid IN (SELECT "transaction" FROM _To_Separate);	
		
	
	RETURN;
	
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for _User_DeleteSendedOrders
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."_User_DeleteSendedOrders"();
CREATE OR REPLACE FUNCTION "public"."_User_DeleteSendedOrders"()
  RETURNS "pg_catalog"."void" AS $BODY$ 	
		DELETE FROM public.myorders WHERE status = 'S'
 $BODY$
  LANGUAGE sql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for _User_DellOT
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."_User_DellOT"();
CREATE OR REPLACE FUNCTION "public"."_User_DellOT"()
  RETURNS "pg_catalog"."void" AS $BODY$ 	
DELETE FROM public.myorders;
DELETE FROM public.balance;
DELETE FROM public.trades;
DELETE FROM public.orders;
DELETE FROM public.offtrades;
 $BODY$
  LANGUAGE sql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for _User_cyclefill
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."_User_cyclefill"("v_from" int4, "v_to" int4, "v_bysell" varchar, "v_qty" int4);
CREATE OR REPLACE FUNCTION "public"."_User_cyclefill"("v_from" int4, "v_to" int4, "v_bysell" varchar, "v_qty" int4)
  RETURNS "pg_catalog"."int4" AS $BODY$
	DECLARE i int;
BEGIN

	FOR i IN v_from..v_to LOOP
		raise notice 'Value: %', i;
		PERFORM public.addupdatetrade(i, 895, 4, 'FUTU', 'MIX-9.20', i, 26139179828273, '20200826 11:30:11', v_bysell, 'SOLID30101', 285250, v_qty, 285250 * v_qty, 0, 'TEST', ' ', '', '');		
		
	--	i = i + 1;
		
	END LOOP;
		 
  	RETURN 1;
	
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for addmessage
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."addmessage"("vfrom" varchar, "vto" varchar, "vmessage" varchar);
CREATE OR REPLACE FUNCTION "public"."addmessage"("vfrom" varchar, "vto" varchar, "vmessage" varchar)
  RETURNS "pg_catalog"."int4" AS $BODY$
BEGIN
	INSERT INTO public.messages
           ("messtime", "from", "to", "message")
    VALUES
			(now(), vfrom, vto, vmessage);
					
	RETURN MAX("Id") FROM public.messages;
			 
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for addmyorder
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."addmyorder"("tpid" int4, "securityid" int4, "buysell" varchar, "price" float4, "quantity" int4);
CREATE OR REPLACE FUNCTION "public"."addmyorder"("tpid" int4, "securityid" int4, "buysell" varchar, "price" float4, "quantity" int4)
  RETURNS "pg_catalog"."int4" AS $BODY$
	DECLARE r int;
BEGIN
	INSERT INTO public.MyOrders
           (SetTime, TPId, SecurityId, BuySell, Price, Quantity, Status, SetTimeFloat, AnswerTimeFloat)
    VALUES
			(now(), TPId, SecurityId, BuySell, Price, Quantity, 'S', 0, -1);
					
	RETURN MAX(transactionid) FROM public.myorders;
			 
  	--RETURN r;
	
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for addupdatecurrentquote
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."addupdatecurrentquote"("acode" varchar, "alastdealprice" float8, "afut_deposit" float8);
CREATE OR REPLACE FUNCTION "public"."addupdatecurrentquote"("acode" varchar, "alastdealprice" float8, "afut_deposit" float8=0)
  RETURNS "pg_catalog"."int4" AS $BODY$

BEGIN

	UPDATE public.currentquotes SET quoedate = now(), lastdealprice = alastdealprice, fut_deposit = afut_deposit WHERE code = acode;
	
	IF NOT FOUND THEN
		INSERT INTO public.currentquotes (quoedate,code,lastdealprice,fut_deposit)
							VALUES      (now(), acode, alastdealprice, afut_deposit)	;	
	END IF;
			 
	RETURN 1;		
	
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for addupdateorder
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."addupdateorder"("v_transaction" int4, "v_internalid" int4, "v_stockid" int4, "v_level" varchar, "v_code" varchar, "v_orderno" int8, "v_ordertime" timestamp, "v_status" varchar, "v_buysell" varchar, "v_account" varchar, "v_price" float4, "v_quantity" int4, "v_value" float4, "v_clientid" varchar, "v_balance" int4, "v_ordertype" varchar, "v_settlecode" varchar, "v_comment" varchar);
CREATE OR REPLACE FUNCTION "public"."addupdateorder"("v_transaction" int4, "v_internalid" int4, "v_stockid" int4, "v_level" varchar, "v_code" varchar, "v_orderno" int8, "v_ordertime" timestamp, "v_status" varchar, "v_buysell" varchar, "v_account" varchar, "v_price" float4, "v_quantity" int4, "v_value" float4, "v_clientid" varchar, "v_balance" int4, "v_ordertype" varchar, "v_settlecode" varchar, "v_comment" varchar)
  RETURNS "pg_catalog"."int4" AS $BODY$

begin
	
	perform public.setanswertime(v_transaction);


	UPDATE public.Orders
	   SET transaction = transaction
		  ,internalid = v_internalid
		  ,stockid = v_stockid
		  ,level = v_level
		  ,code = v_code
		  ,ordertime = v_ordertime
		  ,status = v_status
		  ,buysell = v_buysell
		  ,account = v_account
		  ,price = v_price
		  ,quantity = v_quantity
		  ,value = v_value
		  ,clientid = v_clientid
		  ,balance = v_balance
		  ,ordertype = v_ordertype
		  ,settlecode = v_settlecode
		  ,comment = v_comment
	WHERE orderno = v_orderno;
		
	IF NOT FOUND THEN
	
		INSERT INTO public.Orders
           (transaction
           ,internalid
           ,stockid
           ,level
           ,code
           ,orderno
           ,ordertime
           ,status
           ,buysell
           ,account
           ,price
           ,quantity
           ,value
           ,clientid
           ,balance
           ,ordertype
           ,settlecode
           ,comment)
		VALUES
           (v_transaction,
           v_internalid,
           v_stockid,
           v_level,
           v_code,
           v_orderno,
           v_ordertime, 
           v_status,
           v_buysell,
           v_account,
           v_price,
           v_quantity,
           v_value,
           v_clientid, 
           v_balance,
           v_ordertype,
           v_settlecode,
           v_comment);
 
	END IF;

	
  	RETURN public.refreshtrsstatus(v_transaction);
	
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for addupdatetrade
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."addupdatetrade"("v_transaction" int4, "v_internalid" int4, "v_stockid" int4, "v_level" varchar, "v_code" varchar, "v_tradeno" int8, "v_orderno" int8, "v_tradetime" timestamp, "v_buysell" varchar, "v_account" varchar, "v_price" float4, "v_quantity" int4, "v_value" float4, "v_accr" float4, "v_clientid" varchar, "v_tradetype" varchar, "v_settlecode" varchar, "v_comment" varchar);
CREATE OR REPLACE FUNCTION "public"."addupdatetrade"("v_transaction" int4, "v_internalid" int4, "v_stockid" int4, "v_level" varchar, "v_code" varchar, "v_tradeno" int8, "v_orderno" int8, "v_tradetime" timestamp, "v_buysell" varchar, "v_account" varchar, "v_price" float4, "v_quantity" int4, "v_value" float4, "v_accr" float4, "v_clientid" varchar, "v_tradetype" varchar, "v_settlecode" varchar, "v_comment" varchar)
  RETURNS "pg_catalog"."int4" AS $BODY$
	DECLARE	QtyChange	int;
	DECLARE r	int;
	declare t 	int;
	declare tmp int;
	declare vordtrs	int;
	declare vmyords int;
begin
	
	r = 0;
	perform public.setanswertime(v_transaction);

	UPDATE public.Trades
	   SET transaction = v_transaction
		  ,internalid = v_internalid
		  ,stockid = v_stockid
		  ,level = v_level
		  ,code = v_code
		  ,orderno = v_orderno
		  ,tradetime = v_tradetime
		  ,buysell = v_buysell
		  ,account = v_account
		  ,price = v_price
		  ,quantity = v_quantity
		  ,value = (CASE WHEN (v_stockid = 4 AND v_code LIKE '%Si-%') THEN v_price * v_quantity * 1000 ELSE v_value END)
		  ,accr = v_accr
		  ,clientid = v_clientid
		  ,tradetype = v_tradetype
		  ,settlecode = v_settlecode
		  ,comment = v_comment
	WHERE tradeno = v_tradeno;


	IF NOT FOUND THEN	
		INSERT INTO public.Trades
           (transaction
           ,internalid
           ,stockid
           ,level
           ,code
		   ,tradeno
           ,orderno
           ,tradetime
           ,buysell
           ,account
           ,price
           ,quantity
           ,value
           ,accr
           ,clientid
           ,tradetype
           ,settlecode
           ,comment)
		VALUES
           (v_transaction,
           v_internalid,
           v_stockid,
           v_level,
           v_code,
           v_tradeno,
           v_orderno,
           v_tradetime, 
           v_buysell,
           v_account,
           v_price,
           v_quantity,
           CASE WHEN (v_stockid = 4 AND v_code LIKE '%Si-%') THEN v_price * v_quantity * 1000 ELSE v_value END,
         --  CASE stockid WHEN 7 THEN value * 100 ELSE value END,
           v_accr,
           v_clientid, 
           v_tradetype,
           v_settlecode,
           v_comment);
		  
		QtyChange = CASE WHEN (v_buysell = 'B') THEN v_quantity ELSE -v_quantity END;

		PERFORM "public"."AddUpdateBalance"(v_tradeno, v_transaction, v_code, QtyChange, v_value);
	--	PERFORM OffTradeQty(v_tradeno);
		   
	END IF;

	select count(*) into strict vordtrs FROM Orders WHERE "transaction" = v_transaction; 

	if (vordtrs > 0) THEN
		SELECT RefreshTrsStatus(v_transaction) into strict tmp;
	end if;
	
	select count(*) into strict vmyords FROM public.MyOrders WHERE TransactionId = v_transaction; 
	if (vmyords > 0) THEN
		SELECT COALESCE(TPId, 0) into strict r FROM public.MyOrders WHERE TransactionId = v_transaction;
	END IF;
			 
  RETURN r;
	
	
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for delmessages
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."delmessages"("ato" varchar);
CREATE OR REPLACE FUNCTION "public"."delmessages"("ato" varchar)
  RETURNS "pg_catalog"."void" AS $BODY$
    DELETE FROM public.messages WHERE "to" = ato
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for getactiveorders
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."getactiveorders"("atpid" int4, "asecurityid" int4, "abuysell" varchar);
CREATE OR REPLACE FUNCTION "public"."getactiveorders"("atpid" int4, "asecurityid" int4, "abuysell" varchar)
  RETURNS SETOF "public"."out_getactiveorders" AS $BODY$
	SELECT mo.Transactionid, mo.Price, COALESCE(o.balance, mo.Quantity), COALESCE(o.orderno, 0), COALESCE(mo.DropAttemptTime, mo.SetTime)
	FROM MyOrders AS mo LEFT JOIN Orders AS o ON (mo.Transactionid = o.transaction) 
	WHERE mo.Status in ('S', 'O') and mo.TPId = aTPId AND mo.SecurityId = aSecurityId AND mo.BuySell = aBuySell
	ORDER BY Transactionid
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- Function structure for getmessages
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."getmessages"("ato" varchar);
CREATE OR REPLACE FUNCTION "public"."getmessages"("ato" varchar)
  RETURNS SETOF "public"."out_messages" AS $BODY$
    SELECT "messtime", "from", "message" FROM public.messages WHERE "to" = ato
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- Function structure for getseclist
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."getseclist"();
CREATE OR REPLACE FUNCTION "public"."getseclist"()
  RETURNS SETOF "public"."out_getseclist" AS $BODY$
	SELECT s.SecurityId, s.code, s.level, s.stockid, s.SecType, a.account
		FROM Securities AS s INNER JOIN Accounts AS a ON (s.AccountId = a.Id)
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- Function structure for getsecparams
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."getsecparams"("asecurityid" int4);
CREATE OR REPLACE FUNCTION "public"."getsecparams"("asecurityid" int4)
  RETURNS SETOF "public"."out_getsecparams" AS $BODY$
	SELECT LotSize, PriceStep, PriceDriver, ActiveTime, VolOff, Vmin, Mhigh, Vmax, Mlow, ForcedActivity
		FROM public.Securities WHERE SecurityId = aSecurityId
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- Function structure for gettplist
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."gettplist"();
CREATE OR REPLACE FUNCTION "public"."gettplist"()
  RETURNS SETOF "public"."tp" AS $BODY$
    SELECT * FROM public.TP WHERE tp.isactive = B'1'
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- Function structure for gettpparams
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."gettpparams"("atpid" int4);
CREATE OR REPLACE FUNCTION "public"."gettpparams"("atpid" int4)
  RETURNS SETOF "public"."tp" AS $BODY$
    SELECT * FROM public.TP WHERE TPId = aTPId
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- Function structure for gettpqtys
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."gettpqtys"("atpid" int4);
CREATE OR REPLACE FUNCTION "public"."gettpqtys"("atpid" int4)
  RETURNS SETOF "public"."out_gettpqtys" AS $BODY$
    SELECT SecurityId, Quantity FROM public.Balance WHERE TPId = atpid
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- Function structure for gettpseclist
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."gettpseclist"("atpid" int4);
CREATE OR REPLACE FUNCTION "public"."gettpseclist"("atpid" int4)
  RETURNS SETOF "public"."out_gettpseclist" AS $BODY$
	SELECT tps.Sec_Id, tps.Sec_Type, tps.Hedge_Kf, tps.PD_Kf, tps.PDToSecId, a.account, tps.P2P_Kf
	FROM TP_Sec AS tps INNER JOIN Accounts AS a ON (tps.AccountId = a.Id)
	WHERE TP_Id = aTPId
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- Function structure for gettradescheldue
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."gettradescheldue"();
CREATE OR REPLACE FUNCTION "public"."gettradescheldue"()
  RETURNS SETOF "public"."tradescheldue" AS $BODY$
    	SELECT Id, StartTime, StopTime, SecStopBefore
		FROM public.TradeScheldue
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- Function structure for offtradeqty
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."offtradeqty"("atradeno" int8);
CREATE OR REPLACE FUNCTION "public"."offtradeqty"("atradeno" int8)
  RETURNS "pg_catalog"."int4" AS $BODY$
	DECLARE vtn1 bigint;
	DECLARE vtn2 bigint;
	DECLARE vdiff	int;
	DECLARE fulloff	int;
	

BEGIN

	fulloff	=	1;
	
	WHILE (fulloff > 0)  LOOP
	
		DROP TABLE IF EXISTS _Off_Trades;

		CREATE TEMP TABLE _Off_Trades AS
		SELECT tmp.* FROM
		(
			SELECT t.code, t._TPId, t.tn1, t.tn2, t.tt1, 
					(t.v1 / t.q1 * CASE t.bs1 WHEN 'S' THEN 1 ELSE -1 END) AS vq1, (t.q1-t.qoff1) AS r1,
					(t.v2 / t.q2 * CASE t.bs2 WHEN 'S' THEN 1 ELSE -1 END) AS vq2, (t.q2-t.qoff2) AS r2,
					CASE WHEN (t.q1-t.qoff1) > (t.q2-t.qoff2) THEN (t.q2-t.qoff2) ELSE (t.q1-t.qoff1) END AS diff
					 FROM
			(
				SELECT 
					  t1.code
					  ,t1._TPId
					  ,t1.tradeno AS tn1
					  ,t1.tradetime AS tt1
					  ,t1.buysell AS bs1
					  ,t1.quantity AS q1
					  ,t1.price AS p1
					  ,t1.value AS v1
					  ,t1.QtyOff AS qoff1
					  ,t2.tradeno AS tn2
					  ,t2.tradetime AS tt2
					  ,t2.buysell AS bs2
					  ,t2.quantity AS q2
					  ,t2.price AS p2
					  ,t2.value AS v2
					  ,t2.QtyOff AS qoff2
					  , ROW_NUMBER() OVER (PARTITION BY t1.tradeno ORDER BY t2.tradeno) AS rn	
				FROM Trades AS t1 INNER JOIN Trades AS t2
						 ON (t1.code = t2.code AND t1._TPId = t2._TPId AND t1.tradeno > t2.tradeno AND t1.buysell <> t2.buysell)
				WHERE (t1.tradeno = atradeno) AND (t1.quantity <> t1.QtyOff) AND (t2.quantity <> t2.QtyOff)
			) AS t WHERE t.rn = 1
		) AS tmp;

		
		INSERT INTO OffTrades (code, TPId, tradeno1, tradeno2, OffTime, qtyoff, OffResult)
			 (SELECT code, _TPId, tn1, tn2, tt1, diff, diff * (vq1 + vq2) FROM _Off_Trades);
		vtn1 = (select tn1  FROM _Off_Trades);	 
		vtn2 = (select tn2  FROM _Off_Trades);
		vdiff = (select diff FROM _Off_Trades);
		fulloff = (SELECT COUNT(*) FROM _Off_Trades);	
		UPDATE Trades SET QtyOff = QtyOff + vdiff WHERE (tradeno = vtn1) OR (tradeno = vtn2);
	
	END LOOP;
	
		 
  	RETURN 1;
	
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for refreshtrsstatus
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."refreshtrsstatus"("trsid" int4);
CREATE OR REPLACE FUNCTION "public"."refreshtrsstatus"("trsid" int4)
  RETURNS "pg_catalog"."int4" AS $BODY$
	DECLARE		v_gettrsid		int;
	DECLARE		v_count			int;
	DECLARE		v_status		varchar(1);
	DECLARE		v_qtyleft		int;
	DECLARE		v_trdcnt 		int;
	DECLARE		v_intrds 		int;
BEGIN

	v_gettrsid = 0;

	SELECT COUNT(*) FROM Orders into strict v_count
	WHERE "transaction" = trsid;
	
	if (v_count > 0) then 
		v_gettrsid = trsid; 
		
		select status into strict v_status FROM Orders WHERE "transaction" = trsid;
		select quantity - balance into strict v_qtyleft FROM Orders WHERE "transaction" = trsid;	
		
		v_intrds = 0;
		SELECT COUNT(*) FROM Trades into strict v_trdcnt	WHERE "transaction" = trsid;	
		if (v_trdcnt > 0) then
			SELECT SUM(quantity) FROM Trades into strict v_intrds	WHERE "transaction" = trsid;
		end if;
		
		UPDATE MyOrders as mo SET
			Status = CASE WHEN (v_qtyleft > v_intrds) OR (v_status = 'O') THEN 'O' ELSE 'C' END,
			AnswerTimeFloat = 0
		WHERE TransactionId = v_gettrsid;			
	
	end if;


	
	RETURN v_gettrsid;

	
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for setanswertime
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."setanswertime"("trsid" int4);
CREATE OR REPLACE FUNCTION "public"."setanswertime"("trsid" int4)
  RETURNS "pg_catalog"."int4" AS $BODY$

BEGIN
																													   
		UPDATE MyOrders as mo set answertime = now() where answertime is null and transactionid = trsid;																									   
			 
  	RETURN trsid;
	
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for setdroptime
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."setdroptime"("atrsid" int4, "adroptime" timestamp);
CREATE OR REPLACE FUNCTION "public"."setdroptime"("atrsid" int4, "adroptime" timestamp)
  RETURNS "pg_catalog"."int4" AS $BODY$
    UPDATE public.MyOrders SET DropAttemptTime = now()--adroptime 
		WHERE TransactionId = atrsid RETURNING 1
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for setorderrejected
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."setorderrejected"("atransactionid" int4);
CREATE OR REPLACE FUNCTION "public"."setorderrejected"("atransactionid" int4)
  RETURNS SETOF "public"."out_setorderrejected" AS $BODY$

--	IF (SELECT COUNT(*) FROM Orders WHERE [transaction] = @TransactionId) = 0
	UPDATE MyOrders SET status = 'R' WHERE TransactionId = aTransactionId;

	SELECT TPId, SecurityId FROM MyOrders WHERE TransactionId = aTransactionId;
	
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- View structure for Last_Delays
-- ----------------------------
DROP VIEW IF EXISTS "public"."Last_Delays";
CREATE VIEW "public"."Last_Delays" AS  SELECT "OrdersDelay".transactionid,
    "OrdersDelay".delay,
    "OrdersDelay".stockid,
    "OrdersDelay".rn
   FROM "OrdersDelay"
  WHERE (("OrdersDelay".rn < 11) AND ("OrdersDelay".stockid IS NOT NULL));

-- ----------------------------
-- View structure for Delays_ByStock
-- ----------------------------
DROP VIEW IF EXISTS "public"."Delays_ByStock";
CREATE VIEW "public"."Delays_ByStock" AS  SELECT "Last_Delays".stockid,
    max("Last_Delays".delay) AS max,
    min("Last_Delays".delay) AS avg
   FROM "Last_Delays"
  GROUP BY "Last_Delays".stockid;

-- ----------------------------
-- View structure for OrdersDelay
-- ----------------------------
DROP VIEW IF EXISTS "public"."OrdersDelay";
CREATE VIEW "public"."OrdersDelay" AS  SELECT myorders.transactionid,
    date_part('milliseconds'::text, (myorders.answertime - myorders.settime)) AS delay,
    orders.stockid,
    row_number() OVER (PARTITION BY orders.stockid ORDER BY myorders.transactionid DESC) AS rn
   FROM (myorders
     LEFT JOIN orders ON ((myorders.transactionid = orders.transaction)))
  ORDER BY myorders.transactionid DESC;

-- ----------------------------
-- View structure for Trades_All
-- ----------------------------
DROP VIEW IF EXISTS "public"."Trades_All";
CREATE VIEW "public"."Trades_All" AS  SELECT trades.transaction,
    trades.internalid,
    trades.stockid,
    trades.level,
    trades.code,
    trades.tradeno,
    trades.orderno,
    trades.tradetime,
    trades.buysell,
    trades.account,
    trades.price,
    trades.quantity,
    trades.value,
    trades.accr,
    trades.clientid,
    trades.tradetype,
    trades.settlecode,
    trades.comment,
    trades._tpid,
    trades.qtyoff
   FROM trades
UNION
 SELECT trades.transaction,
    trades.internalid,
    trades.stockid,
    trades.level,
    trades.code,
    trades.tradeno,
    trades.orderno,
    trades.tradetime,
    trades.buysell,
    trades.account,
    trades.price,
    trades.quantity,
    trades.value,
    trades.accr,
    trades.clientid,
    trades.tradetype,
    trades.settlecode,
    trades.comment,
    trades._tpid,
    trades.qtyoff
   FROM "Arch".trades;

-- ----------------------------
-- View structure for _tmp_finres
-- ----------------------------
DROP VIEW IF EXISTS "public"."_tmp_finres";
CREATE VIEW "public"."_tmp_finres" AS  SELECT tp.tp_id,
    tp.sec_id,
    s.code,
    s.lotsize,
    COALESCE(b1.quantity, 0) AS quantity1,
    COALESCE(b1.quote, (0)::double precision) AS quote1,
    COALESCE(b2.quantity, 0) AS quantity2,
    COALESCE(b2.quote, (0)::double precision) AS quote2
   FROM (((tp_sec tp
     LEFT JOIN securities s ON ((tp.sec_id = s.securityid)))
     LEFT JOIN ( SELECT balance.tpid,
            balance.securityid,
            balance.quantity,
            balance.lasttradeno,
            balance.quote,
            balance.arch_time
           FROM "Arch".balance
          WHERE (balance.arch_time = ( SELECT "FR_GetBalanceTime"('2020-09-09 00:00:00'::timestamp without time zone) AS "FR_getBalanceTime"))) b1 ON (((tp.tp_id = b1.tpid) AND (tp.sec_id = b1.securityid))))
     LEFT JOIN ( SELECT balance.tpid,
            balance.securityid,
            balance.quantity,
            balance.lasttradeno,
            balance.quote,
            balance.arch_time
           FROM "Arch".balance
          WHERE (balance.arch_time = ( SELECT "FR_GetBalanceTime"('2020-09-10 00:00:00'::timestamp without time zone) AS "FR_getBalanceTime"))) b2 ON (((tp.tp_id = b2.tpid) AND (tp.sec_id = b2.securityid))))
  WHERE (tp.tp_id = 20275);

-- ----------------------------
-- View structure for Full_Balances_2_1
-- ----------------------------
DROP VIEW IF EXISTS "public"."Full_Balances_2_1";
CREATE VIEW "public"."Full_Balances_2_1" AS  SELECT tps.tp_id,
    t.name,
    tps.sec_id,
    s.code,
    COALESCE(b.quantity, 0) AS qty,
    (((bb.qtybase)::double precision * tps.hedge_kf))::integer AS qtyneed,
    COALESCE(b.value, (0)::real) AS "Value",
    tps.sec_type,
    tps.hedge_kf,
    0 AS qtybytrades,
    0 AS qtyoff,
    0 AS offresult,
    s.pdps_def
   FROM ((((tp_sec tps
     LEFT JOIN tp t ON ((t.tpid = tps.tp_id)))
     LEFT JOIN securities s ON ((tps.sec_id = s.securityid)))
     LEFT JOIN balance b ON (((tps.tp_id = b.tpid) AND (tps.sec_id = b.securityid))))
     LEFT JOIN ( SELECT tps1.tp_id,
            COALESCE(b1.quantity, 0) AS qtybase
           FROM (tp_sec tps1
             LEFT JOIN balance b1 ON (((b1.tpid = tps1.tp_id) AND (b1.securityid = tps1.sec_id))))
          WHERE ((tps1.sec_type)::text = 'B'::text)) bb ON ((tps.tp_id = bb.tp_id)));

-- ----------------------------
-- View structure for Full_Balances_2
-- ----------------------------
DROP VIEW IF EXISTS "public"."Full_Balances_2";
CREATE VIEW "public"."Full_Balances_2" AS  SELECT tps.tp_id,
    t.name,
    tps.sec_id,
    s.code,
    COALESCE(b.quantity, 0) AS qty,
    ((((bb.qtybase)::double precision * tps.hedge_kf))::integer *
        CASE
            WHEN ((tps.sec_type)::text = 'B'::text) THEN 1
            ELSE '-1'::integer
        END) AS qtyneed,
    COALESCE(b.value, (0)::real) AS "Value",
    tps.sec_type,
    tps.hedge_kf,
    0 AS qtybytrades,
    0 AS qtyoff,
    0 AS offresult,
    s.pdps_def
   FROM ((((tp_sec tps
     LEFT JOIN tp t ON ((t.tpid = tps.tp_id)))
     LEFT JOIN securities s ON ((tps.sec_id = s.securityid)))
     LEFT JOIN balance b ON (((tps.tp_id = b.tpid) AND (tps.sec_id = b.securityid))))
     LEFT JOIN ( SELECT tps1.tp_id,
            COALESCE(b1.quantity, 0) AS qtybase
           FROM (tp_sec tps1
             LEFT JOIN balance b1 ON (((b1.tpid = tps1.tp_id) AND (b1.securityid = tps1.sec_id))))
          WHERE ((tps1.sec_type)::text = 'B'::text)) bb ON ((tps.tp_id = bb.tp_id)));

-- ----------------------------
-- View structure for TPList
-- ----------------------------
DROP VIEW IF EXISTS "public"."TPList";
CREATE VIEW "public"."TPList" AS  SELECT tp.tpid,
    ((('('::text || ((tp.tpid)::character varying)::text) || ') '::text) || (tp.name)::text) AS fullname
   FROM tp
  WHERE (tp.isactive = B'1'::"bit")
  ORDER BY tp.tpid;

-- ----------------------------
-- View structure for TP_Balances_3
-- ----------------------------
DROP VIEW IF EXISTS "public"."TP_Balances_3";
CREATE VIEW "public"."TP_Balances_3" AS  SELECT t.tpid,
    t.name,
    fbb.qty,
    (
        CASE fbb.qty
            WHEN 0 THEN (0)::double precision
            ELSE (fbs.value / (fbb.qty)::double precision)
        END)::numeric(16,2) AS basismean
   FROM ((tp t
     LEFT JOIN ( SELECT "Full_Balances_2_1".tp_id,
            "Full_Balances_2_1".qty
           FROM "Full_Balances_2_1"
          WHERE (("Full_Balances_2_1".sec_type)::text = 'B'::text)) fbb ON ((t.tpid = fbb.tp_id)))
     LEFT JOIN ( SELECT "Full_Balances_2_1".tp_id,
            sum((("Full_Balances_2_1"."Value" * "Full_Balances_2_1".pdps_def) * (
                CASE "Full_Balances_2_1".sec_type
                    WHEN 'P'::text THEN 0
                    ELSE 1
                END)::double precision)) AS value
           FROM "Full_Balances_2_1"
          GROUP BY "Full_Balances_2_1".tp_id) fbs ON ((t.tpid = fbs.tp_id)))
  WHERE (t.isactive = B'1'::"bit");

-- ----------------------------
-- View structure for TP_Balances_2
-- ----------------------------
DROP VIEW IF EXISTS "public"."TP_Balances_2";
CREATE VIEW "public"."TP_Balances_2" AS  SELECT t.tpid,
    t.name,
    (- fbb.qty) AS qty,
    (fbp.basismean)::numeric(16,2) AS basismean
   FROM ((tp t
     LEFT JOIN ( SELECT "Full_Balances_2_1".tp_id,
            "Full_Balances_2_1".qty
           FROM "Full_Balances_2_1"
          WHERE (("Full_Balances_2_1".sec_type)::text = 'B'::text)) fbb ON ((t.tpid = fbb.tp_id)))
     LEFT JOIN ( SELECT t_1.tp_id,
            sum((((t_1.price * t_1.pdps_def) * t_1.hedge_kf) * (t_1.mult)::double precision)) AS basismean
           FROM ( SELECT "Full_Balances_2_1".tp_id,
                    "Full_Balances_2_1".sec_id,
                    "Full_Balances_2_1".qty,
                    "Full_Balances_2_1"."Value",
                        CASE
                            WHEN ("Full_Balances_2_1".qty <> 0) THEN ("Full_Balances_2_1"."Value" / ("Full_Balances_2_1".qty)::double precision)
                            ELSE (0)::double precision
                        END AS price,
                    "Full_Balances_2_1".hedge_kf,
                    "Full_Balances_2_1".pdps_def,
                        CASE
                            WHEN (("Full_Balances_2_1".sec_type)::text = 'B'::text) THEN '-1'::integer
                            WHEN (("Full_Balances_2_1".sec_type)::text = 'H'::text) THEN 1
                            ELSE 0
                        END AS mult
                   FROM "Full_Balances_2_1") t_1
          GROUP BY t_1.tp_id) fbp ON ((t.tpid = fbp.tp_id)))
  WHERE (t.isactive = B'1'::"bit");

-- ----------------------------
-- View structure for TP_Basis_Count_tmp
-- ----------------------------
DROP VIEW IF EXISTS "public"."TP_Basis_Count_tmp";
CREATE VIEW "public"."TP_Basis_Count_tmp" AS  SELECT t.tpid,
    t.name,
    tc."IsActive",
    tc."Ticker",
    q.lastdealprice AS "Quote",
    tc."PDTicker",
    qp.lastdealprice AS pdquote,
    tc."Kf",
    ((COALESCE(q.lastdealprice, (0)::double precision) * COALESCE(qp.lastdealprice, (1)::double precision)) * tc."Kf") AS marketvalue,
    tc."ExpirationDate",
    (date(tc."ExpirationDate") - date(now())) AS daysleft,
    tc."RepoPerc",
    tc."DiscountPerc",
    tc."DivSumm",
    tc."Spread"
   FROM (((tp_basis_count tc
     LEFT JOIN tp t ON ((tc."TPId" = t.tpid)))
     LEFT JOIN currentquotes q ON (((tc."Ticker")::text = (q.code)::text)))
     LEFT JOIN currentquotes qp ON (((tc."PDTicker")::text = (qp.code)::text)));

-- ----------------------------
-- View structure for TP_Basis_Count_Full
-- ----------------------------
DROP VIEW IF EXISTS "public"."TP_Basis_Count_Full";
CREATE VIEW "public"."TP_Basis_Count_Full" AS  SELECT "TP_Basis_Count_tmp".tpid,
    (((((("TP_Basis_Count_tmp".name)::text || '('::text) || ("TP_Basis_Count_tmp"."Ticker")::text) || ', '::text) || ("TP_Basis_Count_tmp"."PDTicker")::text) || ')'::text) AS tpname,
    "TP_Basis_Count_tmp"."Quote",
    "TP_Basis_Count_tmp".pdquote,
    "TP_Basis_Count_tmp"."Kf",
    "TP_Basis_Count_tmp".marketvalue,
    "TP_Basis_Count_tmp"."ExpirationDate",
    "TP_Basis_Count_tmp".daysleft,
    ("TP_Basis_Count_tmp"."RepoPerc")::numeric(12,2) AS "RepoPerc",
    ("TP_Basis_Count_tmp"."DiscountPerc")::numeric(12,2) AS "DiscountPerc",
    ("TP_Basis_Count_tmp"."DivSumm")::numeric(12,2) AS "DivSumm",
    (((("TP_Basis_Count_tmp".marketvalue * (((1)::numeric - ("TP_Basis_Count_tmp"."DiscountPerc" / (100)::numeric)))::double precision) * ("TP_Basis_Count_tmp"."RepoPerc")::double precision) / (100)::double precision))::numeric(12,2) AS profit,
    ((("TP_Basis_Count_tmp"."DivSumm")::double precision - ((((("TP_Basis_Count_tmp".marketvalue * (((1)::numeric - ("TP_Basis_Count_tmp"."DiscountPerc" / (100)::numeric)))::double precision) * ("TP_Basis_Count_tmp"."RepoPerc")::double precision) / (100)::double precision) * ("TP_Basis_Count_tmp".daysleft)::double precision) / (365)::double precision)))::numeric(12,2) AS basiscentral,
    "TP_Basis_Count_tmp"."Spread",
    (((("TP_Basis_Count_tmp"."DivSumm")::double precision - ((((("TP_Basis_Count_tmp".marketvalue * (((1)::numeric - ("TP_Basis_Count_tmp"."DiscountPerc" / (100)::numeric)))::double precision) * ("TP_Basis_Count_tmp"."RepoPerc")::double precision) / (100)::double precision) * ("TP_Basis_Count_tmp".daysleft)::double precision) / (365)::double precision)) - (("TP_Basis_Count_tmp"."Spread" / (2)::numeric))::double precision))::numeric(12,0) AS bdirect,
    (((("TP_Basis_Count_tmp"."DivSumm")::double precision - ((((("TP_Basis_Count_tmp".marketvalue * (((1)::numeric - ("TP_Basis_Count_tmp"."DiscountPerc" / (100)::numeric)))::double precision) * ("TP_Basis_Count_tmp"."RepoPerc")::double precision) / (100)::double precision) * ("TP_Basis_Count_tmp".daysleft)::double precision) / (365)::double precision)) + (("TP_Basis_Count_tmp"."Spread" / (2)::numeric))::double precision))::numeric(12,0) AS binverse
   FROM "TP_Basis_Count_tmp"
  WHERE ("TP_Basis_Count_tmp"."IsActive" = B'1'::"bit");

-- ----------------------------
-- Alter sequences owned by
-- ----------------------------
SELECT setval('"public"."messages_id_seq"', 472, true);

-- ----------------------------
-- Alter sequences owned by
-- ----------------------------
SELECT setval('"public"."myorders_transactionid_seq"', 830436, true);

-- ----------------------------
-- Indexes structure for table balance
-- ----------------------------
CREATE UNIQUE INDEX "pk_balance" ON "public"."balance" USING btree (
  "tpid" "pg_catalog"."int4_ops" ASC NULLS LAST,
  "securityid" "pg_catalog"."int4_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table balance
-- ----------------------------
ALTER TABLE "public"."balance" ADD CONSTRAINT "balance_pkey" PRIMARY KEY ("tpid", "securityid");

-- ----------------------------
-- Primary Key structure for table offtrades
-- ----------------------------
ALTER TABLE "public"."offtrades" ADD CONSTRAINT "offtrades_pkey" PRIMARY KEY ("tpid", "tradeno1", "tradeno2");

-- ----------------------------
-- Primary Key structure for table orders
-- ----------------------------
ALTER TABLE "public"."orders" ADD CONSTRAINT "orders_pkey" PRIMARY KEY ("orderno");

-- ----------------------------
-- Primary Key structure for table securities
-- ----------------------------
ALTER TABLE "public"."securities" ADD CONSTRAINT "securities_pkey" PRIMARY KEY ("securityid");

-- ----------------------------
-- Primary Key structure for table tp_sec
-- ----------------------------
ALTER TABLE "public"."tp_sec" ADD CONSTRAINT "tp_sec_pkey" PRIMARY KEY ("tp_id", "sec_id", "accountid");

-- ----------------------------
-- Primary Key structure for table trades
-- ----------------------------
ALTER TABLE "public"."trades" ADD CONSTRAINT "trades_pkey" PRIMARY KEY ("tradeno");
