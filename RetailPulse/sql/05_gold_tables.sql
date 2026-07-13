-- =============================================================================
-- RetailPulse | 05_gold_tables.sql
-- Purpose: Business-ready aggregate tables (GOLD Layer)
-- Audience: Looker Studio, executive dashboards, self-service analytics
-- =============================================================================

-- =============================================================================
-- GOLD: daily_sales
-- Daily revenue, orders, and units sold
-- =============================================================================
CREATE OR REPLACE TABLE `retailpulse-project.retail_gold.daily_sales`
PARTITION BY sale_date
AS
SELECT
  fo.order_date AS sale_date,
  COUNT(DISTINCT fo.order_id) AS total_orders,
  COUNT(DISTINCT fo.customer_id) AS unique_customers,
  SUM(fo.total_amount) AS gross_revenue,
  SUM(fo.discount) AS total_discount,
  SUM(fo.tax) AS total_tax,
  SUM(fo.line_revenue) AS line_item_revenue,
  SUM(fo.total_units) AS units_sold,
  ROUND(AVG(fo.total_amount), 2) AS avg_order_value,
  ROUND(SAFE_DIVIDE(SUM(fo.total_amount), COUNT(DISTINCT fo.order_id)), 2) AS revenue_per_order
FROM `retailpulse-project.retail_silver.fact_orders` fo
WHERE fo.is_revenue_eligible = TRUE
  AND fo.is_valid_customer = TRUE
  AND fo.is_valid_amount = TRUE
GROUP BY fo.order_date;

-- =============================================================================
-- GOLD: monthly_sales
-- =============================================================================
CREATE OR REPLACE TABLE `retailpulse-project.retail_gold.monthly_sales`
AS
SELECT
  DATE_TRUNC(fo.order_date, MONTH) AS sale_month,
  EXTRACT(YEAR FROM fo.order_date) AS sale_year,
  EXTRACT(MONTH FROM fo.order_date) AS sale_month_num,
  FORMAT_DATE('%Y-%m', fo.order_date) AS year_month,
  COUNT(DISTINCT fo.order_id) AS total_orders,
  COUNT(DISTINCT fo.customer_id) AS unique_customers,
  SUM(fo.total_amount) AS gross_revenue,
  SUM(fo.discount) AS total_discount,
  ROUND(AVG(fo.total_amount), 2) AS avg_order_value,
  SUM(fo.total_units) AS units_sold,
  -- Month-over-month growth
  LAG(SUM(fo.total_amount)) OVER (ORDER BY DATE_TRUNC(fo.order_date, MONTH)) AS prev_month_revenue,
  ROUND(
    SAFE_DIVIDE(
      SUM(fo.total_amount) - LAG(SUM(fo.total_amount)) OVER (ORDER BY DATE_TRUNC(fo.order_date, MONTH)),
      LAG(SUM(fo.total_amount)) OVER (ORDER BY DATE_TRUNC(fo.order_date, MONTH))
    ) * 100, 2
  ) AS mom_revenue_growth_pct
FROM `retailpulse-project.retail_silver.fact_orders` fo
WHERE fo.is_revenue_eligible = TRUE
  AND fo.is_valid_customer = TRUE
GROUP BY sale_month, sale_year, sale_month_num, year_month;

-- =============================================================================
-- GOLD: customer_lifetime_value
-- =============================================================================
CREATE OR REPLACE TABLE `retailpulse-project.retail_gold.customer_lifetime_value`
CLUSTER BY customer_id
AS
SELECT
  c.customer_id,
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  c.city,
  c.state,
  c.signup_date,
  COUNT(DISTINCT fo.order_id) AS total_orders,
  SUM(fo.total_amount) AS lifetime_value,
  ROUND(AVG(fo.total_amount), 2) AS avg_order_value,
  MIN(fo.order_date) AS first_order_date,
  MAX(fo.order_date) AS last_order_date,
  DATE_DIFF(MAX(fo.order_date), MIN(fo.order_date), DAY) AS customer_tenure_days,
  CASE
    WHEN COUNT(DISTINCT fo.order_id) >= 5 THEN 'VIP'
    WHEN COUNT(DISTINCT fo.order_id) >= 3 THEN 'Loyal'
    WHEN COUNT(DISTINCT fo.order_id) = 2 THEN 'Repeat'
    WHEN COUNT(DISTINCT fo.order_id) = 1 THEN 'One-Time'
    ELSE 'Prospect'
  END AS customer_segment,
  NTILE(10) OVER (ORDER BY SUM(fo.total_amount) DESC) AS ltv_decile
