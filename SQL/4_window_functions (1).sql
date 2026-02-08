
-- Part B: Window Functions Implementation

-- 5.1 RANKING FUNCTIONS

-- 5.1.1 ROW_NUMBER() - Sequential ranking of products by revenue
SELECT
    ROW_NUMBER() OVER (ORDER BY SUM(t.total_amount) DESC) AS row_num,
    p.product_name,
    p.category,
    SUM(t.total_amount) AS total_revenue,
    COUNT(t.transaction_id) AS times_sold
FROM products p
INNER JOIN transactions t ON p.product_id = t.product_id
GROUP BY p.product_name, p.category
ORDER BY row_num;


-- 5.1.2 RANK() & DENSE_RANK() - Top 5 products per region
SELECT * FROM (
    SELECT
        c.region,
        p.product_name,
        SUM(t.total_amount) AS region_revenue,
        RANK()       OVER (PARTITION BY c.region ORDER BY SUM(t.total_amount) DESC) AS rank_pos,
        DENSE_RANK() OVER (PARTITION BY c.region ORDER BY SUM(t.total_amount) DESC) AS dense_rank_pos
    FROM transactions t
    INNER JOIN customers c ON t.customer_id = c.customer_id
    INNER JOIN products p  ON t.product_id  = p.product_id
    GROUP BY c.region, p.product_name
) ranked
WHERE rank_pos <= 5
ORDER BY region, rank_pos;


-- 5.1.3 PERCENT_RANK() - Relative product standing
SELECT
    p.product_name,
    SUM(t.total_amount) AS total_revenue,
    PERCENT_RANK() OVER (ORDER BY SUM(t.total_amount) DESC) AS pct_rank
FROM products p
INNER JOIN transactions t ON p.product_id = t.product_id
GROUP BY p.product_name
ORDER BY pct_rank;

-- 5.2 AGGREGATE WINDOW FUNCTIONS

-- 5.2.1 SUM() OVER() with ROWS frame - Running monthly sales total
SELECT
    TO_CHAR(transaction_date, 'YYYY-MM') AS sale_month,
    SUM(total_amount) AS monthly_revenue,
    SUM(SUM(total_amount)) OVER (
        ORDER BY TO_CHAR(transaction_date, 'YYYY-MM')
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM transactions
GROUP BY TO_CHAR(transaction_date, 'YYYY-MM')
ORDER BY sale_month;


-- 5.2.2 AVG() OVER() with ROWS frame - 3-Month moving average
SELECT
    TO_CHAR(transaction_date, 'YYYY-MM') AS sale_month,
    SUM(total_amount) AS monthly_revenue,
    ROUND(AVG(SUM(total_amount)) OVER (
        ORDER BY TO_CHAR(transaction_date, 'YYYY-MM')
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3m
FROM transactions
GROUP BY TO_CHAR(transaction_date, 'YYYY-MM')
ORDER BY sale_month;


-- 5.2.3 MIN() / MAX() OVER() - Monthly revenue extremes by region
SELECT
    c.region,
    TO_CHAR(t.transaction_date, 'YYYY-MM') AS sale_month,
    SUM(t.total_amount) AS monthly_revenue,
    MIN(SUM(t.total_amount)) OVER (PARTITION BY c.region) AS region_min_month,
    MAX(SUM(t.total_amount)) OVER (PARTITION BY c.region) AS region_max_month
FROM transactions t
INNER JOIN customers c ON t.customer_id = c.customer_id
GROUP BY c.region, TO_CHAR(t.transaction_date, 'YYYY-MM')
ORDER BY c.region, sale_month;

-- 5.3 NAVIGATION FUNCTIONS

-- 5.3.1 LAG() - Month-over-month revenue growth
SELECT
    sale_month,
    monthly_revenue,
    LAG(monthly_revenue, 1) OVER (ORDER BY sale_month) AS prev_month_revenue,
    CASE
        WHEN LAG(monthly_revenue, 1) OVER (ORDER BY sale_month) IS NOT NULL THEN
            ROUND((
                (monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY sale_month))
                / LAG(monthly_revenue, 1) OVER (ORDER BY sale_month)
            ) * 100, 2)
        ELSE NULL
    END AS mom_growth_pct
FROM (
    SELECT
        TO_CHAR(transaction_date, 'YYYY-MM') AS sale_month,
        SUM(total_amount) AS monthly_revenue
    FROM transactions
    GROUP BY TO_CHAR(transaction_date, 'YYYY-MM')
) monthly_sales
ORDER BY sale_month;


-- 5.3.2 LEAD() - Forward-looking revenue projection
SELECT
    sale_month,
    monthly_revenue,
    LEAD(monthly_revenue, 1) OVER (ORDER BY sale_month) AS next_month_revenue,
    CASE
        WHEN LEAD(monthly_revenue, 1) OVER (ORDER BY sale_month) IS NOT NULL THEN
            ROUND((
                (LEAD(monthly_revenue, 1) OVER (ORDER BY sale_month) - monthly_revenue)
                / monthly_revenue
            ) * 100, 2)
        ELSE NULL
    END AS expected_change_pct
FROM (
    SELECT
        TO_CHAR(transaction_date, 'YYYY-MM') AS sale_month,
        SUM(total_amount) AS monthly_revenue
    FROM transactions
    GROUP BY TO_CHAR(transaction_date, 'YYYY-MM')
) monthly_sales
ORDER BY sale_month;

-- 5.4 DISTRIBUTION FUNCTIONS

-- 5.4.1 NTILE(4) - Customer spending quartile segmentation
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.region,
    COALESCE(SUM(t.total_amount), 0) AS total_spent,
    NTILE(4) OVER (ORDER BY COALESCE(SUM(t.total_amount), 0) DESC) AS spending_quartile,
    CASE NTILE(4) OVER (ORDER BY COALESCE(SUM(t.total_amount), 0) DESC)
        WHEN 1 THEN 'Platinum (Top 25%)'
        WHEN 2 THEN 'Gold (25-50%)'
        WHEN 3 THEN 'Silver (50-75%)'
        WHEN 4 THEN 'Bronze (Bottom 25%)'
    END AS segment_label
FROM customers c
LEFT JOIN transactions t ON c.customer_id = t.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.region
ORDER BY total_spent DESC;


-- 5.4.2 CUME_DIST() - Cumulative distribution of customer spending
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    COALESCE(SUM(t.total_amount), 0) AS total_spent,
    ROUND(CUME_DIST() OVER (
        ORDER BY COALESCE(SUM(t.total_amount), 0)
    )::NUMERIC, 4) AS cumulative_dist
FROM customers c
LEFT JOIN transactions t ON c.customer_id = t.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent;
