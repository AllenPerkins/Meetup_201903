/*
We have this

 MultiSeriesId |    Date    | Unemployment | Inflation | Interest
---------------+------------+--------------+-----------+----------
        100000 | 2009-01-01 |          7.8 |   211.933 |     0.15
        100001 | 2009-02-01 |          8.3 |   212.705 |     0.22
        100002 | 2009-03-01 |          8.7 |   212.495 |     0.18
        100003 | 2009-04-01 |            9 |   212.709 |     0.15
        100004 | 2009-05-01 |          9.4 |   213.022 |     0.18

We need to get to this:

    Date    |  Trend   | TrendN
------------+----------+--------
 2009-01-01 | Negative |      0
 2009-10-01 | Positive |      1
 2010-02-01 | Negative |      0
 2010-04-01 | Positive |      1
 2010-07-01 | Negative |      0

So we need to shape our data.

*/

/*
Use a window function to get a start and end date for when the particular
measurement value was effective.
*/
DROP TABLE IF EXISTS "Econ"."Inflation_S0";
CREATE TABLE "Econ"."Inflation_S0" AS
SELECT
  LAG("Date", 1) OVER(ORDER BY "Date") AS "PrevDate",
  "Date",
  LAG("Inflation", 1) OVER () AS "PrevInflation",
  "Inflation"
FROM
  "Econ"."MultiSeries";

/*
With a LAG function the first observation is NULL. We fix that.
*/
DROP TABLE IF EXISTS "Econ"."Inflation_S1";
CREATE TABLE "Econ"."Inflation_S1" AS
SELECT
  "PrevDate",
  "Date",
  "PrevInflation",
  "Inflation"
FROM
  "Econ"."Inflation_S0"
WHERE 1=1
  AND "PrevDate" IS NOT NULL
UNION
SELECT
  "Date" AS "PrevDate",
  "Date",
  "Inflation" AS "PrevInflation",
  "Inflation"
FROM
  "Econ"."Inflation_S0"
WHERE 1=1
  AND "PrevDate" IS NULL
ORDER BY
  "Date";

/*
Based on the change in value from one month to the next, is the change
good or bad? Set the value of our categorical variable accordingly.
*/
DROP TABLE IF EXISTS "Econ"."Inflation_S2";
CREATE TABLE "Econ"."Inflation_S2" AS
SELECT
  "PrevDate",
  "Date",
  "PrevInflation",
  "Inflation",
  CASE
    WHEN "Inflation" < "PrevInflation" THEN 'Positive'
    WHEN "Inflation" > "PrevInflation" THEN 'Negative'
    WHEN "Inflation" = "PrevInflation" THEN 'Unchanged'
  END AS "Trend"
FROM
  "Econ"."Inflation_S1"
ORDER BY "Date";

/*
Update the previous trend category value now that we have a categorical
value.
*/
DROP TABLE IF EXISTS "Econ"."Inflation_S3";
CREATE TABLE "Econ"."Inflation_S3" AS
SELECT
  "PrevDate",
  "Date",
  "PrevInflation",
  "Inflation",
  CASE
    WHEN "Trend" = 'Unchanged' 
    THEN LAG("Trend", 1) OVER(ORDER BY "PrevDate")
    ELSE "Trend"
  END AS "PrevTrend",
  "Trend"
FROM
  "Econ"."Inflation_S2";

/*
We may have months where there is no change. Flag those unchanging months
and we will filter them out later.
*/
DROP TABLE IF EXISTS "Econ"."Inflation_S4";
CREATE TABLE "Econ"."Inflation_S4" AS
SELECT 
  "PrevDate",
  "Date",
  "PrevInflation",
  "Inflation",
  CASE
    WHEN LAG("PrevTrend", 1) OVER(ORDER BY "PrevDate") = "PrevTrend"
    THEN 'Skip'
    WHEN "PrevTrend" IS NULL
    THEN LAG("PrevTrend", 1) OVER(ORDER BY "PrevDate")
  END AS "Disposition",
  "PrevTrend",
  "Trend"
FROM 
  "Econ"."Inflation_S3"
WHERE 1=1
  AND "PrevTrend" <> 'Unchanged'
  AND "Trend" <> 'Unchanged';

/*
Provide a numerical value to complement our categorical variable.
For example, a positive categorical variable can be mapped to one and a
negative categorical variable can be mapped to zero.
*/
DROP TABLE IF EXISTS "Econ"."Inflation_S5";
CREATE TABLE "Econ"."Inflation_S5" AS
SELECT 
  "PrevDate" AS "Date",
  "PrevTrend" AS "Trend",
  CASE
    WHEN "PrevTrend" = 'Negative' THEN 0
    WHEN "PrevTrend" = 'Positive' THEN 1
  END AS "TrendN"
FROM 
  "Econ"."Inflation_S4"
WHERE 1=1
 AND "Disposition" IS NULL
ORDER BY
  "PrevDate";
