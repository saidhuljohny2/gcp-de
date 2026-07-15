# Syllabus — Python for Data Engineers

## Course Goals

By the end of this course, learners will be able to:

1. Write idiomatic Python for data manipulation and pipeline scripts
2. Ingest, clean, transform, and load data using Pandas and SQL connectors
3. Build reliable ETL jobs with logging, error handling, and tests
4. Integrate with REST APIs and relational databases
5. Apply production patterns: config, idempotency, and data quality checks
6. Deliver a capstone pipeline from raw sources to analytics-ready tables

---

## Week 1 — Python Foundations for Data Work

### Session 1: Environment & Python Essentials
**Duration:** 5 hours | **Lab:** Lab 01

| Topic | Details |
|-------|---------|
| DE landscape | Where Python fits: orchestration, transforms, SDKs |
| Setup | venv, pip, VS Code/Cursor, REPL vs scripts |
| Types | int, float, str, bool, None |
| Collections | list, dict, tuple, set — when DEs use each |
| Strings | f-strings, parsing, `.split()`, `.strip()` |

**Learning outcomes:** Run Python scripts; manipulate strings and collections for log parsing.

### Session 2: Control Flow, Functions & File I/O
**Duration:** 5 hours | **Lab:** Lab 02

| Topic | Details |
|-------|---------|
| Control flow | if/elif/else, for, while, comprehensions |
| Functions | parameters, return, docstrings, `*args` |
| File I/O | `open()`, context managers, CSV/JSON basics |
| pathlib | Modern path handling for pipelines |
| Error handling intro | try/except, raising errors |

**Learning outcomes:** Build a script that reads files from a directory and writes transformed output.

---

## Week 2 — NumPy & Pandas

### Session 3: NumPy for Numerical Data
**Duration:** 5 hours | **Lab:** Lab 03

| Topic | Details |
|-------|---------|
| Arrays | creation, shape, dtype, broadcasting |
| Vectorized ops | why loops are slow in DE workloads |
| Boolean indexing | filtering rows at scale |
| Aggregations | sum, mean, percentiles on time-series |

**Learning outcomes:** Process sensor/metrics arrays without Python loops.

### Session 4: Pandas Fundamentals
**Duration:** 5 hours | **Lab:** Lab 04

| Topic | Details |
|-------|---------|
| Series & DataFrame | construction, `read_csv`, `read_parquet` |
| Selection | `.loc`, `.iloc`, boolean masks |
| dtypes | casting, `astype`, nullable integers |
| Basic transforms | `apply`, `map`, `rename`, `assign` |

**Learning outcomes:** Load tabular data and perform column-level transformations.

---

## Week 3 — Data Cleaning & Analytics Prep

### Session 5: Data Cleaning Pipelines
**Duration:** 5 hours | **Lab:** Lab 05

| Topic | Details |
|-------|---------|
| Missing data | `isna`, `fillna`, `dropna`, strategies |
| Duplicates | `duplicated`, `drop_duplicates` |
| Type coercion | dates with `pd.to_datetime` |
| Normalization | trimming, casing, category mapping |
| Pipeline pattern | chain transforms in pure functions |

**Learning outcomes:** Implement a reusable cleaning module for messy retail data.

### Session 6: Joins, GroupBy & Window Logic
**Duration:** 5 hours | **Lab:** Lab 06

| Topic | Details |
|-------|---------|
| Merges | inner/left/right/outer, key validation |
| GroupBy | split-apply-combine, `agg`, named aggregations |
| Pivot | `pivot_table`, wide vs long format |
| Sort & rank | `sort_values`, `rank`, top-N per group |

**Learning outcomes:** Build dimensional models from multiple source tables in memory.

---

## Week 4 — External Systems

### Session 7: APIs & Semi-Structured Data
**Duration:** 5 hours | **Lab:** Lab 07

| Topic | Details |
|-------|---------|
| HTTP basics | GET/POST, status codes, headers |
| `requests` | pagination, rate limits, retries |
| JSON | `json.loads`, nested extraction, `json_normalize` |
| Incremental loads | watermarks, `since` parameters |

**Learning outcomes:** Ingest paginated API data into a staging DataFrame.

### Session 8: Databases with Python
**Duration:** 5 hours | **Lab:** Lab 08

| Topic | Details |
|-------|---------|
| SQLAlchemy | engines, connections, `read_sql`, `to_sql` |
| Parameterized SQL | preventing injection, batch inserts |
| Transactions | commit/rollback patterns |
| SQLite → warehouse pattern | local dev mirroring prod |

**Learning outcomes:** Extract from one DB table, transform in Pandas, load to another.

---

## Week 5 — Production Pipeline Patterns

### Session 9: Pipeline Architecture & Orchestration Concepts
**Duration:** 5 hours | **Lab:** Lab 09

| Topic | Details |
|-------|---------|
| ETL vs ELT | when Python runs where |
| Idempotency | upserts, merge keys, overwrite partitions |
| Config | `.env`, YAML, environment-based settings |
| Scheduling concepts | cron, Airflow DAG mental model |
| CLI entry points | `argparse`, `if __name__ == "__main__"` |

**Learning outcomes:** Refactor labs into a multi-step CLI pipeline with config.

### Session 10: Logging, Testing & Data Quality
**Duration:** 5 hours | **Lab:** Lab 10

| Topic | Details |
|-------|---------|
| `logging` module | levels, handlers, structured logs |
| pytest | unit tests for transform functions |
| Fixtures | sample data for reproducible tests |
| Data quality | row counts, null thresholds, schema checks |
| Great Expectations intro | declarative expectations |

**Learning outcomes:** Add tests and quality gates to an existing pipeline.

---

## Week 6 — Scale & Capstone

### Session 11: Cloud Storage & Batch Patterns
**Duration:** 5 hours | **Lab:** Lab 11

| Topic | Details |
|-------|---------|
| Object storage concepts | buckets, prefixes, partitions |
| Parquet | columnar benefits, `pyarrow` |
| Chunked processing | `read_csv(chunksize=)` for large files |
| Local simulation | folder-as-bucket patterns |

**Learning outcomes:** Process partitioned Parquet datasets in batches.

### Session 12: Capstone — End-to-End Pipeline
**Duration:** 5 hours | **Project:** Capstone

| Deliverable | Criteria |
|-------------|----------|
| Multi-source ingest | API + files + database |
| Transforms | cleaning, joins, aggregations |
| Load | analytics-ready Parquet/SQL tables |
| Ops | logging, config, tests, README |

**Learning outcomes:** Present a portfolio-ready mini pipeline.

---

## Weekly Time Breakdown (per 5-hour session)

| Block | Time | Activity |
|-------|------|----------|
| Warm-up & review | 30 min | Quiz recap, Q&A |
| Lecture & demos | 90 min | Slides + live coding |
| Guided practice | 60 min | Instructor-led exercises |
| Lab | 90 min | Independent lab work |
| Wrap-up | 30 min | Solutions walkthrough, homework |

## Recommended Reading

- [Python official tutorial](https://docs.python.org/3/tutorial/) — Sessions 1–2
- [Pandas user guide](https://pandas.pydata.org/docs/user_guide/index.html) — Weeks 2–3
- [Real Python — Data Engineering](https://realpython.com/tutorials/data-engineering/) — supplementary
