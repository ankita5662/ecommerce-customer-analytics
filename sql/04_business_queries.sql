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

