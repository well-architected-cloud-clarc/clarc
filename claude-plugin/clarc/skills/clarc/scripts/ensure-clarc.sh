#!/usr/bin/env bash
# Print the path of a runnable clarc: PATH first, else the cached download, else fetch the rolling `latest` release.
set -euo pipefail
repo=well-architected-cloud-clarc/clarc
dest="${CLARC_HOME:-$HOME/.local/share/clarc}"

if command -v clarc >/dev/null; then command -v clarc; exit 0; fi
[ ! -x "$dest/clarc" ] || { echo "$dest/clarc"; exit 0; }

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) target=x86_64-unknown-linux-gnu; ext=tar.gz ;;
  Linux-aarch64|Linux-arm64) target=aarch64-unknown-linux-gnu; ext=tar.gz ;;
  Darwin-arm64) target=aarch64-apple-darwin; ext=tar.gz ;;
  Darwin-x86_64) target=x86_64-apple-darwin; ext=tar.gz ;;
  MINGW*|MSYS*|CYGWIN*) target=x86_64-pc-windows-gnu; ext=zip ;;
  *) echo "no clarc release for $(uname -s)-$(uname -m)" >&2; exit 1 ;;
esac

base="https://github.com/$repo/releases/download/latest"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
curl -fsSL "$base/SHA256SUMS" -o "$tmp/SHA256SUMS"
file=$(awk -v t="-$target.$ext" 'index($2, t) { print $2 }' "$tmp/SHA256SUMS" | head -n1)
[ -n "$file" ] || { echo "no asset for $target in SHA256SUMS" >&2; exit 1; }
curl -fsSL "$base/$file" -o "$tmp/$file"
(cd "$tmp" && grep " $file\$" SHA256SUMS | { sha256sum -c - 2>/dev/null || shasum -a 256 -c -; } >&2)

case "$ext" in
  zip) unzip -q "$tmp/$file" -d "$tmp/x" ;;
  *) mkdir "$tmp/x" && tar xzf "$tmp/$file" -C "$tmp/x" ;;
esac
mkdir -p "$dest"
cp "$tmp"/x/*/clarc* "$dest/"
chmod +x "$dest"/clarc*
ls "$dest"/clarc* | head -n1
