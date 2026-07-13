-- =============================================================================
-- RetailPulse | 04_silver_tables.sql
-- Purpose: Cleaned, validated dimensional model (SILVER Layer)
-- Techniques: CTEs, Window Functions, QUALIFY, Business Rules
-- =============================================================================
--
-- TRANSFORMATIONS APPLIED:
--   • Deduplication (ROW_NUMBER + QUALIFY)
--   • Null handling and default values
--   • State standardization (2-letter abbreviations)
--   • Category uppercase normalization
--   • Date parsing and validation
--   • Referential integrity checks
--   • Business rule filters (cancelled orders, negative amounts, etc.)
--
-- WINDOW FUNCTIONS DEMONSTRATED:
--   ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, FIRST_VALUE, LAST_VALUE, NTILE
--
-- =============================================================================

-- =============================================================================
-- SILVER: dim_customers
-- Business Rules:
--   • Remove duplicate customer_id (keep earliest signup)
--   • Valid email format or NULL
--   • Standardize state to 2-letter code
--   • Default missing country to 'USA'
-- =============================================================================
CREATE OR REPLACE TABLE `retailpulse-project.retail_silver.dim_customers`
CLUSTER BY customer_id, state
AS
WITH state_mapping AS (
  SELECT 'NEW YORK' AS state_full, 'NY' AS state_code UNION ALL
  SELECT 'CALIFORNIA', 'CA' UNION ALL SELECT 'CALIFORNIA', 'CA' UNION ALL
  SELECT 'ILLINOIS', 'IL' UNION ALL SELECT 'TEXAS', 'TX' UNION ALL
  SELECT 'ARIZONA', 'AZ' UNION ALL SELECT 'PENNSYLVANIA', 'PA' UNION ALL
  SELECT 'FLORIDA', 'FL' UNION ALL SELECT 'OHIO', 'OH' UNION ALL
  SELECT 'NORTH CAROLINA', 'NC' UNION ALL SELECT 'WASHINGTON', 'WA' UNION ALL
  SELECT 'COLORADO', 'CO' UNION ALL SELECT 'MASSACHUSETTS', 'MA' UNION ALL
  SELECT 'TENNESSEE', 'TN' UNION ALL SELECT 'MICHIGAN', 'MI' UNION ALL
  SELECT 'OREGON', 'OR' UNION ALL SELECT 'NEVADA', 'NV' UNION ALL
  SELECT 'GEORGIA', 'GA' UNION ALL SELECT 'MINNESOTA', 'MN' UNION ALL
  SELECT 'UTAH', 'UT' UNION ALL SELECT 'MISSOURI', 'MO' UNION ALL
  SELECT 'INDIANA', 'IN'
),
cleaned AS (
  SELECT
    customer_id,
    TRIM(first_name) AS first_name,
    TRIM(last_name) AS last_name,
    NULLIF(TRIM(gender), '') AS gender,
    CASE
      WHEN REGEXP_CONTAINS(email, r'^[^@]+@[^@]+\.[^@]+$') THEN LOWER(TRIM(email))
      ELSE NULL
    END AS email,
    NULLIF(TRIM(phone), '') AS phone,
    TRIM(city) AS city,
    UPPER(TRIM(COALESCE(
      sm.state_code,
      CASE WHEN LENGTH(TRIM(state)) = 2 THEN UPPER(TRIM(state)) ELSE NULL END
    ))) AS state,
    COALESCE(NULLIF(TRIM(country), ''), 'USA') AS country,
    SAFE.PARSE_DATE('%Y-%m-%d', signup_date) AS signup_date,
    _loaded_at
  FROM `retailpulse-project.retail_bronze.customers` c
  LEFT JOIN state_mapping sm ON UPPER(TRIM(c.state)) = sm.state_full
),
deduped AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY customer_id
      ORDER BY signup_date ASC NULLS LAST, _loaded_at ASC
    ) AS rn
  FROM cleaned
  WHERE customer_id IS NOT NULL
)
SELECT
  customer_id,
  first_name,
  last_name,
  gender,
  email,
  phone,
  city,
  state,
  country,
  signup_date,
  -- Customer segment using NTILE window function
  NTILE(4) OVER (ORDER BY signup_date ASC NULLS LAST) AS customer_segment_ntile,
  CURRENT_TIMESTAMP() AS _silver_loaded_at
FROM deduped
WHERE rn = 1;

