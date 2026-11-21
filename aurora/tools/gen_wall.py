#!/usr/bin/env python3
"""Aurora wallpaper generator — teal / violet mesh + silk ribbons."""
import numpy as np
from PIL import Image, ImageFilter
import os

W, H = 2560, 1440
rng = np.random.default_rng(7)


def hex2rgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)])


BG_TOP = hex2rgb("#04060b")
BG_BOT = hex2rgb("#070d16")

# vertical base gradient
y = np.linspace(0, 1, H)[:, None, None]
img = BG_TOP[None, None, :] * (1 - y) + BG_BOT[None, None, :] * y
img = np.repeat(img, W, axis=1)


def smooth_noise(n, scale, seed):
    r = np.random.default_rng(seed)
    k = max(3, int(scale))
    v = r.normal(0, 1, n + k * 4)
    kernel = np.exp(-0.5 * (np.linspace(-2, 2, k * 4) ** 2))
    kernel /= kernel.sum()
    v = np.convolve(v, kernel, mode="same")[k * 2: k * 2 + n]
    v -= v.min()
    v /= max(v.max(), 1e-6)
    return v


def screen(base, layer):
    return 1.0 - (1.0 - base) * (1.0 - np.clip(layer, 0, 1))


def ribbon(base, y0, amp, period, phase, width, col_a, col_b, alpha=0.85,
           tilt=0.0, streak=0.35, seed=1):
    """Aurora curtain: coloured band with soft gaussian cross-section."""
    x = np.arange(W, dtype=np.float32)
    yy = np.arange(H, dtype=np.float32)[:, None]
    centre = (y0 * H + amp * H * np.sin(2 * np.pi * x / (period * W) + phase)
              + tilt * (x - W / 2))
    w = width * H * (1.0 + 0.35 * np.sin(2 * np.pi * x / (period * 1.7 * W) + phase * 1.3))
    dist = (yy - centre[None, :]) / np.maximum(w[None, :], 1e-6)
    band = np.exp(-0.5 * dist ** 2)

    # rainbow variation along the band + fine rays
    t = np.clip(0.5 + 0.5 * np.sin(2 * np.pi * x / (period * 2.2 * W) + phase), 0, 1)
    rays = smooth_noise(W, 9, seed)
    rays = 0.55 + 0.45 * rays
    col = (col_a[None, :] * (1 - t)[:, None] + col_b[None, :] * t[:, None])
    layer = band[:, :, None] * col[None, :, :] * (alpha * rays)[None, :, None]
    return screen(base, np.clip(layer, 0, 1))


def glow(base, cx, cy, radius, color, alpha):
    x = np.arange(W, dtype=np.float32)[None, :]
    y = np.arange(H, dtype=np.float32)[:, None]
    d2 = ((x - cx * W) ** 2 + (y - cy * H) ** 2) / (2 * (radius * H) ** 2)
    layer = np.exp(-d2)[:, :, None] * color[None, None, :] * alpha
    return screen(base, np.clip(layer, 0, 1))


TEAL = hex2rgb("#2dd4bf")
MINT = hex2rgb("#5eead4")
GREEN = hex2rgb("#34d399")
VIOLET = hex2rgb("#8b5cf6")
INDIGO = hex2rgb("#6366f1")
BLUE = hex2rgb("#0ea5e9")
PINK = hex2rgb("#f472b6")

# ambient glows
img = glow(img, 0.16, 0.80, 0.48, TEAL, 0.20)
img = glow(img, 0.80, 0.16, 0.50, VIOLET, 0.24)
img = glow(img, 0.50, 0.46, 0.60, BLUE, 0.08)
img = glow(img, 0.94, 0.86, 0.34, PINK, 0.10)

# silk ribbons (bottom-left rising to mid, violet curtain top-right)
img = ribbon(img, 0.94, 0.030, 1.6, 0.6, 0.085, GREEN, TEAL, 0.62, 0.10, 0.65, 11)
img = ribbon(img, 0.82, 0.040, 1.9, 2.4, 0.038, TEAL, MINT, 0.40, 0.06, 0.55, 12)
img = ribbon(img, 0.24, 0.045, 1.4, 1.1, 0.075, INDIGO, VIOLET, 0.34, -0.10, 0.50, 13)
img = ribbon(img, 0.52, 0.030, 2.1, 4.0, 0.022, VIOLET, PINK, 0.16, 0.02, 0.45, 14)

# stars in the upper half
stars = np.zeros((H, W), dtype=np.float32)
n_stars = 260
xs = rng.integers(0, W, n_stars)
ys = (rng.random(n_stars) ** 1.5 * H * 0.70).astype(int)
for x, y0 in zip(xs, ys):
    r = rng.choice([0, 0, 0, 1])
    b = rng.uniform(0.18, 0.85) * (1 - y0 / (H * 0.95))
    stars[max(0, y0 - r):y0 + r + 1, max(0, x - r):x + r + 1] += b
star_img = np.zeros((H, W, 3), dtype=np.float32)
star_img[:] = stars[:, :, None] * np.array([0.75, 0.92, 1.0])
img = screen(img, np.clip(star_img, 0, 1))

# vignette
x = np.linspace(-1, 1, W)[None, :]
y = np.linspace(-1, 1, H)[:, None]
r = np.sqrt((x * 0.92) ** 2 + (y * 0.92) ** 2)
vig = np.clip(1.0 - 0.58 * r ** 2.2, 0, 1)
img *= vig[:, :, None]

# gentle contrast curve + fine grain
img = np.clip(img, 0, 1)
img = img ** 1.08
grain = rng.normal(0, 0.0038, (H, W, 1))
img = np.clip(img + grain, 0, 1)

out = Image.fromarray((img * 255).astype(np.uint8), "RGB")
out = out.filter(ImageFilter.GaussianBlur(0.4))
out.save("/home/studen/.local/share/wallpapers/aurora/aurora-4k.png", optimize=True)
out.resize((1920, 1080), Image.LANCZOS).save(
    "/home/studen/.local/share/wallpapers/aurora/aurora.png", optimize=True)

blur = out.resize((1920, 1080), Image.LANCZOS).filter(ImageFilter.GaussianBlur(26))
blur = Image.eval(blur, lambda v: int(v * 0.72))
blur.save("/home/studen/.local/share/wallpapers/aurora/aurora-blur.png", optimize=True)
print("done")
