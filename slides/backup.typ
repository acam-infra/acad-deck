// acad-deck example backup slides (2 slides)
#import "@preview/touying:0.7.4": *
#import "../core/theme.typ": *
#import "data.typ" as D

#let cfg = toml("../deck.toml")
#let d = cfg.deck

#show: acad-theme.with(
  config-info(
    title: [#d.title — Backup],
    subtitle: [#d.venue],
    author: [#d.author],
    institution: [#d.institution],
    date: [#d.date],
  ),
  config-common(handout: HANDOUT),
)

#slide(title: [B1 — latency breakdown from data.typ])[
  #v(1fr)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 24pt,
    tile([#fmt2(D.baseline-latency) s], [Baseline latency]),
    tile([#fmt2(D.ours-latency) s], [Optimized latency (#D.speedup-range)], fill: ACCENT),
  )
  #v(1fr)
]

#slide(title: [B2 — checklist before presenting])[
  #v(1fr)
  #bullet([Run `make`], [Verify zero Typst warnings and all layout gates pass])
  #v(12pt)
  #bullet([Run `make check`], [Verify timing budget, concept order, and spoken jargon])
  #v(1fr)
]
