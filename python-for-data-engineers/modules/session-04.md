# Session 4 — Pandas Fundamentals

**Duration:** 5 hours | **Lab:** [Lab 04](../labs/starter/lab-04.py)

## Objectives

- Load CSV and Parquet into DataFrames
- Select rows and columns with `.loc` / `.iloc`
- Apply column transforms with `assign` and `astype`

## Agenda

1. **Series vs DataFrame** (30 min)
2. **Loading data** (45 min) — CSV, Parquet, dtype inference
3. **Selection** (60 min)
4. **Column operations** (60 min)
5. **Lab 04** (90 min)

## Key Concepts

```python
import pandas as pd

df = pd.read_csv("data/orders.csv", parse_dates=["order_date"])
summary = (
    df.assign(amount_usd=df["amount"] * df["fx_rate"])
    .loc[df["status"] == "completed", ["order_id", "amount_usd"]]
)
```

### `.loc` vs `.iloc`

| Method | Index by |
|--------|----------|
| `.loc` | labels |
| `.iloc` | integer position |

## Quiz

1. What does `parse_dates` do at read time?
2. Difference between `df["col"]` and `df[["col"]]`?
3. When do you get `SettingWithCopyWarning`?
4. Why prefer Parquet over CSV in pipelines?
5. How do you inspect `df.dtypes` and fix a numeric column read as object?

## Homework

Profile memory usage: CSV vs Parquet for the same dataset.
