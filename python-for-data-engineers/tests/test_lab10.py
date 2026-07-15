"""Tests for Lab 10 transform and validation."""

import pandas as pd
import pytest

def _transform(df: pd.DataFrame) -> pd.DataFrame:
    return (
        df.drop_duplicates(subset=["order_id"])
        .assign(amount_usd=df["amount"] * df["fx_rate"])
        .loc[df["status"] == "completed"]
    )


def _validate(df: pd.DataFrame) -> None:
    if len(df) < 1:
        raise ValueError("Expected at least 1 row")
    if df["order_id"].isna().any():
        raise ValueError("Null order_id found")
    if (df["amount_usd"] < 0).any():
        raise ValueError("Negative amount_usd found")


@pytest.fixture
def sample_orders() -> pd.DataFrame:
    return pd.DataFrame(
        {
            "order_id": [1, 2, 2],
            "amount": [10.0, 20.0, 20.0],
            "fx_rate": [1.0, 1.0, 1.0],
            "status": ["completed", "completed", "cancelled"],
        }
    )


def test_transform_dedupes_and_filters(sample_orders: pd.DataFrame) -> None:
    result = _transform(sample_orders)
    assert len(result) == 1
    assert result.iloc[0]["order_id"] == 1


def test_transform_computes_amount_usd(sample_orders: pd.DataFrame) -> None:
    result = _transform(sample_orders)
    assert result.iloc[0]["amount_usd"] == 10.0


def test_validate_rejects_empty() -> None:
    with pytest.raises(ValueError, match="at least 1 row"):
        _validate(pd.DataFrame({"order_id": [], "amount_usd": []}))
