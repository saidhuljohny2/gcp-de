"""Lab 08 Solution — Database ETL with SQLAlchemy"""

import pandas as pd
from sqlalchemy import create_engine, text


def run_etl(csv_path: str, db_path: str) -> int:
    engine = create_engine(f"sqlite:///{db_path}")

    raw = pd.read_csv(csv_path, parse_dates=["order_date"])
    raw.to_sql("raw_orders", engine, if_exists="replace", index=False)

    with engine.connect() as conn:
        df = pd.read_sql(
            text("SELECT * FROM raw_orders WHERE status = 'completed'"),
            conn,
        )

    df = df.assign(amount_usd=df["amount"] * df["fx_rate"])
    df.to_sql("analytics_orders", engine, if_exists="replace", index=False)
    return len(df)


if __name__ == "__main__":
    count = run_etl("data/orders.csv", "data/retail.db")
    print(f"Loaded {count} rows to analytics_orders")
