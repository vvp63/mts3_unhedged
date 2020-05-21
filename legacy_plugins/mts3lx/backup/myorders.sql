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

 Date: 07/05/2020 12:24:07
*/


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
