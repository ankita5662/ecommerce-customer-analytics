-- Rule used throughout: only delivered orders count as completed sales.
-- Revenue = total payment value, which includes shipping fees. Currency: Brazilian reais.

USE olist;

-- Q1. How much revenue did the business make, and from how many orders?
-- Result: 96,477 orders, 15,422,461.77 reais
-- (1 delivered order has no payment record, so the join drops it: 96,478 -> 96,477)
SELECT COUNT(DISTINCT o.order_id) AS orders,
       SUM(p.payment_value) AS total_revenue
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered';

-- Q2. How did revenue, orders and average order value change month by month?
-- Findings:
--   * Late 2016 is unusable (265 orders in Oct, none in Nov, 1 order in Dec).
--   * 2017: orders grew from 750 (Jan) to 7,289 (Nov), the peak month.
--   * 2018: orders stayed flat at roughly 6,100-7,100 a month.
--   * Average order value stayed between about 146 and 176 reais, so growth
--     came from more orders, not bigger orders.
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
       COUNT(DISTINCT o.order_id) AS orders,
       SUM(p.payment_value) AS revenue,
       ROUND(SUM(p.payment_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;
-- Q3. show the top 5 states by number of delivered orders.
--findings:
-- Top 5 states by delivered orders: 77% of the total, SP about 42%.
SELECT c.customer_state AS Top_states , COUNT(DISTINCT o.order_id) AS Top_orders
FROM customers c INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE order_status = 'delivered'
GROUP BY customer_state
ORDER BY Top_orders DESC LIMIT 5;
-- Q4. find the average review score for each order status.
-- Findings:
---Delivered orders make up 97% of reviews and average 4.16 stars, while every other status averages 2.0 or below. 
---The small group of orders that don't complete is where the unhappy customers are.
SELECT AVG(review_score) AS avg_review , o.order_status, COUNT(*) AS reviews
FROM order_reviews_clean
LEFT JOIN orders o ON order_reviews_clean.order_id = o.order_id
GROUP BY o.order_status ORDER BY avg_review DESC;
-- Q5. find the average number of days from purchase to delivery, for delivered orders only.
-- Findings:
-- Average days from purchase to delivery takes about 12.5 days/ roughly 2 weeks to reach cutsomers (delivered orders only)
SELECT AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp))
FROM orders o 
WHERE order_status = 'delivered' 
AND order_delivered_customer_date IS NOT NULL;
--Q6. How many delivered orders arrived later than the estimated delivery date?
-- Findings:
--- 6534 Delivered orders arrived after the estimated date (day-level comparison).
SELECT COUNT(*) AS late_orders
FROM orders o
WHERE DATE(order_estimated_delivery_date) < DATE(order_delivered_customer_date) 
AND order_status = 'delivered' 
AND order_delivered_customer_date IS NOT NULL;
-- Q7. Do late deliveries get lower review scores?
-- Result: on time 4.29 stars (89,442 reviews), late 2.27 stars (6,381 reviews).
-- Late orders (about 7% of reviewed orders) score roughly 2 stars lower.
SELECT CASE WHEN DATE(o.order_estimated_delivery_date) < DATE(o.order_delivered_customer_date)
            THEN 'late' ELSE 'on time' END AS delivery_status,
       ROUND(AVG(r.review_score), 2) AS avg_score,
       COUNT(*) AS reviews
FROM orders o
JOIN order_reviews_clean r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;

-- Q8. Which 5 states have the most late deliveries (count)?
-- Result: SP 1,820 | RJ 1,495 | MG 519 | BA 396 | RS 325
-- SP tops the list mainly because it has the most orders (see Q9 for rates).
SELECT customer_state AS state,
       COUNT(DISTINCT o.order_id) AS late_orders
FROM customers c INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE DATE(o.order_estimated_delivery_date) < DATE(o.order_delivered_customer_date)
  AND o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY customer_state
ORDER BY late_orders DESC
LIMIT 5;

-- Q9. Which states have the highest late-delivery rate (states with 500+ delivered orders)?
-- Highest: MA 17.43% (717 orders), CE 13.76%, BA 12.16%, RJ 12.11% (12,350 orders).
-- RJ has far more late orders in total than MA, even though MA's rate is higher.
SELECT c.customer_state AS state,
       ROUND(100 * AVG(CASE WHEN DATE(o.order_estimated_delivery_date) < DATE(o.order_delivered_customer_date)
                            THEN 1 ELSE 0 END), 2) AS late_pct,
       COUNT(*) AS orders
FROM customers c INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY state
HAVING COUNT(*) >= 500
ORDER BY late_pct DESC
LIMIT 10;
-- Q10. Which product categories earn the most revenue (delivered orders)?
-- Revenue = sum of item prices (excludes shipping), so it differs from the payment-based total in Q1.
-- Top 3: health_beauty 1.23M, watches_gifts 1.17M, bed_bath_table 1.02M (reais).
-- bed_bath_table has the most orders (9,272) but ranks 3rd in revenue.
-- Note: products with no category or no English translation drop out of the joins.
SELECT t.product_category_name_english AS category,
       ROUND(SUM(oi.price), 2) AS revenue,
       COUNT(DISTINCT oi.order_id) AS orders
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products pr ON oi.product_id = pr.product_id
JOIN product_category_translation t ON pr.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY revenue DESC
LIMIT 10;
-- Q11. How many customers placed more than one delivered order?
-- Result: 2,801 repeat customers.
SELECT COUNT(*) AS repeat_customers
FROM (
  SELECT c.customer_unique_id
  FROM customers c
  JOIN orders o ON o.customer_id = c.customer_id
  WHERE o.order_status = 'delivered'
  GROUP BY c.customer_unique_id
  HAVING COUNT(DISTINCT o.order_id) > 1
) AS repeat_list;
-- Q12. How many unique customers have at least one delivered order?
-- Result: 93,358. Repeat share = 2,801 / 93,358 = about 3.0%.
SELECT COUNT(DISTINCT c.customer_unique_id) AS total_customers
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered';
