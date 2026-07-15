# Session 1 — Environment & Python Essentials

**Duration:** 5 hours | **Lab:** [Lab 01](../labs/starter/lab-01.py)

## Objectives

- Explain where Python fits in a modern data stack
- Set up a reproducible development environment
- Use core types and collections to parse simple log lines

## Agenda

1. **Why Python for DE** (30 min) — orchestrators, transforms, cloud SDKs
2. **Environment setup** (45 min) — venv, pip, running scripts
3. **Types & variables** (45 min) — REPL exploration
4. **Collections** (60 min) — lists and dicts for records
5. **String processing** (45 min) — parsing pipeline logs
6. **Lab 01** (90 min)

## Key Concepts

### The Data Engineer Python Stack

```
Sources → Ingest (Python) → Staging → Transform (Python/SQL) → Warehouse → Analytics
```

Python is strongest at: glue code, API ingestion, complex transforms, SDK integration.

### Collections Cheat Sheet

| Type | DE use case |
|------|-------------|
| `list` | Ordered rows, column names |
| `dict` | JSON records, config key-value |
| `tuple` | Immutable keys, function returns |
| `set` | Distinct values, dedup checks |

## Demo: Parse a Log Line

```python
line = "2024-01-15 10:23:01 ERROR payment-service timeout user_id=8821"
parts = line.split()
timestamp = " ".join(parts[:2])
level = parts[2]
message = " ".join(parts[3:])
print(timestamp, level, message)
```

## Quiz (5 questions)

1. What is the difference between a list and a tuple?
2. When would you use a `dict` vs a `list` of `dict`s for API data?
3. What does `venv` isolate?
4. What is the output of `"a,b,c".split(",")`?
5. Name two places Python runs in a typical cloud data platform.

## Homework

Read Python tutorial sections on [data structures](https://docs.python.org/3/tutorial/datastructures.html).
