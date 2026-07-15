# Session 10 — Logging, Testing & Data Quality

**Duration:** 5 hours | **Lab:** [Lab 10](../labs/starter/lab-10.py)

## Objectives

- Add structured logging to pipelines
- Write pytest unit tests for transforms
- Implement lightweight data quality checks

## Agenda

1. **logging module** (60 min)
2. **pytest fundamentals** (60 min)
3. **Test fixtures** (30 min)
4. **Quality gates** (30 min)
5. **Lab 10** (90 min)

## Key Concepts

```python
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

def assert_row_count(df, min_rows: int) -> None:
    if len(df) < min_rows:
        raise ValueError(f"Expected >= {min_rows} rows, got {len(df)}")
```

## Quiz

1. DEBUG vs INFO in production?
2. What makes a good unit test for a transform?
3. Fixture purpose in pytest?
4. Row count vs schema validation?
5. When to fail the pipeline vs quarantine bad rows?

## Homework

Introduce one Great Expectations expectation on a column.
