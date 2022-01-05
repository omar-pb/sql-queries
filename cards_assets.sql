-- REMOVE ANY DATA QUALITY CODE - users do not get creation_id until they have saved their creation faffle
-- For Cards
-- Assets (stickers & backgrounds) that have been not used or has low usage particular on cards for Q1
-- Whether layouts were applied, what the most popular type of layouts were (i.e. ones with x many images, or x many text boxes) all split by card type
-- Assets that Winnie gave do not have any category mappings to backgrounds in Q1
drop table if exists Assets;
create temp table Assets as
select          distinct asset_id
                ,asset_name
                ,asset_url
from            "DB_PROD"."WAREHOUSE"."F_EDITOR_CREATION_EVENT"
where           name in ('EDITOR_ADD_DECORATION', 'EDITOR_SET_PAGE_BACKGROUND_COLOUR', 'APPLY_BACKGROUND_TO_PAGE')
                and asset_name is not null;



--How many ordered creations in Q1 did users apply a layout/background?

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
                and*/ event_time between '2021-05-01' and '2021-07-31'
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
                and event_time between '2021-05-01' and '2021-07-31'
                and s1 = 'Books'
                and first_ordered is not null
group by        1,2,3
order by        1,4 desc;


-- Layouts usage
select          Card_type
                ,event_details:layoutImages
                ,event_details:layoutTextBoxes
                ,count(distinct a.creation_id)
from
(select          distinct creation_id
                ,S3 as Card_type
                ,name
                ,event_time
                ,asset_Id
                ,summary
                ,event_details
                ,dense_rank () over (partition by creation_id order by event_time desc) as last_Event
from            "DB_PROD"."DATAQUALITY"."Q_PBX_EDITOR_ECREATION" a
left join       "DB_ANALYTICS_TEAM"."CSORSBY"."RC_VARIANTS" rc
                    on rc.rc_id = a.variant_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" d
                    on rc.BABEL_PRODUCT_ID = d.BASKET_PRODUCT_ID
where           event_time :: date between '2021-05-01' and '2021-07-31'
                and S1 = 'Books'
                and name = 'APPLY_LAYOUT_TO_PAGE'
/*qualify         last_Event = 1*/) a
inner join      -- order info
(select         CREATION_PK
                ,creation_id
                ,sum(num_orders) as orders
                ,sum(num_Sessions) as sessions
from            "DB_PROD"."WAREHOUSE"."DIM_CREATION"
where           first_ordered is not null
group by        1,2) b
                on a.creation_id = b.creation_id
group by 1,2,3
order by 1, 4 desc;



select          S2,case when name = 'APPLY_LAYOUT_TO_PAGE' then 'Applied_a_layout'
                end as layout_used
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
                and*/ event_time between '2021-05-01' and '2021-07-31'
                and s1 = 'Books'
                and first_ordered is not null
group by        1,2
order by        1,2
;