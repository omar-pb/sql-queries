--CREATE TABLES
drop table if exists BOOK_ASSETS;
create temp table BOOK_ASSETS as
select  distinct dc.CREATION_ID as creation_id
        ,dc.CREATION_PK as creation_pk
        ,ce.NAME as event_name
        ,ce.ASSET_ID as asset_id
        ,ce.ASSET_NAME as asset_name
        ,ce.EVENT_DETAILS:fontFamily as font
        ,ce.EVENT_TIME
        ,db.BRAND as brand
        ,ce.LOCALE as locale
        ,products.S2 as S2
from    "DB_PROD"."WAREHOUSE"."DIM_CREATION" dc
inner join      "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT" ce on dc.CREATION_PK = ce.CREATION_SK
left join       "DB_PROD"."WAREHOUSE"."DIM_BRAND" db on ce.BRAND_SK = db.BRAND_PK
left join       "DB_ANALYTICS_TEAM"."CSORSBY"."RC_VARIANTS" variants on ce.VARIANT_ID = variants.RC_ID --This is a temporary lookup that Chris S has created to link back the rollercoaster variant_id to a babel product_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" products  on variants.BABEL_PRODUCT_ID = products.BASKET_PRODUCT_ID -- Joining onto our variant lookup to get meaningful names for the variant_IDs
where   products.s1 = 'Books'
and     ce.EVENT_TIME :: date between '2021-12-11' and '2021-12-12'
;

select top 10 *
from "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT"
where S1 = 'Books'
;

//('EDITOR_ADD_DECORATION', 'EDITOR_SET_PAGE_BACKGROUND_COLOUR', 'APPLY_BACKGROUND_TO_PAGE', 'EDITOR_TEXT_STYLE', 'EDITOR_TOGGLE_MASK', 'APPLY_LAYOUT_TO_PAGE')

drop table if exists ASSET_DETAILS;
create temp table ASSET_DETAILS as
select  ree.RAW:data:event.creationId as creation_id
from    DB_PROD.RAW.COM_PHOTOBOX_EDITOR_ECREATION ree
where   (RAW:data:event.merchThemeId :: string is null
or      RAW:data:event.merchThemeId :: string = '')
and     EVENT_TIME :: date between '2021-08-01' and '2021-12-12'
;

select top 10 *
from BOOK_ASSETS
where event_name = 'EDITOR_TEXT_STYLE'
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
count(distinct BOOK_ASSETS.creation_id) as NO_OF_CREATION
from BOOK_ASSETS
//inner join ASSET_DETAILS AD on BOOK_ASSETS.creation_id = AD.creation_id
where EVENT_TIME :: date between '2021-08-01' and '2021-12-12'
group by 1
order by 2 ASC
;


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
        ,products.S2 as S2
from    "DB_PROD"."WAREHOUSE"."DIM_CREATION" dc
inner join      "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT" ce on dc.CREATION_PK = ce.CREATION_SK
//inner join ASSET_DETAILS ad on dc.CREATION_ID =  ad.creation_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BRAND" db on ce.BRAND_SK = db.BRAND_PK
left join       "DB_ANALYTICS_TEAM"."CSORSBY"."RC_VARIANTS" variants on ce.VARIANT_ID = variants.RC_ID --This is a temporary lookup that Chris S has created to link back the rollercoaster variant_id to a babel product_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" products  on variants.BABEL_PRODUCT_ID = products.BASKET_PRODUCT_ID -- Joining onto our variant lookup to get meaningful names for the variant_IDs
where   products.s1 = 'Books'
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
select  products.S2 as S2,
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
//inner join ASSET_DETAILS ad on dc.CREATION_ID =  ad.creation_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BRAND" db on ce.BRAND_SK = db.BRAND_PK
left join       "DB_ANALYTICS_TEAM"."CSORSBY"."RC_VARIANTS" variants on ce.VARIANT_ID = variants.RC_ID --This is a temporary lookup that Chris S has created to link back the rollercoaster variant_id to a babel product_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" products  on variants.BABEL_PRODUCT_ID = products.BASKET_PRODUCT_ID -- Joining onto our variant lookup to get meaningful names for the variant_IDs
where   products.s1 = 'Books'
and     ce.EVENT_TIME :: date between '2021-08-01' and '2021-12-12'
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
//inner join ASSET_DETAILS ad on dc.CREATION_ID =  ad.creation_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BRAND" db on ce.BRAND_SK = db.BRAND_PK
left join       "DB_ANALYTICS_TEAM"."CSORSBY"."RC_VARIANTS" variants on ce.VARIANT_ID = variants.RC_ID --This is a temporary lookup that Chris S has created to link back the rollercoaster variant_id to a babel product_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" products  on variants.BABEL_PRODUCT_ID = products.BASKET_PRODUCT_ID -- Joining onto our variant lookup to get meaningful names for the variant_IDs
where   products.s1 = 'Books'
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
and     EVENT_TIME :: date between '2021-08-01' and '2021-12-12'
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
//inner join ASSET_DETAILS ad on dc.CREATION_ID =  ad.creation_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BRAND" db on ce.BRAND_SK = db.BRAND_PK
left join       "DB_ANALYTICS_TEAM"."CSORSBY"."RC_VARIANTS" variants on ce.VARIANT_ID = variants.RC_ID --This is a temporary lookup that Chris S has created to link back the rollercoaster variant_id to a babel product_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" products  on variants.BABEL_PRODUCT_ID = products.BASKET_PRODUCT_ID -- Joining onto our variant lookup to get meaningful names for the variant_IDs
where   products.s1 = 'Books'
and     ce.EVENT_TIME :: date between '2021-08-01' and '2021-12-12'
group by 1,2
order by 1,2 ASC
;

---------------------------------------------------------------------

--ASSET SPLIT BY NAME
select name
     //, a.ASSET_ID
     //, a.ASSET_URL
     , a.EVENT_DETAILS:fontFamily as FONT
     , count(distinct a.creation_sk) as NO_OF_CREATIONS
from "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT" a
         left join "DB_ANALYTICS_TEAM"."CSORSBY"."RC_VARIANTS" rc
                   on rc.rc_id = a.variant_id
         left join "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" d
                   on rc.BABEL_PRODUCT_ID = d.BASKET_PRODUCT_ID
         left join "DB_PROD"."WAREHOUSE"."DIM_CREATION" c
                   on a.creation_sk = c.creation_pk
where name in ('EDITOR_TEXT_STYLE')
  and a.event_time :: date between '2021-08-01' and '2021-12-12'
  and s1 = 'Books'
  and first_ordered is not null
group by 1, 2
order by 3 desc;



Select top 10 *
from "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT"
where NAME in ('EDITOR_TEXT_STYLE')
and event_time :: date between '2021-12-10' and '2021-12-12'
