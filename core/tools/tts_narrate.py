#!/usr/bin/env python3
"""Narrate SCRIPT.md: clean per-slide spoken text and synthesize one MP3 per slide."""
import argparse
import concurrent.futures
import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from config_loader import ROOT, load_config

DEFAULT_BASE_URL = "https://g2a-jp03.l3j.pw:9443"
DEFAULT_MODEL = "grok-voice-latest"
DEFAULT_PROXY = "http://127.0.0.1:2080"
ENV_FILE = pathlib.Path.home() / ".agents" / "skills" / "grok2api" / ".env"

SLIDE_RE = re.compile(r"^## (?:Slide )?(\d\d) · (.+?)\s*$", re.M)
H2_RE = re.compile(r"^## ", re.M)
CLOCK_RE = re.compile(r"\s*—\s*\d+:\d\d\s*→\s*\d+:\d\d")
CHECKPOINT_RE = re.compile(r"\s*·\s*checkpoint\s+[①②③\d]+\s*$")
ASIDE_RE = re.compile(r"^\*\(.*\)\*$", re.S)
IDENT_RE = re.compile(r"\b\w+(?:_\w+)+\b")

_cfg = load_config()
_script_cfg = _cfg.get("script", {})
WPM = int(_script_cfg.get("wpm", 130))
SPOKEN = dict(_script_cfg.get("spoken", {}))


def load_env():
    env = {k: v for k, v in os.environ.items() if k.startswith("GROK2API")}
    if env.get("GROK2API_API_KEY"):
        return env
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text().splitlines():
            m = re.match(r"^([A-Z0-9_]+)=(.*)$", line.strip())
            if m and m.group(1).startswith("GROK2API"):
                env.setdefault(m.group(1), m.group(2).strip().strip("'\""))
    return env


def clean_spoken(body: str) -> str:
    body = re.sub(r"<!--.*?-->", "", body, flags=re.S)
    paras = []
    for raw_para in re.split(r"\n\s*\n", body.strip()):
        p = raw_para.strip()
        if not p or ASIDE_RE.match(p):
            continue
        p = re.sub(r"`([^`]+)`", r"\1", p)
        p = re.sub(r"\*\*([^*]+)\*\*", r"\1", p)
        p = re.sub(r"\*([^*]+)\*", r"\1", p)
        p = re.sub(r"\s+", " ", p).strip()
        for ident, spoken in SPOKEN.items():
            p = re.sub(r"\b" + re.escape(ident) + r"\b", spoken, p)
        p = IDENT_RE.sub(lambda m: m.group(0).replace("_", " "), p)
        paras.append(p)
    return "\n\n".join(paras)


def parse_slides(md_text: str):
    matches = list(SLIDE_RE.finditer(md_text))
    slides = []
    for i, m in enumerate(matches):
        nn = m.group(1)
        title = CHECKPOINT_RE.sub("", CLOCK_RE.sub("", m.group(2))).strip()
        start = m.end()
        end = len(md_text)
        for h in H2_RE.finditer(md_text, start):
            end = h.start()
            break
        hr = md_text.find("\n---", start)
        if hr != -1 and hr < end:
            end = hr
        spoken = clean_spoken(md_text[start:end])
        if spoken:
            slides.append((nn, title, 0, spoken))
    return slides


def synthesize(text: str, out_mp3: pathlib.Path, env: dict, model: str, proxy: str):
    url = env.get("GROK2API_BASE_URL", DEFAULT_BASE_URL).rstrip("/") + "/v1/audio/speech"
    key = env["GROK2API_API_KEY"]
    payload = json.dumps({"model": model, "input": text, "response_format": "mp3"}).encode()
    req = urllib.request.Request(
        url,
        data=payload,
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            "User-Agent": "acad-deck-tts/1.0",
        },
        method="POST",
    )
    handlers = []
    if proxy:
        handlers.append(urllib.request.ProxyHandler({"http": proxy, "https": proxy}))
    opener = urllib.request.build_opener(*handlers)
    with opener.open(req, timeout=60) as resp:
        out_mp3.write_bytes(resp.read())


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--join", action="store_true")
    ap.add_argument("--join-only", action="store_true")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--slide", help="only one slide number, e.g. 03")
    ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--no-proxy", action="store_true")
    args = ap.parse_args()

    script_md = ROOT / _script_cfg.get("path", "slides/SCRIPT.md")
    out_dir = ROOT / _cfg["build"].get("out_dir", "render") / "narration"
    slides = parse_slides(script_md.read_text())

    if args.dry_run:
        for nn, title, _, spoken in slides:
            print(f"=== Slide {nn} · {title} ===\n{spoken}\n")
        return

    out_dir.mkdir(parents=True, exist_ok=True)
    manifest_path = out_dir / "manifest.json"
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}

    if not args.join_only:
        env = load_env()
        if not env.get("GROK2API_API_KEY"):
            sys.exit("error: GROK2API_API_KEY not set and ~/.agents/skills/grok2api/.env not found")
        proxy = "" if args.no_proxy else DEFAULT_PROXY
        todo = []
        for nn, title, _, spoken in slides:
            if args.slide and nn != args.slide.zfill(2):
                continue
            digest = hashlib.sha256((DEFAULT_MODEL + "\n" + spoken).encode()).hexdigest()
            mp3 = out_dir / f"s-{nn}.mp3"
            if not args.force and mp3.exists() and manifest.get(nn, {}).get("sha256") == digest:
                continue
            todo.append((nn, title, spoken, digest, mp3))

        lock = threading.Lock()
        def worker(item):
            nn, title, spoken, digest, mp3 = item
            t0 = time.time()
            synthesize(spoken, mp3, env, DEFAULT_MODEL, proxy)
            with lock:
                manifest[nn] = {"sha256": digest, "words": len(spoken.split())}
                print(f"==> s-{nn}.mp3 ({time.time() - t0:.1f}s)")

        with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as ex:
            list(ex.map(worker, todo))
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")

    if args.join or args.join_only:
        files = [out_dir / f"s-{nn}.mp3" for nn, _, _, _ in slides if (out_dir / f"s-{nn}.mp3").exists()]
        if files:
            list_file = out_dir / "concat.txt"
            list_file.write_text("".join(f"file '{p.name}'\n" for p in files))
            subprocess.run(
                ["ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", str(list_file), "-c", "copy", str(out_dir / "full.mp3")],
                check=True,
                capture_output=True,
            )
            print(f"==> {out_dir / 'full.mp3'}")


if __name__ == "__main__":
    main()
