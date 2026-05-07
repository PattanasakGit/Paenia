#!/usr/bin/env python3
import math
import struct
import zlib
from pathlib import Path

OUT = Path("build/icon-source.png")
SIZE = 1024


def clamp(value):
    return max(0, min(255, int(value)))


def mix(a, b, t):
    return tuple(a[i] * (1 - t) + b[i] * t for i in range(3))


def rounded_rect_alpha(x, y, left, top, right, bottom, radius):
    if x < left or x > right or y < top or y > bottom:
        return 0
    cx = min(max(x, left + radius), right - radius)
    cy = min(max(y, top + radius), bottom - radius)
    dist = math.hypot(x - cx, y - cy)
    return max(0, min(1, radius + 1 - dist))


def circle_alpha(x, y, cx, cy, radius):
    dist = math.hypot(x - cx, y - cy)
    return max(0, min(1, radius + 1 - dist))


pixels = bytearray()
for y in range(SIZE):
    row = bytearray([0])
    for x in range(SIZE):
        nx = x / (SIZE - 1)
        ny = y / (SIZE - 1)
        base = mix((6, 8, 13), (24, 19, 42), (nx + ny) / 2)
        glow1 = max(0, 1 - math.hypot(nx - 0.22, ny - 0.18) / 0.62)
        glow2 = max(0, 1 - math.hypot(nx - 0.82, ny - 0.78) / 0.72)
        r = base[0] + glow1 * 34 + glow2 * 75
        g = base[1] + glow1 * 210 + glow2 * 24
        b = base[2] + glow1 * 235 + glow2 * 190

        plate = rounded_rect_alpha(x, y, 166, 190, 858, 834, 170)
        if plate > 0:
            pr, pg, pb = mix((20, 24, 34), (74, 56, 102), (nx * 0.65 + ny * 0.35))
            r = r * (1 - 0.82 * plate) + pr * 0.82 * plate
            g = g * (1 - 0.82 * plate) + pg * 0.82 * plate
            b = b * (1 - 0.82 * plate) + pb * 0.82 * plate

        # Palette thumb hole
        hole = circle_alpha(x, y, 690, 368, 78)
        if hole > 0:
            r = r * (1 - 0.9 * hole) + 8 * 0.9 * hole
            g = g * (1 - 0.9 * hole) + 10 * 0.9 * hole
            b = b * (1 - 0.9 * hole) + 16 * 0.9 * hole

        dots = [
            (355, 360, 64, (0, 229, 255)),
            (485, 475, 72, (255, 79, 216)),
            (360, 610, 70, (92, 255, 149)),
            (580, 640, 58, (77, 124, 255)),
        ]
        for cx, cy, radius, color in dots:
            a = circle_alpha(x, y, cx, cy, radius)
            if a > 0:
                r = r * (1 - a) + color[0] * a
                g = g * (1 - a) + color[1] * a
                b = b * (1 - a) + color[2] * a

        # Subtle glass border highlight
        border = max(
            rounded_rect_alpha(x, y, 158, 182, 866, 842, 178)
            - rounded_rect_alpha(x, y, 178, 202, 846, 822, 158),
            0,
        )
        r = r * (1 - border * 0.5) + 255 * border * 0.5
        g = g * (1 - border * 0.5) + 255 * border * 0.5
        b = b * (1 - border * 0.5) + 255 * border * 0.5

        row += bytes((clamp(r), clamp(g), clamp(b), 255))
    pixels += row


def chunk(kind, data):
    return (
        struct.pack(">I", len(data))
        + kind
        + data
        + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    )


png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(bytes(pixels), 9))
png += chunk(b"IEND", b"")
OUT.write_bytes(png)
print(OUT)
