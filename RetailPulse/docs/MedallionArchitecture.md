# Medallion Architecture in RetailPulse

## What is Medallion Architecture?

Medallion Architecture is a data design pattern that organizes a lakehouse or warehouse into **progressively refined layers**, each named after a metal quality tier. Data flows in one direction — from raw ingestion to business-ready analytics — with each layer adding structure, quality, and semantic meaning.

Originally popularized by Databricks for Delta Lake, the pattern applies equally to BigQuery-centric pipelines where Cloud Storage serves as the lake and BigQuery datasets represent each medallion tier.

---

## The Three (Plus One) Layers

| Layer | Metal | Dataset | Quality | Mutability | Primary Audience |
|-------|-------|---------|---------|------------|------------------|
| Raw | — | `retail_raw` | Unvalidated | Append-only | Data Engineers |
| Bronze | Bronze | `retail_bronze` | Raw copy | Append-only | Data Engineers |
| Silver | Silver | `retail_silver` | Cleaned & conformed | Slowly changing | Analysts, Engineers |
| Gold | Gold | `retail_gold` | Business aggregates | Refresh on schedule | Executives, BI |

---

## Layer 0: Landing Zone (Cloud Storage)

Although not officially a "medallion" layer, GCS serves as the **landing zone** — the physical data lake where source files arrive before BigQuery registration.

### RetailPulse Implementation

```
gs://retailpulse-data-lake/
└── raw/
    ├── customers.csv      (500 rows)
    ├── products.csv       (200 rows)
    ├── orders.csv         (3,000 rows)
    ├── order_items.csv    (7,000 rows)
    └── payments.csv       (3,000 rows)
```

### Responsibilities

- Accept files from source systems without transformation
- Provide durable, low-cost storage
- Serve as the URI target for BigQuery external tables
- Retain files as the system of record for reprocessing

### Design Rules

1. **Never modify source files in place** — append new dated folders in production (`raw/orders/dt=2025-07-01/`)
2. **Use consistent naming** — lowercase, underscore-separated
3. **Include headers** — all CSV files have a header row
4. **Partition by date in production** — hive-style partitioning for incremental loads

---

## Layer 1: Raw — `retail_raw`

### Purpose

Register GCS files as **external tables** so BigQuery can query them without loading data into managed storage.

### Tables

| External Table | Source File | Rows |
|----------------|-------------|------|
| `ext_customers` | customers.csv | ~500 |
| `ext_products` | products.csv | ~200 |
| `ext_orders` | orders.csv | ~3,001 |
| `ext_order_items` | order_items.csv | ~7,001 |
| `ext_payments` | payments.csv | ~3,001 |

### Characteristics

- **Schema-on-read:** Types defined in DDL, not enforced at write time
- **No DML:** Cannot INSERT, UPDATE, or DELETE into external tables
- **No optimization:** Partitioning and clustering are not available
- **Cost model:** GCS storage + BigQuery bytes scanned per query

### When to Query Raw

- Initial data exploration before committing to a load
- Validating file arrival and row counts
- One-time audits comparing GCS to bronze

### When NOT to Query Raw

- Production dashboards (use gold)
- Repeated analytical queries (materialize to bronze)
- Joins across multiple large external tables (expensive)

### SQL File

`sql/02_external_tables.sql`

---

## Layer 2: Bronze — `retail_bronze`

### Purpose

Create an **immutable, native BigQuery copy** of raw data. Bronze is the foundation for all downstream transformations.

### Tables

| Native Table | Source | Partition | Cluster |
|--------------|--------|-----------|---------|
| `customers` | ext_customers | — | customer_id |
| `products` | ext_products | — | product_id, category |
| `orders` | ext_orders | order_date | customer_id, status |
| `order_items` | ext_order_items | — | order_id, product_id |
| `payments` | ext_payments | payment_date | order_id, payment_method |

### Transformations Applied

| Transformation | Rationale |
|----------------|-----------|
| CTAS from external tables | Materialize for performance |
| SAFE.PARSE_DATE on date columns | Convert STRING to DATE where obvious |
| Add `_loaded_at` timestamp | Track ingestion time |
| Add `_source_file` URI | Lineage and debugging |
| Partition orders and payments | Cost optimization for time-range queries |
| Cluster high-cardinality keys | Join and filter performance |

### Transformations NOT Applied

- No deduplication (preserve raw duplicates for silver to handle)
- No business rule filtering (cancelled orders remain)
- No referential integrity enforcement
- No column renaming beyond metadata

