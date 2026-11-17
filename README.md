# acad-deck

A reproducible, venue-agnostic **Typst + Touying** academic presentation template with automated layout gates, 32:9 dual-screen speaker notes, `pdfpc-ts` offline presenter console, paper figure SVG extraction, and optional TTS narration.

Extracted and generalized from [`chocolatedesue/netloom-presentations`](https://github.com/chocolatedesue/netloom-presentations).

## Quick Start

```bash
./setup.sh --check   # verify typst, poppler-utils, pymupdf, and fonts
make                 # build deck, handout, backup, notes, script, pdfpc + run gates
make check           # check SCRIPT.md timing, concept order, deixis, jargon, dashes
make present         # open 32:9 presenter view in pdfpc-ts (ARGS=--deck | --watch)
```

## Layout

```text
acad-deck/
├── deck.toml                  # Single configuration file (metadata, theme, gates, script, figures)
├── Makefile & setup.sh        # Unified build entry and dependency installer
├── STYLE.md                   # Contrast, typography, layout, and figure rules
├── core/
│   ├── theme.typ              # Parameterized Touying theme + components (bullet/card/tile/strap/focus-steps)
│   ├── build.sh               # Strict compile (0 warnings, exact page counts) + QA PNGs + gates
│   ├── present.sh             # Local offline pdfpc-ts launcher (Safari/Chrome, --watch hot reload)
│   └── tools/
│       ├── config_loader.py   # deck.toml loader
│       ├── check_talk.py      # Gates: speaker notes, bitmap >= 150 PPI, ink fill, 1-line headings
│       ├── build_notes.py     # SCRIPT.md -> 32:9 notes PDF, A4 script PDF, .pdfpc
│       ├── check_script.py    # Script lint: WPM clock, concept order, deixis, jargon, dashes
│       ├── extract_paper_figs.py # Paper PDFs -> ink-cropped vector SVGs (text as paths)
│       └── tts_narrate.py     # Incremental parallel TTS narration via Grok2API
└── slides/
    ├── main.typ               # Main presentation slides (single source of truth)
    ├── backup.typ             # Q&A backup slides
    ├── data.typ               # Single source of truth for every measurement
    ├── figures.typ            # Native CeTZ diagrams
    ├── SCRIPT.md              # Spoken script, checkpoints, and Q&A
    └── assets/                # brand/ logos and paper/ extracted SVGs
```

## Customizing for a New Talk

1. Edit `deck.toml`: set `[deck]` metadata, `[theme]` colors/logos, `[build]` page counts, `[script]` duration/WPM/glossary, and `[figures]` paper PDF mappings.
2. Put measurements in `slides/data.typ` and slides in `slides/main.typ`.
3. Write speaker text in `slides/SCRIPT.md` using `## Slide NN · <Title>` headings.
4. Run `make` and inspect `qa/s-*.png` after every edit.
