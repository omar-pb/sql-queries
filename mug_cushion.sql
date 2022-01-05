--BOT TABLE--
drop table if exists botUsers;
create table botUsers as
select          distinct visitor_id
                ,BROWSER_SESSION_ID
from            "DB_PROD"."WAREHOUSE"."F_USER_INTERACTION"
where           EVENT_DATETIME_UTC >= '2021-10-18'
                and SUSPECTED_BOT_ACTIVITY = 'FALSE';

--RANGE TO THEMES--
with range_page_users as (
select          c.brand
                ,visitor_id
                ,URL_PATHNAME as URL1
                ,BROWSER_SESSION_ID
                ,min(EVENT_DATETIME_UTC) as first_visit_in_session
from            "DB_PROD"."WAREHOUSE"."F_USER_INTERACTION" a
left join       "DB_PROD"."WAREHOUSE"."DIM_LOCALE" b
                    on a.DIM_LOCALE_SK = b.locale_pk
left join       "DB_PROD"."WAREHOUSE"."DIM_BRAND" c
                    on a.DIM_BRAND_SK = c.BRAND_PK
left join       "DB_PROD"."WAREHOUSE"."DIM_DEVICE" d
                    on a.DIM_DEVICE_SK = d.device_pk
where           URL_PATHNAME in ('/shop/mugs', '/boutique/mug-personnalise','/butik/fotokrus','/shop/fototassen','/shop/fotomokken','/negozio/tazze-personalizzate','/tienda/tazas-personalizadas')
                and EVENT_DATETIME_UTC between date '2020-05-01' and date '2022-01-03'-- launch date
                and SUSPECTED_BOT_ACTIVITY = 'FALSE'
 group by       1,2,3,4
),
range_pages as (
select          distinct visitor_id
                ,case when URL_PATHNAME in ('/shop/cards/design-your-own','/boutique/cartes/realisez-votre-propre-carte','/butik/kort/designe-dit-eget-kort'
                                 ,'/butik/kort/designa-ditt-eget-kort','/shop/kaarten/ontwerp-je-eigen-kaart','/shop/karten/karten-selbst-gestalten'
                                 ,'/negozio/biglietti/crea-il-tuo-biglietto','/tienda/tarjetas/disena-tu-tarjeta','/tarjetas-personalizadas/disena-tu-tarjeta'
                                 ,'/cartas-e-convites') then 'DYO'
                        when URL_PATHNAME in ('/shop/cards/christmas-cards','/boutique/cartes/cartes-de-noel','/butik/kort/julefotokort','/butik/kort/julkort','/shop/kaarten/kerstkaarten',
                                 '/shop/karten/weihnachtskarten','/negozio/biglietti/cartolina-natale','/tienda/tarjetas/navidad-postales','/tarjetas-personalizadas/navidad-postales') then 'Christmas Cards'
                        when URL_PATHNAME IN ('/shop/cards/birthday-invitations','/boutique/cartes/invitations-anniversaire','/butik/kort/fodselsdagsinvitationer',
                                 '/butik/kort/fodelsedagsinbjudningar','/shop/kaarten/verjaardagsuitnodigingen','/shop/karten/einladungen-geburtstagsparty',
                                '/negozio/biglietti/inviti-compleanno', '/tienda/tarjetas/cumpleanos-invitaciones', '/tarjetas-personalizadas/cumpleanos-invitaciones') then 'Birthday Cards'
                        when URL_PATHNAME IN ('/shop/cards/baby-announcements','/boutique/cartes/faire-part-naissance','/butik/kort/bekendtgorelse-babyen',
                                '/butik/kort/babykort','/shop/kaarten/geboortekaartjes','/shop/karten/geburtskarten','/negozio/biglietti/neonati',
                                '/tienda/tarjetas/bautizo-invitaciones','/tarjetas-personalizadas/bautizo-invitaciones') then 'New Baby Cards'
                        when URL_PATHNAME IN ('/shop/cards/thank-you','/boutique/cartes/cartes-remerciement','/butik/kort/takkekort',
                                '/butik/kort/tackkort','/shop/kaarten/bedankkaartjes','/shop/karten/dankeskarten','/negozio/biglietti/ringraziamento',
                                '/tienda/tarjetas/agradecimiento','/tarjetas-personalizadas/agradecimiento') then 'Thank You Cards'
                        when URL_PATHNAME IN ('/shop/cards/wedding-invitations','/boutique/cartes/faire-part-mariage','/butik/kort/bryllupsinvitationer',
                                '/butik/kort/brollopsinbjudningar','/shop/kaarten/trouwkaarten','/shop/karten/hochzeitseinladungen',
                                '/negozio/biglietti/inviti-nozze','/tienda/tarjetas/bodas-invitaciones','/tarjetas-personalizadas/bodas-invitaciones') then 'Wedding Cards'
                END AS Landing_theme
                ,BROWSER_SESSION_ID
                ,EVENT_DATETIME_UTC
                ,c.brand
from            "DB_PROD"."WAREHOUSE"."F_USER_INTERACTION" a
left join       "DB_PROD"."WAREHOUSE"."DIM_LOCALE" b
                    on a.DIM_LOCALE_SK = b.locale_pk
left join       "DB_PROD"."WAREHOUSE"."DIM_BRAND" c
                    on a.DIM_BRAND_SK = c.BRAND_PK
left join       "DB_PROD"."WAREHOUSE"."DIM_DEVICE" d
                    on a.DIM_DEVICE_SK = d.device_pk
where           URL_PATHNAME in ('/shop/cards/design-your-own','/boutique/cartes/realisez-votre-propre-carte','/butik/kort/designe-dit-eget-kort'
                                 ,'/butik/kort/designa-ditt-eget-kort','/shop/kaarten/ontwerp-je-eigen-kaart','/shop/karten/karten-selbst-gestalten'
                                 ,'/negozio/biglietti/crea-il-tuo-biglietto','/tienda/tarjetas/disena-tu-tarjeta','/tarjetas-personalizadas/disena-tu-tarjeta'
                                 ,'/cartas-e-convites','/shop/cards/christmas-cards','/boutique/cartes/cartes-de-noel','/butik/kort/julefotokort','/butik/kort/julkort','/shop/kaarten/kerstkaarten',
                                 '/shop/karten/weihnachtskarten','/negozio/biglietti/cartolina-natale','/tienda/tarjetas/navidad-postales','/tarjetas-personalizadas/navidad-postales','/shop/cards/birthday-invitations','/boutique/cartes/invitations-anniversaire','/butik/kort/fodselsdagsinvitationer',
                                 '/butik/kort/fodelsedagsinbjudningar','/shop/kaarten/verjaardagsuitnodigingen','/shop/karten/einladungen-geburtstagsparty',
                                '/negozio/biglietti/inviti-compleanno', '/tienda/tarjetas/cumpleanos-invitaciones', '/tarjetas-personalizadas/cumpleanos-invitaciones','/shop/cards/baby-announcements','/boutique/cartes/faire-part-naissance','/butik/kort/bekendtgorelse-babyen',
                                '/butik/kort/babykort','/shop/kaarten/geboortekaartjes','/shop/karten/geburtskarten','/negozio/biglietti/neonati',
                                '/tienda/tarjetas/bautizo-invitaciones','/tarjetas-personalizadas/bautizo-invitaciones','/shop/cards/thank-you','/boutique/cartes/cartes-remerciement','/butik/kort/takkekort',
                                '/butik/kort/tackkort','/shop/kaarten/bedankkaartjes','/shop/karten/dankeskarten','/negozio/biglietti/ringraziamento',
                                '/tienda/tarjetas/agradecimiento','/tarjetas-personalizadas/agradecimiento','/shop/cards/wedding-invitations','/boutique/cartes/faire-part-mariage','/butik/kort/bryllupsinvitationer',
                                '/butik/kort/brollopsinbjudningar','/shop/kaarten/trouwkaarten','/shop/karten/hochzeitseinladungen',
                                '/negozio/biglietti/inviti-nozze','/tienda/tarjetas/bodas-invitaciones','/tarjetas-personalizadas/bodas-invitaciones')
                and EVENT_DATETIME_UTC between '2021-10-23' and '2022-01-03'
                and SUSPECTED_BOT_ACTIVITY = 'FALSE'
),
all_users as (
select          rp.*, trp.Landing_theme, trp.EVENT_DATETIME_UTC
from            range_page_users rp
left join       range_pages trp
                    on rp.visitor_id = trp.visitor_id -- same visitor
                    and rp.browser_session_id = trp.browser_session_id -- same session
                    and trp.EVENT_DATETIME_UTC >= rp.first_visit_in_session) -- after visiting cards range page

