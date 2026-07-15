# Labs

## Structure

| Session | Starter | Solution |
|---------|---------|----------|
| 1 | `starter/lab-01.py` | `solutions/lab-01.py` |
| 2 | `starter/lab-02.py` | `solutions/lab-02.py` |
| ... | ... | ... |
| 12 | `starter/lab-12-capstone.md` | build in `capstone/` |

## Running labs

From project root with venv activated:

```bash
python labs/starter/lab-01.py
python labs/solutions/lab-01.py   # after class
pytest tests/ -v                   # from session 10 onward
```

## Data

Sample files are in `../data/`. Labs write outputs to `data/outbox/` (gitignored).

## Lab 02 setup

```bash
mkdir -p data/inbox data/outbox
cp data/orders.csv data/inbox/orders_a.csv
cp data/orders.csv data/inbox/orders_b.csv
```
