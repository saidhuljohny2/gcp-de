# Looker Studio Dashboard Build Guide

Complete step-by-step instructions for building the RetailPulse executive analytics dashboard in Looker Studio (formerly Google Data Studio).

---

## Dashboard Overview

| Attribute | Detail |
|-----------|--------|
| **Name** | RetailPulse Executive Dashboard |
| **Data Source** | BigQuery `retail_gold` dataset |
| **Audience** | Executives, merchandising, marketing |
| **Refresh** | Automatic (BigQuery connector caches 12 hours) |
| **Estimated Build Time** | 30–45 minutes |

### Dashboard Layout

```
┌─────────────────────────────────────────────────────────────────────┐
│  RetailPulse Executive Dashboard                    [Date Filter]   │
├──────────────┬──────────────┬──────────────┬────────────────────────┤
│  Total       │  Total       │  Total       │  Avg Order             │
│  Revenue     │  Orders      │  Customers   │  Value                 │
│  $X.XXM      │  X,XXX       │  X,XXX       │  $XX.XX                │
├──────────────┴──────────────┴──────────────┴────────────────────────┤
│  Monthly Revenue Trend (Time Series)                                │
│  ████████████████████████████████████████████████████████████████   │
├────────────────────────────────┬────────────────────────────────────┤
│  Sales by State (Geo Map)      │  Top 10 Products (Bar Chart)       │
│                                │                                    │
├────────────────────────────────┼────────────────────────────────────┤
│  Revenue by Category (Pie)     │  Customer Segments (Donut)         │
│                                │                                    │
├────────────────────────────────┴────────────────────────────────────┤
│  Payment Method Analysis (Stacked Bar)                              │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

1. RetailPulse gold layer tables created (`05_gold_tables.sql` executed)
2. Google account with access to the GCP project
3. BigQuery Data Viewer role on `retail_gold` dataset
4. Gold tables populated with data (run verification query below)

### Verification

```sql
SELECT table_name, row_count
FROM `retailpulse-project.retail_gold.INFORMATION_SCHEMA.TABLE_STORAGE`
WHERE row_count > 0
ORDER BY table_name;
```

Expected tables with data: `daily_sales`, `monthly_sales`, `customer_lifetime_value`, `top_products`, `top_categories`, `state_wise_sales`, `brand_performance`, `payment_analysis`, `average_order_value`, `executive_kpis`.

---

## Step 1: Create the Report

1. Navigate to [Looker Studio](https://lookerstudio.google.com/)
2. Click **Create** → **Report**
3. In the connector panel, select **BigQuery**
4. Choose **Recent Projects** or **My Projects**
5. Select project: `retailpulse-project`
6. Select dataset: `retail_gold`
7. Select table: `executive_kpis`
8. Click **Add** to connect

---

## Step 2: Configure Data Sources

You will create **6 data sources** connecting to different gold tables. The first connection (executive_kpis) is already created in Step 1.

### Add Remaining Data Sources

1. Click **Resource** → **Manage added data sources**
2. Click **Add a Data Source** → **BigQuery**
3. Add each table below:

| # | Data Source Name | BigQuery Table | Primary Use |
|---|------------------|----------------|-------------|
| 1 | DS_Executive_KPIs | executive_kpis | Scorecards |
| 2 | DS_Daily_Sales | daily_sales | Revenue trend |
| 3 | DS_Monthly_Sales | monthly_sales | Monthly trend |
| 4 | DS_State_Sales | state_wise_sales | Geo map |
| 5 | DS_Top_Products | top_products | Product bar chart |
| 6 | DS_Top_Categories | top_categories | Category pie chart |
| 7 | DS_Customer_LTV | customer_lifetime_value | Segment donut |
| 8 | DS_Payment_Analysis | payment_analysis | Payment bar chart |

### Field Type Configuration

After adding each data source, verify field types in **Resource → Manage added data sources → Edit**:

| Field | Type | Aggregation |
|-------|------|-------------|
| revenue | Currency (USD) | SUM |
| order_count / total_orders | Number | SUM |
| customer_count / total_customers | Number | SUM |
| avg_order_value | Currency (USD) | AVG |
| order_date | Date | — |
| year_month | Text | — |
| state | Text (Geo: State) | — |
| category | Text | — |
| product_name | Text | — |
| customer_segment | Text | — |
| payment_method | Text | — |
| revenue_rank | Number | — |
| mom_growth_pct | Percent | AVG |

---

## Step 3: Build Scorecard KPIs

Switch data source to **DS_Executive_KPIs**.

### Scorecard 1: Total Revenue

1. Click **Add a Chart** → **Scorecard**
2. Position: top-left (x=50, y=20, width=250, height=100)
3. Data source: DS_Executive_KPIs
4. Metric: `total_revenue`
5. Style:
   - Label: "Total Revenue"
   - Compact numbers: ON
   - Decimal places: 0
   - Prefix: "$"
   - Background: #4285F4 (Google Blue)
   - Font color: White

### Scorecard 2: Total Orders

1. Add Scorecard next to Revenue
2. Metric: `total_orders`
3. Style:
   - Label: "Total Orders"
   - Background: #34A853 (Google Green)

### Scorecard 3: Total Customers

1. Add Scorecard
2. Metric: `total_customers`
3. Style:
   - Label: "Total Customers"
   - Background: #FBBC04 (Google Yellow)
   - Font color: #333

### Scorecard 4: Average Order Value

1. Add Scorecard
2. Metric: `avg_order_value`
3. Style:
   - Label: "Avg Order Value"
   - Prefix: "$"
   - Decimal places: 2
   - Background: #EA4335 (Google Red)

---

## Step 4: Monthly Revenue Trend

1. Click **Add a Chart** → **Time Series Chart**
2. Position: below scorecards (full width)
3. Data source: **DS_Monthly_Sales**
4. Dimension: `year_month` (set as Date type: Year Month)
5. Metric: `revenue`
6. Style:
   - Chart title: "Monthly Revenue Trend"
   - Show data labels: OFF
   - Line color: #4285F4
   - Fill area under line: ON (opacity 20%)
   - Show axis titles: ON
   - Y-axis label: "Revenue ($)"

### Optional: Add MoM Growth Line

1. Click **Add metric** → `mom_growth_pct`
2. Set as right Y-axis
3. Chart type for second metric: Line
4. Color: #EA4335

---

## Step 5: Sales by State (Geo Map)

1. Click **Add a Chart** → **Geo Chart** → **Filled Map**
2. Position: bottom-left quadrant
3. Data source: **DS_State_Sales**
4. Geographic dimension: `state` (set region to United States)
5. Color metric: `revenue`
6. Style:
   - Chart title: "Sales by State"
   - Color scale: Blue gradient (light to #4285F4)
   - Show labels: ON
   - Map zoom: US

### State Field Geo Configuration

1. Edit data source DS_State_Sales
2. Click `state` field → Type → **Geo** → **State** → Country: United States

---

## Step 6: Top 10 Products (Bar Chart)

1. Click **Add a Chart** → **Bar Chart**
2. Position: bottom-right quadrant
3. Data source: **DS_Top_Products**
4. Dimension: `product_name`
5. Metric: `revenue`
6. Filter: `revenue_rank` ≤ 10
7. Sort: `revenue_rank` ascending
8. Style:
   - Chart title: "Top 10 Products by Revenue"
   - Orientation: Horizontal
   - Bar color: #34A853
   - Show data labels: ON
   - Label position: End

---

## Step 7: Revenue by Category (Pie Chart)

1. Click **Add a Chart** → **Pie Chart**
2. Position: middle-left
3. Data source: **DS_Top_Categories**
4. Dimension: `category`
5. Metric: `revenue`
6. Sort: `revenue` descending
7. Style:
   - Chart title: "Revenue by Category"
   - Slice labels: Percentage + Category name
   - Donut hole: 0% (full pie)
   - Color palette: Google categorical

---

## Step 8: Customer Segments (Donut Chart)

1. Click **Add a Chart** → **Pie Chart**
2. Position: middle-right
3. Data source: **DS_Customer_LTV**
4. Dimension: `customer_segment`
5. Metric: Record Count (or COUNT of `customer_id`)
6. Style:
   - Chart title: "Customer Segments"
   - Donut hole: 50%
   - Slice order: Platinum, Gold, Silver, Bronze
   - Colors: Platinum=#4285F4, Gold=#FBBC04, Silver=#9AA0A6, Bronze=#CD7F32

---

## Step 9: Payment Method Analysis

1. Click **Add a Chart** → **Stacked Bar Chart** (or Column Chart)
2. Position: bottom full-width
3. Data source: **DS_Payment_Analysis**
4. Dimension: `payment_method`
5. Metrics: `transaction_count`, `revenue`
6. Sort: `revenue` descending
7. Style:
   - Chart title: "Payment Method Analysis"
   - Show data labels: ON
   - Dual axis: transaction_count (left), revenue (right)

---

## Step 10: Add Date Range Filter

1. Click **Add a Control** → **Date Range Control**
2. Position: top-right corner
3. Data source: **DS_Daily_Sales**
4. Date dimension: `order_date`
5. Default date range: Last 12 months
6. Apply to: All charts using daily/monthly sales data

### Cross-Filter Setup

Enable cross-filtering so clicking a state on the map filters other charts:

1. Select the Geo Chart
2. In properties, enable **Interactions → Apply filter**
3. Repeat for bar chart and pie charts

---

## Step 11: Dashboard Styling

### Theme

1. Click **Theme and Layout** → **Customize**
2. Primary color: #4285F4
3. Font: Google Sans (or Roboto)
4. Background: #FFFFFF
5. Grid settings: ON (snap to grid)

### Header

1. Add a **Text** box at the top
2. Content: "RetailPulse Executive Dashboard"
3. Font size: 24px, Bold, Color: #333

### Footer

1. Add text: "Data source: BigQuery retail_gold | Last refreshed: auto"
2. Font size: 10px, Color: #9AA0A6

---

## Step 12: Testing and Validation

### Checklist

| # | Check | Expected |
|---|-------|----------|
| 1 | Revenue scorecard shows value > $0 | Matches `executive_kpis.total_revenue` |
| 2 | Monthly trend shows data points | One point per month in dataset |
| 3 | Geo map colors US states | States with sales are colored |
| 4 | Top products shows 10 bars | Filtered by revenue_rank ≤ 10 |
| 5 | Category pie sums to ~100% | Percentages add up |
| 6 | Customer segments show 4 slices | Platinum, Gold, Silver, Bronze |
| 7 | Payment chart shows all methods | Credit Card, PayPal, etc. |
| 8 | Date filter updates all charts | Charts respond to date change |

### Validation Query

```sql
SELECT
  (SELECT total_revenue FROM `retailpulse-project.retail_gold.executive_kpis`) AS kpi_revenue,
  (SELECT SUM(revenue) FROM `retailpulse-project.retail_gold.daily_sales`) AS daily_sum,
  (SELECT COUNT(*) FROM `retailpulse-project.retail_gold.top_products` WHERE revenue_rank <= 10) AS top_10_count;
