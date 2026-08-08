#!/usr/bin/env bash
set -euo pipefail

# Run from the directory containing this script, so it also works when
# launched from Git Bash with another current working directory.
cd "$(dirname "$0")"

MOD=${1:-1}
COLOR=${2:-"#96dcaa"}
#COLOR="70,140,45"
ALPHA=${3:-200}
PREFIX="tile"$MOD"-leav"${ALPHA}

SHAPES=(
    box
    half
    up-half
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
    py generate-tile-transparent.py \
        --alpha $ALPHA \
        --mask "x.xxxx..xxx.xx/.x..x...xxxxxx/xxxx..xxxx..xx/..xxxxxxxx..xx/xxxx.xxxx.xxx./xxxx.xx..x.x../xxx..x.x.x.xx./x..x.xxx....x./x.xxxx..xxxx../...xx..x.xxxxx/xxx..xx.xx.xxx/xx.x.xxxxxx.xx/xx.xxxxxxx..xx/..xxxxx.xx...x" \
        --shape "$shape" \
        "${COMMON_OPTIONS[@]}"
done
