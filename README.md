# Individual Assignment I: SQL JOINs & Window Functions

**Course:** INSY 8311: Database Development with PL/SQL  
**Instructor:** Eric Maniraguha  
**Name:** Nelly Ngoga Urujeni 
** ID:** 29139 
**Group:** A
**DBMS:** PostgreSQL  


## 1. Business Problem Definition

### Business Context
GreenLeaf Organics is a mid-sized e-commerce retail company headquartered in Kigali, Rwanda, specializing in organic food products. The company operates across four geographic regions (North, South, East, West) and serves over 2,000 active customers through its online platform. The Sales and Marketing department needs data-driven insights to optimize revenue, improve customer retention, and streamline regional product distribution.

### Data Challenge
The company currently lacks visibility into which products are performing best in each region, how customer purchasing behavior varies over time, and which customer segments contribute most to total revenue. Without running totals, month-over-month growth analysis, and customer segmentation, the marketing team cannot allocate budgets effectively or design targeted promotional campaigns. Additionally, inactive customers and underperforming products remain undetected, leading to inventory waste and missed re-engagement opportunities.

### Expected Outcome
By implementing SQL JOINs and window function analytics, the company will identify top-performing products per region, track cumulative revenue trends, measure month-over-month sales growth, segment customers into spending quartiles for targeted marketing, and compute three-month moving averages to detect seasonal patterns. These insights will directly inform Q1 2026 marketing budget allocation and regional inventory planning.

---

## 2. Success Criteria

| # | Success Criterion | Window Function | Measurement |
|---|-------------------|-----------------|-------------|
| 1 | Identify top 5 products per region by quarterly revenue | RANK() / DENSE_RANK() | Ranked product list per region |
| 2 | Calculate running monthly sales totals for trend analysis | SUM() OVER(ORDER BY month) | Cumulative revenue curve per month |
| 3 | Measure month-over-month revenue growth rate | LAG() / LEAD() | Percentage change between consecutive months |
| 4 | Segment customers into spending quartiles | NTILE(4) | Four equal customer groups by total spend |
| 5 | Compute 3-month moving averages for seasonal smoothing | AVG() OVER(ROWS 2 PRECEDING) | Smoothed revenue trend line |

---

## 3. Database Schema Design

### ER Diagram

*The ER diagram is included in the `screenshots/` folder as `ERD_Diagram.JPG`.*


### Table: customers
| Column | Data Type | Constraint | Description |
|--------|-----------|------------|-------------|
| customer_id | SERIAL | PRIMARY KEY | Unique customer identifier |
| first_name | VARCHAR(50) | NOT NULL | Customer first name |
| last_name | VARCHAR(50) | NOT NULL | Customer last name |
| email | VARCHAR(100) | UNIQUE, NOT NULL | Customer email address |
| region | VARCHAR(20) | NOT NULL, FK → regions | Geographic region |
| join_date | DATE | NOT NULL | Date customer registered |

### Table: products
| Column | Data Type | Constraint | Description |
|--------|-----------|------------|-------------|
| product_id | SERIAL | PRIMARY KEY | Unique product identifier |
| product_name | VARCHAR(100) | NOT NULL | Name of the product |
| category | VARCHAR(50) | NOT NULL | Product category |
| unit_price | DECIMAL(10,2) | NOT NULL | Price per unit in RWF |
| stock_quantity | INTEGER | DEFAULT 0 | Current inventory count |

### Table: transactions
| Column | Data Type | Constraint | Description |
|--------|-----------|------------|-------------|
| transaction_id | SERIAL | PRIMARY KEY | Unique transaction identifier |
| customer_id | INTEGER | FK → customers | References the buying customer |
| product_id | INTEGER | FK → products | References the purchased product |
| quantity | INTEGER | NOT NULL | Units purchased |
| total_amount | DECIMAL(12,2) | NOT NULL | Total transaction value |
| transaction_date | DATE | NOT NULL | Date of purchase |

### Table: regions
| Column | Data Type | Constraint | Description |
|--------|-----------|------------|-------------|
| region_id | SERIAL | PRIMARY KEY | Unique region identifier |
| region_name | VARCHAR(20) | UNIQUE, NOT NULL | Region name |
| region_manager | VARCHAR(100) | NOT NULL | Regional manager name |

---

## 4. Part A: SQL JOINs Implementation

### 4.1 INNER JOIN: Transactions with Customer and Product Details

```sql
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
```


**Business Interpretation:**  
The INNER JOIN returns only rows where matching records exist in all three tables. All 26 transactions are returned because every transaction references a valid customer and product. This query provides the foundational data view for business reporting, showing that customers across all four regions are actively purchasing across multiple product categories.

---

### 4.2 LEFT JOIN: Customers with No Transactions

```sql
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
```


**Business Interpretation:**  
The LEFT JOIN reveals that Kevin Ndayisaba and Liliane Mukeshimana have zero transactions despite being registered customers. Both are in the West region, which suggests a possible onboarding issue or lack of product availability in that area. These two customers should be targeted with welcome discount campaigns to convert them from dormant to active buyers.

