"""
Lab 11 — Partitioned Parquet Lake

Goal: Write orders partitioned by date, then read back one partition.

Tasks:
1. Load orders.csv
2. Write to data/lake/orders/ partitioned by order_date (directory per date)
3. Read back one partition and print row count
"""

from pathlib import Path

import pandas as pd

ORDERS_PATH = "data/orders.csv"
LAKE_PATH = Path("data/lake/orders")


def write_partitioned(df: pd.DataFrame, base_path: Path) -> None:
    # TODO: use df.to_parquet with partition_cols or manual loops
    raise NotImplementedError


def read_partition(base_path: Path, date: str) -> pd.DataFrame:
    # TODO
    raise NotImplementedError


if __name__ == "__main__":
    df = pd.read_csv(ORDERS_PATH, parse_dates=["order_date"])
    write_partitioned(df, LAKE_PATH)
    part = read_partition(LAKE_PATH, "2024-01-05")
    print(f"Partition 2024-01-05: {len(part)} rows")
