# RetailPulse – End-to-End BigQuery Data Engineering Case Study

[![GCP](https://img.shields.io/badge/Google%20Cloud-BigQuery-4285F4?logo=google-cloud)](https://cloud.google.com/bigquery)
[![Architecture](https://img.shields.io/badge/Architecture-Medallion-00C853)](architecture/architecture.md)
[![SQL](https://img.shields.io/badge/SQL-55%2B%20Queries-blue)](sql/07_analytics.sql)

> **RetailPulse** is a production-style BigQuery data warehouse case study for retail and e-commerce analytics. Built on the **Medallion Architecture**, it takes students from raw CSV files in Cloud Storage through Bronze, Silver, and Gold layers to a Looker Studio dashboard — in approximately **90 minutes**.

---

## Project Overview

| Attribute | Detail |
|-----------|--------|
| **Industry** | Retail / E-Commerce |
| **Platform** | Google Cloud Platform (GCS, BigQuery, Looker Studio) |
| **Architecture** | Medallion (Raw → Bronze → Silver → Gold) |
| **Data Volume** | ~500 customers, 200 products, 3,000 orders, 7,000 line items |
| **Duration** | 90-minute classroom session |
| **Audience** | Data engineering students, bootcamp learners, interview prep |

RetailPulse simulates a real enterprise retail analytics pipeline. Source systems export daily CSV snapshots to a GCS data lake. BigQuery external tables expose raw data, native tables materialize bronze copies, silver SQL applies data quality and dimensional modeling, and gold tables deliver business KPIs for executive dashboards.

---

## Architecture

```
┌─────────────────┐     ┌──────────────────────────────────────────────────────────┐
│  Source Systems │     │                    Google Cloud Platform                  │
│  (CSV Exports)  │────▶│  GCS Bucket          BigQuery                    Looker   │
└─────────────────┘     │  retailpulse-data-lake                              Studio │
                        │       │                                                  │
                        │       ▼                                                  │
                        │  retail_raw (External Tables)                            │
                        │       │                                                  │
                        │       ▼                                                  │
                        │  retail_bronze (Native Tables, Partitioned & Clustered)    │
                        │       │                                                  │
                        │       ▼                                                  │
                        │  retail_silver (Star Schema: Facts & Dimensions)         │
                        │       │                                                  │
                        │       ▼                                                  │
                        │  retail_gold (Business Aggregates & KPIs) ────────────────▶│
                        └──────────────────────────────────────────────────────────┘
```

See [architecture/architecture.md](architecture/architecture.md) for the full design document and [diagrams/](diagrams/) for editable draw.io diagrams.

---

## Folder Structure

```
RetailPulse/
│
├── README.md                          # This file
│
├── architecture/
│   ├── architecture.md                # Full system architecture document
│   └── architecture.png               # Architecture diagram image
│
├── datasets/
│   ├── customers.csv                  # 500 customer records
│   ├── products.csv                   # 200 product catalog entries
│   ├── orders.csv                     # 3,000 order transactions
│   ├── order_items.csv                # 7,000 order line items
│   └── payments.csv                   # 3,000 payment records
│
├── sql/
│   ├── 01_create_datasets.sql         # Create retail_raw, bronze, silver, gold
│   ├── 02_external_tables.sql         # External tables over GCS
│   ├── 03_bronze_tables.sql           # CTAS, partitioning, clustering
│   ├── 04_silver_tables.sql           # Dimensional model, window functions
│   ├── 05_gold_tables.sql             # Business aggregates and KPIs
│   ├── 06_views.sql                   # Logical and materialized views
│   └── 07_analytics.sql               # 55 interview-style analytical queries
│
├── docs/
│   ├── MedallionArchitecture.md       # Layer-by-layer medallion design
│   ├── BigQueryConcepts.md            # Partitioning, clustering, cost optimization
│   ├── SQLConcepts.md                 # CTEs, window functions, star schema
│   └── TeachingGuide.md               # 90-minute classroom guide + interview Q&A
│
├── diagrams/
│   ├── medallion.drawio               # Medallion architecture diagram
│   └── architecture.drawio            # Full system architecture diagram
│
├── dashboard/
│   └── looker_dashboard.md            # Looker Studio build guide
│
├── images/
│   └── dashboard_mockup.png           # Dashboard mockup reference
│
└── scripts/
    └── generate_data.py               # Regenerate sample CSV datasets
```

---

## Prerequisites

### Knowledge

- Basic SQL (SELECT, JOIN, GROUP BY, WHERE)
- Familiarity with relational databases
- Optional: prior exposure to cloud concepts

### Tools

| Tool | Purpose | Install |
|------|---------|---------|
| [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) | `gcloud`, `bq`, `gsutil` CLI | Required |
| [BigQuery Console](https://console.cloud.google.com/bigquery) | Run SQL, inspect tables | Browser |
| [Looker Studio](https://lookerstudio.google.com/) | Build dashboards | Browser |
| Python 3.8+ | Regenerate datasets (optional) | Optional |

### GCP Requirements

- Google Cloud account with billing enabled
- Project with BigQuery API enabled
- IAM roles: `BigQuery Admin`, `Storage Admin` (or equivalent custom roles)
- Estimated cost: **< $1 USD** for a full classroom run (small dataset)

---

## GCP Setup

### Step 1: Create a GCP Project

```bash
export PROJECT_ID="retailpulse-project"   # Replace with your project ID
gcloud config set project $PROJECT_ID
gcloud services enable bigquery.googleapis.com storage.googleapis.com
```

### Step 2: Create a Cloud Storage Bucket

```bash
export BUCKET="retailpulse-data-lake"     # Must be globally unique; add suffix if needed
gsutil mb -l US gs://$BUCKET/
```

### Step 3: Upload CSV Files

```bash
cd RetailPulse
gsutil -m cp datasets/*.csv gs://$BUCKET/raw/
gsutil ls gs://$BUCKET/raw/
```

### Step 4: Update SQL Configuration

Search and replace in all `sql/*.sql` files:

| Placeholder | Replace With |
|-------------|--------------|
| `retailpulse-project` | Your GCP project ID |
| `gs://retailpulse-data-lake/raw/` | Your GCS bucket path |

---

## Execution Steps

Run SQL files **in order** using the BigQuery Console or `bq` CLI.

### Option A: BigQuery Console

1. Open [BigQuery Console](https://console.cloud.google.com/bigquery)
2. Click **Compose New Query**
3. Paste and run each file from `sql/` in sequence (01 → 07)

### Option B: bq CLI

```bash
export PROJECT_ID="your-project-id"
cd RetailPulse/sql

for f in 01_create_datasets.sql 02_external_tables.sql 03_bronze_tables.sql \
         04_silver_tables.sql 05_gold_tables.sql 06_views.sql; do
  echo "Running $f..."
  bq query --use_legacy_sql=false --project_id=$PROJECT_ID < "$f"
done
```

### Verification Checklist

After each layer, confirm success:

```sql
-- Datasets exist
SELECT schema_name FROM `your-project.INFORMATION_SCHEMA.SCHEMATA`
WHERE schema_name LIKE 'retail_%';

-- Row counts by layer
SELECT 'bronze.orders' AS tbl, COUNT(*) AS rows FROM `your-project.retail_bronze.orders`
UNION ALL SELECT 'silver.fact_orders', COUNT(*) FROM `your-project.retail_silver.fact_orders`
UNION ALL SELECT 'gold.daily_sales', COUNT(*) FROM `your-project.retail_gold.daily_sales`;
```

### Build the Dashboard

Follow [dashboard/looker_dashboard.md](dashboard/looker_dashboard.md) to connect Looker Studio to `retail_gold` tables.

---

## Data Model Summary

### Source Tables (5 CSV files)

| Table | Rows | Key Fields |
|-------|------|------------|
| `customers` | 500 | customer_id, email, state, signup_date |
| `products` | 200 | product_id, category, brand, price |
| `orders` | 3,000 | order_id, customer_id, order_date, status |
| `order_items` | 7,000 | order_item_id, order_id, product_id, quantity |
| `payments` | 3,000 | payment_id, order_id, payment_method |

### Silver Layer (Star Schema)

| Type | Table | Purpose |
|------|-------|---------|
| Dimension | `dim_customers` | Cleaned customer master |
| Dimension | `dim_products` | Product catalog with rankings |
| Dimension | `dim_payments` | Payment method reference |
| Fact | `fact_orders` | Order header facts |
| Fact | `fact_order_items` | Line-item grain facts |

### Gold Layer (Business Tables)

| Table | Business Question |
|-------|-------------------|
| `daily_sales` | What was revenue yesterday? |
| `monthly_sales` | How is revenue trending by month? |
| `customer_lifetime_value` | Who are our most valuable customers? |
| `repeat_customers` | What is our repeat purchase rate? |
| `top_products` | Which products drive the most revenue? |
| `top_categories` | Which categories perform best? |
| `state_wise_sales` | Which states generate the most sales? |
| `brand_performance` | How do brands compare? |
| `payment_analysis` | Which payment methods are most popular? |
| `average_order_value` | What is our AOV trend? |
| `executive_kpis` | Single-row executive summary |

---

## Results

After completing the pipeline you will have:

- **4 BigQuery datasets** following medallion naming conventions
- **5 external tables** querying GCS without data duplication
- **5 bronze tables** with partitioning and clustering
- **5 silver tables** with data quality rules and window functions
- **11 gold tables** ready for BI consumption
- **2 materialized views** for query acceleration
- **55 analytical queries** for practice and interviews
- **1 Looker Studio dashboard** with revenue, orders, and segment KPIs

Sample executive KPI query:

```sql
SELECT *
FROM `retailpulse-project.retail_gold.executive_kpis`;
```

---

## Learning Outcomes

By completing RetailPulse, students will be able to:

1. **Design** a medallion architecture data warehouse on Google Cloud
2. **Create** BigQuery datasets, external tables, and native tables
3. **Apply** partitioning and clustering for cost and performance optimization
4. **Transform** raw data using CTEs, window functions, and the QUALIFY clause
5. **Model** a star schema with fact and dimension tables
6. **Implement** data quality rules (deduplication, null handling, referential integrity)
7. **Build** business-ready gold aggregates for executive reporting
8. **Optimize** BigQuery costs using dry runs, clustering, and materialized views
9. **Connect** BigQuery to Looker Studio for self-service analytics
10. **Answer** 50+ common BigQuery data engineering interview questions

---

## Documentation Index

| Document | Description |
|----------|-------------|
| [architecture/architecture.md](architecture/architecture.md) | Full system architecture |
| [docs/MedallionArchitecture.md](docs/MedallionArchitecture.md) | Medallion layer design |
| [docs/BigQueryConcepts.md](docs/BigQueryConcepts.md) | BigQuery features and optimization |
| [docs/SQLConcepts.md](docs/SQLConcepts.md) | SQL patterns used in the project |
| [docs/TeachingGuide.md](docs/TeachingGuide.md) | 90-minute teaching guide |
| [dashboard/looker_dashboard.md](dashboard/looker_dashboard.md) | Dashboard build instructions |

---

## License

This project is provided for educational purposes. Use freely in classrooms, bootcamps, and portfolio projects.

---

## Contributing

Improvements welcome! Focus areas: additional data quality scenarios, incremental load patterns, CI/CD with Cloud Build, and Terraform for infrastructure-as-code.
