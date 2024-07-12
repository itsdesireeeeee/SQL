-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS helperbat;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS histRange;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
-- What is the highest era (earned run average) recorded in baseball history?
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- SECTION 1: BASICS


-- Question 1i
-- In the people table, find the namefirst, namelast and birthyear for all players with weight greater than 300 pounds.
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE weight > 300
;

-- Question 1ii
-- Find the namefirst, namelast and birthyear of all players whose namefirst field contains a space.
-- Order the results by namefirst, breaking ties with namelast both in ascending order.
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst LIKE '_% _%' --wildcard repeating then space and then same pattern
  ORDER BY namefirst, namelast
;

-- Question 1iii
-- From the people table, group together players with the same birthyear, and 
-- report the birthyear, average height, and number of players for each birthyear.
-- Order the results by birthyear in ascending order.
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(*)
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear ASC
;

-- Question 1iv
-- Following the results of part iii, now only include groups with an average height > 70. 
-- Again order the results by birthyear in ascending order.
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT *
  FROM q1iii
  WHERE avgheight > 70
;


-- SeCtION 2: HALL OF FAME SCHOOLS


-- Question 2i
--  Find the namefirst, namelast, playerid and yearid of all people who were successfully inducted into the Hall of Fame
--  in descending order of yearid. Break ties on yearid by playerid (ascending).
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT P.namefirst, P.namelast, P.playerID, H.yearid
  FROM halloffame AS H
  INNER JOIN people AS P
  ON P.playerID = H.playerID
  WHERE inducted LIKE 'Y'
  ORDER BY H.yearid DESC, P.playerID ASC
;

-- Question 2ii
--  Find the people who were successfully inducted into the Hall of Fame and played in college at a school located in the state of California. 
--  For each person, return their namefirst, namelast, playerid, schoolid, and yearid in descending order of yearid.
--  Break ties on yearid by schoolid, playerid (ascending). For this question, yearid refers to the year of induction into the Hall of Fame.
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT H.namefirst, H.namelast, H.playerid, C.schoolID, H.yearid
  FROM q2i AS H INNER JOIN collegeplaying AS C
  ON H.playerid = C.playerid
  INNER JOIN schools AS S
  ON S.schoolID = C.schoolID
  WHERE S.schoolState LIKE 'CA'
  ORDER BY H.yearid DESC, C.schoolID, H.playerid ASC
;

-- Question 2iii
--  Find the playerid, namefirst, namelast and schoolid of all people who were successfully inducted into the Hall of Fame 
--  whether or not they played in college. Return people in descending order of playerid.
--  Break ties on playerid by schoolid (ascending). (Note: schoolid should be NULL if they did not play in college.)
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT H.playerid, H.namefirst, H.namelast, C.schoolID
  FROM q2i AS H LEFT OUTER JOIN collegeplaying AS C
  ON H.playerid = C.playerid
  ORDER BY H.playerid DESC, C.schoolID ASC
;


-- SECTION 3: SABERMETRICS


-- Question 3i
--  Find the playerid, namefirst, namelast, yearid and single-year slg (Slugging Percentage) of the players with the 10 best annual slg recorded over all time.
--  A player can appear multiple times in the output.
--  For statistical significance, only include players with more than 50 at-bats in the season. 
--  Order the results by slg descending, and break ties by yearid, playerid (ascending)
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT P.playerID, P.namefirst, P.namelast, B.yearID,
    (((B.H - B.H2B - b.H3B - B.HR) + (2 * B.H2B) + (3*B.H3B) + (4*B.HR))
          / CAST(B.AB AS REAL)) AS slg
  FROM people AS P INNER JOIN batting AS B
  ON P.playerID = B.playerID
  WHERE B.AB > 50
  ORDER BY slg DESC, B.yearID, P.playerID
  LIMIT 10
;

-- Question 3ii
--  Find the playerid, namefirst, namelast and lslg (Lifetime Slugging Percentage) for the players with the top 10 lslg. 
--  Lslg uses the same formula as Slugging Percentage (SLG), but it uses the number of singles, doubles, triples, home runs, 
--  and at bats each player has over their entire career, rather than just over a single season.
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
    SELECT P.playerID, P.namefirst, P.namelast,
    ((B.s + (2*B.d)+ (3*B.t) + (4*B.hr)) / CAST(B.ab AS REAL)) AS lslg
    FROM people AS P INNER JOIN helperbat AS B
    ON P.playerID = B.playerid
    WHERE B.ab > 50
    ORDER BY lslg DESC, P.playerID
    LIMIT 10
;

-- Helper Function for Question 3ii
-- The following helper function calculates the sum of the batting stats over a player's lifetime.
CREATE VIEW helperbat(playerid, s, d, t, hr, ab)
AS
    SELECT B.playerID,(sum(B.H) - sum(B.H2B) - sum(B.H3B) - sum(B.HR)),
    sum(B.H2B), sum(B.H3B), sum(B.HR), sum(B.AB)
    FROM people AS P INNER JOIN batting AS B
    ON P.playerID = B.playerID
    GROUP BY P.playerID
