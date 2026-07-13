-- =============================================================================
-- RetailPulse | 06_views.sql
-- Purpose: Logical views and materialized views for analytics layer
-- Demonstrates: Views, Materialized Views, Cost Optimization patterns
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LOGICAL VIEW: vw_order_details
-- Denormalized view joining orders, customers, and payments
-- Cost tip: Prefer querying gold tables for dashboards; use views for ad-hoc
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `retailpulse-project.retail_gold.vw_order_details`
AS
SELECT
  fo.order_id,
  fo.order_date,
  fo.status,
  fo.total_amount,
  fo.discount,
  fo.tax,
  fo.shipping_city,
  fo.shipping_state,
  c.customer_id,
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  c.email,
  c.state AS customer_state,
  dp.payment_method,
  dp.payment_status,
  fo.is_revenue_eligible,
  fo.customer_order_sequence
FROM `retailpulse-project.retail_silver.fact_orders` fo
LEFT JOIN `retailpulse-project.retail_silver.dim_customers` c ON fo.customer_id = c.customer_id
LEFT JOIN `retailpulse-project.retail_silver.dim_payments` dp ON fo.order_id = dp.order_id AND dp.payment_rank = 1;

-- -----------------------------------------------------------------------------
-- LOGICAL VIEW: vw_product_sales
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `retailpulse-project.retail_gold.vw_product_sales`
AS
SELECT
  foi.order_item_id,
  foi.order_id,
  foi.order_date,
  foi.product_id,
  p.product_name,
  p.category,
  p.brand,
  foi.quantity,
  foi.unit_price,
  foi.line_total,
  foi.customer_id,
  foi.order_status
FROM `retailpulse-project.retail_silver.fact_order_items` foi
INNER JOIN `retailpulse-project.retail_silver.dim_products` p ON foi.product_id = p.product_id;

-- -----------------------------------------------------------------------------
-- LOGICAL VIEW: vw_customer_360
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `retailpulse-project.retail_gold.vw_customer_360`
AS
SELECT
  clv.customer_id,
  clv.customer_name,
  clv.city,
  clv.state,
  clv.signup_date,
  clv.total_orders,
  clv.lifetime_value,
  clv.avg_order_value,
  clv.customer_segment,
  clv.ltv_decile,
  clv.first_order_date,
  clv.last_order_date,
  rc.is_repeat_customer
FROM `retailpulse-project.retail_gold.customer_lifetime_value` clv
LEFT JOIN `retailpulse-project.retail_gold.repeat_customers` rc ON clv.customer_id = rc.customer_id;

-- -----------------------------------------------------------------------------
-- LOGICAL VIEW: vw_daily_kpis
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `retailpulse-project.retail_gold.vw_daily_kpis`
AS
SELECT
  sale_date,
  total_orders,
  unique_customers,
  gross_revenue,
  avg_order_value,
  units_sold,
  SUM(gross_revenue) OVER (ORDER BY sale_date ROWS UNBOUNDED PRECEDING) AS cumulative_revenue,
  AVG(gross_revenue) OVER (ORDER BY sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS revenue_7day_ma
FROM `retailpulse-project.retail_gold.daily_sales`;

-- -----------------------------------------------------------------------------
-- MATERIALIZED VIEW: mv_monthly_category_revenue
-- Pre-aggregated for fast dashboard refreshes; auto-refreshes within ~30 min
-- Best for: frequently queried aggregates with predictable refresh needs
-- -----------------------------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS `retailpulse-project.retail_gold.mv_monthly_category_revenue`
PARTITION BY sale_month
CLUSTER BY category
OPTIONS (
  enable_refresh = TRUE,
  refresh_interval_minutes = 60,
  description = 'Materialized monthly revenue by category for Looker Studio'
)
AS
SELECT
  DATE_TRUNC(foi.order_date, MONTH) AS sale_month,
  foi.category,
  SUM(foi.line_total) AS total_revenue,
  SUM(foi.quantity) AS units_sold,
  COUNT(DISTINCT foi.order_id) AS order_count
FROM `retailpulse-project.retail_silver.fact_order_items` foi
WHERE foi.is_revenue_eligible = TRUE
GROUP BY sale_month, foi.category;

-- -----------------------------------------------------------------------------
-- MATERIALIZED VIEW: mv_state_daily_revenue
-- -----------------------------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS `retailpulse-project.retail_gold.mv_state_daily_revenue`
PARTITION BY sale_date
CLUSTER BY state
OPTIONS (
  enable_refresh = TRUE,
  refresh_interval_minutes = 60
)
AS
SELECT
  fo.order_date AS sale_date,
  fo.shipping_state AS state,
  SUM(fo.total_amount) AS daily_revenue,
  COUNT(DISTINCT fo.order_id) AS daily_orders
FROM `retailpulse-project.retail_silver.fact_orders` fo
WHERE fo.is_revenue_eligible = TRUE AND fo.shipping_state IS NOT NULL
GROUP BY sale_date, state;

-- =============================================================================
-- QUERY EXECUTION PLAN (demonstration)
-- Run EXPLAIN to understand how BigQuery processes a view query
-- =============================================================================
/*
EXPLAIN
SELECT category, SUM(total_revenue)
FROM `retailpulse-project.retail_gold.mv_monthly_category_revenue`
WHERE sale_month >= '2024-01-01'
GROUP BY category;
*/

-- =============================================================================
-- DRY RUN (cost estimation before execution)
-- =============================================================================
/*
-- CLI: bq query --dry_run --use_legacy_sql=false 'SELECT ...'
-- Console: Click "Validator" to see bytes processed estimate
SELECT SUM(gross_revenue) FROM `retailpulse-project.retail_gold.daily_sales`;
*/
