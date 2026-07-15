"""Lab 09 Solution — Pipeline with Config & CLI"""

import argparse
from pathlib import Path

import pandas as pd
import yaml

CONFIG_PATH = Path("config/lab09.yaml")


def load_config(path: Path) -> dict:
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def extract(cfg: dict, run_date: str | None) -> pd.DataFrame:
    df = pd.read_csv(cfg["input_path"], parse_dates=["order_date"])
    if run_date:
        df = df.loc[df["order_date"] == run_date]
    return df


def transform(df: pd.DataFrame) -> pd.DataFrame:
    return (
        df.drop_duplicates(subset=["order_id"])
        .assign(amount_usd=df["amount"] * df["fx_rate"])
        .loc[df["status"] == "completed"]
    )


def load(df: pd.DataFrame, cfg: dict) -> None:
    out = Path(cfg["output_path"])
    out.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(out, index=False)


def main() -> None:
    parser = argparse.ArgumentParser(description="Orders pipeline")
    parser.add_argument("--run-date", help="Optional filter date YYYY-MM-DD")
    args = parser.parse_args()

    cfg = load_config(CONFIG_PATH)
    raw = extract(cfg, args.run_date)
    clean = transform(raw)
    load(clean, cfg)
    print(f"Pipeline complete: {len(clean)} rows")


if __name__ == "__main__":
    main()