SELECT          a.brand
                ,b.LANDING_THEME
                ,total_users
                ,PROGRESSIONS
                ,PROGRESSIONS/total_users as progression_rate
FROM
(select         brand
                ,count(distinct visitor_id) as total_users
from            all_users group by 1) a
left join
(select Landing_theme
        ,brand
       ,sum(progressed) as progressions
FROM
(select         visitor_id
                ,brand
                ,Landing_theme
                ,case when max(EVENT_DATETIME_UTC) is not null then 1 else 0 end as progressed
from            all_users
group by        1,2,3)
GROUP BY 1,2) as b
on a.brand = b.brand
where landing_theme is not null;



--TOP SELECTED THEMES--
select          RAW:extensions.brand, RAW:data:event.interactionData.merchThemeId, count(distinct RAW:data:analytics.clientId) users
from            "DB_PROD"."RAW"."COM_PHOTOBOX_SHOP_INTERACTION"
inner join      botUsers
                    on RAW:data:analytics.clientId = botUsers.visitor_id
                    and RAW:data:analytics.browserSessionId = botUsers.browser_Session_id
WHERE           RAW:eventTime :: DATE between '2021-10-23' and '2022-01-03'
                AND RAW:data:event.interactionType = 'clickEvent'
                AND RAW:data:event.elementId = 'themeListingModalCreateButton' -- theme modal
