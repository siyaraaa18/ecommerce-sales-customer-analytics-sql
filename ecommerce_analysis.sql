-- ============================================================
-- PROJECT  : E-Commerce Sales & Customer Analytics
-- Author   : Siyara Sathar
-- Tool     : MySQL
-- Dataset  : Online Retail II (UCI Machine Learning Repository)
-- Description: Analysis of 1M+ retail transactions from a
--              UK-based online store to uncover sales trends,
--              customer behavior and product performance insights
-- ============================================================

-- ============================================================
-- SECTION 1 : DATABASE SETUP
-- ============================================================

CREATE DATABASE IF NOT EXISTS ecommerce_db;
USE ecommerce_db;

-- ============================================================
-- SECTION 2 : TABLE CREATION
-- ============================================================

CREATE TABLE IF NOT EXISTS online_retail (
    invoice        VARCHAR(20),
    stock_code     VARCHAR(20),
    description    VARCHAR(255),
    quantity       INT,
    invoice_date   DATETIME,
    price          DECIMAL(10,2),
    customer_id    VARCHAR(20),
    country        VARCHAR(100)
);

-- ============================================================
-- SECTION 3 : DATA IMPORT
-- ============================================================

-- Loading first file (2009-2010 data)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/retail_2009.csv'
INTO TABLE online_retail
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(invoice, stock_code, description, quantity, @invoice_date, price, customer_id, country)
SET invoice_date = STR_TO_DATE(@invoice_date, '%d-%m-%Y %H:%i');

-- Loading second file (2010-2011 data)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/retail_2010.csv'
INTO TABLE online_retail
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(invoice, stock_code, description, quantity, @invoice_date, price, customer_id, country)
SET invoice_date = STR_TO_DATE(@invoice_date, '%d-%m-%Y %H:%i');

-- Verifying total row count after import
SELECT COUNT(*) AS total_rows FROM online_retail;
-- Result: 1,067,371 rows 

-- ============================================================
-- SECTION 4 : DATA CLEANING
-- ============================================================

-- ----------------------------------------
-- 4.1 Checking for NULL values
-- ----------------------------------------

SELECT
    COUNT(*) AS total_rows,
    COALESCE(SUM(CASE WHEN invoice IS NULL THEN 1 END), 0) AS null_invoice,
    COALESCE(SUM(CASE WHEN stock_code IS NULL THEN 1 END), 0) AS null_stock_code,
    COALESCE(SUM(CASE WHEN description IS NULL THEN 1 END), 0) AS null_description,
    COALESCE(SUM(CASE WHEN quantity IS NULL THEN 1 END), 0) AS null_quantity,
    COALESCE(SUM(CASE WHEN invoice_date IS NULL THEN 1 END), 0) AS null_invoice_date,
    COALESCE(SUM(CASE WHEN price IS NULL THEN 1 END), 0) AS null_price,
    COALESCE(SUM(CASE WHEN customer_id IS NULL THEN 1 END), 0) AS null_customer_id,
    COALESCE(SUM(CASE WHEN country IS NULL THEN 1 END), 0) AS null_country
FROM online_retail;
-- Result: No NULL values found in any column

-- ----------------------------------------
-- 4.2 Checking for empty strings
-- ----------------------------------------

SELECT
    COALESCE(SUM(CASE WHEN invoice = '' THEN 1 END), 0) AS empty_invoice,
    COALESCE(SUM(CASE WHEN stock_code = '' THEN 1 END), 0)  AS empty_stock_code,
    COALESCE(SUM(CASE WHEN description = '' THEN 1 END), 0) AS empty_description,
    COALESCE(SUM(CASE WHEN customer_id = '' THEN 1 END), 0) AS empty_customer_id,
    COALESCE(SUM(CASE WHEN country = '' THEN 1 END), 0) AS empty_country
FROM online_retail;
-- Result: empty_description = 4,382 | empty_customer_id = 243,007 (22.8%)

-- ----------------------------------------
-- 4.3 Checking for duplicate rows
-- ----------------------------------------

