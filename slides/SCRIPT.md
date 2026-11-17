# Speaker Script

> Configured by `deck.toml`. Per-slide timings are computed automatically at `wpm` words per minute.

---

## Slide 01 · Title

Good morning everyone. Today I am presenting our reproducible Typst presentation workflow.

---

## Slide 02 · Background: a single-source workflow keeps slides consistent

Most academic talks drift between slides, speaker notes, and paper numbers.

Here, one Typst source produces both the live deck and the handout, while this script compiles into 32 by 9 presenter notes and pdfpc metadata.

---

## Slide 03 · Method: parameterized tokens and measured typography

Every project configures its palette, logos, and timing budget in `deck.toml`.

All measurements live in `data.typ`, and our pipeline delivers 4.2 to 6.8x speedup with `T_stall` and `T_exec` tracked consistently.

---

## Slide 04 · Thank You

Thank you for your attention. I am happy to take any questions.

---

## Appendix · Q&A — likely questions, one-line answers

1. **How do I customize colors and logos?** Edit `[theme]` in `deck.toml` and place your logo files under `slides/assets/brand/`.
2. **How do I enable progressive reveal?** Use `focus-steps(...)` from `core/theme.typ`, which automatically collapses to all-bright in handout mode.
