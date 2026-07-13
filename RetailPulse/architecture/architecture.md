# RetailPulse System Architecture

## Document Information

| Field | Value |
|-------|-------|
| **Project** | RetailPulse |
| **Version** | 1.0 |
| **Author** | RetailPulse Data Engineering Team |
| **Last Updated** | July 2026 |
| **Status** | Production-Ready Educational Reference |

---

## 1. Executive Summary

RetailPulse is an end-to-end retail analytics data platform built entirely on Google Cloud Platform. The system ingests five CSV source files representing customers, products, orders, order items, and payments, processes them through a four-layer Medallion Architecture in BigQuery, and exposes business-ready datasets to Looker Studio for executive dashboards.

The architecture prioritizes **simplicity for teaching**, **enterprise naming conventions**, and **production patterns** including external tables, native table materialization, dimensional modeling, partitioning, clustering, and materialized views.

---

## 2. Business Context

### 2.1 Problem Statement

A mid-size e-commerce retailer needs a centralized analytics platform to answer:

- What is daily and monthly revenue?
- Which products, categories, and brands perform best?
- Which geographic regions drive sales?
- Who are the highest-value customers?
- What payment methods do customers prefer?
- What is the repeat purchase rate?

### 2.2 Stakeholders

| Stakeholder | Need | Layer Consumed |
|-------------|------|----------------|
| Executive Leadership | KPI dashboards | Gold |
| Marketing Team | Customer segmentation | Gold, Silver |
| Merchandising | Product performance | Gold |
| Data Engineering | Pipeline maintenance | Bronze, Silver |
| Data Analysts | Ad-hoc SQL exploration | Silver, Gold |

### 2.3 Success Criteria

- Single source of truth for retail metrics
- Sub-second dashboard refresh for gold tables
- Reproducible pipeline executable in under 90 minutes
- Clear separation of raw, cleaned, and aggregated data
- Cost under $1 per full classroom deployment

---

## 3. Architecture Overview

### 3.1 High-Level Data Flow

```
┌──────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌──────────────┐
│   Source     │    │  Cloud      │    │    RAW      │    │   BRONZE    │    │   SILVER    │    │    GOLD      │
│   Systems    │───▶│  Storage    │───▶│  External   │───▶│   Native    │───▶│    Star     │───▶│  Business    │───▶ Looker Studio
│   (CSV)      │    │  (GCS)      │    │   Tables    │    │   Tables    │    │   Schema    │    │  Aggregates  │
└──────────────┘    └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘    └──────────────┘
```

### 3.2 Technology Stack

| Layer | Technology | Role |
|-------|------------|------|
| Storage | Google Cloud Storage | Data lake landing zone |
| Compute / Warehouse | BigQuery | SQL transformations and serving |
| Visualization | Looker Studio | Self-service dashboards |
| Orchestration | Manual / bq CLI (extensible to Cloud Composer) | Pipeline execution |
| IaC (future) | Terraform | Infrastructure provisioning |

### 3.3 GCP Resources

| Resource | Name | Location |
|----------|------|----------|
| GCP Project | `retailpulse-project` | — |
| GCS Bucket | `gs://retailpulse-data-lake` | US (multi-region) |
| BigQuery Dataset | `retail_raw` | US |
| BigQuery Dataset | `retail_bronze` | US |
| BigQuery Dataset | `retail_silver` | US |
| BigQuery Dataset | `retail_gold` | US |

---

## 4. Layer-by-Layer Design

### 4.1 Landing Zone — Google Cloud Storage

**Path pattern:** `gs://retailpulse-data-lake/raw/{table_name}.csv`

| File | Approx Rows | Grain |
|------|-------------|-------|
| customers.csv | 500 | One row per customer |
| products.csv | 200 | One row per product |
| orders.csv | 3,000 | One row per order |
| order_items.csv | 7,000 | One row per line item |
| payments.csv | 3,000 | One row per payment |

**Design decisions:**
- CSV chosen for maximum accessibility in classroom settings
- Files include intentional bad records for data quality teaching
- No transformation at landing — preserve source fidelity

### 4.2 Raw Layer — `retail_raw`

**Purpose:** Register GCS files as queryable BigQuery external tables without loading data.

| Table | Source URI | Format |
|-------|-----------|--------|
| ext_customers | gs://retailpulse-data-lake/raw/customers.csv | CSV |
| ext_products | gs://retailpulse-data-lake/raw/products.csv | CSV |
| ext_orders | gs://retailpulse-data-lake/raw/orders.csv | CSV |
| ext_order_items | gs://retailpulse-data-lake/raw/order_items.csv | CSV |
| ext_payments | gs://retailpulse-data-lake/raw/payments.csv | CSV |

