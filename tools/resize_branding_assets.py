#!/usr/bin/env python3
"""Resize project branding images to Godot-friendly dimensions."""

from __future__ import annotations

import argparse
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BRANDING_DIR = ROOT / "assets" / "branding"
DEFAULT_ICON = BRANDING_DIR / "dream-coastline-icon.png"
DEFAULT_SPLASH = BRANDING_DIR / "dream-coastline-splash.png"


def run_sips(args: list[str]) -> None:
    if shutil.which("sips") is None:
        raise SystemExit("This script requires macOS `sips` on PATH.")
    subprocess.run(["sips", *args], check=True)


def resize_exact(path: Path, width: int, height: int) -> None:
    if not path.exists():
        raise SystemExit(f"Missing image: {path}")
    run_sips(["-z", str(height), str(width), str(path)])


def optimize_png(path: Path) -> None:
    if not path.exists():
        return
    pngquant = shutil.which("pngquant")
    if pngquant is None:
        return
    subprocess.run(
        [
            pngquant,
            "--force",
            "--skip-if-larger",
            "--strip",
            "--ext",
            ".png",
            str(path),
        ],
        check=True,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--icon", type=Path, default=DEFAULT_ICON)
    parser.add_argument("--icon-size", type=int, default=256)
    parser.add_argument("--splash", type=Path, default=DEFAULT_SPLASH)
    parser.add_argument("--splash-width", type=int, default=1280)
    parser.add_argument("--splash-height", type=int, default=720)
    parser.add_argument("--no-optimize", action="store_true")
    args = parser.parse_args()

    resize_exact(args.icon, args.icon_size, args.icon_size)
    if args.splash.exists():
        resize_exact(args.splash, args.splash_width, args.splash_height)

    if not args.no_optimize:
        optimize_png(args.icon)
        optimize_png(args.splash)

    print(f"icon={args.icon} {args.icon_size}x{args.icon_size}")
    if args.splash.exists():
        print(f"splash={args.splash} {args.splash_width}x{args.splash_height}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
