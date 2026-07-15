---
marp: true
theme: default
paginate: true
footer: 'Session 11 — Cloud & Batch'
style: |
  section { font-size: 28px; }
  h1 { color: #1a5276; }
  pre { background: #1e1e1e; color: #d4d4d4; }
---

# Session 11
## Cloud Storage & Batch Patterns

**Week 6** | Lab 11: Partitioned Parquet Lake

---

## Object Storage Model

```
s3://bucket/orders/dt=2024-01-15/part-000.parquet
         │        │            │
      bucket   prefix      partition
```

Locally simulate: `data/lake/orders/dt=2024-01-15/`

---

## Why Parquet?

- **Columnar** — read only needed columns
- **Compressed** — less storage & network
- **Typed schema** — embedded metadata

Standard for data lakes & warehouses

---

## Hive-Style Partitions

```python
for date, group in df.groupby("order_date"):
    path = f"data/lake/orders/dt={date}/data.parquet"
    group.to_parquet(path, index=False)
```

Query engines prune partitions by date filter

---

## Chunked Processing

```python
for chunk in pd.read_csv("huge.csv", chunksize=50_000):
    process(chunk)
```

Memory-bounded processing for files > RAM

---

## Small Files Problem

Too many tiny Parquet files → slow queries

**Fix:** compaction jobs merging partitions

---

## Lab 11

Write partitioned lake → read single `dt=` partition back

---

## Key Takeaways

- Partition by query patterns (usually date)
- Parquet over CSV for analytics layers
- Chunk when data exceeds memory

**Next:** Capstone → Session 12
