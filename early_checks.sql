--EARLY CHECKS--
--Number of users going through each variation
select event_time :: date, EXP_VARIANT, count(distinct client_id)
from "DB_PROD"."DATAQUALITY"."Q_PBX_EXPERIMENT"
where exp_name = 'PBX-shop-ALL-heroImage-dec21'
and event_time > '2021-12-15 10:00:00.000'
group by 1,2
order by 1;

--Total number of users per variation--
select EXP_VARIANT, count(distinct client_id)
from "DB_PROD"."DATAQUALITY"."Q_PBX_EXPERIMENT"
where exp_name = 'PBX-shop-ALL-heroImage-dec21'
and event_time > '2021-12-01 10:45:00.000'
group by 1
order by 1;


--Number of variations per user
select CLIENT_ID, count(distinct EXP_VARIANT)
from "DB_PROD"."DATAQUALITY"."Q_PBX_EXPERIMENT"
where exp_name = 'PBX-editor-ALL-Layouts-nov05'
and event_time > '2021-12-01 10:45:00.000'
group by 1
order by 2 desc;

--check columns--
select * from DB_PROD.DATAQUALITY.Q_PBX_EXPERIMENT
where exp_name = 'PBX-editor-ALL-Layouts-nov05'
limit 10;

--Number of users per locale
select LOCALE, count(distinct client_id)
from "DB_PROD"."DATAQUALITY"."Q_PBX_EXPERIMENT"
where exp_name = 'PBX-editor-ALL-Layouts-nov05'
and event_time > '2021-12-01 10:45:00.000'
group by 1;

--Number of users per device
select
       case when b.device_type is NULL then 'n/a' else b.device_type end as device_type, count(distinct client_id)
from "DB_PROD"."DATAQUALITY"."Q_PBX_EXPERIMENT" a
left join "DB_PROD"."DATAQUALITY"."Q_USER_AGENTS" b
on a.user_agent = b.user_agent
where exp_name = 'PBX-editor-ALL-Layouts-nov05'
and event_time > '2021-12-01 10:45:00.000'
group by 1;