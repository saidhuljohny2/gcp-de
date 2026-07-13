# BigQuery Concepts – RetailPulse Reference

A practical guide to BigQuery features demonstrated in the RetailPulse project, with examples tied to actual project tables.

---

## Table of Contents

1. [Datasets and Projects](#1-datasets-and-projects)
2. [External Tables](#2-external-tables)
3. [Native Tables and CTAS](#3-native-tables-and-ctas)
4. [Partitioning](#4-partitioning)
5. [Clustering](#5-clustering)
6. [Table Expiration](#6-table-expiration)
7. [Logical Views](#7-logical-views)
8. [Materialized Views](#8-materialized-views)
9. [Cost Optimization](#9-cost-optimization)
10. [Query Execution and Dry Runs](#10-query-execution-and-dry-runs)
11. [INFORMATION_SCHEMA](#11-information_schema)

---

## 1. Datasets and Projects

A **project** contains **datasets**, which contain **tables, views, and routines**.

```
retailpulse-project          ← GCP Project
├── retail_raw               ← Dataset (schema)
│   └── ext_orders           ← External Table
├── retail_bronze
│   └── orders               ← Native Table
├── retail_silver
│   └── fact_orders
└── retail_gold
    └── daily_sales
```

### Fully Qualified Table Names

```sql
`project_id.dataset_id.table_id`
-- Example:
`retailpulse-project.retail_bronze.orders`
```

### Dataset Creation with Options

```sql
CREATE SCHEMA IF NOT EXISTS `retailpulse-project.retail_bronze`
OPTIONS (
  description = 'Bronze layer: native tables with raw schema',
  location = 'US',
  default_table_expiration_ms = 7776000000  -- 90 days
);
```

**RetailPulse datasets:** `retail_raw`, `retail_bronze`, `retail_silver`, `retail_gold` — all in `US` location for co-location with the GCS bucket.

---

## 2. External Tables

External tables define a schema over files stored **outside** BigQuery managed storage (typically GCS).

### RetailPulse Example

```sql
CREATE OR REPLACE EXTERNAL TABLE `retailpulse-project.retail_raw.ext_orders`
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
  uris = ['gs://retailpulse-data-lake/raw/orders.csv'],
  skip_leading_rows = 1,
  allow_quoted_newlines = TRUE
);
```

### Advantages

| Advantage | Explanation |
|-----------|-------------|
| No data duplication | Files stay in GCS; BigQuery reads at query time |
| Fast setup | No load job required |
| Cost-effective storage | GCS Standard ~$0.020/GB/month vs BQ active storage |
| Data lake pattern | Ideal for medallion raw layer |

### Limitations

| Limitation | Explanation |
|------------|-------------|
| No partitioning/clustering | Cannot optimize storage layout |
| No DML | Cannot INSERT, UPDATE, DELETE |
| Slower queries | Reads from GCS on every query |
| Schema drift risk | CSV changes can break queries silently |

### When to Use External vs Native

| Use External When | Use Native When |
|-------------------|-----------------|
| Exploring new data sources | Production analytics |
| Data changes infrequently | Repeated query access |
| Storage cost is a concern | Performance is critical |
| Raw landing zone | Bronze layer and below |

---

## 3. Native Tables and CTAS

**CREATE TABLE AS SELECT (CTAS)** materializes query results into a managed BigQuery table.

### RetailPulse Bronze Pattern

```sql
CREATE OR REPLACE TABLE `retailpulse-project.retail_bronze.orders`
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
  'gs://retailpulse-data-lake/raw/orders.csv' AS _source_file
FROM `retailpulse-project.retail_raw.ext_orders`;
```

### CTAS Benefits

- Atomic table creation with data
- Inherits partitioning and clustering from DDL
- Single operation replaces CREATE + INSERT
- Used for full-refresh bronze, silver, and gold layers

### CREATE OR REPLACE vs INSERT

| Pattern | Use Case |
|---------|----------|
| CREATE OR REPLACE TABLE AS SELECT | Full refresh (teaching project) |
| INSERT INTO ... SELECT | Incremental append (production) |
| MERGE INTO ... WHEN MATCHED | Upsert / slowly changing dimensions |

---

## 4. Partitioning

Partitioning divides a table into segments based on a column value, enabling **partition pruning** — BigQuery scans only relevant partitions.

### Types of Partitioning

| Type | Column Type | Example |
|------|-------------|---------|
| Time-unit | DATE, TIMESTAMP, DATETIME | PARTITION BY order_date |
| Integer range | INT64 | PARTITION BY RANGE_BUCKET(user_id, GENERATE_ARRAY(0, 1000000, 10000)) |
| Ingestion time | Pseudo-column _PARTITIONTIME | PARTITION BY _PARTITIONDATE |

### RetailPulse Partitioned Tables

```sql
-- bronze.orders: partitioned by order_date (DATE)
CREATE OR REPLACE TABLE `retailpulse-project.retail_bronze.orders`
PARTITION BY order_date
CLUSTER BY customer_id, status
AS SELECT ...;

-- bronze.payments: partitioned by payment_date (DATE)
CREATE OR REPLACE TABLE `retailpulse-project.retail_bronze.payments`
PARTITION BY payment_date
CLUSTER BY order_id, payment_method
AS SELECT ...;
```

### Partition Pruning in Action

```sql
-- Scans only 31 partitions (January 2025)
SELECT SUM(total_amount)
FROM `retailpulse-project.retail_bronze.orders`
WHERE order_date BETWEEN '2025-01-01' AND '2025-01-31';

-- Scans ALL partitions (no pruning)
SELECT SUM(total_amount)
FROM `retailpulse-project.retail_bronze.orders`
WHERE customer_id = 'CUST00042';
```

### Partitioning Best Practices

1. **Partition on columns used in WHERE filters** — typically date columns
2. **Require partition filter in production** — `require_partition_filter = TRUE`
3. **Avoid over-partitioning small tables** — customers (500 rows) does not need partitioning
4. **Use DATE not TIMESTAMP** when time-of-day is irrelevant
5. **Monitor partition count** — BigQuery allows up to 4,000 partitions per table

### Require Partition Filter

```sql
ALTER TABLE `retailpulse-project.retail_bronze.orders`
SET OPTIONS (require_partition_filter = TRUE);
```

---

## 5. Clustering

Clustering sorts data within partitions (or across the table if unpartitioned) by up to **four columns**, co-locating related rows for faster scans.

### RetailPulse Clustered Tables

| Table | Cluster Columns | Rationale |
|-------|----------------|-----------|
| bronze.customers | customer_id | Point lookups and joins |
| bronze.products | product_id, category | Product joins and category filters |
| bronze.orders | customer_id, status | Customer history and status filters |
| bronze.order_items | order_id, product_id | Join to orders and products |
| bronze.payments | order_id, payment_method | Payment joins and method analysis |

### Example

```sql
CREATE OR REPLACE TABLE `retailpulse-project.retail_bronze.order_items`
CLUSTER BY order_id, product_id
AS SELECT ...;
```

### Partitioning vs Clustering

| Feature | Partitioning | Clustering |
|---------|-------------|------------|
| Mechanism | Divides table into segments | Sorts data within segments |
| Best for | Date/time range filters | Equality filters and joins |
| Cost impact | Eliminates partition scans | Reduces bytes within partition |
| Column limit | 1 partition column | Up to 4 cluster columns |
| Can combine? | Yes — partition + cluster is ideal | Yes |

### Automatic Reclustering

BigQuery automatically reclusters data during background optimization. No manual maintenance required.

---

## 6. Table Expiration

Automatically delete tables after a specified time — useful for dev/staging environments.

### Dataset-Level Default

```sql
CREATE SCHEMA `retailpulse-project.retail_raw`
OPTIONS (
  default_table_expiration_ms = 7776000000  -- 90 days in milliseconds
);
```

### Table-Level Expiration

```sql
ALTER TABLE `retailpulse-project.retail_bronze.orders`
SET OPTIONS (
  expiration_timestamp = TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
);
```

### RetailPulse Recommendation

- **Production gold tables:** No expiration
- **Dev bronze tables:** 30-day expiration
- **Temporary analysis tables:** 7-day expiration

---

## 7. Logical Views

Views are **virtual tables** defined by a SQL query. No data is stored; the query runs on each access.

### RetailPulse Example

```sql
CREATE OR REPLACE VIEW `retailpulse-project.retail_gold.vw_sales_summary`
AS
SELECT
  o.order_date,
  c.state_code,
  p.category,
  SUM(oi.line_revenue) AS revenue,
  COUNT(DISTINCT o.order_id) AS orders
FROM `retailpulse-project.retail_silver.fact_orders` o
JOIN `retailpulse-project.retail_silver.fact_order_items` oi USING (order_id)
JOIN `retailpulse-project.retail_silver.dim_customers` c USING (customer_id)
JOIN `retailpulse-project.retail_silver.dim_products` p USING (product_id)
GROUP BY 1, 2, 3;
```

### Views vs Tables

| Aspect | View | Table |
|--------|------|-------|
| Storage cost | None | Charged per GB |
| Query cost | Full query each time | Scan stored data |
| Freshness | Always current | Depends on refresh |
| Use case | Abstraction layer | Performance-critical |

---

## 8. Materialized Views

Materialized views **pre-compute and store** query results, automatically refreshing when base tables change.

### RetailPulse Example

```sql
CREATE MATERIALIZED VIEW `retailpulse-project.retail_gold.mv_daily_revenue`
OPTIONS (
  enable_refresh = TRUE,
  refresh_interval_minutes = 60
)
AS
SELECT
  order_date,
  SUM(total_amount) AS daily_revenue,
  COUNT(DISTINCT order_id) AS order_count,
  COUNT(DISTINCT customer_id) AS customer_count
FROM `retailpulse-project.retail_silver.fact_orders`
GROUP BY order_date;
```

### Materialized View Benefits

| Benefit | Detail |
|---------|--------|
| Query acceleration | BigQuery rewrites queries to use MV when possible |
| Automatic refresh | No manual scheduling for simple MVs |
| Cost reduction | Avoid re-scanning silver tables for common aggregations |
| BI performance | Dashboard queries hit pre-aggregated data |

### Limitations

- Not all SQL constructs are supported (no DISTINCT on STRUCT, limited JOIN types)
- Storage cost for materialized data
- Refresh lag depending on `refresh_interval_minutes`
- Maximum 50 materialized views per dataset

### When to Use

| Use Materialized View | Use Regular Table (Gold) |
|-----------------------|--------------------------|
| Simple aggregations | Complex multi-join logic |
| Automatic refresh needed | Custom refresh schedule |
| Query rewrite benefit | Full control over schema |

---

## 9. Cost Optimization

BigQuery pricing has two components: **storage** and **query (bytes processed)**.

### Storage Pricing (Approximate)

| Tier | Cost |
|------|------|
| Active storage | $0.02/GB/month |
| Long-term storage (90+ days unmodified) | $0.01/GB/month |

### Query Pricing (On-Demand)

| Tier | Cost |
|------|------|
| On-demand | $5/TB scanned |
| Free tier | 1 TB/month free |

### Optimization Techniques in RetailPulse

#### 1. Partition Pruning

Always filter on partition columns:

```sql
-- Good: scans ~1/24 of data for 1 month of 2 years
WHERE order_date >= '2025-06-01'

-- Bad: full table scan
WHERE customer_id = 'CUST00001'
```

#### 2. Clustering for Joins

Cluster `order_items` by `order_id` so joins to `orders` scan fewer blocks.

#### 3. Select Only Needed Columns

```sql
-- Good
SELECT order_id, total_amount FROM bronze.orders

-- Bad
SELECT * FROM bronze.orders
```

#### 4. Use Gold Tables for Dashboards

Pre-aggregated `daily_sales` scans kilobytes vs gigabytes from silver facts.

#### 5. Materialized Views

Let BigQuery rewrite dashboard queries to hit `mv_daily_revenue`.

#### 6. Avoid SELECT DISTINCT on Large Tables

Use GROUP BY or window functions instead when possible.

#### 7. Use APPROX_COUNT_DISTINCT for Estimates

```sql
SELECT APPROX_COUNT_DISTINCT(customer_id) FROM fact_orders;
```

#### 8. Cache Awareness

BigQuery caches identical queries for 24 hours at no cost. Re-running the same dashboard query is free within the cache window.

### Cost Monitoring

```sql
-- Table storage sizes
SELECT
  table_schema,
  table_name,
  ROUND(size_bytes / POW(1024, 3), 4) AS size_gb,
  row_count
FROM `retailpulse-project.retail_bronze.INFORMATION_SCHEMA.TABLE_STORAGE`
ORDER BY size_bytes DESC;
```

---

## 10. Query Execution and Dry Runs

### Dry Run

Estimate bytes processed **without executing** the query or incurring cost.

```bash
bq query --use_legacy_sql=false --dry_run '
SELECT COUNT(*) FROM `retailpulse-project.retail_bronze.orders`
WHERE order_date >= "2025-01-01"
'
```

Output example:
```
Query successfully validated. Assuming the tables are not modified, running this query will process 245,760 bytes.
```

### Execution Plan

In BigQuery Console, click **Execution Details** after running a query to see:

- Stages and parallelism
- Bytes read per stage
- Whether partition pruning occurred
- Whether a materialized view was used (MV rewrite)

### RetailPulse Teaching Exercise

1. Run a dry run on `SELECT * FROM bronze.orders` (no filter)
2. Run a dry run with `WHERE order_date >= '2025-01-01'`
3. Compare bytes processed — demonstrate partition pruning savings

---

## 11. INFORMATION_SCHEMA

BigQuery exposes metadata through `INFORMATION_SCHEMA` views.

### Useful Queries

```sql
-- List all RetailPulse tables
SELECT table_schema, table_name, table_type
FROM `retailpulse-project.region-us.INFORMATION_SCHEMA.TABLES`
WHERE table_schema LIKE 'retail_%'
ORDER BY table_schema, table_name;

-- Partitioning and clustering details
SELECT
  table_name,
  ddl
FROM `retailpulse-project.retail_bronze.INFORMATION_SCHEMA.TABLES`
WHERE table_type = 'BASE TABLE';

-- Column metadata
SELECT table_name, column_name, data_type, is_nullable
FROM `retailpulse-project.retail_silver.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'fact_orders'
ORDER BY ordinal_position;

-- Storage and row counts
SELECT
  table_name,
  total_rows,
  ROUND(size_bytes / 1024, 2) AS size_kb
FROM `retailpulse-project.retail_gold.INFORMATION_SCHEMA.TABLE_STORAGE`;
```

---

## Quick Reference Card

| Concept | RetailPulse File | Key Table |
|---------|-----------------|-----------|
| Dataset creation | 01_create_datasets.sql | retail_bronze |
| External tables | 02_external_tables.sql | ext_orders |
| CTAS + partition | 03_bronze_tables.sql | orders |
| Clustering | 03_bronze_tables.sql | order_items |
| Logical views | 06_views.sql | vw_sales_summary |
| Materialized views | 06_views.sql | mv_daily_revenue |
| Cost optimization | All files | gold.daily_sales |

---

## Related Documentation

- [docs/MedallionArchitecture.md](MedallionArchitecture.md)
- [docs/SQLConcepts.md](SQLConcepts.md)
- [sql/03_bronze_tables.sql](../sql/03_bronze_tables.sql)
- [sql/06_views.sql](../sql/06_views.sql)
