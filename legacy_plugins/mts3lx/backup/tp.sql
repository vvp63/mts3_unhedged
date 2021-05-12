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

 Date: 30/04/2021 15:55:50
*/


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
-- Records of tp
-- ----------------------------
INSERT INTO "public"."tp" VALUES (20175, 'MIX9:Micex', '0', '0', '0', -10000, 10000, 0, 0, 0, 0, 0.2, 0, 1, 1, 0, 0, 2, 1, 'M', 0, 0, 0);
INSERT INTO "public"."tp" VALUES (22032, 'SiM0:SiH0', '0', '0', '0', -50, -5, 3, 0, 0, 1, 1, 0, 1, 3, 10, 1000, 3, 2, 'M', 0, 0, 0);
INSERT INTO "public"."tp" VALUES (22022, 'SRM0:SRH0', '0', '1', '0', 800, 990, 0, 0, 0, 2, 2, 0, 1, 2, 5, 100, 2, 1, 'M', 0, 0, 0);
INSERT INTO "public"."tp" VALUES (21105, 'RIU9:SIU9', '0', '1', '1', 500, 2000, 50, 0, 0, 0, 0, 0, 1, 10, 7, 200, 1, 1, 'M', 0, 0, 0);
INSERT INTO "public"."tp" VALUES (20185, 'RIH9:Micex', '0', '1', '0', -10000, 10000, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 2, 1, 'M', 0, 0, 0);
INSERT INTO "public"."tp" VALUES (22042, 'SRM0:SBRF', '0', '1', '0', -40, -30, 0, -10, 1, 1, 0, 0, 1, 3, 10, 1000, 3, 2, 'M', 0, 0, 0);
INSERT INTO "public"."tp" VALUES (20275, 'MXZ0:Micex', '1', '1', '0', 140, 1140, 0, -1500, 0.17, 0.22, 0.00017, 0.00022, 5, 100, 5, 6000, 1, 5, 'V', 0, 0, 0);
INSERT INTO "public"."tp" VALUES (20665, 'RIU0:Micex(SiU0)', '1', '0', '0', 2114, 2414, 0, 0, 0, 10, 10, 0, 1, 3, 5, 100, 2, 1, 'M', 0, 0, 0);
INSERT INTO "public"."tp" VALUES (999105, 'MXZ0:IMOEX', '1', '0', '0', -10000, 10000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'V', 0, 0, 0);
