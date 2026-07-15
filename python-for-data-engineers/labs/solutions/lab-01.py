"""Lab 01 Solution — Parse Pipeline Logs"""

from pathlib import Path

LOG_PATH = Path("data/pipeline.log")
LEVELS = {"INFO", "WARN", "ERROR"}


def parse_log_line(line: str) -> tuple[str, str, str]:
    parts = line.split()
    timestamp = " ".join(parts[:2])
    level = parts[2]
    message = " ".join(parts[3:])
    return timestamp, level, message


def count_levels(lines: list[str]) -> dict[str, int]:
    counts: dict[str, int] = {lvl: 0 for lvl in LEVELS}
    for line in lines:
        if not line.strip():
            continue
        _, level, _ = parse_log_line(line)
        if level in counts:
            counts[level] += 1
    return counts


if __name__ == "__main__":
    lines = LOG_PATH.read_text(encoding="utf-8").splitlines()
    print(count_levels(lines))
