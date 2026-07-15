# Session 11 — Cloud Storage & Batch Patterns

**Duration:** 5 hours | **Lab:** [Lab 11](../labs/starter/lab-11.py)

## Objectives

- Understand object storage and Hive-style partitions
- Read/write Parquet efficiently
- Process large files in chunks

## Agenda

1. **Object storage model** (45 min)
2. **Parquet & pyarrow** (45 min)
3. **Partitioning** (45 min)
4. **Chunked reads** (45 min)
5. **Lab 11** (90 min)

## Key Concepts

Partition path example: `s3://bucket/orders/dt=2024-01-15/part-000.parquet`

Locally simulate with: `data/lake/orders/dt=2024-01-15/data.parquet`

```python
for chunk in pd.read_csv("data/large_orders.csv", chunksize=50_000):
    process(chunk)
```

## Quiz

1. Columnar vs row storage benefits?
2. Why partition by date?
3. Memory issue with `read_csv` on 10GB file?
4. What metadata does Parquet store?
5. Small files problem?

## Homework

Write a partition compaction script merging small Parquet files.
