"""Lab 02 Solution — Batch File Processor"""

import csv
from pathlib import Path

INBOX = Path("data/inbox")
OUTBOX = Path("data/outbox")


def combine_csv_files(inbox: Path, out_path: Path) -> int:
    rows: list[dict] = []
    fieldnames: list[str] | None = None

    for path in sorted(inbox.glob("*.csv")):
        with path.open(newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            if fieldnames is None:
                fieldnames = reader.fieldnames or []
                fieldnames = [*fieldnames, "source_file"]
            for row in reader:
                row["source_file"] = path.name
                rows.append(row)

    if not rows or fieldnames is None:
        out_path.write_text("", encoding="utf-8")
        return 0

    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    return len(rows)


if __name__ == "__main__":
    OUTBOX.mkdir(parents=True, exist_ok=True)
    rows = combine_csv_files(INBOX, OUTBOX / "combined.csv")
    print(f"Wrote {rows} rows")
