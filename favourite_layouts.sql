--global cvr
select          count(distinct CLIENT_ID)
from            "DB_PROD"."WAREHOUSE"."F_USER_INTERACTION" a
inner join      "DB_PROD"."WAREHOUSE"."DIM_BRAND" b
                    on a.dim_brand_sk = b.brand_pk
inner join      "DB_PROD"."WAREHOUSE"."DIM_LOCALE" c
                    on a.DIM_LOCALE_SK = c.LOCALE_PK
where           brand in ('photobox','hofmann')
                and locale_code != 'pt_PT'
                and EVENT_DATETIME_UTC between '2021-12-01 10:45:00.000' and '2021-12-08 10:45:00.000';

select          count(distinct CUSTOMER_ORDER_REF)
from            "DB_PROD"."WAREHOUSE"."F_ORDER" a
inner join      "DB_PROD"."WAREHOUSE"."DIM_BRAND" b
                    on a.brand_sk = b.brand_pk
inner join      "DB_PROD"."WAREHOUSE"."DIM_LOCALE" c
                    on a.LOCALE_SK = c.LOCALE_PK
where           ORDER_PAID_TIMESTAMP  between '2021-12-01 10:45:00.000' and '2021-12-08 10:45:00.000'
                and brand in ('photobox','hofmann')
                and c.locale_code != 'pt_PT';

-----           site cvr: pbx uk, mobile and desktop web only
select          count(distinct CLIENT_ID)
from            "DB_PROD"."WAREHOUSE"."F_USER_INTERACTION" a
inner join      "DB_PROD"."WAREHOUSE"."DIM_BRAND" b
                    on a.dim_brand_sk = b.brand_pk
inner join      "DB_PROD"."WAREHOUSE"."DIM_LOCALE" c
                    on a.DIM_LOCALE_SK = c.LOCALE_PK
inner join      "DB_PROD"."WAREHOUSE"."DIM_DEVICE" d
                    on a.DIM_DEVICE_SK = d.DEVICE_PK
where           b.brand in ('photobox','hofmann')
                --and c.locale_Code = 'fr_FR'
                and c.locale_code != 'pt_PT'
                and device_type in ('smartphone')
                and EVENT_DATETIME_UTC between '2021-12-01 10:45:00.000' and '2021-12-08 10:45:00.000';

select          count(distinct CUSTOMER_ORDER_REF)
from            "DB_PROD"."WAREHOUSE"."F_ORDER" a
inner join      "DB_PROD"."WAREHOUSE"."DIM_BRAND" b
                    on a.brand_sk = b.brand_pk
inner join      "DB_PROD"."WAREHOUSE"."DIM_LOCALE" c
                    on a.LOCALE_SK = c.LOCALE_PK
inner join      "DB_PROD"."WAREHOUSE"."DIM_DEVICE" d
                    on a.DEVICE_SK = d.DEVICE_PK
where           ORDER_PAID_TIMESTAMP  between '2021-12-01 10:45:00.000' and '2021-12-08 10:45:00.000'
                and b.brand in ('photobox','hofmann')
                --and locale_Code = 'fr_FR'
                and c.locale_code != 'pt_PT'
                and device_type in ('desktop');

--% users using feature
drop table if exists Test_Entrance;
create temp table Test_Entrance as
select a.*
from (
        select RAW:data:analytics.clientId as client_id_1
               ,RAW:data:event.expVariant as variation
               ,min(RAW:eventTime) as event_time
        from "DB_PROD"."RAW"."COM_PHOTOBOX_EXPERIMENT"
        where RAW:data:event.expName = 'PBX-editor-ALL-Layouts-nov05'
        and RAW:eventTime between '2021-12-01 10:45:00.000' and '2021-12-08 10:45:00.000' --2 weeks worth of allocations
        group by 1,2
      ) a
;


------- How many users applied a layout on which page
select          variation
                ,count(distinct a.CLIENT_ID_1) as total_variant_users
                ,count(distinct (case when name = 'EDITOR_SAVE_LAYOUT' and component_type ilike '%FRONT-COVER%' then a.CLIENT_ID_1 end)) as save_layout_front_page
                ,count(distinct (case when name = 'EDITOR_SAVE_LAYOUT' and component_type ilike '%PAGE%' then a.CLIENT_ID_1 end)) as save_layout_page
from            Test_Entrance a
left join
(select         RAW:data:analytics:clientId as cid,
                RAW:data:event:name as name,
                RAW:data:event:componentType component_type,
                min(RAW:eventTime) first_event_time
 from           "DB_PROD"."RAW"."COM_PHOTOBOX_EDITOR_ECREATION" a
 where          RAW:eventTime between '2021-06-03T17:55:00Z' and '2021-07-02T17:55:00Z'
group by        1,2,3) b
                on CLIENT_ID_1 = b.cid
group by        1;


-- AoV

-- Sessions
select           variation
                ,a.client_id_1 as user
                ,count(distinct b.CREATION_SESSION_ID) as sessions
                ,b.LOCALE