group by        1,2
order by        1,3 desc;



--TOP SELECTED FORMAT--
select          /*RAW:data:event.interactionData.merchThemeId,*/RAW:extensions.brand, RAW:data:event.interactionData.selectedVariantId, count(distinct RAW:data:analytics.clientId) users
from            "DB_PROD"."RAW"."COM_PHOTOBOX_SHOP_INTERACTION"
inner join      botUsers
                    on RAW:data:analytics.clientId = botUsers.visitor_id
                    and RAW:data:analytics.browserSessionId = botUsers.browser_Session_id
WHERE           RAW:eventTime :: DATE between '2021-10-23' and '2022-01-03'
                AND RAW:data:event.interactionType = 'clickEvent'
                AND RAW:data:event.elementId = 'themeListingModalCreateButton' -- theme modal
                AND RAW:data:event.interactionData.merchThemeId IS NOT NULL
group by        1,2
order by        3 desc;



--USERS TO SELECT A THEME--
select          RAW:extensions.brand, /*RAW:data:event.interactionData.merchThemeId,*/ count(distinct RAW:data:analytics.clientId) users
from            "DB_PROD"."RAW"."COM_PHOTOBOX_SHOP_INTERACTION"
inner join      botUsers
                    on RAW:data:analytics.clientId = botUsers.visitor_id
                    and RAW:data:analytics.browserSessionId = botUsers.browser_Session_id
WHERE           RAW:eventTime :: DATE between '2021-10-23' and '2022-01-03'
                AND RAW:data:event.interactionType = 'clickEvent'
                AND RAW:data:event.elementId = 'themeListingModalCreateButton' -- theme modal
group by        1
order by        2 asc;



