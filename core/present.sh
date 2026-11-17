#!/usr/bin/env bash
# Open the built deck in the pdfpc-ts presenter console (local offline mode).
#
#   ./core/present.sh              # 32:9 notes PDF, slide left + script right
#   ./core/present.sh --deck       # 16:9 deck, no notes pane
#   ./core/present.sh --watch      # reload the window whenever build.sh rewrites the PDF
#   ./core/present.sh --chrome     # Chrome app window instead of Safari (macOS)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DECK_NAME="$(python3 -c 'import tomllib; print(tomllib.load(open("'"$ROOT"'/deck.toml","rb"))["deck"]["name"])')"
OUT_DIR="$(python3 -c 'import tomllib; print(tomllib.load(open("'"$ROOT"'/deck.toml","rb"))["build"].get("out_dir","render"))')"
RENDER="$ROOT/$OUT_DIR"
CACHE="${PDFPC_TS_DIR:-$HOME/.cache/pdfpc-ts}"
REPO="https://github.com/chocolatedesue/pdfpc-ts"

mode=notes
watch=0
browser=auto
passthrough=()
for arg in "$@"; do
  case "$arg" in
    --deck|--handout) mode=deck ;;
    --notes) mode=notes ;;
    --watch) watch=1 ;;
    --safari) browser=safari ;;
    --chrome) browser=chrome ;;
    *) passthrough+=("$arg") ;;
  esac
done

if [ "$browser" = auto ]; then
  if [ "$(uname -s)" = "Darwin" ]; then browser=safari; else browser=chrome; fi
fi

if [ "$mode" = deck ]; then
  pdf="$RENDER/${DECK_NAME}-talk.pdf"
  layout=--no-notes
else
  pdf="$RENDER/${DECK_NAME}-talk-notes.pdf"
  layout=--notes
fi

if [ ! -f "$pdf" ]; then
  echo "error: $(basename "$pdf") not built yet — run 'make' first" >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "error: node not found (need >= 23.6 for TypeScript type stripping)" >&2
  exit 1
fi

if [ ! -d "$CACHE/.git" ]; then
  echo "==> first run: caching $REPO in $CACHE"
  git clone --depth 1 "$REPO" "$CACHE"
else
  git -C "$CACHE" pull --quiet --ff-only || echo "warning: could not refresh $CACHE, using cached copy"
fi

built_from="$CACHE/dist/.built-from"
head_sha="$(git -C "$CACHE" rev-parse HEAD 2>/dev/null || echo unknown)"
if [ ! -f "$CACHE/dist/index.html" ] || [ "$(cat "$built_from" 2>/dev/null || true)" != "$head_sha" ]; then
  if command -v pnpm >/dev/null 2>&1; then pm=pnpm; elif command -v npm >/dev/null 2>&1; then pm=npm; else pm=""; fi
  if [ -n "$pm" ]; then
    echo "==> building offline console ($pm)"
    "$pm" --dir "$CACHE" install >/dev/null 2>&1 || true
    if "$pm" --dir "$CACHE" run build >/dev/null 2>&1; then
      echo "$head_sha" > "$built_from"
    fi
  fi
fi

TOKEN="$CACHE/dist/reload-token.txt"
if [ -f "$CACHE/dist/index.html" ] && ! grep -q pdfpc-acad-reloader "$CACHE/dist/index.html"; then
  python3 - "$CACHE/dist/index.html" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
html = p.read_text()
snippet = """<script data-pdfpc-acad-reloader>
(() => {
  let seen = null;
  setInterval(async () => {
    try {
      const r = await fetch('/reload-token.txt?' + Date.now(), { cache: 'no-store' });
      if (!r.ok) { seen = null; return; }
      const v = (await r.text()).trim();
      if (seen === null) { seen = v; return; }
      if (v !== seen) location.reload();
    } catch {}
  }, 1000);
})();
</script>
</body>"""
if "</body>" in html:
    p.write_text(html.replace("</body>", snippet, 1))
PY
fi

mtime_of() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0; }
watcher=""
if [ "$watch" = 1 ] && [ -f "$CACHE/dist/index.html" ]; then
  mtime_of "$pdf" > "$TOKEN"
  (
    last="$(cat "$TOKEN")"
    while :; do
      cur="$(mtime_of "$pdf")"
      if [ "$cur" != "$last" ]; then
        sleep 0.5
        cur="$(mtime_of "$pdf")"
        echo "$cur" > "$TOKEN"
        echo "==> deck changed — reloading presenter window"
        last="$cur"
      fi
      sleep 1
    done
  ) &
  watcher=$!
else
  rm -f "$TOKEN"
fi

shim=""
if [ "$browser" = safari ]; then
  shim="$(mktemp -t pdfpc-safari-shim)"
  cat > "$shim" <<'SHIM'
#!/bin/sh
url=""
for a in "$@"; do
  case "$a" in
    --app=*) url="${a#--app=}" ;;
    http://*|https://*) url="$a" ;;
  esac
done
if [ -n "$url" ]; then
  osascript -e 'on run {u}
    tell application "Safari"
      make new document with properties {URL:u}
      activate
    end tell
  end run' "$url" >/dev/null 2>&1 || open -a Safari "$url"
fi
exec sleep 2147483647
SHIM
  chmod +x "$shim"
  passthrough+=(--chrome "$shim")
fi

cleanup() {
  [ -n "$watcher" ] && kill "$watcher" 2>/dev/null || true
  [ -n "$shim" ] && rm -f "$shim" || true
  rm -f "$TOKEN" || true
}
trap cleanup EXIT INT TERM

echo "==> $(basename "$pdf")  [$layout]  [$browser]"
exec node "$CACHE/cli.ts" "$layout" ${passthrough[@]+"${passthrough[@]}"} "$pdf"
