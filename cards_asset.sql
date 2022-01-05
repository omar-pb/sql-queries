-- Quick tips for the Editor data
select          top 10 *
from           "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT" as editor --note this table has locale already, so no need to use DIM_LOCALE
left join      "DB_PROD"."WAREHOUSE"."DIM_BRAND"  as brand --filter by brand using the brand.brand column
                    on editor.brand_sk = brand.brand_pk
left join      "DB_PROD"."WAREHOUSE"."DIM_DEVICE"  as device -- filter for device
                    on editor.DEVICE_SK = device.DEVICE_PK
left join      "DB_PROD"."WAREHOUSE"."DIM_CREATION"  as creation --Here you can filter for further details on creation such as first_ordered date, creation_started etc. Creation_ID also exists in this table
                    on editor.creation_sk = creation.creation_pk
left join      "DB_ANALYTICS_TEAM"."CSORSBY"."RC_VARIANTS" variants --This is a temporary lookup that Chris S has created to link back the rollercoaster variant_id to a babel product_id
                    on editor.variant_id = variants.rc_id
left join      "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" products -- Joining onto our variant lookup to get meaningful names for the variant_IDs
                    on variants.BABEL_PRODUCT_ID = products.BASKET_PRODUCT_ID
where           brand.brand in ('photobox','hofmann') -- Note only rollercoaster brands are here, so PXXL is not currently included
                and device.device_type in ('smartphone','desktop')
                and editor.event_time :: date between '2021-01-01' and '2021-09-28' -- time of the event occurrence, if you want time of creation start use the creation_start column from dim_creation table
                and editor.name in ('CREATE_NEW_EVENT') -- if filtering for a particular user action, you can do so here. Some are documented in confluence here https://confluence.photobox.com/pages/viewpage.action?spaceKey=PBZAN&title=Editor+Event+Tracking, otherwise you can ask any Editor dev for the suitable event name
                and products.s1 = 'Calendars'
                and first_ordered is not null --i.e. this particular creation has been ordered
;
-------------------------------------------------------------------------------------------------
--CREATE TABLES
drop table if exists CARD_ASSETS;
create table CARD_ASSETS as
select   distinct dc.CREATION_ID as creation_id
        ,dc.CREATION_PK as creation_pk
        ,ce.NAME as event_name
        ,ce.ASSET_ID as asset_id
        ,ce.ASSET_NAME as asset_name
        ,ce.EVENT_DETAILS:fontFamily as font
        ,ce.EVENT_TIME
        ,db.BRAND as brand
        ,ce.LOCALE as locale
        ,products.S4 as S4
from    "DB_PROD"."WAREHOUSE"."DIM_CREATION" dc
inner join      "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT" ce on dc.CREATION_PK = ce.CREATION_SK
left join       "DB_PROD"."WAREHOUSE"."DIM_BRAND" db on ce.BRAND_SK = db.BRAND_PK
left join       "DB_ANALYTICS_TEAM"."CSORSBY"."RC_VARIANTS" variants on ce.VARIANT_ID = variants.RC_ID --This is a temporary lookup that Chris S has created to link back the rollercoaster variant_id to a babel product_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" products  on variants.BABEL_PRODUCT_ID = products.BASKET_PRODUCT_ID -- Joining onto our variant lookup to get meaningful names for the variant_IDs
where   products.s1 = 'Cards'
and     ce.EVENT_TIME :: date between '2021-08-01' and '2021-12-12'
;

//('EDITOR_ADD_DECORATION', 'EDITOR_SET_PAGE_BACKGROUND_COLOUR', 'APPLY_BACKGROUND_TO_PAGE', 'EDITOR_TEXT_STYLE', 'EDITOR_TOGGLE_MASK', 'APPLY_LAYOUT_TO_PAGE')