SELECT 
    invoice, stock_code, invoice_date, 
    quantity, price, customer_id,
    COUNT(*) AS duplicate_count
FROM online_retail
GROUP BY 
    invoice, stock_code, invoice_date,
    quantity, price, customer_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC
LIMIT 10;

-- Total number of duplicate rows
SELECT COUNT(*) AS total_duplicate_rows
FROM (
    SELECT 
        invoice, stock_code, invoice_date,
        quantity, price, customer_id,
        COUNT(*) AS duplicate_count
    FROM online_retail
    GROUP BY 
        invoice, stock_code, invoice_date,
        quantity, price, customer_id
    HAVING COUNT(*) > 1
) AS duplicates;

-- Result: 32,909 duplicate rows found

-- ----------------------------------------
-- 4.4 Checking cancellations
-- ----------------------------------------
-- Invoices starting with 'C' are cancellations

SELECT COUNT(*) AS total_cancellations
FROM online_retail
WHERE invoice LIKE 'C%';
-- Result: 19,494 cancellations found

-- ----------------------------------------
-- 4.5 Checking negative quantities
-- ----------------------------------------
SELECT COUNT(*) AS negative_quantity_rows
FROM online_retail
WHERE quantity < 0;
-- Result: 22,950 negative quantity rows found 

-- ----------------------------------------
-- 4.6 Checking zero or negative prices
-- ----------------------------------------
SELECT COUNT(*) AS bad_price_rows
FROM online_retail
WHERE price <= 0;
-- Result: 6,225 zero or negative price rows found

-- ----------------------------------------
-- 4.7 Creating clean table for analysis
-- ----------------------------------------
-- Based on findings from 4.1 to 4.6 the following
-- issues were identified and fixed:
--
-- Issue                    | Count   | Fix Applied
-- --------------------------------------------------------
-- Duplicate rows           | 32,909  | DISTINCT
-- Negative quantities      | 22,950  | quantity > 0
-- Zero/negative prices     | 6,225   | price > 0
-- Cancellation invoices    | 19,494  | invoice NOT LIKE 'C%'
-- Empty descriptions       | 4,382   | description != ''
-- Empty customer IDs       | 243,007 | NULLIF(customer_id,'')
-- Missing revenue column   | —       | quantity x price added
-- --------------------------------------------------------

CREATE TABLE online_retail_clean AS
SELECT DISTINCT
    invoice, stock_code,
    TRIM(description) AS description,
    quantity, invoice_date, price,
    NULLIF(customer_id, '') AS customer_id,
    country,
    ROUND(quantity * price, 2) AS revenue
FROM online_retail
WHERE quantity > 0
  AND price > 0
  AND invoice NOT LIKE 'C%'
  AND description != '';

-- Verify clean table
SELECT COUNT(*) AS clean_rows FROM online_retail_clean;
-- Result: 1,007,895 rows

-- Quick look at clean table
SELECT * FROM online_retail_clean LIMIT 10;

-- Verify no empty customer_ids remain as empty strings
SELECT COUNT(*) AS empty_customer_check 
FROM online_retail_clean 
WHERE customer_id = '';
-- Result: 0 

-- Verify no negative quantities remain
SELECT COUNT(*) AS negative_qty_check
FROM online_retail_clean
WHERE quantity < 0;
-- Result: 0

-- Verify no cancellations remain
SELECT COUNT(*) AS cancellation_check
FROM online_retail_clean
WHERE invoice LIKE 'C%';
-- Result: 0

-- ============================================================
-- SECTION 5 : EXPLORATORY DATA ANALYSIS (EDA)
-- ============================================================

-- ----------------------------------------
-- 5.1 Overall Business Summary
-- ----------------------------------------
-- Q: What is the overall performance of the store?

SELECT
    COUNT(DISTINCT invoice) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT stock_code) AS total_products,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(AVG(revenue), 2) AS avg_order_value,
    MIN(invoice_date) AS first_order_date,
    MAX(invoice_date) AS last_order_date