FROM `retailpulse-project.retail_silver.dim_customers` c
LEFT JOIN `retailpulse-project.retail_silver.fact_orders` fo
  ON c.customer_id = fo.customer_id
  AND fo.is_revenue_eligible = TRUE
GROUP BY c.customer_id, customer_name, c.city, c.state, c.signup_date;

-- =============================================================================
-- GOLD: repeat_customers
-- =============================================================================
CREATE OR REPLACE TABLE `retailpulse-project.retail_gold.repeat_customers`
AS
SELECT
  customer_id,
  total_orders,
  lifetime_value,
  customer_segment,
  first_order_date,
  last_order_date,
  DATE_DIFF(last_order_date, first_order_date, DAY) AS days_between_first_last,
  CASE WHEN total_orders > 1 THEN TRUE ELSE FALSE END AS is_repeat_customer
FROM `retailpulse-project.retail_gold.customer_lifetime_value`
WHERE total_orders > 0;

-- =============================================================================
-- GOLD: top_products
-- =============================================================================
CREATE OR REPLACE TABLE `retailpulse-project.retail_gold.top_products`
AS
SELECT
  foi.product_id,
  p.product_name,
  p.category,
  p.subcategory,
  p.brand,
  SUM(foi.quantity) AS units_sold,
  SUM(foi.line_total) AS total_revenue,
  COUNT(DISTINCT foi.order_id) AS order_count,
  ROUND(AVG(foi.unit_price), 2) AS avg_selling_price,
  RANK() OVER (ORDER BY SUM(foi.line_total) DESC) AS revenue_rank,
  DENSE_RANK() OVER (ORDER BY SUM(foi.quantity) DESC) AS units_rank
FROM `retailpulse-project.retail_silver.fact_order_items` foi
INNER JOIN `retailpulse-project.retail_silver.dim_products` p ON foi.product_id = p.product_id
WHERE foi.is_revenue_eligible = TRUE
GROUP BY foi.product_id, p.product_name, p.category, p.subcategory, p.brand;

-- =============================================================================
-- GOLD: top_categories
-- =============================================================================
CREATE OR REPLACE TABLE `retailpulse-project.retail_gold.top_categories`
AS
SELECT
  foi.category,
  SUM(foi.line_total) AS total_revenue,
  SUM(foi.quantity) AS units_sold,
  COUNT(DISTINCT foi.order_id) AS order_count,
  COUNT(DISTINCT foi.product_id) AS product_count,
  ROUND(AVG(foi.line_total), 2) AS avg_line_value,
  RANK() OVER (ORDER BY SUM(foi.line_total) DESC) AS category_revenue_rank
FROM `retailpulse-project.retail_silver.fact_order_items` foi
WHERE foi.is_revenue_eligible = TRUE
GROUP BY foi.category;

-- =============================================================================
-- GOLD: state_wise_sales
-- =============================================================================
CREATE OR REPLACE TABLE `retailpulse-project.retail_gold.state_wise_sales`
AS
SELECT
  fo.shipping_state AS state,
  COUNT(DISTINCT fo.order_id) AS total_orders,
  COUNT(DISTINCT fo.customer_id) AS unique_customers,
  SUM(fo.total_amount) AS total_revenue,
  ROUND(AVG(fo.total_amount), 2) AS avg_order_value,
  SUM(fo.total_units) AS units_sold,
  RANK() OVER (ORDER BY SUM(fo.total_amount) DESC) AS state_revenue_rank
FROM `retailpulse-project.retail_silver.fact_orders` fo
WHERE fo.is_revenue_eligible = TRUE
  AND fo.shipping_state IS NOT NULL
GROUP BY fo.shipping_state;

-- =============================================================================
-- GOLD: brand_performance
-- =============================================================================
CREATE OR REPLACE TABLE `retailpulse-project.retail_gold.brand_performance`
AS
SELECT
  foi.brand,
  foi.category,
  SUM(foi.line_total) AS total_revenue,
  SUM(foi.quantity) AS units_sold,
  COUNT(DISTINCT foi.product_id) AS product_count,
  COUNT(DISTINCT foi.order_id) AS order_count,
  ROUND(SAFE_DIVIDE(SUM(foi.line_total), SUM(foi.quantity)), 2) AS revenue_per_unit,
  RANK() OVER (PARTITION BY foi.category ORDER BY SUM(foi.line_total) DESC) AS brand_rank_in_category
