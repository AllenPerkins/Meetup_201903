/*

We have this:

 Top10Id |   Word   | Sentiment | Frequency | YearMon
---------+----------+-----------+-----------+---------
  108356 | weak     | negative  |        51 | 200901
  108357 | declined | negative  |        50 | 200901
  108358 | declines | negative  |        40 | 200901
  108359 | decline  | negative  |        39 | 200901
  108360 | weakened | negative  |        26 | 200901

We need to get to this:

   Start    |    End     | Outlook
------------+------------+----------
 2009-01-01 | 2010-04-01 | Negative
 2010-04-01 | 2010-07-01 | Positive
 2010-07-01 | 2010-12-01 | Negative
 2010-12-01 | 2011-04-01 | Positive
 2011-04-01 | 2012-02-01 | Negative

So we need to shape our data.

*/

/*
Create summary groupings for the different sentiments. Even though we
have some details, we just want to know whether the Beige Book text was
generally positive or generally negative. Sum up the scores for positive
and negative.
*/

DROP TABLE IF EXISTS "NLP"."LMScore";
CREATE TABLE "NLP"."LMScore" AS
SELECT
  "YearMon", 'positive' AS "Sentiment", SUM("Frequency") AS "Score"
FROM
  "NLP"."Top10"
WHERE
  "Sentiment" IN ('positive','superfluous')
GROUP BY
  "YearMon"
UNION
SELECT
  "YearMon", 'negative' AS "Sentiment", SUM("Frequency") AS "Score"
FROM
  "NLP"."Top10"
WHERE
  "Sentiment" IN ('negative', 'uncertainty', 'constraining')
GROUP BY
  "YearMon"
ORDER BY 1,3;

/*
Now that we have a sum of the scores, we need to get the max score for each
book that was published. In other words, for each month when a book was
published was the outlook more positive or more negative?
*/
DROP TABLE IF EXISTS "NLP"."LMScore_S0";
CREATE TABLE "NLP"."LMScore_S0" AS 
SELECT
  A."YearMon", A."Sentiment", A."Score"
FROM
  "NLP"."LMScore" A
INNER JOIN (
  SELECT "YearMon", MAX("Score") AS "Score"
  FROM   "NLP"."LMScore"
  GROUP BY "YearMon"
  ) AS B ON 1=1
    AND B."YearMon" = A."YearMon"
    AND B."Score" = A."Score"
ORDER BY
  A."YearMon";

/*
Use a windows function to get a begin and end period.
*/
DROP TABLE IF EXISTS "NLP"."LMScore_S1";
CREATE TABLE "NLP"."LMScore_S1" AS
SELECT
  "YearMon",
  LAG("YearMon", 1) OVER(ORDER BY "YearMon") AS "PrevYearMon",
  "Sentiment",
  LAG("Sentiment", 1) OVER () AS "PrevSentiment",
  "Score"
FROM
  "NLP"."LMScore_S0";

/*
Clean up column names and remove what we do not need.
*/
DROP TABLE IF EXISTS "NLP"."LMScore_S2";
CREATE TABLE "NLP"."LMScore_S2" AS
SELECT
  "YearMon",
  "Sentiment" AS "PrevSentiment",
  "Sentiment"
FROM
  "NLP"."LMScore_S1"
WHERE 1=1
  AND "PrevSentiment" IS NULL
UNION
SELECT
  "YearMon",
  "PrevSentiment",
  "Sentiment"
FROM
  "NLP"."LMScore_S1"
WHERE 1=1
  AND "Sentiment" <> "PrevSentiment"
ORDER BY
  "YearMon";

/*
Convert the YearMon column to a string that looks like a date. YearMon
was a string parsed from the file name used by our web scraper.
*/
DROP TABLE IF EXISTS "NLP"."LMScore_S3";
CREATE TABLE "NLP"."LMScore_S3" AS
SELECT
  TO_CHAR(TO_DATE("YearMon", 'YYYYMM'),'YYYY-MM-DD') AS "Start",
  CASE
    WHEN LEAD("YearMon", 1) OVER() IS NOT NULL
    THEN TO_CHAR(TO_DATE(LEAD("YearMon", 1) OVER(),'YYYYMM'),'YYYY-MM-DD')
    ELSE TO_CHAR(TO_DATE('201903', 'YYYYMM'), 'YYYY-MM-DD')
  END AS "End",
  INITCAP("Sentiment") AS "Outlook"
FROM
  "NLP"."LMScore_S2"
ORDER BY 1;