--TOTAL ORDERS BY THEME--
SELECT RAW:brand,f.VALUE:product.merchThemeId, COUNT(DISTINCT o.RAW:data.customerOrderRef)
FROM "DB_PROD"."RAW"."COM_PHOTOBOX_ECOMMERCE_ORDER" o,
lateral flatten(input => o.RAW, path=> 'data.orderItems') f
WHERE o.EVENT_DATE between '2021-10-23' and '2022-01-03' AND o.RAW:data.version >= '3'
AND F.VALUE:product.merchThemeId IS NOT NULL
AND F.VALUE:product.merchThemeId <> ''
GROUP BY RAW:brand, f.VALUE:product.merchThemeId
ORDER BY 1,3 DESC;



-- TOTAL THEMES ORDERS BY BRAND--
SELECT RAW:brand,
COUNT(DISTINCT RAW:data.customerOrderRef) as theme_orders
FROM
(SELECT *
FROM "DB_PROD"."RAW"."COM_PHOTOBOX_ECOMMERCE_ORDER" o,
lateral flatten(input => o.RAW, path=> 'data.orderItems') f
WHERE o.EVENT_DATE between '2021-10-23' and '2022-01-03' AND o.RAW:data.version >= '3'
AND F.VALUE:product.merchThemeId IS NOT NULL
AND F.VALUE:product.merchThemeId <> '') a
LEFT JOIN "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" P on a.VALUE:product.basketProductId = p.BASKET_PRODUCT_ID
where S1 = 'Cards'
group by 1
order by 1;



--TOTAL DYO ORDERS BY BRAND--
SELECT RAW:brand as brand,
COUNT(DISTINCT RAW:data.customerOrderRef) as DYO_orders
FROM
(SELECT *
FROM "DB_PROD"."RAW"."COM_PHOTOBOX_ECOMMERCE_ORDER" o,
lateral flatten(input => o.RAW, path=> 'data.orderItems') f
WHERE o.EVENT_DATE between '2021-10-23' and '2022-01-03' AND o.RAW:data.version >= '3'
AND (F.VALUE:product.merchThemeId IS NULL OR F.VALUE:product.merchThemeId = '')) a
LEFT JOIN "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" P on a.VALUE:product.basketProductId = p.BASKET_PRODUCT_ID
where S1 = 'Cards'
group by 1
order by 1;



--TOTAL CARDS ORDERS BY BRAND--
SELECT RAW:brand as brand,
COUNT(DISTINCT RAW:data.customerOrderRef) as Theme_orders
FROM
(SELECT *
FROM "DB_PROD"."RAW"."COM_PHOTOBOX_ECOMMERCE_ORDER" o,
lateral flatten(input => o.RAW, path=> 'data.orderItems') f
WHERE o.EVENT_DATE between '2021-10-23' and '2022-01-03' AND o.RAW:data.version >= '3') a
LEFT JOIN "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" P on a.VALUE:product.basketProductId = p.BASKET_PRODUCT_ID
where S1 = 'Cards'
group by 1
order by 1;



