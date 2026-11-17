// acad-deck — Generic Touying Presentation Theme
//
// Visual language: clean academic light ground, configurable structural navy
// & accent tokens with contrast-verified light/dark pairs, teal tick +
// segmented rule under every slide title, quiet three-part footer, and
// optional focus-step overlays that collapse cleanly in handout mode.
//
// Configuration is loaded from ../deck.toml at the repo root.

#import "@preview/touying:0.7.4": *

#let _cfg = toml("../deck.toml")
#let _deck = _cfg.at("deck", default: (:))
#let _th = _cfg.at("theme", default: (:))

// ------------------------------------------------------------------ tokens
#let DEEP = rgb(_th.at("deep", default: "#0F2744"))
#let DEEP-LT = rgb(_th.at("deep_lt", default: "#E8F0F8"))
#let ACCENT = rgb(_th.at("accent", default: "#0E7490"))
#let ACCENT-LT = rgb(_th.at("accent_lt", default: "#E0F5FB"))
#let TEAL = rgb(_th.at("teal", default: "#14B8A6"))          // strokes on dark / header tick
#let TEAL-DEEP = rgb(_th.at("teal_deep", default: "#0F766E")) // teal text on light grounds
#let BAD = rgb(_th.at("bad", default: "#B91C1C"))
#let GOOD = TEAL-DEEP
#let INK = rgb(_th.at("ink", default: "#1F2937"))
#let MUTED = rgb(_th.at("muted", default: "#5B6673"))
#let FOOT = rgb(_th.at("foot", default: "#667382"))
#let GDARK = rgb(_th.at("gdark", default: "#24364F"))
#let GMID = rgb(_th.at("gmid", default: "#5B6673"))
#let GLT = rgb(_th.at("glt", default: "#94A3B8"))
#let GFAINT = rgb(_th.at("gfaint", default: "#D5DEE6"))
#let GFILL = rgb(_th.at("gfill", default: "#F3F7FA"))
#let DIM = MUTED.transparentize(45%)

// Dark-ground text ladder for section-divider cards
#let D-TAG-FUT = rgb("#94A3B8")
#let D-NAME-FUT = rgb("#C3CEDA")
#let D-DESC-FUT = rgb("#94A3B8")
#let D-TAG-PAST = rgb("#A9B8C8")
#let D-NAME-PAST = rgb("#E3EAF2")
#let D-DESC-PAST = rgb("#A9B8C8")
#let D-NAME-ACT = rgb("#FFFFFF")
#let D-DESC-ACT = rgb("#DCE5EE")

#let SANS = _th.at("sans_font", default: "Liberation Sans")
#let MONO = _th.at("mono_font", default: "Liberation Mono")
#let CJK = _th.at("cjk_font", default: "Noto Sans CJK SC")

// Paths in deck.toml are relative to repo root; resolve relative to core/
#let _inst-logo-rel = _th.at("logo_institution", default: "")
#let _venue-logo-rel = _th.at("logo_venue", default: "")
#let LOGO-INST = if _inst-logo-rel != "" { "../" + _inst-logo-rel } else { none }
#let LOGO-VENUE = if _venue-logo-rel != "" { "../" + _venue-logo-rel } else { none }

#let HANDOUT = sys.inputs.at("handout", default: "0") == "1"

// ------------------------------------------------------------------ helpers
#let kw(it) = text(font: MONO, size: 0.9em, fill: DEEP, it)
#let mono(it) = text(font: MONO, size: 0.9em, it)
#let hot(it) = text(fill: ACCENT, weight: "bold", it)
#let note = speaker-note

#let fmt2(v) = {
  let s = str(calc.round(v, digits: 2))
  let parts = s.split(".")
  if parts.len() == 1 { s + ".00" } else if parts.at(1).len() == 1 { s + "0" } else { s }
}