FROM online_retail_clean;
-- Result: 40,077 orders | 5,878 customers | £20,476,260 revenue

-- ----------------------------------------
-- 5.2 Revenue by Year
-- ----------------------------------------
-- Q: How did revenue grow year over year?

SELECT
    YEAR(invoice_date) AS year,
    COUNT(DISTINCT invoice) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(AVG(revenue), 2) AS avg_order_value
FROM online_retail_clean
GROUP BY YEAR(invoice_date)
ORDER BY year;

-- Result: 2010 £9.8M | 2011 £9.8M — stable revenue

-- ----------------------------------------
-- 5.3 Revenue by Month
-- ----------------------------------------
-- Q: Which months generate the most revenue?

SELECT
    YEAR(invoice_date) AS year,
    MONTH(invoice_date) AS month,
    MONTHNAME(invoice_date) AS month_name,
    COUNT(DISTINCT invoice) AS total_orders,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM online_retail_clean
GROUP BY 
    YEAR(invoice_date),
    MONTH(invoice_date),
    MONTHNAME(invoice_date)
ORDER BY year, month;

-- Result: November consistently highest | February lowest

-- ----------------------------------------
-- 5.4 Top 10 Products by Revenue
-- ----------------------------------------
-- Q: Which products drive the most revenue?

SELECT
    stock_code,
    description,
    COUNT(DISTINCT invoice) AS times_ordered,
    SUM(quantity) AS total_quantity_sold,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM online_retail_clean
GROUP BY stock_code, description
ORDER BY total_revenue DESC
LIMIT 10;

-- Result: Regency Cakestand £330K | White Hanging Heart £260K

-- ----------------------------------------
-- 5.5 Top 10 Products by Quantity Sold
-- ----------------------------------------
-- Q: Which products are most popular by volume?

SELECT
    stock_code,
    description,
    COUNT(DISTINCT invoice) AS times_ordered,
    SUM(quantity) AS total_quantity_sold,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(AVG(price), 2) AS avg_price
FROM online_retail_clean
GROUP BY stock_code, description
ORDER BY total_quantity_sold DESC
LIMIT 10;

-- Result: World War 2 Gliders 106K units | White Hanging Heart 94K units 

-- ----------------------------------------
-- 5.6 Revenue by Country
-- ----------------------------------------
-- Q: Which countries generate the most revenue?

SELECT
    country,
    COUNT(DISTINCT invoice) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(AVG(revenue), 2) AS avg_order_value
FROM online_retail_clean
GROUP BY country
ORDER BY total_revenue DESC
LIMIT 10;

-- Result: UK £17.4M (85%) | Netherlands highest avg order £108.96

-- ============================================================
-- SECTION 6 : CUSTOMER & RFM ANALYSIS
-- ============================================================

-- ----------------------------------------
-- 6.1 Top 10 Customers by Revenue
-- ----------------------------------------
-- Q: Who are our highest value customers?

SELECT
    customer_id,
    country,
    COUNT(DISTINCT invoice) AS total_orders,
    SUM(quantity) AS total_items_bought,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM online_retail_clean
WHERE customer_id IS NOT NULL
GROUP BY customer_id, country
ORDER BY total_revenue DESC
LIMIT 10;

-- Result: Customer 18102 (UK) top with £580,987 revenue

-- ----------------------------------------
-- 6.2 Repeat vs One-Time Customers
-- ----------------------------------------
-- Q: How many customers came back vs bought once?

SELECT
    CASE 
        WHEN total_orders = 1 THEN 'One-Time Customer'
        WHEN total_orders BETWEEN 2 AND 5 THEN 'Occasional Customer'
        WHEN total_orders BETWEEN 6 AND 20 THEN 'Regular Customer'
        ELSE 'Loyal Customer'
    END AS customer_segment,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / 
        SUM(COUNT(*)) OVER(), 2) AS percentage
FROM (
    SELECT 
        customer_id,
        COUNT(DISTINCT invoice) AS total_orders
    FROM online_retail_clean
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
) AS customer_orders
GROUP BY customer_segment
ORDER BY total_customers DESC;

