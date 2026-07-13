-- =============================================================================
-- RetailPulse | 07_analytics.sql
-- Purpose: 50+ Interview-Style Analytical Queries
-- Usage: Run individually in BigQuery Console or bq CLI
-- =============================================================================

-- =============================================================================
-- SECTION 1: TOP N & RANKING QUERIES (Q1–Q10)
-- =============================================================================

-- Q1: Top 10 customers by lifetime revenue
SELECT customer_id, customer_name, lifetime_value, total_orders, customer_segment
FROM `retailpulse-project.retail_gold.customer_lifetime_value`
ORDER BY lifetime_value DESC
LIMIT 10;

-- Q2: Top 10 products by revenue
SELECT product_id, product_name, category, total_revenue, units_sold, revenue_rank
FROM `retailpulse-project.retail_gold.top_products`
ORDER BY revenue_rank
LIMIT 10;

-- Q3: Top 5 categories by revenue
SELECT category, total_revenue, units_sold, category_revenue_rank
FROM `retailpulse-project.retail_gold.top_categories`
ORDER BY category_revenue_rank
LIMIT 5;

-- Q4: Top 10 states by revenue
SELECT state, total_revenue, total_orders, avg_order_value, state_revenue_rank
FROM `retailpulse-project.retail_gold.state_wise_sales`
ORDER BY state_revenue_rank
LIMIT 10;

-- Q5: Bottom 10 states by revenue
SELECT state, total_revenue, total_orders
FROM `retailpulse-project.retail_gold.state_wise_sales`
ORDER BY total_revenue ASC
LIMIT 10;

-- Q6: Top brands overall
SELECT brand, SUM(total_revenue) AS revenue, SUM(units_sold) AS units
FROM `retailpulse-project.retail_gold.brand_performance`
GROUP BY brand
ORDER BY revenue DESC
LIMIT 10;

-- Q7: Top product in each category
SELECT category, product_name, total_revenue
FROM (
  SELECT
    p.category, p.product_name, p.total_revenue,
    RANK() OVER (PARTITION BY p.category ORDER BY p.total_revenue DESC) AS rnk
  FROM `retailpulse-project.retail_gold.top_products` p
)
WHERE rnk = 1;

-- Q8: Top 10 customers by order count
SELECT customer_id, customer_name, total_orders, lifetime_value
FROM `retailpulse-project.retail_gold.customer_lifetime_value`
ORDER BY total_orders DESC, lifetime_value DESC
LIMIT 10;

-- Q9: Highest average order value by state
SELECT state, avg_order_value, total_orders
FROM `retailpulse-project.retail_gold.state_wise_sales`
ORDER BY avg_order_value DESC
LIMIT 10;

-- Q10: Top payment methods by revenue
SELECT payment_method, SUM(associated_revenue) AS revenue, SUM(payment_count) AS payments
FROM `retailpulse-project.retail_gold.payment_analysis`
WHERE payment_status = 'Success'
GROUP BY payment_method
ORDER BY revenue DESC;

-- =============================================================================
-- SECTION 2: REVENUE & SALES TRENDS (Q11–Q20)
-- =============================================================================

-- Q11: Monthly revenue trend
SELECT year_month, gross_revenue, total_orders, mom_revenue_growth_pct
FROM `retailpulse-project.retail_gold.monthly_sales`
ORDER BY sale_month;

-- Q12: Daily revenue for last 30 days
SELECT sale_date, gross_revenue, total_orders, avg_order_value
FROM `retailpulse-project.retail_gold.daily_sales`
WHERE sale_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
ORDER BY sale_date;

-- Q13: Year-over-year monthly comparison
SELECT
  sale_month_num,
  SUM(CASE WHEN sale_year = 2024 THEN gross_revenue END) AS revenue_2024,
  SUM(CASE WHEN sale_year = 2025 THEN gross_revenue END) AS revenue_2025
