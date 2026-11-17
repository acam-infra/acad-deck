#!/usr/bin/env bash
#
# Build an acad-deck presentation from deck.toml.
#
#   render/<name>-talk.pdf           the deck as presented
#   render/<name>-talk-handout.pdf   one page per slide
#   render/<name>-backup.pdf         backup slides (if configured)
#   render/<name>-talk-notes.pdf     32:9 presenter view (slide + speaker script)
#   render/<name>-script.pdf         A4 delivery script with timings & Q&A
#   render/<name>-talk.pdfpc         pdfpc presenter metadata

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TYPST="${TYPST:-typst}"
command -v "$TYPST" >/dev/null 2>&1 || {
  echo "FAIL: typst not found. Run ./setup.sh or set TYPST=/path/to/typst" >&2
  exit 1
}

# Load build settings from deck.toml
eval "$(python3 - <<'PY'
import tomllib, shlex
with open("deck.toml", "rb") as f:
    cfg = tomllib.load(f)
d = cfg["deck"]
b = cfg["build"]
print(f"DECK_NAME={shlex.quote(d['name'])}")
print(f"MAIN_SRC={shlex.quote(b['main_src'])}")
print(f"BACKUP_SRC={shlex.quote(b.get('backup_src', ''))}")
print(f"OUT_DIR={shlex.quote(b.get('out_dir', 'render'))}")
print(f"QA_DIR={shlex.quote(b.get('qa_dir', 'qa'))}")
print(f"PAGES_MAIN={int(b['pages_main'])}")
print(f"PAGES_HANDOUT={int(b['pages_handout'])}")
print(f"PAGES_BACKUP={int(b.get('pages_backup', 0))}")
PY
)"

OUT="$OUT_DIR/${DECK_NAME}-talk.pdf"
OUT_HANDOUT="$OUT_DIR/${DECK_NAME}-talk-handout.pdf"
OUT_BACKUP="$OUT_DIR/${DECK_NAME}-backup.pdf"

mkdir -p "$OUT_DIR" "$QA_DIR"

compile_strict() {
  local src="$1" pdf="$2"; shift 2
  local log
  log=$("$TYPST" compile --root "$ROOT" "$@" "$src" "$pdf" 2>&1) || { echo "$log" >&2; exit 1; }
  if grep -qi 'warning' <<<"$log"; then
    echo "FAIL: $src compiled with typst warnings:" >&2
    echo "$log" >&2
    exit 1
  fi
}

expect_pages() {
  local got
  got=$(pdfinfo "$1" 2>/dev/null | awk '/^Pages:/ {print $2}')
  if [ "$got" != "$2" ]; then
    echo "FAIL: $1 has $got pages, expected $2." >&2
    exit 1
  fi
  echo "==> $(basename "$1"): $got pages"
}

echo "==> extracting paper figures (if configured in deck.toml)"
python3 core/tools/extract_paper_figs.py 2>/dev/null | sed 's/^/    /' || true

echo "==> compiling deck"
compile_strict "$MAIN_SRC" "$OUT"
compile_strict "$MAIN_SRC" "$OUT_HANDOUT" --input handout=1
expect_pages "$OUT" "$PAGES_MAIN"
expect_pages "$OUT_HANDOUT" "$PAGES_HANDOUT"

if [ -n "$BACKUP_SRC" ] && [ -f "$BACKUP_SRC" ]; then
  compile_strict "$BACKUP_SRC" "$OUT_BACKUP"
  if [ "$PAGES_BACKUP" -gt 0 ]; then
    expect_pages "$OUT_BACKUP" "$PAGES_BACKUP"
  fi
fi

echo "==> rendering QA pages"
rm -f "$QA_DIR"/s-*.png "$QA_DIR"/b-*.png
pdftoppm -png -r 110 "$OUT_HANDOUT" "$QA_DIR/s"
if [ -n "$BACKUP_SRC" ] && [ -f "$OUT_BACKUP" ]; then
  pdftoppm -png -r 110 "$OUT_BACKUP" "$QA_DIR/b"
fi
pdftoppm -png -singlefile -r 150 -f 1 -l 1 "$OUT" "$OUT_DIR/cover-thumb"

echo "==> compiling notes and delivery script PDFs"
TYPST="$TYPST" python3 core/tools/build_notes.py

echo "==> gates"
python3 core/tools/check_talk.py

echo
echo "deck    : $OUT"
echo "handout : $OUT_HANDOUT"
echo "notes   : $OUT_DIR/${DECK_NAME}-talk-notes.pdf"
echo "pdfpc   : $OUT_DIR/${DECK_NAME}-talk.pdfpc"
echo "script  : $OUT_DIR/${DECK_NAME}-script.pdf"
if [ -n "$BACKUP_SRC" ] && [ -f "$OUT_BACKUP" ]; then
  echo "backup  : $OUT_BACKUP"
fi
echo "QA      : $QA_DIR/s-*.png"