--E2U THEME VER 24H--
with editor as (
select          RAW:data:analytics.clientId as client_id
                ,RAW:extensions.brand as brand
                ,min(RAW:eventTime) as EVENT_DATETIME_UTC
from            "DB_PROD"."RAW"."COM_PHOTOBOX_EDITOR_ECREATION"
inner join      botUsers
                    on RAW:data:analytics.clientId = botUsers.visitor_id
                    and RAW:data:analytics.browserSessionId = botUsers.browser_Session_id
where           RAW:data:event:merchThemeId :: string is not null -- This is only for Cards at the moment
                and RAW:eventTime :: date between '2021-10-23' and '2022-01-03'
group by        1,2),
checkout as (
select          a.client_Id
                ,a.brand
                ,min(a.EVENT_DATETIME_UTC) as EVENT_DATETIME_UTC
from
(select         distinct RAW:data:clientId as client_Id
                ,EVENT_TIME as EVENT_DATETIME_UTC
                ,RAW:brand as brand
FROM
(SELECT *
FROM "DB_PROD"."RAW"."COM_PHOTOBOX_ECOMMERCE_ORDER" o,
lateral flatten(input => o.RAW, path=> 'data.orderItems') f
WHERE o.EVENT_DATE between '2021-10-23' and '2022-01-03' AND o.RAW:data.version >= '3'
AND F.VALUE:product.merchThemeId IS NOT NULL AND F.VALUE:product.merchThemeId <> '') a
LEFT JOIN "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" P on a.VALUE:product.basketProductId = p.BASKET_PRODUCT_ID
where S1 = 'Cards') a
inner join      editor e
                    on e.client_Id = a.client_Id
                    and e.brand = a.brand
                    and a.EVENT_DATETIME_UTC >= e.EVENT_DATETIME_UTC -- after first visit to range page
                    and datediff(hour,e.EVENT_DATETIME_UTC, a.EVENT_DATETIME_UTC) BETWEEN 0 and 23
group by        1,2
)
,funnel_data as
(select distinct
     b.client_id
    ,b.brand
    ,b.EVENT_DATETIME_UTC AS editor_ts
    ,c.EVENT_DATETIME_UTC AS checkout_ts
from editor as b
left join checkout as c
    on b.client_id = c.client_id
    and b.brand = c.brand
 )
select
    brand
    ,sum(case when editor_ts is not null then 1 else 0 end) AS Editor
    ,sum(case when checkout_ts is not null then 1 else 0 end) AS Ordered
from funnel_data
group by 1
order by 1
;



--E2U DYO VER 24H--
with editor as (
select          RAW:data:analytics.clientId as client_id
                ,RAW:extensions.brand as brand
                ,min(RAW:eventTime) as EVENT_DATETIME_UTC
from            "DB_PROD"."RAW"."COM_PHOTOBOX_EDITOR_ECREATION"
inner join      botUsers
                    on RAW:data:analytics.clientId = botUsers.visitor_id
                    and RAW:data:analytics.browserSessionId = botUsers.browser_Session_id
left join       "DB_ANALYTICS_TEAM"."CSORSBY"."RC_VARIANTS" f
                    on RAW:data:event.variantId = f.rc_id
left join       "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" e
                    on f.BABEL_PRODUCT_ID = e.BASKET_PRODUCT_ID -- need to join for variant_id - i.e they went into the editor with card
where           RAW:data:event:merchThemeId :: string is null -- but not a themed card
                and RAW:eventTime :: date between '2021-10-23' and '2022-01-03'
                and S1 = 'Cards'
group by        1,2),
checkout as (
select          a.client_Id
                ,a.brand
                ,min(a.EVENT_DATETIME_UTC) as EVENT_DATETIME_UTC
from
(select         distinct RAW:data:clientId as client_Id
                ,EVENT_TIME as EVENT_DATETIME_UTC
                ,RAW:brand as brand
FROM
(SELECT *
FROM "DB_PROD"."RAW"."COM_PHOTOBOX_ECOMMERCE_ORDER" o,
lateral flatten(input => o.RAW, path=> 'data.orderItems') f
WHERE o.EVENT_DATE between '2021-10-23' and '2022-01-03' AND o.RAW:data.version >= '3'
AND (F.VALUE:product.merchThemeId IS NULL OR F.VALUE:product.merchThemeId = '')) a
LEFT JOIN "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" P on a.VALUE:product.basketProductId = p.BASKET_PRODUCT_ID
where S1 = 'Cards') a
inner join      editor e
                    on e.client_Id = a.client_Id
                    and e.brand = a.brand
                    and a.EVENT_DATETIME_UTC >= e.EVENT_DATETIME_UTC -- after first visit to range page
                    and datediff(hour,e.EVENT_DATETIME_UTC, a.EVENT_DATETIME_UTC) BETWEEN 0 and 23
group by        1,2
)
,funnel_data as
(select distinct
     b.client_id
    ,b.brand
    ,b.EVENT_DATETIME_UTC AS editor_ts
    ,c.EVENT_DATETIME_UTC AS checkout_ts
from editor as b
left join checkout as c
    on b.client_id = c.client_id
    and b.brand = c.brand
 )
