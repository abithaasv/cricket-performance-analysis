-- Actual Work lol

select * from deliveries limit 10;
select * from match_details limit 10;
select * from playing_11 limit 10;
select * from players_info_with_keys limit 10;
select * from venue limit 10;

-- Top 10 batsmen per season + averages + strike rates

select season, striker, runs_in_season,runs_in_season/times_out_in_szn as batting_average,
runs_in_season*100/balls_faced_in_szn as strike_rate,
rnk_in_szn
from(
select season,striker,sum(runs_off_bat) as runs_in_season,
sum(case when wides is null and noballs is null then 1 else 0 end) as balls_faced_in_szn,
sum(case when player_dismissed = striker or player_dismissed = non_striker then 1 else 0 end) as times_out_in_szn,
rank() over (partition by season order by sum(runs_off_bat) desc) as rnk_in_szn
from deliveries
group by 1,2) a
where rnk_in_szn <=10
order by season, rnk_in_szn;

-- Top 10 bowlers per season + bowling averages + economy rates

select season, bowler, wickets_in_szn,deliveries_in_szn/wickets_in_szn as bowling_average,
(runs_szn+extras_szn)*6/deliveries_in_szn as economy_rate_szn,
rnk_in_szn
from(
select season,bowler,
sum(case when wicket_type not in ('','run out','retired hurt', 'retired out','obstructing the field')
then 1 else 0 end) as wickets_in_szn,
count(ball) as deliveries_in_szn,
sum(runs_off_bat) as runs_szn,
sum(extras) as extras_szn,
rank() over (partition by season order by sum(case when wicket_type not in 
('','run out','retired hurt', 'retired out','obstructing the field') then 1 else 0 end) desc) 
as rnk_in_szn
from deliveries
group by 1,2) a
where rnk_in_szn <=10
order by season, rnk_in_szn;

-- Top 5 batsmen per season based on combined metric

select *
from (
select a.season,a.striker,round(((runs_in_season/season_average)+(batting_average/season_batting_average)
+(strike_rate/season_strike_rate)),2) as batting_metric,balls_faced,
rank() over (partition by season order by ((runs_in_season/season_average)+(batting_average/season_batting_average)
+(strike_rate/season_strike_rate)) desc) as szn_rnk
from 
(select season,striker,sum(runs_off_bat) as runs_in_season,
sum(runs_off_bat)/sum(case when player_dismissed = striker or player_dismissed = non_striker then 1 else 0 end) as batting_average,
sum(runs_off_bat)*100/sum(case when wides is null and noballs is null then 1 else 0 end) as strike_rate,
sum(case when wides is null and noballs is null then 1 else 0 end) as balls_faced
from deliveries
group by 1,2) a
left join 
(select season,sum(runs_off_bat) as total_runs_in_season,
sum(runs_off_bat)/count(distinct striker) as season_average,
sum(runs_off_bat)/sum(case when player_dismissed = striker or player_dismissed = non_striker then 1 else 0 end) as season_batting_average,
sum(runs_off_bat)*100/sum(case when wides is null and noballs is null then 1 else 0 end) as season_strike_rate
from deliveries
group by 1) b
on a.season = b.season
where balls_faced>120
) c
where szn_rnk <=5;

-- Top 5 bowlers per season based on combined metric

select *
from (
select a.season,a.bowler,round(((wickets/total_avg_wickets)+(total_bowling_average/bowling_average)
+(total_economy_rate/economy_rate)),2) as bowling_metric,balls_bowled,
rank() over (partition by season order by ((wickets/total_avg_wickets)+(total_bowling_average/bowling_average)
+(total_economy_rate/economy_rate)) desc) as szn_rnk
from(
select season,bowler,
sum(case when wicket_type not in ('','run out','retired hurt', 'retired out','obstructing the field')
then 1 else 0 end) as wickets,
count(ball)/sum(case when wicket_type not in ('','run out','retired hurt', 'retired out','obstructing the field')
then 1 else 0 end) as bowling_average,
count(ball) as balls_bowled,
sum(runs_off_bat+extras)*6/count(ball) as economy_rate
from deliveries
group by 1,2) a
left join
(select season,
sum(case when wicket_type not in ('','run out','retired hurt', 'retired out','obstructing the field')
then 1 else 0 end)/count(distinct bowler) as total_avg_wickets,
count(ball)/sum(case when wicket_type not in ('','run out','retired hurt', 'retired out','obstructing the field')
then 1 else 0 end) as total_bowling_average,
sum(runs_off_bat+extras)*6/count(ball) as total_economy_rate
from deliveries
group by 1) b
on a.season = b.season
where balls_bowled>120) c
where szn_rnk <=5;