#let dark-deco = [
  #place(top + right, dx: -2.4cm, dy: -6.6cm, circle(radius: 7.4cm, stroke: 1.1pt + rgb("#14b8a63d")))
  #place(top + right, dx: -1.2cm, dy: -8.4cm, circle(radius: 9.4cm, stroke: 0.8pt + rgb("#ffffff17")))
  #place(top + right, dx: -3.8cm, dy: -4.6cm, circle(radius: 5.4cm, stroke: 0.9pt + rgb("#0891b245")))
  #place(top + right, dx: -6.8cm, dy: 1.9cm, circle(radius: 0.14cm, fill: TEAL))
  #place(top + right, dx: -6.8cm, dy: 1.9cm, circle(radius: 0.3cm, stroke: 0.7pt + rgb("#14b8a666")))
  #place(top + right, dx: -9.6cm, dy: 4.2cm, circle(radius: 0.07cm, fill: rgb("#7dd3fc99")))
  #place(top + right, dx: -4.2cm, dy: 5.8cm, circle(radius: 0.06cm, fill: rgb("#ffffff5c")))
  #place(top + right, dx: -11.5cm, dy: 1.4cm, circle(radius: 0.06cm, fill: rgb("#ffffff40")))
]

#let strap(body, fill: rgb("#D9EEF6"), color: DEEP) = block(
  width: 100%,
  inset: (x: 12pt, y: 8pt),
  fill: fill,
  stroke: (left: 3pt + ACCENT),
  radius: 3pt,
  text(size: 17pt, weight: "medium", fill: color, body),
)

#let BODY-HEAD = 15pt
#let BODY-TEXT = 13.5pt

#let bullet(head, tail, size: BODY-HEAD, spacing: 0.4em, dim: false) = block(spacing: spacing, {
  let c-mark = if dim { DIM } else { TEAL-DEEP }
  let c-text = if dim { DIM } else { INK }
  grid(
    columns: (auto, 1fr),
    column-gutter: 9pt,
    align: (left + top, left + top),
    text(size: size, weight: "bold", fill: c-mark)[▸],
    {
      text(size: size, weight: "bold", fill: c-text, head)
      if tail != none {
        linebreak()
        text(size: size - 1.5pt, fill: c-text, tail)
      }
    },
  )
})

/// Focus-walk overlay helper: highlights one item per step, collapses to
/// all-bright in handout mode (never collapsing to last-only).
#let focus-steps(items, spacing: 14pt) = {
  let render(hot-idx) = stack(
    spacing: spacing,
    ..items.enumerate().map(((i, it)) =>
      bullet(it.head, it.tail, dim: hot-idx != none and i != hot-idx)
    ),
  )
  if HANDOUT { render(none) } else { alternatives(..range(items.len()).map(render)) }
}

#let card(head, body, fill: GFILL, edge: DEEP.transparentize(70%), stroke-w: 0.8pt) = block(
  width: 100%,
  inset: (x: 11pt, y: 8pt),
  fill: fill,
  stroke: stroke-w + edge,
  radius: 3pt,
  {
    text(size: BODY-HEAD, weight: "bold", fill: INK, head)
    v(3pt)
    text(size: BODY-TEXT, fill: INK, body)
  },
)

#let tile(value, label, fill: GDARK, value-size: 34pt) = block(
  width: 100%,
  inset: (x: 12pt, y: 10pt),
  fill: fill,
  radius: 4pt,
  {
    set align(center)
    text(size: value-size, weight: "bold", fill: white, value)
    v(-4pt)
    text(size: 13.5pt, weight: "medium", fill: white, label)
  },
)

