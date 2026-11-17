#!/usr/bin/env python3
"""Extract paper figures declared in deck.toml [figures] as cropped, scalable SVGs."""
import pathlib
import sys

import pymupdf as fitz

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from config_loader import ROOT, load_config

PAD = 2.0


def ink_rect(page, dpi=300):
    pm = page.get_pixmap(dpi=dpi, colorspace=fitz.csGRAY)
    w, h, s = pm.width, pm.height, pm.samples
    minx, miny, maxx, maxy = w, h, -1, -1
    for y in range(h):
        row = s[y * w:(y + 1) * w]
        left = next((x for x in range(w) if row[x] < 250), None)
        if left is None:
            continue
        right = next(x for x in range(w - 1, -1, -1) if row[x] < 250)
        minx, maxx = min(minx, left), max(maxx, right)
        miny, maxy = min(miny, y), max(maxy, y)
    if maxx < 0:
        return page.rect
    k = 72.0 / dpi
    r = fitz.Rect(minx * k, miny * k, (maxx + 1) * k, (maxy + 1) * k)
    r = r + (-PAD, -PAD, PAD, PAD)
    return r & page.rect


def main():
    cfg = load_config()
    figs = cfg.get("figures", {})
    if not figs:
        print("no [figures] configured in deck.toml — skipping")
        return

    out_dir = ROOT / "slides" / "assets" / "paper"
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, rel in figs.items():
        src = ROOT / rel
        if not src.exists():
            print(f"WARN: missing source figure {src}", file=sys.stderr)
            continue
        doc = fitz.open(src)
        page = doc[0]
        r = ink_rect(page)
        out = fitz.open()
        np_ = out.new_page(width=r.width, height=r.height)
        np_.show_pdf_page(fitz.Rect(0, 0, r.width, r.height), doc, 0, clip=r)
        svg = np_.get_svg_image(text_as_path=True)
        dst = out_dir / f"{name}.svg"
        dst.write_text(svg, encoding="utf-8")
        out.close()
        doc.close()
        print(f"{name:14s} {r.width:7.1f} x {r.height:6.1f} pt -> {dst.name} ({dst.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
