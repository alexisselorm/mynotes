"""Generates the mynotes app icon.

Design: a slightly tilted "stack of notes" card with an "N" and an extended-dot
caret, drawn in lucide's 24x24 stroke geometry (stroke = 2 svg units, round
caps/joins), composited on a diagonal green gradient.

Usage:  python3 tool/make_app_icon.py
Output: assets/images/app_icon.png        (1024x1024, alpha, transparent outside)
        assets/images/app_icon_foreground.png (1024x1024, art at 66% for adaptive safe zone)
"""

from pathlib import Path

from PIL import Image, ImageDraw

OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "images"

SS = 4  # supersampling factor
SIZE = 1024

# gradient stops #7BE495 -> #2FB84B (derived from the app seed colour 63,212,50)
GRAD_TOP_LEFT = (127, 233, 156)
GRAD_BOTTOM_RIGHT = (36, 150, 60)
GLYPH = (255, 255, 255, 255)

# art is laid out on a 24x24 grid (lucide geometry); this is the fraction of
# the icon canvas the grid spans
GRID_SIZE = 24
GLYPH_SCALE = 0.82
CARD_TILT = 7  # degrees, clockwise


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def gradient(w, h):
    """Diagonal RGB gradient, top-left -> bottom-right."""
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        for x in range(w):
            t = (x / w + y / h) / 2
            px[x, y] = lerp(GRAD_TOP_LEFT, GRAD_BOTTOM_RIGHT, t)
    return img


def stroke(draw, pts, width, fill):
    """Polyline with round caps and round joins, drawn segment by segment."""
    w = max(1, round(width))
    r = w / 2
    for i in range(len(pts) - 1):
        draw.line([pts[i], pts[i + 1]], fill=fill, width=w)
    # round every vertex so joins (and caps) stay circular like lucide's
    for (x, y) in pts:
        draw.ellipse([x - r, y - r, x + r, y + r], fill=fill)


def rounded_polygon_outline(draw, pts, width, fill):
    """Outline of a closed polygon with rounded corners."""
    n = len(pts)
    for i in range(n):
        a, b = pts[i], pts[(i + 1) % n]
        draw.line([a, b], fill=fill, width=max(1, round(width)))
    r = width / 2
    for (x, y) in pts:
        draw.ellipse([x - r, y - r, x + r, y + r], fill=fill)


def card_polygon(inset_ratio):
    """Tilted note card in unit-box coords (before scaling)."""
    # card box: x in [-8, 8], y in [-9.5, 9.5]
    x0, x1, y0, y1 = -7.4, 7.4, -9.0, 9.0
    inset = inset_ratio * (x1 - x0)
    pts = [
        (x0 + inset, y0),
        (x1, y0),
        (x1, y1 - inset),
        (x0, y1),
    ]
    return pts


def glyph(draw, cx, cy, scale, card_dims):
    """Draws the card + N + caret centred at (cx, cy)."""
    from math import cos, radians, sin

    a = radians(CARD_TILT)
    ca, sa = cos(a), sin(a)

    def to_px(pts):
        out = []
        for (x, y) in pts:
            # rotate then scale then translate
            rx = x * ca - y * sa
            ry = x * sa + y * ca
            out.append((cx + rx * scale, cy + ry * scale))
        return out

    card = card_polygon(card_dims)
    # all widths are expressed on the 24-grid, then scaled with the art
    card_w = 1.25 * scale
    pts = to_px(card)
    # stroke each edge separately: draw.line with a closed point list fills the
    # outline instead of tracing it, so we draw the 4 sides as plain segments
    rounded_polygon_outline(draw, pts, card_w, GLYPH)

    # "N": left stem, diagonal, right stem
    # "N": left stem, diagonal, right stem (kept inside the card)
    n_pts = [(-3.9, 4.2), (-3.9, -4.2), (3.4, 4.2), (3.4, -4.2)]
    stroke(draw, to_px(n_pts), 1.6 * scale, GLYPH)

    # caret: extended dot (pipe) sitting in the card's margin
    pipe = [(5.9, 5.2), (5.9, -3.4)]
    stroke(draw, to_px(pipe), 1.15 * scale, GLYPH)


def build(size=SIZE, canvas_ratio=1.0, background=True, rounded=True):
    """Full app icon. background=False yields the transparent art layer only."""
    W = H = size
    img = gradient(W, H) if background else Image.new("RGB", (W, H))

    # glyph layer: white art on transparent, composited over the gradient.
    # Only the art's own alpha is used, so the background never gets tinted.
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    scale = W * GLYPH_SCALE * canvas_ratio / GRID_SIZE
    glyph(d, W / 2, H / 2, scale, card_dims=0.16)

    img = img.convert("RGBA")
    art_alpha = layer.getchannel("A")
    img.alpha_composite(Image.merge("RGBA", (*(Image.new("L", (W, H), 255) for _ in range(3)), art_alpha)))

    if not background:
        # keep only the art: its alpha is the whole silhouette
        art = img.convert("RGBA")
        art.putalpha(layer.getchannel("A"))
        return art

    if rounded:
        # rounded-square silhouette (iOS/macOS style); Android uses its own mask
        mask = Image.new("L", (W, H), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, W - 1, H - 1], radius=round(W * 0.225), fill=255
        )
        img.putalpha(mask)
    else:
        img.putalpha(255)
    return img


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    big = build(SIZE * 2)  # render at 2048 then downscale for clean edges
    full = big.resize((SIZE, SIZE), Image.LANCZOS)
    full.save(OUT_DIR / "app_icon.png")

    # adaptive-icon foreground: art only, transparent, inside the 66% safe zone
    adaptive = build(SIZE * 2, canvas_ratio=0.62, background=False).resize(
        (SIZE, SIZE), Image.LANCZOS
    )
    adaptive.save(OUT_DIR / "app_icon_foreground.png")

    print("wrote", OUT_DIR / "app_icon.png")
    print("wrote", OUT_DIR / "app_icon_foreground.png")


if __name__ == "__main__":
    main()