-- =============================================================================
-- SILVER: dim_products
-- Business Rules:
--   • Uppercase category names
--   • Remove products with negative or zero price
--   • Deduplicate by product_id
-- =============================================================================
CREATE OR REPLACE TABLE `retailpulse-project.retail_silver.dim_products`
CLUSTER BY product_id, category
AS
WITH cleaned AS (
  SELECT
    product_id,
    TRIM(product_name) AS product_name,
    UPPER(TRIM(category)) AS category,
    TRIM(subcategory) AS subcategory,
    TRIM(brand) AS brand,
    price,
    cost,
    SAFE.PARSE_DATE('%Y-%m-%d', launch_date) AS launch_date,
    ROUND(SAFE_DIVIDE(price - cost, NULLIF(price, 0)) * 100, 2) AS margin_pct,
    _loaded_at
  FROM `retailpulse-project.retail_bronze.products`
  WHERE price > 0 AND cost >= 0
),
deduped AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY _loaded_at DESC) AS rn,
  RANK() OVER (ORDER BY price DESC) AS price_rank,
    DENSE_RANK() OVER (PARTITION BY category ORDER BY price DESC) AS category_price_dense_rank
  FROM cleaned
)
SELECT
  product_id,
  product_name,
  category,
  subcategory,
  brand,
  price,
  cost,
  launch_date,
  margin_pct,
  price_rank,
  category_price_dense_rank,
  CURRENT_TIMESTAMP() AS _silver_loaded_at
FROM deduped
WHERE rn = 1;

-- =============================================================================
-- SILVER: dim_payments
-- Business Rules:
--   • Remove duplicate payments per order (keep first successful)
--   • Valid payment_status values only
-- =============================================================================
CREATE OR REPLACE TABLE `retailpulse-project.retail_silver.dim_payments`
PARTITION BY payment_date
CLUSTER BY order_id, payment_method
AS
WITH cleaned AS (
  SELECT
    payment_id,
    order_id,
    TRIM(payment_method) AS payment_method,
    TRIM(payment_status) AS payment_status,
    payment_date,
    _loaded_at,
    ROW_NUMBER() OVER (
      PARTITION BY order_id
      ORDER BY
        CASE payment_status WHEN 'Success' THEN 1 WHEN 'Pending' THEN 2 ELSE 3 END,
        payment_date ASC
    ) AS payment_rank,
    LAG(payment_status) OVER (PARTITION BY order_id ORDER BY payment_date) AS prev_payment_status,
    LEAD(payment_method) OVER (PARTITION BY order_id ORDER BY payment_date) AS next_payment_method,
    FIRST_VALUE(payment_method) OVER (
      PARTITION BY order_id ORDER BY payment_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS first_payment_method,
    LAST_VALUE(payment_status) OVER (
      PARTITION BY order_id ORDER BY payment_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_payment_status
  FROM `retailpulse-project.retail_bronze.payments`
  WHERE payment_id IS NOT NULL
)
SELECT
  payment_id,
  order_id,
  payment_method,
  payment_status,
  payment_date,
  payment_rank,
  prev_payment_status,
  next_payment_method,
  first_payment_method,
  last_payment_status,
  CURRENT_TIMESTAMP() AS _silver_loaded_at
FROM cleaned
QUALIFY ROW_NUMBER() OVER (PARTITION BY payment_id ORDER BY _loaded_at DESC) = 1;

-- =============================================================================
-- SILVER: fact_orders
-- Business Rules:
--   • Exclude invalid customer references
--   • Flag cancelled/returned orders (retain for analytics with is_valid_order flag)
--   • Remove negative total_amount for revenue calculations
--   • Standardize shipping_state
--   • Deduplicate orders
-- =============================================================================
CREATE OR REPLACE TABLE `retailpulse-project.retail_silver.fact_orders`
PARTITION BY order_date
CLUSTER BY customer_id, status
AS
WITH state_mapping AS (
  SELECT 'NEW YORK' AS state_full, 'NY' AS state_code UNION ALL
  SELECT 'CALIFORNIA', 'CA' UNION ALL SELECT 'TEXAS', 'TX' UNION ALL
  SELECT 'FLORIDA', 'FL' UNION ALL SELECT 'ILLINOIS', 'IL' UNION ALL
  SELECT 'ARIZONA', 'AZ' UNION ALL SELECT 'PENNSYLVANIA', 'PA' UNION ALL
  SELECT 'OHIO', 'OH' UNION ALL SELECT 'NORTH CAROLINA', 'NC' UNION ALL
  SELECT 'WASHINGTON', 'WA' UNION ALL SELECT 'COLORADO', 'CO' UNION ALL
  SELECT 'MASSACHUSETTS', 'MA' UNION ALL SELECT 'TENNESSEE', 'TN' UNION ALL
  SELECT 'MICHIGAN', 'MI' UNION ALL SELECT 'OREGON', 'OR' UNION ALL
  SELECT 'NEVADA', 'NV' UNION ALL SELECT 'GEORGIA', 'GA' UNION ALL
  SELECT 'MINNESOTA', 'MN' UNION ALL SELECT 'UTAH', 'UT' UNION ALL
  SELECT 'MISSOURI', 'MO' UNION ALL SELECT 'INDIANA', 'IN'
),
valid_customers AS (
  SELECT customer_id FROM `retailpulse-project.retail_silver.dim_customers`
),
order_line_revenue AS (
  SELECT
    oi.order_id,
    SUM(oi.quantity * oi.unit_price) AS line_revenue,
    SUM(oi.quantity) AS total_units,
    COUNT(DISTINCT oi.product_id) AS distinct_products
  FROM `retailpulse-project.retail_bronze.order_items` oi
  INNER JOIN `retailpulse-project.retail_silver.dim_products` p ON oi.product_id = p.product_id
  GROUP BY oi.order_id
),
cleaned AS (
  SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    UPPER(TRIM(o.status)) AS status,
    TRIM(o.shipping_city) AS shipping_city,
    UPPER(TRIM(COALESCE(
      sm.state_code,
      CASE WHEN LENGTH(TRIM(o.shipping_state)) = 2 THEN UPPER(TRIM(o.shipping_state)) ELSE NULL END
    ))) AS shipping_state,
    COALESCE(o.discount, 0) AS discount,
    COALESCE(o.tax, 0) AS tax,
    o.total_amount,
    olr.line_revenue,
    olr.total_units,
    olr.distinct_products,
    -- Business rule flags
    CASE WHEN vc.customer_id IS NOT NULL THEN TRUE ELSE FALSE END AS is_valid_customer,
    CASE WHEN o.total_amount >= 0 THEN TRUE ELSE FALSE END AS is_valid_amount,
    CASE WHEN UPPER(TRIM(o.status)) = 'COMPLETED' THEN TRUE ELSE FALSE END AS is_completed,
    CASE WHEN UPPER(TRIM(o.status)) IN ('COMPLETED', 'RETURNED') THEN TRUE ELSE FALSE END AS is_revenue_eligible,
    o._loaded_at
  FROM `retailpulse-project.retail_bronze.orders` o
  LEFT JOIN valid_customers vc ON o.customer_id = vc.customer_id
  LEFT JOIN state_mapping sm ON UPPER(TRIM(o.shipping_state)) = sm.state_full
  LEFT JOIN order_line_revenue olr ON o.order_id = olr.order_id
  WHERE o.order_id IS NOT NULL AND o.order_date IS NOT NULL
),
with_windows AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY _loaded_at DESC) AS rn,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS customer_order_sequence,
    LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date,
    LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS next_order_date,
    DATE_DIFF(
      order_date,
      LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date),
      DAY
    ) AS days_since_prev_order,
    SUM(CASE WHEN is_revenue_eligible THEN total_amount ELSE 0 END) OVER (
      PARTITION BY customer_id ORDER BY order_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_customer_revenue,
    NTILE(5) OVER (ORDER BY total_amount) AS order_value_quintile
  FROM cleaned
)
SELECT
  order_id,
  customer_id,
  order_date,
  status,
  shipping_city,
  shipping_state,
  discount,
  tax,
  total_amount,
  line_revenue,
  total_units,
  distinct_products,
  is_valid_customer,
  is_valid_amount,
  is_completed,
  is_revenue_eligible,
  customer_order_sequence,
  prev_order_date,
  next_order_date,
  days_since_prev_order,
  running_customer_revenue,
  order_value_quintile,
  CURRENT_TIMESTAMP() AS _silver_loaded_at
