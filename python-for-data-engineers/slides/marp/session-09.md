---
marp: true
theme: default
paginate: true
footer: 'Session 09 — Pipeline Architecture'
style: |
  section { font-size: 28px; }
  h1 { color: #1a5276; }
  pre { background: #1e1e1e; color: #d4d4d4; }
---

# Session 9
## Pipeline Architecture & Orchestration

**Week 5** | Lab 09: Config + CLI Pipeline

---

## ETL vs ELT

| Pattern | Python runs... |
|---------|----------------|
| ETL | Before warehouse load |
| ELT | After raw load in warehouse |

Cloud trend: **ELT** + SQL transforms; Python for ingest & complex logic

---

## Project Layout

```
pipeline/
  extract.py
  transform.py
  load.py
  run.py          # CLI entry
config.yaml       # paths, no secrets
.env              # secrets (gitignored)
```

---

## External Config

```yaml
input_path: data/orders.csv
output_path: data/outbox/pipeline_orders.parquet
```

```python
import yaml
cfg = yaml.safe_load(Path("config.yaml").read_text())
```

---

## CLI for Schedulers

```python
import argparse
parser = argparse.ArgumentParser()
parser.add_argument("--run-date")
args = parser.parse_args()
```

Airflow/cron calls: `python run.py --run-date 2024-01-15`

---

## Idempotency

Re-running the job should be **safe**

- Partition overwrite by date
- Merge on natural key
- Staging → prod swap

---

## Lab 09

YAML config + argparse + E/T/L modules

---

## Key Takeaways

- Separate config from code
- CLI entry points integrate with orchestrators
- Design for safe re-runs from day one

**Next:** Logging & testing → Session 10
