---
marp: true
theme: default
paginate: true
footer: 'Session 07 — APIs & JSON'
style: |
  section { font-size: 28px; }
  h1 { color: #1a5276; }
  pre { background: #1e1e1e; color: #d4d4d4; }
---

# Session 7
## APIs & Semi-Structured Data

**Week 4** | Lab 07: Paginated API Ingest

---

## HTTP Basics for DEs

| Code | Meaning |
|------|---------|
| 200 | OK |
| 401 | Auth failed |
| 429 | Rate limited |
| 500 | Server error |

Always set `timeout=` and handle failures

---

## requests Pattern

```python
import requests

resp = requests.get(url, params={"page": 1}, timeout=30)
resp.raise_for_status()
data = resp.json()
```

---

## Pagination Loop

```python
page, total = 1, 1
frames = []
while page <= total:
    payload = fetch_page(page)
    total = payload["total_pages"]
    frames.append(pd.DataFrame(payload["products"]))
    page += 1
df = pd.concat(frames, ignore_index=True)
```

---

## Flatten Nested JSON

```python
pd.json_normalize(payload, record_path="items", meta="page")
```

Semi-structured → tabular for the warehouse

---

## Incremental Loads

Store watermark: `last_synced_at` in metadata table

Next run: `?since=2024-01-15T00:00:00Z`

---

## Lab 07

Mock API from `api_products_page*.json` → single Parquet file

---

## Key Takeaways

- Retry + backoff for production APIs
- Pagination is a while-loop mental model
- Normalize JSON early in the pipeline

**Next:** Databases → Session 8
