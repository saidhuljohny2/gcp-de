"""
Lab 10 — Logging, Tests & Data Quality

Goal: Add logging and pytest tests to the transform from Lab 09.

Tasks:
1. Add logging to transform steps
2. Create tests/test_transform.py with 3+ tests
3. Implement validate_orders(df) that checks:
   - at least 1 row
   - no null order_id
   - amount_usd >= 0
"""

import logging
import pandas as pd

logger = logging.getLogger(__name__)


def transform(df: pd.DataFrame) -> pd.DataFrame:
    # TODO: add logging
    raise NotImplementedError


def validate_orders(df: pd.DataFrame) -> None:
    # TODO
    raise NotImplementedError
