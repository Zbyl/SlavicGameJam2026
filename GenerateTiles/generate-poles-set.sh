#!/usr/bin/env bash
set -euo pipefail

# Run from the directory containing this script, so it also works when
# launched from Git Bash with another current working directory.
cd "$(dirname "$0")"

MOD=${1:-1}
COLOR=${2:-"#96dcaa"}
PREFIX="tile"$MOD

SHAPES=(
    #"pole1"
    #"pole2"
    #"pole3"
    #"pole4"
    #"pole5"
    #"pole6"
    #"mid-x"
    #"mid-y"
    #"midwall-x"
    #"midwall-y"
    #"midthick-x"
    #"midthick-y"
    #"half-x0"
    #"half-x1"
    #"half-y0"
    #"half-y1"
    #"wall-x0"
    #"wall-x1"
    #"wall-y0"
    #"wall-y1"
    #"thick-x0"
    #"thick-x1"
    #"thick-y0"
    #"thick-y1"
    thick-slope-x0
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
    py generate-pole.py \
        --shape "$shape" \
        "${COMMON_OPTIONS[@]}"
done