### Bronze Principles

1. **Append-only:** New data is inserted, never updated in place
2. **Schema preservation:** Column names match source unless type coercion is required
3. **Auditability:** Metadata columns enable lineage tracking
4. **Reprocessability:** Bronze can be rebuilt from raw at any time

### SQL File

`sql/03_bronze_tables.sql`

---

## Layer 3: Silver — `retail_silver`

### Purpose

Apply **data quality, standardization, and dimensional modeling** to produce a trusted analytics foundation.

### Star Schema Output

#### Dimensions

| Table | Grain | Key Columns |
|-------|-------|-------------|
| `dim_customers` | customer_id | name, email, state_code, signup_date, customer_tier |
| `dim_products` | product_id | name, category, brand, price, margin_pct, price_rank |
| `dim_payments` | payment_id | order_id, method, status, payment_date |

#### Facts

| Table | Grain | Measures |
|-------|-------|----------|
| `fact_orders` | order_id | total_amount, discount, tax, item_count, prev_order_date |
| `fact_order_items` | order_item_id | quantity, unit_price, line_revenue |

### Data Quality Rules

| Rule ID | Rule | SQL Pattern |
|---------|------|-------------|
| DQ-01 | Remove duplicate customers | ROW_NUMBER + QUALIFY |
| DQ-02 | Remove duplicate orders | ROW_NUMBER + QUALIFY |
| DQ-03 | Remove duplicate payments | ROW_NUMBER + QUALIFY |
| DQ-04 | Filter invalid emails | REGEXP_CONTAINS or NULLIF |
| DQ-05 | Parse and validate dates | SAFE.PARSE_DATE, filter NULL |
| DQ-06 | Standardize state to 2-letter code | CTE state_mapping |
| DQ-07 | Uppercase category names | UPPER(TRIM(category)) |
| DQ-08 | Remove negative prices | WHERE price >= 0 |
| DQ-09 | Remove negative order totals | WHERE total_amount >= 0 |
| DQ-10 | Exclude cancelled orders from facts | WHERE status = 'Completed' |
| DQ-11 | Enforce customer FK | INNER JOIN dim_customers |
| DQ-12 | Enforce product FK | INNER JOIN dim_products |
| DQ-13 | Remove orphan order items | INNER JOIN fact_orders |

### Window Functions in Silver

| Function | Usage in RetailPulse |
|----------|---------------------|
| ROW_NUMBER | Deduplication (PARTITION BY id ORDER BY _loaded_at DESC) |
| RANK | Product price ranking |
| DENSE_RANK | Customer order frequency ranking |
| LAG | Days since previous order per customer |
| LEAD | Days until next order per customer |
| FIRST_VALUE | First order date per customer |
| LAST_VALUE | Most recent order date per customer |
| NTILE | Customer decile segmentation (1–10) |
| QUALIFY | Filter window results without subquery |

### Silver Principles

1. **Single source of truth** for cleaned entity data
2. **Conformed dimensions** — consistent definitions across facts
3. **Documented business rules** — every filter has a rule ID
4. **Idempotent rebuilds** — CREATE OR REPLACE TABLE each run

### SQL File

`sql/04_silver_tables.sql`

---

## Layer 4: Gold — `retail_gold`

### Purpose

Deliver **business-ready aggregates** that directly answer stakeholder questions. Gold tables are wide, denormalized, and optimized for BI tools.

### Business Tables

| Table | Business Question | Grain |
|-------|-------------------|-------|
| `daily_sales` | What was revenue on each day? | order_date |
| `monthly_sales` | How is revenue trending monthly? | year_month |
| `customer_lifetime_value` | Who are our best customers? | customer_id |
| `repeat_customers` | Who buys more than once? | customer_id |
| `top_products` | Which products sell most? | product_id |
| `top_categories` | Which categories drive revenue? | category |
| `state_wise_sales` | Which states perform best? | state |
| `brand_performance` | How do brands compare? | brand |
| `payment_analysis` | Which payment methods dominate? | payment_method |
| `average_order_value` | What is AOV over time? | order_date |
| `executive_kpis` | What are the headline numbers? | snapshot (1 row) |

### Gold Design Principles

1. **Denormalize for BI** — pre-join dimensions into aggregates
2. **Name for business users** — `revenue` not `sum_total_amount`
3. **Include rankings** — pre-compute RANK for dashboard top-N
4. **Pre-calculate ratios** — margin %, growth %, share %
5. **Minimize dashboard SQL** — Looker Studio reads tables, not complex queries

