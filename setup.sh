#!/usr/bin/env bash
#
# Set up a development machine to build an acad-deck presentation.
#
#   ./setup.sh              install what is missing, then verify
#   ./setup.sh --check      verify only, change nothing
#   ./setup.sh --build      install, verify, then run `make` once

set -euo pipefail

TYPST_VERSION="${TYPST_VERSION:-0.15.1}"
PREFIX="${PREFIX:-/usr/local}"
BIN="$PREFIX/bin"
FONTS=("Liberation Sans" "Liberation Mono" "Noto Sans CJK SC")

CHECK=0
BUILD=0
for arg in "$@"; do
  case "$arg" in
    --check) CHECK=1 ;;
    --build) BUILD=1 ;;
    -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf 'unknown argument: %s (try --help)\n' "$arg" >&2; exit 2 ;;
  esac
done

say()  { printf '==> %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }
die()  { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

typst_version() {
  have typst || return 0
  typst --version 2>/dev/null | awk '{print $2}'
}

missing_fonts() {
  have typst || { printf '%s\n' "${FONTS[@]}"; return 0; }
  local f listed
  listed="$(typst fonts 2>/dev/null)"
  for f in "${FONTS[@]}"; do
    grep -qix -- "$f" <<<"$listed" || printf '%s\n' "$f"
  done
}

install_typst() {
  if [ "$(typst_version)" = "$TYPST_VERSION" ]; then
    note "typst $TYPST_VERSION already installed"
    return
  fi
  have typst && note "replacing typst $(typst_version) with $TYPST_VERSION"

  case "$(uname -m)" in
    x86_64|aarch64) arch="$(uname -m)" ;;
    *) die "no prebuilt typst for $(uname -m); install $TYPST_VERSION manually" ;;
  esac

  local url="https://github.com/typst/typst/releases/download/v$TYPST_VERSION/typst-$arch-unknown-linux-musl.tar.xz"
  local tmp; tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  say "downloading typst $TYPST_VERSION ($arch)"
  curl -fsSL "$url" -o "$tmp/typst.tar.xz" || die "download failed: $url"
  tar -xf "$tmp/typst.tar.xz" -C "$tmp"

  mkdir -p "$BIN" 2>/dev/null || die "cannot create $BIN; re-run with PREFIX=~/.local"
  install -m755 "$tmp/typst-$arch-unknown-linux-musl/typst" "$BIN/typst" \
    || die "cannot write $BIN/typst; re-run with PREFIX=~/.local"
  note "installed $BIN/typst"
}

install_apt_packages() {
  local want=()
  have pdfinfo  || want+=(poppler-utils)
  have pdftoppm || want+=(poppler-utils)
  if [ -n "$(missing_fonts)" ]; then
    want+=(fonts-liberation2 fonts-noto-cjk)
  fi
  if [ ${#want[@]} -eq 0 ]; then
    note "poppler-utils and fonts already present"
    return
  fi
  if have apt-get; then
    say "installing apt packages: ${want[*]}"
    sudo apt-get update -qq && sudo apt-get install -y "${want[@]}"
  else
    die "missing ${want[*]}; please install via your OS package manager"
  fi
}

install_pymupdf() {
  if python3 -c "import pymupdf" 2>/dev/null; then
    note "pymupdf already installed"
    return
  fi
  say "installing pymupdf"
  python3 -m pip install --user pymupdf || die "pip install pymupdf failed"
}

verify() {
  local ok=1
  have typst || { note "MISSING: typst"; ok=0; }
  have pdfinfo || { note "MISSING: pdfinfo (poppler-utils)"; ok=0; }
  have pdftoppm || { note "MISSING: pdftoppm (poppler-utils)"; ok=0; }
  python3 -c "import pymupdf" 2>/dev/null || { note "MISSING: pymupdf"; ok=0; }
  local mf; mf="$(missing_fonts)"
  if [ -n "$mf" ]; then
    note "MISSING fonts: $(tr '\n' ', ' <<<"$mf" | sed 's/, $//')"
    ok=0
  fi
  [ "$ok" = 1 ] || die "check failed"
  say "all dependencies present (typst $(typst_version))"
}

if [ "$CHECK" = 1 ]; then
  verify
  exit 0
fi

install_typst
install_apt_packages
install_pymupdf
verify

if [ "$BUILD" = 1 ]; then
  make
fi
