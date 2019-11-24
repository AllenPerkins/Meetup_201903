-------------------------------------------------------------------------------
--Create database tables for the source data.
-------------------------------------------------------------------------------
CREATE SCHEMA "NLP";
CREATE SEQUENCE "NLP"."TopN"
INCREMENT BY 1 START WITH 100000;
DROP TABLE IF EXISTS "NLP"."Top10";
CREATE TABLE "NLP"."Top10"(
  "Top10Id"   INT CONSTRAINT pk_nlp_top10_top10id
              PRIMARY KEY
              DEFAULT nextval('"NLP"."TopN"'),
  "Word"      VARCHAR(200),
  "Sentiment" VARCHAR(200),
  "Frequency" INT,
  "YearMon"   VARCHAR(6)
);

CREATE SCHEMA "Econ";
CREATE SEQUENCE "Econ"."Series"
INCREMENT BY 1 START WITH 100000;
DROP TABLE IF EXISTS "Econ"."MultiSeries";
CREATE TABLE "Econ"."MultiSeries"(
  "MultiSeriesId"	INT CONSTRAINT pk_econ_multiseries_multiseries0id
					        PRIMARY KEY
					        DEFAULT nextval('"Econ"."Series"'),
  "Date"			    DATE,
  "Unemployment"  DOUBLE PRECISION,
  "Inflation"     DOUBLE PRECISION,
  "Interest"      DOUBLE PRECISION
);
