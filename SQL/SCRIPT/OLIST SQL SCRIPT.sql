USE olist;
SHOW TABLES;
DESCRIBE orders;
SELECT * FROM orders LIMIT 5;
SELECT * FROM orders;
SELECT * FROM CUSTOMERS;
SELECT COUNT(*) FROM ORDERS;

-- orders in each status ---
SELECT ORDER_STATUS, COUNT(*) AS TOTAL_ORDER
FROM ORDERS
GROUP BY ORDER_STATUS;

--- date range of the data---
SELECT MIN(order_purchase_timestamp) AS first_order,
       MAX(order_purchase_timestamp) AS last_order
FROM orders;

-- TOTAL PRODUCT REVENUE---
SELECT * FROM order_items;

SELECT ROUND(SUM(price), 2) AS total_revenue,
       ROUND(SUM(freight_value), 2) AS total_freight
FROM order_items;

-- 5 states which have the most orders---
SELECT C.CUSTOMER_STATE, COUNT(*) AS TOTAL_ORDERS
FROM ORDERS AS O
JOIN CUSTOMERS AS C
ON O.CUSTOMER_ID= C.CUSTOMER_ID
GROUP BY CUSTOMER_STATE
ORDER BY TOTAL_ORDERS desc 
LIMIT 5;

SELECT CUSTOMER_STATE, COUNT(*) AS TOTAL_ORDERS
FROM CUSTOMERS
GROUP BY CUSTOMER_STATE
ORDER BY TOTAL_ORDERS desc
LIMIT 5;

-- Monthly orders---
SELECT DATE_FORMAT(ORDER_PURCHASE_TIMESTAMP, '%Y-%M')AS ORDER_MONTH,
COUNT(*) AS TOTAL_ORDERS
FROM ORDERS
GROUP BY DATE_FORMAT(ORDER_PURCHASE_TIMESTAMP, '%Y-%M') 
ORDER BY TOTAL_ORDERS desc;

SELECT DATE_FORMAT(ORDER_PURCHASE_TIMESTAMP, '%Y-%m')AS ORDER_MONTH,
COUNT(*) AS TOTAL_ORDERS
FROM ORDERS
GROUP BY DATE_FORMAT(ORDER_PURCHASE_TIMESTAMP, '%Y-%m') 
ORDER BY ORDER_MONTH;

-- REVENUE BY MONTH ---
SELECT DATE_FORMAT(ORDER_PURCHASE_TIMESTAMP, '%Y-%m')AS ORDER_MONTH,
ROUND(SUM(OD.PRICE),2) AS TOTAL_REVENUE,
COUNT(DISTINCT OD.ORDER_ID) AS TOTAL_ORDER
FROM ORDERS AS O
JOIN ORDER_ITEMS AS OD
ON O.ORDER_ID= OD.ORDER_ID
WHERE O.ORDER_STATUS='DELIVERED'
GROUP BY DATE_FORMAT(ORDER_PURCHASE_TIMESTAMP, '%Y-%m')
ORDER BY ORDER_MONTH;

-- REVENUE BY YEAR ---
SELECT DATE_FORMAT(ORDER_PURCHASE_TIMESTAMP, '%Y')AS ORDER_YEAR,
ROUND(SUM(OD.PRICE),2) AS TOTAL_REVENUE,
COUNT(DISTINCT OD.ORDER_ID) AS TOTAL_ORDER
FROM ORDERS AS O
JOIN ORDER_ITEMS AS OD
ON O.ORDER_ID= OD.ORDER_ID
WHERE O.ORDER_STATUS='DELIVERED'
GROUP BY DATE_FORMAT(ORDER_PURCHASE_TIMESTAMP, '%Y')
ORDER BY ORDER_YEAR;

-- TOP PRODUCT CATEGORY --
DESCRIBE category_translation;
RENAME TABLE product_category_name_translation TO CATEGORY_TRANSLATION;
SELECT * FROM category_translation;
ALTER TABLE category_translation
RENAME COLUMN `ï»¿product_category_name` TO product_category_name;

SELECT CT.PRODUCT_CATEGORY_NAME_ENGLISH, ROUND(SUM(OI.PRICE),2) AS TOTAL_REVENUE, COUNT(DISTINCT O.ORDER_ID) AS TOTAL_ORDER
FROM ORDERS AS O
JOIN ORDER_ITEMS AS OI ON O.ORDER_ID = OI.ORDER_ID
JOIN PRODUCTS AS PR ON OI.PRODUCT_ID = PR.PRODUCT_ID
JOIN CATEGORY_TRANSLATION AS CT ON PR.PRODUCT_CATEGORY_NAME = CT.PRODUCT_CATEGORY_NAME
GROUP BY PRODUCT_CATEGORY_NAME_ENGLISH
ORDER BY TOTAL_REVENUE desc
LIMIT 10;

SELECT t.product_category_name_english AS category, ROUND(SUM(oi.price), 2) AS revenue, COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN category_translation t ON p.product_category_name = t.product_category_name
WHERE order_status = 'delivered'
GROUP BY product_category_name_english
ORDER BY revenue DESC
LIMIT 10;

-- delivery performance-- --This line calculates what percentage of orders were late--
SELECT ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS avg_delivery_days,
       ROUND(100 * SUM(order_delivered_customer_date > order_estimated_delivery_date) / COUNT(*), 1) AS pct_late
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date <> '';
  
  -- delivery days --
  SELECT order_id,
       order_purchase_timestamp,
       order_delivered_customer_date,
       DATEDIFF(order_delivered_customer_date, order_purchase_timestamp) AS delivery_days
FROM orders
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date <> ''
LIMIT 10;

-- compares review scores for on-time and late orders.--
SELECT * FROM ORDER_REVIEWS LIMIT 10;
SELECT * FROM ORDERS LIMIT 10;

SELECT CASE WHEN O.order_delivered_customer_date > O.order_estimated_delivery_date 
            THEN 'LATE' ELSE 'ON-TIME' END AS DELIVERY_STATUS,
COUNT(*) AS TOTAL_REVIEWS,
ROUND(AVG(OE.REVIEW_SCORE),1) AS AVG_REVIEW_SCORE
FROM ORDERS AS O
JOIN ORDER_REVIEWS AS OE ON O.ORDER_ID = OE.ORDER_ID
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date <> ''
GROUP BY DELIVERY_STATUS;

-- PAYMENT METHOD--
SELECT PAYMENT_TYPE,
       COUNT(DISTINCT ORDER_ID) AS TOTAL_ORDERS,
       ROUND(SUM(PAYMENT_VALUE), 2) AS TOTAL_VALUE
FROM ORDER_PAYMENTS
GROUP BY PAYMENT_TYPE
ORDER BY TOTAL_ORDERS DESC;

WITH customer_orders AS (
  SELECT c.customer_unique_id,
         COUNT(DISTINCT o.order_id) AS order_count
  FROM orders o
  JOIN customers c ON o.customer_id = c.customer_id
  WHERE o.order_status = 'delivered'
  GROUP BY c.customer_unique_id
)
SELECT COUNT(*) AS total_customers,
       SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
       ROUND(100 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_repeat
FROM customer_orders;

SELECT c.customer_unique_id,
       COUNT(DISTINCT o.order_id) AS order_count
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY order_count DESC;

SELECT VERSION();

SELECT ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
WHERE p.product_category_name = 'cama_mesa_banho'
  AND oi.order_id IN (SELECT order_id FROM orders WHERE order_status = 'delivered');