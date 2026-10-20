-- =========================================================
-- ORDER / PRODUCT STORED PROCEDURES
-- Database: change to your database name
-- Tables expected:
-- orders(orderid, clean_orderdate, customername, country, state, city,
--        region, segment, shipmode)
-- products(product_id, product, model, category, `Sub-Category`)
-- order_product(orderid, product_id, sales, quantity, discount, feedback)
-- =========================================================

-- Run this only if clean_orderdate is currently stored as VARCHAR.
UPDATE orders
SET clean_orderdate = STR_TO_DATE(clean_orderdate, '%d/%m/%Y');

ALTER TABLE orders MODIFY COLUMN clean_orderdate DATE;

DROP PROCEDURE IF EXISTS view_orders;
DROP PROCEDURE IF EXISTS update_model;
DROP PROCEDURE IF EXISTS orders_by_country;
DROP PROCEDURE IF EXISTS orders_by_segment;
DROP PROCEDURE IF EXISTS sales_by_product;
DROP PROCEDURE IF EXISTS sales_by_category;
DROP PROCEDURE IF EXISTS shipmode_summary;
DROP PROCEDURE IF EXISTS customer_orders;
DROP PROCEDURE IF EXISTS product_performance;
DROP PROCEDURE IF EXISTS feedback_summary;

DELIMITER //

-- 1. Date-wise order records
CREATE PROCEDURE view_orders(IN Sdate DATE, IN Edate DATE)
BEGIN
    SELECT *
    FROM orders
    WHERE clean_orderdate BETWEEN Sdate AND Edate
    ORDER BY clean_orderdate, orderid;
END //

-- 2. Update product model by product_id
CREATE PROCEDURE update_model(IN p_id INT, IN New_model VARCHAR(100))
BEGIN
    UPDATE products
    SET model = New_model
    WHERE product_id = p_id;

    SELECT *
    FROM products
    WHERE product_id = p_id;
END //

-- 3. Order count by country
CREATE PROCEDURE orders_by_country(IN p_country VARCHAR(100))
BEGIN
    SELECT country, COUNT(*) AS total_orders
    FROM orders
    WHERE country = p_country
    GROUP BY country;
END //

-- 4. Orders by customer segment
CREATE PROCEDURE orders_by_segment(IN p_segment VARCHAR(100))
BEGIN
    SELECT segment, COUNT(*) AS total_orders
    FROM orders
    WHERE segment = p_segment
    GROUP BY segment;
END //

-- 5. Product sales between two dates
CREATE PROCEDURE sales_by_product(IN Sdate DATE, IN Edate DATE)
BEGIN
    SELECT
        op.product_id,
        p.product,
        p.model,
        SUM(op.sales) AS total_sales,
        SUM(op.quantity) AS total_quantity,
        ROUND(AVG(op.discount), 2) AS avg_discount
    FROM order_product op
    JOIN products p ON p.product_id = op.product_id
    JOIN orders o ON o.orderid = op.orderid
    WHERE o.clean_orderdate BETWEEN Sdate AND Edate
    GROUP BY op.product_id, p.product, p.model
    ORDER BY total_sales DESC;
END //

-- 6. Sales by category
CREATE PROCEDURE sales_by_category(IN Sdate DATE, IN Edate DATE)
BEGIN
    SELECT
        p.category,
        SUM(op.sales) AS total_sales,
        SUM(op.quantity) AS total_quantity
    FROM order_product op
    JOIN products p ON p.product_id = op.product_id
    JOIN orders o ON o.orderid = op.orderid
    WHERE o.clean_orderdate BETWEEN Sdate AND Edate
    GROUP BY p.category
    ORDER BY total_sales DESC;
END //

-- 7. Ship-mode summary
CREATE PROCEDURE shipmode_summary(IN Sdate DATE, IN Edate DATE)
BEGIN
    SELECT
        shipmode,
        COUNT(*) AS total_orders
    FROM orders
    WHERE clean_orderdate BETWEEN Sdate AND Edate
    GROUP BY shipmode
    ORDER BY total_orders DESC;
END //

-- 8. Search all orders for a customer
CREATE PROCEDURE customer_orders(IN p_customer VARCHAR(150))
BEGIN
    SELECT *
    FROM orders
    WHERE customername LIKE CONCAT('%', p_customer, '%')
    ORDER BY clean_orderdate DESC;
END //

-- 9. Product performance
CREATE PROCEDURE product_performance(IN p_id INT)
BEGIN
    SELECT
        p.product_id,
        p.product,
        p.model,
        p.category,
        p.`Sub-Category`,
        COALESCE(SUM(op.sales), 0) AS total_sales,
        COALESCE(SUM(op.quantity), 0) AS total_quantity,
        ROUND(COALESCE(AVG(op.discount), 0), 2) AS avg_discount,
        COALESCE(SUM(CASE WHEN op.feedback = TRUE THEN 1 ELSE 0 END), 0) AS positive_feedback,
        COALESCE(SUM(CASE WHEN op.feedback = FALSE THEN 1 ELSE 0 END), 0) AS negative_feedback
    FROM products p
    LEFT JOIN order_product op ON op.product_id = p.product_id
    WHERE p.product_id = p_id
    GROUP BY p.product_id, p.product, p.model, p.category, p.`Sub-Category`;
END //

-- 10. Feedback summary
CREATE PROCEDURE feedback_summary(IN Sdate DATE, IN Edate DATE)
BEGIN
    SELECT
        op.feedback,
        COUNT(*) AS feedback_count
    FROM order_product op
    JOIN orders o ON o.orderid = op.orderid
    WHERE o.clean_orderdate BETWEEN Sdate AND Edate
    GROUP BY op.feedback;
END //

DELIMITER ;

-- Example calls:
-- CALL view_orders('2011-01-01', '2011-01-10');
-- CALL update_model(1, 'Recycled');
-- CALL orders_by_country('Germany');
-- CALL orders_by_segment('Consumer');
-- CALL sales_by_product('2011-01-01', '2013-12-31');
-- CALL sales_by_category('2011-01-01', '2013-12-31');
-- CALL shipmode_summary('2011-01-01', '2013-12-31');
-- CALL customer_orders('Ruby');
-- CALL product_performance(1);
-- CALL feedback_summary('2011-01-01', '2013-12-31');