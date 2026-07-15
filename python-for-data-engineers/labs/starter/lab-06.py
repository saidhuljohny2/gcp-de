"""
Lab 06 — Joins & Aggregations

Goal: Build a daily revenue report joined with customer country.

Tasks:
1. Clean orders (reuse patterns from lab 05)
2. Load customers.json
3. Inner join on customer_id
4. Group by order_date + country: sum revenue, count orders
5. Save to data/outbox/daily_revenue_by_country.csv
"""

import pandas as pd


def build_daily_revenue(orders: pd.DataFrame, customers: pd.DataFrame) -> pd.DataFrame:
    # TODO
    raise NotImplementedError


if __name__ == "__main__":
    pass
