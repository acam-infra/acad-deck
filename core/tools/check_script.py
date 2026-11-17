#!/usr/bin/env python3
"""Check SCRIPT.md: clock, concept introduction order, deixis, jargon, and dashes."""
import argparse
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from config_loader import ROOT, load_config
from tts_narrate import SPOKEN, WPM, parse_slides

IDENT_RE = re.compile(r"\b[a-z]\w*(?:_\w+)+\b")
DASHES = ("—", "–")


def mmss(seconds):
    s = int(round(seconds))
    return f"{s // 60}:{s % 60:02d}"


def sentences(text):
    for para in text.split("\n\n"):
        for sent in re.split(r"(?<=[.?!])\s+", para.strip()):
            if sent:
                yield sent


def main():
    cfg = load_config()
    sc = cfg.get("script", {})
    script_md = ROOT / sc.get("path", "slides/SCRIPT.md")
    talk_minutes = int(sc.get("duration_minutes", 12))
    introduced = dict(sc.get("introduced", {}))
    deixis = list(sc.get("deixis", {}).get("phrases", []))

    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--wpm", type=int, default=WPM)
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    if not script_md.exists():
        sys.exit(f"error: {script_md} not found")
    slides = parse_slides(script_md.read_text())
    if not slides:
        sys.exit("error: no Slide sections found")

    fails = []
    say = (lambda *a: None) if args.quiet else print

    say(f"==> clock ({args.wpm} wpm)")
    total_words = 0
    running = 0.0
    for nn, _title, _secs, text in slides:
        words = len(text.split())
        need = words * 60 / args.wpm
        total_words += words
        running += need
        say(f"    s-{nn}  {words:4d} words  {need:5.1f}s   {mmss(running)}")
    spoken = total_words * 60 / args.wpm
    say(f"    total {total_words} words = {mmss(spoken)} against the {talk_minutes}:00 slot")
    if spoken > talk_minutes * 60:
        fails.append(f"whole talk runs {mmss(spoken)} at {args.wpm} wpm, over the {talk_minutes}:00 slot")

    say("\n==> concepts")
    first_use = {}
    for nn, _title, _budget, text in slides:
        if int(nn) <= 1:
            continue
        low = text.lower()
        for term in introduced:
            forms = {term.lower(), SPOKEN.get(term, term).lower()}
            if any(re.search(r"(?<!\w)" + re.escape(f) + r"e?s?(?!\w)", low) for f in forms):
                first_use.setdefault(term, int(nn))
    for term, declared in sorted(introduced.items(), key=lambda kv: kv[1]):
        used = first_use.get(term)
        if used is None:
            say(f"    {term:<26} declared s-{declared:02d}, never spoken")
        elif used < declared:
            fails.append(f"'{term}' is spoken on s-{used:02d} but only explained on s-{declared:02d}")
            say(f"    {term:<26} FIRST USE s-{used:02d} < introduced s-{declared:02d}")
        else:
            say(f"    {term:<26} introduced s-{declared:02d}, first spoken s-{used:02d}  ok")

    say("\n==> figure deixis")
    hits = 0
    for nn, _title, _budget, text in slides:
        for sent in sentences(text):
            low = sent.lower()
            for phrase in deixis:
                if phrase in low:
                    hits += 1
                    fails.append(f"s-{nn} describes the slide instead of the point: \"{sent.strip()[:70]}\"")
                    say(f"    s-{nn}  [{phrase}] {sent.strip()[:70]}")
                    break
    if not hits:
        say("    none — every page states its conclusion")

    say("\n==> spoken jargon")
    unknown = 0
    for nn, _title, _budget, text in slides:
        for ident in set(IDENT_RE.findall(text)):
            if ident not in SPOKEN and ident.lower() not in (k.lower() for k in SPOKEN):
                unknown += 1
                fails.append(f"s-{nn} says '{ident}' aloud with no pronunciation in deck.toml [script.spoken]")
                say(f"    s-{nn}  {ident}")
    if not unknown:
        say("    none — every identifier has a spoken form")

    say("\n==> em dashes")
    dashes = 0
    for nn, _title, _budget, text in slides:
        for sent in sentences(text):
            for ch in DASHES:
                if ch in sent:
                    dashes += 1
                    fails.append(f"s-{nn} uses a dash aside: \"{sent.strip()[:70]}\"")
                    say(f"    s-{nn}  {sent.strip()[:70]}")
                    break
    if not dashes:
        say("    none — no written-register dash asides")

    print()
    for f in fails:
        print("FAIL: " + f)
    if not fails:
        print("==> SCRIPT.md: clock, concept order, deixis, jargon and dashes all clean")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
