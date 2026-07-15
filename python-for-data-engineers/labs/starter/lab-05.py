"""
Lab 05 — Data Cleaning Pipeline

Goal: Clean messy orders and customers data.

Tasks:
1. Load orders.csv — drop duplicate order_id, fill missing product_id with 'UNKNOWN'
2. Load customers.json — normalize email (lower, strip), trim name
3. Return cleaned DataFrames from pure functions clean_orders, clean_customers
"""

import json
from pathlib import Path

import pandas as pd

ORDERS_PATH = "data/orders.csv"
CUSTOMERS_PATH = "data/customers.json"


def clean_orders(df: pd.DataFrame) -> pd.DataFrame:
  # TODO
  raise NotImplementedError


def clean_customers(path: Path) -> pd.DataFrame:
  # TODO
  raise NotImplementedError


if __name__ == "__main__":
    orders = clean_orders(pd.read_csv(ORDERS_PATH))
    customers = clean_customers(Path(CUSTOMERS_PATH))
    print(orders.head())
    print(customers.head())
