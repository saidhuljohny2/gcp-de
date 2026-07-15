# Session 7 — APIs & Semi-Structured Data

**Duration:** 5 hours | **Lab:** [Lab 07](../labs/starter/lab-07.py)

## Objectives

- Call REST APIs with `requests` and handle errors
- Paginate through API results
- Flatten nested JSON into tabular form

## Agenda

1. **HTTP for DEs** (45 min)
2. **requests library** (45 min)
3. **Pagination patterns** (60 min)
4. **JSON normalization** (30 min)
5. **Lab 07** (90 min)

## Key Concepts

```python
import requests

def fetch_page(url: str, params: dict) -> dict:
    resp = requests.get(url, params=params, timeout=30)
    resp.raise_for_status()
    return resp.json()
```

Incremental loads: persist `last_updated` watermark in a metadata table or file.

## Quiz

1. What does `raise_for_status()` do?
2. How to respect API rate limits?
3. Difference between `json.loads` and `response.json()`?
4. What is `pd.json_normalize` for?
5. Idempotent API load strategy?

## Homework

Add exponential backoff retry on HTTP 429/503.
