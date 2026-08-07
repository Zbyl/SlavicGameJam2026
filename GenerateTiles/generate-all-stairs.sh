#!/usr/bin/env bash
set -euo pipefail

# Run from the directory containing this script, so it also works when
# launched from Git Bash with another current working directory.
cd "$(dirname "$0")"

MOD=5
PREFIX="tile"$MOD
COLORS=( "96dcaa" "927b66" "ec9a4e" "d1cdc5"  # 
         "c96a63" "d4a3a3" "7e9cb4" "8c7da1"  # Red, Pink, Blue, Violet
         "dbb568" "e0cbac"                    # Mustard & Straw Yellow
       )

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
    --camera-rotation 45
    --camera-elevation 30
    --edge-width 0.5
    --scale 2
    --aa 2
)

for shape in "${SHAPES[@]}"; do
    py generate-stairs.py \
        --shape "$shape" \
        "${COMMON_OPTIONS[@]}"
done
