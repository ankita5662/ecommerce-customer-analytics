-- Checks run on the Olist data after loading, with what each one found

USE olist;

-- 1. Date range of orders
SELECT MIN(order_purchase_timestamp) AS first_order,
       MAX(order_purchase_timestamp) AS last_order
FROM orders;

-- 2. Order status breakdown (96,478 of 99,441 orders are delivered)
SELECT order_status, COUNT(*) AS orders
FROM orders
GROUP BY order_status
ORDER BY orders DESC;

-- 3. Customer IDs vs real people (99,441 IDs, 96,096 unique people)
SELECT COUNT(*) AS customer_ids,
       COUNT(DISTINCT customer_unique_id) AS unique_people
FROM customers;

-- 4. Orders with no items (775) and no payment (1)
SELECT COUNT(*) FROM orders
WHERE order_id NOT IN (SELECT order_id FROM order_items);

SELECT COUNT(*) FROM orders
WHERE order_id NOT IN (SELECT order_id FROM order_payments);

-- 5. Delivered orders with no delivery date (8)
SELECT COUNT(*) AS delivered_but_no_date
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- 6. Duplicate reviews: 99,223 rows, 98,409 distinct review IDs, 98,672 orders reviewed
SELECT COUNT(*) AS total_reviews,
       COUNT(DISTINCT review_id) AS distinct_review_ids,
       COUNT(DISTINCT order_id) AS orders_reviewed
FROM order_reviews;

-- Clean view: keep the latest answered review per order
CREATE VIEW order_reviews_clean AS
SELECT review_id, order_id, review_score, review_comment_title,
       review_comment_message, review_creation_date, review_answer_timestamp
FROM (
  SELECT r.*,
         ROW_NUMBER() OVER (
           PARTITION BY order_id
           ORDER BY review_answer_timestamp DESC, review_id
         ) AS rn
  FROM order_reviews r
) t
WHERE rn = 1;

-- 7. Payments include shipping: total paid 16.01M vs price + freight 15.84M vs price only 13.59M
SELECT
  (SELECT ROUND(SUM(payment_value), 2) FROM order_payments)      AS total_paid,
  (SELECT ROUND(SUM(price), 2) FROM order_items)                  AS total_price,
  (SELECT ROUND(SUM(freight_value), 2) FROM order_items)          AS total_shipping,
  (SELECT ROUND(SUM(price + freight_value), 2) FROM order_items)  AS price_plus_shipping;
