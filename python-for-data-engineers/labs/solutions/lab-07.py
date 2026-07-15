"""Lab 07 Solution — Mock API Pagination"""

import json
from pathlib import Path

import pandas as pd


def fetch_all_products(data_dir: Path) -> pd.DataFrame:
    page = 1
    frames: list[pd.DataFrame] = []
    total_pages = 1

    while page <= total_pages:
        path = data_dir / f"api_products_page{page}.json"
        payload = json.loads(path.read_text(encoding="utf-8"))
        total_pages = payload["total_pages"]
        frames.append(pd.DataFrame(payload["products"]))
        page += 1

    return pd.concat(frames, ignore_index=True)


if __name__ == "__main__":
    df = fetch_all_products(Path("data"))
    out = Path("data/outbox/api_products.parquet")
    out.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(out, index=False)
    print(df)
