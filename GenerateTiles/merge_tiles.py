import os
from PIL import Image

# --- CONFIGURATION ---
DIR="tiles"
TILE_SIZE = 80
N_SETS = 17  # Maximal number for N
ROW_LEN = 24  # Minimum row length (0 means it defaults to the longest list)
        
LIST1 = ["box", "half", "up-half", "slope-x0", "slope-x1", "slope-y0", "slope-y1", "up-slope-x0", "up-slope-x1", "up-slope-y0", "up-slope-y1", "leav170-box", "leav170-half", "leav170-up-half", "leav210-box", "leav210-half", "leav210-up-half", "pole1", "pole2", "pole3", "pole4", "pole5", "thick-x0", "thick-y0", "thick-x1", "thick-y1", "pole6", "midthick-x", "midthick-y"]
LIST2 = ["stairs-x0", "stairs-x1", "stairs-y0", "stairs-y1", "short-stairs-x0", "short-stairs-x1", "short-stairs-y0", "short-stairs-y1", "up-stairs-x0", "up-stairs-x1", "up-stairs-y0", "up-stairs-y1", "up-short-stairs-x0", "up-short-stairs-x1", "up-short-stairs-y0", "up-short-stairs-y1", "half-x0", "half-y0","half-x1", "half-y1", "wall-x0", "wall-y0", "wall-x1", "wall-y1", "mid-x", "mid-y", "midwall-x", "midwall-y"]
OUTPUT_FILE = "merge_tiles.png"
# ---------------------

# Calculate grid dimensions
max_list_len = max(len(LIST1), len(LIST2))
cols = max(max_list_len, ROW_LEN)
rows = N_SETS * 2  # Each N has 2 rows (one for LIST1, one for LIST2)

grid_width = cols * TILE_SIZE
grid_height = rows * TILE_SIZE

# Create a transparent background canvas
canvas = Image.new("RGBA", (grid_width, grid_height), (0, 0, 0, 0))

current_row = 0

# Loop through each set N from 1 to N_SETS
for n in range(1, N_SETS + 1):
    # Each set handles LIST1 then LIST2
    for current_list in [LIST1, LIST2]:
        for col_idx, item in enumerate(current_list):
            filename = os.path.join(DIR, f"tile{n}-{item}.png")

            if os.path.exists(filename):
                try:
                    with Image.open(filename) as img:
                        # Ensure the tile matches expected dimensions
                        if img.size != (TILE_SIZE, TILE_SIZE):
                            img = img.resize((TILE_SIZE, TILE_SIZE))

                        # Calculate coordinate positioning
                        x = col_idx * TILE_SIZE
                        y = current_row * TILE_SIZE

                        # Paste tile onto the transparent master canvas
                        canvas.paste(img, (x, y))
                except Exception as e:
                    print(f"Error processing {filename}: {e}")
            else:
                print(f"Warning: File not found: {filename}")

        current_row += 1

# Save the final consolidated asset sheet
canvas.save(OUTPUT_FILE)
print(f"Successfully generated sprite sheet: {OUTPUT_FILE} ({grid_width}x{grid_height} px)")
