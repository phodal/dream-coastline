#!/usr/bin/env python3
"""Lower hot peaks in generated long-form music/ambience assets."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REPORT_PATH = ROOT / "artifacts" / "audio-mix-audit" / "latest.json"
LONG_AUDIO_KINDS = {"ambience", "music", "stinger"}
TARGET_PEAK_THRESHOLD_DB = -1.0
MASTERING_GAIN_DB = -2.0


def tool_path(name: str) -> str:
    found = shutil.which(name)
    if found:
        return found
    fallback = Path("/opt/homebrew/bin") / name
    if fallback.exists():
        return str(fallback)
    raise FileNotFoundError(name)


def run_audit() -> None:
    command = [
        sys.executable,
        "tools/audit_audio_mix.py",
        "--json-output",
        str(REPORT_PATH.relative_to(ROOT)),
    ]
    result = subprocess.run(command, cwd=ROOT, check=False)
    if result.returncode != 0:
        raise RuntimeError("audio mix audit failed before mastering")


def load_targets() -> list[dict]:
    report = json.loads(REPORT_PATH.read_text(encoding="utf-8"))
    targets: list[dict] = []
    for asset in report.get("assets", []):
        if asset.get("kind") not in LONG_AUDIO_KINDS:
            continue
        max_volume = asset.get("max_volume_db")
        if not isinstance(max_volume, (int, float)):
            continue
        if float(max_volume) >= TARGET_PEAK_THRESHOLD_DB:
            targets.append(asset)
    return targets


def master_asset(ffmpeg: str, asset: dict, apply: bool) -> None:
    relative_path = Path(str(asset["path"]))
    source = ROOT / relative_path
    temp = source.with_suffix(source.suffix + ".mastering-tmp.mp3")
    print(
        "audio-hot-peak-master target=%s kind=%s max=%.1f gain=%.1f apply=%s"
        % (
            relative_path,
            asset.get("kind", ""),
            float(asset.get("max_volume_db", 0.0)),
            MASTERING_GAIN_DB,
            str(apply).lower(),
        )
    )
    if not apply:
        return
    command = [
        ffmpeg,
        "-y",
        "-hide_banner",
        "-nostats",
        "-i",
        str(source),
        "-af",
        "volume=%.1fdB" % MASTERING_GAIN_DB,
        "-codec:a",
        "libmp3lame",
        "-q:a",
        "2",
        str(temp),
    ]
    result = subprocess.run(command, cwd=ROOT, check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode != 0:
        try:
            temp.unlink()
        except FileNotFoundError:
            pass
        raise RuntimeError("ffmpeg failed for %s: %s" % (relative_path, result.stderr.strip()))
    temp.replace(source)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="Rewrite target MP3 files in place.")
    args = parser.parse_args()

    try:
        ffmpeg = tool_path("ffmpeg")
    except FileNotFoundError as error:
        print(f"audio-hot-peak-master status=SKIP reason=missing-tool tool={error.filename}")
        return 0

    run_audit()
    targets = load_targets()
    for asset in targets:
        master_asset(ffmpeg, asset, args.apply)
    print("audio-hot-peak-master status=PASS targets=%d applied=%s" % (len(targets), str(args.apply).lower()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
