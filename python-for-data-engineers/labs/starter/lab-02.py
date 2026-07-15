"""
Lab 02 — Batch File Processor

Goal: Read all .csv files from data/inbox/, add a source_file column,
      and write combined output to data/outbox/combined.csv

Setup: Run once to create sample inbox files:
  python -c "from pathlib import Path; import shutil; Path('data/inbox').mkdir(exist_ok=True); shutil.copy('data/orders.csv','data/inbox/orders_a.csv')"

Tasks:
1. Use pathlib to list data/inbox/*.csv
2. Read each CSV (csv module or pandas)
3. Add column source_file with the filename
4. Write one combined CSV to data/outbox/combined.csv
"""

from pathlib import Path

INBOX = Path("data/inbox")
OUTBOX = Path("data/outbox")


def combine_csv_files(inbox: Path, out_path: Path) -> int:
    """Combine all CSVs in inbox; return row count."""
    # TODO: implement
    raise NotImplementedError


if __name__ == "__main__":
    OUTBOX.mkdir(parents=True, exist_ok=True)
    rows = combine_csv_files(INBOX, OUTBOX / "combined.csv")
    print(f"Wrote {rows} rows")