drop table if exists ASSET_DETAILS;
create table ASSET_DETAILS as
select  ree.RAW:data:event.creationId as creation_id
from    DB_PROD.RAW.COM_PHOTOBOX_EDITOR_ECREATION ree
where   (RAW:data:event.merchThemeId :: string is null
or      RAW:data:event.merchThemeId :: string = '')
and     EVENT_TIME :: date between '2021-08-01' and '2021-12-12'
;



--TOTAL PER ASSETS
select
        case
            when event_name = 'EDITOR_ADD_DECORATION' then 'ILLUSTRATION_USED'
            when event_name = 'EDITOR_SET_PAGE_BACKGROUND_COLOUR' then 'SET_PAGE_COLOUR'
            when event_name = 'APPLY_BACKGROUND_TO_PAGE' then 'APPLIED_TEXTURED_BACKGROUND'
            when event_name = 'EDITOR_TEXT_STYLE' then 'APPLIED_FONT'
            when event_name = 'APPLY_LAYOUT_TO_PAGE' then 'APPLIED_LAYOUT'
            when event_name = 'EDITOR_TOGGLE_MASK' then 'CUTOUT'
            else 'TOTAL'
        end
as ASSET_USED,
//font as FONT,
count(distinct creation_pk) as NO_OF_CREATION
from CARD_ASSETS
inner join ASSET_DETAILS AD on CARD_ASSETS.creation_id = AD.creation_id
where EVENT_TIME :: date between '2021-08-01' and '2021-12-12'
group by 1
order by 2 ASC
;


--Ordered Layouts

--DETAILED ASSETS USED
with asset_datails as (
select  ree.RAW:data:event.creationId as creation_id
from    DB_PROD.RAW.COM_PHOTOBOX_EDITOR_ECREATION ree
where   (RAW:data:event.merchThemeId :: string is null
or      RAW:data:event.merchThemeId :: string = '')
and     EVENT_TIME :: date between '2021-08-01' and '2021-12-09'
)

select  case
            when ce.NAME = 'EDITOR_ADD_DECORATION' then 'ILLUSTRATION_USED'
            when ce.NAME = 'EDITOR_SET_PAGE_BACKGROUND_COLOUR' then 'SET_PAGE_COLOUR'
            when ce.NAME = 'APPLY_BACKGROUND_TO_PAGE' then 'APPLIED_TEXTURED_BACKGROUND'
            when ce.NAME = 'EDITOR_TEXT_STYLE' then 'APPLIED_FONT'
            when ce.NAME = 'APPLY_LAYOUT_TO_PAGE' then 'APPLIED_LAYOUT'
            when ce.NAME = 'EDITOR_TOGGLE_MASK' then 'CUTOUT'
            else 'TOTAL OTHERS'
        end
as ASSET_USED,
count(distinct creation_pk) as TOTAL_PER_ASSET
        ,ce.ASSET_NAME as asset_name
        ,ce.EVENT_DETAILS:fontFamily as font
        ,db.BRAND as brand
        ,ce.LOCALE as locale
        ,products.S4 as S4
from    "DB_PROD"."WAREHOUSE"."DIM_CREATION" dc
inner join      "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT" ce on dc.CREATION_PK = ce.CREATION_SK
inner join ASSET_DETAILS ad on dc.CREATION_ID =  ad.creation_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BRAND" db on ce.BRAND_SK = db.BRAND_PK
left join       "DB_ANALYTICS_TEAM"."CSORSBY"."RC_VARIANTS" variants on ce.VARIANT_ID = variants.RC_ID --This is a temporary lookup that Chris S has created to link back the rollercoaster variant_id to a babel product_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" products  on variants.BABEL_PRODUCT_ID = products.BASKET_PRODUCT_ID -- Joining onto our variant lookup to get meaningful names for the variant_IDs
where   products.s1 = 'Cards'
and     ce.EVENT_TIME :: date between '2021-08-01' and '2021-12-12'
group by 1,3,4,5,6,7
order by 1,2 DESC
;

