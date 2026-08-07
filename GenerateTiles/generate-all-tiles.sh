#!/usr/bin/env bash
set -euo pipefail

# Run from the directory containing this script, so it also works when
# launched from Git Bash with another current working directory.
cd "$(dirname "$0")"

MOD=3
PREFIX="tile"$MOD
COLORS=( "96dcaa"  "927b66"  "ec9a4e" )
COLOR=${COLORS[(($MOD-1))]}

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
    py generate-tile.py \
        --shape "$shape" \
        "${COMMON_OPTIONS[@]}"
done
