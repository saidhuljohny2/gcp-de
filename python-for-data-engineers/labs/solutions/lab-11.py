"""Lab 11 Solution — Partitioned Parquet Lake"""

from pathlib import Path

import pandas as pd


def write_partitioned(df: pd.DataFrame, base_path: Path) -> None:
    base_path.mkdir(parents=True, exist_ok=True)
    df = df.copy()
    df["order_date"] = df["order_date"].dt.strftime("%Y-%m-%d")
    for date, group in df.groupby("order_date"):
        part_dir = base_path / f"dt={date}"
        part_dir.mkdir(parents=True, exist_ok=True)
        group.to_parquet(part_dir / "data.parquet", index=False)


def read_partition(base_path: Path, date: str) -> pd.DataFrame:
    return pd.read_parquet(base_path / f"dt={date}" / "data.parquet")


if __name__ == "__main__":
    df = pd.read_csv("data/orders.csv", parse_dates=["order_date"])
    lake = Path("data/lake/orders")
    write_partitioned(df, lake)
    part = read_partition(lake, "2024-01-05")
    print(f"Partition 2024-01-05: {len(part)} rows")
