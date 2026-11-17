// Native CeTZ diagrams for the deck.
#import "@preview/cetz:0.5.2"
#import "../core/theme.typ": DEEP, DEEP-LT, ACCENT, ACCENT-LT, TEAL, TEAL-DEEP, INK, MUTED, GFILL, GFAINT, SANS

#let fig-example-pipeline(unit: 0.72cm) = cetz.canvas(length: unit, {
  import cetz.draw: *

  let box-style = (fill: GFILL, stroke: 0.9pt + DEEP, radius: 0.15)
  let hot-style = (fill: ACCENT-LT, stroke: 1.2pt + ACCENT, radius: 0.15)

  rect((0, 0), (3.4, 2.0), ..box-style, name: "in")
  content("in.center", text(size: 11pt, weight: "bold", fill: INK)[Input Spec])

  rect((4.6, 0), (8.4, 2.0), ..hot-style, name: "opt")
  content("opt.center", text(size: 11pt, weight: "bold", fill: DEEP)[Core Engine])

  rect((9.6, 0), (13.0, 2.0), ..box-style, name: "out")
  content("out.center", text(size: 11pt, weight: "bold", fill: INK)[Output])

  line("in.east", "opt.west", mark: (end: ">", fill: DEEP), stroke: 1.1pt + DEEP)
  line("opt.east", "out.west", mark: (end: ">", fill: ACCENT), stroke: 1.1pt + ACCENT)
})
