# Slides

## Marp (source)

Edit decks in `marp/session-XX.md`. Preview:

```bash
npm install -g @marp-team/marp-cli
marp slides/marp/session-01.md --preview
```

Export to PDF for student handouts:

```bash
marp slides/marp/session-01.md -o slides/pdf/session-01.pdf
```

## PowerPoint

Generated files live in `pptx/`. Rebuild after editing Marp sources:

```bash
python scripts/generate_pptx.py
```

Single session:

```bash
python scripts/generate_pptx.py --session 4
```

## Visual elements in Marp

- **Mermaid diagrams** render in Marp preview (flowcharts for ETL, merges, lake layout)
- **Code blocks** use dark theme in exported PPTX
- Consistent header/footer per session