FROM `retailpulse-project.retail_silver.fact_order_items` foi
WHERE foi.is_revenue_eligible = TRUE
GROUP BY foi.brand, foi.category;

-- =============================================================================
-- GOLD: payment_analysis
-- =============================================================================
CREATE OR REPLACE TABLE `retailpulse-project.retail_gold.payment_analysis`
AS
SELECT
  dp.payment_method,
  dp.payment_status,
  COUNT(DISTINCT dp.payment_id) AS payment_count,
  COUNT(DISTINCT dp.order_id) AS order_count,
  SUM(fo.total_amount) AS associated_revenue,
  ROUND(AVG(fo.total_amount), 2) AS avg_order_value,
  ROUND(
    COUNTIF(dp.payment_status = 'Success') * 100.0 / COUNT(*), 2
  ) AS success_rate_pct
FROM `retailpulse-project.retail_silver.dim_payments` dp
LEFT JOIN `retailpulse-project.retail_silver.fact_orders` fo
  ON dp.order_id = fo.order_id AND fo.is_revenue_eligible = TRUE
GROUP BY dp.payment_method, dp.payment_status;

-- =============================================================================
-- GOLD: average_order_value (summary KPI table)
-- =============================================================================
CREATE OR REPLACE TABLE `retailpulse-project.retail_gold.average_order_value`
AS
SELECT
  'ALL' AS dimension,
  'ALL' AS dimension_value,
  COUNT(DISTINCT order_id) AS order_count,
  ROUND(AVG(total_amount), 2) AS avg_order_value,
  ROUND(APPROX_QUANTILES(total_amount, 100)[OFFSET(50)], 2) AS median_order_value,
  ROUND(MIN(total_amount), 2) AS min_order_value,
  ROUND(MAX(total_amount), 2) AS max_order_value
FROM `retailpulse-project.retail_silver.fact_orders`
WHERE is_revenue_eligible = TRUE AND is_valid_amount = TRUE

UNION ALL

SELECT
  'By State' AS dimension,
  shipping_state AS dimension_value,
  COUNT(DISTINCT order_id),
  ROUND(AVG(total_amount), 2),
  ROUND(APPROX_QUANTILES(total_amount, 100)[OFFSET(50)], 2),
  ROUND(MIN(total_amount), 2),
  ROUND(MAX(total_amount), 2)
FROM `retailpulse-project.retail_silver.fact_orders`
WHERE is_revenue_eligible = TRUE AND shipping_state IS NOT NULL
GROUP BY shipping_state;

-- =============================================================================
-- GOLD: executive_kpis (single-row snapshot for dashboards)
-- =============================================================================
CREATE OR REPLACE TABLE `retailpulse-project.retail_gold.executive_kpis`
AS
SELECT
  (SELECT COUNT(DISTINCT customer_id) FROM `retailpulse-project.retail_silver.dim_customers`) AS total_customers,
  (SELECT COUNT(DISTINCT order_id) FROM `retailpulse-project.retail_silver.fact_orders` WHERE is_revenue_eligible) AS total_orders,
  (SELECT ROUND(SUM(total_amount), 2) FROM `retailpulse-project.retail_silver.fact_orders` WHERE is_revenue_eligible) AS total_revenue,
  (SELECT ROUND(AVG(total_amount), 2) FROM `retailpulse-project.retail_silver.fact_orders` WHERE is_revenue_eligible) AS avg_order_value,
  (SELECT COUNT(*) FROM `retailpulse-project.retail_gold.repeat_customers` WHERE is_repeat_customer) AS repeat_customers,
  (SELECT ROUND(SAFE_DIVIDE(
    (SELECT COUNT(*) FROM `retailpulse-project.retail_gold.repeat_customers` WHERE is_repeat_customer),
    (SELECT COUNT(*) FROM `retailpulse-project.retail_gold.repeat_customers`)
  ) * 100, 2)) AS repeat_customer_rate_pct,
  CURRENT_TIMESTAMP() AS snapshot_timestamp;
