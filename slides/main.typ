// acad-deck example main presentation (4 slides)
#import "@preview/touying:0.7.4": *
#import "@preview/mitex:0.2.7": mi
#import "../core/theme.typ": *
#import "figures.typ": *
#import "data.typ" as D

#let cfg = toml("../deck.toml")
#let d = cfg.deck

#show: acad-theme.with(
  config-info(
    title: [#d.title],
    subtitle: [#d.subtitle],
    author: [#d.author],
    institution: [#d.institution],
    date: [#d.date],
  ),
  config-common(
    handout: HANDOUT,
  ),
)

#let T-stall = mi(`T_{\mathrm{stall}}`)
#let T-exec = mi(`T_{\mathrm{exec}}`)

// ============================================================ 01 · Title
#title-slide()

// ============================================================ 02 · Background
#slide(title: [Background: a single-source workflow keeps slides consistent])[
  #v(1fr)
  #grid(
    columns: (1fr, 340pt),
    column-gutter: 24pt,
    align: horizon,
    [
      #bullet(
        [Typst + Touying source of truth],
        [One `.typ` file defines the deck; `--input handout=1` produces the printable handout],
      )
      #v(16pt)
      #bullet(
        [Decoupled speaker script],
        [Spoken text lives in `SCRIPT.md` and compiles into 32:9 presenter notes and `.pdfpc`],
      )
      #v(16pt)
      #bullet(
        [Automated layout gates],
        [Every build checks warnings, page counts, bitmap PPI, fill density, and one-line headings],
      )
    ],
    figure(
      fig-example-pipeline(unit: 0.62cm),
      caption: [Declarative build pipeline from source to verified PDFs],
    ),
  )
  #v(1fr)
  #strap([One Typst source drives slides, handout, presenter notes, and layout gates.])
]

// ============================================================ 03 · Method
#slide(title: [Method: parameterized tokens and measured typography])[
  #v(1fr)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 22pt,
    align: top,
    card(
      [Contrast-checked palette],
      [Tokens in `deck.toml` separate dark-ground strokes (`TEAL`) from light-ground text (`TEAL-DEEP`) and enforce `4.5:1` legibility.],
      fill: ACCENT-LT,
      edge: ACCENT,
      stroke-w: 1.2pt,
    ),
    card(
      [Single-source numbers (`data.typ`)],
      [Measurements like #hot[#D.speedup-range] (#fmt2(D.baseline-latency) s to #fmt2(D.ours-latency) s) and #T-stall + #T-exec #text(font: SANS)[live in `data.typ`.]],
    ),
  )
  #v(16pt)
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 20pt,
    tile([#fmt2(D.baseline-latency) s], [Baseline latency]),
    tile([#fmt2(D.ours-latency) s], [Optimized latency], fill: ACCENT),
    tile([#D.speedup-range], [Measured speedup], fill: DEEP),
  )
  #v(1fr)
  #strap([Separate content, data, and style so every talk builds reproducibly from day one.])
]

// ============================================================ 04 · Closing
#thank-you-slide()