select
    brand
    ,sum(case when editor_ts is not null then 1 else 0 end) AS Editor
    ,sum(case when checkout_ts is not null then 1 else 0 end) AS Ordered
from funnel_data
group by 1
order by 1
;



--TRAFFIC BY LOCALE--
select locale_Code,
       EVENT_DATETIME_UTC :: date as date,
       count(distinct visitor_id) as users
from "DB_PROD"."WAREHOUSE"."F_USER_INTERACTION" a
         left join "DB_PROD"."WAREHOUSE"."DIM_LOCALE" b
                   on a.DIM_LOCALE_SK = b.locale_pk
         left join "DB_PROD"."WAREHOUSE"."DIM_BRAND" c
                   on a.DIM_BRAND_SK = c.BRAND_PK
         left join "DB_PROD"."WAREHOUSE"."DIM_DEVICE" d
                   on a.DIM_DEVICE_SK = d.device_pk
where URL_PATHNAME in
      ('/shop/cards', '/boutique/cartes', '/butik/kort', '/shop/kaarten', '/shop/karten', '/negozio/biglietti',
       '/tienda/tarjetas', '/tarjetas-personalizadas')
  and EVENT_DATETIME_UTC :: date between '2021-10-23' and '2022-01-03'
  and SUSPECTED_BOT_ACTIVITY = 'FALSE'
group by 1, 2
order by 1, 2 asc;


--TRAFFIC BY BRAND--
select          c.brand,
                EVENT_DATETIME_UTC :: date as date,
                count(distinct visitor_id)
from            "DB_PROD"."WAREHOUSE"."F_USER_INTERACTION" a
left join       "DB_PROD"."WAREHOUSE"."DIM_LOCALE" b
                    on a.DIM_LOCALE_SK = b.locale_pk
left join       "DB_PROD"."WAREHOUSE"."DIM_BRAND" c
                    on a.DIM_BRAND_SK = c.BRAND_PK
left join       "DB_PROD"."WAREHOUSE"."DIM_DEVICE" d
                    on a.DIM_DEVICE_SK = d.device_pk
left join       db_analytics_team.jfarrand.BOT_TRAFFIC t
                    on a.visitor_id = t.client_id
where           URL_PATHNAME in ('/shop/cards', '/boutique/cartes','/butik/kort','/shop/kaarten','/shop/karten','/negozio/biglietti','/tienda/tarjetas','/tarjetas-personalizadas')
                and EVENT_DATETIME_UTC :: date between '2021-10-23' and '2022-01-03'
                and SUSPECTED_BOT_ACTIVITY = 'FALSE'
                and t.client_id is null
group by        1,2
order by        1,2 asc;




--TRAFFIC BY DEVICE--
select          c.brand,
                D.device_type,
                --case when EVENT_DATETIME_UTC :: date < '2021-10-18' then 'Pre' else 'Post' end as time_period,
                EVENT_DATETIME_UTC :: date as date,
                count(distinct visitor_id) as users
from            "DB_PROD"."WAREHOUSE"."F_USER_INTERACTION" a
left join       "DB_PROD"."WAREHOUSE"."DIM_LOCALE" b
                    on a.DIM_LOCALE_SK = b.locale_pk
left join       "DB_PROD"."WAREHOUSE"."DIM_BRAND" c
                    on a.DIM_BRAND_SK = c.BRAND_PK
left join       "DB_PROD"."WAREHOUSE"."DIM_DEVICE" d
                    on a.DIM_DEVICE_SK = d.device_pk
