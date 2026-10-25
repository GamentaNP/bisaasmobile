#!/usr/bin/env python3
"""Generate the Play Store graphic assets from brand constants.

Outputs (docs/store-assets/):
  - feature-graphic-1024x500.png  (Play feature graphic, 1024x500)
  - play-icon-512.png             (Play high-res icon, 512x512, from the app logo)

Re-run any time the brand changes:  python tool/generate_store_assets.py
Colors mirror lib/app/theme/app_colors.dart (Duolongo ramp).
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "store-assets"
OUT.mkdir(parents=True, exist_ok=True)

# Brand (AppColors)
GREEN = (0x58, 0xCC, 0x02)
GREEN_DARK = (0x46, 0xA3, 0x02)
GREEN_LIGHT = (0x89, 0xE2, 0x19)
BLUE = (0x1C, 0xB0, 0xF6)
BLUE_DARK = (0x18, 0x99, 0xD6)
VIOLET = (0xCE, 0x82, 0xFF)
VIOLET_DARK = (0xA5, 0x60, 0xD0)
INK = (0x13, 0x1F, 0x24)          # backgroundDark
WHITE = (0xFF, 0xFF, 0xFF)

FONT_DIR = ROOT / "assets" / "fonts"
BOLD = str(FONT_DIR / "InstrumentSans-Bold.ttf")
MEDIUM = str(FONT_DIR / "InstrumentSans-Medium.ttf")


def vertical_gradient(size, top, bottom):
    w, h = size
    base = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / max(h - 1, 1)
        base.putpixel((0, y), tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)))
    return base.resize((w, h))


def chunky_text(draw, xy, text, font, fill, shadow, depth=6):
    """Duolongo extrusion: hard shadow straight down, then the fill on top."""
    x, y = xy
    for i in range(depth, 0, -1):
        draw.text((x, y + i), text, font=font, fill=shadow)
    draw.text((x, y), text, font=font, fill=fill)


def chunky_pill(draw, xy, text, font, fill, edge, text_fill=WHITE, pad_x=28, pad_y=14, depth=6):
    x0, y0 = xy
    tmp = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    box = tmp.textbbox((0, 0), text, font=font)
    tw, th = box[2] - box[0], box[3] - box[1]
    w, h = tw + pad_x * 2, th + pad_y * 2
    radius = h // 2
    # edge first (offset down), face on top
    draw.rounded_rectangle([x0, y0 + depth, x0 + w, y0 + h + depth], radius, fill=edge)
    draw.rounded_rectangle([x0, y0, x0 + w, y0 + h], radius, fill=fill)
    draw.text((x0 + pad_x, y0 + pad_y - box[1]), text, font=font, fill=text_fill)
    return w, h + depth


def rounded(im, radius):
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *im.size], radius, fill=255)
    out = im.convert("RGBA")
    out.putalpha(mask)
    return out


def feature_graphic():
    W, H = 1024, 500
    img = vertical_gradient((W, H), INK, (0x1A, 0x2B, 0x33)).convert("RGBA")

    # faint oversized quiz-mark ring for texture
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([W - 420, -160, W + 220, 480], outline=(*GREEN, 40), width=90)
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(30)))

    draw = ImageDraw.Draw(img)

    f_title = ImageFont.truetype(BOLD, 128)
    f_tag = ImageFont.truetype(MEDIUM, 38)
    f_pill = ImageFont.truetype(MEDIUM, 30)

    chunky_text(draw, (64, 96), "CivilCal", f_title, WHITE, GREEN_DARK, depth=8)

    draw.text((66, 268), "Master civil engineering daily.", font=f_tag, fill=(*GREEN_LIGHT, 255))

    x = 64
    for label, fill, edge in (
        ("Daily Quiz", GREEN, GREEN_DARK),
        ("AI Tutor", BLUE, BLUE_DARK),
        ("Calculators", VIOLET, VIOLET_DARK),
    ):
        w, h = chunky_pill(draw, (x, 352), label, f_pill, fill, edge)
        x += w + 18

    # logo, rounded, right side
    logo = Image.open(ROOT / "assets" / "images" / "logo_icon.png").convert("RGBA")
    side = 290
    logo = logo.resize((side, side), Image.LANCZOS)
    logo = rounded(logo, 56)
    lx = W - side - 60
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [lx + 10, 105 + 12, lx + side + 10, 105 + side + 12], 56, fill=(0, 0, 0, 110)
    )
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(8)))
    img.alpha_composite(logo, (lx, 105))

    img.convert("RGB").save(OUT / "feature-graphic-1024x500.png", optimize=True)
    print("wrote", OUT / "feature-graphic-1024x500.png")


def play_icon():
    logo = Image.open(ROOT / "assets" / "images" / "logo_icon.png").convert("RGB")
    logo.resize((512, 512), Image.LANCZOS).save(OUT / "play-icon-512.png", optimize=True)
    print("wrote", OUT / "play-icon-512.png")


if __name__ == "__main__":
    feature_graphic()
    play_icon()
