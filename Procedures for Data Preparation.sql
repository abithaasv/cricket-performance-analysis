DELIMITER //
CREATE PROCEDURE clean_deliveries()
BEGIN
create table deliveries
as
select ï»¿index as del_index,match_id,season,innings,ball,
batting_team,bowling_team,striker,non_striker,bowler,runs_off_bat,extras,
case when wides = 99 then Null else wides end as wides,
case when noballs = 99 then Null else noballs end as noballs,
case when byes = 99 then Null else byes end as byes,
case when legbyes = 99 then Null else legbyes end as legbyes,
case when penalty = 99 then Null else penalty end as penalty,
wicket_type,player_dismissed,striker_id,non_striker_id,bowler_id
from deliveries_upload;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE clean_match_details()
BEGIN
create table match_details
as
select team1,team2,gender,season,date as match_date,
case when match_number = 999 then Null else match_number end as match_number,
toss_winner,toss_decision,player_of_match,winner,
case when win_by = 999 then Null else win_by end as win_by, 
match_id,winner_type,outcome,eliminator,method,venueID
from match_details_upload;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE clean_player_info_with_keys()
BEGIN
create table players_info_with_keys
as
select ï»¿Name as Player_Name, Full_Name,
Batting_Style, 
case when Bowling_Style = '' then null else Bowling_Style end as Bowling_Style,
case when Playing_Position = "" then Null else Playing_Position end as Playing_Position,
identifier, key_cricinfo,
case when Bowling_Type = "" then Null else Bowling_Type end as Bowling_Type,
case when Bowling_Arm = "" then Null else Bowling_Arm end as Bowling_Arm
from players_info_with_keys_upload;
END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE clean_playing_11()
BEGIN
create table playing_11
as
select ï»¿Index as p11_index, Match_ID, Team, Players,
case when identifier = 'zzzzz99999' then Null else identifier end as identifier,
case when key_cricinfo = 999999999 then Null else key_cricinfo end as key_cricinfo 
from playing_11_upload;
END //
DELIMITER ;

