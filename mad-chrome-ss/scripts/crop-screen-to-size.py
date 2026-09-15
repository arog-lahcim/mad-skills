#!/usr/bin/env python3
"""Crop a target-ratio frame around a browser window from a full-screen capture."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image


def parse_rect(value: str) -> tuple[float, float, float, float]:
    parts = [float(part) for part in value.split(",")]
    if len(parts) != 4:
        raise argparse.ArgumentTypeError("expected x,y,width,height")
    return tuple(parts)  # type: ignore[return-value]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("output")
    parser.add_argument("--screen", required=True, type=parse_rect)
    parser.add_argument("--window", required=True, type=parse_rect)
    parser.add_argument("--width", type=int, default=1280)
    parser.add_argument("--height", type=int, default=800)
    parser.add_argument("--margin", type=float, default=48)
    args = parser.parse_args()

    source_path = Path(args.input)
    destination = Path(args.output)
    if not source_path.is_file():
        print(f"input not found: {source_path}", file=sys.stderr)
        return 1

    image = Image.open(source_path).convert("RGB")
    screen_x, screen_y, screen_width, screen_height = args.screen
    window_x, window_y, window_width, window_height = args.window
    if screen_width <= 0 or screen_height <= 0:
        print("screen dimensions must be positive", file=sys.stderr)
        return 1

    local_x = window_x - screen_x
    local_y = window_y - screen_y
    box_width = window_width + 2 * args.margin
    box_height = window_height + 2 * args.margin
    target_ratio = args.width / args.height

    crop_width = max(box_width, box_height * target_ratio)
    crop_height = crop_width / target_ratio
    if crop_height < box_height:
        crop_height = box_height
        crop_width = crop_height * target_ratio
    if crop_width > screen_width or crop_height > screen_height:
        print(
            "window plus margin cannot fit inside a target-ratio screen crop",
            file=sys.stderr,
        )
        return 1

    center_x = local_x + window_width / 2
    center_y = local_y + window_height / 2
    crop_x = center_x - crop_width / 2
    crop_y = center_y - crop_height / 2

    crop_x = min(max(0, crop_x), max(0, screen_width - crop_width))
    crop_y = min(max(0, crop_y), max(0, screen_height - crop_height))

    scale_x = image.width / screen_width
    scale_y = image.height / screen_height
    if abs(scale_x - scale_y) > 0.01:
        print(
            f"non-uniform display scale: scale_x={scale_x}, scale_y={scale_y}",
            file=sys.stderr,
        )
        return 1
    pixel_box = (
        round(crop_x * scale_x),
        round(crop_y * scale_y),
        round((crop_x + crop_width) * scale_x),
        round((crop_y + crop_height) * scale_y),
    )

    cropped = image.crop(pixel_box)
    final = cropped.resize((args.width, args.height), Image.Resampling.LANCZOS)
    destination.parent.mkdir(parents=True, exist_ok=True)
    final.save(destination, format="PNG", optimize=True)

    print(
        f"{destination} {final.size} crop={pixel_box} "
        f"scale_x={scale_x:.6f} scale_y={scale_y:.6f}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
