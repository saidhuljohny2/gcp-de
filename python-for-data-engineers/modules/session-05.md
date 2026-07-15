# Session 5 — Data Cleaning Pipelines

**Duration:** 5 hours | **Lab:** [Lab 05](../labs/starter/lab-05.py)

## Objectives

- Handle missing values with explicit strategies
- Normalize text and categorical fields
- Chain cleaning steps as pure functions

## Agenda

1. **Missing data strategies** (60 min)
2. **Duplicates & keys** (45 min)
3. **Dates & types** (45 min)
4. **Pipeline composition** (30 min)
5. **Lab 05** (90 min)

## Key Concepts

```python
def clean_orders(df: pd.DataFrame) -> pd.DataFrame:
    return (
        df.drop_duplicates(subset=["order_id"])
        .assign(
            email=df["email"].str.strip().str.lower(),
            order_date=pd.to_datetime(df["order_date"], utc=True),
        )
        .fillna({"discount": 0})
    )
```

Document **why** you chose each fill strategy — auditors and future you will ask.

## Quiz

1. `dropna` vs `fillna` — when for each?
2. Danger of forward-fill on financial amounts?
3. How to detect duplicate natural keys before load?
4. What does `utc=True` on `to_datetime` give you?
5. Why chain with `.pipe()`?

## Homework

Add a data profile report: null %, distinct counts per column.