-- Result: 72.39% repeat customers | Only 27.61% one-time buyers

-- ----------------------------------------
-- 6.3 RFM Analysis
-- ----------------------------------------
-- Business Question: How do we segment customers by value?
-- RFM = Recency (how recently), Frequency (how often),
--       Monetary (how much they spend)

WITH rfm_base AS (
    SELECT
        customer_id,
        DATEDIFF('2011-12-10', MAX(invoice_date))  AS recency,
        COUNT(DISTINCT invoice) AS frequency,
        ROUND(SUM(revenue), 2) AS monetary
    FROM online_retail_clean
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        customer_id, recency,
        frequency, monetary,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
)
SELECT
    customer_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score) AS rfm_total,
    CASE
        WHEN (r_score + f_score + m_score) >= 13 THEN 'Champions'
        WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal Customers'
        WHEN (r_score + f_score + m_score) >= 7  THEN 'Potential Loyalists'
        WHEN (r_score + f_score + m_score) >= 4  THEN 'At Risk Customers'
        ELSE                                           'Lost Customers'
    END AS rfm_segment
FROM rfm_scores
ORDER BY rfm_total DESC;

-- Result: Champions score 15 | bought within 26 days on average

-- ----------------------------------------
-- 6.4 RFM Segment Summary
-- ----------------------------------------
-- Q: How many customers in each segment?

WITH rfm_base AS (
    SELECT
        customer_id,
        DATEDIFF('2011-12-10', MAX(invoice_date))  AS recency,
        COUNT(DISTINCT invoice) AS frequency,
        ROUND(SUM(revenue), 2) AS monetary
    FROM online_retail_clean
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        customer_id,
        recency,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
),
rfm_segments AS (
    SELECT
        customer_id,
        recency,
        frequency,
        monetary,
        (r_score + f_score + m_score) AS rfm_total,
        CASE
            WHEN (r_score + f_score + m_score) >= 13 THEN 'Champions'
            WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal Customers'
            WHEN (r_score + f_score + m_score) >= 7  THEN 'Potential Loyalists'
            WHEN (r_score + f_score + m_score) >= 4  THEN 'At Risk Customers'
            ELSE                                           'Lost Customers'
        END AS rfm_segment
    FROM rfm_scores
)
SELECT
    rfm_segment,
    COUNT(*) AS total_customers,
    ROUND(AVG(recency), 1) AS avg_recency_days,
    ROUND(AVG(frequency), 1) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_monetary,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER(), 2) AS percentage
FROM rfm_segments
GROUP BY rfm_segment
ORDER BY total_revenue DESC;

-- Result: Champions 22% of customers generate 62% of revenue

-- ============================================================
-- SECTION 7 : ADVANCED ANALYSIS
-- ============================================================

-- ----------------------------------------
-- 7.1 Month over Month Revenue Growth
-- ----------------------------------------
-- Q: How is revenue trending month on month?
-- Technique: LAG() window function

WITH monthly_revenue AS (
    SELECT
        YEAR(invoice_date) AS year,
        MONTH(invoice_date) AS month,
        MONTHNAME(invoice_date) AS month_name,
        ROUND(SUM(revenue), 2) AS total_revenue
    FROM online_retail_clean
    GROUP BY 
        YEAR(invoice_date),
        MONTH(invoice_date),
        MONTHNAME(invoice_date)
)
SELECT
    year,
    month,
    month_name,
    total_revenue,
    LAG(total_revenue) OVER ( ORDER BY year, month) AS prev_month_revenue,
    ROUND(total_revenue - LAG(total_revenue) 
        OVER (ORDER BY year, month), 2) AS revenue_change,
    ROUND((total_revenue - LAG(total_revenue) 
        OVER (ORDER BY year, month)) * 100 / LAG(total_revenue) 
        OVER (ORDER BY year, month), 2) AS growth_percentage
FROM monthly_revenue
ORDER BY year, month;

-- Result: March 2010 strongest growth +50.66% | Nov peak both years

