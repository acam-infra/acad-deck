---
name: typst-deck
description: >-
  Runbooks for an acad-deck Typst + Touying presentation: orient in a deck
  repo, edit slides, sync SCRIPT.md and WPM timings, add or remove slides,
  customize deck.toml colour/font tokens, extract paper figures or draw CeTZ
  diagrams, use focus-steps overlays safely, read build gates, and launch the
  offline pdfpc-ts presenter console.
---

# typst-deck — Runbooks

Configuration lives in `deck.toml`, style & contrast rules in `STYLE.md`, slides in `slides/main.typ` (plus `slides/backup.typ`), measurements in `slides/data.typ`, and spoken script in `slides/SCRIPT.md`.

## 0. Orient

```bash
./setup.sh --check                           # verify typst, poppler, pymupdf, fonts
grep -n '^#slide(title:' slides/main.typ     # slide -> line map
make                                         # build all PDFs + QA PNGs + run gates
make check                                   # check SCRIPT.md clock, concepts, deixis, jargon
```

Page numbering: `qa/s-NN.png` and gate messages use **1-indexed PDF page numbers** (title = `01`); the footer slide counter skips `title-slide` and `thank-you-slide`.

## 1. Edit a Slide

1. Locate the `#slide(title: [Section: claim])[...]` block in `slides/main.typ`. Keep headings to `Section: claim`, sentence case, ≤ 8 words, **one line**.
2. Use `core/theme.typ` components:
   - `bullet([head], [tail])` (`tail` may be `none`)
   - `card([head], [body], fill: GFILL, edge: ...)`
   - `tile([value], [label], fill: GDARK)`
   - `strap([...])` (optional bottom argument bar)
   - `focus-steps(( (head: [...], tail: [...]), ... ))` (progressive highlight that collapses cleanly in `--input handout=1`)
3. Put every measurement in `slides/data.typ` and reference `#D.<field>` or `#fmt2(...)` — never hard-code numbers inside slides.
4. **MiTeX font leak:** text immediately following `#mi(...)` inherits the math serif font; wrap it in `#text(font: SANS)[...]`.
5. Update the matching `## Slide NN · <title>` section in `slides/SCRIPT.md` in the same commit.
6. Run `make` and visually inspect `qa/s-NN.png` for every touched page.

## 2. Edit the Script & Clock (`slides/SCRIPT.md`)

- **Do not write clocks into headings.** `core/tools/build_notes.py` and `check_script.py` compute per-slide seconds and running totals automatically from word count at `[script].wpm` in `deck.toml`.
- Keep each slide section headed as `## Slide NN · <Title>` (optionally `· checkpoint ①`).
- Stage directions wrapped wholly in `*(...)*` are shown on the presenter card (`notes.pdf`) and skipped by `tts_narrate.py`.
- After editing `slides/SCRIPT.md`, run:
  - `make check` — verifies total duration ≤ `[script].duration_minutes`, concept introduction order (`[script.introduced]`), zero figure deixis (`[script.deixis]`), spoken pronunciation for snake_case identifiers (`[script.spoken]`), and no em/en dash asides.
  - `make` — rebuilds `render/<name>-talk-notes.pdf`, `render/<name>-script.pdf`, and `.pdfpc`. Check the presenter card visually if a slide's prose is long (auto-scales down to 13pt).

## 3. Add or Remove a Slide

1. Add/remove the `#slide(title: [Section: claim])[...]` block in `slides/main.typ`.
2. Update `pages_main` and `pages_handout` in `deck.toml [build]` (the page-count gate is exact).
3. Add/remove the corresponding `## Slide NN · <Title>` section in `slides/SCRIPT.md` and re-verify slide indices in `deck.toml [script.introduced]` and `[gates].exempt_pages`.
4. Run `make && make check`.

## 4. Customize Tokens & Logos (`deck.toml`)

- Edit `[deck]` for title, subtitle, author, presenter, institution, venue, date, and footer strings.
- Edit `[theme]` for palette hex tokens and fonts (`sans_font`, `mono_font`, `cjk_font`). Keep dark/light contrast ≥ 4.5:1 (`STYLE.md` §1) and keep `teal` (dark-ground strokes/ticks) separate from `teal_deep` (light-ground text).
- Set `logo_institution` and `logo_venue` relative to the repo root (e.g. `"slides/assets/brand/inst.png"`), or leave `""` to omit.
- Inside dark blocks (`DEEP` / `GDARK`), override `*bold*` (`show strong: it => text(fill: white, weight: "bold", it.body)`) so bold text does not inherit `DEEP` and disappear.

## 5. Figures (Paper SVGs & CeTZ)

Preference order:
1. **Paper vector SVG**: put source PDFs in the repo, register `name = "path/to/fig.pdf"` under `deck.toml [figures]`, run `make` (`extract_paper_figs.py` crops to the ink bounding box with `text_as_path=True`), and place `image("assets/paper/<name>.svg", width: ...)`.
2. **Native CeTZ**: add drawing functions in `slides/figures.typ` using `core/theme.typ` tokens and `slides/data.typ`.
3. **Raster images**: must resolve to ≥ 150 PPI at placed size (`[gates].ppi_floor`).

## 6. Overlays (`focus-steps`)

- Never use Touying `only(...)` (causes layout jumps and drops content in handout mode) or raw `alternatives(...)` (collapses handout to the final dim-all-but-last frame).
- Always use `focus-steps(...)` from `core/theme.typ`, which branches on `HANDOUT` (`--input handout=1`) so the handout renders all items at full contrast on a single page.
- Update `pages_main` in `deck.toml [build]` to match the physical page count with overlays, while keeping `pages_handout` equal to the logical slide count.

## 7. Read Gates, Narrate & Present

| Gate | Meaning | Fix |
|---|---|---|
| `compiled with typst warnings` | Overflow, missing font, or layout warning | Fix the warning; never ignore it |
| `has N pages, expected M` | Slide overflowed or `deck.toml [build]` stale | Trim content or update `pages_main`/`pages_handout` |
| `heading must be one line` | Title wrapped in the 58pt header bar | Shorten the claim; do not shrink the font |
| `mid-slide hole` / `sparse slide` | Blank band > `gap_ceil` or inked rows < `cover_floor` | Distribute air with `#v(1fr)` or add substantive content |
| `bottom dead zone` | Ink stops above `ink_floor` (88%) | Add `#strap(...)` or set `soft_bottom_dead_zone = true` in `deck.toml` |
| `bitmap ... resolves to N PPI` | Raster too low-res at placed size | Use vector SVG or higher-res source |

- **Narrate**: `make narrate` calls `core/tools/tts_narrate.py --join` (incremental sha256 cache per slide; requires `GROK2API_API_KEY`).
- **Present**: `make present` launches local offline `pdfpc-ts` (`ARGS="--deck"` for 16:9 only, `ARGS="--watch"` for auto-reload on rebuild, `ARGS="--chrome"` on Linux/non-Safari).
