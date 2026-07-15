# Session 8 — Databases with Python

**Duration:** 5 hours | **Lab:** [Lab 08](../labs/starter/lab-08.py)

## Objectives

- Connect to SQLite with SQLAlchemy
- Extract query results into Pandas
- Load DataFrames back with append/replace strategies

## Agenda

1. **SQLAlchemy engines** (45 min)
2. **Extract with read_sql** (60 min)
3. **Load with to_sql** (60 min)
4. **Transactions** (30 min)
5. **Lab 08** (90 min)

## Key Concepts

```python
from sqlalchemy import create_engine, text

engine = create_engine("sqlite:///data/retail.db")

with engine.connect() as conn:
    df = pd.read_sql(text("SELECT * FROM raw_orders WHERE order_date >= :d"), conn, params={"d": "2024-01-01"})
```

**Never** use f-strings for SQL values — use bound parameters.

## Quiz

1. `if_exists="append"` vs `"replace"`?
2. Why use a context manager for connections?
3. How does SQLAlchemy help across SQLite vs Postgres?
4. Batch insert considerations?
5. When to push transforms to SQL vs Pandas?

## Homework

Implement upsert pattern with a staging table.
