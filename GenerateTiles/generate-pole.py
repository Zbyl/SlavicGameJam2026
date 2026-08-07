#!/usr/bin/env python3

from PIL import Image, ImageDraw
import argparse
import colorsys
import math
import os


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

SCALE = 2
AA = 2


SHAPES = (
    "box",
    "half",
    "up-half",
    "pole1",
    "pole2",
    "pole3",
    "pole4",
    "pole5",
    "pole6",
    "mid-x",
    "mid-y",
    "midwall-x",
    "midwall-y",
    "midthick-x",
    "midthick-y",
    "half-x0",
    "half-x1",
    "half-y0",
    "half-y1",
    "wall-x0",
    "wall-x1",
    "wall-y0",
    "wall-y1",
    "thick-x0",
    "thick-x1",
    "thick-y0",
    "thick-y1",
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
    parser.add_argument("--x0", type=float, help="custom minimum X fraction (0..1)")
    parser.add_argument("--x1", type=float, help="custom maximum X fraction (0..1)")
    parser.add_argument("--y0", type=float, help="custom minimum Y fraction (0..1)")
    parser.add_argument("--y1", type=float, help="custom maximum Y fraction (0..1)")
    parser.add_argument("--scale", type=positive_int, default=SCALE)
    parser.add_argument("--aa", type=positive_int, default=AA, help="supersampling factor")

    return parser.parse_args()


# ----------------------------------------------------------------------
# Shape definitions
# ----------------------------------------------------------------------

def get_prism_bounds(shape):
    """Return x0, y0, z0, x1, y1, z1 as fractions of a full block."""
    shapes = {
        "box":    (0.00, 0.00, 0.00, 1.00, 1.00, 1.00),
        "half":   (0.00, 0.00, 0.00, 1.00, 1.00, 0.50),
        "up-half": (0.00, 0.00, 0.50, 1.00, 1.00, 1.00),
        "pole1":   (0.45, 0.45, 0.00, 0.55, 0.55, 1.00),
        "pole2":   (0.35, 0.35, 0.00, 0.65, 0.65, 1.00),
        "pole3":   (0.30, 0.30, 0.00, 0.70, 0.70, 1.00),
        "pole4":   (0.25, 0.25, 0.00, 0.75, 0.75, 1.00),
        "pole5":   (0.15, 0.15, 0.00, 0.85, 0.85, 1.00),
        "pole6":   (0.05, 0.05, 0.00, 0.95, 0.95, 1.00),
        "mid-x":   (0.25, 0.00, 0.00, 0.75, 1.00, 1.00),
        "mid-y":   (0.00, 0.25, 0.00, 1.00, 0.75, 1.00),
        "midwall-x": (0.45, 0.00, 0.00, 0.55, 1.00, 1.00),
        "midwall-y": (0.00, 0.45, 0.00, 1.00, 0.55, 1.00),
        "midthick-x": (0.05, 0.00, 0.00, 0.95, 1.00, 1.00),
        "midthick-y": (0.00, 0.05, 0.00, 1.00, 0.95, 1.00),
        "half-x0": (0.00, 0.00, 0.00, 0.50, 1.00, 1.00),
        "half-x1": (0.50, 0.00, 0.00, 1.00, 1.00, 1.00),
        "half-y0": (0.00, 0.00, 0.00, 1.00, 0.50, 1.00),
        "half-y1": (0.00, 0.50, 0.00, 1.00, 1.00, 1.00),
        "wall-x0": (0.00, 0.00, 0.00, 0.10, 1.00, 1.00),
        "wall-x1": (0.90, 0.00, 0.00, 1.00, 1.00, 1.00),
        "wall-y0": (0.00, 0.00, 0.00, 1.00, 0.10, 1.00),
        "wall-y1": (0.00, 0.90, 0.00, 1.00, 1.00, 1.00),
        "thick-x0": (0.00, 0.00, 0.00, 0.8, 1.00, 1.00),
        "thick-x1": (0.20, 0.00, 0.00, 1.00, 1.00, 1.00),
        "thick-y0": (0.00, 0.00, 0.00, 1.00, 0.80, 1.00),
        "thick-y1": (0.00, 0.20, 0.00, 1.00, 1.00, 1.00),
    }
    return shapes[shape]


def make_box_vertices(x0, y0, z0, x1, y1, z1, size, height):
    """Create the eight vertices of an axis-aligned rectangular box."""
    return {
        "b00": (x0 * size, y0 * size, z0 * height),
        "b10": (x1 * size, y0 * size, z0 * height),
        "b11": (x1 * size, y1 * size, z0 * height),
        "b01": (x0 * size, y1 * size, z0 * height),
        "t00": (x0 * size, y0 * size, z1 * height),
        "t10": (x1 * size, y0 * size, z1 * height),
        "t11": (x1 * size, y1 * size, z1 * height),
        "t01": (x0 * size, y1 * size, z1 * height),
    }


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


def blend_color(first, second, amount):
    """Linearly blend two RGBA colours; amount is clamped to 0..1."""
    amount = max(0.0, min(1.0, amount))
    return tuple(
        round(a + (b - a) * amount)
        for a, b in zip(first, second)
    )


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


# ----------------------------------------------------------------------
# Main generator
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
    h = args.box_height
    x0, y0, z0, x1, y1, z1 = get_prism_bounds(args.shape)

    # Any supplied footprint value overrides the named shape. This makes the
    # same drawing function useful for arbitrary narrow or partial blocks.
    x0 = args.x0 if args.x0 is not None else x0
    x1 = args.x1 if args.x1 is not None else x1
    y0 = args.y0 if args.y0 is not None else y0
    y1 = args.y1 if args.y1 is not None else y1

    if not (0 <= x0 < x1 <= 1 and 0 <= y0 < y1 <= 1 and 0 <= z0 < z1 <= 1):
        raise ValueError("box bounds must satisfy 0 <= min < max <= 1")

    vertices = make_box_vertices(x0, y0, z0, x1, y1, z1, s, h)

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
        draw.polygon(face["polygon"], fill=face["color"])

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

    image = image.resize(
        (
            args.tile_width * args.scale,
            args.tile_height * args.scale,
        ),
        Image.Resampling.LANCZOS,
    )

    os.makedirs(directory, exist_ok=True)
    image.save(os.path.join(directory, output))

    print(
        f"Saved {os.path.join(directory, output)}: "
        f"{args.tile_width * args.scale} x "
        f"{args.tile_height * args.scale} "
        f"({args.shape})"
    )


if __name__ == "__main__":
    main()
