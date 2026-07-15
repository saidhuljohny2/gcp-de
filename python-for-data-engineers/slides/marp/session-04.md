---
marp: true
theme: default
paginate: true
footer: 'Session 04 — Pandas Fundamentals'
style: |
  section { font-size: 28px; }
  h1 { color: #1a5276; }
  pre { background: #1e1e1e; color: #d4d4d4; }
---

# Session 4
## Pandas Fundamentals

**Week 2** | Lab 04: Orders ETL

---

## Series vs DataFrame

- **Series** — one column with index
- **DataFrame** — table of Series

```python
import pandas as pd
df = pd.read_csv("data/orders.csv", parse_dates=["order_date"])
df.info()
df.head()
```

---

## Selection: .loc vs .iloc

| Method | Indexes by |
|--------|------------|
| `.loc` | labels |
| `.iloc` | integer position |

```python
df.loc[df["status"] == "completed", ["order_id", "amount"]]
```

---

## Column Transforms

```python
completed = (
    df.assign(amount_usd=df["amount"] * df["fx_rate"])
    .loc[df["status"] == "completed"]
)
completed.to_parquet("data/outbox/completed_orders.parquet")
```

---

## CSV vs Parquet

| Format | Pros |
|--------|------|
| CSV | Human-readable, universal |
| Parquet | Compressed, typed, columnar |

**Pipelines:** land CSV → process → store Parquet

---

## Lab 04

Load orders → compute `amount_usd` → filter completed → write Parquet

---

## Key Takeaways

- Parse dates at **read** time
- Chain transforms with `assign` + `loc`
- Parquet for downstream analytics

**Next:** Data cleaning → Session 5