;

-- Question 3iii
--  Find the namefirst, namelast and Lifetime Slugging Percentage (lslg) 
--  of batters whose lifetime slugging percentage is higher than San Francisco's favorite Willie Mays.
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  SELECT P.namefirst, P.namelast, ((B.s + (2*B.d)+ (3*B.t) + (4*B.hr))
   / CAST(B.ab AS REAL)) AS lslg
  FROM people AS P INNER JOIN helperbat AS B
  ON P.playerID = B.playerID
  WHERE B.ab > 50
  AND lslg >
    (SELECT ((h.s + (2*h.d)+ (3*h.t) + (4*h.hr))/ CAST(h.ab AS REAL))
     FROM people AS x INNER JOIN helperbat AS h
     ON x.playerID = h.playerID
     WHERE x.playerID LIKE 'mayswi01'
    )
;


-- SECTION 4: SALARIES


--  Question 4i
--  Find the yearid, min, max and average of all player salaries for each year recorded, ordered by yearid in ascending order.
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid, MIN(salary), MAX(salary), AVG(salary)
  FROM salaries
  GROUP BY yearid
  ORDER BY yearid ASC
;

-- Question 4ii
--  For salaries in 2016, compute a histogram. Divide the salary range into 10 equal bins from min to max, 
--  with binids 0 through 9, and count the salaries in each bin. 
--  Return the binid, low and high boundaries for each bin, as well as the number of salaries in each bin, 
--  with results sorted from smallest bin to largest. Note: The high value for bin 9 may be inclusive
CREATE VIEW q4ii(binid, low, high, count)
AS
  SELECT binid, mini + (binid * width), mini + ((binid+1) * width), COUNT(salary)-- replace this line
  FROM binids LEFT OUTER JOIN histRange
  LEFT OUTER JOIN salaries
  WHERE yearid = 2016 AND ((salary >= mini + (binid * width) AND salary < mini + ((binid+1) * width)) OR (salary == maxi) AND binid == 9)
  GROUP BY binid
;

--  Helper function for question 4ii
--  Computes the minimum and maximum salaries in 2016 as well as the width of each bin of the histogram.
CREATE VIEW histRange(width, mini, maxi)
AS
    SELECT  ((MAX(salary) - MIN(salary))/10.0), MIN(salary), MAX(salary)
    FROM salaries
    WHERE yearid = 2016
;


-- Question 4iii
--  For each year with recorded salaries after the first, return the yearid, mindiff, maxdiff, and avgdiff with respect to the previous year. 
--  Order the output by yearid in ascending order. (You should omit the very first year of recorded salaries from the result.)
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  SELECT yearid, (min(s.salary) - (SELECT min(salary) FROM salaries as ss WHERE ss.yearid LIKE (s.yearid - 1) GROUP BY ss.yearid)),
        (max(s.salary) - (SELECT max(salary) FROM salaries as ss WHERE ss.yearid LIKE (s.yearid - 1) GROUP BY ss.yearid)),
        (avg(s.salary) - (SELECT avg(salary) FROM salaries as ss WHERE ss.yearid LIKE (s.yearid - 1) GROUP BY ss.yearid))
  FROM salaries AS s
  WHERE s.yearid NOT LIKE 1985
  GROUP BY s.yearid
  ORDER BY s.yearid ASC
;

-- Question 4iv
--  In 2001, the max salary went up by over $6 million. Write a query to find the players that had the max salary in 2000 and 2001. 
--  Return the playerid, namefirst, namelast, salary and yearid for those two years.
--  If multiple players tied for the max salary in a year, return all of them.
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
    SELECT p.playerID, p.namefirst, p.namelast, s.salary, s.yearID
    FROM people AS p
    INNER JOIN salaries AS s
    ON p.playerid = s.playerid
    WHERE (s.salary = (SELECT MAX(salary) FROM salaries WHERE salaries.yearid = 2000)
        AND s.yearid = 2000)
    OR (s.salary = (SELECT MAX(salary) FROM salaries WHERE salaries.yearid = 2001)
        AND s.yearid = 2001)
;


-- Question 4v
--  Each team has at least 1 All Star and may have multiple. 
--  For each team in the year 2016, give the teamid and diffAvg 
--  (the difference between the team's highest paid all-star's salary and the team's lowest paid all-star's salary).
CREATE VIEW q4v(team, diffAvg)
AS
  SELECT A.teamid, max(S.salary) - min(S.salary)
    FROM allstarfull AS A
    INNER JOIN salaries AS S
    ON S.playerid = A.playerid
    AND S.yearid = A.yearid
    WHERE A.yearid = 2016
    GROUP BY A.teamid
;

