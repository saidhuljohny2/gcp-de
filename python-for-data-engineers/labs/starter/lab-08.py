"""
Lab 08 — Database ETL with SQLAlchemy

Goal: Extract orders from SQLite, transform, load to analytics table.

Tasks:
1. Create SQLite DB at data/retail.db with raw_orders from orders.csv
2. SQL extract: completed orders only
3. Transform: add amount_usd
4. Load to table analytics_orders (replace)
"""

from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, text

DB_PATH = "data/retail.db"


def run_etl(csv_path: str, db_path: str) -> int:
    # TODO
    raise NotImplementedError


if __name__ == "__main__":
    count = run_etl("data/orders.csv", DB_PATH)
    print(f"Loaded {count} rows to analytics_orders")
