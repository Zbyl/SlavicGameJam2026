#!/usr/bin/env bash
set -euo pipefail

# Run from the directory containing this script, so it also works when
# launched from Git Bash with another current working directory.
cd "$(dirname "$0")"

MOD=${1:-1}
COLOR=${2:-"96dcaa"}
PREFIX="tile"$MOD

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
    --edge-width 0.0
    --scale 2
    --aa 2
)

for shape in "${SHAPES[@]}"; do
    py generate-stairs.py \
        --shape "$shape" \
        "${COMMON_OPTIONS[@]}"
done
