-- =============================================================================
-- RetailPulse | 03_bronze_tables.sql
-- Purpose: Load raw data into native BigQuery tables (BRONZE Layer)
-- Techniques: CREATE TABLE AS SELECT (CTAS), Partitioning, Clustering
-- =============================================================================
--
-- BRONZE LAYER BEST PRACTICES:
--   • Preserve source data as-is (append-only mindset)
--   • Add ingestion metadata columns (_loaded_at, _source_file)
--   • Partition large fact tables by date for cost optimization
--   • Cluster by high-cardinality filter/join columns
--
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BRONZE: customers
-- Small dimension — no partitioning needed; cluster by customer_id
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE `gcp-evening-batch-501811.retail_bronze.customers`
CLUSTER BY customer_id
AS
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
  CURRENT_TIMESTAMP() AS _loaded_at,
  'gs://test-bkt-20261525/retail/customers.csv' AS _source_file
FROM `gcp-evening-batch-501811.retail_raw.ext_customers`;

-- -----------------------------------------------------------------------------
-- BRONZE: products
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE `gcp-evening-batch-501811.retail_bronze.products`
CLUSTER BY product_id, category
AS
SELECT
  product_id,
  product_name,
  category,
  subcategory,
  brand,
  price,
  cost,
  launch_date,
  CURRENT_TIMESTAMP() AS _loaded_at,
  'gs://test-bkt-20261525/retail/products.csv' AS _source_file
FROM `gcp-evening-batch-501811.retail_raw.ext_products`;

-- -----------------------------------------------------------------------------
-- BRONZE: orders
-- PARTITIONED by order_date, CLUSTERED by customer_id
-- This is the primary cost optimization pattern for fact tables
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE `gcp-evening-batch-501811.retail_bronze.orders`
PARTITION BY order_date
CLUSTER BY customer_id, status
AS
SELECT
  order_id,
  customer_id,
  SAFE.PARSE_DATE('%Y-%m-%d', order_date) AS order_date,
  status,
  shipping_city,
  shipping_state,
  discount,
  tax,
  total_amount,
  CURRENT_TIMESTAMP() AS _loaded_at,
  'gs://test-bkt-20261525/retail/orders.csv' AS _source_file
FROM `gcp-evening-batch-501811.retail_raw.ext_orders`;

-- -----------------------------------------------------------------------------
-- BRONZE: order_items
-- Cluster by order_id and product_id for join performance
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE `gcp-evening-batch-501811.retail_bronze.order_items`
CLUSTER BY order_id, product_id
AS
SELECT
  order_item_id,
  order_id,
  product_id,
  quantity,
  unit_price,
  CURRENT_TIMESTAMP() AS _loaded_at,
  'gs://test-bkt-20261525/retail/order_items.csv' AS _source_file
FROM `gcp-evening-batch-501811.retail_raw.ext_order_items`;

-- -----------------------------------------------------------------------------
-- BRONZE: payments
-- Partition by payment_date for time-range analytics
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE `gcp-evening-batch-501811.retail_bronze.payments`
PARTITION BY payment_date
CLUSTER BY order_id, payment_method
AS
SELECT
  payment_id,
  order_id,
  payment_method,
  payment_status,
  SAFE.PARSE_DATE('%Y-%m-%d', payment_date) AS payment_date,
  CURRENT_TIMESTAMP() AS _loaded_at,
  'gs://test-bkt-20261525/retail/payments.csv' AS _source_file
FROM `gcp-evening-batch-501811.retail_raw.ext_payments`;

-- =============================================================================
-- TABLE EXPIRATION EXAMPLE (optional — for dev/staging environments)
-- Uncomment to auto-delete bronze staging tables after 30 days
-- =============================================================================
/*
ALTER TABLE `gcp-evening-batch-501811.retail_bronze.orders`
SET OPTIONS (expiration_timestamp = TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 30 DAY));
*/

-- =============================================================================
-- VERIFICATION: Partition and cluster metadata
-- =============================================================================
/*
SELECT
  table_name,
  partitioning_type,
  clustering_fields,
  total_rows,
  ROUND(size_bytes / POW(1024, 2), 2) AS size_mb
FROM `gcp-evening-batch-501811.retail_bronze.INFORMATION_SCHEMA.TABLES`
WHERE table_type = 'BASE TABLE'
ORDER BY table_name;
*/

-- =============================================================================
-- INCREMENTAL LOAD PATTERN (for production)
-- Append new records using INSERT INTO ... SELECT with watermark filter
-- =============================================================================
/*
INSERT INTO `gcp-evening-batch-501811.retail_bronze.orders`
SELECT ... FROM `gcp-evening-batch-501811.retail_raw.ext_orders`
WHERE order_date > (SELECT MAX(order_date) FROM `gcp-evening-batch-501811.retail_bronze.orders`);
*/
