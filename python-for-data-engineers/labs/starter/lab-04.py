"""
Lab 04 — Orders ETL with Pandas

Goal: Load orders, compute amount_usd, filter completed orders.

Tasks:
1. Read data/orders.csv with parsed order_date
2. Add amount_usd = amount * fx_rate
3. Keep only status == 'completed'
4. Write result to data/outbox/completed_orders.parquet
"""

import pandas as pd

ORDERS_PATH = "data/orders.csv"
OUTPUT_PATH = "data/outbox/completed_orders.parquet"


def transform_orders(path: str) -> pd.DataFrame:
    # TODO: implement
    raise NotImplementedError


if __name__ == "__main__":
    result = transform_orders(ORDERS_PATH)
    result.to_parquet(OUTPUT_PATH, index=False)
    print(f"Wrote {len(result)} rows to {OUTPUT_PATH}")
