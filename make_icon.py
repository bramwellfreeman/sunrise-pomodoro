#!/usr/bin/env python3
"""Generate the Sunrise Pomodoro app icon (1024px master PNG).

Draws a macOS-style rounded-rect icon: a dawn sky gradient, a rising sun with a
soft glow, and a hill silhouette in front — matching the menu-bar glyph.
"""
from PIL import Image, ImageDraw, ImageFilter

S = 1024                      # master size
SS = 4                        # supersample factor for smooth edges
W = S * SS

def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))

# --- sky gradient (indigo night at top -> warm dawn at the horizon) ---
sky = Image.new("RGB", (1, W))
top    = (46, 33, 74)         # deep indigo
mid    = (150, 78, 96)        # dusky rose
bottom = (255, 176, 110)      # warm peach
px = sky.load()
for y in range(W):
    t = y / (W - 1)
    if t < 0.55:
        c = lerp(top, mid, t / 0.55)
    else:
        c = lerp(mid, bottom, (t - 0.55) / 0.45)
    px[0, y] = c
sky = sky.resize((W, W))

art = sky.convert("RGBA")
draw = ImageDraw.Draw(art)

# --- sun with glow ---
sun_cx = W * 0.5
sun_cy = W * 0.52
sun_r  = W * 0.17
sun_color = (255, 208, 92)

glow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
gr = sun_r * 2.1
gd.ellipse([sun_cx - gr, sun_cy - gr, sun_cx + gr, sun_cy + gr],
           fill=(255, 200, 120, 130))
glow = glow.filter(ImageFilter.GaussianBlur(W * 0.05))
art = Image.alpha_composite(art, glow)
draw = ImageDraw.Draw(art)
draw.ellipse([sun_cx - sun_r, sun_cy - sun_r, sun_cx + sun_r, sun_cy + sun_r],
             fill=sun_color)

# --- hill silhouette (a gentle mound across the lower third) ---
hill_color = (58, 40, 58)
crest_y = W * 0.66
edge_y  = W * 0.80
hill = [(0, W), (0, edge_y)]
steps = 120
for i in range(steps + 1):
    x = W * i / steps
    # cosine mound: highest in the middle
    import math
    t = i / steps
    y = edge_y - (edge_y - crest_y) * (0.5 - 0.5 * math.cos(2 * math.pi * t)) \
        if False else edge_y - (edge_y - crest_y) * (math.sin(math.pi * t) ** 0.8)
    hill.append((x, y))
hill += [(W, edge_y), (W, W)]
draw.polygon(hill, fill=hill_color)

# --- rounded-rect mask (macOS squircle-ish, ~22.4% corner radius) ---
mask = Image.new("L", (W, W), 0)
md = ImageDraw.Draw(mask)
inset = int(W * 0.045)         # slight margin like real app icons
radius = int(W * 0.224)
md.rounded_rectangle([inset, inset, W - inset, W - inset],
                     radius=radius, fill=255)

out = Image.new("RGBA", (W, W), (0, 0, 0, 0))
out.paste(art, (0, 0), mask)

out = out.resize((S, S), Image.LANCZOS)
out.save("icon_master.png")
print("wrote icon_master.png", out.size)
