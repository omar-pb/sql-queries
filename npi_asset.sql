--TEMP TABLES--

--ASSETS TABLE--
drop table if exists ASSETS;
create temp table ASSETS as
select   distinct dc.CREATION_ID as creation_id
        ,dc.CREATION_PK as creation_pk
        ,ce.NAME as decoration
        ,ce.ASSET_ID as asset_id
        ,ce.ASSET_NAME as asset_name
        ,ce.EVENT_DETAILS:fontFamily as font
        ,dc.NUM_ORDERS as num_orders
        ,db.BRAND as brand
        ,ce.LOCALE as locale
from    "DB_PROD"."WAREHOUSE"."DIM_CREATION" dc
left join "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT" ce on dc.CREATION_PK = ce.CREATION_SK
left join "DB_PROD"."WAREHOUSE"."DIM_BRAND" db on ce.BRAND_SK = db.BRAND
where ce.NAME in ('EDITOR_ADD_DECORATION', 'EDITOR_SET_PAGE_BACKGROUND_COLOUR', 'APPLY_BACKGROUND_TO_PAGE', 'EDITOR_TEXT_STYLE', 'EDITOR_TOGGLE_MASK')
and   ce.EVENT_TIME :: date between '2021-08-01' and '2021-12-07'
;


--DYO TABLE--
drop table if exists MERCH_DETAILS;
create temp table MERCH_DETAILS as
select  ree.RAW:data:event.creationId as creation_id
        ,ree.RAW:data:extension.brand as brand
from    DB_PROD.RAW.COM_PHOTOBOX_EDITOR_ECREATION ree
where   RAW:data:event.merchThemeId :: string is null
and     EVENT_TIME :: date between '2021-08-01' and '2021-12-07'
;

--=========================================================================
--OPERATIONS--

select  a.decoration
        ,a.asset_id
        ,a.asset_name
        ,md.font_family
        ,a.num_orders
        ,md.brand
        ,a.locale
from ASSETS as a
left join MERCH_DETAILS MD on a.creation_id = MD.creation_id
where font_family != null
;










--=========================================================================
select   distinct dc.CREATION_ID as creation_id
        ,dc.CREATION_PK as creation_pk
        ,ce.NAME as decoration
        ,ce.ASSET_ID as asset_id
        ,dc.NUM_ORDERS as num_orders
        ,db.BRAND as brand
        ,ce.LOCALE as locale
from    "DB_PROD"."WAREHOUSE"."DIM_CREATION" dc
left join "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT" ce on dc.CREATION_PK = ce.CREATION_SK
left join "DB_PROD"."WAREHOUSE"."DIM_BRAND" db on ce.BRAND_SK = db.BRAND
where ce.NAME in ('EDITOR_ADD_DECORATION', 'EDITOR_SET_PAGE_BACKGROUND_COLOUR', 'APPLY_BACKGROUND_TO_PAGE', 'EDITOR_TEXT_STYLE')
and   ce.EVENT_TIME :: date between '2021-08-01' and '2021-12-07'
limit 10
;


select  ree.RAW:data:event.creationId as creation_id
        ,ree.RAW:data:event.merchThemeId as merch_id
        ,ree.RAW:data:event.eventDetails.fontFamily as font_family
from    DB_PROD.RAW.COM_PHOTOBOX_EDITOR_ECREATION ree
where ree.RAW:data:event.creationId :: string is not null
and ree.RAW:data:event:eventDetails.fontFamily :: string is not null
and EVENT_TIME :: date between '2021-08-01' and '2021-12-07'
;

select  ree.RAW:data:event.creationId as creation_id
        ,ree.RAW:data:event.merchThemeId as merch_id
        ,ree.RAW:data:event.eventDetails.fontFamily as font_family
        ,ree.RAW:data:extension.brand as brand
