# Session 2 — Control Flow, Functions & File I/O

**Duration:** 5 hours | **Lab:** [Lab 02](../labs/starter/lab-02.py)

## Objectives

- Write functions that encapsulate transform steps
- Read and write files safely with context managers
- Use `pathlib` for portable pipeline paths

## Agenda

1. **Control flow review** (30 min)
2. **Comprehensions** (45 min) — list/dict comprehensions for mapping
3. **Functions** (60 min) — single responsibility per transform
4. **File I/O & CSV** (60 min)
5. **pathlib & batch files** (30 min)
6. **Lab 02** (90 min)

## Key Concepts

### Function Design for Pipelines

Each function should: take data in → return data out → have no hidden side effects (when possible).

```python
def normalize_email(raw: str) -> str:
    return raw.strip().lower()
```

### Context Managers

```python
from pathlib import Path

def read_lines(path: Path) -> list[str]:
    with path.open(encoding="utf-8") as f:
        return [line.strip() for line in f if line.strip()]
```

## Quiz

1. What does `if __name__ == "__main__"` guard?
2. Why use `with open(...)` instead of `open` + `close`?
3. Write a comprehension that keeps only lines containing `"ERROR"`.
4. What is `Path("data") / "orders.csv"` on Windows vs macOS?
5. When should you raise an exception vs return `None`?

## Homework

Extend Lab 02 to support `.json` files in the same input folder.
