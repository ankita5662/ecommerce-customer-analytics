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
