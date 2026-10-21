#!/usr/bin/env python3
"""Generate the launcher icon PNGs from the brand SVG.

Why this exists
---------------
`pubspec.yaml` pointed `flutter_launcher_icons` at
`assets/images/logo_icon_foreground.png`, which did not exist, so the
generator had never run. The committed launcher icons were therefore the
**stock Flutter logo** on both Android and iOS — a guaranteed store
rejection and unpublishable branding.

The brand asset is `assets/images/logo_icon.svg`: a 1024x1024 canvas holding
a rounded dark plate and a gradient "M" glyph. Two PNGs are produced from it:

* `assets/images/logo_icon.png` — the **legacy / iOS** icon: an opaque
  full-bleed square (iOS masks the corners itself and rejects an icon
  with an alpha channel, so the plate must be square and opaque).
* `assets/images/logo_icon_foreground.png` — the **Android adaptive**
  foreground: the glyph alone on a transparent canvas, scaled into the
  central 66% safe zone. The plate colour comes from
  `adaptive_icon_background` in `pubspec.yaml`.

Usage
-----
    python tool/generate_launcher_icon.py

Then regenerate the platform icons:

    dart run flutter_launcher_icons
"""

from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image, ImageDraw

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(REPO_ROOT, "assets", "images")

SIZE = 1024
PLATE = (0x0B, 0x0F, 0x17)

# The "M" path from logo_icon.svg, in its own 644x624 coordinate space.
M_PATH = [
    (0, 624),
    (0, 0),
    (200, 0),
    (444, 312),
    (444, 0),
    (644, 0),
    (644, 624),
    (444, 624),
    (200, 312),
    (200, 624),
]

# The gradient stops from logo_icon.svg, along the path's bounding-box diagonal.
GRADIENT_FROM = (0x22, 0xD3, 0xEE)
GRADIENT_TO = (0x0E, 0xA5, 0xC9)

# The glyph's offset inside the 1024x1024 plate (the SVG's translate(280,200)).
GLYPH_X = 280
GLYPH_Y = 200


def _gradient_alpha(polygon: list[tuple[int, int]]) -> Image.Image:
    """Render the diagonal gradient, masked to the glyph polygon.

    The SVG gradient is `x1=0 y1=0 x2=1 y2=1` in objectBoundingBox units,
    which — for this path — is the diagonal of the glyph's own bounding box.
    """
    xs = [p[0] for p in polygon]
    ys = [p[1] for p in polygon]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)
    span = float((max_x - min_x) + (max_y - min_y)) or 1.0

    yy, xx = np.mgrid[0:SIZE, 0:SIZE]
    t = np.clip(((xx - min_x) + (yy - min_y)) / span, 0.0, 1.0)

    r = GRADIENT_FROM[0] + (GRADIENT_TO[0] - GRADIENT_FROM[0]) * t
    g = GRADIENT_FROM[1] + (GRADIENT_TO[1] - GRADIENT_FROM[1]) * t
    b = GRADIENT_FROM[2] + (GRADIENT_TO[2] - GRADIENT_FROM[2]) * t
    rgb = np.stack([r, g, b], axis=-1).astype(np.uint8)

    alpha = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(alpha).polygon(polygon, fill=255)
    rgb = Image.fromarray(rgb, "RGB")
    rgb.putalpha(alpha)
    return rgb


def _scaled_polygon(scale: float, offset_x: float, offset_y: float) -> list[tuple[int, int]]:
    return [
        (int(round(x * scale + offset_x)), int(round(y * scale + offset_y)))
        for (x, y) in M_PATH
    ]


def _legacy_icon() -> Image.Image:
    """The full-bleed square used for iOS and for Android's legacy icon."""
    canvas = Image.new("RGBA", (SIZE, SIZE), PLATE + (255,))
    polygon = _scaled_polygon(1.0, GLYPH_X, GLYPH_Y)
    canvas.paste(_gradient_alpha(polygon), (0, 0), _gradient_alpha(polygon))
    return canvas


def _adaptive_foreground() -> Image.Image:
    """The glyph alone, centred on a transparent canvas.

    The glyph is drawn at its **natural** size and centred, not pre-scaled
    into the safe zone. `flutter_launcher_icons` wraps the adaptive
    foreground in an `android:inset="16%"`, so the drawable is shrunk to
    ~73dp of the 108dp canvas; pre-scaling here as well would shrink the
    mark twice. Centred at natural size, the glyph lands at ~70% of the
    66dp safe circle — prominent, and entirely inside it.
    """
    glyph_w = 644
    glyph_h = 624
    offset_x = (SIZE - glyph_w) / 2
    offset_y = (SIZE - glyph_h) / 2

    polygon = _scaled_polygon(1.0, offset_x, offset_y)
    gradient = _gradient_alpha(polygon)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    canvas.paste(gradient, (0, 0), gradient)
    return canvas


def main() -> int:
    legacy_path = os.path.join(ASSETS, "logo_icon.png")
    foreground_path = os.path.join(ASSETS, "logo_icon_foreground.png")

    legacy = _legacy_icon()
    # The iOS marketing icon must be fully opaque: App Store Connect rejects an
    # asset with an alpha channel, and `flutter_launcher_icons` flattens it
    # again with `remove_alpha_ios: true`.
    legacy.convert("RGB").save(legacy_path, "PNG", optimize=True)

    foreground = _adaptive_foreground()
    foreground.save(foreground_path, "PNG", optimize=True)

    print(f"wrote {os.path.relpath(legacy_path, REPO_ROOT)}")
    print(f"wrote {os.path.relpath(foreground_path, REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