where           URL_PATHNAME in ('/shop/cards', '/boutique/cartes','/butik/kort','/shop/kaarten','/shop/karten','/negozio/biglietti','/tienda/tarjetas','/tarjetas-personalizadas')
                and EVENT_DATETIME_UTC :: date between '2021-10-23' and '2022-01-03'
                and SUSPECTED_BOT_ACTIVITY = 'FALSE'
group by        1,2,3
order by        1,2,3 asc;



--TOTAL TRAFFIC--
select sum(users) as total_users
from (select count(distinct visitor_id) as users
      from "DB_PROD"."WAREHOUSE"."F_USER_INTERACTION" a
               left join "DB_PROD"."WAREHOUSE"."DIM_LOCALE" b
                         on a.DIM_LOCALE_SK = b.locale_pk
               left join "DB_PROD"."WAREHOUSE"."DIM_BRAND" c
                         on a.DIM_BRAND_SK = c.BRAND_PK
               left join "DB_PROD"."WAREHOUSE"."DIM_DEVICE" d
                         on a.DIM_DEVICE_SK = d.device_pk
               left join db_analytics_team.jfarrand.BOT_TRAFFIC t
                         on a.visitor_id = t.client_id
      where URL_PATHNAME in
            ('/shop/cards', '/boutique/cartes', '/butik/kort', '/shop/kaarten', '/shop/karten', '/negozio/biglietti',
             '/tienda/tarjetas', '/tarjetas-personalizadas')
        and EVENT_DATETIME_UTC :: date between '2021-10-23' and '2022-01-03'
        and SUSPECTED_BOT_ACTIVITY = 'FALSE'
        and t.client_id is null
     )
;



--TOTAL CARDS ORDERS--
SELECT sum(theme_orders) as total_orders
from (select COUNT(DISTINCT RAW: data.customerOrderRef) as theme_orders
      FROM (SELECT *
            FROM "DB_PROD"."RAW"."COM_PHOTOBOX_ECOMMERCE_ORDER" o,
                 lateral flatten(input => o.RAW, path => 'data.orderItems') f
            WHERE o.EVENT_DATE between '2021-10-23' and '2022-01-03'
              AND o.RAW: data.version >= '3') a
               LEFT JOIN "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" P
                         on a.VALUE:product.basketProductId = p.BASKET_PRODUCT_ID
      where S1 = 'Cards')
;


--TOTAL ORDERS DIFFERENT THEMES--
WITH no_themes  AS (
    SELECT RAW:brand AS BRAND
         , COUNT(DISTINCT f.VALUE:product.merchThemeId) AS NO_DIFFERENT_THEMES
         , o.RAW: data.customerOrderRef AS ORDER_REF
         //, o.RAW: data.orderItems.quantity AS QUANTITY
    FROM "DB_PROD"."RAW"."COM_PHOTOBOX_ECOMMERCE_ORDER" o,
         lateral flatten(input => o.RAW, path => 'data.orderItems') f
    WHERE o.EVENT_DATE between '2021-10-23' and '2021-12-19'
      AND o.RAW: data.version >= '3'
      AND F.VALUE:product.merchThemeId IS NOT NULL
      AND F.VALUE:product.merchThemeId <> ''
    GROUP BY 1,3
    ORDER BY 1,2 DESC
)

SELECT * FROM no_themes
WHERE NO_DIFFERENT_THEMES > 1;




--BASKET VALUE--

SELECT BASKET_PRODUCT_NAME, ORDER_VALUE, GROSS_QUANTITY, SYMBOL FROM DB_PROD.WAREHOUSE.F_SALES_AND_REVENUE sr
INNER JOIN DB_PROD.WAREHOUSE.DIM_CURRENCY_TYPE ct ON sr.DIM_CURRENCY_TYPE_SK = ct.CURRENCY_TYPE_PK
AND ct.CURRENCY_TYPE_LABEL = 'group'
INNER JOIN DB_PROD.WAREHOUSE.DIM_CURRENCY c ON c.CURRENCY_PK = sr.DIM_PAYMENT_CURRENCY_SK
INNER JOIN DB_PROD.WAREHOUSE.DIM_LINE_ITEM_TYPE li ON sr.DIM_LINE_ITEM_TYPE_SK = li.LINE_ITEM_TYPE_PK
AND li.LINE_ITEM_TYPE_ID = 'dry sale'
WHERE ORDER_VALUE is not null
AND IS_ORDER_VALUE = TRUE
ORDER BY ORDER_VALUE DESC
LIMIT 10;