```

Dashboard revenue should match `kpi_revenue`.

---

## Step 13: Sharing

### Share with Viewers

1. Click **Share** (top-right)
2. Add viewer email addresses
3. Permission: **Viewer** (not Editor)
4. Optional: "Notify people" checkbox

### Embed in Website

1. Click **Share** → **Embed report**
2. Copy iframe code
3. Set width="100%" height="800"

### Schedule Email Delivery

1. Click **Share** → **Schedule email delivery**
2. Set frequency: Weekly on Monday
3. Add recipient emails
4. Format: PDF attachment

---

## Advanced Enhancements

### Calculated Fields

**Revenue per Customer:**
```
total_revenue / total_customers
```

**Conversion Rate (if applicable):**
```
total_orders / total_customers
```

### Parameters

Create a **parameter** for dynamic top-N:

1. Resource → Manage blended data → Add a parameter
2. Name: `top_n`, Type: Number, Default: 10
3. Use in filter: `revenue_rank <= top_n`

### Blended Data

Blend `DS_Top_Products` with `DS_Top_Categories` on a shared `brand` field for a combined product-category analysis.

### Conditional Formatting

On the revenue scorecard, add conditional formatting:
- Green if total_revenue > 1,000,000
- Red if total_revenue < 500,000

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| "Permission denied" on BigQuery | Missing IAM role | Grant `bigquery.dataViewer` on retail_gold |
| Scorecard shows "null" | executive_kpis is empty | Re-run 05_gold_tables.sql |
| Geo map shows no states | State field not set as Geo type | Edit data source → state → Geo → US State |
| Charts show "No data" | Date filter too narrow | Reset date range to "Auto" or "All available dates" |
| Revenue doesn't match | Different filter scopes | Ensure all charts use consistent date filters |
| Slow dashboard load | Too many data sources | Use blended data or aggregate further in gold |

---

## Related Files

| File | Purpose |
|------|---------|
| `sql/05_gold_tables.sql` | Gold tables that feed the dashboard |
| `sql/06_views.sql` | Optional views for simplified data sources |
| `images/dashboard_mockup.png` | Visual reference mockup |
| `docs/TeachingGuide.md` | Classroom demo script for this dashboard |
