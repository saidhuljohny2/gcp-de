# Python for Data Engineers

A **6-week, 12-session** hands-on course teaching Python through real data engineering workflows — from fundamentals to production-ready pipelines.

## Who This Course Is For

- Aspiring data engineers moving from SQL/ETL tools into Python
- Analytics engineers who need stronger pipeline skills
- Software developers transitioning into data platform work

**Prerequisites:** Basic SQL familiarity, comfort with the command line, no prior Python required.

## Course Structure

| Week | Sessions | Theme |
|------|----------|-------|
| 1 | 1–2 | Python foundations & file I/O |
| 2 | 3–4 | NumPy & Pandas for data work |
| 3 | 5–6 | Cleaning, transforms & aggregations |
| 4 | 7–8 | APIs, JSON & database connectivity |
| 5 | 9–10 | Pipelines, logging & testing |
| 6 | 11–12 | Cloud patterns & capstone project |

**Total:** ~60 hours (5 hours/session × 12 sessions)

## Repository Layout

```
python-for-data-engineers/
├── README.md                 # You are here
├── docs/
│   ├── syllabus.md           # Full curriculum & learning outcomes
│   └── instructor-guide.md   # Teaching notes, timing, assessments
├── modules/                  # Lesson plans (one per session)
├── labs/
│   ├── starter/              # Student starting code
│   └── solutions/            # Reference solutions
├── slides/
│   ├── marp/                 # Marp Markdown decks (source of truth)
│   └── pptx/                 # Generated PowerPoint files
├── data/                     # Sample datasets for labs
├── scripts/
│   └── generate_pptx.py      # Build .pptx from slide content
└── requirements.txt
```

## Quick Start (Instructors)

```bash
cd python-for-data-engineers
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt

# Preview Marp slides (install Marp CLI: npm i -g @marp-team/marp-cli)
marp slides/marp/session-01.md --preview

# Generate all PowerPoint decks
python scripts/generate_pptx.py
```

## Quick Start (Students)

```bash
git clone <repo-url> && cd python-for-data-engineers
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
jupyter lab   # optional, for interactive work
```

Work through `modules/session-XX.md`, follow along with `slides/`, then complete `labs/starter/lab-XX.py`.

## Assessments

| Type | Weight | When |
|------|--------|------|
| Weekly labs (10) | 50% | After sessions 1–10 |
| Quizzes (6) | 20% | End of each week |
| Capstone project | 30% | Week 6 |

See `docs/instructor-guide.md` for rubrics and quiz question banks.

## License

MIT — use freely for internal training and workshops.
