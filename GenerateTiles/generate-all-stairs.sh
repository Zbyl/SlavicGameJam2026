#!/usr/bin/env bash
set -euo pipefail

# Run from the directory containing this script, so it also works when
# launched from Git Bash with another current working directory.
cd "$(dirname "$0")"

MOD=1
PREFIX="tile"$MOD
COLORS=( "96dcaa"  "927b66"  "ec9a4e" )
COLOR=${COLORS[(($MOD-1))]}

SHAPES=(
  stairs-x0
  stairs-x1
  stairs-y0
  stairs-y1
  short-stairs-x0
  short-stairs-x1
  short-stairs-y0
  short-stairs-y1
  up-stairs-x0
  up-stairs-x1
  up-stairs-y0
  up-stairs-y1
  up-short-stairs-x0
  up-short-stairs-x1
  up-short-stairs-y0
  up-short-stairs-y1
)

# Common settings for the whole tileset. Edit these as desired.
COMMON_OPTIONS=(
    --prefix $PREFIX
    --color $COLOR
    --camera-rotation 35
    --camera-elevation 45
    --tile-width 64
    --tile-height 64
    --box-size 16
    --box-height 16
    --edge-width 1
    --scale 2
    --aa 2
)

for shape in "${SHAPES[@]}"; do
    py generate-stairs.py \
        --shape "$shape" \
        "${COMMON_OPTIONS[@]}"
done
