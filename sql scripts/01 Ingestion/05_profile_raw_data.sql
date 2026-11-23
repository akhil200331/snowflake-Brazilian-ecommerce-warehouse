USE ROLE SYSADMIN;
USE DATABASE ECOM_DWH_DEV;
USE SCHEMA RAW_DATA;

-- 1. Duplicate business keys (key candidates)
SELECT 'customers: customer_id' AS chk, COUNT(*) - COUNT(DISTINCT CUSTOMER_ID) AS dups FROM RAW_CUSTOMERS UNION ALL
SELECT 'orders: order_id',               COUNT(*) - COUNT(DISTINCT ORDER_ID) FROM RAW_ORDERS UNION ALL
SELECT 'products: product_id',           COUNT(*) - COUNT(DISTINCT PRODUCT_ID) FROM RAW_PRODUCTS UNION ALL
SELECT 'sellers: seller_id',             COUNT(*) - COUNT(DISTINCT SELLER_ID) FROM RAW_SELLERS UNION ALL
SELECT 'reviews: review_id',             COUNT(*) - COUNT(DISTINCT REVIEW_ID) FROM RAW_ORDER_REVIEWS UNION ALL
SELECT 'order_items: order_id+item_id',  COUNT(*) - COUNT(DISTINCT ORDER_ID || '|' || ORDER_ITEM_ID) FROM RAW_ORDER_ITEMS UNION ALL
SELECT 'payments: order_id+seq',         COUNT(*) - COUNT(DISTINCT ORDER_ID || '|' || PAYMENT_SEQUENTIAL) FROM RAW_ORDER_PAYMENTS;

-- 2. customer_id vs customer_unique_id
SELECT COUNT(DISTINCT CUSTOMER_ID) AS distinct_customer_id,
       COUNT(DISTINCT CUSTOMER_UNIQUE_ID) AS distinct_unique_id
FROM RAW_CUSTOMERS;

-- 3. Referential integrity (orphans)
SELECT 'orders without customer' AS chk, COUNT(*) AS cnt
FROM RAW_ORDERS o LEFT JOIN RAW_CUSTOMERS c ON o.CUSTOMER_ID = c.CUSTOMER_ID WHERE c.CUSTOMER_ID IS NULL
UNION ALL
SELECT 'items without order', COUNT(*)
FROM RAW_ORDER_ITEMS i LEFT JOIN RAW_ORDERS o ON i.ORDER_ID = o.ORDER_ID WHERE o.ORDER_ID IS NULL
UNION ALL
SELECT 'items without product', COUNT(*)
FROM RAW_ORDER_ITEMS i LEFT JOIN RAW_PRODUCTS p ON i.PRODUCT_ID = p.PRODUCT_ID WHERE p.PRODUCT_ID IS NULL
UNION ALL
SELECT 'items without seller', COUNT(*)
FROM RAW_ORDER_ITEMS i LEFT JOIN RAW_SELLERS s ON i.SELLER_ID = s.SELLER_ID WHERE s.SELLER_ID IS NULL
UNION ALL
SELECT 'payments without order', COUNT(*)
FROM RAW_ORDER_PAYMENTS p LEFT JOIN RAW_ORDERS o ON p.ORDER_ID = o.ORDER_ID WHERE o.ORDER_ID IS NULL
UNION ALL
SELECT 'reviews without order', COUNT(*)
FROM RAW_ORDER_REVIEWS r LEFT JOIN RAW_ORDERS o ON r.ORDER_ID = o.ORDER_ID WHERE o.ORDER_ID IS NULL
UNION ALL
SELECT 'orders without items', COUNT(*)
FROM RAW_ORDERS o LEFT JOIN RAW_ORDER_ITEMS i ON o.ORDER_ID = i.ORDER_ID WHERE i.ORDER_ID IS NULL
UNION ALL
SELECT 'product categories missing translation', COUNT(DISTINCT p.PRODUCT_CATEGORY_NAME)
FROM RAW_PRODUCTS p LEFT JOIN RAW_CATEGORY_TRANSLATION t ON p.PRODUCT_CATEGORY_NAME = t.PRODUCT_CATEGORY_NAME
WHERE t.PRODUCT_CATEGORY_NAME IS NULL AND p.PRODUCT_CATEGORY_NAME IS NOT NULL;

-- 4. Reviews per order
SELECT reviews_per_order, COUNT(*) AS orders
FROM (SELECT ORDER_ID, COUNT(*) AS reviews_per_order FROM RAW_ORDER_REVIEWS GROUP BY ORDER_ID)
GROUP BY reviews_per_order ORDER BY 1;

-- 5. Order status distribution
select order_status,count(*) as cnt from RAW_ORDERS group by 1 order by 2 desc;

-- 6. Values that will fail type conversion in Silver
SELECT 'bad purchase ts' AS chk, COUNT(*) AS cnt
FROM RAW_ORDERS WHERE ORDER_PURCHASE_TIMESTAMP IS NOT NULL AND TRY_TO_TIMESTAMP(ORDER_PURCHASE_TIMESTAMP) IS NULL
UNION ALL
SELECT 'bad price', COUNT(*) FROM RAW_ORDER_ITEMS WHERE PRICE IS NOT NULL AND TRY_TO_DECIMAL(PRICE, 12, 2) IS NULL
UNION ALL
SELECT 'bad payment_value', COUNT(*) FROM RAW_ORDER_PAYMENTS WHERE PAYMENT_VALUE IS NOT NULL AND TRY_TO_DECIMAL(PAYMENT_VALUE, 12, 2) IS NULL
UNION ALL
SELECT 'bad review_score', COUNT(*) FROM RAW_ORDER_REVIEWS WHERE REVIEW_SCORE IS NOT NULL AND TRY_TO_NUMBER(REVIEW_SCORE) IS NULL;

