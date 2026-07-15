"""Lab 04 Solution — Orders ETL with Pandas"""

from pathlib import Path

import pandas as pd

ORDERS_PATH = "data/orders.csv"
OUTPUT_PATH = Path("data/outbox/completed_orders.parquet")


def transform_orders(path: str) -> pd.DataFrame:
    df = pd.read_csv(path, parse_dates=["order_date"])
    return (
        df.assign(amount_usd=df["amount"] * df["fx_rate"])
        .loc[df["status"] == "completed", ["order_id", "customer_id", "product_id", "order_date", "amount_usd"]]
    )


if __name__ == "__main__":
    result = transform_orders(ORDERS_PATH)
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    result.to_parquet(OUTPUT_PATH, index=False)
    print(f"Wrote {len(result)} rows to {OUTPUT_PATH}")
