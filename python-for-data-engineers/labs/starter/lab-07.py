"""
Lab 07 — Mock API Pagination

Goal: Simulate paginated API ingestion from local JSON files.

Files: data/api_products_page1.json, data/api_products_page2.json

Tasks:
1. Loop pages 1..N until page > total_pages
2. Collect all products into one DataFrame
3. Save to data/outbox/api_products.parquet

Hint: construct path as f"data/api_products_page{page}.json"
"""

from pathlib import Path

import pandas as pd


def fetch_all_products(data_dir: Path) -> pd.DataFrame:
    # TODO: pagination loop
    raise NotImplementedError


if __name__ == "__main__":
    df = fetch_all_products(Path("data"))
    out = Path("data/outbox/api_products.parquet")
    out.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(out, index=False)
    print(df)