### SQL File

`sql/05_gold_tables.sql`

---

## Data Flow Diagram

```
GCS CSV Files
     │
     ▼
┌─────────────────────────────────────────────────────────┐
│  RAW (retail_raw)                                       │
│  ext_customers, ext_products, ext_orders,               │
│  ext_order_items, ext_payments                          │
│  • External tables over GCS                             │
│  • Schema defined, data untouched                       │
└─────────────────────┬───────────────────────────────────┘
                      │ CTAS (03_bronze_tables.sql)
                      ▼
┌─────────────────────────────────────────────────────────┐
│  BRONZE (retail_bronze)                                 │
│  customers, products, orders, order_items, payments     │
│  • Native tables with metadata columns                  │
│  • Partitioned: orders, payments                        │
│  • Clustered: all tables                                │
└─────────────────────┬───────────────────────────────────┘
                      │ Transform + DQ (04_silver_tables.sql)
                      ▼
┌─────────────────────────────────────────────────────────┐
│  SILVER (retail_silver)                                 │
│  dim_customers, dim_products, dim_payments              │
│  fact_orders, fact_order_items                          │
│  • Star schema                                          │
│  • Window functions, QUALIFY, CTEs                      │
│  • Business rules applied                               │
└─────────────────────┬───────────────────────────────────┘
                      │ Aggregate (05_gold_tables.sql)
                      ▼
┌─────────────────────────────────────────────────────────┐
│  GOLD (retail_gold)                                     │
│  daily_sales, monthly_sales, customer_lifetime_value, │
│  top_products, executive_kpis, ...                      │
│  • Business-ready KPIs                                  │
│  • Views + Materialized Views (06_views.sql)            │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
              Looker Studio Dashboard
```

---

## Layer Comparison Matrix

| Dimension | Raw | Bronze | Silver | Gold |
|-----------|-----|--------|--------|------|
| Storage | GCS + BQ metadata | BQ native | BQ native | BQ native |
| Table type | External | Native | Native | Native |
| Data quality | None | Minimal | Full | N/A (aggregated) |
| Schema | Source-like | Source-like | Star schema | Denormalized |
| Partitioning | No | Yes (facts) | Optional | Optional |
| Intended queries | Exploration | Reprocessing | Analysis | Dashboards |
| Refresh frequency | On file arrival | Daily | Daily | Daily / hourly |
| Row count vs source | Same | Same | Fewer (DQ filtered) | Much fewer |

---

## Medallion vs Traditional ETL

| Aspect | Traditional ETL | Medallion |
|--------|----------------|-----------|
| Staging | Temporary, deleted after load | Bronze persists permanently |
| Transform location | ETL tool | SQL in warehouse |
| Reprocessing | Full pipeline restart | Replay from any layer |
| Data lineage | Often implicit | Layer boundaries are explicit |
| Schema evolution | Risky | Bronze absorbs changes; silver adapts |

---

## Production Evolution Path

### Phase 1: Teaching (Current)

Manual SQL execution, full refresh, single environment.

### Phase 2: Scheduled

Cloud Scheduler + BigQuery scheduled queries for daily gold refresh.

### Phase 3: Orchestrated

Cloud Composer DAG: ingest → bronze → silver → gold with dependency checks.

### Phase 4: Transformation Framework

dbt project with models mapped 1:1 to silver and gold tables, tests for DQ rules.

### Phase 5: Multi-Environment

Dev / staging / prod datasets with Terraform-managed IAM and CI/CD promotion.

---

## Key Takeaways

1. **Each layer has one job** — don't skip bronze; don't put business logic in raw
2. **Bronze is your safety net** — always rebuildable from raw
3. **Silver is where quality happens** — invest in documented DQ rules
4. **Gold is for consumers** — optimize for read patterns, not normalization
5. **Name datasets by layer** — `retail_bronze`, not `retail_staging_v2_final`

---

## Related Documentation

- [architecture/architecture.md](../architecture/architecture.md) — Full system architecture
- [docs/BigQueryConcepts.md](BigQueryConcepts.md) — Partitioning, clustering, cost
- [docs/SQLConcepts.md](SQLConcepts.md) — CTEs, window functions, star schema
- [sql/02_external_tables.sql](../sql/02_external_tables.sql) — Raw layer DDL
- [diagrams/medallion.drawio](../diagrams/medallion.drawio) — Editable diagram
