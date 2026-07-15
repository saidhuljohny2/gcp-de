"""
Lab 01 — Parse Pipeline Logs

Goal: Read data/pipeline.log and produce a summary of log levels.

Tasks:
1. Read all lines from data/pipeline.log
2. Parse each line into: timestamp, level, message
3. Count occurrences of INFO, WARN, ERROR
4. Print the counts as a dict

Example output:
{'INFO': 5, 'WARN': 1, 'ERROR': 3}
"""

LOG_PATH = "data/pipeline.log"


def parse_log_line(line: str) -> tuple[str, str, str]:
    """Return (timestamp, level, message) from a log line."""
    # TODO: implement
    raise NotImplementedError


def count_levels(lines: list[str]) -> dict[str, int]:
    """Count log levels across all lines."""
    # TODO: implement
    raise NotImplementedError


if __name__ == "__main__":
  pass  # TODO: wire up and print results
