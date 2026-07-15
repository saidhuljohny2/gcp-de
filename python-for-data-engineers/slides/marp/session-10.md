---
marp: true
theme: default
paginate: true
footer: 'Session 10 — Logging & Testing'
style: |
  section { font-size: 28px; }
  h1 { color: #1a5276; }
  pre { background: #1e1e1e; color: #d4d4d4; }
---

# Session 10
## Logging, Testing & Data Quality

**Week 5** | Lab 10: Tests + Validation Gates

---

## logging Module

```python
import logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

logger.info("Transforming %s rows", len(df))
```

Use INFO in prod; DEBUG only when troubleshooting

---

## pytest Unit Tests

```python
def test_transform_filters_cancelled(sample_orders):
    result = transform(sample_orders)
    assert (result["status"] == "cancelled").sum() == 0
```

Test **transform functions** — not the whole database

---

## Fixtures

```python
@pytest.fixture
def sample_orders():
    return pd.DataFrame({...})
```

Reusable sample data → consistent tests

---

## Data Quality Gates

```python
def validate_orders(df):
    if len(df) < 1:
        raise ValueError("No rows")
    if df["order_id"].isna().any():
        raise ValueError("Null keys")
```

Fail fast **before** corrupting downstream tables

---

## Quality Check Types

| Check | Example |
|-------|---------|
| Row count | `len(df) > 0` |
| Null rate | `df["id"].isna().mean() < 0.01` |
| Schema | expected columns present |
| Range | `amount >= 0` |

---

## Lab 10

Add logging + 3 pytest tests + `validate_orders()`

Run: `pytest tests/ -v`

---

## Key Takeaways

- Logs are your production debugger
- Test pure transform functions
- Quality gates prevent silent data corruption

**Next:** Cloud batch patterns → Session 11