---

### 4.3 RIGHT JOIN: Products with No Sales Activity

```sql
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
```


**Business Interpretation:**  
The RIGHT JOIN identifies Baobab Powder and Shea Butter as products with zero sales and zero stock. These items were added to the catalog but never stocked or sold, representing potential new product launches that stalled. The company should decide whether to properly launch these products with marketing support or remove them from the catalog.

---

### 4.4 FULL OUTER JOIN: Customers and Transactions with Status

```sql
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
```


**Business Interpretation:**  
The FULL OUTER JOIN provides a complete view of all customers and all transactions, including unmatched records on both sides. Kevin and Liliane appear with NULL transaction fields and a status of "No transactions," confirming they are dormant. This unified view is essential for gap analysis, allowing the marketing team to quickly identify which customers need activation campaigns.

---

### 4.5 SELF JOIN: Customers in the Same Region by Join Date

```sql
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
```


**Business Interpretation:**  
The SELF JOIN pairs every customer with their regional peers to compare registration timelines. In the East region, Grace Tumukunde and Irene Umutoni joined 158 days apart, while the West region shows the widest gap between Jules Habiyaremye and Liliane Mukeshimana. This helps identify whether onboarding waves correlate with marketing campaigns and whether newer customers in each region are being effectively engaged.

---

## 5. Part B: Window Functions Implementation

### 5.1 Ranking Functions

#### 5.1.1 ROW_NUMBER(): Sequential Product Ranking by Revenue

```sql
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
```


**Business Interpretation:**  
ROW_NUMBER() assigns each product a unique rank regardless of ties. Organic Honey is the top seller, confirming it as the company's flagship product that should receive priority in inventory restocking and marketing investment.

---

#### 5.1.2 RANK() & DENSE_RANK(): Top 5 Products per Region

```sql
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
```


**Business Interpretation:**  
RANK() and DENSE_RANK() reveal regional product preferences. Organic Honey dominates in multiple regions, confirming its universal appeal. DENSE_RANK() avoids gaps in the ranking when ties exist, making it easier to count how many distinct revenue tiers exist per region.

---

#### 5.1.3 PERCENT_RANK(): Relative Product Standing

```sql
SELECT
    p.product_name,
    SUM(t.total_amount) AS total_revenue,
    PERCENT_RANK() OVER (ORDER BY SUM(t.total_amount) DESC) AS pct_rank
FROM products p
INNER JOIN transactions t ON p.product_id = t.product_id
GROUP BY p.product_name
ORDER BY pct_rank;
```


**Business Interpretation:**  
PERCENT_RANK() shows each product's relative position as a percentile. The top products generate a disproportionate share of revenue, suggesting a Pareto-like distribution that the company can leverage for focused marketing efforts on high performers.

---

### 5.2 Aggregate Window Functions

#### 5.2.1 SUM() OVER() with ROWS Frame: Running Monthly Sales Total

```sql
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
```


**Business Interpretation:**  
The running total shows cumulative revenue growing across the three-month period (Nov 2025 to Jan 2026). The ROWS frame ensures exact row-level accumulation. This view helps management track progress toward quarterly revenue targets and identify which months contributed the most to overall growth.

---

#### 5.2.2 AVG() OVER() with ROWS Frame: 3-Month Moving Average

```sql
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
```


**Business Interpretation:**  
The 3-month moving average smooths out monthly volatility to reveal underlying trends. This smoothed view helps the company set realistic monthly targets and distinguish genuine trend shifts from one-time spikes or dips.

---

#### 5.2.3 MIN() / MAX() OVER(): Monthly Revenue Extremes by Region

```sql
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
```


**Business Interpretation:**  
MIN() and MAX() OVER() with PARTITION BY region reveals the performance range in each region. Regions with wide ranges indicate inconsistent monthly sales, helping regional managers set realistic targets and plan promotional activities for low-revenue months.

---

### 5.3 Navigation Functions

#### 5.3.1 LAG(): Month-over-Month Revenue Growth

```sql
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
```


**Business Interpretation:**  
LAG() compares each month's revenue to the previous month, calculating the percentage change. This reveals whether the business is growing or contracting month-over-month. Significant drops signal the need for promotional intervention, while growth months validate current strategies.

---

#### 5.3.2 LEAD(): Forward-Looking Revenue Projection

```sql
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
```


**Business Interpretation:**  
LEAD() provides a forward-looking perspective that complements LAG(). By showing what the next month's revenue will be, this view helps operations teams prepare for demand changes. The NULL for the last month confirms it is the most recent complete month in the dataset.

---

### 5.4 Distribution Functions

#### 5.4.1 NTILE(4): Customer Spending Quartile Segmentation

```sql
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
```


**Business Interpretation:**  
NTILE(4) segments all 12 customers into four equal quartiles. The Platinum tier customers collectively account for the largest share of total revenue. The Bronze tier includes the two inactive customers. This segmentation directly supports differentiated marketing: Platinum customers should receive VIP perks, while Bronze customers need win-back or activation campaigns.

