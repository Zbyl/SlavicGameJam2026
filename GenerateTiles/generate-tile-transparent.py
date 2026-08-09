#!/usr/bin/env python3

from PIL import Image, ImageDraw
import argparse
import colorsys
import math
import os
import random

try:
    import numpy as np
except ImportError:
    np = None


# ----------------------------------------------------------------------
# Defaults
# ----------------------------------------------------------------------
DIR = "tiles"
TILE_WIDTH = 40
TILE_HEIGHT = 40

BOX_SIZE = TILE_WIDTH / math.sqrt(2)
BOX_HEIGHT = BOX_SIZE * math.sqrt(3) * 0.5 * 0.95

SHAPE = "box"
PREFIX = "tile"

CAMERA_ROTATION = 45.0
CAMERA_ELEVATION = 30.0

COLOR = (150, 220, 170)

TOP_BRIGHTNESS = 1.00
LEFT_BRIGHTNESS = 0.82
RIGHT_BRIGHTNESS = 0.65
BOTTOM_BRIGHTNESS = 0.55
EDGE_BRIGHTNESS = 0.38

TOP_HUE_SHIFT = 0.0
LEFT_HUE_SHIFT = -2.0
RIGHT_HUE_SHIFT = 3.0
BOTTOM_HUE_SHIFT = 0.0
EDGE_HUE_SHIFT = 0.0

EDGE_WIDTH = 0.5

ALPHA = 255

SCALE = 2
AA = 2


SHAPES = (
    "box",
    "half",
    "up-half",
    "slope-x0",
    "slope-x1",
    "slope-y0",
    "slope-y1",
    "up-slope-x0",
    "up-slope-x1",
    "up-slope-y0",
    "up-slope-y1",
    "barely-slope-x0",
    "barely-slope-x1",
    "barely-slope-y0",
    "barely-slope-y1",
)


# ----------------------------------------------------------------------
# Command line
# ----------------------------------------------------------------------

def parse_color(value):
    """Accept #RRGGBB, RRGGBB, or R,G,B."""
    text = value.strip()

    if text.startswith("#"):
        text = text[1:]

    if "," in text:
        try:
            parts = tuple(int(x.strip()) for x in text.split(","))
        except ValueError as exc:
            raise argparse.ArgumentTypeError(
                "color must be #RRGGBB, RRGGBB, or R,G,B"
            ) from exc

        if len(parts) != 3 or any(x < 0 or x > 255 for x in parts):
            raise argparse.ArgumentTypeError(
                "R,G,B components must each be in the range 0..255"
            )
        return parts

    if len(text) == 6:
        try:
            return tuple(int(text[i:i + 2], 16) for i in (0, 2, 4))
        except ValueError:
            pass

    raise argparse.ArgumentTypeError(
        "color must be #RRGGBB, RRGGBB, or R,G,B"
    )


def positive_int(value):
    value = int(value)
    if value <= 0:
        raise argparse.ArgumentTypeError("must be greater than zero")
    return value


def positive_float(value):
    value = float(value)
    if value <= 0:
        raise argparse.ArgumentTypeError("must be greater than zero")
    return value


def nonnegative_float(value):
    value = float(value)
    if value < 0:
        raise argparse.ArgumentTypeError("must be zero or greater")
    return value


def alpha_value(value):
    value = int(value)
    if not 0 <= value <= 255:
        raise argparse.ArgumentTypeError("alpha must be in the range 0..255")
    return value


def fraction_value(value):
    value = float(value)
    if not 0.0 <= value <= 1.0:
        raise argparse.ArgumentTypeError("must be in the range 0..1")
    return value


