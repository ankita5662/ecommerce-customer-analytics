-- 02_load_data.sql
-- Loads the Olist CSV files into the tables (files kept in C:/data)
-- Note: the CSVs use '\n' line endings; blank values are converted to NULL

USE olist;

TRUNCATE TABLE customers;
LOAD DATA LOCAL INFILE 'C:/data/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

TRUNCATE TABLE sellers;
LOAD DATA LOCAL INFILE 'C:/data/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

TRUNCATE TABLE product_category_translation;
LOAD DATA LOCAL INFILE 'C:/data/product_category_name_translation.csv'
INTO TABLE product_category_translation
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

TRUNCATE TABLE products;
LOAD DATA LOCAL INFILE 'C:/data/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_category_name, @a, @b, @c, @d, @e, @f, @g)
SET product_name_lenght        = NULLIF(@a,''),
    product_description_lenght = NULLIF(@b,''),
    product_photos_qty         = NULLIF(@c,''),
    product_weight_g           = NULLIF(@d,''),
    product_length_cm          = NULLIF(@e,''),
    product_height_cm          = NULLIF(@f,''),
    product_width_cm           = NULLIF(@g,'');

TRUNCATE TABLE orders;
LOAD DATA LOCAL INFILE 'C:/data/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, @p, @a, @c, @d, @e)
SET order_purchase_timestamp      = NULLIF(@p,''),
    order_approved_at             = NULLIF(@a,''),
    order_delivered_carrier_date  = NULLIF(@c,''),
    order_delivered_customer_date = NULLIF(@d,''),
    order_estimated_delivery_date = NULLIF(@e,'');

TRUNCATE TABLE order_items;
LOAD DATA LOCAL INFILE 'C:/data/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

TRUNCATE TABLE order_payments;
LOAD DATA LOCAL INFILE 'C:/data/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

TRUNCATE TABLE order_reviews;
LOAD DATA LOCAL INFILE 'C:/data/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Validation: row counts (expected: customers 99441, sellers 3095, products 32951,
-- translation 71, orders 99441, order_items 112650, order_payments 103886, order_reviews ~99223)
SELECT 'customers' AS tbl, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'translation', COUNT(*) FROM product_category_translation
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews;
