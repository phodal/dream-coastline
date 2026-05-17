#!/usr/bin/env python3
"""Record Story Review Mode as a hands-off review video."""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_GODOT = Path("/Applications/Godot.app/Contents/MacOS/Godot")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scene", default="01-illiterate", help="Story scene id to record.")
    parser.add_argument("--scope", choices=("scene", "all"), default="scene", help="Record one scene or continue through all remaining scenes.")
    parser.add_argument(
        "--output",
        default="artifacts/story-review/01-illiterate",
        help="Directory for native movie, mp4, and poster frame.",
    )
    parser.add_argument("--godot", default=str(DEFAULT_GODOT), help="Path to Godot executable.")
    parser.add_argument("--resolution", default="1280x720", help="Godot viewport resolution.")
    parser.add_argument("--fps", type=int, default=30, help="Fixed movie FPS.")
    parser.add_argument("--step-seconds", type=float, default=0.85, help="Seconds each story step remains on screen.")
    parser.add_argument("--max-frames", type=int, default=7200, help="Safety cap for Godot movie frames.")
    parser.add_argument("--keep-avi", action="store_true", help="Keep Godot's native AVI after mp4 transcode.")
    parser.add_argument("--keep-old", action="store_true", help="Keep old movie files before recording.")
    parser.add_argument("--headless", action="store_true", help="Use Godot headless mode. Visible mode is more reliable for movie capture on macOS.")
    return parser.parse_args()


def find_ffmpeg() -> str | None:
    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg is not None:
        return ffmpeg
    fallback = Path("/opt/homebrew/bin/ffmpeg")
    return str(fallback) if fallback.exists() else None


def main() -> int:
    args = parse_args()
    output = (ROOT / args.output).resolve() if not Path(args.output).is_absolute() else Path(args.output)
    output.mkdir(parents=True, exist_ok=True)
    if not args.keep_old:
        for pattern in ("frame_*.png", "manifest.json", "*.avi", "*.mp4", "poster.png"):
            for path in output.glob(pattern):
                path.unlink()

    godot = Path(args.godot).expanduser()
    native_movie = output / f"{args.scene}.avi"
    mp4_path = output / f"{args.scene}.mp4"
    poster_path = output / "poster.png"
    command = [
        str(godot),
        "--path",
        str(ROOT),
    ]
    if args.headless:
        command.append("--headless")
    command.extend(
        [
            "--scene",
            "res://src/main.tscn",
            "--resolution",
            args.resolution,
            "--fixed-fps",
            str(args.fps),
            "--write-movie",
            str(native_movie),
            "--disable-vsync",
            "--quit-after",
            str(args.max_frames),
            "--",
            "--play-story-review",
            "--review-scene",
            args.scene,
            "--review-scope",
            args.scope,
            "--review-step-seconds",
            str(args.step_seconds),
        ]
    )
    print(" ".join(command))
    result = subprocess.run(command, cwd=ROOT, check=False)
    if result.returncode != 0:
        return result.returncode
    if not native_movie.exists() or native_movie.stat().st_size <= 0:
        print(f"story-review-video status=FAIL reason=missing-native-movie path={native_movie}", file=sys.stderr)
        return 1

    ffmpeg = find_ffmpeg()
    if ffmpeg is None:
        print(f"story-review-video status=SKIP reason=missing-ffmpeg movie={native_movie}")
        return 0

    encode = [
        ffmpeg,
        "-y",
        "-i",
        str(native_movie),
        "-vf",
        "format=yuv420p",
        "-movflags",
        "+faststart",
        str(mp4_path),
    ]
    print(" ".join(encode))
    encoded = subprocess.run(encode, cwd=ROOT, check=False)
    if encoded.returncode != 0:
        return encoded.returncode

    poster = [ffmpeg, "-y", "-i", str(mp4_path), "-frames:v", "1", "-update", "1", str(poster_path)]
    print(" ".join(poster))
    poster_result = subprocess.run(poster, cwd=ROOT, check=False)
    if poster_result.returncode != 0:
        return poster_result.returncode

    if not args.keep_avi:
        native_movie.unlink(missing_ok=True)
    print(f"story-review-video status=PASS path={mp4_path} poster={poster_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
