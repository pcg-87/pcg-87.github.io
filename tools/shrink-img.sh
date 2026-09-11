#!/usr/bin/env bash
# Downscale and strip metadata from screenshots before committing them.
#
# Git keeps every version of every binary forever, so an oversized screenshot
# re-saved a few times bloats the repo permanently. Uses macOS's built-in
# `sips` -- nothing to install.
#
# Work happens on a temp copy and the original is replaced ONLY if the result
# is actually smaller. sips re-encodes PNGs, which can inflate an already
# well-compressed file, so "optimising" unconditionally would make things worse.
#
# Usage:  tools/shrink-img.sh [-w WIDTH] FILE [FILE...]
#         tools/shrink-img.sh assets/img/my-post/*.png

set -euo pipefail

WIDTH=1600
while getopts "w:h" opt; do
  case "$opt" in
    w) WIDTH="$OPTARG" ;;
    h) sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) exit 64 ;;
  esac
done
shift $((OPTIND - 1))

if [ "$#" -eq 0 ]; then
  echo "usage: $(basename "$0") [-w WIDTH] FILE [FILE...]" >&2
  exit 64
fi

command -v sips >/dev/null || { echo "sips not found (macOS only)" >&2; exit 1; }

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

total_before=0
total_after=0

for f in "$@"; do
  if [ ! -f "$f" ]; then
    echo "skip (not a file): $f" >&2
    continue
  fi

  case "${f##*.}" in
    png|PNG|jpg|JPG|jpeg|JPEG|tiff|TIFF) ;;
    svg|SVG) echo "skip (vector, already small): $f"; continue ;;
    *) echo "skip (unsupported type): $f" >&2; continue ;;
  esac

  before=$(stat -f%z "$f")
  work="$tmpdir/$(basename "$f")"
  cp "$f" "$work"

  cur_w=$(sips -g pixelWidth "$work" | awk '/pixelWidth/{print $2}')
  if [ "${cur_w:-0}" -gt "$WIDTH" ]; then
    sips --resampleWidth "$WIDTH" "$work" >/dev/null
  fi
  sips --deleteColorManagementProperties "$work" >/dev/null 2>&1 || true

  after=$(stat -f%z "$work")

  if [ "$after" -lt "$before" ]; then
    mv "$work" "$f"
    printf '%-50s %6sK -> %6sK\n' "$f" "$((before / 1024))" "$((after / 1024))"
  else
    after=$before
    printf '%-50s %6sK  (left alone; processing would not shrink it)\n' \
      "$f" "$((before / 1024))"
  fi

  total_before=$((total_before + before))
  total_after=$((total_after + after))
done

if [ "$total_before" -gt 0 ]; then
  saved=$(( (total_before - total_after) * 100 / total_before ))
  printf '\ntotal %sK -> %sK (%s%% smaller)\n' \
    "$((total_before / 1024))" "$((total_after / 1024))" "$saved"
fi
