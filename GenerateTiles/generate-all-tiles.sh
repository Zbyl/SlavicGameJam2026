#!/usr/bin/env bash
set -euo pipefail

# Run from the directory containing this script
cd "$(dirname "$0")"

# Define the color palette array
COLORS=(
#  "96dcaa" "927b66" "ec9a4e" "d1cdc5"  # Original set
#  "c96a63" "d4a3a3" "7e9cb4" "8c7da1"  # Red, Pink, Blue, Violet
#  "dbb568" "e0cbac" "a5a5a5" 
#  "777777" "4a4a4a"  # Mustard & Straw Yellow
# more vibrant
#"72dfa0" "a87952" "f49a37" "d1cdc5"
#"dc5f57" "e39aab" "689fc8" "9674b7"
#"e8b94e" "e8c891" "a5a5a5" 
#"777777" "4a4a4a"
# new g
# "72dfa0" "a87952" "f49a37" "d1cdc5"
#  "768972" "b0c2a5" "cbd5b9" # Extra Greens
#  "5d4b3e" "bba58f"          # Extra Browns
#  "decda9" "eae2ca"          # Sands
#  "6b7074" "9ca2a6"          # Extra Grays
#  "b1634b" "dbb568"          # Extra Autumn
# Leaves
"#2F4A24" "#4A7C3A" "#6E8F4E" "#9BB26B" 
# Earth 
"#4A3728" "#6B4A2E" "#8B5A2B" 
# Sand 
"#D9C89E" "#C2A876" 
#Stone 
"#4A4A4A" "#7D7D7D" "#B0B0B0" 
# Autumn 
"#D9A521" "#C1620E" "#A8471E" "#7A2E1E"
)

# Dynamically count the number of colors in the array
NUM_COLORS=${#COLORS[@]}

echo "Starting generation for $NUM_COLORS color sets..."
echo "----------------------------------------"

# Loop N from 1 to the total number of colors
for (( N=1; N<=NUM_COLORS; N++ )); do
    # Map N (1-based) to the array index (0-based)
    COLOR_IDX=$(( N - 1 ))
    COL=${COLORS[$COLOR_IDX]}

    echo "Processing Set #$N with color #$COL..."

    # Check if generator scripts exist and are executable before running
    if [[ -x "./generate-tiles-set.sh" && -x "./generate-stairs-set.sh" ]]; then
        ./generate-tiles-set.sh "$N" "$COL"
        ./generate-stairs-set.sh "$N" "$COL"
        ./generate-leaves-set.sh "$N" "$COL" 170
        ./generate-leaves-set.sh "$N" "$COL" 210
        ./generate-poles-set.sh "$N" "$COL"
    else
        echo "Error: Verification failed. Ensure generator scripts are in this folder and executable (chmod +x)."
        exit 1
    fi
    
    echo "Set #$N finished successfully."
    echo "----------------------------------------"
done

echo "All generation tasks completed!"
exit 0
