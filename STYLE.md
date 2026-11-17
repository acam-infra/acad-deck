# acad-deck — Style & Quality Gates

## 0. Core Stance

1. **One sentence per slide.** The slide carries the claim; `slides/SCRIPT.md` carries the prose.
2. **Heading format: `Section: claim`.** Sentence case, target ≤ 8 words, MUST fit on one line (`[gate]`).
3. **2–3 points per page.** Count everything the eye stops at (bullets, cards, labelled arrows).
4. **Never dim text to show state** unless using `focus-steps()` where `DIM` is contrast-checked.
5. **Single source of truth for numbers.** Every measurement lives in `slides/data.typ` with its paper/source reference.

## 1. Colour & Contrast Floor

```text
brightness = (299R + 587G + 114B) / 1000        # 0-255
contrast   = (L_lighter + 0.05) / (L_darker + 0.05)
```

- Dark fills (`< 30%` brightness) MUST take light text (`>= 80%` brightness).
- Light fills (`>= 80%` brightness) MUST take dark text (`< 20%` brightness).
- Body text MUST clear **4.5:1**; large emphasis (17pt+) SHOULD clear **5:1**.
- **Two faces for bright accents:** `TEAL` (`#14B8A6`) is for dark-ground strokes and the header tick only; `TEAL-DEEP` (`#0F766E`) is for teal text on light grounds.
- **One accent:** `ACCENT` (`#0E7490`) marks the paper's own contribution/system. `BAD` (`#B91C1C`) is the one red; `GOOD` (`TEAL-DEEP`) is the one green.

## 2. Typography & Layout

- Canvas: **960 × 540pt** (16:9), margins `x: 46pt, top: 96pt, bottom: 46pt`, 58pt header bar.
- Body scale: `BODY-HEAD` = **15pt bold `INK`**, `BODY-TEXT` = **13.5pt regular `INK`** (never grey tails).
- Headings: **19pt bold `DEEP`**, one line (`[gate]`). Fix wraps by cutting words, not shrinking the font.
- Place vertical air with `#v(1fr)`, not magic pixel gaps.
- **MiTeX font leak:** text after `#mi(...)` inherits the math serif — wrap following text in `#text(font: SANS)[...]`.

## 3. Figures

Preference order:
1. **Paper figure as cropped vector SVG** via `extract_paper_figs.py` (`text_as_path=True`).
2. **Native CeTZ** in `slides/figures.typ` using theme tokens and `data.typ`.
3. **High-DPI rasters** only when vector is unavailable (MUST resolve to `>= 150 PPI` at placed size `[gate]`).

## 4. Automated Gates (`core/build.sh` → `core/tools/check_talk.py`)

1. **Zero Typst warnings** (hard fail).
2. **Exact page counts** matching `deck.toml [build]` (`pages_main`, `pages_handout`, `pages_backup`).
3. **Speaker notes completeness** (every slide in `.pdfpc` has a non-empty note).
4. **Bitmap PPI `>= 150`** at placed size.
5. **Fill density:** largest blank band `<= 28%` (`gap_ceil`), inked content rows `>= 33%` (`cover_floor`), bottom reach `>= 88%` (`ink_floor`, configurable as soft warning via `soft_bottom_dead_zone`).
6. **One-line headings** on every content slide.
