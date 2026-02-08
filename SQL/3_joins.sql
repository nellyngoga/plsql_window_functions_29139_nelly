-- Part A: SQL JOINs Implementation
-- 4.1 INNER JOIN
-- Retrieve transactions with valid customers and products

SELECT
    t.transaction_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.region,
    p.product_name,
    p.category,
    t.quantity,
    t.total_amount,
    t.transaction_date
FROM transactions t
INNER JOIN customers c ON t.customer_id = c.customer_id
INNER JOIN products p  ON t.product_id  = p.product_id
ORDER BY t.transaction_date DESC;

-- 4.2 LEFT JOIN
-- Identify customers who have never made a transaction

SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    c.region,
    c.join_date,
    COUNT(t.transaction_id)          AS total_transactions,
    COALESCE(SUM(t.total_amount), 0) AS total_spent
FROM customers c
LEFT JOIN transactions t ON c.customer_id = t.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.region, c.join_date
ORDER BY total_transactions ASC, c.join_date ASC;



-- 4.3 RIGHT JOIN
-- Detect products with no sales activity

SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price,
    p.stock_quantity,
    COUNT(t.transaction_id)          AS times_sold,
    COALESCE(SUM(t.total_amount), 0) AS total_revenue
FROM transactions t
RIGHT JOIN products p ON t.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category, p.unit_price, p.stock_quantity
ORDER BY times_sold ASC;


-- 4.4 FULL OUTER JOIN
-- Show all customers and all transactions, including unmatched

SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.region,
    t.transaction_id,
    t.total_amount,
    t.transaction_date,
    CASE
        WHEN t.transaction_id IS NULL THEN 'No transactions'
        ELSE 'Has transactions'
    END AS status
FROM customers c
FULL OUTER JOIN transactions t ON c.customer_id = t.customer_id
ORDER BY c.customer_id, t.transaction_date;



-- 4.5 SELF JOIN
-- Compare customers registered in the same region

SELECT
    c1.first_name || ' ' || c1.last_name AS customer_1,
    c2.first_name || ' ' || c2.last_name AS customer_2,
    c1.region,
    c1.join_date AS customer_1_join_date,
    c2.join_date AS customer_2_join_date,
    c2.join_date - c1.join_date AS days_apart
FROM customers c1
INNER JOIN customers c2
    ON c1.region = c2.region
    AND c1.customer_id < c2.customer_id
ORDER BY c1.region, days_apart DESC;