FROM `retailpulse-project.retail_gold.monthly_sales`
GROUP BY sale_month_num
ORDER BY sale_month_num;

-- Q14: Running total revenue by day
SELECT
  sale_date,
  gross_revenue,
  SUM(gross_revenue) OVER (ORDER BY sale_date ROWS UNBOUNDED PRECEDING) AS cumulative_revenue
FROM `retailpulse-project.retail_gold.daily_sales`
ORDER BY sale_date;

-- Q15: 7-day moving average of daily revenue
SELECT
  sale_date,
  gross_revenue,
  AVG(gross_revenue) OVER (
    ORDER BY sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS revenue_7day_ma
FROM `retailpulse-project.retail_gold.daily_sales`
ORDER BY sale_date;

-- Q16: Revenue by quarter
SELECT
  CONCAT(EXTRACT(YEAR FROM sale_month), '-Q', EXTRACT(QUARTER FROM sale_month)) AS quarter,
  SUM(gross_revenue) AS quarterly_revenue,
  SUM(total_orders) AS quarterly_orders
FROM `retailpulse-project.retail_gold.monthly_sales`
GROUP BY quarter
ORDER BY quarter;

-- Q17: Best revenue day ever
SELECT sale_date, gross_revenue, total_orders
FROM `retailpulse-project.retail_gold.daily_sales`
ORDER BY gross_revenue DESC
LIMIT 1;

-- Q18: Worst revenue day (excluding zero)
SELECT sale_date, gross_revenue, total_orders
FROM `retailpulse-project.retail_gold.daily_sales`
WHERE gross_revenue > 0
ORDER BY gross_revenue ASC
LIMIT 1;

-- Q19: Weekend vs weekday revenue
SELECT
  CASE WHEN EXTRACT(DAYOFWEEK FROM sale_date) IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
  SUM(gross_revenue) AS total_revenue,
  AVG(gross_revenue) AS avg_daily_revenue,
  COUNT(*) AS days_count
FROM `retailpulse-project.retail_gold.daily_sales`
GROUP BY day_type;

-- Q20: Revenue growth rate month over month
SELECT
  year_month,
  gross_revenue,
  prev_month_revenue,
  mom_revenue_growth_pct
FROM `retailpulse-project.retail_gold.monthly_sales`
WHERE prev_month_revenue IS NOT NULL
ORDER BY sale_month;

-- =============================================================================
-- SECTION 3: CUSTOMER ANALYTICS (Q21–Q30)
-- =============================================================================

-- Q21: Customer retention — repeat vs one-time
SELECT
  customer_segment,
  COUNT(*) AS customer_count,
  ROUND(AVG(lifetime_value), 2) AS avg_ltv
FROM `retailpulse-project.retail_gold.customer_lifetime_value`
GROUP BY customer_segment
ORDER BY avg_ltv DESC;

-- Q22: Repeat customer rate
SELECT
  COUNTIF(is_repeat_customer) AS repeat_customers,
  COUNT(*) AS total_customers_with_orders,
  ROUND(COUNTIF(is_repeat_customer) * 100.0 / COUNT(*), 2) AS repeat_rate_pct
FROM `retailpulse-project.retail_gold.repeat_customers`;

-- Q23: Average days between first and last order for repeat customers
SELECT
  ROUND(AVG(days_between_first_last), 1) AS avg_days_between_orders,
  ROUND(APPROX_QUANTILES(days_between_first_last, 100)[OFFSET(50)], 1) AS median_days
FROM `retailpulse-project.retail_gold.repeat_customers`
WHERE is_repeat_customer = TRUE;

-- Q24: New customers per month (by signup)
SELECT
  FORMAT_DATE('%Y-%m', signup_date) AS signup_month,
  COUNT(*) AS new_customers
FROM `retailpulse-project.retail_silver.dim_customers`
WHERE signup_date IS NOT NULL
GROUP BY signup_month
ORDER BY signup_month;

-- Q25: Customers with no orders
SELECT COUNT(*) AS customers_without_orders
FROM `retailpulse-project.retail_silver.dim_customers` c
LEFT JOIN `retailpulse-project.retail_gold.customer_lifetime_value` clv ON c.customer_id = clv.customer_id
WHERE clv.total_orders IS NULL OR clv.total_orders = 0;

-- Q26: VIP customers (top decile LTV)
SELECT customer_id, customer_name, lifetime_value, total_orders
FROM `retailpulse-project.retail_gold.customer_lifetime_value`
WHERE ltv_decile = 1
ORDER BY lifetime_value DESC
LIMIT 20;

-- Q27: Customer cohort analysis — orders by signup month
SELECT
  FORMAT_DATE('%Y-%m', c.signup_date) AS cohort,
  COUNT(DISTINCT c.customer_id) AS cohort_size,
  COUNT(DISTINCT fo.order_id) AS total_orders,
  ROUND(SUM(fo.total_amount), 2) AS cohort_revenue
FROM `retailpulse-project.retail_silver.dim_customers` c
LEFT JOIN `retailpulse-project.retail_silver.fact_orders` fo
  ON c.customer_id = fo.customer_id AND fo.is_revenue_eligible = TRUE
WHERE c.signup_date IS NOT NULL
GROUP BY cohort
ORDER BY cohort;

-- Q28: Customers who only bought once
SELECT COUNT(*) AS one_time_buyers
FROM `retailpulse-project.retail_gold.customer_lifetime_value`
WHERE total_orders = 1;

-- Q29: Average customer tenure in days
SELECT ROUND(AVG(customer_tenure_days), 1) AS avg_tenure_days
FROM `retailpulse-project.retail_gold.customer_lifetime_value`
WHERE total_orders > 1;

-- Q30: Top city by customer count
SELECT city, state, COUNT(*) AS customer_count
FROM `retailpulse-project.retail_silver.dim_customers`
GROUP BY city, state
ORDER BY customer_count DESC
LIMIT 10;

-- =============================================================================
-- SECTION 4: PRODUCT & CATEGORY ANALYTICS (Q31–Q40)
-- =============================================================================

-- Q31: Best selling category by units
SELECT category, units_sold, total_revenue
FROM `retailpulse-project.retail_gold.top_categories`
ORDER BY units_sold DESC
LIMIT 1;

-- Q32: Category revenue share (%)
SELECT
  category,
  total_revenue,
  ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER (), 2) AS revenue_share_pct
