"""Lab 06 Solution — Joins & Aggregations"""

import json
from pathlib import Path

import pandas as pd


def build_daily_revenue(orders: pd.DataFrame, customers: pd.DataFrame) -> pd.DataFrame:
    orders = orders.drop_duplicates(subset=["order_id"]).assign(
        amount_usd=orders["amount"] * orders["fx_rate"]
    )
    orders = orders.loc[orders["status"] == "completed"]
    enriched = orders.merge(customers[["customer_id", "country"]], on="customer_id", how="inner")
    return (
        enriched.groupby(["order_date", "country"], as_index=False)
        .agg(revenue=("amount_usd", "sum"), order_count=("order_id", "nunique"))
        .sort_values(["order_date", "country"])
    )


if __name__ == "__main__":
    orders = pd.read_csv("data/orders.csv", parse_dates=["order_date"])
    customers = pd.DataFrame(json.loads(Path("data/customers.json").read_text()))
    report = build_daily_revenue(orders, customers)
    out = Path("data/outbox/daily_revenue_by_country.csv")
    out.parent.mkdir(parents=True, exist_ok=True)
    report.to_csv(out, index=False)
    print(report)
