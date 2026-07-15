---
marp: true
theme: default
paginate: true
footer: 'Session 03 — NumPy'
style: |
  section { font-size: 28px; }
  h1 { color: #1a5276; }
  pre { background: #1e1e1e; color: #d4d4d4; }
---

# Session 3
## NumPy for Numerical Data

**Week 2** | Lab 03: Sensor Metrics

---

## Why Vectorization?

| Approach | 1M rows |
|----------|---------|
| Python loop | ~seconds |
| NumPy vectorized | ~milliseconds |

DE insight: Pandas uses NumPy under the hood

---

## Arrays & dtypes

```python
import numpy as np

temps = np.array([22.1, 23.4, np.nan, 21.8])
print(temps.dtype)      # float64
print(temps.mean())     # nan — need nan-aware ops
print(np.nanmean(temps))  # 22.43
```

---

## Boolean Indexing

```python
mask = temps > 22
hot = temps[mask]
valid = temps[~np.isnan(temps)]
```

Filter **without** explicit loops

---

## Aggregations per Group

Use Pandas `groupby` for labeled groups — NumPy for raw array math

Lab 03: per-sensor min / mean / max temperature

---

## Key Takeaways

- Prefer vectorized ops on numeric columns
- Handle `NaN` explicitly
- NumPy explains **why** Pandas is fast

**Next:** Pandas DataFrames → Session 4
