# Instructor Guide

## Teaching Philosophy

Lead with **data engineering scenarios**, not abstract CS. Every concept should answer: *"When would I use this in a pipeline?"*

- **Live code > slides** — use slides for mental models, then switch to the IDE.
- **Fail on purpose** — show bad CSV data, API timeouts, and schema drift.
- **Incremental labs** — each lab builds skills used in the capstone.

## Session Checklist

Before each session:

- [ ] Pull latest repo; verify `data/` sample files present
- [ ] Open `slides/marp/session-XX.md` in preview mode
- [ ] Run lab solution once to confirm dependencies
- [ ] Prepare 2–3 "extension" challenges for fast finishers

## Assessment Rubrics

### Weekly Labs (50 points total, 5 pts each)

| Criterion | 5 | 3 | 1 |
|-----------|---|---|---|
| Correctness | Runs end-to-end, correct output | Partial output or edge-case bugs | Does not run |
| Code quality | Clear names, functions, no dead code | Works but messy | Copy-paste spaghetti |
| DE practices | Uses pathlib, logging, or config where relevant | Some good practices | Script-only, no structure |

### Capstone (30 points)

| Criterion | Points |
|-----------|--------|
| Ingests ≥2 sources | 6 |
| Documented transforms | 6 |
| Idempotent or safe re-run | 4 |
| Tests (≥3) | 6 |
| README with run instructions | 4 |
| Demo / walkthrough | 4 |

### Weekly Quizzes (20 points total)

5 questions × 4 weeks (weeks 1–4) + capstone review quiz. Mix:

- Multiple choice (concepts)
- Code reading (what does this output?)
- Short answer (when to use merge vs join)

**Sample questions** are embedded at the bottom of each `modules/session-XX.md`.

## Common Student Struggles

| Issue | Session | Fix |
|-------|---------|-----|
| Indentation errors | 1–2 | Use an IDE with visible whitespace; never mix tabs/spaces |
| `SettingWithCopyWarning` | 4–6 | Teach `.loc` assignment; use `.copy()` explicitly |
| Timezone-naive datetimes | 5 | Always `utc=True` then convert |
| API pagination loops | 7 | Whiteboard the while-loop pattern first |
| SQL string formatting | 8 | Show SQL injection example, then parameterized queries |
| "It works on my machine" | 9–10 | Introduce `.env` and `requirements.txt` early |

## Capstone Scenario (RetailPulse)

Students build a pipeline for a fictional retailer:

1. **Sources:** `data/orders.csv`, `data/customers.json`, REST API mock (`data/api_products.json` pages)
2. **Transforms:** clean orders, join to customers, enrich with product categories
3. **Output:** `output/fact_orders.parquet`, `output/dim_customers.parquet`
4. **Ops:** `config.yaml`, `pytest`, structured logs

Provide the data files in `data/`; students should not need external accounts.

## Timing Adjustments

| If running short | If running long |
|------------------|-----------------|
| Skip NumPy broadcasting deep-dive | Add Great Expectations hands-on |
| Combine sessions 5+6 review | Add Airflow Docker demo (optional week 7) |
| Capstone as take-home | Split capstone across 2 sessions |

## Slide Delivery Notes

- **Marp decks** in `slides/marp/` — export to PDF for students who want handouts:
  ```bash
  marp slides/marp/session-01.md -o slides/pdf/session-01.pdf
  ```
- **PPTX** in `slides/pptx/` — for PowerPoint/Keynote presenters; regenerate with:
  ```bash
  python scripts/generate_pptx.py
  ```

## Extension Topics (Optional Week 7+)

- Apache Airflow locally with Docker
- dbt Python models
- Spark with PySpark
- GCP/AWS SDK basics (BigQuery, S3)
- Kafka consumer with `confluent-kafka`