// ------------------------------------------------------------------- slides
#let slide(
  title: auto,
  config: (:),
  repeat: auto,
  setting: body => body,
  composer: auto,
  ..bodies,
) = touying-slide-wrapper(self => {
  let f-left = _deck.at("footer_left", default: _deck.at("institution", default: ""))
  let f-center = _deck.at("footer_center", default: _deck.at("title", default: ""))

  let header(self) = {
    set align(top)
    pad(left: 46pt, right: 46pt, {
      block(width: 100%, height: 58pt, {
        grid(
          columns: (auto, 1fr, auto),
          column-gutter: 12pt,
          align: (bottom + left, bottom + left, bottom + right),
          box(fill: TEAL, width: 4.2pt, height: 18pt, radius: 1.5pt),
          block(
            height: 100%,
            align(
              bottom,
              text(size: 19pt, weight: "bold", fill: DEEP, hyphenate: false, {
                if title != auto { title } else { utils.call-or-display(self, self.store.title) }
              }),
            ),
          ),
          block(
            height: 100%,
            align(
              bottom + right,
              if LOGO-INST != none { image(LOGO-INST, height: 24pt) } else { [] },
            ),
          ),
        )
        grid(
          columns: (13%, 1fr),
          gutter: 0pt,
          line(length: 100%, stroke: 1.8pt + TEAL),
          line(length: 100%, stroke: 0.6pt + rgb("#E2E8F0")),
        )
      })
    })
  }

  let footer(self) = {
    set text(size: 10pt, fill: FOOT)
    pad(left: 46pt, right: 46pt, {
      place(top, dy: -6pt, line(length: 100%, stroke: 0.75pt + GFAINT))
      grid(
        columns: (1fr, auto, 1fr),
        column-gutter: 1em,
        align(left)[#f-left],
        align(center)[#text(size: 9.5pt)[#f-center]],
        align(right)[#context [#utils.slide-counter.display() / #utils.last-slide-number]],
      )
    })
  }

  let self = utils.merge-dicts(self, config-page(header: header, footer: footer))
  touying-slide(
    self: self,
    config: config,
    repeat: repeat,
    setting: setting,
    composer: composer,
    ..bodies,
  )
})

#let title-slide(config: (:), ..args) = touying-slide-wrapper(self => {
  self = utils.merge-dicts(
    self,
    config-common(freeze-slide-counter: true),
    config-page(header: none, footer: none, margin: (x: 54pt, top: 48pt, bottom: 40pt), fill: white),
    config,
  )
  let info = self.info + args.named()
  touying-slide(self: self, {
    set text(fill: INK, font: (SANS, CJK), hyphenate: false)

    v(1.2fr)
    align(center)[
      #block(width: 96%)[
        #text(size: 33.5pt, weight: "bold", fill: INK)[
          #if info.subtitle != none and info.subtitle != auto [
            #info.title: #info.subtitle
          ] else [
            #info.title
          ]
        ]
      ]

      #v(26pt)
      #text(size: 18pt, fill: INK, info.author)

      #if info.at("institution", default: none) != none [
        #v(11pt)
        #text(size: 14pt, fill: MUTED, info.institution)
      ]

      #if info.at("date", default: none) != none [
        #v(6pt)
        #text(size: 12.5pt, fill: rgb("#64748B"), info.date)
      ]
    ]

    v(1.8fr)

    if LOGO-VENUE != none or LOGO-INST != none [
      align(center)[
        #grid(
          columns: (auto, auto),
          column-gutter: 56pt,
          align: horizon,
          if LOGO-VENUE != none { image(LOGO-VENUE, height: 56pt) },
          if LOGO-INST != none { image(LOGO-INST, height: 34pt) },
        )
      ]
    ]
    v(0.8fr)
  })
})