FROM `retailpulse-project.retail_gold.top_categories`
ORDER BY revenue_share_pct DESC;

-- Q33: Products with highest margin
SELECT product_id, product_name, category, price, cost, margin_pct
FROM `retailpulse-project.retail_silver.dim_products`
ORDER BY margin_pct DESC
LIMIT 10;

-- Q34: Brand market share within Electronics
SELECT
  brand,
  total_revenue,
  ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER (), 2) AS share_pct
FROM `retailpulse-project.retail_gold.brand_performance`
WHERE category = 'ELECTRONICS'
ORDER BY total_revenue DESC;

-- Q35: Average units per order by category
SELECT
  foi.category,
  ROUND(AVG(foi.quantity), 2) AS avg_units_per_line,
  COUNT(DISTINCT foi.order_id) AS orders
FROM `retailpulse-project.retail_silver.fact_order_items` foi
WHERE foi.is_revenue_eligible = TRUE
GROUP BY foi.category
ORDER BY avg_units_per_line DESC;

-- Q36: Products never sold
SELECT p.product_id, p.product_name, p.category
FROM `retailpulse-project.retail_silver.dim_products` p
LEFT JOIN `retailpulse-project.retail_silver.fact_order_items` foi ON p.product_id = foi.product_id
WHERE foi.product_id IS NULL;

