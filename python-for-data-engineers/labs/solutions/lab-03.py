"""Lab 03 Solution — Sensor Metrics with NumPy"""

import pandas as pd

DATA_PATH = "data/sensor_readings.csv"


def sensor_stats(df: pd.DataFrame) -> pd.DataFrame:
    return (
        df.groupby("sensor_id", as_index=False)["temperature_c"]
        .agg(mean_temp="mean", min_temp="min", max_temp="max")
        .round(2)
    )


if __name__ == "__main__":
    df = pd.read_csv(DATA_PATH)
    print(sensor_stats(df))