**Characteristics:**
- Schema defined explicitly in DDL
- Dates stored as STRING (parsed downstream)
- No partitioning or clustering (not supported on external tables)
- Query cost: bytes scanned from GCS on each query

### 4.3 Bronze Layer — `retail_bronze`

**Purpose:** Immutable native copy of raw data with ingestion metadata.

| Table | Partition Key | Cluster Keys | Metadata Columns |
|-------|---------------|--------------|------------------|
| customers | — | customer_id | _loaded_at, _source_file |
| products | — | product_id, category | _loaded_at, _source_file |
| orders | order_date | customer_id, status | _loaded_at, _source_file |
| order_items | — | order_id, product_id | _loaded_at, _source_file |
| payments | payment_date | order_id, payment_method | _loaded_at, _source_file |

**Design principles:**
- CTAS (CREATE TABLE AS SELECT) from external tables
- Append-only mindset — never update bronze in place
- Minimal transformation: only SAFE.PARSE_DATE for obvious date fields
- Partition large fact tables by date for partition pruning

### 4.4 Silver Layer — `retail_silver`

**Purpose:** Cleaned, validated, conformed dimensional model.

#### Dimension Tables

| Table | Primary Key | Key Transformations |
|-------|-------------|---------------------|
| dim_customers | customer_id | State standardization, email validation, dedup |
| dim_products | product_id | Category uppercase, negative price removal, ranking |
| dim_payments | payment_id | Duplicate payment removal, status normalization |

#### Fact Tables

| Table | Grain | Key Transformations |
|-------|-------|---------------------|
| fact_orders | order_id | Exclude cancelled/invalid, referential integrity |
| fact_order_items | order_item_id | Join validation, line revenue calculation |

#### Data Quality Rules

| Rule | Implementation |
|------|----------------|
| Deduplication | ROW_NUMBER() + QUALIFY rn = 1 |
| Invalid dates | SAFE.PARSE_DATE, filter NULL results |
| Negative amounts | WHERE total_amount >= 0 |
| Orphan records | INNER JOIN to valid dimensions |
| State normalization | CTE mapping full names to 2-letter codes |
| Cancelled orders | Excluded from revenue facts |

#### Window Functions Applied

ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, FIRST_VALUE, LAST_VALUE, NTILE — demonstrated in `04_silver_tables.sql`.

### 4.5 Gold Layer — `retail_gold`

**Purpose:** Business-ready aggregates optimized for BI consumption.

| Table | Grain | Primary Metrics |
|-------|-------|-----------------|
| daily_sales | order_date | revenue, orders, customers, AOV |
| monthly_sales | year_month | revenue, orders, MoM growth |
| customer_lifetime_value | customer_id | LTV, order count, segment |
| repeat_customers | customer_id | repeat flag, days between orders |
| top_products | product_id | revenue, units, rank |
| top_categories | category | revenue, share % |
| state_wise_sales | state | revenue, orders, rank |
| brand_performance | brand | revenue, margin, rank |
| payment_analysis | payment_method | count, revenue, success rate |
| average_order_value | order_date | AOV, rolling 7-day AOV |
| executive_kpis | snapshot | total revenue, orders, customers |

### 4.6 Views Layer — `retail_gold` (views)

| Object | Type | Purpose |
|--------|------|---------|
| vw_sales_summary | Logical View | Simplified analyst interface |
| vw_customer_360 | Logical View | Customer-centric joined view |
| mv_daily_revenue | Materialized View | Pre-aggregated daily revenue |
| mv_category_performance | Materialized View | Pre-aggregated category metrics |

---

## 5. Dimensional Model (Star Schema)

```
                    ┌─────────────────┐
                    │  dim_customers  │
                    │  (customer_id)  │
                    └────────┬────────┘
                             │
┌─────────────────┐          │          ┌─────────────────┐
│  dim_products   │          │          │  dim_payments   │
│  (product_id)   │          │          │  (payment_id)   │
└────────┬────────┘          │          └────────┬────────┘
         │                   │                   │
         │    ┌──────────────┴──────────────┐    │
         └───▶│       fact_order_items      │◀───┘
              │    (order_item_id)          │
              └──────────────┬──────────────┘
                             │
                    ┌────────┴────────┐
                    │   fact_orders   │
                    │   (order_id)    │
                    └─────────────────┘
```