-- Q37: Cross-category analysis — orders with multiple categories
SELECT
  CASE WHEN category_count > 1 THEN 'Multi-Category' ELSE 'Single-Category' END AS order_type,
  COUNT(*) AS order_count
FROM (
  SELECT order_id, COUNT(DISTINCT category) AS category_count
  FROM `retailpulse-project.retail_silver.fact_order_items`
  WHERE is_revenue_eligible = TRUE
  GROUP BY order_id
)
GROUP BY order_type;

-- Q38: Subcategory performance
SELECT
  p.category,
  p.subcategory,
  SUM(foi.line_total) AS revenue,
  SUM(foi.quantity) AS units
FROM `retailpulse-project.retail_silver.fact_order_items` foi
JOIN `retailpulse-project.retail_silver.dim_products` p ON foi.product_id = p.product_id
WHERE foi.is_revenue_eligible = TRUE
GROUP BY p.category, p.subcategory
ORDER BY revenue DESC
LIMIT 15;

-- Q39: Price band distribution
SELECT
  CASE
    WHEN total_amount < 50 THEN 'Under $50'
    WHEN total_amount < 100 THEN '$50-$100'
    WHEN total_amount < 250 THEN '$100-$250'
    WHEN total_amount < 500 THEN '$250-$500'
    ELSE '$500+'
  END AS price_band,
  COUNT(*) AS order_count
FROM `retailpulse-project.retail_silver.fact_orders`
WHERE is_revenue_eligible = TRUE
GROUP BY price_band
ORDER BY MIN(total_amount);

-- Q40: Discount impact on order value
SELECT
  CASE WHEN discount > 0 THEN 'With Discount' ELSE 'No Discount' END AS discount_flag,
  COUNT(*) AS orders,
  ROUND(AVG(total_amount), 2) AS avg_order_value,
  ROUND(AVG(discount), 2) AS avg_discount
FROM `retailpulse-project.retail_silver.fact_orders`
WHERE is_revenue_eligible = TRUE
GROUP BY discount_flag;

-- =============================================================================
-- SECTION 5: PAYMENT & OPERATIONS (Q41–Q45)
-- =============================================================================

-- Q41: Payment success rate by method
SELECT
  payment_method,
  ROUND(COUNTIF(payment_status = 'Success') * 100.0 / COUNT(*), 2) AS success_rate_pct,
  COUNT(*) AS total_payments
FROM `retailpulse-project.retail_silver.dim_payments`
GROUP BY payment_method
ORDER BY success_rate_pct DESC;

-- Q42: Revenue by payment method (successful only)
SELECT payment_method, SUM(associated_revenue) AS revenue
FROM `retailpulse-project.retail_gold.payment_analysis`
WHERE payment_status = 'Success'
GROUP BY payment_method
ORDER BY revenue DESC;

-- Q43: Failed payment analysis
SELECT payment_method, payment_status, COUNT(*) AS cnt
FROM `retailpulse-project.retail_silver.dim_payments`
WHERE payment_status IN ('Failed', 'Refunded')
GROUP BY payment_method, payment_status
ORDER BY cnt DESC;

-- Q44: Orders by status distribution
SELECT status, COUNT(*) AS order_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct
FROM `retailpulse-project.retail_silver.fact_orders`
GROUP BY status
ORDER BY order_count DESC;

-- Q45: Average order value (global KPI)
SELECT avg_order_value, median_order_value, order_count
FROM `retailpulse-project.retail_gold.average_order_value`
WHERE dimension = 'ALL';

-- =============================================================================
-- SECTION 6: ADVANCED WINDOW FUNCTIONS (Q46–Q50)
-- =============================================================================