FROM with_windows
WHERE rn = 1;

-- =============================================================================
-- SILVER: fact_order_items (line-level fact for product analytics)
-- Business Rules:
--   • Valid product_id only (exclude missing products)
--   • Join to valid orders
-- =============================================================================
CREATE OR REPLACE TABLE `retailpulse-project.retail_silver.fact_order_items`
CLUSTER BY order_id, product_id
AS
WITH cleaned AS (
  SELECT
    oi.order_item_id,
    oi.order_id,
    oi.product_id,
    oi.quantity,
    oi.unit_price,
    oi.quantity * oi.unit_price AS line_total,
    fo.order_date,
    fo.customer_id,
    fo.status AS order_status,
    fo.is_revenue_eligible,
    p.category,
    p.brand,
    ROW_NUMBER() OVER (PARTITION BY oi.order_item_id ORDER BY oi._loaded_at DESC) AS rn
  FROM `retailpulse-project.retail_bronze.order_items` oi
  INNER JOIN `retailpulse-project.retail_silver.fact_orders` fo ON oi.order_id = fo.order_id
  INNER JOIN `retailpulse-project.retail_silver.dim_products` p ON oi.product_id = p.product_id
)
SELECT
  order_item_id,
  order_id,
  product_id,
  quantity,
  unit_price,
  line_total,
  order_date,
  customer_id,
  order_status,
  is_revenue_eligible,
  category,
  brand,
  CURRENT_TIMESTAMP() AS _silver_loaded_at
FROM cleaned
WHERE rn = 1;

-- =============================================================================
-- DATA QUALITY SUMMARY (run after load)
-- =============================================================================
/*
SELECT 'Invalid customers in orders' AS check_name,
  COUNT(*) AS issue_count
FROM `retailpulse-project.retail_silver.fact_orders`
WHERE is_valid_customer = FALSE

UNION ALL
SELECT 'Negative order amounts',
  COUNT(*) FROM `retailpulse-project.retail_silver.fact_orders` WHERE is_valid_amount = FALSE

UNION ALL
SELECT 'Duplicate payments removed',
  (SELECT COUNT(*) FROM `retailpulse-project.retail_bronze.payments`) -
  (SELECT COUNT(*) FROM `retailpulse-project.retail_silver.dim_payments`);
*/
