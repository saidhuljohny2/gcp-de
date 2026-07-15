"""
Lab 03 — Sensor Metrics with NumPy

Goal: Load data/sensor_readings.csv and compute per-sensor stats.

Tasks:
1. Load temperature_c column per sensor_id using pandas or csv + numpy
2. Ignore NaN values
3. For each sensor: mean, min, max temperature
4. Print results as a formatted table
"""

import numpy as np
import pandas as pd

DATA_PATH = "data/sensor_readings.csv"


def sensor_stats(df: pd.DataFrame) -> pd.DataFrame:
    """Return DataFrame with sensor_id, mean_temp, min_temp, max_temp."""
    # TODO: implement using groupby or numpy per group
    raise NotImplementedError


if __name__ == "__main__":
    df = pd.read_csv(DATA_PATH)
    print(sensor_stats(df))