#let section-slide(
  num: "01",
  title: auto,
  subtitle: auto,
  sections: (
    ("01", "Intro", "Background & Problem"),
    ("02", "Method", "Design & Mechanisms"),
    ("03", "Eval", "Evaluation & Ablation"),
    ("04", "Conclusion", "Takeaway & Summary"),
  ),
  config: (:),
) = touying-slide-wrapper(self => {
  self = utils.merge-dicts(
    self,
    config-page(
      fill: DEEP,
      header: none,
      footer: none,
      margin: (x: 56pt, top: 44pt, bottom: 36pt),
    ),
    config,
  )

  let active-idx = int(num) - 1
  let total-sec = if sections.len() < 10 { "0" + str(sections.len()) } else { str(sections.len()) }

  let body = {
    dark-deco

    grid(
      columns: (auto, auto, auto),
      gutter: 0.35em,
      rect(fill: TEAL, width: 1.6cm, height: 0.16cm, radius: 1pt),
      rect(fill: rgb("#3E5F7E"), width: 0.75cm, height: 0.16cm, radius: 1pt),
      rect(fill: rgb("#22405F"), width: 0.4cm, height: 0.16cm, radius: 1pt),
    )

    v(16pt)
    text(size: 14pt, fill: TEAL, weight: "bold", tracking: 3pt)[SECTION #num / #total-sec]
    v(10pt)
    text(size: 40pt, weight: "bold", fill: white, title)
    if subtitle != none and subtitle != auto {
      v(6pt)
      text(size: 18pt, fill: rgb("#A9B8C8"), subtitle)
    }

    v(1fr)

    grid(
      columns: (1fr,) * sections.len(),
      column-gutter: 12pt,
      ..sections.enumerate().map(((idx, (snum, tag, desc))) => {
        let is-active = (idx == active-idx)
        let is-past = (idx < active-idx)
        block(
          width: 100%,
          inset: (x: 12pt, y: 14pt),
          fill: if is-active { rgb("#153250") } else { rgb("#0b1e33") },
          stroke: if is-active { 1.5pt + TEAL } else { 0.6pt + rgb("#ffffff2e") },
          radius: 4pt,
          {
            text(
              size: 11pt,
              weight: "bold",
              fill: if is-active { TEAL } else if is-past { D-TAG-PAST } else { D-TAG-FUT },
              tracking: 1.5pt,
              [PART #snum #if is-active [ · ACTIVE] else if is-past [ ✓] else []],
            )
            v(4pt)
            text(
              size: 18pt,
              weight: "bold",
              fill: if is-active { D-NAME-ACT } else if is-past { D-NAME-PAST } else { D-NAME-FUT },
              tag,
            )
            v(2pt)
            text(
              size: 11pt,
              fill: if is-active { D-DESC-ACT } else if is-past { D-DESC-PAST } else { D-DESC-FUT },
              desc,
            )
          },
        )
      })
    )
    v(10pt)
  }

  touying-slide(self: self, body)
})

#let end-slide(config: (:), body) = touying-slide-wrapper(self => {
  self = utils.merge-dicts(
    self,
    config-page(header: none, margin: (x: 56pt, top: 48pt, bottom: 40pt)),
    config,
  )
  touying-slide(self: self, body)
})