def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate an orthographic isometric-style PNG tile."
    )

    parser.add_argument(
        "-t", "--shape",
        choices=SHAPES,
        default=SHAPE,
        help=f"shape to generate (default: {SHAPE})",
    )
    parser.add_argument(
        "-o", "--output",
        help="output PNG filename; default is PREFIX-SHAPE.png",
    )
    parser.add_argument(
        "-d", "--dir",
        default=DIR,
        help=f"directory for the output PNG file (default is \"{DIR}\")",
    )
    parser.add_argument(
        "-p", "--prefix",
        default=PREFIX,
        help=f"output prefix when --output is omitted (default: {PREFIX})",
    )

    parser.add_argument("--tile-width", type=positive_int, default=TILE_WIDTH)
    parser.add_argument("--tile-height", type=positive_int, default=TILE_HEIGHT)
    parser.add_argument("--box-size", type=positive_float, default=BOX_SIZE)
    parser.add_argument("--box-height", type=positive_float, default=BOX_HEIGHT)

    parser.add_argument(
        "--camera-rotation", "--rotation",
        dest="camera_rotation",
        type=float,
        default=CAMERA_ROTATION,
        help=f"camera azimuth in degrees (default: {CAMERA_ROTATION})",
    )
    parser.add_argument(
        "--camera-elevation", "--elevation",
        dest="camera_elevation",
        type=float,
        default=CAMERA_ELEVATION,
        help=f"camera elevation above horizontal in degrees (default: {CAMERA_ELEVATION})",
    )

    parser.add_argument(
        "-c", "--color",
        type=parse_color,
        default=COLOR,
        metavar="COLOR",
        help="base color as #RRGGBB, RRGGBB, or R,G,B",
    )

    parser.add_argument("--top-brightness", type=nonnegative_float, default=TOP_BRIGHTNESS)
    parser.add_argument("--left-brightness", type=nonnegative_float, default=LEFT_BRIGHTNESS)
    parser.add_argument("--right-brightness", type=nonnegative_float, default=RIGHT_BRIGHTNESS)
    parser.add_argument("--bottom-brightness", type=nonnegative_float, default=BOTTOM_BRIGHTNESS)
    parser.add_argument("--edge-brightness", type=nonnegative_float, default=EDGE_BRIGHTNESS)

    parser.add_argument("--top-hue-shift", type=float, default=TOP_HUE_SHIFT)
    parser.add_argument("--left-hue-shift", type=float, default=LEFT_HUE_SHIFT)
    parser.add_argument("--right-hue-shift", type=float, default=RIGHT_HUE_SHIFT)
    parser.add_argument("--bottom-hue-shift", type=float, default=BOTTOM_HUE_SHIFT)
    parser.add_argument("--edge-hue-shift", type=float, default=EDGE_HUE_SHIFT)

    parser.add_argument("--edge-width", type=nonnegative_float, default=EDGE_WIDTH)
    parser.add_argument("--scale", type=positive_int, default=SCALE)
    parser.add_argument("--aa", type=positive_int, default=AA, help="supersampling factor")

    parser.add_argument(
        "-a", "--alpha",
        type=alpha_value,
        default=ALPHA,
        help="alpha (0-255) applied to every face and edge, for a glass/translucent "
             "look (default: opaque, 255)",
    )
    parser.add_argument(
        "-m", "--mask",
        default=None,
        help="pattern applied to every face: either a path to an image file "
             "(alpha or luminance is thresholded, one cell per pixel) or an "
             "inline pattern of rows separated by '/', e.g. 'x.x/.x./x.x'. "
             "In a cell, space/'.'/'0' means fully transparent, anything else "
             "means the face is drawn there using --alpha. Faces are always "
             "drawn solid (as if unmasked) when --mask is omitted.",
    )
    parser.add_argument(
        "--mask-invert",
        action="store_true",
        help="invert the mask (swap transparent/opaque cells)",
    )
    parser.add_argument(
        "--mask-random",
        type=fraction_value,
        default=None,
        metavar="FILL",
        help="generate a random mask instead of reading --mask; FILL is 0..1, "
             "the fraction of cells left opaque (0 = fully transparent tile, "
             "1 = fully solid). Cannot be combined with --mask.",
    )
    parser.add_argument(
        "--mask-random-size",
        type=positive_int,
        default=14,
        help="grid resolution (NxN) used by --mask-random (default: 14)",
    )
    parser.add_argument(
        "--mask-random-seed",
        type=int,
        default=None,
        help="seed for --mask-random, so the same pattern can be reproduced "
             "(default: a different random pattern every run)",
    )

    args = parser.parse_args()

    if args.mask is not None and args.mask_random is not None:
        parser.error("--mask and --mask-random cannot be used together")

    return args


# ----------------------------------------------------------------------
# Shape definitions
# ----------------------------------------------------------------------

