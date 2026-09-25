"""Build compact runtime and approved-vs-runtime Township review sheets."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps


TILE = (640, 360)
LABEL_HEIGHT = 28

COMPARISONS = [
    ("01 Town Square", "township_visual_v0_1_1_01_gameplay_town_square.png", "01-town-square.png"),
    ("02 Great Hall", "township_visual_v0_1_1_02_gameplay_great_hall.png", "02-great-hall-focus.png"),
    ("03 Workshop", "township_visual_v0_1_1_04_gameplay_workshop.png", "03-workshop.png"),
    ("04 Nurse / homes", "township_visual_v0_1_1_07_gameplay_homes_west.png", "04-nurse-south-entrance.png"),
    ("05 Market / pond", "township_visual_v0_1_1_06_gameplay_fish_market_pond.png", "05-fish-market-pond.png"),
    ("06 Snow slide", "township_visual_v0_1_1_08_gameplay_snow_slide.png", "06-snow-slide.png"),
    ("07 Lodge / Bell / Gate", "township_visual_v0_1_1_09_gameplay_lodge_bell_gate.png", "07-lodge-bell-gate.png"),
]


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--runtime", type=Path, required=True)
    parser.add_argument("--approved", type=Path, required=True)
    return parser.parse_args()


def tile(path: Path, label: str) -> Image.Image:
    with Image.open(path) as source:
        fitted = ImageOps.fit(source.convert("RGB"), TILE, method=Image.Resampling.LANCZOS)
    result = Image.new("RGB", (TILE[0], TILE[1] + LABEL_HEIGHT), "#17202b")
    result.paste(fitted, (0, LABEL_HEIGHT))
    ImageDraw.Draw(result).text((10, 7), label, fill="white")
    return result


def runtime_sheet(runtime: Path) -> None:
    files = [path for path in sorted(runtime.glob("[0-9][0-9]-*.png")) if int(path.name[:2]) <= 10]
    rows = (len(files) + 1) // 2
    sheet = Image.new("RGB", (TILE[0] * 2, (TILE[1] + LABEL_HEIGHT) * rows), "#101721")
    for index, path in enumerate(files):
        item = tile(path, path.stem)
        sheet.paste(item, ((index % 2) * TILE[0], (index // 2) * item.height))
    sheet.save(runtime / "11-runtime-contact-sheet.png", optimize=True)


def comparison_sheet(runtime: Path, approved: Path) -> None:
    row_height = TILE[1] + LABEL_HEIGHT
    sheet = Image.new("RGB", (TILE[0] * 2, row_height * len(COMPARISONS)), "#101721")
    for index, (label, approved_name, runtime_name) in enumerate(COMPARISONS):
        sheet.paste(tile(approved / approved_name, f"APPROVED — {label}"), (0, index * row_height))
        sheet.paste(tile(runtime / runtime_name, f"RUNTIME — {label}"), (TILE[0], index * row_height))
    sheet.save(runtime / "12-approved-runtime-comparison.png", optimize=True)


def main() -> None:
    args = arguments()
    runtime_sheet(args.runtime)
    comparison_sheet(args.runtime, args.approved)


if __name__ == "__main__":
    main()
