

CREATE DATABASE vinDiata;
USE vinDiata;

CREATE TABLE ABCdata(
user_id INT,
gPlayed INT,
deposit INT,
withdrawal INT,
gPlayedPoint DECIMAL(10,3),
depositPoint DECIMAL(10,3),
withdrawalPoint DECIMAL(10,3),
deposGreaterThanwithdPoint DECIMAL(10,3),
loyaltyPoint DECIMAL(10,3),
slot VARCHAR(10),
month INT,
date INT
);

ALTER TABLE gPlayed ALTER COLUMN Games_Played INT;

-- Making Master Table having all necessary columns to easily create KPI's , 
--columns are created after extracting values from Games Played Table, DEposit Table, Withdrawal Table.

GO

INSERT INTO ABCdata(
user_id,
gPlayed,
deposit,
withdrawal,
gPlayedPoint,
depositPoint,
withdrawalPoint,
deposGreaterThanwithdPoint,
loyaltyPoint,
slot,
month,
date 
) 

SELECT 
COALESCE(g.user_id, d.user_id, w.user_id) AS user_id,
ISNULL(g.gPlayed,0) AS gPlayed,
ISNULL(d.deposit,0) AS deposit,
ISNULL(w.withdrawal,0) AS withdrawal,

--POINTS

0.2*ISNULL(g.gPlayed,0) AS gPlayedPoint,
0.01*ISNULL(d.deposit,0) AS deposPoint,
0.005*ISNULL(w.withdrawal,0) AS withdPoint,
-- Deposit Greater Than Withdrawal 
0.001*
CASE
 WHEN ISNULL(d.deposit,0) - ISNULL(w.withdrawal,0) >0
 THEN ISNULL(d.deposit,0) - ISNULL(w.withdrawal,0)
 ELSE 0
END AS deposGreaterThanWithdPoint,

--Loyalty Point

(
  0.2 * ISNULL(g.gPlayed,0) + 0.01 * ISNULL(d.deposit,0) + 0.005 * ISNULL(w.withdrawal,0) + 
  0.001*
  CASE
     WHEN ISNULL(d.deposit,0) - ISNULL(w.withdrawal,0) >0
     THEN ISNULL(d.deposit,0) - ISNULL(w.withdrawal,0)
   ELSE 0
  END
 ) AS loyaltyPoint,

--SLOT 
   COALESCE(g.slot, d.slot, w.slot) AS slot,
--MONTH
   COALESCE(g.month, d.month, w.month) AS month,
--DAY
   COALESCE(g.day, d.day, w.day) AS date

FROM (
  SELECT user_id,
  SUM(Games_Played) AS gPlayed,
  MONTH(Datetime) AS month,
  DAY(Datetime) AS day,
  CASE 
    WHEN DATEPART(HOUR, Datetime) <12 THEN 'S1'
    ELSE 'S2'
  END as slot
  FROM gPlayed
  GROUP BY user_id,
  MONTH(Datetime),
  DAY(Datetime),
  CASE 
    WHEN DATEPART(HOUR, Datetime) <12 THEN 'S1'
    ELSE 'S2'
  END
)g

FULL OUTER JOIN
( 
  SELECT user_id,
  SUM(Amount) AS deposit,
  MONTH(Datetime) AS month,
  DAY(Datetime) AS day,
  CASE
     WHEN DATEPART(HOUR, Datetime) <12 THEN 'S1'
     ELSE 'S2'
  END AS slot
  FROM deposit
  GROUP BY user_id,
  MONTH(Datetime),
  DAY(Datetime),
  CASE
     WHEN DATEPART(HOUR, Datetime) <12 THEN 'S1'
     ELSE 'S2'
  END
)d

ON g.user_id = d.user_id
AND g.month = d.month
AND g.day = d.day
AND g.slot = d.slot

FULL OUTER JOIN

( 
  SELECT user_id,
  SUM(Amount) AS withdrawal,
  MONTH(Datetime) AS MONTH,
  DAY(Datetime) AS day,
  CASE
     WHEN DATEPART(HOUR, Datetime) <12 THEN 'S1'
     ELSE 'S2'
  END AS slot
  FROM withdrawal
  GROUP BY user_id,
  MONTH(Datetime),
  DAY(Datetime),
   CASE
     WHEN DATEPART(HOUR, Datetime) <12 THEN 'S1'
     ELSE 'S2'
  END
)w

ON COALESCE(g.user_id, d.user_id) = w.user_id
AND COALESCE(g.month, d.month) = w.month
AND COALESCE(g.day, d.day) = w.day
AND COALESCE(g.slot, d.slot) = w.slot


--------------------------------------------DATA VALIDATION TO CHECK NO MISSING AND CORRECT DATA ------------------------------------------------
SELECT * FROM ABCdata;

SELECT TOP 50 * FROM ABCdata;

SELECT * FROM ABCdata WHERE user_id = 1;

SELECT SUM(Games_Played) FROM gPlayed;
SELECT SUM(Amount) FROM deposit;
SELECT SUM(Amount) FROM withdrawal;

SELECT SUM(gPlayed), SUM(deposit), SUM(withdrawal) FROM ABCdata;

-- DATA INTEGRITY CHECK
SELECT DISTINCT slot FROM ABCdata;

-- CHECK FOR NEGATIVE VALUES
SELECT * FROM ABCdata WHERE deposGreaterThanWithdPoint <0;

--CHECK FOR NO DISPERANCIES
SELECT * , (gPlayedPoint+ depositPoint+withdrawalPoint+ deposGreaterThanwithdPoint) AS Check_point FROM ABCdata WHERE
ABS(loyaltyPoint -(gPlayedPoint+ depositPoint+withdrawalPoint+ deposGreaterThanwithdPoint) ) > 0.001;

