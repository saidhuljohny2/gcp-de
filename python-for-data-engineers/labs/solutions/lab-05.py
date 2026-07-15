"""Lab 05 Solution — Data Cleaning Pipeline"""

import json
from pathlib import Path

import pandas as pd


def clean_orders(df: pd.DataFrame) -> pd.DataFrame:
    return df.drop_duplicates(subset=["order_id"]).assign(
        product_id=df["product_id"].fillna("UNKNOWN")
    )


def clean_customers(path: Path) -> pd.DataFrame:
    records = json.loads(path.read_text(encoding="utf-8"))
    df = pd.DataFrame(records)
    return df.assign(
        name=df["name"].str.strip(),
        email=df["email"].str.strip().str.lower(),
    )


if __name__ == "__main__":
    orders = clean_orders(pd.read_csv("data/orders.csv"))
    customers = clean_customers(Path("data/customers.json"))
    print(orders.head())
    print(customers.head())
