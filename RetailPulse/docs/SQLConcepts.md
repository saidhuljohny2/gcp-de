# SQL Concepts – RetailPulse Reference

SQL patterns, techniques, and design principles used throughout the RetailPulse BigQuery project.

---

## Table of Contents

1. [CTEs (Common Table Expressions)](#1-ctes-common-table-expressions)
2. [Window Functions](#2-window-functions)
3. [QUALIFY Clause](#3-qualify-clause)
4. [Data Cleaning Patterns](#4-data-cleaning-patterns)
5. [Star Schema Design](#5-star-schema-design)
6. [Aggregation Patterns](#6-aggregation-patterns)
7. [Join Patterns](#7-join-patterns)
8. [Date and Time Functions](#8-date-and-time-functions)

---

## 1. CTEs (Common Table Expressions)

CTEs (`WITH` clauses) break complex SQL into readable, named steps. RetailPulse uses them extensively in `04_silver_tables.sql`.

### Basic Syntax

```sql
WITH step_one AS (
  SELECT ... FROM source_table
),
step_two AS (
  SELECT ... FROM step_one
)
SELECT * FROM step_two;
```

### Pattern: Clean → Transform → Load

```sql
WITH state_mapping AS (
  SELECT 'CALIFORNIA' AS state_full, 'CA' AS state_code
  UNION ALL SELECT 'NEW YORK', 'NY'
  UNION ALL SELECT 'TEXAS', 'TX'
  -- ... additional states
),
cleaned AS (
  SELECT
    customer_id,
    TRIM(first_name) AS first_name,
    TRIM(last_name) AS last_name,
    UPPER(TRIM(state)) AS state_raw,
    SAFE.PARSE_DATE('%Y-%m-%d', signup_date) AS signup_date
  FROM `retailpulse-project.retail_bronze.customers`
),
standardized AS (
  SELECT
    c.*,
    COALESCE(m.state_code, c.state_raw) AS state_code
  FROM cleaned c
  LEFT JOIN state_mapping m ON c.state_raw = m.state_full
),
deduped AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY customer_id
      ORDER BY signup_date DESC, _loaded_at DESC
    ) AS rn
  FROM standardized
)
SELECT * EXCEPT(rn)
FROM deduped
WHERE rn = 1;
```

### Why CTEs Over Subqueries

| CTE Advantage | Explanation |
|---------------|-------------|
| Readability | Each step has a descriptive name |
| Debuggability | Run individual CTEs in isolation |
| Reusability | Reference a CTE multiple times in the same query |
| No nesting | Avoid deeply nested subquery pyramids |

### CTE Best Practices

1. Name CTEs by what they **do** (`deduped`, `validated`), not what they **are** (`temp1`)
2. Keep each CTE to one logical transformation
3. Order CTEs top-to-bottom in pipeline sequence
4. Use `SELECT * EXCEPT(rn)` to drop helper columns from final output

---

## 2. Window Functions

Window functions perform calculations across a set of rows **related to the current row** without collapsing results into groups (unlike GROUP BY).

### Syntax

```sql
function_name(expression) OVER (
  [PARTITION BY column1, column2]
  [ORDER BY column3 [ASC|DESC]]
  [ROWS|RANGE BETWEEN start AND end]
)
```

### 2.1 ROW_NUMBER

Assigns a unique sequential integer to each row within a partition.

```sql
-- Deduplication: keep the latest record per customer
SELECT *
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY customer_id
      ORDER BY _loaded_at DESC
    ) AS rn
  FROM `retailpulse-project.retail_bronze.customers`
)
WHERE rn = 1;
```

**RetailPulse usage:** Deduplication in dim_customers, dim_products, dim_payments, fact_orders.

### 2.2 RANK

Assigns rank with gaps when ties exist.

```sql
-- Rank products by price (ties get same rank, next rank skips)
SELECT
  product_id,
  product_name,
  price,
  RANK() OVER (ORDER BY price DESC) AS price_rank
FROM `retailpulse-project.retail_silver.dim_products`;
```

Example output:

| product_id | price | price_rank |
|------------|-------|------------|
| PROD00001 | 999.99 | 1 |
| PROD00002 | 899.99 | 2 |
| PROD00003 | 899.99 | 2 |
| PROD00004 | 750.00 | 4 |

**RetailPulse usage:** Product price ranking in dim_products, top_products in gold.

### 2.3 DENSE_RANK

Like RANK but without gaps after ties.

```sql
SELECT
  customer_id,
  COUNT(*) AS order_count,
  DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS frequency_rank
FROM `retailpulse-project.retail_silver.fact_orders`
GROUP BY customer_id;
```

| customer_id | order_count | RANK | DENSE_RANK |
|-------------|-------------|------|------------|
| CUST00001 | 15 | 1 | 1 |
| CUST00002 | 12 | 2 | 2 |
| CUST00003 | 12 | 2 | 2 |
| CUST00004 | 10 | 4 | 3 |

**RetailPulse usage:** Customer order frequency ranking.

### 2.4 LAG and LEAD

Access values from preceding or following rows.

```sql
SELECT
  customer_id,
  order_date,
  total_amount,
  LAG(order_date) OVER (
    PARTITION BY customer_id ORDER BY order_date
  ) AS previous_order_date,
  DATE_DIFF(
    order_date,
    LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date),
    DAY
  ) AS days_since_last_order,
  LEAD(order_date) OVER (
    PARTITION BY customer_id ORDER BY order_date
  ) AS next_order_date
FROM `retailpulse-project.retail_silver.fact_orders`;
```

**RetailPulse usage:** Repeat customer analysis, days-between-orders in fact_orders.

### 2.5 FIRST_VALUE and LAST_VALUE

Return the first or last value in a window frame.

```sql
SELECT
  customer_id,
  order_date,
  total_amount,
  FIRST_VALUE(order_date) OVER (
    PARTITION BY customer_id ORDER BY order_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
  ) AS first_order_date,
  LAST_VALUE(order_date) OVER (
    PARTITION BY customer_id ORDER BY order_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
  ) AS last_order_date
FROM `retailpulse-project.retail_silver.fact_orders`;
```

**Note:** LAST_VALUE requires explicit frame clause (`ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`) to include all rows in the partition.

**RetailPulse usage:** Customer tenure calculation in customer_lifetime_value.

### 2.6 NTILE

Divides rows into N roughly equal buckets.

```sql
SELECT
  customer_id,
  lifetime_value,
  NTILE(4) OVER (ORDER BY lifetime_value DESC) AS value_quartile,
  CASE NTILE(4) OVER (ORDER BY lifetime_value DESC)
    WHEN 1 THEN 'Platinum'
    WHEN 2 THEN 'Gold'
    WHEN 3 THEN 'Silver'
    ELSE 'Bronze'
  END AS customer_segment
FROM `retailpulse-project.retail_gold.customer_lifetime_value`;
```

**RetailPulse usage:** Customer segmentation into quartiles (Platinum/Gold/Silver/Bronze).

### Window Function Summary

| Function | Returns | Ties Handling | RetailPulse Use |
|----------|---------|---------------|-----------------|
| ROW_NUMBER | Unique sequential int | Arbitrary tiebreak | Deduplication |
| RANK | Rank with gaps | Same rank, gap after | Product ranking |
| DENSE_RANK | Rank without gaps | Same rank, no gap | Customer frequency |
| LAG | Previous row value | — | Days since last order |
| LEAD | Next row value | — | Days until next order |
| FIRST_VALUE | First in frame | — | First order date |
| LAST_VALUE | Last in frame | — | Last order date |
| NTILE | Bucket number (1-N) | — | Customer segments |

---

## 3. QUALIFY Clause

BigQuery's `QUALIFY` clause filters results of window functions **without a subquery** — equivalent to `HAVING` for window functions.

### Without QUALIFY (verbose)

```sql
SELECT * FROM (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY _loaded_at DESC) AS rn
  FROM bronze.customers
)
WHERE rn = 1;
```

### With QUALIFY (clean)

```sql
SELECT * EXCEPT(rn)
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY _loaded_at DESC) AS rn
  FROM `retailpulse-project.retail_bronze.customers`
)
QUALIFY rn = 1;
```

### Additional QUALIFY Examples

```sql
-- Top 3 products per category by revenue
SELECT category, product_id, revenue
FROM product_revenue
QUALIFY RANK() OVER (PARTITION BY category ORDER BY revenue DESC) <= 3;

-- Remove duplicate payments
SELECT * EXCEPT(rn)
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY payment_id ORDER BY _loaded_at DESC) AS rn
  FROM `retailpulse-project.retail_bronze.payments`
)
QUALIFY rn = 1;

-- Customers with more than 5 orders
SELECT customer_id, order_count
FROM (
  SELECT customer_id, COUNT(*) AS order_count
  FROM `retailpulse-project.retail_silver.fact_orders`
  GROUP BY customer_id
)
QUALIFY order_count > 5;
```

---

## 4. Data Cleaning Patterns

### 4.1 Null Handling

```sql
-- COALESCE: first non-null value
COALESCE(email, 'unknown@retailpulse.com') AS email

-- NULLIF: convert sentinel values to NULL
NULLIF(TRIM(gender), '') AS gender

-- IFNULL: two-argument COALESCE
IFNULL(country, 'USA') AS country
```

### 4.2 String Standardization

```sql
UPPER(TRIM(category)) AS category,          -- 'electronics' → 'ELECTRONICS'
INITCAP(TRIM(first_name)) AS first_name,    -- 'james' → 'James'
REGEXP_REPLACE(phone, r'[^0-9+]', '') AS phone_clean
```

### 4.3 Safe Type Conversion

```sql
SAFE.PARSE_DATE('%Y-%m-%d', signup_date) AS signup_date   -- NULL on invalid
SAFE_CAST(price AS FLOAT64) AS price                       -- NULL on invalid
```

### 4.4 Email Validation

```sql
CASE
  WHEN REGEXP_CONTAINS(email, r'^[^@]+@[^@]+\.[^@]+$') THEN LOWER(TRIM(email))
  ELSE NULL
END AS email
```

### 4.5 Referential Integrity

```sql
-- Inner join to enforce FK: only orders with valid customers
SELECT o.*
FROM `retailpulse-project.retail_bronze.orders` o
INNER JOIN `retailpulse-project.retail_silver.dim_customers` c
  ON o.customer_id = c.customer_id;
```

### 4.6 Business Rule Filters

```sql
WHERE status = 'Completed'           -- Revenue facts: completed orders only
  AND total_amount >= 0              -- No negative amounts
  AND order_date IS NOT NULL         -- Valid dates only
  AND customer_id != 'CUST99999'     -- Remove test/invalid IDs
```

---

## 5. Star Schema Design

### Concept

A **star schema** has a central **fact table** surrounded by **dimension tables**. Facts contain measurable events; dimensions contain descriptive attributes.

### RetailPulse Star Schema

```
         dim_customers                dim_products
         ┌─────────────┐              ┌─────────────┐
         │ customer_id │◄────┐  ┌────►│ product_id  │
         │ first_name  │     │  │     │ category    │
         │ state_code  │     │  │     │ brand       │
         │ segment     │     │  │     │ price       │
         └─────────────┘     │  │     └─────────────┘
                             │  │
                    ┌────────┴──┴────────┐
                    │  fact_order_items  │
                    │  order_item_id     │
                    │  order_id          │
                    │  product_id        │
                    │  quantity          │
                    │  line_revenue      │
                    └────────┬───────────┘
                             │
                    ┌────────┴───────────┐
                    │    fact_orders     │
                    │    order_id        │
                    │    customer_id     │
                    │    order_date      │
                    │    total_amount    │
                    └────────┬───────────┘
                             │
                    ┌────────┴───────────┐
                    │   dim_payments     │
                    │   payment_id       │
                    │   payment_method   │
                    │   payment_status   │
                    └────────────────────┘
```

### Fact Table Design Rules

| Rule | RetailPulse Example |
|------|---------------------|
| One grain per fact table | fact_orders = one row per order |
| Foreign keys to dimensions | customer_id → dim_customers |
| Numeric measures | total_amount, quantity, line_revenue |
| Degenerate dimensions OK | order_id stored in fact (no dim_orders) |

### Dimension Table Design Rules

| Rule | RetailPulse Example |
|------|---------------------|
| One row per entity | dim_customers = one row per customer_id |
| Descriptive attributes | name, state, segment |
| Surrogate key = natural key | customer_id used directly (no auto-increment) |
| Slowly changing | Full refresh in teaching project; SCD Type 2 in production |

### Star vs Snowflake

| Aspect | Star (RetailPulse) | Snowflake |
|--------|-------------------|-----------|
| Normalization | Denormalized dimensions | Normalized sub-dimensions |
| Join count | Fewer joins | More joins |
| Query simplicity | Simpler | More complex |
| Storage | More redundant | Less redundant |
| BigQuery preference | Preferred | Rarely needed |

---

## 6. Aggregation Patterns

### 6.1 Basic Aggregation

```sql
SELECT
  order_date,
  COUNT(DISTINCT order_id) AS order_count,
  SUM(total_amount) AS revenue,
  AVG(total_amount) AS avg_order_value
FROM `retailpulse-project.retail_silver.fact_orders`
GROUP BY order_date;
```

### 6.2 GROUPING SETS / ROLLUP

```sql
SELECT
  COALESCE(state_code, 'ALL STATES') AS state,
  COALESCE(category, 'ALL CATEGORIES') AS category,
  SUM(line_revenue) AS revenue
FROM sales_detail
GROUP BY ROLLUP(state_code, category);
```

### 6.3 Running Totals

```sql
SELECT
  order_date,
  daily_revenue,
  SUM(daily_revenue) OVER (ORDER BY order_date) AS cumulative_revenue
FROM `retailpulse-project.retail_gold.daily_sales`;
```

### 6.4 Moving Averages

```sql
SELECT
  order_date,
  avg_order_value,
  AVG(avg_order_value) OVER (
    ORDER BY order_date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS moving_avg_7day
FROM `retailpulse-project.retail_gold.average_order_value`;
```

### 6.5 Percent of Total

```sql
SELECT
  category,
  revenue,
  ROUND(100.0 * revenue / SUM(revenue) OVER (), 2) AS pct_of_total
FROM `retailpulse-project.retail_gold.top_categories`;
```

### 6.6 Month-over-Month Growth

```sql
SELECT
  year_month,
  revenue,
  LAG(revenue) OVER (ORDER BY year_month) AS prev_month_revenue,
  ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY year_month))
    / NULLIF(LAG(revenue) OVER (ORDER BY year_month), 0), 2) AS mom_growth_pct
FROM `retailpulse-project.retail_gold.monthly_sales`;
```

---

## 7. Join Patterns

### 7.1 Inner Join (Enforce Referential Integrity)

```sql
SELECT oi.*, o.order_date, o.customer_id
FROM `retailpulse-project.retail_silver.fact_order_items` oi
INNER JOIN `retailpulse-project.retail_silver.fact_orders` o
  ON oi.order_id = o.order_id;
```

### 7.2 Left Join (Preserve All Facts)

```sql
SELECT
  c.customer_id,
  c.first_name,
  COALESCE(COUNT(o.order_id), 0) AS order_count
FROM `retailpulse-project.retail_silver.dim_customers` c
LEFT JOIN `retailpulse-project.retail_silver.fact_orders` o
  ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name;
```

### 7.3 Avoid Fan-Out

When joining facts to dimensions, aggregate first to prevent row multiplication:

```sql
-- Wrong: joining fact_orders to fact_order_items doubles order amounts
-- Right: aggregate line items first, then join
WITH order_lines AS (
  SELECT order_id, SUM(line_revenue) AS line_total
  FROM fact_order_items
  GROUP BY order_id
)
SELECT o.order_id, o.total_amount, ol.line_total
FROM fact_orders o
JOIN order_lines ol ON o.order_id = ol.order_id;
```

---

## 8. Date and Time Functions

### Common Functions in RetailPulse

```sql
-- Parsing
SAFE.PARSE_DATE('%Y-%m-%d', '2025-07-13')         -- STRING → DATE
DATE(order_timestamp)                               -- TIMESTAMP → DATE

-- Extraction
EXTRACT(YEAR FROM order_date)                         -- 2025
EXTRACT(MONTH FROM order_date)                        -- 7
FORMAT_DATE('%Y-%m', order_date)                      -- '2025-07'

-- Arithmetic
DATE_ADD(order_date, INTERVAL 30 DAY)                 -- 30 days later
DATE_DIFF(last_order, first_order, DAY)               -- days between
DATE_TRUNC(order_date, MONTH)                         -- first of month

-- Current
CURRENT_DATE()                                        -- today's date
CURRENT_TIMESTAMP()                                   -- now (for _loaded_at)
```

---

## Related Documentation

- [docs/MedallionArchitecture.md](MedallionArchitecture.md)
- [docs/BigQueryConcepts.md](BigQueryConcepts.md)
- [sql/04_silver_tables.sql](../sql/04_silver_tables.sql)
- [sql/05_gold_tables.sql](../sql/05_gold_tables.sql)
- [sql/07_analytics.sql](../sql/07_analytics.sql)
