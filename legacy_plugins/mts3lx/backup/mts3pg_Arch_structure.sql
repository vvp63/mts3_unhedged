/*
 Navicat Premium Data Transfer

 Source Server         : Aquila collo
 Source Server Type    : PostgreSQL
 Source Server Version : 120008
 Source Host           : localhost:5432
 Source Catalog        : mts3pg
 Source Schema         : Arch

 Target Server Type    : PostgreSQL
 Target Server Version : 120008
 File Encoding         : 65001

 Date: 01/09/2021 11:34:04
*/


-- ----------------------------
-- Table structure for balance
-- ----------------------------
DROP TABLE IF EXISTS "Arch"."balance";
CREATE UNLOGGED TABLE "Arch"."balance" (
  "tpid" int4 NOT NULL,
  "securityid" int4 NOT NULL,
  "quantity" int4 NOT NULL,
  "lasttradeno" int8 NOT NULL,
  "quote" float8,
  "arch_time" timestamp(6)
)
;

-- ----------------------------
-- Table structure for myorders
-- ----------------------------
DROP TABLE IF EXISTS "Arch"."myorders";
CREATE UNLOGGED TABLE "Arch"."myorders" (
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
  "answertime" timestamp(6),
  "archtime" timestamp(6)
)
;

-- ----------------------------
-- Table structure for offtrades
-- ----------------------------
DROP TABLE IF EXISTS "Arch"."offtrades";
CREATE UNLOGGED TABLE "Arch"."offtrades" (
  "code" varchar(50) COLLATE "pg_catalog"."default",
  "tpid" int4,
  "tradeno1" int8,
  "tradeno2" int8,
  "offtime" timestamp(6),
  "qtyoff" int4,
  "offresult" float8,
  "arch_time" timestamp(6)
)
;

-- ----------------------------
-- Table structure for orders
-- ----------------------------
DROP TABLE IF EXISTS "Arch"."orders";
CREATE UNLOGGED TABLE "Arch"."orders" (
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
  "comment" varchar(30) COLLATE "pg_catalog"."default",
  "arch_time" timestamp(6)
)
;

-- ----------------------------
-- Table structure for trades
-- ----------------------------
DROP TABLE IF EXISTS "Arch"."trades";
CREATE UNLOGGED TABLE "Arch"."trades" (
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
  "qtyoff" int4 DEFAULT 0,
  "arch_time" timestamp(6)
)
;
