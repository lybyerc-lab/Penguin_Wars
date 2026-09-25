"""Crop Township occlusion bakes and record deterministic placement metadata."""

from __future__ import annotations

import argparse
import json
import math
import shutil
from pathlib import Path

from PIL import Image


CAMERA_WIDTH_METRES = 56.0
CAMERA_GROUND_CENTRE = (0.0, -2.5)
CAMERA_TILT_RADIANS = 0.663224995136261
GODOT_PIXELS_PER_METRE = (81.0, 80.0)
PADDING = 6


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def main() -> None:
    args = arguments()
    args.output.mkdir(parents=True, exist_ok=True)
    background_source = args.input / "township_background.png"
    background_target = args.output / background_source.name
    shutil.copy2(background_source, background_target)

    with Image.open(background_source) as background:
        source_size = background.size

    layers: dict[str, dict[str, object]] = {}
    for source in sorted(args.input.glob("township_*.png")):
        if source.name == background_source.name:
            continue
        with Image.open(source) as image:
            rgba = image.convert("RGBA")
            bounds = rgba.getchannel("A").getbbox()
            if bounds is None:
                raise RuntimeError(f"Layer has no visible pixels: {source}")
            left = max(0, bounds[0] - PADDING)
            top = max(0, bounds[1] - PADDING)
            right = min(rgba.width, bounds[2] + PADDING)
            bottom = min(rgba.height, bounds[3] + PADDING)
            crop = (left, top, right, bottom)
            target = args.output / source.name
            rgba.crop(crop).save(target, optimize=True)
            layers[source.stem.removeprefix("township_")] = {
                "file": target.name,
                "crop": list(crop),
                "size": [right - left, bottom - top],
            }

    horizontal_pixels_per_metre = source_size[0] / CAMERA_WIDTH_METRES
    vertical_ground_pixels_per_metre = horizontal_pixels_per_metre * math.cos(CAMERA_TILT_RADIANS)
    metadata = {
        "source_resolution": list(source_size),
        "camera_width_metres": CAMERA_WIDTH_METRES,
        "camera_ground_centre": list(CAMERA_GROUND_CENTRE),
        "godot_pixels_per_metre": list(GODOT_PIXELS_PER_METRE),
        "sprite_scale": [
            GODOT_PIXELS_PER_METRE[0] / horizontal_pixels_per_metre,
            GODOT_PIXELS_PER_METRE[1] / vertical_ground_pixels_per_metre,
        ],
        "background": background_target.name,
        "layers": layers,
    }
    (args.output / "township_visual_manifest.json").write_text(
        json.dumps(metadata, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(metadata, indent=2))


if __name__ == "__main__":
    main()