-- 7. NULL counts on key columns
SELECT COUNT_IF(ORDER_APPROVED_AT IS NULL)            AS null_approved,
       COUNT_IF(ORDER_DELIVERED_CARRIER_DATE IS NULL) AS null_carrier,
       COUNT_IF(ORDER_DELIVERED_CUSTOMER_DATE IS NULL) AS null_delivered
FROM RAW_ORDERS;
SELECT COUNT_IF(PRODUCT_CATEGORY_NAME IS NULL) AS null_category,
       COUNT_IF(PRODUCT_WEIGHT_G IS NULL)      AS null_weight
FROM RAW_PRODUCTS;

-- 8. Zip prefix length (customers, sellers)
SELECT 'customers' AS src, MIN(LENGTH(CUSTOMER_ZIP_CODE_PREFIX)) AS min_len, MAX(LENGTH(CUSTOMER_ZIP_CODE_PREFIX)) AS max_len FROM RAW_CUSTOMERS
UNION ALL
SELECT 'sellers', MIN(LENGTH(SELLER_ZIP_CODE_PREFIX)), MAX(LENGTH(SELLER_ZIP_CODE_PREFIX)) FROM RAW_SELLERS;


-- My Checks
-- 1. Customers Dataset
select count(DISTINCT CUSTOMER_ID) as cid,count(DISTINCT(CUSTOMER_UNIQUE_ID)) as cuid from RAW_CUSTOMERS;
select count(distinct CUSTOMER_UNIQUE_ID) from RAW_CUSTOMERS where CUSTOMER_UNIQUE_ID is not null;

-- Below Query is to check how customer ID is differen from CUstomer Unique ID

-- Column	Meaning
-- customer_id	Identifies a customer record associated with a particular order.
-- customer_unique_id	Identifies the actual customer across different orders, acting as a persistent customer identifier.
select * from RAW_CUSTOMERS where customer_unique_id in (select customer_unique_id from RAW_CUSTOMERS group by 1 having count(1)>1) order by customer_unique_id;

-- 2. Orders Dataset
select * from RAW_ORDERS where customer_id in ('1afe8a9c67eec3516c09a8bdcc539090','24b0e2bd287e47d54d193e7bbb51103f');

select count(distinct order_id) as distinct_order_count, count(*) as records from RAW_ORDERS;

select * from RAW_ORDERS where CUSTOMER_ID is null;

select distinct order_status from RAW_ORDERS;

SELECT ORDER_STATUS, COUNT(*) as delivered_date_null_cnt FROM RAW_ORDERS WHERE ORDER_DELIVERED_CUSTOMER_DATE IS NULL GROUP BY ORDER_STATUS ORDER BY ORDER_STATUS;

select * from RAW_ORDERS where ORDER_PURCHASE_TIMESTAMP is null or order_approved_at is null or order_delivered_carrier_date is null or order_delivered_customer_date is null or order_estimated_delivery_date is null ORDER BY ORDER_STATUS;

-- 3. Order Items
select count(distinct order_id) as order_id_cnt,count(*) as records from RAW_ORDER_ITEMS; -- not tallying
-- check for concatenate key
select count(distinct concatenated_key) from (select concat(order_id,'-',order_item_id) as concatenated_key from RAW_ORDER_ITEMS); -- Tallying with records
select * from RAW_ORDER_ITEMS where order_id is null; -- Empty Records

select * from RAW_ORDER_ITEMS where order_id in('e69f75a717d64fc5ecdfae42b2e8e086',
'2d858f451373b04fb5c984a1cc2defaf',
'ab7c89dc1bf4a1ead9d6ec1ec8968a84');

-- 4. Order Payments
select * from RAW_ORDER_PAYMENTS;

select count(distinct order_id) as order_count_unique,count(*) as cnt from RAW_ORDER_PAYMENTS; -- Not Valid
select count(concatenated_key) from (select concat(order_id,'-',PAYMENT_SEQUENTIAL) as concatenated_key from RAW_ORDER_PAYMENTS);

select * from RAW_ORDER_PAYMENTS where order_id is null;

select * from RAW_ORDER_PAYMENTS where payment_installments is null or payment_sequential is null or payment_type is null or payment_value is null;


-- 5. Order Reviews
select * from RAW_ORDER_REVIEWS;

select count(distinct REVIEW_ID) as unique_id_count,count(*) as records from RAW_ORDER_REVIEWS; -- Not Tallying

select count(concatenated_key) as surrogate_key from (select concat(order_id,'-',REVIEW_ID) as concatenated_key from RAW_ORDER_REVIEWS);

select * from RAW_ORDER_REVIEWS where review_score is null or review_creation_date is null or review_answer_timestamp is null; -- Perfect good to go


-- 5. Raw Products
select * from RAW_PRODUCTS;

select count(distinct PRODUCT_ID) as cnt_unique,count(*) as records from RAW_PRODUCTS;

select * from RAW_PRODUCTS where PRODUCT_CATEGORY_NAME is null or product_name_lenght is null or product_description_lenght is null or product_photos_qty is null or product_weight_g is null or product_length_cm is null or product_height_cm is null or product_width_cm is null; -- Need to analyse with other tables

-- 6. Raw Sellers
select * from RAW_SELLERS;

select count(distinct seller_id) as cnt_unique_records,count(*) as records from RAW_SELLERS; -- Good to go

select * from RAW_SELLERS where seller_zip_code_prefix is null or seller_city is null or seller_state is null; -- Good to go