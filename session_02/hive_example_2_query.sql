
--###############################################################################################################
--#
--#   Create HDFS Directory Structure and Load Data
--#   Data is from Kaggle: https://www.kaggle.com/c/march-machine-learning-mania-2016/data
--#
--###############################################################################################################


--#su hdfs
--#hadoop fs -mkdir /demo
--#hadoop fs -mkdir /demo/ncaa
--#hadoop fs -mkdir /demo/ncaa/SeasonResults
--#hadoop fs -mkdir /demo/ncaa/Teams
--#hadoop fs -put /data/SeasonResults.csv /demo/ncaa/SeasonResults/.
--#hadoop fs -put /data/Teams.csv /demo/ncaa/Teams/.


--###############################################################################################################
--#
--#   Connect to Hive via JDBC (Beeline)
--#   /usr/lib/hive/bin/beeline -u jdbc:hive2://localhost:10000/default
--#
--###############################################################################################################


SHOW TABLES;


--###############################################################################################################
--#
--#   Hive - Load Data
--#
--###############################################################################################################

CREATE EXTERNAL TABLE IF NOT EXISTS mm_season_temp
    (id string, season string, day string, wteam string, wscore int, lteam string, lscore int, wloc string, ot string)
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ","
    LINES TERMINATED BY "\n"
    STORED AS TEXTFILE
    LOCATION "/demo/ncaa/SeasonResults"
    TBLPROPERTIES ("skip.header.line.count"="1");

CREATE TABLE IF NOT EXISTS mm_season
    (id string, season string, day string, wteam string, wscore int, lteam string, lscore int, wloc string, ot string)
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ","
    LINES TERMINATED BY "\n"
    STORED AS ORC;

INSERT OVERWRITE TABLE mm_season SELECT * FROM mm_season_temp;

SELECT * FROM mm_season LIMIT 10;

SELECT COUNT(*) FROM mm_season;

DESCRIBE mm_season;

--###############################################################################################################

CREATE EXTERNAL TABLE IF NOT EXISTS mm_teams_temp
    (team_id string, team_name string)
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ","
    LINES TERMINATED BY "\n"
    STORED AS TEXTFILE
    LOCATION "/demo/ncaa/Teams"
    TBLPROPERTIES ("skip.header.line.count"="1");

CREATE TABLE IF NOT EXISTS mm_teams
    (team_id string, team_name string)
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ","
    LINES TERMINATED BY "\n"
    STORED AS ORC;

INSERT OVERWRITE TABLE mm_teams SELECT * FROM mm_teams_temp;

SELECT * FROM mm_teams LIMIT 10;

SELECT COUNT(*) FROM mm_teams;

DESCRIBE mm_teams;


--###############################################################################################################
--#
--#   Hive - Join (as materialized table)
--#
--###############################################################################################################

CREATE TABLE IF NOT EXISTS mm_join1 AS
    SELECT mm_season.*, 
        teams2a.team_name AS WTEAM_NAME, 
        teams2b.team_name AS LTEAM_NAME
    FROM mm_season
    LEFT JOIN mm_teams teams2a ON (mm_season.wteam = teams2a.team_id)
    LEFT JOIN mm_teams teams2b ON (mm_season.lteam = teams2b.team_id);

SELECT * FROM mm_join1 LIMIT 10;
    
DESC mm_join1;

SELECT COUNT(*) FROM mm_season;
SELECT COUNT(*) FROM mm_teams;
SELECT COUNT(*) FROM mm_join1;

--SHOW CREATE TABLE mm_join1;


--###############################################################################################################
--#
--#   Hive - Join (as view)
--#
--###############################################################################################################

CREATE VIEW IF NOT EXISTS mm_join1_view AS
    SELECT mm_season.*, 
        teams2a.team_name AS WTEAM_NAME, 
        teams2b.team_name AS LTEAM_NAME
    FROM mm_season
    LEFT JOIN mm_teams teams2a ON (mm_season.wteam = teams2a.team_id)
    LEFT JOIN mm_teams teams2b ON (mm_season.lteam = teams2b.team_id);


--###############################################################################################################
--#
--#   Hive - Calculations
--#
--###############################################################################################################


-- Calculate the Top 15 Teams with the most Wins
SELECT WTEAM_NAME, COUNT(*) AS WINS 
    FROM mm_join1 
    GROUP BY WTEAM_NAME 
    ORDER BY WINS DESC 
    LIMIT 15;


-- Calculate the Top 15 Teams with the most Losses
SELECT LTEAM_NAME, COUNT(*) AS LOSSES 
    FROM mm_join1 
    GROUP BY LTEAM_NAME 
    ORDER BY LOSSES DESC 
    LIMIT 15;


-- Calculate the Top 15 Matchups with the biggest score difference
SELECT SEASON, WTEAM_NAME, WSCORE, LTEAM_NAME, LSCORE, WLOC, (WSCORE-LSCORE) AS SCORE_DIFF, CONCAT(WTEAM_NAME, " OVER ", LTEAM_NAME) as DESC
    FROM mm_join1
    ORDER BY SCORE_DIFF DESC
    LIMIT 15;



--###############################################################################################################
--#
--#  Performance Testing 
--#
--###############################################################################################################

CREATE EXTERNAL TABLE IF NOT EXISTS testdata
    (id string, ssn string, amount int, password string, cc string, dob string, datestr string, cei string, name string, email string)
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ","
    LINES TERMINATED BY "\n"
    STORED AS TEXTFILE
    LOCATION "/demo/ncaa/testdata"
    TBLPROPERTIES ("skip.header.line.count"="1");

CREATE TABLE IF NOT EXISTS testdata_orc
    (id string, ssn string, amount int, password string, cc string, dob string, datestr string, cei string, name string, email string)
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ","
    LINES TERMINATED BY "\n"
    STORED AS ORC;

INSERT OVERWRITE TABLE testdata_orc SELECT * FROM testdata;

SELECT COUNT(*) FROM testdata;
SELECT COUNT(*) FROM testdata_orc;

ANALYZE TABLE testdata COMPUTE STATISTICS;
ANALYZE TABLE testdata COMPUTE STATISTICS FOR COLUMNS;

SELECT COUNT(*) FROM testdata;


--#ZEND
