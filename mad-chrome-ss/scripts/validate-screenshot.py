#!/usr/bin/env python3
"""Validate final screenshot dimensions and white outer corners."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("image")
    parser.add_argument("--width", type=int, default=1280)
    parser.add_argument("--height", type=int, default=800)
    parser.add_argument("--white-threshold", type=int, default=245)
    args = parser.parse_args()

    path = Path(args.image)
    if not path.is_file():
        print(f"image not found: {path}", file=sys.stderr)
        return 1

    image = Image.open(path).convert("RGB")
    expected = (args.width, args.height)
    if image.size != expected:
        print(f"wrong dimensions: {image.size}, expected {expected}", file=sys.stderr)
        return 1

    corners = [
        (0, 0),
        (image.width - 1, 0),
        (0, image.height - 1),
        (image.width - 1, image.height - 1),
    ]
    failures = [
        (point, image.getpixel(point))
        for point in corners
        if min(image.getpixel(point)) < args.white_threshold
    ]
    if failures:
        print(f"outer corners are not white: {failures}", file=sys.stderr)
        return 1

    print(f"verified {path} {image.width}x{image.height} white-corners=OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
