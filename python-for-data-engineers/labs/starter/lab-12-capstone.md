# Capstone — RetailPulse End-to-End Pipeline

## Scenario

You are the data engineer for **RetailPulse**. Build a pipeline that prepares analytics-ready datasets from multiple sources.

## Sources

| Source | Path | Format |
|--------|------|--------|
| Orders | `data/orders.csv` | CSV |
| Customers | `data/customers.json` | JSON array |
| Products (API mock) | `data/api_products_page*.json` | Paginated JSON |
| Product master | `data/products.csv` | CSV |

## Deliverables

Create a package or script tree under `capstone/` with:

```
capstone/
  README.md           # How to run
  config.yaml         # Paths and settings
  run.py              # CLI entry point
  extract.py
  transform.py
  load.py
  tests/              # ≥3 pytest tests
```

### Output tables (Parquet)

1. **`output/fact_orders.parquet`** — completed orders with:
   - `amount_usd`, customer country, product category
2. **`output/dim_customers.parquet`** — one row per customer, cleaned email/name

### Non-functional requirements

- [ ] Idempotent: re-running does not duplicate or corrupt data
- [ ] Logging at INFO for each major step
- [ ] `pytest` passes
- [ ] `python capstone/run.py` runs end-to-end

## Stretch goals

- Incremental load by `order_date`
- Data quality HTML report
- SQLite load in addition to Parquet

## Presentation (15 min)

1. Architecture diagram
2. Live demo
3. Production improvements you'd make next

## Evaluation

See `docs/instructor-guide.md` capstone rubric (30 points).