from            Test_Entrance a
left join
(select         b.visitor_id,
                name,
                locale,
                summary,
                EVENT_DETAILS,
                c.CREATION_SESSION_ID,
                min(a.event_time) first_event_time
 from           "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT" a
 inner join     "DB_PROD"."WAREHOUSE"."DIM_VISITOR" b
                    on a.VISITOR_SK = b.VISITOR_PK
 inner join     "DB_PROD"."WAREHOUSE"."DIM_CREATION_SESSION" c
                    on a.CREATION_SESSION_SK = c.CREATION_SESSION_PK
 where          a.event_time between '2021-12-01 10:45:00.000' and '2021-12-08 10:45:00.000'
                --and name in ('TOGGLE_FOCUS_ON_EDITABLE_ELEMENT','EDITOR_SCALE_IMAGE','EDITOR_TOGGLE_ROTATE_APERTURE','EDITOR_SET_IMAGE_OPACITY','EDITOR_TOGGLE_MASK','EDITOR_SWAP_IMAGE_START')
group by        1,2,3,4,5,6) b
                on a.CLIENT_ID_1 = b.visitor_id
group by        1,2,4
order by        1
;


-- Layout usage
select          variation
                ,CLIENT_ID_1 as users
                ,count(b.NAME) as layout_usage
from            Test_Entrance a
join
(select NAME
        ,VISITOR_ID
    from    "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT" a
    inner join     "DB_PROD"."WAREHOUSE"."DIM_VISITOR" b
                    on a.VISITOR_SK = b.VISITOR_PK
    where a.NAME in ('APPLY_LAYOUT_TO_PAGE')
) b
    on client_id_1 = b.VISITOR_ID
group by        1,2
;

select top 5 *
from "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT"
where name in ('APPLY_LAYOUT_TO_PAGE')
;



-- Payments

drop table if exists payments_command_old;
create table payments_command_old as
SELECT
    RAW:eventID AS eventID,
    RAW:eventTime AS eventTime,
    RAW:data:event:eventType AS eventType,
    RAW:extensions.brand AS extensions_brand,
    RAW:source AS source,
    RAW:data:event.clientId AS client_Id,
    RAW:data:event.basketId AS BasketID,
    RAW:data:event.locale AS locale,
    RAW:data:event.memberId AS member_ID,
    RAW:data:event.orderReference AS order_reference
FROM "DB_PROD"."RAW"."COM_PHOTOBOX_CHECKOUT_PAYMENTSCOMMAND"
;
drop table if exists payments_command_new;
create table payments_command_new as
SELECT distinct
    RAW:id AS eventID,
    RAW:time AS eventTime,
    RAW:type AS eventType,
    RAW:brand AS extensions_brand,
    RAW:source AS source,
    RAW:data:clientId AS client_Id,
    RAW:data:basketId AS BasketID,
    RAW:locale AS locale,
    RAW:data:memberId AS member_ID,
    RAW:data:orderReference AS order_reference
FROM "DB_PROD"."RAW"."COM_PHOTOBOX_PAYMENTS_PAYMENTSCOMMAND"
;
drop table if exists total_orders;
create temp table total_orders as
SELECT DISTINCT
    o.member_id
    ,pco.client_id
    ,o.order_paid_timestamp
    ,o.customer_order_ref
FROM "DB_PROD"."WAREHOUSE"."F_ORDER" AS o
INNER JOIN payments_command_old AS pco
      ON o.member_id = pco.member_id
      AND o.order_paid_timestamp <'2020-11-09'
WHERE o.order_paid_timestamp >= '2020-01-01'
UNION ALL
SELECT DISTINCT
    o.member_id
    ,pcn.client_id
    ,o.order_paid_timestamp
    ,o.customer_order_ref
FROM "DB_PROD"."WAREHOUSE"."F_ORDER" AS o
INNER JOIN payments_command_new AS pcn
      ON o.member_id = pcn.member_id
      AND o.order_paid_timestamp >='2020-11-09';


--Join Orders table to users in the test
drop table if exists Orders;
create temp table Orders as
select *
from Test_Entrance a
--Test_Entrance_adj a
left join total_orders b
    on a.client_id_1=b.client_id
    and b.order_paid_timestamp>=a.first_entrance
    --and datediff(day,a.first_entrance, b.order_paid_timestamp) BETWEEN 0 and 13 --This is a 2 week period for editor, but for non editor change this to experiment time period
    and b.order_paid_timestamp between '2021-11-01 11:15:00.000' and '2021-11-14 11:15:00.000' -- for a non-editor experiment

--get conversion metrics
select variation
       ,count(distinct client_id_1) as UserCount
       ,sum(Conversion) as Conversions
       ,sum(Conversion)/count(distinct client_id_1) AS Conversion_rate
from (
            select
                left(variation,2) as Variation
                ,client_id_1
                ,case when max(order_paid_timestamp) is not null then 1 else 0 end as Conversion
            from orders
            group by 1,2
      ) as o
Group by 1
order by 1;


-------------------------------------------------------------

--