SELECT * FROM ABCdata;

----------------------------------------------------------- PART A -----------------------------------------------------------------------------------
----------------------------------------------------- PLAYERWISE LOYALTY POINTS-----------------------------------------------------------------------
----------------------------------------------------------- QUESTION A 1 ----------------------------------------------------------------------------

--A.1.a 2nd OCTO slot 1
SELECT user_id, loyaltyPoint FROM ABCdata WHERE month = 10 AND date = 2 AND slot = 'S1';


--A.1.b 16th OCTO slot 2
SELECT user_id, loyaltyPoint FROM ABCdata WHERE month = 10 AND date = 16 AND slot = 'S2';


--A.1.a 18th OCTO slot 1
SELECT user_id, loyaltyPoint FROM ABCdata WHERE month = 10 AND date = 18 AND slot = 'S1';


--A.1.a 26th OCTO slot 2
SELECT user_id, loyaltyPoint FROM ABCdata WHERE month = 10 AND date = 26 AND slot = 'S2';

------------------------------------------------------------- QUESTION A 2 ---------------------------------------------------------------------------
----------------------------------------OVERALL LOYALTY POINTS EARNED AND RANKING PLAYERS BASED ON LOYALTY POINTS-------------------------------------

SELECT user_id , 
       SUM(loyaltyPoint) AS totalLoyaltyPoint, 
       SUM(gPlayed) AS totalGamesPlayed, 
       RANK() OVER (ORDER BY SUM(loyaltyPoint) DESC, SUM(gPlayed) DESC) AS playerRank 
       FROM ABCdata 
       WHERE month = 10 GROUP BY user_id;

----------------------------------------------------------------- QUESTION A 3 --------------------------------------------------------------------
------------------------------------------------------- AVERAGE DEPOSIT AMOUNT --------------------------------------------------------------------

SELECT AVG(deposit) AS avgDeposit FROM ABCdata;

------------------------------------------------------------------ QUESTION A 4 -------------------------------------------------------------------
--------------------------------------------------------- AVERAGE DEPOSIT PER USER IN A MONTH ----------------------------------------------------

SELECT AVG(totDeposit) AS avgDepositPerUser FROM 
( SELECT user_id, SUM(deposit) as totDeposit
  FROM ABCdata 
  WHERE month = 10 
  GROUP BY user_id
)t;

-------------------------------------------------------------------- QUESTION 5 -------------------------------------------------------------------
--------------------------------------------------------- AVG NUMBER OF GAMES PLAYER PER USER ------------------------------------------------------

SELECT AVG(totGamesPlayed) AS avgGamesPlayedPerUser
FROM( 
  SELECT user_id, SUM(gPlayed) AS totGamesPlayed
  FROM ABCdata
  GROUP BY user_id
)t;

----------------------------------------------------------LEADERBOARD WITH TOP 50 PERFORMERS --------------------------------------------------------

WITH leaderBoard AS(
  SELECT user_id,
  SUM(loyaltyPoint) AS totalLoyalty,
  SUM(gPlayed) AS totalGamesPlayed,
  SUM(deposit) AS totalDeposit,
  SUM(withdrawal) AS totalWithdrawal,
  RANK() OVER( ORDER BY SUM(loyaltyPoint) DESC, SUM(gPlayed) DESC) AS playerRank
  FROM ABCdata
  WHERE month = 10
  GROUP BY user_id
)
SELECT TOP 50 * FROM leaderBoard ORDER BY playerRank;

-------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------- QUESTION B ----------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------ HOW CASH OF 50000 SHOULD BE DISTRIBUTED AMONG TOP 50 PLAYERS ? -----------------------------------------------------



/* BONUS should be Distributed based on all values , formula should not be bias.

    SUGGESTED FORMULA FOR DISTIBUTING BONUS = (userLoyalty / Total loyalty of top 50 Users) * 50,000
                                               OR
    GIVING small amount of money to all 50 users and splitting remaining bonus to all users based on their loyalty points .
    ex. giving 100 or 500 rs to all 50 users then remaining money will be distributed based on loyalty formula.


*/

----------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------- QUESTION C ---------------------------------------------------------------------------
------------------------------------------------IS LOYALTY FORMULA IN ASSESMENT IS FAIR OR NOT ? ---------------------------------------------------------

/*  
     ANS : I think formula is unfair beacuse its giving more priority for money/ deposit so any rich user can dominate formula.
           Also formula is giving less priority for games being played which is CORE CONCEPT of gaming platform.
           Withdrawal doesn't need loyalty points as much.

     SUGGESTED IMPROVEMENTS - 

    1. As currently loyalty point is hightly biased to deposit and giving less priority to games played.
        ex. gamesPlayedPoint = 0.2 * (50 games) = 10 POINTS
            depositPoint = 0.01 * 1000 rs = 10 POINTS 
            SO BASICALLY RICH USERS CAN DOMINATES LOYALTY DEFINATIONS JUST BY DEPOSITING MORE MONEY AND PLAYING LESS OR NO GAMES.
    

    2. POINTS FOR PLAYING GAMES SHOULD BE MORE like instead 0.2 it shouls o.5 or MORE. 
       IT WILL ENGAGE USERS WHO ARE HAVING CORE INTEREST IN PLAYING GAMES . 
       THIS IS HOW THEY WII RETAIN.


    2. users can trick formula, if user deposit, then withdraws still points will be earned.
       SO WE CAN REDUCE POINTS FOR WITHDRAWAL.


    3.LIKE MOST FAMOUS PLATFORM DOES ex. leetcode, Naukri app, PROVIDE POINTS FOR DAILY LOGIN WHICH 
       LEADS TO CONSTISTENT AND LOYAL USERS


*/

-----------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- THANKS ------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------