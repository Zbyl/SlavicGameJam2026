#!/usr/bin/env python3

from PIL import Image, ImageDraw
import argparse
import colorsys
import math


# ----------------------------------------------------------------------
# Defaults
# ----------------------------------------------------------------------

TILE_WIDTH = 64
TILE_HEIGHT = 64

BOX_SIZE = 16.0
BOX_HEIGHT = 16.0

SHAPE = "stairs-x1"
NSTEPS = 4
PREFIX = "tile"

CAMERA_ROTATION = 35.0
CAMERA_ELEVATION = 45.0

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

EDGE_WIDTH = 1.0

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
        description="Generate an orthographic isometric-style PNG stair tile."
    )

    parser.add_argument(
        "-t", "--shape",
        choices=SHAPES,
        default=SHAPE,
        help=f"shape to generate (default: {SHAPE})",
    )
    parser.add_argument(
        "-n", "--nsteps",
        type=positive_int,
        default=NSTEPS,
        help=f"number of steps (default: {NSTEPS})",
    )
    parser.add_argument(
        "-o", "--output",
        help="output PNG filename; default is PREFIX-SHAPE.png",
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

    return parser.parse_args()


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


def polygon_normal(points):
    """Return a non-zero normal for a planar polygon, if possible."""
    p0 = points[0]
    for i in range(1, len(points) - 1):
        a = sub(points[i], p0)
        b = sub(points[i + 1], p0)
        n = cross(a, b)
        if dot(n, n) > 1e-12:
            return n
    return (0.0, 0.0, 0.0)


def orient_polygon(points, desired_normal):
    """Reverse polygon winding when necessary to point its normal outward."""
    if dot(polygon_normal(points), desired_normal) < 0:
        return list(reversed(points))
    return points


def average_depth(points, camera_vector):
    return sum(dot(point, camera_vector) for point in points) / len(points)


# ----------------------------------------------------------------------
# Stair geometry
# ----------------------------------------------------------------------

def parse_shape(shape):
    """
    Return (upper, short, axis, low_side).

    Direction follows generate-tile.py's slope convention:
    x1 means the staircase descends toward x=BOX_SIZE (x=1), so x1 is
    the low edge.  x0 means x=0 is the low edge, and similarly for y.
    """
    upper = shape.startswith("up-")
    base = shape[3:] if upper else shape

    short = base.startswith("short-")
    if short:
        base = base[6:]

    # base is now e.g. "stairs-x1"
    _, direction = base.split("-", 1)
    axis = direction[0]
    low_side = int(direction[1])

    return upper, short, axis, low_side


def stair_levels(nsteps, short):
    """
    Heights from low edge toward high edge, as fractions of BOX_HEIGHT.

    stairs:       1/n, 2/n, ..., 1
    short-stairs: 0,   1/n, ..., (n-1)/n
    """
    if short:
        return [i / nsteps for i in range(nsteps)]
    return [(i + 1) / nsteps for i in range(nsteps)]


def build_geometry(shape, nsteps, size, height):
    """Build exposed polygons for the staircase solid."""
    upper, short, axis, low_side = parse_shape(shape)
    levels = [fraction * height for fraction in stair_levels(nsteps, short)]

    # Coordinate boundaries ordered from the low edge toward the high edge.
    if low_side == 0:
        bounds = [size * i / nsteps for i in range(nsteps + 1)]
        low_dir = -1.0
    else:
        bounds = [size * (1.0 - i / nsteps) for i in range(nsteps + 1)]
        low_dir = 1.0

    high_dir = -low_dir

    if axis == "x":
        def point(u, v, z):
            return (u, v, z)

        low_normal = (low_dir, 0.0, 0.0)
        high_normal = (high_dir, 0.0, 0.0)
        side0_normal = (0.0, -1.0, 0.0)
        side1_normal = (0.0, 1.0, 0.0)
    else:
        def point(u, v, z):
            return (v, u, z)

        low_normal = (0.0, low_dir, 0.0)
        high_normal = (0.0, high_dir, 0.0)
        side0_normal = (-1.0, 0.0, 0.0)
        side1_normal = (1.0, 0.0, 0.0)

    faces = []

    def add_face(kind, points, desired_normal):
        points = orient_polygon(points, desired_normal)
        if dot(polygon_normal(points), polygon_normal(points)) <= 1e-12:
            return
        faces.append({"kind": kind, "points": points})

    # Horizontal staircase boundary.
    material_indices = []

    for i in range(nsteps):
        u0 = bounds[i]
        u1 = bounds[i + 1]
        z = levels[i]

        if upper:
            # Complement: material lies from the staircase profile up to h.
            if z < height - 1e-12:
                material_indices.append(i)
                add_face(
                    "bottom",
                    [
                        point(u0, 0, z), point(u0, size, z),
                        point(u1, size, z), point(u1, 0, z),
                    ],
                    (0.0, 0.0, -1.0),
                )
        else:
            # Ordinary stairs: material lies from z=0 up to the profile.
            if z > 1e-12:
                material_indices.append(i)
                add_face(
                    "top",
                    [
                        point(u0, 0, z), point(u1, 0, z),
                        point(u1, size, z), point(u0, size, z),
                    ],
                    (0.0, 0.0, 1.0),
                )

    # The opposite outer cap is planar.  Draw it as one polygon so it does
    # not get artificial seam lines at every internal step boundary.
    if material_indices:
        first = material_indices[0]
        last = material_indices[-1]
        u0 = bounds[first]
        u1 = bounds[last + 1]

        if upper:
            add_face(
                "top",
                [
                    point(u0, 0, height), point(u1, 0, height),
                    point(u1, size, height), point(u0, size, height),
                ],
                (0.0, 0.0, 1.0),
            )
        else:
            add_face(
                "bottom",
                [
                    point(u0, 0, 0), point(u0, size, 0),
                    point(u1, size, 0), point(u1, 0, 0),
                ],
                (0.0, 0.0, -1.0),
            )

    # Vertical risers between consecutive steps.
    for i in range(nsteps - 1):
        u = bounds[i + 1]
        z0 = levels[i]
        z1 = levels[i + 1]

        if abs(z1 - z0) <= 1e-12:
            continue

        desired = high_normal if upper else low_normal
        add_face(
            "side",
            [
                point(u, 0, z0), point(u, size, z0),
                point(u, size, z1), point(u, 0, z1),
            ],
            desired,
        )

    # Low and high end faces.
    low_z = levels[0]
    high_z = levels[-1]

    if upper:
        if low_z < height - 1e-12:
            add_face(
                "side",
                [point(bounds[0], 0, low_z), point(bounds[0], size, low_z),
                 point(bounds[0], size, height), point(bounds[0], 0, height)],
                low_normal,
            )
        if high_z < height - 1e-12:
            add_face(
                "side",
                [point(bounds[-1], 0, high_z), point(bounds[-1], 0, height),
                 point(bounds[-1], size, height), point(bounds[-1], size, high_z)],
                high_normal,
            )
    else:
        if low_z > 1e-12:
            add_face(
                "side",
                [point(bounds[0], 0, 0), point(bounds[0], 0, low_z),
                 point(bounds[0], size, low_z), point(bounds[0], size, 0)],
                low_normal,
            )
        if high_z > 1e-12:
            add_face(
                "side",
                [point(bounds[-1], 0, 0), point(bounds[-1], size, 0),
                 point(bounds[-1], size, high_z), point(bounds[-1], 0, high_z)],
                high_normal,
            )

    # The two long staircase-profile side faces.
    # Construct a single staircase-outline polygon on each side so only the
    # actual silhouette is edged; there are no spurious vertical lines down
    # through the interior at every step boundary.  For short-stairs and
    # up-stairs, zero-thickness end segments are excluded entirely.
    if material_indices:
        first = material_indices[0]
        last = material_indices[-1]

        for v, desired_normal in ((0.0, side0_normal), (size, side1_normal)):
            profile = []

            if upper:
                # Flat upper edge over the part of the footprint containing
                # material.
                profile.append(point(bounds[first], v, height))
                profile.append(point(bounds[last + 1], v, height))

                # Stair profile from high back toward low.
                profile.append(point(bounds[last + 1], v, levels[last]))
                for i in range(last, first - 1, -1):
                    profile.append(point(bounds[i], v, levels[i]))
                    if i > first:
                        profile.append(point(bounds[i], v, levels[i - 1]))
            else:
                # Ground edge over the part of the footprint containing
                # material.
                profile.append(point(bounds[first], v, 0.0))
                profile.append(point(bounds[last + 1], v, 0.0))

                # Stair profile from high back toward low.
                profile.append(point(bounds[last + 1], v, levels[last]))
                for i in range(last, first - 1, -1):
                    profile.append(point(bounds[i], v, levels[i]))
                    if i > first:
                        profile.append(point(bounds[i], v, levels[i - 1]))

            add_face("side", profile, desired_normal)

    return faces


# ----------------------------------------------------------------------
# Main generator
# ----------------------------------------------------------------------

def main():
    args = parse_args()

    output = args.output or f"{args.prefix}-{args.shape}.png"

    top_color = modify_color(args.color, args.top_brightness, args.top_hue_shift)
    left_color = modify_color(args.color, args.left_brightness, args.left_hue_shift)
    right_color = modify_color(args.color, args.right_brightness, args.right_hue_shift)
    bottom_color = modify_color(args.color, args.bottom_brightness, args.bottom_hue_shift)
    edge_color = modify_color(args.color, args.edge_brightness, args.edge_hue_shift)

    faces = build_geometry(
        args.shape,
        args.nsteps,
        args.box_size,
        args.box_height,
    )

    az = math.radians(args.camera_rotation)
    el = math.radians(args.camera_elevation)

    # Vector from the object toward the camera.
    camera_vector = (
        math.cos(az) * math.cos(el),
        math.sin(az) * math.cos(el),
        math.sin(el),
    )

    ground_center = (args.box_size / 2, args.box_size / 2, 0)
    projected_ground_center = project(
        ground_center,
        args.camera_rotation,
        args.camera_elevation,
    )

    def screen_point(p):
        x, y = p
        return (
            args.tile_width / 2 + x - projected_ground_center[0],
            args.tile_height / 2 + y - projected_ground_center[1],
        )

    def aa_point(point3d):
        x, y = screen_point(project(
            point3d,
            args.camera_rotation,
            args.camera_elevation,
        ))
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

    visible_faces = []

    for face in faces:
        points = face["points"]
        normal = polygon_normal(points)

        # Back-face culling.
        if dot(normal, camera_vector) <= 1e-10:
            continue

        polygon = [aa_point(point) for point in points]
        if polygon_area(polygon) <= 0.5:
            continue

        if face["kind"] == "top":
            color = top_color
        elif face["kind"] == "bottom":
            color = bottom_color
        else:
            # Match generate-tile.py: shade vertical faces according to where
            # they appear horizontally in the projected image.
            projected_points = [
                project(point, args.camera_rotation, args.camera_elevation)
                for point in points
            ]
            mean_x = sum(p[0] for p in projected_points) / len(projected_points)
            color = left_color if mean_x < projected_ground_center[0] else right_color

        visible_faces.append({
            "points": points,
            "polygon": polygon,
            "color": color,
            "depth": average_depth(points, camera_vector),
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

    # Draw boundary edges of visible faces. Coordinate tuples themselves are
    # used as edge keys because staircase geometry has no fixed vertex names.
    visible_edges = set()
    for face in visible_faces:
        points = face["points"]
        for i in range(len(points)):
            a = points[i]
            b = points[(i + 1) % len(points)]
            if a == b:
                continue
            visible_edges.add(tuple(sorted((a, b))))

    if args.edge_width > 0:
        edge_width_aa = max(1, round(args.edge_width * args.aa))

        for a, b in visible_edges:
            p1 = aa_point(a)
            p2 = aa_point(b)
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

    image.save(output)

    print(
        f"Saved {output}: "
        f"{args.tile_width * args.scale} x "
        f"{args.tile_height * args.scale} "
        f"({args.shape}, {args.nsteps} steps)"
    )


if __name__ == "__main__":
    main()
