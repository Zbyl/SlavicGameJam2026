#!/usr/bin/env bash
set -euo pipefail

# Run from the directory containing this script, so it also works when
# launched from Git Bash with another current working directory.
cd "$(dirname "$0")"

SHAPES=(
    box
    half
    up-half
    slope-x0
    slope-x1
    slope-y0
    slope-y1
    up-slope-x0
    up-slope-x1
    up-slope-y0
    up-slope-y1
)

# 1 --color "96dcaa"
# 2 --color "927b66"
# 3 --color "ec9a4e"

# Common settings for the whole tileset. Edit these as desired.
COMMON_OPTIONS=(
    --prefix tile3
    --color "ec9a4e"
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
    py generate-tile.py \
        --shape "$shape" \
        "${COMMON_OPTIONS[@]}"
done
