"""Lab 10 Solution — Logging, Tests & Data Quality"""

import logging

import pandas as pd

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def transform(df: pd.DataFrame) -> pd.DataFrame:
    logger.info("Starting transform on %s rows", len(df))
    result = (
        df.drop_duplicates(subset=["order_id"])
        .assign(amount_usd=df["amount"] * df["fx_rate"])
        .loc[df["status"] == "completed"]
    )
    logger.info("Transform complete: %s rows", len(result))
    return result


def validate_orders(df: pd.DataFrame) -> None:
    if len(df) < 1:
        raise ValueError("Expected at least 1 row")
    if df["order_id"].isna().any():
        raise ValueError("Null order_id found")
    if (df["amount_usd"] < 0).any():
        raise ValueError("Negative amount_usd found")