-- ----------------------------------------
-- 7.2 Running Total Revenue
-- ----------------------------------------
-- Q: What is our cumulative revenue over time?
-- Technique: SUM() OVER() window function

WITH monthly_revenue AS (
    SELECT
        YEAR(invoice_date) AS year,
        MONTH(invoice_date) AS month,
        MONTHNAME(invoice_date) AS month_name,
        ROUND(SUM(revenue), 2) AS total_revenue
    FROM online_retail_clean
    GROUP BY
        YEAR(invoice_date),
        MONTH(invoice_date),
        MONTHNAME(invoice_date)
)
SELECT
    year,
    month,
    month_name,
    total_revenue,
    ROUND(SUM(total_revenue) OVER ( ORDER BY year, month
        ROWS BETWEEN UNBOUNDED PRECEDING 
        AND CURRENT ROW), 2) AS running_total
FROM monthly_revenue
ORDER BY year, month;

-- Result: Cumulative revenue reached £8.3M by October 2010

-- ----------------------------------------
-- 7.3 Customer Revenue Ranking
-- ----------------------------------------
-- Q: How do customers rank against each other?
-- Technique: RANK(), DENSE_RANK(), NTILE() window functions

WITH customer_revenue AS (
    SELECT
        customer_id,
        country,
        COUNT(DISTINCT invoice) AS total_orders,
        ROUND(SUM(revenue), 2) AS total_revenue
    FROM online_retail_clean
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id, country
)
SELECT
    customer_id,
    country,
    total_orders,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_dense_rank,
    NTILE(4) OVER (ORDER BY total_revenue DESC) AS revenue_quartile
FROM customer_revenue
ORDER BY revenue_rank
LIMIT 20;

-- Result: Customer 18102 rank 1 | Top 20 all in Quartile 1

-- ----------------------------------------
-- 7.4 Cohort Analysis
-- ----------------------------------------
-- Q: Do customers return after first purchase?
-- Technique: CTE + Window Functions to track retention by cohort

WITH first_purchase AS (
    -- Find each customer's first purchase month
    SELECT
        customer_id,
        DATE_FORMAT(MIN(invoice_date), '%Y-%m') AS cohort_month
    FROM online_retail_clean
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),
customer_activity AS (
    -- Find all months each customer was active
    SELECT
        o.customer_id,
        DATE_FORMAT(o.invoice_date, '%Y-%m') AS activity_month,
        f.cohort_month
    FROM online_retail_clean o
    JOIN first_purchase f 
        ON o.customer_id = f.customer_id
    WHERE o.customer_id IS NOT NULL
),
cohort_data AS (
    -- Calculate months since first purchase
    SELECT
        cohort_month,
        activity_month,
        COUNT(DISTINCT customer_id) AS active_customers,
        PERIOD_DIFF(
            REPLACE(activity_month, '-', ''),
            REPLACE(cohort_month, '-', '')) AS months_since_first
    FROM customer_activity
    GROUP BY cohort_month, activity_month
)
SELECT
    cohort_month,
    months_since_first,
    active_customers,
    FIRST_VALUE(active_customers) OVER (
        PARTITION BY cohort_month
        ORDER BY months_since_first) AS cohort_size,
    ROUND(active_customers * 100.0 /
        FIRST_VALUE(active_customers) OVER (
        PARTITION BY cohort_month
        ORDER BY months_since_first), 2) AS retention_rate
FROM cohort_data
ORDER BY cohort_month, months_since_first
LIMIT 30;

-- Result: Dec 2009 cohort retained 35%+ consistently above industry avg

-- ============================================================
-- SECTION 8 : BUSINESS INSIGHTS SUMMARY
-- ============================================================

-- ----------------------------------------
-- 8.1 Overall Business Health Check
-- ----------------------------------------
-- Business Question: What is the complete one-line summary of the business performance?

SELECT
    COUNT(DISTINCT invoice) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT stock_code) AS total_products,
    COUNT(DISTINCT country) AS total_countries,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(AVG(revenue), 2) AS avg_order_value,
    ROUND(SUM(revenue) /
        COUNT(DISTINCT customer_id), 2) AS revenue_per_customer,
    MIN(invoice_date) AS data_from,
    MAX(invoice_date) AS data_to