-- Toss Outcome vs Match Outcome by Venue

select city,toss_decision,num_matches,win_count_toss_winner/num_matches as win_percent_toss_winner
from(
select city,toss_decision,
sum(case when toss_winner = winner then 1 else 0 end) as win_count_toss_winner,
count(*) as num_matches
from match_details md
left join venue vn
on md.venueID = vn.id
group by 1,2) a
where num_matches > 20
order by 4 desc;

-- Typical playing 11 breakdown by position

select case when Playing_Position in ('Wicketkeeper','Wicketkeeper Batter') then 'Wicket Keeper'
when Playing_Position like '%Batter%' then 'Batsman'
when Playing_Position like '%Allrounder%' then 'All Rounder'
else 'Bowler' end as Playing_Position,
sum(ct) as players_in_position,count(distinct match_id) as num_matches,
sum(ct)/count(distinct match_id) as players_in_11
from(
select match_id,Playing_Position,count(*) as ct
from(
select p11.*,md.winner,pk.Playing_Position
from playing_11 p11
left join match_details md
on p11.Match_ID = md.match_id
left join players_info_with_keys pk
on p11.key_cricinfo = pk.key_cricinfo) a
where team = winner
group by 1,2) b
where Playing_Position is not null
group by 1;

-- Tight bowling correlation with match outcome

select season,sum(case when extras_team < other_extras then 1 else 0 end)/count(case when extras_team < other_extras then 1 else 0 end)
as matches_tighter_bowlers_won
from(
select season,match_id,bowling_team,winner,extras_team,
case when lag(extras_team) over (partition by match_id) is null 
then lead(extras_team) over (partition by match_id) else lag(extras_team) over (partition by match_id) 
end as other_extras
from(
select dl.season,dl.match_id,dl.bowling_team,md.winner,
sum(extras) as extras_team
from deliveries dl
left join match_details md
on dl.match_id = md.match_id
group by 1,2,3,4
order by 1,2,3) a
) b
where bowling_team = winner
group by 1;

-- Catches win Matches split by season

select season,sum(case when field_wick_team > field_wick_others then 1 else 0 end)/count(case when field_wick_team > field_wick_others then 1 else 0 end)
as matches_better_fielders_won
from(
select season,match_id,bowling_team,winner,field_wick_team,
case when lag(field_wick_team) over (partition by match_id) is null 
then lead(field_wick_team) over (partition by match_id) else lag(field_wick_team) over (partition by match_id) 
end as field_wick_others
from(
select dl.season,dl.match_id,dl.bowling_team,md.winner,
sum(case when wicket_type in ('caught','run out','caught and bowled','stumped') then 1 else 0 end) 
as field_wick_team
from deliveries dl
left join match_details md
on dl.match_id = md.match_id
group by 1,2,3,4
order by 1,2,3) a
) b
where bowling_team = winner
group by 1;

-- Capturing the Powerplay

select season,sum(case when runs_conceded < runs_conceded_others then 1 else 0 end)/count(case when runs_conceded < runs_conceded_others then 1 else 0 end)
as matches_big_batters_won,
sum(case when wickets_taken > wickets_taken_others then 1 else 0 end)/count(case when wickets_taken > wickets_taken_others then 1 else 0 end)
as matches_sharp_bowlers_won
from(
select season,match_id,bowling_team,winner,runs_conceded,wickets_taken,
case when lag(runs_conceded) over (partition by match_id) is null 
then lead(runs_conceded) over (partition by match_id) else lag(runs_conceded) over (partition by match_id) 
end as runs_conceded_others,
case when lag(wickets_taken) over (partition by match_id) is null 
then lead(wickets_taken) over (partition by match_id) else lag(wickets_taken) over (partition by match_id) 
end as wickets_taken_others
from(
select dl.season,dl.match_id,dl.bowling_team,md.winner,
sum(runs_off_bat+extras) as runs_conceded,
sum(case when wicket_type <> ''then 1 else 0 end) as wickets_taken
from deliveries dl
left join match_details md
on dl.match_id = md.match_id
where dl.ball <6.1
group by 1,2,3,4
order by 1,2,3
) a
) b
where bowling_team = winner
group by 1;
