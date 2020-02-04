/*
 Navicat Premium Data Transfer

 Source Server         : Aquila
 Source Server Type    : PostgreSQL
 Source Server Version : 100010
 Source Host           : localhost:5432
 Source Catalog        : MTS3pg
 Source Schema         : public

 Target Server Type    : PostgreSQL
 Target Server Version : 110000
 File Encoding         : 65001

 Date: 03/02/2020 17:01:19
*/


-- ----------------------------
-- Sequence structure for myorders_transactionid_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "myorders_transactionid_seq";
CREATE SEQUENCE "myorders_transactionid_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 2147483647
START 1
CACHE 1;

-- ----------------------------
-- Table structure for accounts
-- ----------------------------
DROP TABLE IF EXISTS "accounts";
CREATE TABLE "accounts" (
  "id" int4 NOT NULL,
  "account" varchar(20) COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Records of accounts
-- ----------------------------
BEGIN;
INSERT INTO "accounts" VALUES (4, 'SOLID30101');
INSERT INTO "accounts" VALUES (1, '01533001SOLID');
COMMIT;

-- ----------------------------
-- Table structure for balance
-- ----------------------------
DROP TABLE IF EXISTS "balance";
CREATE TABLE "balance" (
  "tpid" int4 NOT NULL,
  "securityid" int4 NOT NULL,
  "quantity" int4 NOT NULL,
  "lasttradeno" int8 NOT NULL
)
;

-- ----------------------------
-- Records of balance
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for myorders
-- ----------------------------
DROP TABLE IF EXISTS "myorders";
CREATE TABLE "myorders" (
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
-- Records of myorders
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for offtrades
-- ----------------------------
DROP TABLE IF EXISTS "offtrades";
CREATE TABLE "offtrades" (
  "code" varchar(50) COLLATE "pg_catalog"."default",
  "tpid" int4,
  "tradeno1" int8,
  "tradeno2" int8,
  "offtime" timestamp(6),
  "qtyoff" int4,
  "offresult" float8
)
;

-- ----------------------------
-- Records of offtrades
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for orders
-- ----------------------------
DROP TABLE IF EXISTS "orders";
CREATE TABLE "orders" (
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
-- Records of orders
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for out_getactiveorders
-- ----------------------------
DROP TABLE IF EXISTS "out_getactiveorders";
CREATE TABLE "out_getactiveorders" (
  "Transactionid" int4,
  "Price" float4,
  "balance" int4,
  "orderno" int8,
  "SetTime" timestamp(6)
)
;

-- ----------------------------
-- Records of out_getactiveorders
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for out_getseclist
-- ----------------------------
DROP TABLE IF EXISTS "out_getseclist";
CREATE TABLE "out_getseclist" (
  "SecurityId" int4,
  "code" varchar(50) COLLATE "pg_catalog"."default",
  "level" varchar(50) COLLATE "pg_catalog"."default",
  "stockid" int4,
  "SecType" varchar(1) COLLATE "pg_catalog"."default",
  "account" varchar(20) COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Records of out_getseclist
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for out_getsecparams
-- ----------------------------
DROP TABLE IF EXISTS "out_getsecparams";
CREATE TABLE "out_getsecparams" (
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
-- Records of out_getsecparams
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for out_gettpqtys
-- ----------------------------
DROP TABLE IF EXISTS "out_gettpqtys";
CREATE TABLE "out_gettpqtys" (
  "securityid" int4,
  "quantity" int4
)
;

-- ----------------------------
-- Records of out_gettpqtys
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for out_gettpseclist
-- ----------------------------
DROP TABLE IF EXISTS "out_gettpseclist";
CREATE TABLE "out_gettpseclist" (
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
-- Records of out_gettpseclist
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for out_setorderrejected
-- ----------------------------
DROP TABLE IF EXISTS "out_setorderrejected";
CREATE TABLE "out_setorderrejected" (
  "tpid" int4,
  "securityid" int4
)
;

-- ----------------------------
-- Records of out_setorderrejected
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for securities
-- ----------------------------
DROP TABLE IF EXISTS "securities";
CREATE TABLE "securities" (
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
-- Records of securities
-- ----------------------------
BEGIN;
INSERT INTO "securities" VALUES (101, 'AFKS', 'TQBR', 1, 1, 'S', 100, 0.005, 0.005, 300, 0, 10, 0.7, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (102, 'ALRS', 'TQBR', 1, 1, 'S', 10, 0.01, 0.01, 300, 0, 10, 0.7, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (103, 'CHMF', 'TQBR', 1, 1, 'S', 10, 0.1, 0.1, 300, 0, 10, 0.7, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (104, 'FEES', 'TQBR', 1, 1, 'S', 10000, 1e-05, 1e-05, 300, 2, 5, 0.7, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (105, 'GAZP', 'TQBR', 1, 1, 'S', 10, 0.01, 0.01, 300, 0, 50, 1, 125, 0.5, 1, '0');
INSERT INTO "securities" VALUES (5000, 'RTSI', 'RTSI', 4, 4, 'I', 1, 1, 1, 300, 0, 0, 0, 0, 0, 1, '0');
INSERT INTO "securities" VALUES (106, 'GMKN', 'TQBR', 1, 1, 'S', 1, 1, 1, 300, 0, 10, 1, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (107, 'HYDR', 'TQBR', 1, 1, 'S', 1000, 0.0001, 0.0001, 300, 2, 10, 1, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (108, 'LKOH', 'TQBR', 1, 1, 'S', 1, 0.5, 0.5, 300, 2, 50, 1, 100, 0.5, 1, '0');
INSERT INTO "securities" VALUES (109, 'MGNT', 'TQBR', 1, 1, 'S', 1, 1, 1, 300, 2, 10, 1, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (123, 'NLMK', 'TQBR', 1, 1, 'S', 10, 0.02, 0.02, 300, 2, 30, 1, 40, 0.5, 1, '0');
INSERT INTO "securities" VALUES (5001, 'RURUSD', 'RTSI', 4, 4, 'I', 1, 1, 1, 900, 0, 0, 0, 0, 0, 1, '0');
INSERT INTO "securities" VALUES (5002, 'MCX EQ ON', 'RTSI', 4, 4, 'I', 1, 1, 1, 300, 0, 0, 0, 0, 0, 1, '0');
INSERT INTO "securities" VALUES (110, 'MOEX', 'TQBR', 1, 1, 'S', 10, 0.01, 0.01, 300, 2, 10, 1, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (111, 'MTSS', 'TQBR', 1, 1, 'S', 10, 0.05, 0.05, 300, 2, 10, 1, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (112, 'NVTK', 'TQBR', 1, 1, 'S', 10, 0.1, 0.1, 300, 2, 10, 1, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (113, 'ROSN', 'TQBR', 1, 1, 'S', 10, 0.05, 0.05, 300, 2, 20, 1, 40, 0.5, 1, '0');
INSERT INTO "securities" VALUES (114, 'RTKM', 'TQBR', 1, 1, 'S', 10, 0.01, 0.01, 300, 2, 10, 0.7, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (115, 'SBER', 'TQBR', 1, 1, 'S', 10, 0.01, 0.01, 300, 0, 50, 1, 125, 0.5, 1, '0');
INSERT INTO "securities" VALUES (116, 'SBERP', 'TQBR', 1, 1, 'S', 10, 0.01, 0.01, 300, 2, 10, 0.7, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (117, 'SNGS', 'TQBR', 1, 1, 'S', 100, 0.005, 0.005, 300, 2, 20, 1, 40, 0.5, 1, '0');
INSERT INTO "securities" VALUES (118, 'SNGSP', 'TQBR', 1, 1, 'S', 100, 0.005, 0.005, 300, 2, 10, 1, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (119, 'TATN', 'TQBR', 1, 1, 'S', 10, 0.1, 0.1, 300, 2, 12, 1, 30, 0.5, 1, '0');
INSERT INTO "securities" VALUES (120, 'TRNFP', 'TQBR', 1, 1, 'S', 1, 50, 50, 300, 0, 1, 0.7, 3, 0.5, 1, '0');
INSERT INTO "securities" VALUES (121, 'URKA', 'TQBR', 1, 1, 'S', 10, 0.05, 0.05, 300, 2, 10, 1, 60, 0.5, 1, '0');
INSERT INTO "securities" VALUES (122, 'VTBR', 'TQBR', 1, 1, 'S', 10000, 1e-05, 1e-05, 300, 0, 125, 1, 200, 0.5, 1, '0');
INSERT INTO "securities" VALUES (6001, 'USD000UTSTOM', 'CETS', 5, 15, 'F', 1000, 0.0025, 0.0025, 900, 10, 10, 0.7, 20, 0.5, 1, '1');
INSERT INTO "securities" VALUES (1073, 'MIX-3.19', 'FUTU', 4, 4, 'F', 1, 25, 25, 300, 10, 10, 0.7, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (124, 'AFLT', 'TQBR', 1, 1, 'S', 10, 0.05, 0.05, 300, 2, 3, 0.7, 7, 0.5, 1, '0');
INSERT INTO "securities" VALUES (125, 'BANE', 'TQBR', 1, 1, 'S', 1, 0.5, 0.5, 300, 0, 10, 1, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (126, 'IRAO', 'TQBR', 1, 1, 'S', 1000, 0.0005, 0.0005, 300, 2, 3, 1, 10, 0.5, 1, '0');
INSERT INTO "securities" VALUES (127, 'MAGN', 'TQBR', 1, 1, 'S', 100, 0.005, 0.005, 300, 2, 3, 0.7, 10, 0.5, 1, '0');
INSERT INTO "securities" VALUES (128, 'POLY', 'TQBR', 1, 1, 'S', 1, 0.1, 0.1, 300, 2, 20, 1, 50, 0.5, 1, '0');
INSERT INTO "securities" VALUES (129, 'YNDX', 'TQBR', 1, 1, 'S', 1, 0.5, 0.5, 300, 2, 20, 1, 40, 0.5, 1, '0');
INSERT INTO "securities" VALUES (131, 'MTLR', 'TQBR', 1, 1, 'S', 1, 0.05, 0.05, 300, 2, 20, 1, 40, 0.5, 1, '0');
INSERT INTO "securities" VALUES (132, 'UPRO', 'TQBR', 1, 1, 'S', 1000, 0.001, 0.001, 300, 2, 3, 1, 10, 0.5, 1, '0');
INSERT INTO "securities" VALUES (133, 'PHOR', 'TQBR', 1, 1, 'S', 1, 1, 1, 300, 2, 3, 1, 10, 0.5, 1, '0');
INSERT INTO "securities" VALUES (134, 'MSNG', 'TQBR', 1, 1, 'S', 1000, 0.0005, 0.0005, 300, 2, 3, 1, 10, 0.5, 1, '0');
INSERT INTO "securities" VALUES (135, 'BANEP', 'TQBR', 1, 1, 'S', 1, 0.5, 0.5, 300, 2, 3, 0.7, 10, 0.5, 1, '0');
INSERT INTO "securities" VALUES (136, 'PIKK', 'TQBR', 1, 1, 'S', 10, 0.1, 0.1, 300, 2, 3, 0.7, 10, 0.5, 1, '0');
INSERT INTO "securities" VALUES (137, 'RSTI', 'TQBR', 1, 1, 'S', 1000, 0.0001, 0.0001, 300, 2, 3, 0.7, 10, 0.5, 1, '0');
INSERT INTO "securities" VALUES (138, 'MVID', 'TQBR', 1, 1, 'S', 10, 0.1, 0.1, 300, 2, 3, 0.7, 10, 0.5, 1, '0');
INSERT INTO "securities" VALUES (139, 'RUAL', 'TQBR', 1, 1, 'S', 10, 0.01, 0.01, 300, 2, 10, 0.7, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (140, 'CBOM', 'TQBR', 1, 1, 'S', 100, 0.001, 0.001, 300, 2, 3, 0.7, 10, 0.5, 1, '0');
INSERT INTO "securities" VALUES (142, 'TATNP', 'TQBR', 1, 1, 'S', 10, 0.1, 0.1, 300, 2, 10, 1, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (1024, 'CMX GLDFEB16', 'CME', 7, 7, 'F', 100, 0.1, 0.1, 300, 5, 5, 0.5, 15, 0.3, 1, '1');
INSERT INTO "securities" VALUES (5003, 'IMOEX', 'RTSI', 4, 4, 'I', 1, 1, 1, 300, 0, 0, 0, 0, 0, 1, '0');
INSERT INTO "securities" VALUES (130, 'MFON', 'TQBR', 1, 1, 'S', 10, 0.1, 0.1, 300, 2, 10, 1, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (141, 'NMTP', 'TQBR', 1, 1, 'S', 1000, 0.005, 0.005, 300, 2, 3, 1, 10, 0.5, 1, '0');
INSERT INTO "securities" VALUES (143, 'PLZL', 'TQBR', 1, 1, 'S', 1, 1, 1, 300, 2, 10, 1, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (144, 'FIVE', 'TQBR', 1, 1, 'S', 1, 0.5, 0.5, 300, 2, 10, 1, 20, 0.5, 1, '0');
INSERT INTO "securities" VALUES (1075, 'RTS-9.19', 'FUTU', 4, 4, 'F', 1, 10, 10, 300, 10, 10, 0.7, 20, 0.5, 1.3347, '0');
INSERT INTO "securities" VALUES (1076, 'RTS-12.19', 'FUTU', 4, 4, 'F', 1, 10, 10, 300, 10, 10, 0.7, 20, 0.5, 1.3347, '0');
INSERT INTO "securities" VALUES (2202, 'SBRF-6.20', 'FUTU', 4, 4, 'F', 100, 1, 1, 300, 5, 0, 0, 0, 0, 1, '0');
INSERT INTO "securities" VALUES (2201, 'SBRF-3.20', 'FUTU', 4, 4, 'F', 100, 1, 1, 300, 5, 0, 0, 0, 0, 1, '0');
INSERT INTO "securities" VALUES (2203, 'Si-3.20', 'FUTU', 4, 4, 'F', 1000, 1, 1, 300, 5, 0, 0, 0, 0, 1, '0');
INSERT INTO "securities" VALUES (2204, 'Si-6.20', 'FUTU', 4, 4, 'F', 1000, 1, 1, 300, 5, 0, 0, 0, 0, 1, '0');
COMMIT;

-- ----------------------------
-- Table structure for tp
-- ----------------------------
DROP TABLE IF EXISTS "tp";
CREATE TABLE "tp" (
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
-- Records of tp
-- ----------------------------
BEGIN;
INSERT INTO "tp" VALUES (21105, 'RIU9:SIU9', '0', '1', '1', 1300, 2000, 50, 0, 0, 0, 0, 1, 10, 7, 200, 1, 1, 'M', 0, 0, 0);
INSERT INTO "tp" VALUES (20185, 'RIH9:Micex', '0', '1', '0', -10000, 10000, 0, 0, 0, 0, 0, 1, 1, 0, 0, 2, 1, 'M', 0, 0, 0);
INSERT INTO "tp" VALUES (20175, 'MIX9:Micex', '0', '0', '0', -10000, 10000, 0, 0, 0, 0, 0.2, 1, 1, 0, 0, 2, 1, 'M', 0, 0, 0);
INSERT INTO "tp" VALUES (22022, 'SRM0:SRH0', '1', '0', '0', -10000, 10000, 0, 0, 0, 0, 0, 1, 1, 5, 100, 2, 1, 'M', 0, 0, 0);
INSERT INTO "tp" VALUES (22032, 'SiM0:SiH0', '1', '1', '1', -680, -665, 8, -8, 1, 1, 0, 1, 3, 10, 1000, 3, 2, 'M', 0, 0, 0);
COMMIT;

-- ----------------------------
-- Table structure for tp_sec
-- ----------------------------
DROP TABLE IF EXISTS "tp_sec";
CREATE TABLE "tp_sec" (
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
-- Records of tp_sec
-- ----------------------------
BEGIN;
INSERT INTO "tp_sec" VALUES (21105, 1075, 4, 'H', 1, 1, 0, 1);
INSERT INTO "tp_sec" VALUES (21105, 1076, 4, 'B', 1, 1, 0, 1);
INSERT INTO "tp_sec" VALUES (22022, 2202, 4, 'B', 1, 1, 0, 1);
INSERT INTO "tp_sec" VALUES (22022, 2201, 4, 'H', 1, 1, 0, 1);
INSERT INTO "tp_sec" VALUES (22032, 2204, 4, 'B', 1, 1, 0, 1);
INSERT INTO "tp_sec" VALUES (22032, 2203, 4, 'H', 1, 1, 0, 1);
COMMIT;

-- ----------------------------
-- Table structure for trades
-- ----------------------------
DROP TABLE IF EXISTS "trades";
CREATE TABLE "trades" (
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
-- Records of trades
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for tradescheldue
-- ----------------------------
DROP TABLE IF EXISTS "tradescheldue";
CREATE TABLE "tradescheldue" (
  "id" int4 NOT NULL,
  "starttime" timestamp(6) NOT NULL,
  "stoptime" timestamp(6) NOT NULL,
  "secstopbefore" int4 NOT NULL
)
;

-- ----------------------------
-- Records of tradescheldue
-- ----------------------------
BEGIN;
INSERT INTO "tradescheldue" VALUES (1, '2019-01-25 10:30:00', '2019-01-25 17:50:00', 10);
COMMIT;

-- ----------------------------
-- Function structure for _User_DellOT
-- ----------------------------
DROP FUNCTION IF EXISTS "_User_DellOT"();
CREATE OR REPLACE FUNCTION "_User_DellOT"()
  RETURNS "pg_catalog"."void" AS $BODY$ 	
DELETE FROM public.myorders;
DELETE FROM public.balance;
DELETE FROM public.trades;
DELETE FROM public.orders;
 $BODY$
  LANGUAGE sql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for addmyorder
-- ----------------------------
DROP FUNCTION IF EXISTS "addmyorder"("tpid" int4, "securityid" int4, "buysell" varchar, "price" float4, "quantity" int4);
CREATE OR REPLACE FUNCTION "addmyorder"("tpid" int4, "securityid" int4, "buysell" varchar, "price" float4, "quantity" int4)
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
-- Function structure for addupdatebalance
-- ----------------------------
DROP FUNCTION IF EXISTS "addupdatebalance"("atradeno" int8, "atransaction" int4, "acode" varchar, "aquantity" int4);
CREATE OR REPLACE FUNCTION "addupdatebalance"("atradeno" int8, "atransaction" int4, "acode" varchar, "aquantity" int4)
  RETURNS "pg_catalog"."int4" AS $BODY$
	DECLARE	vTPId		int;
	DECLARE	vSecurityId	int;
BEGIN

	vTPId = (select TPId FROM MyOrders WHERE TransactionId	=	atransaction);
	vTPId = COALESCE(vTPId, 0);
	UPDATE Trades SET _TPId = vTPId WHERE tradeno = atradeno;
	vSecurityId	= (select SecurityId	FROM Securities WHERE code = acode);
	UPDATE Balance SET Quantity = Quantity + aquantity, LastTradeNo = atradeno
	WHERE TPId = vTPId AND SecurityId = vSecurityId;

	IF NOT FOUND THEN
		INSERT INTO public.Balance
           (TPId, SecurityId, Quantity, LastTradeNo)
		VALUES
			(vTPId, vSecurityId, aquantity, atradeno);
	END IF;
			 
  	RETURN 1;
	

	
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for addupdateorder
-- ----------------------------
DROP FUNCTION IF EXISTS "addupdateorder"("v_transaction" int4, "v_internalid" int4, "v_stockid" int4, "v_level" varchar, "v_code" varchar, "v_orderno" int8, "v_ordertime" timestamp, "v_status" varchar, "v_buysell" varchar, "v_account" varchar, "v_price" float4, "v_quantity" int4, "v_value" float4, "v_clientid" varchar, "v_balance" int4, "v_ordertype" varchar, "v_settlecode" varchar, "v_comment" varchar);
CREATE OR REPLACE FUNCTION "addupdateorder"("v_transaction" int4, "v_internalid" int4, "v_stockid" int4, "v_level" varchar, "v_code" varchar, "v_orderno" int8, "v_ordertime" timestamp, "v_status" varchar, "v_buysell" varchar, "v_account" varchar, "v_price" float4, "v_quantity" int4, "v_value" float4, "v_clientid" varchar, "v_balance" int4, "v_ordertype" varchar, "v_settlecode" varchar, "v_comment" varchar)
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
DROP FUNCTION IF EXISTS "addupdatetrade"("v_transaction" int4, "v_internalid" int4, "v_stockid" int4, "v_level" varchar, "v_code" varchar, "v_tradeno" int8, "v_orderno" int8, "v_tradetime" timestamp, "v_buysell" varchar, "v_account" varchar, "v_price" float4, "v_quantity" int4, "v_value" float4, "v_accr" float4, "v_clientid" varchar, "v_tradetype" varchar, "v_settlecode" varchar, "v_comment" varchar);
CREATE OR REPLACE FUNCTION "addupdatetrade"("v_transaction" int4, "v_internalid" int4, "v_stockid" int4, "v_level" varchar, "v_code" varchar, "v_tradeno" int8, "v_orderno" int8, "v_tradetime" timestamp, "v_buysell" varchar, "v_account" varchar, "v_price" float4, "v_quantity" int4, "v_value" float4, "v_accr" float4, "v_clientid" varchar, "v_tradetype" varchar, "v_settlecode" varchar, "v_comment" varchar)
  RETURNS "pg_catalog"."int4" AS $BODY$
	DECLARE	QtyChange	int;
	DECLARE r	int;
	declare t 	int;
	declare tmp int;
	declare vordtrs	int;
begin
	
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

		PERFORM AddUpdateBalance(v_tradeno, v_transaction, v_code, QtyChange);
		PERFORM OffTradeQty(v_tradeno);
		   
	END IF;

	select count(*) into strict vordtrs FROM Orders WHERE "transaction" = v_transaction; 

	if (vordtrs > 0) THEN
		SELECT RefreshTrsStatus(v_transaction) into strict tmp;
	end if;

	SELECT COALESCE(TPId, 0) into strict r FROM public.MyOrders WHERE TransactionId = v_transaction;
			 
  RETURN r;
	
	
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for getactiveorders
-- ----------------------------
DROP FUNCTION IF EXISTS "getactiveorders"("atpid" int4, "asecurityid" int4, "abuysell" varchar);
CREATE OR REPLACE FUNCTION "getactiveorders"("atpid" int4, "asecurityid" int4, "abuysell" varchar)
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
-- Function structure for getseclist
-- ----------------------------
DROP FUNCTION IF EXISTS "getseclist"();
CREATE OR REPLACE FUNCTION "getseclist"()
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
DROP FUNCTION IF EXISTS "getsecparams"("asecurityid" int4);
CREATE OR REPLACE FUNCTION "getsecparams"("asecurityid" int4)
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
DROP FUNCTION IF EXISTS "gettplist"();
CREATE OR REPLACE FUNCTION "gettplist"()
  RETURNS SETOF "public"."tp" AS $BODY$
    SELECT * FROM public.TP
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- Function structure for gettpparams
-- ----------------------------
DROP FUNCTION IF EXISTS "gettpparams"("atpid" int4);
CREATE OR REPLACE FUNCTION "gettpparams"("atpid" int4)
  RETURNS SETOF "public"."tp" AS $BODY$
    SELECT * FROM public.TP WHERE TPId = aTPId
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- Function structure for gettpqtys
-- ----------------------------
DROP FUNCTION IF EXISTS "gettpqtys"("atpid" int4);
CREATE OR REPLACE FUNCTION "gettpqtys"("atpid" int4)
  RETURNS SETOF "public"."out_gettpqtys" AS $BODY$
    SELECT SecurityId, Quantity FROM public.Balance WHERE TPId = @TPId
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- Function structure for gettpseclist
-- ----------------------------
DROP FUNCTION IF EXISTS "gettpseclist"("atpid" int4);
CREATE OR REPLACE FUNCTION "gettpseclist"("atpid" int4)
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
DROP FUNCTION IF EXISTS "gettradescheldue"();
CREATE OR REPLACE FUNCTION "gettradescheldue"()
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
DROP FUNCTION IF EXISTS "offtradeqty"("atradeno" int8);
CREATE OR REPLACE FUNCTION "offtradeqty"("atradeno" int8)
  RETURNS "pg_catalog"."int4" AS $BODY$
	DECLARE tn2 bigint;
	DECLARE qtyoff	int;
	DECLARE fulloff	smallint;
BEGIN
/*
	set fulloff	=	1;
	
	UNTIL (fulloff = 0)
    LOOP
	
		DROP TABLE IF EXISTS _Off_Trades;

		CREATE TEMP TABLE _Off_Trades AS
		SELECT * FROM
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
		) AS t;
		
		UPDATE Trades SET QtyOff = QtyOff + diff FROM _Off_Trades WHERE (tradeno = tn1) OR (tradeno = tn2);
		INSERT INTO OffTrades (code, TPId, tradeno1, tradeno2, OffTime, qtyoff, OffResult)
			 (SELECT code, _TPId, tn1, tn2, tt1, diff, diff * (vq1 + vq2) FROM _Off_Trades);
		tn2 = (select tn2  FROM _Off_Trades);
		qtyoff = (select diff FROM _Off_Trades);
		fulloff = (SELECT COUNT(*) FROM _Off_Trades);	
	
	END LOOP;
	*/
		 
  	RETURN 1;
	
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for refreshtrsstatus
-- ----------------------------
DROP FUNCTION IF EXISTS "refreshtrsstatus"("trsid" int4);
CREATE OR REPLACE FUNCTION "refreshtrsstatus"("trsid" int4)
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

/*
	select COALESCE(o.transaction, 0) into strict v_gettrsid
	FROM Orders AS o LEFT JOIN Trades AS t ON (o.transaction=t.transaction)
	WHERE o.transaction = trsid GROUP BY o.transaction, o.status, o.quantity, o.balance, t.quantity;
	
	select o.status into strict v_status
	FROM Orders AS o LEFT JOIN Trades AS t ON (o.transaction=t.transaction)
	WHERE o.transaction = trsid GROUP BY o.transaction, o.status, o.quantity, o.balance, t.quantity;

	select (o.quantity - o.balance - COALESCE(SUM(t.quantity), 0)) into strict v_qtyleft
	FROM Orders AS o LEFT JOIN Trades AS t ON (o.transaction=t.transaction)
	WHERE o.transaction = trsid GROUP BY o.transaction, o.status, o.quantity, o.balance, t.quantity;
	

																														   
	UPDATE MyOrders as mo SET
		Status = CASE WHEN v_gettrsid > 0 THEN
							CASE 
								WHEN (v_qtyleft > 0) OR (v_status = 'O') THEN 'O'
								ELSE 'C' END
						ELSE Status END,
		AnswerTimeFloat = 0
	WHERE TransactionId = v_gettrsid;		
	*/
	
	RETURN v_gettrsid;

	
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for setanswertime
-- ----------------------------
DROP FUNCTION IF EXISTS "setanswertime"("trsid" int4);
CREATE OR REPLACE FUNCTION "setanswertime"("trsid" int4)
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
DROP FUNCTION IF EXISTS "setdroptime"("atrsid" int4, "adroptime" timestamp);
CREATE OR REPLACE FUNCTION "setdroptime"("atrsid" int4, "adroptime" timestamp)
  RETURNS "pg_catalog"."int4" AS $BODY$
    UPDATE public.MyOrders SET DropAttemptTime = now()--adroptime 
		WHERE TransactionId = atrsid RETURNING 1
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for setorderrejected
-- ----------------------------
DROP FUNCTION IF EXISTS "setorderrejected"("atransactionid" int4);
CREATE OR REPLACE FUNCTION "setorderrejected"("atransactionid" int4)
  RETURNS SETOF "public"."out_setorderrejected" AS $BODY$

--	IF (SELECT COUNT(*) FROM Orders WHERE [transaction] = @TransactionId) = 0
	UPDATE MyOrders SET status = 'R' WHERE TransactionId = aTransactionId;

	SELECT TPId, SecurityId FROM MyOrders WHERE TransactionId = aTransactionId;
	
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- View structure for OrdersDelay
-- ----------------------------
DROP VIEW IF EXISTS "OrdersDelay";
CREATE VIEW "OrdersDelay" AS  SELECT myorders.transactionid,
    date_part('milliseconds'::text, (myorders.answertime - myorders.settime)) AS delay
   FROM myorders
  ORDER BY myorders.transactionid DESC;

-- ----------------------------
-- Records of tradescheldue
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Alter sequences owned by
-- ----------------------------
SELECT setval('"myorders_transactionid_seq"', 104152, true);

-- ----------------------------
-- Indexes structure for table balance
-- ----------------------------
CREATE UNIQUE INDEX "pk_balance" ON "balance" USING btree (
  "tpid" "pg_catalog"."int4_ops" ASC NULLS LAST,
  "securityid" "pg_catalog"."int4_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table securities
-- ----------------------------
ALTER TABLE "securities" ADD CONSTRAINT "securities_pkey" PRIMARY KEY ("securityid");

-- ----------------------------
-- Primary Key structure for table tp
-- ----------------------------
ALTER TABLE "tp" ADD CONSTRAINT "tp_pkey" PRIMARY KEY ("tpid");
