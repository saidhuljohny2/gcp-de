# Session 6 — Joins, GroupBy & Window Logic

**Duration:** 5 hours | **Lab:** [Lab 06](../labs/starter/lab-06.py)

## Objectives

- Merge multiple tables with validation
- Aggregate with `groupby` and named aggregations
- Reshape data with `pivot_table`

## Agenda

1. **Merge types** (60 min) — inner/left, validate cardinality
2. **GroupBy** (60 min)
3. **Pivot & reshape** (45 min)
4. **Lab 06** (90 min)

## Key Concepts

```python
orders_enriched = orders.merge(
    customers, on="customer_id", how="left", validate="m:1"
)

daily_revenue = (
    orders_enriched.groupby("order_date", as_index=False)
    .agg(revenue=("amount_usd", "sum"), orders=("order_id", "nunique"))
)
```

Always check row counts before and after merges.

## Quiz

1. What does `validate="m:1"` catch?
2. Left vs inner join — impact on revenue totals?
3. Difference between `agg` and `transform`?
4. When to use `pivot_table` vs `groupby`?
5. How to find customers with >3 orders?

## Homework

Build a `dim_customer` with lifetime value and last order date.