WITH omars_table AS (
    SELECT          sr.BASKET_PRODUCT_NAME
                    , ORDER_VALUE
                    , GROSS_QUANTITY
                    , SYMBOL
                    , DIM_ORDER_HEADER_SK
    FROM            "DB_PROD"."RAW"."COM_PHOTOBOX_ECOMMERCE_ORDER" o,
    lateral flatten(input => o.RAW, path=> 'data.orderItems') f
    INNER JOIN      "DB_PROD"."WAREHOUSE"."DIM_BASKET_PRODUCT" bp on VALUE:product.basketProductId = bp.BASKET_PRODUCT_ID
    INNER JOIN      DB_PROD.WAREHOUSE.F_SALES_AND_REVENUE sr on sr.ORDER_ITEM_ID = o.data.orderItems:order
    INNER JOIN       DB_PROD.WAREHOUSE.DIM_CURRENCY_TYPE ct ON sr.DIM_CURRENCY_TYPE_SK = ct.CURRENCY_TYPE_PK
                    AND ct.CURRENCY_TYPE_LABEL = 'group'
    INNER JOIN      DB_PROD.WAREHOUSE.DIM_CURRENCY c ON c.CURRENCY_PK = sr.DIM_PAYMENT_CURRENCY_SK
    INNER JOIN      DB_PROD.WAREHOUSE.DIM_LINE_ITEM_TYPE li ON sr.DIM_LINE_ITEM_TYPE_SK = li.LINE_ITEM_TYPE_PK
                    AND li.LINE_ITEM_TYPE_ID = 'dry sale'
    WHERE           1 = 1 -- Added this in so I can comment in and out other where clauses easily
      AND           ORDER_VALUE is not null
      AND           ORDER_PAID_DATETIME_UTC::DATE BETWEEN '2021-12-01' AND '2022-12-07'
      AND F.VALUE:product.merchThemeId IS NOT NULL
      AND F.VALUE:product.merchThemeId <> ''
      AND o.RAW:data.version >= '3'
)
SELECT          BASKET_PRODUCT_NAME
                ,SUM(GROSS_QUANTITY) as items
                ,COUNT(DISTINCT DIM_ORDER_HEADER_SK) as unique_orders
                ,SUM(ORDER_VALUE) as sum_order_value
                ,AVG(ORDER_VALUE) as avg_order_value
                ,AVG(GROSS_QUANTITY) as avg_gross_quantity
FROM            omars_table
GROUP BY        1;

SELECT top 5 * FROM "DB_PROD"."RAW"."COM_PHOTOBOX_ECOMMERCE_ORDER" o
SELECT top 5 * FROM "DB_PROD"."WAREHOUSE".F_SALES_AND_REVENUE


--TOTAL ORDERS SAME THEME--
WITH no_themes  AS (
    SELECT RAW:brand AS BRAND
         , COUNT(f.VALUE:product.merchThemeId) AS THEMES
         , COUNT(DISTINCT o.RAW: data.customerOrderRef) AS ORDER_REF
    FROM "DB_PROD"."RAW"."COM_PHOTOBOX_ECOMMERCE_ORDER" o,
         lateral flatten(input => o.RAW, path => 'data.orderItems') f
    WHERE o.EVENT_DATE between '2021-10-23' and '2021-12-19'
      AND o.RAW: data.version >= '3'
      AND F.VALUE:product.merchThemeId IS NULL
      OR F.VALUE:product.merchThemeId = ''
    GROUP BY 1
    ORDER BY 1,2 DESC
)

SELECT * FROM no_themes
LIMIT 10