def get_heights(shape):
    """
    Return (bottom, top) height fractions at each corner.

          +Y

      01 -------- 11
      |            |
      |            |
      |            |
      00 -------- 10      +X

    slope-x1 means the ordinary/lower wedge slopes down toward x=1.
    up-slope-x1 is its complementary upper wedge.
    """

    shapes = {
        "box": {
            "00": (0, 1), "10": (0, 1), "11": (0, 1), "01": (0, 1),
        },
        "half": {
            "00": (0, 0.5), "10": (0, 0.5), "11": (0, 0.5), "01": (0, 0.5),
        },
        "up-half": {
            "00": (0.5, 1), "10": (0.5, 1), "11": (0.5, 1), "01": (0.5, 1),
        },

        "slope-x1": {
            "00": (0, 1), "10": (0, 0), "11": (0, 0), "01": (0, 1),
        },
        "slope-x0": {
            "00": (0, 0), "10": (0, 1), "11": (0, 1), "01": (0, 0),
        },
        "slope-y1": {
            "00": (0, 1), "10": (0, 1), "11": (0, 0), "01": (0, 0),
        },
        "slope-y0": {
            "00": (0, 0), "10": (0, 0), "11": (0, 1), "01": (0, 1),
        },

        # Complement of the corresponding ordinary/lower slope.
        "up-slope-x1": {
            "00": (1, 1), "10": (0, 1), "11": (0, 1), "01": (1, 1),
        },
        "up-slope-x0": {
            "00": (0, 1), "10": (1, 1), "11": (1, 1), "01": (0, 1),
        },
        "up-slope-y1": {
            "00": (1, 1), "10": (1, 1), "11": (0, 1), "01": (0, 1),
        },
        "up-slope-y0": {
            "00": (0, 1), "10": (0, 1), "11": (1, 1), "01": (1, 1),
        },
        
        "barely-slope-x1": {
            "00": (0, 1), "10": (0, 0.7), "11": (0, 0.7), "01": (0, 1),
        },
        "barely-slope-x0": {
            "00": (0, 0.7), "10": (0, 1), "11": (0, 1), "01": (0, 0.7),
        },
        "barely-slope-y1": {
            "00": (0, 1), "10": (0, 1), "11": (0, 0.7), "01": (0, 0.7),
        },
        "barely-slope-y0": {
            "00": (0, 0.7), "10": (0, 0.7), "11": (0, 1), "01": (0, 1),
        },        
    }

    return shapes[shape]


# ----------------------------------------------------------------------
# Color manipulation
# ----------------------------------------------------------------------

def modify_color(color, brightness=1.0, hue_shift=0.0):
    r, g, b = [c / 255.0 for c in color]
    hue, saturation, value = colorsys.rgb_to_hsv(r, g, b)

    hue = (hue + hue_shift / 360.0) % 1.0
    value = max(0.0, min(1.0, value * brightness))

    r, g, b = colorsys.hsv_to_rgb(hue, saturation, value)

    return (
        round(r * 255),
        round(g * 255),
        round(b * 255),
        255,
    )


# ----------------------------------------------------------------------
# Mask handling
# ----------------------------------------------------------------------
#
# A mask is a small boolean grid ("x" = draw, " " = fully transparent) that
# gets stamped onto every visible face, independently, in that face's own
# 0..1 x 0..1 local coordinate space. Cell (0, 0) of the grid corresponds to
# the "start" corner of the face (names[0] in face_specs) and the grid reads
# left-to-right, top-to-bottom the way you'd type it.

def load_mask(spec, invert=False):
    if spec is None:
        return None

    if os.path.isfile(spec):
        img = Image.open(spec)
        bands = img.getbands()
        if "A" in bands:
            band = img.split()[bands.index("A")]
        else:
            band = img.convert("L")
        width, height = band.size
        pixels = band.load()
        grid = [
            [pixels[col, row] >= 128 for col in range(width)]
            for row in range(height)
        ]
    else:
        rows = [row for row in spec.split("/") if row != ""]
        if not rows:
            raise argparse.ArgumentTypeError("mask pattern is empty")
        if len({len(row) for row in rows}) != 1:
            raise argparse.ArgumentTypeError(
                "mask pattern rows must all have the same length"
            )
        grid = [[ch not in (" ", ".", "0") for ch in row] for row in rows]

    if invert:
        grid = [[not cell for cell in row] for row in grid]

    return grid


