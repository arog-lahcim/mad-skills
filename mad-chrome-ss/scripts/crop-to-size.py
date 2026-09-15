#!/usr/bin/env python3
"""Crop a window capture to content bbox and resize to target dimensions."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image


def content_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    bbox = alpha.getbbox()
    if bbox:
        return bbox

    rgb = rgba.convert("RGB")
    width, height = rgb.size
    pixels = rgb.load()
    min_x, min_y = width, height
    max_x, max_y = 0, 0
    found = False

    for y in range(height):
        for x in range(width):
            r, g, b = pixels[x, y]
            if r > 250 and g > 250 and b > 250:
                continue
            found = True
            min_x = min(min_x, x)
            min_y = min(min_y, y)
            max_x = max(max_x, x)
            max_y = max(max_y, y)

    if not found:
        return (0, 0, width, height)
    return (min_x, min_y, max_x + 1, max_y + 1)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("output")
    parser.add_argument("--width", type=int, default=1280)
    parser.add_argument("--height", type=int, default=800)
    args = parser.parse_args()

    source = Path(args.input)
    destination = Path(args.output)
    if not source.is_file():
        print(f"input not found: {source}", file=sys.stderr)
        return 1

    image = Image.open(source)
    bbox = content_bbox(image)
    cropped = image.crop(bbox).convert("RGB")
    final = cropped.resize((args.width, args.height), Image.Resampling.LANCZOS)

    destination.parent.mkdir(parents=True, exist_ok=True)
    final.save(destination, format="PNG", optimize=True)
    print(f"{destination} {final.size}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
