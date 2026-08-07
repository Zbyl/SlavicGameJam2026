#!/usr/bin/env python3

from PIL import Image, ImageDraw
import argparse
import colorsys
import math


# ----------------------------------------------------------------------
# Defaults -- copied from current generate-tile.py
# ----------------------------------------------------------------------
DIR = "tiles"
TILE_WIDTH = 40
TILE_HEIGHT = 40

BOX_SIZE = TILE_WIDTH / math.sqrt(2)
BOX_HEIGHT = BOX_SIZE * math.sqrt(3) * 0.5 * 0.95

SHAPE = "stairs-x1"
PREFIX = "tile"
NSTEPS = 4

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

SCALE = 2
AA = 2


SHAPES = tuple(
    f"{kind}-{direction}"
    for kind in ("stairs", "short-stairs", "up-stairs", "up-short-stairs")
    for direction in ("x0", "x1", "y0", "y1")
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


def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate an orthographic isometric-style staircase PNG tile."
    )

    parser.add_argument(
        "-t", "--shape", choices=SHAPES, default=SHAPE,
        help=f"stair shape to generate (default: {SHAPE})",
    )
    parser.add_argument(
        "-n", "--nsteps", type=positive_int, default=NSTEPS,
        help=f"number of stair treads (default: {NSTEPS})",
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
        "--camera-rotation", "--rotation", dest="camera_rotation",
        type=float, default=CAMERA_ROTATION,
        help=f"camera azimuth in degrees (default: {CAMERA_ROTATION})",
    )
    parser.add_argument(
        "--camera-elevation", "--elevation", dest="camera_elevation",
        type=float, default=CAMERA_ELEVATION,
        help=f"camera elevation above horizontal in degrees (default: {CAMERA_ELEVATION})",
    )

    parser.add_argument(
        "-c", "--color", type=parse_color, default=COLOR, metavar="COLOR",
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

    return parser.parse_args()


# ----------------------------------------------------------------------
# Color / projection helpers
# ----------------------------------------------------------------------

def modify_color(color, brightness=1.0, hue_shift=0.0):
    r, g, b = [c / 255.0 for c in color]
    hue, saturation, value = colorsys.rgb_to_hsv(r, g, b)
    hue = (hue + hue_shift / 360.0) % 1.0
    value = max(0.0, min(1.0, value * brightness))
    r, g, b = colorsys.hsv_to_rgb(hue, saturation, value)
    return round(r * 255), round(g * 255), round(b * 255), 255


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


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def average_depth(points, camera_vector):
    return sum(dot(p, camera_vector) for p in points) / len(points)


# ----------------------------------------------------------------------
# Stair profile
# ----------------------------------------------------------------------

def decode_shape(shape):
    """Return complementary, short, axis, low_end."""
    complementary = shape.startswith("up-")
    core = shape[3:] if complementary else shape

    short = core.startswith("short-")
    core = core[6:] if short else core

    direction = core.split("-", 1)[1]
    return complementary, short, direction[0], int(direction[1])


def stair_levels(nsteps, short):
    """Height fractions from low end toward high end."""
    if short:
        # First tread is exactly at z=0; last is below z=h.
        return [i / nsteps for i in range(nsteps)]
    # First tread is already elevated; last is exactly at z=h.
    return [(i + 1) / nsteps for i in range(nsteps)]


def world_levels(args):
    complementary, short, axis, low_end = decode_shape(args.shape)
    levels = stair_levels(args.nsteps, short)
    if low_end == 1:
        levels = list(reversed(levels))
    return complementary, short, axis, low_end, [v * args.box_height for v in levels]


# ----------------------------------------------------------------------
# Faces
# ----------------------------------------------------------------------

def build_faces(args):
    """
    Build the solid from simple rectangles.

    These rectangles exist only for filling/shading.  Their boundaries are
    NOT automatically rendered as edges, because the strip subdivision is
    not physical geometry.
    """
    complementary, short, axis, low_end, level_z = world_levels(args)
    s = args.box_size
    h = args.box_height
    n = args.nsteps
    ds = s / n

    faces = []

    def add(kind, points, normal, force_visible=False):
        faces.append({
            "kind": kind,
            "points": points,
            "normal": normal,
            "force_visible": force_visible,
        })

    # Staircase horizontal surfaces.
    for i, z in enumerate(level_z):
        a0 = i * ds
        a1 = (i + 1) * ds

        if axis == "x":
            pts = [(a0, 0, z), (a1, 0, z), (a1, s, z), (a0, s, z)]
        else:
            pts = [(0, a0, z), (s, a0, z), (s, a1, z), (0, a1, z)]

        if complementary:
            # The stepped surface is the underside.  If a terminal strip is
            # exactly h..h, retain it as an upward top face as requested.
            terminal_at_h = abs(z - h) < 1e-12
            add(
                "top" if terminal_at_h else "bottom",
                pts,
                (0, 0, 1) if terminal_at_h else (0, 0, -1),
                force_visible=terminal_at_h,
            )
        else:
            # z=0 short-stair tread remains a genuine visible horizontal face.
            add("top", pts, (0, 0, 1), force_visible=(short and abs(z) < 1e-12))

    # Risers between neighbouring treads.
    for i in range(n - 1):
        z0 = level_z[i]
        z1 = level_z[i + 1]
        if abs(z0 - z1) < 1e-12:
            continue

        a = (i + 1) * ds
        lo, hi = sorted((z0, z1))

        # Ordinary solid is below profile.  Riser outward normal points toward
        # the lower tread.  Complement reverses that normal.
        sign = -1 if z0 < z1 else 1
        if complementary:
            sign = -sign

        if axis == "x":
            pts = [(a, 0, lo), (a, s, lo), (a, s, hi), (a, 0, hi)]
            normal = (sign, 0, 0)
        else:
            pts = [(0, a, lo), (0, a, hi), (s, a, hi), (s, a, lo)]
            normal = (0, sign, 0)

        # Point ordering is irrelevant because normal is explicit.
        add("side", pts, normal)

    # Two transverse long sides.  They are split only for filling; there will
    # be no full-height edge at each split.
    for i, z in enumerate(level_z):
        a0 = i * ds
        a1 = (i + 1) * ds
        lo = z if complementary else 0
        hi = h if complementary else z
        if hi - lo <= 1e-12:
            continue

        if axis == "x":
            add("side", [(a0, 0, lo), (a0, 0, hi), (a1, 0, hi), (a1, 0, lo)], (0, -1, 0))
            add("side", [(a0, s, lo), (a1, s, lo), (a1, s, hi), (a0, s, hi)], (0, 1, 0))
        else:
            add("side", [(0, a0, lo), (0, a1, lo), (0, a1, hi), (0, a0, hi)], (-1, 0, 0))
            add("side", [(s, a0, lo), (s, a0, hi), (s, a1, hi), (s, a1, lo)], (1, 0, 0))

    # Two longitudinal end faces.
    for idx, a, sign in ((0, 0, -1), (n - 1, s, 1)):
        z = level_z[idx]
        lo = z if complementary else 0
        hi = h if complementary else z
        if hi - lo <= 1e-12:
            continue

        if axis == "x":
            pts = [(a, 0, lo), (a, s, lo), (a, s, hi), (a, 0, hi)]
            normal = (sign, 0, 0)
        else:
            pts = [(0, a, lo), (s, a, lo), (s, a, hi), (0, a, hi)]
            normal = (0, sign, 0)
        add("side", pts, normal)

    # Flat opposite cap, one polygon: no artificial step divisions.
    if complementary:
        add("top", [(0, 0, h), (s, 0, h), (s, s, h), (0, s, h)], (0, 0, 1))
    else:
        add("bottom", [(0, s, 0), (s, s, 0), (s, 0, 0), (0, 0, 0)], (0, 0, -1))

    return faces


# ----------------------------------------------------------------------
# Physical edge geometry
# ----------------------------------------------------------------------

def build_edges(args, camera_vector):
    """
    Return only edges that should actually be inked.

    Crucially, this does NOT use rectangle boundaries from build_faces().
    Therefore a staircase running in X does not acquire full-height seams
    merely because its Y-side was filled using one rectangle per step.
    """
    complementary, short, axis, low_end, level_z = world_levels(args)
    s = args.box_size
    h = args.box_height
    n = args.nsteps
    ds = s / n

    edges = []

    def add(a, b):
        if any(abs(x - y) > 1e-12 for x, y in zip(a, b)):
            edges.append((a, b))

    if axis == "x":
        # Camera-facing transverse side is y=0 or y=s.
        near_t = s if camera_vector[1] >= 0 else 0
        axis_camera = camera_vector[0]

        def p(a, t, z):
            return (a, t, z)

        def across(a, z):
            return (a, 0, z), (a, s, z)
    else:
        # Camera-facing transverse side is x=0 or x=s.
        near_t = s if camera_vector[0] >= 0 else 0
        axis_camera = camera_vector[1]

        def p(a, t, z):
            return (t, a, z)

        def across(a, z):
            return (0, a, z), (s, a, z)

    # 1. Staircase outline on ONLY the camera-facing transverse side.
    # Each step contributes its horizontal tread segment and only the short
    # vertical riser between adjacent heights -- never a line down to z=0.
    for i, z in enumerate(level_z):
        a0 = i * ds
        a1 = (i + 1) * ds
        add(p(a0, near_t, z), p(a1, near_t, z))
        if i + 1 < n:
            add(p(a1, near_t, z), p(a1, near_t, level_z[i + 1]))

    # Close this visible side against the opposite flat cap.
    flat_z = h if complementary else 0
    add(p(0, near_t, flat_z), p(s, near_t, flat_z))
    add(p(0, near_t, flat_z), p(0, near_t, level_z[0]))
    add(p(s, near_t, flat_z), p(s, near_t, level_z[-1]))

    # 2. Real step creases across the stair width.
    #
    # For ordinary stairs the stepped surface is the TOP surface, so these
    # across-width edges are real visible tread/riser creases.
    #
    # For complementary (up-*) stairs the stepped surface is the UNDERSIDE.
    # From a camera above the tile, full-width underside-riser borders are
    # hidden by the solid.  The complementary staircase remains visible via
    # the camera-facing side profile generated in section 1, so do not ink
    # these hidden diagonals at all.
    if not complementary:
        for i in range(n - 1):
            z0 = level_z[i]
            z1 = level_z[i + 1]
            if abs(z0 - z1) < 1e-12:
                continue

            a = (i + 1) * ds
            lo, hi = sorted((z0, z1))
            sign = -1 if z0 < z1 else 1

            riser_faces_camera = sign * axis_camera > 1e-10
            if riser_faces_camera:
                e0, e1 = across(a, lo)
                add(e0, e1)
                e0, e1 = across(a, hi)
                add(e0, e1)
            else:
                # Even when the riser faces away, its upper tread border is
                # the visible crease between adjacent top levels.
                e0, e1 = across(a, hi)
                add(e0, e1)

    # 3. Only the longitudinal END toward the camera gets an across-width
    # outline.  The opposite/back end is intentionally not inked.
    near_index = n - 1 if axis_camera >= 0 else 0
    near_a = s if near_index == n - 1 else 0
    near_z = level_z[near_index]
    e0, e1 = across(near_a, h if complementary else near_z)
    add(e0, e1)

    # Remove duplicates without changing order.
    result = []
    seen = set()
    for a, b in edges:
        aa = tuple(round(v, 12) for v in a)
        bb = tuple(round(v, 12) for v in b)
        key = tuple(sorted((aa, bb)))
        if key not in seen:
            seen.add(key)
            result.append((a, b))

    return result


# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------

def main():
    args = parse_args()
    output = args.output or f"{args.prefix}-{args.shape}.png"
    directory = args.dir

    top_color = modify_color(args.color, args.top_brightness, args.top_hue_shift)
    left_color = modify_color(args.color, args.left_brightness, args.left_hue_shift)
    right_color = modify_color(args.color, args.right_brightness, args.right_hue_shift)
    bottom_color = modify_color(args.color, args.bottom_brightness, args.bottom_hue_shift)
    edge_color = modify_color(args.color, args.edge_brightness, args.edge_hue_shift)

    s = args.box_size
    az = math.radians(args.camera_rotation)
    el = math.radians(args.camera_elevation)
    camera_vector = (
        math.cos(az) * math.cos(el),
        math.sin(az) * math.cos(el),
        math.sin(el),
    )

    # Same centering rule as the supplied current generate-tile.py.
    ground_center = (s / 2, s / 2, 0)
    projected_ground_center = project(
        ground_center, args.camera_rotation, args.camera_elevation
    )
    vertical_offset = (
        args.box_height / 2
        * math.cos(math.radians(args.camera_elevation))
    )

    def screen_point(p):
        x, y = p
        return (
            args.tile_width / 2 + x - projected_ground_center[0],
            args.tile_height / 2 + vertical_offset + y - projected_ground_center[1],
        )

    def aa_point_3d(point):
        q = project(point, args.camera_rotation, args.camera_elevation)
        x, y = screen_point(q)
        return round(x * args.scale * args.aa), round(y * args.scale * args.aa)

    def polygon_area(points):
        area = 0.0
        for i in range(len(points)):
            x1, y1 = points[i]
            x2, y2 = points[(i + 1) % len(points)]
            area += x1 * y2 - x2 * y1
        return abs(area) / 2

    visible_faces = []
    for face in build_faces(args):
        if not face["force_visible"] and dot(face["normal"], camera_vector) <= 1e-10:
            continue

        polygon = [aa_point_3d(p) for p in face["points"]]
        if polygon_area(polygon) <= 0.5:
            continue

        if face["kind"] == "top":
            color = top_color
        elif face["kind"] == "bottom":
            color = bottom_color
        else:
            projected = [project(p, args.camera_rotation, args.camera_elevation)
                         for p in face["points"]]
            mean_x = sum(p[0] for p in projected) / len(projected)
            color = left_color if mean_x < projected_ground_center[0] else right_color

        visible_faces.append({
            **face,
            "polygon": polygon,
            "color": color,
            "depth": average_depth(face["points"], camera_vector),
        })

    visible_faces.sort(key=lambda f: f["depth"])

    image = Image.new(
        "RGBA",
        (
            args.tile_width * args.scale * args.aa,
            args.tile_height * args.scale * args.aa,
        ),
        (0, 0, 0, 0),
    )
    draw = ImageDraw.Draw(image)

    # Fill only.  Tessellation edges are deliberately ignored.
    for face in visible_faces:
        draw.polygon(face["polygon"], fill=face["color"])

    # Now ink only the separately-defined physical stair edges.
    if args.edge_width > 0:
        width = max(1, round(args.edge_width * args.aa))
        for a, b in build_edges(args, camera_vector):
            p0 = aa_point_3d(a)
            p1 = aa_point_3d(b)
            if p0 != p1:
                draw.line([p0, p1], fill=edge_color, width=width)

    image = image.resize(
        (args.tile_width * args.scale, args.tile_height * args.scale),
        Image.Resampling.LANCZOS,
    )

    image.save(os.path.join(directory, output))

    print(
        f"Saved {os.path.join(directory, output)}: "
        f"{args.tile_width * args.scale} x {args.tile_height * args.scale} "
        f"({args.shape}, {args.nsteps} steps)"
    )


if __name__ == "__main__":
    main()
