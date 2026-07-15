"""
Lab 09 — Pipeline with Config & CLI

Goal: Refactor ETL into a runnable pipeline package.

Tasks:
1. Read config from config/lab09.yaml (paths for input/output)
2. Implement extract(), transform(), load() functions
3. Add argparse: --run-date optional flag
4. Entry point in run.py
"""

import argparse
from pathlib import Path

import pandas as pd
import yaml

CONFIG_PATH = Path("config/lab09.yaml")


def load_config(path: Path) -> dict:
    # TODO
    raise NotImplementedError


def extract(cfg: dict) -> pd.DataFrame:
    raise NotImplementedError


def transform(df: pd.DataFrame) -> pd.DataFrame:
    raise NotImplementedError


def load(df: pd.DataFrame, cfg: dict) -> None:
    raise NotImplementedError


def main() -> None:
    parser = argparse.ArgumentParser(description="Orders pipeline")
    parser.add_argument("--run-date", help="Optional filter date YYYY-MM-DD")
    args = parser.parse_args()
    # TODO: orchestrate ETL


if __name__ == "__main__":
    main()