**Join paths for analytics:**
- Revenue by customer: `fact_orders` → `dim_customers`
- Revenue by product: `fact_order_items` → `dim_products` → `fact_orders`
- Payment analysis: `fact_orders` → `dim_payments`

---

## 6. Security and Governance

### 6.1 IAM Model (Recommended)

| Role | Principal | Scope |
|------|-----------|-------|
| BigQuery Data Viewer | Analysts | retail_gold, retail_silver |
| BigQuery Data Editor | Data Engineers | All retail_* datasets |
| Storage Object Viewer | BigQuery Service Account | GCS bucket |
| Looker Studio | End Users | retail_gold via authorized views |

### 6.2 Data Classification

| Layer | Classification | PII Present |
|-------|---------------|-------------|
| Raw / Bronze | Internal | Yes (email, phone) |
| Silver | Internal | Yes (masked in views) |
| Gold | Internal / Confidential | Aggregated — minimal PII |

### 6.3 Recommended Production Enhancements

- Column-level security on email and phone in silver
- Authorized views for Looker Studio access
- Audit logging via Cloud Logging
- Dataset-level access controls per team

---

## 7. Performance and Cost Optimization

### 7.1 Partitioning Strategy

| Table | Column | Benefit |
|-------|--------|---------|
| bronze.orders | order_date | Prune scans for date-range queries |
| bronze.payments | payment_date | Prune payment trend queries |

### 7.2 Clustering Strategy

| Table | Columns | Benefit |
|-------|---------|---------|
| bronze.orders | customer_id, status | Faster customer and status filters |
| bronze.order_items | order_id, product_id | Faster joins |
| bronze.products | product_id, category | Faster product lookups |

### 7.3 Cost Controls

- Use `--dry_run` before large queries
- Prefer gold tables over silver for dashboards
- Materialized views for frequently-run aggregations
- Set `default_table_expiration_ms` on dev datasets
- Monitor bytes processed in BigQuery audit logs

### 7.4 Estimated Costs (Classroom Deployment)

| Component | Estimated Cost |
|-----------|---------------|
| GCS storage (< 10 MB) | < $0.01 |
| BigQuery storage | < $0.05 |
| BigQuery queries | < $0.50 |
| Looker Studio | Free |
| **Total** | **< $1.00** |

---

## 8. Operational Model

### 8.1 Pipeline Execution Order

```
01_create_datasets.sql  →  02_external_tables.sql  →  03_bronze_tables.sql
        →  04_silver_tables.sql  →  05_gold_tables.sql  →  06_views.sql
```

### 8.2 Refresh Strategy

| Layer | Current (Teaching) | Production Recommendation |
|-------|-------------------|--------------------------|
| Raw | Manual CSV upload | Scheduled export from source DB |
| Bronze | Full CTAS refresh | Incremental INSERT by watermark |
| Silver | Full rebuild | MERGE / incremental dbt models |
| Gold | Full rebuild | Scheduled query or dbt |

### 8.3 Monitoring

```sql
-- Pipeline health: row count drift
SELECT table_name, row_count, size_bytes
FROM `retailpulse-project.retail_bronze.INFORMATION_SCHEMA.TABLE_STORAGE`
ORDER BY table_name;
```

### 8.4 Failure Handling

| Failure | Detection | Recovery |
|---------|-----------|----------|
| GCS file missing | External table query returns 0 rows | Re-upload CSV |
| Schema mismatch | Query error on CTAS | Fix CSV or update DDL |
| Bad data spike | Silver row count drops significantly | Review DQ rules in 04_silver |
| Cost overrun | Billing alert | Add partition filters |

---

## 9. Future Enhancements

1. **Orchestration:** Cloud Composer (Airflow) DAG for scheduled runs
2. **Transformation:** dbt models replacing inline SQL
3. **CI/CD:** Cloud Build pipeline with SQL linting
4. **Streaming:** Pub/Sub + BigQuery streaming inserts for real-time orders
5. **ML:** BigQuery ML for customer churn prediction
6. **Data Quality:** Great Expectations or Dataplex data quality scans
7. **Infrastructure:** Terraform modules for repeatable GCP provisioning

---

## 10. References

- [BigQuery Best Practices](https://cloud.google.com/bigquery/docs/best-practices-performance-overview)
- [Medallion Architecture (Databricks)](https://www.databricks.com/glossary/medallion-architecture)
- [Looker Studio BigQuery Connector](https://support.google.com/looker-studio/answer/6370296)
- Project SQL: `sql/01_create_datasets.sql` through `sql/07_analytics.sql`
- Diagrams: `diagrams/architecture.drawio`, `diagrams/medallion.drawio`
