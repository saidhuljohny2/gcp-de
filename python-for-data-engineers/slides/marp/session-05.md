---
marp: true
theme: default
paginate: true
footer: 'Session 05 — Data Cleaning'
style: |
  section { font-size: 28px; }
  h1 { color: #1a5276; }
  pre { background: #1e1e1e; color: #d4d4d4; }
---

# Session 5
## Data Cleaning Pipelines

**Week 3** | Lab 05: Clean Orders & Customers

---

## Missing Data Strategies

| Strategy | When |
|----------|------|
| `dropna` | Row unusable without value |
| `fillna(0)` | Numeric default safe |
| `fillna("UNKNOWN")` | Nullable dimension keys |
| Impute | ML / domain rules |

**Document your choice** — audits matter

---

## Cleaning Pipeline Pattern

```python
def clean_orders(df):
    return (
        df.drop_duplicates(subset=["order_id"])
        .assign(
            email=df["email"].str.strip().str.lower(),
            order_date=pd.to_datetime(df["order_date"], utc=True),
        )
        .fillna({"discount": 0})
    )
```

Pure function → easy to test

---

## Text Normalization

```python
df["name"] = df["name"].str.strip()
df["email"] = df["email"].str.lower()
```

80% of messy data is **whitespace and casing**

---

## Duplicate Detection

```python
df.duplicated(subset=["order_id"]).sum()
df.drop_duplicates(subset=["order_id"], keep="last")
```

Always check counts **before** and **after**

---

## Lab 05

Clean `orders.csv` + `customers.json` with reusable functions

---

## Key Takeaways

- Chain cleaning as composable functions
- UTC datetimes everywhere
- Dedup on natural keys before load

**Next:** Joins & GroupBy → Session 6
