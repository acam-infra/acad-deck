#!/usr/bin/env python3
"""Visual and layout quality gates for acad-deck PDFs."""
import json
import pathlib
import sys

import pymupdf

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from config_loader import ROOT, load_config


def fail(msg):
    print(f"FAIL: {msg}", file=sys.stderr)
    return 1


def warn(msg):
    print(f"WARN: {msg}", file=sys.stderr)
    return 0


def check_notes(pdfpc_path):
    if not pdfpc_path.exists():
        return fail(f"missing {pdfpc_path.name}")
    data = json.loads(pdfpc_path.read_text())
    pages = data["pages"]
    bad = [str(pg["idx"] + 1) for pg in pages if not (pg.get("note") or "").strip()]
    if bad:
        return fail(f"pages without a speaker note: {', '.join(bad)}")
    logical = len({pg["label"] for pg in pages})
    print(f"==> speaker notes: {len(pages)} pages / {logical} labels, all annotated")
    return 0


def check_ppi(pdf_path, ppi_floor):
    doc = pymupdf.open(pdf_path)
    worst = None
    for pno, page in enumerate(doc, start=1):
        for info in page.get_image_info():
            bbox = pymupdf.Rect(info["bbox"])
            if bbox.width <= 1 or bbox.height <= 1:
                continue
            ppi = min(info["width"] / bbox.width, info["height"] / bbox.height) * 72.0
            if worst is None or ppi < worst[0]:
                worst = (ppi, pno)
    if worst is None:
        print("==> bitmaps: none placed")
        return 0
    if worst[0] < ppi_floor:
        return fail(f"bitmap on page {worst[1]} resolves to {worst[0]:.0f} PPI, floor is {ppi_floor:.0f}")
    print(f"==> bitmaps: worst is {worst[0]:.0f} PPI on page {worst[1]} (floor {ppi_floor:.0f})")
    return 0


def row_profile(page):
    pm = page.get_pixmap(dpi=72, colorspace=pymupdf.csGRAY)
    w, h = pm.width, pm.height
    limit = int(h * 0.93)
    s = pm.samples
    empty = []
    for y in range(limit):
        row = s[y * w:(y + 1) * w]
        empty.append(not any(px < 250 for px in row))
    return h, empty


def check_ink(pdf_path, ink_floor, skip_pages, soft=False):
    doc = pymupdf.open(pdf_path)
    bad = []
    for pno, page in enumerate(doc, start=1):
        if pno in skip_pages:
            continue
        h, empty = row_profile(page)
        lowest = 0
        for y, is_empty in enumerate(empty):
            if not is_empty:
                lowest = y
        frac = lowest / h
        if frac < ink_floor:
            bad.append((pno, frac))
    if bad:
        detail = ", ".join(f"p{p} ink stops at {f:.0%}" for p, f in bad)
        msg = f"bottom dead zone (floor {ink_floor:.0%}): {detail}"
        return warn(msg) if soft else fail(msg)
    print(f"==> ink bbox: every content slide reaches >= {ink_floor:.0%} of page height")
    return 0


def check_fill(pdf_path, gap_ceil, cover_floor, skip_pages):
    doc = pymupdf.open(pdf_path)
    gaps, covers = [], []
    for pno, page in enumerate(doc, start=1):
        if pno in skip_pages:
            continue
        h, empty = row_profile(page)
        longest = cur = 0
        for is_empty in empty:
            cur = cur + 1 if is_empty else 0
            longest = max(longest, cur)
        gaps.append((pno, longest / h))
        covers.append((pno, 1 - sum(empty) / len(empty)))

    if not gaps:
        return 0
    over = [(p, g) for p, g in gaps if g > gap_ceil]
    thin = [(p, c) for p, c in covers if c < cover_floor]
    rc = 0
    if over:
        detail = ", ".join(f"p{p} has a {g:.0%} blank band" for p, g in over)
        rc |= fail(f"mid-slide hole (ceiling {gap_ceil:.0%}): {detail}")
    if thin:
        detail = ", ".join(f"p{p} only {c:.0%} inked" for p, c in thin)
        rc |= fail(f"sparse slide (floor {cover_floor:.0%}): {detail}")
    if rc == 0:
        worst_gap = max(g for _, g in gaps)
        worst_cover = min(c for _, c in covers)
        print(
            f"==> fill: worst blank band {worst_gap:.0%} (ceiling {gap_ceil:.0%}), "
            f"thinnest page {worst_cover:.0%} inked (floor {cover_floor:.0%})"
        )
    return rc


def check_headings(pdf_path, heading_band, heading_min_size):
    doc = pymupdf.open(pdf_path)
    bad = []
    for pno, page in enumerate(doc, start=1):
        limit = heading_band * page.rect.height
        lines = {}
        for block in page.get_text("dict")["blocks"]:
            for line in block.get("lines", []):
                for span in line["spans"]:
                    if span["size"] > heading_min_size and span["bbox"][1] < limit:
                        lines.setdefault(round(span["bbox"][1], 1), []).append(span["text"])
        if len(lines) > 1:
            joined = " | ".join("".join(v) for _, v in sorted(lines.items()))
            bad.append((pno, joined))
    if bad:
        detail = "; ".join(f"p{p} wraps: {t}" for p, t in bad)
        return fail(f"heading must be one line: {detail}")
    print("==> headings: one line on every page that carries one")
    return 0


def main():
    cfg = load_config()
    name = cfg["deck"]["name"]
    render = ROOT / cfg["build"].get("out_dir", "render")
    g = cfg.get("gates", {})

    talk_pdf = render / f"{name}-talk.pdf"
    handout_pdf = render / f"{name}-talk-handout.pdf"
    pdfpc = render / f"{name}-talk.pdfpc"

    doc = pymupdf.open(handout_pdf)
    skip_pages = {1, len(doc)} | set(g.get("exempt_pages", []))
    doc.close()

    rc = 0
    rc |= check_notes(pdfpc)
    rc |= check_ppi(talk_pdf, float(g.get("ppi_floor", 150.0)))
    rc |= check_ink(
        handout_pdf,
        float(g.get("ink_floor", 0.88)),
        skip_pages,
        soft=bool(g.get("soft_bottom_dead_zone", True)),
    )
    rc |= check_fill(
        handout_pdf,
        float(g.get("gap_ceil", 0.28)),
        float(g.get("cover_floor", 0.33)),
        skip_pages,
    )
    rc |= check_headings(
        handout_pdf,
        float(g.get("heading_band", 0.135)),
        float(g.get("heading_min_size", 15.0)),
    )
    return rc


if __name__ == "__main__":
    sys.exit(main())