from    DB_PROD.RAW.COM_PHOTOBOX_EDITOR_ECREATION ree
left join "DB_PROD"."WAREHOUSE"."DIM_CREATION" dc on ree.RAW:data:event.creationId = dc.CREATION_ID
left join "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT" ce on dc.CREATION_PK = ce.CREATION_SK
left join "DB_PROD"."WAREHOUSE"."DIM_BRAND" db on ce.BRAND_SK = db.BRAND_PK
where ree.RAW:data:event.creationId :: string is not null
and ree.RAW:data:event:eventDetails.fontFamily :: string is not null
limit 10
//and EVENT_TIME :: date between '2021-08-01' and '2021-12-07'
;

--=========================================================================

--TABLE CHECK--
select *
from "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT" ce
where EVENT_TIME :: DATE between  '2021-12-01' and  '2021-12-06'
and NAME in ('EDITOR_TEXT_STYLE')
and SUMMARY = 'fontFamily'
limit 100
;


select *
from "DB_PROD"."WAREHOUSE"."DIM_CREATION" dc
limit 100
;

select *
from "DB_PROD"."WAREHOUSE"."DIM_BRAND" db
limit 100
;


select *
from DB_PROD.RAW.COM_PHOTOBOX_EDITOR_ECREATION
where EVENT_DATE :: DATE between  '2021-12-01' and  '2021-12-06'
and RAW:data:event.merchThemeId :: string is null
and RAW:data:event.creationId :: string is not null
or RAW:data:event.creationId != ''
and RAW:data:event.name = 'EDITOR_TEXT_STYLE'
limit 100;



--=========================================================================

drop table if exists Assets;
create temp table Assets as
select          distinct asset_id
                ,asset_name
                ,asset_url
                ,event_details
from            "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT"
where           name in ('EDITOR_ADD_DECORATION', 'EDITOR_SET_PAGE_BACKGROUND_COLOUR', 'APPLY_BACKGROUND_TO_PAGE', 'EDITOR_TOGGLE_MASK')
                and asset_name is not null
;

--Did this differ by card type?
select          case when name = 'EDITOR_ADD_DECORATION' then 'Used_Illustration'
                        when name = 'EDITOR_SET_PAGE_BACKGROUND_COLOUR' then 'Set_Page_Colour'
                        when name = 'APPLY_BACKGROUND_TO_PAGE' then 'Applied_Textured_Background'
                end as asset_used
                ,count(distinct a.creation_sk) as creations
from            "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT" a
left join       "DB_ANALYTICS_TEAM"."CSORSBY"."RC_VARIANTS" rc
                    on rc.rc_id = a.variant_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" d
                    on rc.BABEL_PRODUCT_ID = d.BASKET_PRODUCT_ID
left join       "DB_PROD"."WAREHOUSE"."DIM_CREATION" c
                    on a.creation_sk = c.creation_pk
left join       assets e
                    on e.asset_id = a.asset_id
where           /*name in ('EDITOR_ADD_DECORATION', 'EDITOR_SET_PAGE_BACKGROUND_COLOUR', 'APPLY_BACKGROUND_TO_PAGE')
                and*/ event_time between '2021-08-01' and '2021-12-07'
                and s1 = 'Books'
                and first_ordered is not null
group by        1
order by        1
;


select          name
                ,e.ASSET_NAME
                ,e.ASSET_URL
                ,count(distinct a.creation_sk) as creations
from            "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT" a
left join       "DB_ANALYTICS_TEAM"."CSORSBY"."RC_VARIANTS" rc
                    on rc.rc_id = a.variant_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" d
                    on rc.BABEL_PRODUCT_ID = d.BASKET_PRODUCT_ID
left join       "DB_PROD"."WAREHOUSE"."DIM_CREATION" c
                    on a.creation_sk = c.creation_pk
left join       assets e
                    on e.asset_id = a.asset_id
where           name in ('EDITOR_ADD_DECORATION', 'EDITOR_SET_PAGE_BACKGROUND_COLOUR', 'APPLY_BACKGROUND_TO_PAGE')
                and event_time between '2021-08-01' and '2021-12-07'
                and s1 = 'Books'
                and first_ordered is not null
group by        1,2,3
order by        1,4 desc;




