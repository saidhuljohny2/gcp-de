# Session 9 — Pipeline Architecture & Orchestration Concepts

**Duration:** 5 hours | **Lab:** [Lab 09](../labs/starter/lab-09.py)

## Objectives

- Structure code into extract / transform / load modules
- Externalize configuration
- Build CLI entry points for schedulers

## Agenda

1. **ETL vs ELT** (30 min)
2. **Project layout** (45 min)
3. **Config patterns** (45 min)
4. **argparse CLI** (45 min)
5. **Idempotency** (30 min)
6. **Lab 09** (90 min)

## Recommended Layout

```
pipeline/
  __init__.py
  config.py
  extract.py
  transform.py
  load.py
  run.py
```

## Quiz

1. What makes a job idempotent?
2. Where should secrets live?
3. How would Airflow call your pipeline?
4. ELT advantage in cloud warehouses?
5. Partition overwrite vs merge?

## Homework

Add `--dry-run` flag that logs actions without writing.