def generate_random_mask(size, fill, seed=None, invert=False):
    """Independent per-cell coin flip, each cell opaque with probability fill."""

    rng = random.Random(seed)
    grid = [[rng.random() < fill for _ in range(size)] for _ in range(size)]

    if invert:
        grid = [[not cell for cell in row] for row in grid]

    return grid


def sample_mask(grid, u, v):
    """Look up a mask cell for local face coordinates u, v in [0, 1].

    v follows the same "up" direction as the UV square assigned to the face
    (see uv_for_face below); row 0 of the grid is the top of the pattern as
    typed, so it is matched against v close to 1.
    """

    rows = len(grid)
    cols = len(grid[0])

    col = min(cols - 1, max(0, int(u * cols)))
    row = min(rows - 1, max(0, int((1.0 - v) * rows)))

    return grid[row][col]


# ----------------------------------------------------------------------
# Vector/projection helpers
# ----------------------------------------------------------------------

def project(point, azimuth_deg, elevation_deg):
    x, y, z = point

    az = math.radians(azimuth_deg)
    el = math.radians(elevation_deg)

    sx = -x * math.sin(az) + y * math.cos(az)
    sy = (
        -x * math.cos(az) * math.sin(el)
        - y * math.sin(az) * math.sin(el)
        + z * math.cos(el)
    )

    return sx, -sy


def sub(a, b):
    return tuple(x - y for x, y in zip(a, b))


def cross(a, b):
    return (
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    )


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def face_normal(vertex_names, vertices):
    p0 = vertices[vertex_names[0]]

    # Find two non-collinear edges. This also handles degenerate ramp faces.
    for i in range(1, len(vertex_names) - 1):
        a = sub(vertices[vertex_names[i]], p0)
        b = sub(vertices[vertex_names[i + 1]], p0)
        n = cross(a, b)
        if dot(n, n) > 1e-12:
            return n

    return (0.0, 0.0, 0.0)


def average_depth(vertex_names, vertices, camera_vector):
    return sum(dot(vertices[name], camera_vector) for name in vertex_names) / len(vertex_names)


def point_in_polygon(point, polygon):
    """Standard ray-casting point-in-polygon test."""

    x, y = point
    inside = False
    n = len(polygon)

    for i in range(n):
        x1, y1 = polygon[i]
        x2, y2 = polygon[(i + 1) % n]

        if (y1 > y) != (y2 > y):
            x_at_y = x1 + (y - y1) * (x2 - x1) / (y2 - y1)
            if x < x_at_y:
                inside = not inside

    return inside


def invert_bilinear(point, p00, p10, p11, p01):
    """Given a point inside quad p00-p10-p11-p01, return its (u, v) in the
    unit square, where p00 -> (0,0), p10 -> (1,0), p11 -> (1,1), p01 -> (0,1).

    Works for any convex (and most non-convex) quad, not just parallelograms,
    which is what lets us texture the slanted ramp faces the same way as the
    axis-aligned top/bottom faces.
    """

    def cross2(a, b):
        return a[0] * b[1] - a[1] * b[0]

    e = sub2(p10, p00)
    f = sub2(p01, p00)
    g = add2(sub2(p00, p10), sub2(p11, p01))
    h = sub2(point, p00)

    k2 = cross2(g, f)
    k1 = cross2(e, f) + cross2(h, g)
    k0 = cross2(h, e)

    if abs(k2) < 1e-9:
        v = -k0 / k1 if abs(k1) > 1e-9 else 0.0
    else:
        discriminant = k1 * k1 - 4 * k0 * k2
        if discriminant < 0:
            discriminant = 0
        root = math.sqrt(discriminant)
        v1 = (-k1 + root) / (2 * k2)
        v2 = (-k1 - root) / (2 * k2)
        v = v1 if 0 <= v1 <= 1 else v2

    denom_x = e[0] + g[0] * v
    if abs(denom_x) > 1e-9:
        u = (h[0] - f[0] * v) / denom_x
    else:
        denom_y = e[1] + g[1] * v
        u = (h[1] - f[1] * v) / denom_y if abs(denom_y) > 1e-9 else 0.0

    return u, v


