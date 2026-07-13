# RetailPulse Teaching Guide

## 90-Minute Classroom Session

**Audience:** Data engineering students with basic SQL knowledge  
**Platform:** Google BigQuery + Cloud Storage + Looker Studio  
**Goal:** Build a complete Medallion Architecture data warehouse from scratch  
**Prerequisites:** GCP account, gcloud CLI installed, SQL fundamentals

---

## Session Timeline

| Time | Module | Activity | Materials |
|------|--------|----------|-----------|
| 0:00–0:10 | Introduction | Project overview, business context, architecture diagram | README.md, architecture.png |
| 0:10–0:20 | GCP Setup | Create project, bucket, upload CSVs | datasets/*.csv |
| 0:20–0:30 | Raw Layer | External tables concept, demo, dry run | 02_external_tables.sql |
| 0:30–0:45 | Bronze Layer | CTAS, partitioning, clustering demo | 03_bronze_tables.sql |
| 0:45–1:05 | Silver Layer | Transformations, window functions, QUALIFY | 04_silver_tables.sql |
| 1:05–1:15 | Gold Layer | Business aggregates, KPI tables | 05_gold_tables.sql |
| 1:15–1:25 | Analytics & Dashboard | Sample queries, Looker Studio walkthrough | 07_analytics.sql, looker_dashboard.md |
| 1:25–1:30 | Wrap-up | Q&A, assignments, interview prep | This guide |

---

## Module 1: Introduction (10 minutes)

### Talking Points

1. **Why retail?** Everyone understands buying products online — relatable domain
2. **Why medallion?** Industry-standard pattern used by Databricks, Snowflake, and GCP teams
3. **Why BigQuery?** Serverless, SQL-native, integrates with GCS and Looker Studio
4. **What will we build?** 4 datasets, 25+ tables, 55 analytical queries, 1 dashboard

### Demo

Show the architecture diagram (`architecture/architecture.png`) and walk through the data flow:

```
CSV → GCS → External Tables → Bronze → Silver → Gold → Dashboard
```

### Discussion Questions

- What happens if we skip the bronze layer and go straight from external to silver?
- Why not put everything in one dataset?
- Who are the consumers at each layer?

---

## Module 2: GCP Setup (10 minutes)

### Instructor Demo

```bash
export PROJECT_ID="retailpulse-project"
gcloud config set project $PROJECT_ID
gcloud services enable bigquery.googleapis.com storage.googleapis.com

export BUCKET="retailpulse-data-lake"
gsutil mb -l US gs://$BUCKET/

cd RetailPulse
gsutil -m cp datasets/*.csv gs://$BUCKET/raw/
gsutil ls -l gs://$BUCKET/raw/
```

### Student Task

Each student creates their own project and bucket. Replace `retailpulse-project` in SQL files with their project ID.

### Checkpoint

Every student should see 5 CSV files in their GCS bucket before proceeding.

---

## Module 3: Raw Layer — External Tables (10 minutes)

### Concepts to Cover

| Concept | Explanation |
|---------|-------------|
| External table | BigQuery table definition over GCS files |
| Schema-on-read | Types defined in DDL, not enforced at write |
| No DML | Cannot INSERT/UPDATE/DELETE |
| Cost | GCS storage + bytes scanned per query |

### Live Demo

```sql
-- Run 01_create_datasets.sql first
-- Then run 02_external_tables.sql

-- Validate row counts
SELECT 'customers' AS tbl, COUNT(*) AS rows FROM `retailpulse-project.retail_raw.ext_customers`
UNION ALL SELECT 'orders', COUNT(*) FROM `retailpulse-project.retail_raw.ext_orders`;
```

### Dry Run Demo

```bash
bq query --use_legacy_sql=false --dry_run \
  'SELECT COUNT(*) FROM `retailpulse-project.retail_raw.ext_orders`'
```

Show bytes processed — explain this is what you pay for.

### Discussion

- When would you use external tables in production?
- What are the risks of querying external tables for dashboards?

---

## Module 4: Bronze Layer (15 minutes)

### Concepts to Cover

| Concept | Explanation |
|---------|-------------|
| CTAS | CREATE TABLE AS SELECT — materialize data |
| Partitioning | Divide table by date for pruning |
| Clustering | Sort within partitions for join performance |
| Metadata columns | _loaded_at, _source_file for lineage |

### Live Demo

Run `03_bronze_tables.sql`, then inspect table metadata:

```sql
SELECT table_name, partitioning_type, clustering_fields, total_rows
FROM `retailpulse-project.retail_bronze.INFORMATION_SCHEMA.TABLES`
WHERE table_type = 'BASE TABLE';
```

### Partition Pruning Demo

```sql
-- Compare bytes processed with and without date filter
-- Run as dry run first!

-- Full scan
SELECT COUNT(*) FROM `retailpulse-project.retail_bronze.orders`;

-- Partition pruned
SELECT COUNT(*) FROM `retailpulse-project.retail_bronze.orders`
WHERE order_date >= '2025-01-01';
```

### Student Exercise 1 (5 minutes)

> Run a dry run on both queries above. Record the bytes processed for each. Calculate the percentage savings from partition pruning.

---

## Module 5: Silver Layer (20 minutes)

### Concepts to Cover

| Concept | Explanation |
|---------|-------------|
| Data quality rules | DQ-01 through DQ-13 |
| CTEs | WITH clauses for readable pipelines |
| Window functions | ROW_NUMBER, RANK, LAG, NTILE |
| QUALIFY | Filter window results without subquery |
| Star schema | Facts and dimensions |

### Live Demo

Run `04_silver_tables.sql`. Then demonstrate data quality impact:

```sql
-- Bronze has duplicates; silver does not
SELECT 'bronze' AS layer, COUNT(*) AS rows, COUNT(DISTINCT customer_id) AS distinct_customers
FROM `retailpulse-project.retail_bronze.customers`
UNION ALL
SELECT 'silver', COUNT(*), COUNT(DISTINCT customer_id)
FROM `retailpulse-project.retail_silver.dim_customers`;
```

### Window Function Walkthrough

Walk through one window function example live:

```sql
SELECT
  customer_id,
  order_date,
  total_amount,
  LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order,
  DATE_DIFF(order_date,
    LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date), DAY
  ) AS days_since_last
FROM `retailpulse-project.retail_silver.fact_orders`
WHERE customer_id = 'CUST00001'
ORDER BY order_date;
```

### Student Exercise 2 (10 minutes)

> Write a query to find the top 5 customers by total revenue using only silver layer tables. Use a CTE for line-item revenue aggregation.

**Expected solution:**

```sql
WITH customer_revenue AS (
  SELECT
    o.customer_id,
    SUM(oi.line_revenue) AS total_revenue
  FROM `retailpulse-project.retail_silver.fact_orders` o
  JOIN `retailpulse-project.retail_silver.fact_order_items` oi USING (order_id)
  GROUP BY o.customer_id
)
SELECT customer_id, total_revenue
FROM customer_revenue
ORDER BY total_revenue DESC
LIMIT 5;
```

---

## Module 6: Gold Layer (10 minutes)

### Concepts to Cover

| Concept | Explanation |
|---------|-------------|
| Business aggregates | Pre-computed KPIs for dashboards |
| Denormalization | Wide tables for BI consumption |
| Rankings | Pre-computed RANK for top-N |
| Executive KPIs | Single-row summary table |

### Live Demo

```sql
-- Executive snapshot
SELECT * FROM `retailpulse-project.retail_gold.executive_kpis`;

-- Monthly trend
SELECT year_month, revenue, mom_growth_pct
FROM `retailpulse-project.retail_gold.monthly_sales`
ORDER BY year_month;

-- Top 5 products
SELECT product_name, revenue, revenue_rank
FROM `retailpulse-project.retail_gold.top_products`
ORDER BY revenue_rank
LIMIT 5;
```

### Student Exercise 3 (5 minutes)

> Query `customer_lifetime_value` and identify how many customers are in each segment (Platinum, Gold, Silver, Bronze).

---

## Module 7: Analytics & Dashboard (10 minutes)

### Live Demo

Run 3 queries from `07_analytics.sql`:

1. Q1: Top 10 customers by lifetime value
2. Q15: Monthly revenue trend with running total
3. Q30: Revenue by payment method

### Looker Studio Walkthrough

Follow `dashboard/looker_dashboard.md` to connect Looker Studio to `retail_gold` tables and build:

- Revenue KPI scorecard
- Monthly revenue time series
- Sales by state map
- Top products bar chart

---

## Module 8: Wrap-up (5 minutes)

### Key Takeaways

1. Medallion architecture provides clear layer boundaries and reprocessability
2. External tables for exploration; native tables for production
3. Partitioning and clustering are essential cost optimizations
4. Silver layer is where data quality and dimensional modeling happen
5. Gold layer serves business consumers with pre-built aggregates

### Homework Assignments

See [Assignments](#assignments) below.

---

## Student Exercises Summary

| # | Exercise | Time | Layer |
|---|----------|------|-------|
| 1 | Compare dry run bytes with/without partition filter | 5 min | Bronze |
| 2 | Top 5 customers by revenue from silver tables | 10 min | Silver |
| 3 | Customer segment distribution from gold | 5 min | Gold |
| 4 | Write a new gold table: weekly_sales | Homework | Gold |
| 5 | Answer 10 interview questions | Homework | All |

---

## Assignments

### Assignment 1: Weekly Sales Table (Intermediate)

Create a new gold table `weekly_sales` that aggregates revenue, order count, and unique customers by week.

**Requirements:**
- Use `DATE_TRUNC(order_date, WEEK)` for week grouping
- Include week-over-week growth percentage
- Add to `05_gold_tables.sql` or create `05b_weekly_sales.sql`

**Grading rubric:**
- Correct grain (one row per week): 25%
- Correct aggregations: 25%
- WoW growth calculation: 25%
- SQL style (CTEs, comments): 25%

### Assignment 2: Data Quality Report (Intermediate)

Write a SQL query that produces a data quality report comparing bronze vs silver row counts for all 5 entity types, showing records removed and removal percentage.

### Assignment 3: Customer Cohort Analysis (Advanced)

Using only silver tables, build a cohort analysis showing retention by signup month. Each cohort row should show the percentage of customers who placed an order in month 0, month 1, month 2, etc.

### Assignment 4: Looker Studio Dashboard (Intermediate)

Build a complete Looker Studio dashboard following `dashboard/looker_dashboard.md` with all 9 visualizations. Submit a shareable link.

### Assignment 5: Incremental Load Design (Advanced)

Write a design document (1 page) describing how you would modify the bronze layer to support incremental daily loads instead of full CTAS refresh. Include SQL pseudocode for the INSERT pattern.

---

## Instructor Notes

### Common Student Mistakes

| Mistake | Correction |
|---------|------------|
| Forgetting to replace project ID | Global find-replace before starting |
| Running SQL files out of order | Enforce 01 → 07 sequence |
| Using SELECT * in production queries | Emphasize column selection for cost |
| Joining facts without aggregation (fan-out) | Teach aggregate-first pattern |
| Skipping dry run | Make dry run a habit before every large query |

### Pacing Adjustments

| If Running Behind | Cut This |
|-------------------|----------|
| 5 minutes behind | Shorten Exercise 3; assign as homework |
| 10 minutes behind | Skip Looker demo; share pre-built dashboard link |
| 15 minutes behind | Combine Modules 6 and 7 |

### Room Setup

- Students need GCP accounts with billing enabled
- Projector for live SQL demos
- Shared Google Doc for troubleshooting common errors
- Pre-created "lab" GCP project as fallback for students with billing issues

---

## 50 BigQuery Interview Questions with Answers

### Section A: BigQuery Fundamentals (Q1–Q10)

**Q1: What is BigQuery and how does it differ from traditional databases?**

BigQuery is Google Cloud's serverless, petabyte-scale data warehouse. Unlike traditional databases, it separates storage and compute, requires no infrastructure management, scales automatically, and charges based on data stored and bytes processed per query rather than provisioned capacity.

**Q2: What are the three hierarchy levels in BigQuery?**

Project → Dataset → Table/View. In RetailPulse: `retailpulse-project` (project) → `retail_bronze` (dataset) → `orders` (table).

**Q3: What is the difference between on-demand and flat-rate pricing?**

On-demand charges $5/TB of data processed per query (with 1 TB/month free). Flat-rate uses slot reservations (hourly cost) for predictable workloads with high query volume. RetailPulse uses on-demand due to small data size.

**Q4: What is a slot in BigQuery?**

A slot is a unit of computational capacity (CPU + memory) used to execute query stages. On-demand queries use shared slots; flat-rate reserves dedicated slots. Complex queries use more slots across parallel stages.

**Q5: What SQL dialect does BigQuery use?**

Standard SQL (ANSI-compliant with extensions). Legacy SQL is deprecated. Always use `standard_sql=true` or `--use_legacy_sql=false`.

**Q6: How does BigQuery handle nested and repeated data?**

BigQuery supports STRUCT (nested records) and ARRAY (repeated fields) natively in columnar format. RetailPulse uses flat tables, but nested data is common in event logs and API responses.

**Q7: What is the difference between CREATE TABLE and CREATE TABLE AS SELECT?**

CREATE TABLE creates an empty table with a defined schema. CTAS creates a table and populates it from a query in one atomic operation. RetailPulse bronze layer uses CTAS to materialize external table data.

**Q8: What regions are available and why does location matter?**

BigQuery is available in multiple regions (US, EU, asia-northeast1, etc.). Location matters for data residency compliance, latency, and co-location with GCS buckets. All RetailPulse datasets use `US` multi-region.

**Q9: How do you list all tables in a dataset?**

```sql
SELECT table_name, table_type
FROM `project_id.dataset_id.INFORMATION_SCHEMA.TABLES`;
```

Or use `bq ls project_id:dataset_id` in the CLI.

**Q10: What is the maximum row size and column count in BigQuery?**

Maximum row size is 100 MB. Maximum columns per table is 10,000. RetailPulse tables have 10–15 columns — well within limits.

---

### Section B: External Tables and Data Ingestion (Q11–Q18)

**Q11: What is an external table in BigQuery?**

An external table is a table definition that maps to data stored outside BigQuery managed storage (typically GCS). BigQuery reads the data at query time without loading it. RetailPulse uses external tables in `retail_raw` for all 5 CSV files.

**Q12: What file formats do external tables support?**

CSV, JSON (newline-delimited), Avro, Parquet, ORC, and Google Sheets. CSV is used in RetailPulse for simplicity; Parquet is recommended for production due to columnar compression.

**Q13: Can you partition or cluster an external table?**

No. Partitioning and clustering are only available on native BigQuery tables. This is a key reason to materialize external data into bronze native tables.

**Q14: What are the cost implications of external tables?**

You pay GCS storage costs (~$0.020/GB/month) plus BigQuery query costs (bytes scanned from GCS). There is no BigQuery active storage charge for external table data itself.

**Q15: How do you load data from GCS into a native BigQuery table?**

Three methods: (1) CTAS from external table (RetailPulse approach), (2) LOAD DATA SQL statement, (3) `bq load` CLI command. CTAS is simplest for full refresh.

**Q16: What is the difference between a load job and a query job?**

A load job ingests data from GCS into a native table (charges for data loaded). A query job runs SQL and charges by bytes processed. CTAS is a query job that also writes results.

**Q17: How would you handle schema evolution in the bronze layer?**

Add new columns to bronze via ALTER TABLE ADD COLUMN (existing rows get NULL). Changed column types require a new table version. Bronze's append-only design means old data retains original schema; new columns are populated on subsequent loads.

**Q18: What is hive partitioning for external tables?**

Hive partitioning maps directory structure to partition columns (e.g., `gs://bucket/orders/dt=2025-07-01/file.csv`). BigQuery auto-discovers partitions from paths. Not used in RetailPulse but essential for production incremental loads.

---

### Section C: Partitioning and Clustering (Q19–Q26)

**Q19: What is table partitioning in BigQuery?**

Partitioning divides a table into segments based on a column value (typically DATE). Queries with partition filters scan only relevant segments, reducing cost and improving performance.

**Q20: What partitioning types does BigQuery support?**

Time-unit (DAY/HOUR/MONTH/YEAR on DATE/TIMESTAMP), integer range (RANGE_BUCKET), and ingestion-time (_PARTITIONTIME pseudo-column).

**Q21: Which RetailPulse tables are partitioned and why?**

`bronze.orders` (by order_date) and `bronze.payments` (by payment_date). These are the largest fact tables with time-range query patterns. Dimension tables (customers, products) are too small to benefit.

**Q22: What is clustering in BigQuery?**

Clustering sorts data within partitions by up to 4 columns, co-locating related rows. Improves performance for filters and joins on clustered columns. Automatically maintained by BigQuery.

**Q23: Can you partition and cluster the same table?**

Yes, and this is a best practice. RetailPulse `bronze.orders` is partitioned by `order_date` and clustered by `customer_id, status` — partition pruning for date filters, clustering for customer/status filters.

**Q24: What is partition pruning?**

When a query filters on the partition column, BigQuery skips scanning irrelevant partitions entirely. A query on one month of data in a 2-year table scans ~1/24 of the data.

**Q25: What is `require_partition_filter`?**

A table option that rejects queries not filtering on the partition column. Prevents accidental full-table scans. Recommended for production partitioned tables.

**Q26: How many partitions can a BigQuery table have?**

Maximum 4,000 partitions per table. With daily partitioning, this supports ~11 years of data. For longer retention, use monthly partitioning.

---

### Section D: SQL and Transformations (Q27–Q36)

**Q27: What is a CTE and why use it over subqueries?**

A Common Table Expression (WITH clause) names a subquery for readability and reuse. CTEs are easier to debug (run individually), avoid deep nesting, and communicate pipeline steps clearly. RetailPulse silver layer uses 3–5 CTEs per table.

**Q28: Explain ROW_NUMBER vs RANK vs DENSE_RANK.**

ROW_NUMBER assigns unique sequential integers (1,2,3,4). RANK assigns same rank to ties with gaps (1,2,2,4). DENSE_RANK assigns same rank to ties without gaps (1,2,2,3). RetailPulse uses ROW_NUMBER for deduplication, RANK for product rankings, DENSE_RANK for customer frequency.

**Q29: What is the QUALIFY clause?**

BigQuery-specific clause that filters window function results without a subquery — like HAVING for window functions. `QUALIFY ROW_NUMBER() OVER (...) = 1` replaces wrapping in `SELECT * FROM (...) WHERE rn = 1`.

**Q30: What is a star schema?**

A dimensional model with central fact tables (measurable events) surrounded by dimension tables (descriptive attributes). RetailPulse silver layer implements a star schema with fact_orders, fact_order_items, and dim_customers, dim_products, dim_payments.

**Q31: What is the difference between WHERE and HAVING?**

WHERE filters rows before aggregation. HAVING filters groups after aggregation. Example: `WHERE status = 'Completed'` filters rows; `HAVING COUNT(*) > 5` filters customer groups with more than 5 orders.

**Q32: How does SAFE.PARSE_DATE differ from PARSE_DATE?**

PARSE_DATE throws an error on invalid input. SAFE.PARSE_DATE returns NULL on invalid input. RetailPulse uses SAFE.PARSE_DATE in bronze to handle intentionally bad dates in sample data without failing the pipeline.

**Q33: What is a MERGE statement and when would you use it?**

MERGE (upsert) inserts new rows and updates existing rows in one statement. Used for slowly changing dimensions and incremental loads. Pattern: `MERGE INTO target USING source ON key WHEN MATCHED THEN UPDATE WHEN NOT MATCHED THEN INSERT`.

**Q34: Explain LAG and LEAD with a RetailPulse example.**

LAG accesses the previous row; LEAD accesses the next row within a partition. In RetailPulse, `LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)` calculates days since the customer's previous order for repeat purchase analysis.

**Q35: What is NTILE used for?**

NTILE(N) divides rows into N roughly equal buckets. RetailPulse uses `NTILE(4)` to segment customers into quartiles: Platinum (top 25%), Gold, Silver, Bronze (bottom 25%).

**Q36: How do you prevent fan-out in joins?**

Aggregate to the correct grain before joining. If joining orders to order_items, aggregate line items to order level first (`GROUP BY order_id`) to prevent multiplying order-level measures.

---

### Section E: Cost Optimization (Q37–Q42)

**Q37: How can you estimate query cost before running it?**

Use dry run: `bq query --dry_run 'SELECT ...'`. Returns bytes that would be processed. Cost = bytes / 1TB × $5. BigQuery Console also shows estimated bytes in the query validator.

**Q38: What are the top 5 ways to reduce BigQuery query costs?**

1. Partition pruning (filter on partition column)
2. Clustering (reduce bytes within partitions)
3. Select only needed columns (avoid SELECT *)
4. Use pre-aggregated gold tables or materialized views
5. Use APPROX_COUNT_DISTINCT for large cardinality estimates

**Q39: What is the BigQuery query cache?**

BigQuery caches identical query results for 24 hours. Re-running the same query within 24 hours is free (no bytes processed). Cache is invalidated if any underlying table is modified.

**Q40: When should you use materialized views vs regular views?**

Materialized views pre-compute and store results (faster, storage cost, auto-refresh). Regular views are logical definitions that re-execute the full query each time. Use MVs for frequently-run aggregations; views for abstraction without storage cost.

**Q41: What is long-term storage pricing?**

Tables or partitions unmodified for 90+ consecutive days automatically move to long-term storage at $0.01/GB/month (50% discount). Bronze tables with append-only loads keep recent partitions on active pricing.

**Q42: How do you monitor BigQuery spending?**

Cloud Billing reports, BigQuery audit logs (`cloudaudit.googleapis.com`), INFORMATION_SCHEMA.JOBS for per-query bytes processed, and budget alerts in Cloud Billing.

---

### Section F: Architecture and Best Practices (Q43–Q50)

**Q43: What is Medallion Architecture?**

A data design pattern organizing data into progressively refined layers: Bronze (raw copy), Silver (cleaned and conformed), Gold (business aggregates). Each layer adds quality and semantic meaning. RetailPulse implements four layers: raw, bronze, silver, gold.

**Q44: Why not query the gold layer for everything?**

Gold tables are pre-aggregated and lose granular detail. Ad-hoc analysis requiring line-item or customer-level detail needs silver tables. Gold is for known reporting patterns; silver is for exploratory analysis.

**Q45: What is data lineage and how does RetailPulse track it?**

Data lineage traces data from source to consumption. RetailPulse tracks lineage via `_source_file` (GCS URI) and `_loaded_at` (ingestion timestamp) metadata columns in bronze tables.

**Q46: How would you implement incremental loading in production?**

1. Land new files in GCS with date partitions
2. INSERT INTO bronze SELECT FROM external table WHERE date > watermark
3. MERGE INTO silver for upsert logic
4. Rebuild or incrementally update gold tables
5. Orchestrate with Cloud Composer or scheduled queries

**Q47: What is the difference between a data lake, data warehouse, and lakehouse?**

Data lake stores raw files (GCS). Data warehouse stores structured, modeled data (BigQuery gold). Lakehouse combines both — BigQuery external tables over GCS with native tables for hot data, which is exactly the RetailPulse pattern.

**Q48: How do you handle slowly changing dimensions (SCD)?**

SCD Type 1: overwrite (RetailPulse teaching approach). SCD Type 2: add new row with effective dates and current flag. SCD Type 3: add previous value column. Production RetailPulse would use SCD Type 2 for dim_customers.

**Q49: What IAM roles are needed for a data engineer vs an analyst?**

Data Engineer: `roles/bigquery.dataEditor` (read/write all layers), `roles/storage.objectAdmin` (GCS access). Analyst: `roles/bigquery.dataViewer` on gold/silver only, optionally via authorized views to restrict PII.

**Q50: How would you test a BigQuery pipeline before production deployment?**

1. Row count validation (bronze vs source, silver vs bronze)
2. Schema validation (INFORMATION_SCHEMA.COLUMNS comparison)
3. Business rule assertions (no negative revenue in gold)
4. Dry run cost checks
5. Reconciliation queries (sum of line items = order total)
6. CI/CD with Cloud Build running SQL against a dev project

---

## Additional Resources

| Resource | URL |
|----------|-----|
| BigQuery Documentation | https://cloud.google.com/bigquery/docs |
| BigQuery Best Practices | https://cloud.google.com/bigquery/docs/best-practices-performance-overview |
| Looker Studio Help | https://support.google.com/looker-studio |
| Medallion Architecture | https://www.databricks.com/glossary/medallion-architecture |
| RetailPulse SQL Files | `sql/01_create_datasets.sql` through `sql/07_analytics.sql` |
