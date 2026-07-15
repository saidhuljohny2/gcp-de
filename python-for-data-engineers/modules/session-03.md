# Session 3 — NumPy for Numerical Data

**Duration:** 5 hours | **Lab:** [Lab 03](../labs/starter/lab-03.py)

## Objectives

- Understand why vectorization matters for data workloads
- Create and filter NumPy arrays
- Compute aggregations on time-series metrics

## Agenda

1. **Python loops vs vectorization** (45 min)
2. **Array creation & dtypes** (45 min)
3. **Boolean indexing** (60 min)
4. **Aggregations** (45 min)
5. **Lab 03** (90 min)

## Key Concepts

NumPy is the foundation under Pandas. DEs use it for: metrics arrays, image/sensor batches, and understanding Pandas performance.

```python
import numpy as np

temps = np.array([22.1, 23.4, np.nan, 21.8])
valid = temps[~np.isnan(temps)]
print(valid.mean())
```

## Quiz

1. What is broadcasting?
2. Why is `arr * 2` faster than `[x * 2 for x in arr]` at scale?
3. How do you filter elements > 100?
4. What does `np.nan` break about `mean()`?
5. When might you still use Pandas instead of raw NumPy?

## Homework

Compute hourly rollups from minute-level temperature data in `data/sensor_readings.csv`.