def sub2(a, b):
    return (a[0] - b[0], a[1] - b[1])


def add2(a, b):
    return (a[0] + b[0], a[1] + b[1])


def resize_with_premultiplied_alpha(image, size):
    """Downscale an RGBA image without dark fringes at transparent edges.

    Plain LANCZOS resizing of RGBA blends fully-transparent (0,0,0,0) pixels
    into their opaque neighbours, which darkens edges. Premultiplying by
    alpha before resizing (and dividing it back out afterward) fixes this.
    Falls back to a plain resize if numpy isn't available.
    """

    if np is None:
        return image.resize(size, Image.Resampling.LANCZOS)

    arr = np.asarray(image).astype(np.float32)
    rgb, alpha = arr[..., :3], arr[..., 3:4]

    premultiplied = np.concatenate([rgb * (alpha / 255.0), alpha], axis=-1)
    pre_image = Image.fromarray(premultiplied.astype(np.uint8), "RGBA")
    resized = pre_image.resize(size, Image.Resampling.LANCZOS)

    arr2 = np.asarray(resized).astype(np.float32)
    rgb2, alpha2 = arr2[..., :3], arr2[..., 3:4]
    safe_alpha = np.where(alpha2 == 0, 1.0, alpha2)
    unpremultiplied = np.clip(rgb2 / (safe_alpha / 255.0), 0, 255)

    final = np.concatenate([unpremultiplied, alpha2], axis=-1).astype(np.uint8)
    return Image.fromarray(final, "RGBA")


# ----------------------------------------------------------------------
# Main generator
# ----------------------------------------------------------------------