---

#### 5.4.2 CUME_DIST(): Cumulative Distribution of Customer Spending

```sql
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
```


**Business Interpretation:**  
CUME_DIST() shows what percentage of customers spend at or below each level. This distribution curve helps set threshold-based discount tiers: for example, the company could offer a 10% discount to customers who reach the 75th percentile to incentivize higher spending.

---

## 6. Results Analysis

### 6.1 Descriptive Analysis: What Happened?
Over the three-month analysis period (November 2025 to January 2026), GreenLeaf Organics processed 26 transactions across 10 active customers out of 12 registered. Organic Honey 500g dominated product performance as the top seller, while two products (Baobab Powder and Shea Butter) recorded zero sales. Revenue distribution was uneven across regions, with the East and West regions showing strong individual customer contributions. Two customers in the West region remained completely dormant with no purchase activity.

### 6.2 Diagnostic Analysis: Why Did It Happen?
The revenue concentration in Organic Honey reflects both the product's universal appeal across regions and its favorable price point (8,500 RWF), which balances accessibility with margin. The two unsold products have zero stock quantity, indicating they were listed in the catalog but never procured for inventory. The West region's high dormancy rate correlates with the two most recent customer registrations (September and October 2025), suggesting these customers joined during a period when onboarding and engagement workflows may have been insufficient.

### 6.3 Prescriptive Analysis: What Should Be Done Next?

| Priority | Action | Expected Impact | Evidence |
|----------|--------|-----------------|----------|
| High | Launch customer activation campaign for Kevin and Liliane in West region with 20% welcome discount | Convert 2 dormant customers to active buyers | LEFT JOIN + NTILE(4) identified inactive Bronze-tier customers |
| High | Implement monthly subscription box for Organic Honey and Green Tea (top 2 products) | Stabilize month-over-month revenue volatility | LAG() growth analysis + SUM() OVER() running totals |
| Medium | Decision on Baobab Powder and Shea Butter: stock and promote, or remove from catalog | Eliminate dead SKUs or unlock new revenue stream | RIGHT JOIN identified zero-sale products |
| Medium | Create Platinum loyalty rewards program for top-quartile customers | Increase retention of highest-revenue customers | NTILE(4) segmentation + CUME_DIST() |
| Low | Adjust inventory levels using 3-month moving averages to predict demand | Reduce overstock by 15% and stockouts by 25% | AVG() OVER(ROWS 2 PRECEDING) moving average |

---

## 7. Key Insights Summary

| # | Insight | Evidence Source |
|---|---------|-----------------|
| 1 | Organic Honey is the top-revenue product across multiple regions | ROW_NUMBER() + RANK() product rankings |
| 2 | 16.7% of customers (2 of 12) are completely dormant with zero transactions | LEFT JOIN customer analysis |
| 3 | Two products are listed but never stocked or sold, representing catalog inefficiency | RIGHT JOIN + FULL OUTER JOIN |
| 4 | Top 25% of customers (Platinum tier) generate a disproportionate share of total revenue | NTILE(4) customer segmentation |
| 5 | Month-over-month revenue shows volatility that could be smoothed with subscriptions | LAG() period comparison |
| 6 | The 3-month moving average provides a more stable demand forecast than raw monthly figures | AVG() OVER(ROWS 2 PRECEDING) |
| 7 | Regional performance ranges vary widely, requiring region-specific strategies | MIN/MAX OVER() + SELF JOIN |
| 8 | West region has the highest customer inactivity rate at 66% (2 of 3 dormant) | LEFT JOIN + FULL OUTER JOIN |

---

## 8. References

1. PostgreSQL Documentation. (2025). "Window Functions." PostgreSQL 16 Official Documentation. https://www.postgresql.org/docs/16/tutorial-window.html
2. PostgreSQL Documentation. (2025). "Queries: JOINs." PostgreSQL 16 Official Documentation. https://www.postgresql.org/docs/16/queries-table-expressions.html
3. Oracle Corporation. (2025). "SQL/PL SQL Window (Analytic) Functions." Oracle Database SQL Language Reference. https://docs.oracle.com/en/database/oracle/oracle-database/
4. Korth, H., Silberschatz, A., & Sudarshan, S. (2019). *Database System Concepts* (7th ed.). McGraw-Hill Education.
5. Beaulieu, A. (2020). *Learning SQL: Generate, Manipulate, and Retrieve Data* (3rd ed.). O'Reilly Media.
6. W3Schools. (2025). "SQL Window Functions Tutorial." https://www.w3schools.com/sql/sql_ref_sqlserver.asp
7. GeeksforGeeks. (2025). "Window Functions in SQL." https://www.geeksforgeeks.org/window-functions-in-sql/


---

## 9. Integrity Statement

> "All sources were properly cited. Implementations and analysis represent original work. No AI-generated content was copied without attribution or adaptation."

I hereby confirm that this assignment is my own original work. All SQL queries were written, tested, and debugged independently. The business scenario, data analysis, and interpretations reflect my personal understanding of the concepts taught in INSY 8311.