#let thank-you-slide(
  title: [Thank You],
  subtitle: [Questions & Comments Welcome],
  author: _deck.at("presenter", default: _deck.at("author", default: "")),
  affiliation: _deck.at("institution", default: ""),
  email: none,
  github: none,
  dark: false,
  config: (:),
) = touying-slide-wrapper(self => {
  let kicker = upper(_deck.at("footer_center", default: _deck.at("title", default: "TALK")))
  if dark {
    self = utils.merge-dicts(
      self,
      config-common(freeze-slide-counter: true),
      config-page(header: none, footer: none, margin: (x: 70pt, y: 54pt), fill: DEEP),
      config,
    )
    touying-slide(self: self, {
      place(top + left, dark-deco)
      place(
        top + left,
        grid(
          columns: (auto, auto),
          column-gutter: 6pt,
          align: horizon,
          rect(fill: TEAL, width: 0.85cm, height: 0.16cm, radius: 1pt),
          rect(fill: rgb("#22405F"), width: 0.4cm, height: 0.16cm, radius: 1pt),
        ),
      )
      v(1fr)
      text(size: 13pt, fill: TEAL, weight: "bold", tracking: 3pt)[#kicker]
      v(14pt)
      text(size: 50pt, weight: "bold", fill: white, title)
      v(12pt)
      grid(
        columns: (22%, 1fr),
        gutter: 0pt,
        line(length: 100%, stroke: 2.6pt + TEAL),
        line(length: 100%, stroke: 0.9pt + rgb("#ffffff2e")),
      )
      v(14pt)
      text(size: 20pt, fill: rgb("#CBD5E1"), subtitle)
      v(1fr)
      line(length: 38%, stroke: 0.6pt + rgb("#ffffff26"))
      v(14pt)
      text(size: 20pt, weight: "bold", fill: white, author)
      if affiliation != none and affiliation != "" {
        linebreak()
        v(2pt)
        text(size: 14pt, fill: rgb("#A9B8C8"), affiliation)
      }
      v(6pt)
      grid(
        columns: (auto, auto),
        column-gutter: 26pt,
        align: horizon,
        if email != none {
          text(size: 14.5pt, fill: rgb("#CBD5E1"))[
            Email: #text(fill: TEAL, font: MONO)[#email]
          ]
        },
        if github != none {
          text(size: 14.5pt, fill: rgb("#CBD5E1"))[
            GitHub: #text(fill: white, font: MONO)[#github]
          ]
        },
      )
    })
  } else {
    self = utils.merge-dicts(
      self,
      config-common(freeze-slide-counter: true),
      config-page(header: none, footer: none, margin: (x: 64pt, top: 46pt, bottom: 44pt), fill: white),
      config,
    )
    touying-slide(self: self, {
      set text(fill: INK, font: (SANS, CJK))
      v(1.2fr)
      align(center)[
        #text(size: 46pt, weight: "bold", fill: INK, title)
        #if subtitle != none and subtitle != auto [
          #v(14pt)
          #text(size: 19pt, fill: MUTED, weight: "medium", subtitle)
        ]
        #v(28pt)
        #text(size: 18pt, weight: "bold", fill: INK, author)
        #if affiliation != none and affiliation != "" [
          #v(8pt)
          #text(size: 14pt, fill: MUTED, affiliation)
        ]
        #if email != none [
          #v(8pt)
          #text(size: 14pt, fill: MUTED)[
            Email: #text(fill: INK, font: MONO, weight: "bold")[#email]
          ]
        ]
      ]
      v(1.8fr)
      if LOGO-VENUE != none or LOGO-INST != none [
        align(center)[
          #grid(
            columns: (auto, auto),
            column-gutter: 56pt,
            align: horizon,
            if LOGO-VENUE != none { image(LOGO-VENUE, height: 56pt) },
            if LOGO-INST != none { image(LOGO-INST, height: 34pt) },
          )
        ]
      ]
      v(0.8fr)
    })
  }
})

// -------------------------------------------------------------------- theme
#let acad-theme(..args, body) = {
  show: touying-slides.with(
    config-page(
      width: 960pt,
      height: 540pt,
      margin: (x: 46pt, top: 96pt, bottom: 46pt),
      header-ascent: 16pt,
      footer-descent: 23pt,
      fill: white,
    ),
    config-common(
      slide-fn: slide,
      show-notes-on-second-screen: if sys.inputs.at("notes", default: "0") == "1" {
        right
      } else {
        none
      },
    ),
    config-methods(
      alert: (self: none, it) => text(fill: ACCENT, weight: "bold", it),
    ),
    config-colors(primary: DEEP, secondary: ACCENT, neutral-darkest: INK, neutral-lightest: white),
    ..args,
  )
  set text(font: (SANS, CJK), size: 19pt, fill: INK, lang: "en")
  set par(leading: 0.62em, spacing: 0.9em)
  show raw: set text(font: MONO)
  show strong: it => text(fill: DEEP, weight: "bold", it.body)
  show figure.caption: set text(size: 11.5pt, fill: MUTED)
  set list(marker: (text(fill: ACCENT)[▸], text(fill: TEAL)[•]), spacing: 0.7em, indent: 0.4em)
  body
}