--====================================================================================


--split by S4
with asset_datails as (
select  ree.RAW:data:event.creationId as creation_id
from    DB_PROD.RAW.COM_PHOTOBOX_EDITOR_ECREATION ree
where   (RAW:data:event.merchThemeId :: string is null
or      RAW:data:event.merchThemeId :: string = '')
and     EVENT_TIME :: date between '2021-08-01' and '2021-12-12'
)
select  products.S4 as S4,
        case
            when ce.NAME = 'EDITOR_ADD_DECORATION' then 'ILLUSTRATION_USED'
            when ce.NAME = 'EDITOR_SET_PAGE_BACKGROUND_COLOUR' then 'SET_PAGE_COLOUR'
            when ce.NAME = 'APPLY_BACKGROUND_TO_PAGE' then 'APPLIED_TEXTURED_BACKGROUND'
            when ce.NAME = 'EDITOR_TEXT_STYLE' then 'APPLIED_FONT'
            when ce.NAME = 'APPLY_LAYOUT_TO_PAGE' then 'APPLIED_LAYOUT'
            when ce.NAME = 'EDITOR_TOGGLE_MASK' then 'CUTOUT'
            else 'TOTAL'
        end
as ASSET_USED,
count(distinct creation_pk) as NO_OF_CREATION
from    "DB_PROD"."WAREHOUSE"."DIM_CREATION" dc
inner join      "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT" ce on dc.CREATION_PK = ce.CREATION_SK
inner join ASSET_DETAILS ad on dc.CREATION_ID =  ad.creation_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BRAND" db on ce.BRAND_SK = db.BRAND_PK
left join       "DB_ANALYTICS_TEAM"."CSORSBY"."RC_VARIANTS" variants on ce.VARIANT_ID = variants.RC_ID --This is a temporary lookup that Chris S has created to link back the rollercoaster variant_id to a babel product_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" products  on variants.BABEL_PRODUCT_ID = products.BASKET_PRODUCT_ID -- Joining onto our variant lookup to get meaningful names for the variant_IDs
where   products.s1 = 'Cards'
and     ce.EVENT_TIME :: date between '2021-08-01' and '2021-12-09'
group by 1,2
order by 1,2 ASC
;

--split by locale
with asset_datails as (
select  ree.RAW:data:event.creationId as creation_id
from    DB_PROD.RAW.COM_PHOTOBOX_EDITOR_ECREATION ree
where   (RAW:data:event.merchThemeId :: string is null
or      RAW:data:event.merchThemeId :: string = '')
and     EVENT_TIME :: date between '2021-08-01' and '2021-12-09'
)
select  ce.LOCALE,
        case
            when ce.NAME = 'EDITOR_ADD_DECORATION' then 'ILLUSTRATION_USED'
            when ce.NAME = 'EDITOR_SET_PAGE_BACKGROUND_COLOUR' then 'SET_PAGE_COLOUR'
            when ce.NAME = 'APPLY_BACKGROUND_TO_PAGE' then 'APPLIED_TEXTURED_BACKGROUND'
            when ce.NAME = 'EDITOR_TEXT_STYLE' then 'APPLIED_FONT'
            when ce.NAME = 'APPLY_LAYOUT_TO_PAGE' then 'APPLIED_LAYOUT'
            when ce.NAME = 'EDITOR_TOGGLE_MASK' then 'CUTOUT'
            else 'TOTAL'
        end
