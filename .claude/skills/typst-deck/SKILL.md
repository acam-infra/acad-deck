---
name: typst-deck
description: >-
  Runbooks for an acad-deck Typst + Touying presentation: edit slides, sync
  SCRIPT.md, add/remove slides, customize deck.toml tokens, extract paper
  figures, run visual/script gates, and launch pdfpc-ts.
---

# typst-deck — Runbooks

Configuration lives in `deck.toml`, style rules in `STYLE.md`, slides in `slides/main.typ`, and spoken script in `slides/SCRIPT.md`.

## 1. Edit a Slide

1. Edit `slides/main.typ` using `bullet([head], [tail])`, `card([head], [body])`, `tile(val, label)`, `strap([...])`, or `focus-steps(...)` from `core/theme.typ`.
2. Put all numbers in `slides/data.typ` (`#D.<field>` or `fmt2(...)`).
3. Wrap text after `#mi(...)` in `#text(font: SANS)[...]` to avoid serif leakage.
4. Update the matching `## Slide NN · <title>` section in `slides/SCRIPT.md`.
5. Run `make` and inspect `qa/s-NN.png` for the pages you touched.

## 2. Add or Remove a Slide

1. Add/remove the `#slide(title: [Section: claim])[...]` block in `slides/main.typ`.
2. Update `pages_main` and `pages_handout` in `deck.toml [build]`.
3. Add/remove the corresponding `## Slide NN · ...` section in `slides/SCRIPT.md` and update `deck.toml [script.introduced]` if concept order shifted.
4. Run `make` and `make check`.

## 3. Extract Paper Figures

1. Add `name = "path/to/figure.pdf"` under `[figures]` in `deck.toml`.
2. Run `make` — `extract_paper_figs.py` crops to the ink bounding box and writes `slides/assets/paper/<name>.svg`.
3. Place with `image("assets/paper/<name>.svg", width: ...)`.

## 4. Check Script & Present

- `make check` — checks total WPM clock, concept introduction order (`[script.introduced]`), figure deixis, spoken jargon (`[script.spoken]`), and dash asides.
- `make present` — opens 32:9 notes view in local offline `pdfpc-ts`. Pass `ARGS="--deck --watch"` for 16:9 auto-reload while editing.
