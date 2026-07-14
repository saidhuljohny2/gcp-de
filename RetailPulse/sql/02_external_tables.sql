-- =============================================================================
-- RetailPulse | 02_external_tables.sql
-- Purpose: Create External Tables over GCS CSV files (RAW Layer)
-- =============================================================================
--
-- WHAT ARE EXTERNAL TABLES?
-- -------------------------
-- External tables are BigQuery table definitions that query data stored OUTSIDE
-- BigQuery (e.g., Google Cloud Storage). BigQuery reads the files at query time
-- rather than loading them into managed storage.
--
-- ADVANTAGES:
--   • No data duplication — files stay in GCS (single source of truth)
--   • Fast to set up for exploration and prototyping
--   • Ideal for data lake / medallion "raw" landing patterns
--   • Storage cost is only GCS (cheaper than BQ active storage for cold data)
--
-- LIMITATIONS:
--   • Query performance slower than native tables (reads from GCS each query)
--   • No clustering or partitioning on external tables
--   • Limited DML support (cannot INSERT/UPDATE/DELETE into external tables)
--   • Schema enforcement depends on file format and hive partitioning setup
--
-- STORAGE COST:
--   • GCS Standard: ~$0.020/GB/month (us-central1, 2025 pricing)
--   • BigQuery query cost still applies (bytes scanned from GCS)
--   • No BigQuery active storage charge for external table data
--
-- =============================================================================
-- Prerequisites:
--   1. Upload CSV files from datasets/ to GCS bucket
--   2. Replace GCS URI below with your bucket path
--
-- Upload command example:
--   gsutil -m cp datasets/*.csv gs://YOUR_BUCKET/retailpulse/raw/
-- =============================================================================

-- GCS bucket path — UPDATE THIS
-- Default pattern: gs://test-bkt-20261525/retail/{table_name}.csv

-- -----------------------------------------------------------------------------
-- EXTERNAL TABLE: customers
-- -----------------------------------------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `gcp-evening-batch-501811.retail_raw.ext_customers`
(
  customer_id   STRING,
  first_name    STRING,
  last_name     STRING,
  gender        STRING,
  email         STRING,
  phone         STRING,
  city          STRING,
  state         STRING,
  country       STRING,
  signup_date   STRING  -- Kept as STRING in raw; parsed in silver layer
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://test-bkt-20261525/retail/customers.csv'],
  skip_leading_rows = 1,
  allow_quoted_newlines = TRUE,
  allow_jagged_rows = FALSE
);

-- -----------------------------------------------------------------------------
-- EXTERNAL TABLE: products
-- -----------------------------------------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `gcp-evening-batch-501811.retail_raw.ext_products`
(
  product_id     STRING,
  product_name   STRING,
  category       STRING,
  subcategory    STRING,
  brand          STRING,
  price          FLOAT64,
  cost           FLOAT64,
  launch_date    STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://test-bkt-20261525/retail/products.csv'],
  skip_leading_rows = 1
);

-- -----------------------------------------------------------------------------
-- EXTERNAL TABLE: orders
-- -----------------------------------------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `gcp-evening-batch-501811.retail_raw.ext_orders`
(
  order_id         STRING,
  customer_id      STRING,
  order_date       STRING,
  status           STRING,
  shipping_city    STRING,
  shipping_state   STRING,
  discount         FLOAT64,
  tax              FLOAT64,
  total_amount     FLOAT64
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://test-bkt-20261525/retail/orders.csv'],
  skip_leading_rows = 1
);

-- -----------------------------------------------------------------------------
-- EXTERNAL TABLE: order_items
-- -----------------------------------------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `gcp-evening-batch-501811.retail_raw.ext_order_items`
(
  order_item_id  STRING,
  order_id       STRING,
  product_id     STRING,
  quantity       INT64,
  unit_price     FLOAT64
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://test-bkt-20261525/retail/order_items.csv'],
  skip_leading_rows = 1
);

-- -----------------------------------------------------------------------------
-- EXTERNAL TABLE: payments
-- -----------------------------------------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `gcp-evening-batch-501811.retail_raw.ext_payments`
(
  payment_id       STRING,
  order_id         STRING,
  payment_method   STRING,
  payment_status   STRING,
  payment_date     STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://test-bkt-20261525/retail/payments.csv'],
  skip_leading_rows = 1
);

-- =============================================================================
-- VALIDATION: Row counts from external tables
-- =============================================================================
/*
SELECT 'customers'    AS source_table, COUNT(*) AS row_count FROM `gcp-evening-batch-501811.retail_raw.ext_customers`
UNION ALL
SELECT 'products',     COUNT(*) FROM `gcp-evening-batch-501811.retail_raw.ext_products`
UNION ALL
SELECT 'orders',       COUNT(*) FROM `gcp-evening-batch-501811.retail_raw.ext_orders`
UNION ALL
SELECT 'order_items',  COUNT(*) FROM `gcp-evening-batch-501811.retail_raw.ext_order_items`
UNION ALL
SELECT 'payments',     COUNT(*) FROM `gcp-evening-batch-501811.retail_raw.ext_payments`;
*/

-- =============================================================================
-- COST TIP: Use dry run before scanning large external tables
-- =============================================================================
/*
bq query --use_legacy_sql=false --dry_run '
SELECT COUNT(*) FROM `gcp-evening-batch-501811.retail_raw.ext_orders`
';
*/