as ASSET_USED,
count(distinct creation_pk) as NO_OF_CREATION
from    "DB_PROD"."WAREHOUSE"."DIM_CREATION" dc
inner join      "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT" ce on dc.CREATION_PK = ce.CREATION_SK
inner join ASSET_DETAILS ad on dc.CREATION_ID =  ad.creation_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BRAND" db on ce.BRAND_SK = db.BRAND_PK
left join       "DB_ANALYTICS_TEAM"."CSORSBY"."RC_VARIANTS" variants on ce.VARIANT_ID = variants.RC_ID --This is a temporary lookup that Chris S has created to link back the rollercoaster variant_id to a babel product_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" products  on variants.BABEL_PRODUCT_ID = products.BASKET_PRODUCT_ID -- Joining onto our variant lookup to get meaningful names for the variant_IDs
where   products.s1 = 'Cards'
and     ce.EVENT_TIME :: date between '2021-08-01' and '2021-12-12'
group by 1,2
order by 1,2 ASC
;


--split by brand
with asset_datails as (
select  ree.RAW:data:event.creationId as creation_id
from    DB_PROD.RAW.COM_PHOTOBOX_EDITOR_ECREATION ree
where   (RAW:data:event.merchThemeId :: string is null
or      RAW:data:event.merchThemeId :: string = '')
and     EVENT_TIME :: date between '2021-08-01' and '2021-12-07'
)
select  db.BRAND,
        case
            when ce.NAME = 'EDITOR_ADD_DECORATION' then 'ILLUSTRATION_USED'
            when ce.NAME = 'EDITOR_SET_PAGE_BACKGROUND_COLOUR' then 'SET_PAGE_COLOUR'
            when ce.NAME = 'APPLY_BACKGROUND_TO_PAGE' then 'APPLIED_TEXTURED_BACKGROUND'
            when ce.NAME = 'EDITOR_TEXT_STYLE' then 'APPLIED_FONT'
            when ce.NAME = 'APPLY_LAYOUT_TO_PAGE' then 'APPLIED_LAYOUT'
            when ce.NAME = 'EDITOR_TOGGLE_MASK' then 'CUTOUT'
            else 'TOTAL'
        end
as ASSET_USED,
count(distinct creation_pk) as NO_OF_CREATION
from    "DB_PROD"."WAREHOUSE"."DIM_CREATION" dc
inner join      "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT" ce on dc.CREATION_PK = ce.CREATION_SK
inner join ASSET_DETAILS ad on dc.CREATION_ID =  ad.creation_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BRAND" db on ce.BRAND_SK = db.BRAND_PK
left join       "DB_ANALYTICS_TEAM"."CSORSBY"."RC_VARIANTS" variants on ce.VARIANT_ID = variants.RC_ID --This is a temporary lookup that Chris S has created to link back the rollercoaster variant_id to a babel product_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" products  on variants.BABEL_PRODUCT_ID = products.BASKET_PRODUCT_ID -- Joining onto our variant lookup to get meaningful names for the variant_IDs
where   products.s1 = 'Cards'
and     ce.EVENT_TIME :: date between '2021-08-01' and '2021-12-09'
group by 1,2
order by 1,2 ASC
;

---------------------------------------------------------------------

--ASSET SPLIT BY NAME
select name
     , e.ASSET_ID
     , a.ASSET_URL
     , count(distinct a.creation_sk) as NO_OF_CREATIONS
from "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT" a
         left join "DB_ANALYTICS_TEAM"."CSORSBY"."RC_VARIANTS" rc
                   on rc.rc_id = a.variant_id
         left join "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" d
                   on rc.BABEL_PRODUCT_ID = d.BASKET_PRODUCT_ID
         left join "DB_PROD"."WAREHOUSE"."DIM_CREATION" c
                   on a.creation_sk = c.creation_pk
         left join CARD_ASSETS e
                   on e.asset_id = a.asset_id
where name in ('EDITOR_SET_PAGE_BACKGROUND_COLOUR')
  and e.event_time :: date between '2021-08-01' and '2021-12-12'
  and s1 = 'Cards'
  and first_ordered is not null
group by 1, 2, 3
order by 1, 4 desc;



Select top 10 *
from "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT"
where NAME in ('EDITOR_TOGGLE_MASK')
and event_time :: date between '2021-12-10' and '2021-12-12'