-- Q46: Customer order sequence with LAG/LEAD
SELECT
  customer_id,
  order_id,
  order_date,
  total_amount,
  customer_order_sequence,
  LAG(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_amount,
  LEAD(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS next_order_amount
FROM `retailpulse-project.retail_silver.fact_orders`
WHERE is_revenue_eligible = TRUE
QUALIFY customer_order_sequence <= 3
ORDER BY customer_id, order_date
LIMIT 50;

-- Q47: Rank customers within each state by LTV
SELECT
  customer_id,
  customer_name,
  state,
  lifetime_value,
  RANK() OVER (PARTITION BY state ORDER BY lifetime_value DESC) AS state_rank
FROM `retailpulse-project.retail_gold.customer_lifetime_value`
WHERE lifetime_value > 0
QUALIFY state_rank <= 5
ORDER BY state, state_rank;

-- Q48: NTILE customer segmentation by revenue
SELECT
  customer_segment_ntile AS revenue_quartile,
  COUNT(*) AS customers,
  ROUND(AVG(lifetime_value), 2) AS avg_ltv
FROM `retailpulse-project.retail_gold.customer_lifetime_value` clv
JOIN `retailpulse-project.retail_silver.dim_customers` c ON clv.customer_id = c.customer_id
GROUP BY revenue_quartile
ORDER BY revenue_quartile;

-- Q49: Dense rank products by units within category
SELECT category, product_name, units_sold, units_rank
FROM `retailpulse-project.retail_gold.top_products`
QUALIFY DENSE_RANK() OVER (PARTITION BY category ORDER BY units_sold DESC) <= 3
ORDER BY category, units_rank;

-- Q50: First and last order date per customer
SELECT
  customer_id,
  FIRST_VALUE(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS first_order,
  LAST_VALUE(order_date) OVER (
    PARTITION BY customer_id ORDER BY order_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
  ) AS last_order,
  COUNT(*) OVER (PARTITION BY customer_id) AS order_count
FROM `retailpulse-project.retail_silver.fact_orders`
WHERE is_revenue_eligible = TRUE
QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) = 1
ORDER BY order_count DESC
LIMIT 20;

-- =============================================================================
-- BONUS QUERIES (Q51–Q55)
-- =============================================================================

-- Q51: Executive KPI snapshot
SELECT * FROM `retailpulse-project.retail_gold.executive_kpis`;

-- Q52: Pareto analysis — products contributing 80% revenue
WITH ranked AS (
  SELECT
    product_name,
    total_revenue,
    SUM(total_revenue) OVER (ORDER BY total_revenue DESC) AS cumulative_revenue,
    SUM(total_revenue) OVER () AS grand_total
  FROM `retailpulse-project.retail_gold.top_products`
)
SELECT product_name, total_revenue,
  ROUND(cumulative_revenue * 100.0 / grand_total, 2) AS cumulative_pct
FROM ranked
WHERE cumulative_revenue <= grand_total * 0.8
ORDER BY total_revenue DESC;

-- Q53: Orders with tax greater than 10% of total
SELECT order_id, total_amount, tax, ROUND(tax / NULLIF(total_amount, 0) * 100, 2) AS tax_pct
FROM `retailpulse-project.retail_silver.fact_orders`
WHERE is_revenue_eligible = TRUE AND tax > total_amount * 0.10
LIMIT 20;

-- Q54: Seasonality — revenue by month of year
SELECT
  EXTRACT(MONTH FROM sale_month) AS month_num,
  FORMAT_DATE('%B', sale_month) AS month_name,
  AVG(gross_revenue) AS avg_monthly_revenue
FROM `retailpulse-project.retail_gold.monthly_sales`
GROUP BY month_num, month_name
ORDER BY month_num;

-- Q55: Data quality — orders with line revenue mismatch
SELECT
  fo.order_id,
  fo.total_amount,
  fo.line_revenue,
  ABS(fo.total_amount - fo.line_revenue - fo.tax + fo.discount) AS variance
FROM `retailpulse-project.retail_silver.fact_orders` fo
WHERE fo.is_revenue_eligible = TRUE
  AND ABS(fo.total_amount - COALESCE(fo.line_revenue, 0)) > 100
ORDER BY variance DESC
LIMIT 20;
