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

drop table if exists Test_Entrance;
create table Test_Entrance as
select a.*
from (
        select  RAW:data:analytics.clientId as client_id_1
                ,RAW:data:event.expVariant as variation
                ,RAW:data:event.expData.interactionType as interaction_type
                ,RAW:data:analytics.userAgent as user_agent
                ,min(RAW:eventTime) as First_Entrance
        from "DB_PROD"."RAW"."COM_PHOTOBOX_EXPERIMENT" cpe
        where RAW:data:event.expName = 'PBX-shop-PDP-video-nov21_v2'
        and RAW:eventTime between '2022-02-01 09:30:00.000' and '2022-02-15 09:30:00.000' --2 weeks worth of allocations
        group by 1,2,3,4
      ) a
;

SELECT  VARIATION
        ,COUNT(DISTINCT CLIENT_ID_1) AS USERS
FROM TEST_ENTRANCE
GROUP BY 1
;


drop table if exists exp_interaction;
create table exp_interaction as
select a.*
from (
        select  RAW:data:analytics.clientId as client_id_1
                ,RAW:data:event.interactionName as interaction_name
                ,min(RAW:eventTime) as First_Entrance
        from "DB_PROD"."RAW"."COM_PHOTOBOX_SHOP_INTERACTION"
        where RAW:data:event.interactionName = 'video_click'
        or RAW:data:event.interactionName = 'video_end'
        and RAW:eventTime between '2022-02-01 09:30:00.000' and '2022-02-15 09:30:00.000' --2 weeks worth of allocations
        group by 1,2
      ) a
;

SELECT  interaction_name
        ,case when QUA.device_type is NULL then 'n/a'
           else QUA.device_type
        end as device_type
        ,count(distinct EI.client_id_1) AS USERS
FROM exp_interaction EI
LEFT JOIN "DB_PROD"."DATAQUALITY"."Q_PBX_EXPERIMENT" QPE ON QPE.CLIENT_ID = EI.CLIENT_ID_1
LEFT JOIN "DB_PROD"."DATAQUALITY"."Q_USER_AGENTS" QUA ON QPE.USER_AGENT = QUA.USER_AGENT
group by 1,2
order by 1,3
;

DROP TABLE IF EXISTS PRODUCTS_PDP;
CREATE TABLE PRODUCTS_PDP AS
SELECT
        CASE
            WHEN URL_PATHNAME IN ('/shop/photo-books/little-moments-photo-book') THEN 'LITTLE MOMENTS PHOTOBOOK'
            WHEN URL_PATHNAME IN ('/shop/photo-books/personalised-cover-photobook') THEN 'PERSONALISED COVER PHOTOBOOK'
            WHEN URL_PATHNAME IN ('/shop/photo-books/lay-flat-silver-halide-photo-book-square') THEN 'LAY FLAT SILVER HALIDE PHOTOBOOK SQUARE'
            WHEN URL_PATHNAME IN ('/shop/photo-books/year-book') THEN 'YEAR BOOK'
            WHEN URL_PATHNAME IN ('/shop/photo-books/personalised-cover-photobook') THEN 'PERSONALISED COVER PHOTOBOOK'
            WHEN URL_PATHNAME IN ('/shop/photo-books/classic-cover-photobook') THEN 'CLASSIC COVER PHOTOBOOK'
            ELSE 'OTHER PRODUCTS'
        END AS PRODUCT
        ,COUNT(DISTINCT FUI.CLIENT_ID) AS USERS
--        ,variation AS VARIATION
FROM "DB_PROD"."WAREHOUSE"."F_USER_INTERACTION" FUI
LEFT JOIN TEST_ENTRANCE TE ON FUI.CLIENT_ID = TE.client_id_1
WHERE EVENT_DATETIME_UTC BETWEEN '2022-02-01 09:30:00.000' AND '2022-02-15 09:30:00.000'
--AND VARIATION IS NOT NULL
GROUP BY 1
ORDER BY 1
;


--Join Orders table to users in the test
drop table if exists Orders;
create table Orders as
select *
from Test_Entrance a
left join total_orders b
    on a.client_id_1=b.client_id
    and b.order_paid_timestamp>=a.first_entrance
    and b.order_paid_timestamp between '2022-02-01 09:30:00.000' and '2022-02-15 09:30:00.000';
-- for a non-editor experiment

SELECT COUNT(DISTINCT customer_order_ref) AS ORDERS, variation as VARIATION
FROM ORDERS
GROUP BY 2
;


drop table if exists entrance_product;
create table entrance_product as
select         distinct client_id_1,s1
from            test_entrance t
inner join      (select * from "DB_PROD"."WAREHOUSE"."F_USER_INTERACTION" a
                 --inner join "DB_PROD"."WAREHOUSE"."DIM_VISITOR" b on a.VISITOR_ID = b.VISITOR_ID
                 inner join "DB_PROD"."WAREHOUSE"."DIM_INTERACTION" c on a.DIM_INTERACTION_SK = c.INTERACTION_PK) a
                    --on a.event_datetime_utc = t.First_Entrance
                    on t.client_id_1 = a.visitor_id
left join       "DB_ANALYTICS_TEAM"."CSORSBY"."RC_VARIANTS" variants --This is a temporary lookup that Chris S has created to link back the rollercoaster variant_id to a babel product_id
                    on a.variant_id = variants.rc_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" products -- Joining onto our variant lookup to get meaningful names for the variant_IDs
                    on variants.BABEL_PRODUCT_ID = products.BASKET_PRODUCT_ID
order by    client_id_1;

select DISTINCT S1
from entrance_product
;
--group by 2


--get conversion metrics
select
       Variation
       ,count(distinct client_id_1) as UserCount
       ,sum(Conversion) as Conversions
       ,sum(Conversion)/count(distinct client_id_1) AS Conversion_rate
from (
            select
                left(variation,2) as Variation
                ,o.client_id_1
                ,case when max(order_paid_timestamp) is not null then 1 else 0 end as Conversion
            from orders o
            inner join entrance_product p on o.client_id_1 = p.client_id_1
            --where s1 = 'Books'
            group by 1,2
      ) as o
Group by 1
order by 1,2;



WITH ORDER_VIDEO AS (
                select
                o.client_id_1 AS CLIENT_ID
                ,left(o.variation,2) as Variation
                ,case when max(order_paid_timestamp) is not null then 1 else 0 end as Conversion
            from orders o
            inner join TEST_ENTRANCE te on o.client_id_1 = te.client_id_1
            group by 1,2
)
SELECT
        interaction_name
        ,COUNT(DISTINCT EI.CLIENT_ID_1) AS USERS
        ,SUM(O.CONVERSION) AS CONVERSIONS
        ,SUM(O.CONVERSION)/COUNT(DISTINCT O.CLIENT_ID) AS CVR
        ,S1 AS S1
FROM ORDER_VIDEO O
LEFT JOIN ENTRANCE_PRODUCT EP ON O.CLIENT_ID = EP.CLIENT_ID_1
LEFT JOIN "DB_PROD"."WAREHOUSE"."DIM_VISITOR" V ON O.CLIENT_ID = V.VISITOR_ID
LEFT JOIN exp_interaction EI ON V.VISITOR_ID = EI.CLIENT_ID_1
WHERE interaction_name IS NOT NULL
GROUP BY 1,5
ORDER BY 4,5
;



