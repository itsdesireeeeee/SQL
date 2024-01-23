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
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst LIKE '_% _%' --wildcard repeating then space and then same pattern
  ORDER BY namefirst, namelast
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(*)
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear ASC
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT *
  FROM q1iii
  WHERE avgheight > 70
;

-- Question 2i
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
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT H.playerid, H.namefirst, H.namelast, C.schoolID
  FROM q2i AS H LEFT OUTER JOIN collegeplaying AS C
  ON H.playerid = C.playerid
  ORDER BY H.playerid DESC, C.schoolID ASC
;

-- Question 3i
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

-- Question 3ii batting helper
-- contains the sum of the batting stats over a players lifetime
CREATE VIEW helperbat(playerid, s, d, t, hr, ab)
AS
    SELECT B.playerID,(sum(B.H) - sum(B.H2B) - sum(B.H3B) - sum(B.HR)),
    sum(B.H2B), sum(B.H3B), sum(B.HR), sum(B.AB)
    FROM people AS P INNER JOIN batting AS B
    ON P.playerID = B.playerID
    GROUP BY P.playerID
;

-- Question 3iii
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


-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid, MIN(salary), MAX(salary), AVG(salary)
  FROM salaries
  GROUP BY yearid
  ORDER BY yearid ASC
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
  SELECT binid, mini + (binid * width), mini + ((binid+1) * width), COUNT(salary)-- replace this line
  FROM binids LEFT OUTER JOIN histRange
  LEFT OUTER JOIN salaries
  WHERE yearid = 2016 AND ((salary >= mini + (binid * width) AND salary < mini + ((binid+1) * width)) OR (salary == maxi) AND binid == 9)
  GROUP BY binid
;


CREATE VIEW histRange(width, mini, maxi)
AS
    SELECT  ((MAX(salary) - MIN(salary))/10.0), MIN(salary), MAX(salary)
    FROM salaries
    WHERE yearid = 2016
;


-- Question 4iii
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

