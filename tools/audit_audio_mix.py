#!/usr/bin/env python3
"""Audit generated audio assets for release-facing mix hygiene."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
AUDIO_CUE_DIR = ROOT / "data" / "audio_cues"
ACTION_VOICE_DIR = ROOT / "data" / "action_voice_lines"
FALLBACK_TOOLS = {
    "ffmpeg": Path("/opt/homebrew/bin/ffmpeg"),
    "ffprobe": Path("/opt/homebrew/bin/ffprobe"),
}

VOLUME_RE = {
    "mean": re.compile(r"mean_volume:\s*([-\d.]+) dB"),
    "max": re.compile(r"max_volume:\s*([-\d.]+) dB"),
}

KIND_LIMITS = {
    "ambience": {"min_duration": 10.0, "max_duration": 360.0, "min_mean": -35.0, "max_mean": -8.0, "max_peak": 0.0},
    "music": {"min_duration": 10.0, "max_duration": 360.0, "min_mean": -35.0, "max_mean": -8.0, "max_peak": 0.0},
    "stinger": {"min_duration": 0.3, "max_duration": 180.0, "min_mean": -40.0, "max_mean": -8.0, "max_peak": 0.0},
    "sfx": {"min_duration": 0.1, "max_duration": 3.0, "min_mean": -50.0, "max_mean": -6.0, "max_peak": -3.0},
    "voice": {"min_duration": 0.4, "max_duration": 20.0, "min_mean": -35.0, "max_mean": -15.0, "max_peak": -2.0},
    "action_voice": {"min_duration": 0.4, "max_duration": 20.0, "min_mean": -35.0, "max_mean": -15.0, "max_peak": -2.0},
}


@dataclass(frozen=True)
class AudioAsset:
    kind: str
    asset_id: str
    path: Path
    source: str


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def tool_path(name: str) -> str | None:
    found = shutil.which(name)
    if found:
        return found
    fallback = FALLBACK_TOOLS[name]
    if fallback.exists():
        return str(fallback)
    return None


def repo_path(path_text: str) -> Path:
    path_text = path_text.replace("res://", "", 1)
    return ROOT / path_text


def record_enabled(record: dict[str, Any]) -> bool:
    if record.get("runtime_enabled") is False:
        return False
    if record.get("sample_generation") is False:
        return False
    return True


def collect_audio_assets() -> tuple[list[AudioAsset], int]:
    assets: list[AudioAsset] = []
    skipped = 0
    seen_paths: set[Path] = set()

    for cue_path in sorted(AUDIO_CUE_DIR.glob("*.json")):
        data = load_json(cue_path)
        for cue in data.get("cues", []):
            if not isinstance(cue, dict):
                continue
            if not record_enabled(cue):
                skipped += 1
                continue
            add_asset(
                assets,
                seen_paths,
                str(cue.get("type", "music")),
                str(cue.get("cue_id", "")),
                repo_path(str(cue.get("target_path", ""))),
                str(cue_path.relative_to(ROOT)),
            )
        for sound in data.get("event_sounds", []):
            if not isinstance(sound, dict):
                continue
            if not record_enabled(sound):
                skipped += 1
                continue
            add_asset(
                assets,
                seen_paths,
                "sfx",
                str(sound.get("sfx_id", "")),
                repo_path(str(sound.get("target_path", ""))),
                str(cue_path.relative_to(ROOT)),
            )
        for voice in data.get("voice_samples", []):
            if not isinstance(voice, dict):
                continue
            if not record_enabled(voice):
                skipped += 1
                continue
            add_asset(
                assets,
                seen_paths,
                "voice",
                str(voice.get("line_id", "")),
                repo_path(str(voice.get("target_path", ""))),
                str(cue_path.relative_to(ROOT)),
            )

    for manifest_path in sorted(ACTION_VOICE_DIR.glob("*.json")):
        data = load_json(manifest_path)
        for action in data.get("actions", []):
            if not isinstance(action, dict):
                continue
            action_id = str(action.get("action_id", ""))
            for line in action.get("playback_queue", []):
                if not isinstance(line, dict):
                    continue
                if line.get("status") != "generated":
                    skipped += 1
                    continue
                line_id = str(line.get("line_id", ""))
                add_asset(
                    assets,
                    seen_paths,
                    "action_voice",
                    f"{action_id}/{line_id}" if action_id else line_id,
                    repo_path(str(line.get("target_path", ""))),
                    str(manifest_path.relative_to(ROOT)),
                )
    return assets, skipped


def add_asset(
    assets: list[AudioAsset],
    seen_paths: set[Path],
    kind: str,
    asset_id: str,
    path: Path,
    source: str,
) -> None:
    if path in seen_paths:
        return
    seen_paths.add(path)
    assets.append(AudioAsset(kind=kind, asset_id=asset_id, path=path, source=source))


def probe_duration(ffprobe: str, path: Path) -> float:
    result = subprocess.run(
        [
            ffprobe,
            "-v",
            "error",
            "-show_entries",
            "format=duration",
            "-of",
            "default=noprint_wrappers=1:nokey=1",
            str(path),
        ],
        cwd=ROOT,
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "ffprobe failed")
    return float(result.stdout.strip())


def measure_volume(ffmpeg: str, path: Path) -> tuple[float, float]:
    result = subprocess.run(
        [ffmpeg, "-hide_banner", "-nostats", "-i", str(path), "-af", "volumedetect", "-f", "null", "-"],
        cwd=ROOT,
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "ffmpeg volumedetect failed")
    mean_match = VOLUME_RE["mean"].search(result.stderr)
    max_match = VOLUME_RE["max"].search(result.stderr)
    if mean_match is None or max_match is None:
        raise RuntimeError("ffmpeg volumedetect did not report mean/max volume")
    return float(mean_match.group(1)), float(max_match.group(1))


def audit_asset(asset: AudioAsset, ffprobe: str, ffmpeg: str) -> tuple[dict[str, Any], list[str], list[str]]:
    rel_path = str(asset.path.relative_to(ROOT)) if asset.path.is_relative_to(ROOT) else str(asset.path)
    record: dict[str, Any] = {
        "kind": asset.kind,
        "asset_id": asset.asset_id,
        "path": rel_path,
        "source": asset.source,
    }
    failures: list[str] = []
    warnings: list[str] = []

    if asset.kind not in KIND_LIMITS:
        failures.append(f"{asset.asset_id}: unsupported audio kind {asset.kind}")
        return record, failures, warnings
    if not asset.path.exists():
        failures.append(f"{asset.asset_id}: missing audio file {rel_path}")
        return record, failures, warnings
    if asset.path.stat().st_size <= 0:
        failures.append(f"{asset.asset_id}: empty audio file {rel_path}")
        return record, failures, warnings
    import_path = Path(str(asset.path) + ".import")
    if not import_path.exists():
        failures.append(f"{asset.asset_id}: missing Godot import metadata {import_path.relative_to(ROOT)}")

    try:
        duration = probe_duration(ffprobe, asset.path)
        mean_volume, max_volume = measure_volume(ffmpeg, asset.path)
    except (RuntimeError, ValueError) as error:
        failures.append(f"{asset.asset_id}: cannot inspect {rel_path}: {error}")
        return record, failures, warnings

    record.update(
        {
            "duration_seconds": round(duration, 3),
            "mean_volume_db": mean_volume,
            "max_volume_db": max_volume,
        }
    )
    limits = KIND_LIMITS[asset.kind]
    if duration < limits["min_duration"] or duration > limits["max_duration"]:
        failures.append(
            f"{asset.asset_id}: duration {duration:.3f}s outside {limits['min_duration']}-{limits['max_duration']}s"
        )
    if mean_volume < limits["min_mean"] or mean_volume > limits["max_mean"]:
        failures.append(
            f"{asset.asset_id}: mean volume {mean_volume:.1f} dB outside {limits['min_mean']}-{limits['max_mean']} dB"
        )
    if max_volume > limits["max_peak"]:
        failures.append(f"{asset.asset_id}: max volume {max_volume:.1f} dB exceeds {limits['max_peak']} dB")
    if asset.kind in {"ambience", "music", "stinger"} and max_volume >= -1.0:
        warnings.append(f"{asset.asset_id}: hot peak {max_volume:.1f} dB; review before final mastering")
    return record, failures, warnings


def write_report(path: Path, report: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json-output", type=Path, help="Write detailed audit JSON to this path.")
    args = parser.parse_args()

    ffprobe = tool_path("ffprobe")
    ffmpeg = tool_path("ffmpeg")
    if ffprobe is None or ffmpeg is None:
        missing = ", ".join(name for name, value in [("ffprobe", ffprobe), ("ffmpeg", ffmpeg)] if value is None)
        print(f"audio-mix-audit status=SKIP reason=missing-tools tools={missing}")
        return 0

    assets, skipped = collect_audio_assets()
    records: list[dict[str, Any]] = []
    failures: list[str] = []
    warnings: list[str] = []
    for asset in assets:
        record, asset_failures, asset_warnings = audit_asset(asset, ffprobe, ffmpeg)
        records.append(record)
        failures.extend(asset_failures)
        warnings.extend(asset_warnings)

    by_kind: dict[str, int] = {}
    for record in records:
        by_kind[record["kind"]] = by_kind.get(record["kind"], 0) + 1
    report = {
        "status": "FAIL" if failures else "PASS",
        "asset_count": len(records),
        "skipped_count": skipped,
        "hot_peak_warning_count": len(warnings),
        "by_kind": dict(sorted(by_kind.items())),
        "warnings": warnings,
        "failures": failures,
        "assets": records,
    }
    if args.json_output is not None:
        output_path = args.json_output if args.json_output.is_absolute() else ROOT / args.json_output
        write_report(output_path, report)

    for failure in failures:
        print(f"audio-mix-audit: {failure}")
    for warning in warnings[:10]:
        print(f"audio-mix-audit warning: {warning}")
    if len(warnings) > 10:
        print(f"audio-mix-audit warning: ... {len(warnings) - 10} more hot peaks in JSON report")
    print(
        "audio-mix-audit status=%s assets=%d skipped=%d hot_peaks=%d report=%s"
        % (
            report["status"],
            report["asset_count"],
            report["skipped_count"],
            report["hot_peak_warning_count"],
            str(args.json_output or ""),
        )
    )
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