def main():
    args = parse_args()

    output = args.output or f"{args.prefix}-{args.shape}.png"
    directory = args.dir

    def with_alpha(color):
        return (color[0], color[1], color[2], args.alpha)

    top_color = with_alpha(modify_color(args.color, args.top_brightness, args.top_hue_shift))
    left_color = with_alpha(modify_color(args.color, args.left_brightness, args.left_hue_shift))
    right_color = with_alpha(modify_color(args.color, args.right_brightness, args.right_hue_shift))
    bottom_color = with_alpha(modify_color(args.color, args.bottom_brightness, args.bottom_hue_shift))
    edge_color = with_alpha(modify_color(args.color, args.edge_brightness, args.edge_hue_shift))

    if args.mask_random is not None:
        mask_grid = generate_random_mask(
            args.mask_random_size,
            args.mask_random,
            args.mask_random_seed,
            args.mask_invert,
        )
    else:
        mask_grid = load_mask(args.mask, args.mask_invert)

    s = args.box_size
    h = args.box_height
    heights = get_heights(args.shape)

    bottom = {corner: value[0] * h for corner, value in heights.items()}
    top = {corner: value[1] * h for corner, value in heights.items()}

    for corner in ("00", "10", "11", "01"):
        if bottom[corner] > top[corner]:
            raise ValueError(
                f"Bottom is above top at corner {corner}: "
                f"{bottom[corner]} > {top[corner]}"
            )

    vertices = {
        "b00": (0, 0, bottom["00"]),
        "b10": (s, 0, bottom["10"]),
        "b11": (s, s, bottom["11"]),
        "b01": (0, s, bottom["01"]),

        "t00": (0, 0, top["00"]),
        "t10": (s, 0, top["10"]),
        "t11": (s, s, top["11"]),
        "t01": (0, s, top["01"]),
    }

    projected = {
        name: project(point, args.camera_rotation, args.camera_elevation)
        for name, point in vertices.items()
    }

    az = math.radians(args.camera_rotation)
    el = math.radians(args.camera_elevation)

    # Vector from the object toward the camera.
    camera_vector = (
        math.cos(az) * math.cos(el),
        math.sin(az) * math.cos(el),
        math.sin(el),
    )

    ground_center = (s / 2, s / 2, 0)
    projected_ground_center = project(
        ground_center,
        args.camera_rotation,
        args.camera_elevation,
    )
    
    vertical_offset = (
        args.box_height / 2
        * math.cos(math.radians(args.camera_elevation))
    )

    def screen_point(p):
        x, y = p

        return (
            args.tile_width / 2
            + x
            - projected_ground_center[0],
    
            args.tile_height / 2
            + vertical_offset
            + y
            - projected_ground_center[1],
        )
   
    def aa_point(p):
        x, y = screen_point(p)
        return (
            round(x * args.scale * args.aa),
            round(y * args.scale * args.aa),
        )

    def polygon_area(points):
        area = 0.0
        for i in range(len(points)):
            x1, y1 = points[i]
            x2, y2 = points[(i + 1) % len(points)]
            area += x1 * y2 - x2 * y1
        return abs(area) / 2

    # Winding is outward-facing in 3-D.
    face_specs = [
        ("x0", ["b00", "t00", "t01", "b01"]),
        ("x1", ["b10", "b11", "t11", "t10"]),
        ("y0", ["b00", "b10", "t10", "t00"]),
        ("y1", ["b01", "t01", "t11", "b11"]),
        ("top", ["t00", "t10", "t11", "t01"]),
        ("bottom", ["b00", "b01", "b11", "b10"]),
    ]

    visible_faces = []

    for kind, names in face_specs:
        normal = face_normal(names, vertices)

        # Back-face culling.
        if dot(normal, camera_vector) <= 1e-10:
            continue

        polygon = [aa_point(projected[name]) for name in names]
        if polygon_area(polygon) <= 0.5:
            continue

        if kind == "top":
            color = top_color
        elif kind == "bottom":
            color = bottom_color
        else:
            # Choose left/right shading based on where the side appears on screen.
            mean_x = sum(projected[name][0] for name in names) / len(names)
            color = left_color if mean_x < projected_ground_center[0] else right_color

        visible_faces.append({
            "kind": kind,
            "names": names,
            "polygon": polygon,
            "color": color,
            "depth": average_depth(names, vertices, camera_vector),
        })

    # Painter's algorithm: far faces first, near faces last.
    visible_faces.sort(key=lambda face: face["depth"])

    image = Image.new(
        "RGBA",
        (
            args.tile_width * args.scale * args.aa,
            args.tile_height * args.scale * args.aa,
        ),
        (0, 0, 0, 0),
    )
    draw = ImageDraw.Draw(image)

    for face in visible_faces:
        if mask_grid is None:
            draw.polygon(face["polygon"], fill=face["color"])
            continue

        # p00, p10, p11, p01 corners of the face's local UV square, in the
        # same cyclic order as face["names"] / face["polygon"].
        p00, p10, p11, p01 = face["polygon"]
        color = face["color"]

        xs = [p[0] for p in face["polygon"]]
        ys = [p[1] for p in face["polygon"]]
        min_x, max_x = max(0, min(xs)), min(image.width - 1, max(xs))
        min_y, max_y = max(0, min(ys)), min(image.height - 1, max(ys))

        for py in range(int(min_y), int(max_y) + 1):
            for px in range(int(min_x), int(max_x) + 1):
                point = (px + 0.5, py + 0.5)
                if not point_in_polygon(point, face["polygon"]):
                    continue

                u, v = invert_bilinear(point, p00, p10, p11, p01)
                if not sample_mask(mask_grid, u, v):
                    continue

                draw.point((px, py), fill=color)

    # Draw every boundary edge of every visible face once.
    visible_edges = set()
    for face in visible_faces:
        names = face["names"]
        for i in range(len(names)):
            a = names[i]
            b = names[(i + 1) % len(names)]
            visible_edges.add(tuple(sorted((a, b))))

    if args.edge_width > 0:
        edge_width_aa = max(1, round(args.edge_width * args.aa))

        for a, b in visible_edges:
            p1 = aa_point(projected[a])
            p2 = aa_point(projected[b])
            if p1 == p2:
                continue
            draw.line([p1, p2], fill=edge_color, width=edge_width_aa)

    image = resize_with_premultiplied_alpha(
        image,
        (
            args.tile_width * args.scale,
            args.tile_height * args.scale,
        ),
    )

    image.save(os.path.join(directory, output))

    print(
        f"Saved {os.path.join(directory, output)}: "
        f"{args.tile_width * args.scale} x "
        f"{args.tile_height * args.scale} "
        f"({args.shape})"
    )


if __name__ == "__main__":
    main()