FROM online_retail_clean;

-- Result: £20.4M revenue | 5,878 customers | £3,483 per customer

-- ----------------------------------------
-- 8.2 Peak Sales Period Identification
-- ----------------------------------------
-- Q: When should the business ramp up operations?

SELECT
    MONTHNAME(invoice_date) AS month_name,
    ROUND(AVG(daily_revenue), 2) AS avg_daily_revenue,
    ROUND(SUM(total_revenue), 2) AS total_revenue,
    SUM(total_orders) AS total_orders
FROM (
    SELECT
        invoice_date,
        MONTHNAME(invoice_date)  AS month_name,
        COUNT(DISTINCT invoice)  AS total_orders,
        ROUND(SUM(revenue), 2)  AS daily_revenue,
        SUM(revenue)  AS total_revenue
    FROM online_retail_clean
    GROUP BY invoice_date, MONTHNAME(invoice_date)
) AS daily_stats
GROUP BY MONTHNAME(invoice_date)
ORDER BY total_revenue DESC;

-- Result: Sep-Dec Golden Quarter = 46% of annual revenue 

-- ----------------------------------------
-- 8.3 Revenue Concentration Analysis
-- ----------------------------------------
-- Q: How dependent is the business on top customers?

WITH customer_revenue AS (
    SELECT
        customer_id,
        ROUND(SUM(revenue), 2) AS total_revenue
    FROM online_retail_clean
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),
ranked AS (
    SELECT
        customer_id,
        total_revenue,
        ROUND(total_revenue * 100.0 /
            SUM(total_revenue) OVER(), 2) AS revenue_share,
        ROUND(SUM(total_revenue) OVER(
            ORDER BY total_revenue DESC) * 100.0 /
            SUM(total_revenue) OVER(), 2) AS cumulative_share,
        RANK() OVER(
            ORDER BY total_revenue DESC) AS customer_rank
    FROM customer_revenue
)
SELECT
    customer_rank,
    customer_id,
    total_revenue,
    revenue_share,
    cumulative_share
FROM ranked
WHERE customer_rank <= 20
ORDER BY customer_rank;

-- Result: Top 10 customers = 16% of total revenue

-- ----------------------------------------
-- 8.4 Product Performance Matrix
-- ----------------------------------------
-- Q: Which products are high value vs high volume?

WITH product_stats AS (
    SELECT
        stock_code,
        description,
        COUNT(DISTINCT invoice) AS total_orders,
        SUM(quantity) AS total_quantity,
        ROUND(SUM(revenue), 2) AS total_revenue,
        ROUND(AVG(price), 2) AS avg_price,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM online_retail_clean
    WHERE customer_id IS NOT NULL
    GROUP BY stock_code, description
),
product_ranked AS (
    SELECT
        stock_code,
        description,
        total_orders,
        total_quantity,
        total_revenue,
        avg_price,
        unique_customers,
        NTILE(3) OVER (
            ORDER BY total_revenue DESC) AS revenue_tier,
        NTILE(3) OVER (
            ORDER BY total_quantity DESC) AS volume_tier
    FROM product_stats
)
SELECT
    stock_code,
    description,
    total_orders,
    total_quantity,
    total_revenue,
    avg_price,
    unique_customers,
    CASE
        WHEN revenue_tier = 1 
        AND volume_tier = 1  THEN 'Star Product'
        WHEN revenue_tier = 1 
        AND volume_tier > 1  THEN 'High Value Low Volume'
        WHEN revenue_tier > 1 
        AND volume_tier = 1  THEN 'High Volume Low Value'
        ELSE                      'Standard Product'
    END  AS product_category
FROM product_ranked
ORDER BY total_revenue DESC
LIMIT 20;

-- Result: Regency Cakestand & White Hanging Heart = Star Products ✅

-- ============================================================
-- END OF PROJECT
-- ============================================================