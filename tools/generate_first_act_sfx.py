#!/usr/bin/env python3
"""Generate short first-act one-shot SFX as MP3 assets.

MiniMax is used for long-form music and voice. These short gameplay effects are
procedural so they stay under one second and behave like one-shot game sounds.
"""

from __future__ import annotations

import json
import math
import random
import struct
import subprocess
import tempfile
import wave
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable


ROOT = Path(__file__).resolve().parents[1]
CUES = ROOT / "data" / "audio_cues" / "01-illiterate.json"
MANIFEST = ROOT / "data" / "audio_generation_manifest.json"
SAMPLE_RATE = 44100


def envelope(t: float, duration: float, attack: float = 0.015, release: float = 0.09) -> float:
    if t < attack:
        return t / attack
    remaining = max(0.0, duration - t)
    if remaining < release:
        return remaining / release
    return 1.0


def noise() -> float:
    return random.uniform(-1.0, 1.0)


def tone(freq: float, t: float, phase: float = 0.0) -> float:
    return math.sin((math.tau * freq * t) + phase)


def render(duration: float, fn: Callable[[float], float]) -> list[int]:
    frames = []
    for index in range(int(SAMPLE_RATE * duration)):
        t = index / SAMPLE_RATE
        value = max(-1.0, min(1.0, fn(t)))
        frames.append(int(value * 32767.0))
    return frames


def write_wav(path: Path, frames: list[int]) -> None:
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(b"".join(struct.pack("<h", sample) for sample in frames))


def convert_to_mp3(wav_path: Path, mp3_path: Path) -> None:
    mp3_path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-hide_banner",
            "-loglevel",
            "error",
            "-i",
            str(wav_path),
            "-codec:a",
            "libmp3lame",
            "-b:a",
            "128k",
            str(mp3_path),
        ],
        check=True,
    )


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def load_manifest() -> dict:
    if MANIFEST.exists():
        return json.loads(MANIFEST.read_text(encoding="utf-8"))
    return {"schema_version": 1, "provider": "minimax", "generated_at": utc_now(), "assets": []}


def upsert_manifest_asset(manifest: dict, sound: dict, frame_count: int, generated_at: str) -> None:
    output_path = str(sound["target_path"])
    target = ROOT / output_path
    asset = {
        "asset_id": sound["sfx_id"],
        "type": "sfx",
        "provider": "local-procedural",
        "scene_id": sound["scene_id"],
        "event_name": sound["event_name"],
        "model": "tools/generate_first_act_sfx.py",
        "output_path": output_path,
        "prompt_summary": sound.get("instrumentation_prompt", ""),
        "status": "generated",
        "generated_at": generated_at,
        "extra_info": {
            "duration_ms": round(frame_count / SAMPLE_RATE * 1000),
            "sample_rate": SAMPLE_RATE,
            "channel": 1,
            "bitrate": 128000,
            "size": target.stat().st_size,
        },
    }
    assets = manifest.setdefault("assets", [])
    for index, existing in enumerate(assets):
        if existing.get("asset_id") == asset["asset_id"]:
            assets[index] = asset
            break
    else:
        assets.append(asset)


def write_manifest(manifest: dict, generated_at: str) -> None:
    manifest["generated_at"] = generated_at
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def step_mud() -> list[int]:
    random.seed("SFX-01-STEP-MUD")
    duration = 0.34

    def sample(t: float) -> float:
        hit = math.exp(-t * 20.0) * (0.48 * tone(72.0, t) + 0.16 * noise())
        grit = math.exp(-max(0.0, t - 0.055) * 42.0) * 0.11 * noise()
        return (hit + grit) * envelope(t, duration, 0.006, 0.12)

    return render(duration, sample)


def step_wood() -> list[int]:
    random.seed("SFX-01-STEP-WOOD")
    duration = 0.28

    def sample(t: float) -> float:
        knock = math.exp(-t * 32.0) * (0.42 * tone(150.0, t) + 0.22 * tone(240.0, t))
        creak = math.exp(-max(0.0, t - 0.055) * 18.0) * 0.12 * tone(510.0 - t * 210.0, t)
        return (knock + creak + 0.05 * noise()) * envelope(t, duration, 0.004, 0.11)

    return render(duration, sample)


def ink_write() -> list[int]:
    random.seed("SFX-01-INK-WRITE")
    duration = 0.82

    def sample(t: float) -> float:
        scratch = 0.20 * noise() * (1.0 if 0.04 < t < 0.48 else 0.35)
        brush = 0.17 * tone(380.0 + 55.0 * math.sin(t * 24.0), t)
        shimmer = 0.12 * tone(1120.0 + 260.0 * t, t) * max(0.0, (t - 0.38) / 0.44)
        bloom = 0.18 * tone(96.0, t) * math.exp(-max(0.0, t - 0.44) * 5.5)
        return (scratch + brush + shimmer + bloom) * envelope(t, duration, 0.02, 0.2)

    return render(duration, sample)


def blade_hit() -> list[int]:
    random.seed("SFX-01-BLADE-HIT")
    duration = 0.56

    def sample(t: float) -> float:
        slash = 0.24 * tone(1480.0 - t * 1180.0, t) * math.exp(-t * 6.0)
        scrape = 0.18 * noise() * math.exp(-t * 10.0)
        impact = 0.38 * tone(118.0, t) * math.exp(-max(0.0, t - 0.16) * 18.0)
        return (slash + scrape + impact) * envelope(t, duration, 0.005, 0.16)

    return render(duration, sample)


def paper_interact() -> list[int]:
    random.seed("SFX-01-PAPER-INTERACT")
    duration = 0.45

    def sample(t: float) -> float:
        rustle = 0.16 * noise() * math.exp(-t * 3.5)
        ink = 0.10 * tone(640.0 + math.sin(t * 40.0) * 55.0, t) * math.exp(-t * 7.0)
        confirm = 0.10 * tone(980.0, t) * math.exp(-max(0.0, t - 0.24) * 18.0)
        return (rustle + ink + confirm) * envelope(t, duration, 0.008, 0.14)

    return render(duration, sample)


GENERATORS = {
    "SFX-01-STEP-MUD": step_mud,
    "SFX-01-STEP-WOOD": step_wood,
    "SFX-01-INK-WRITE": ink_write,
    "SFX-01-BLADE-HIT": blade_hit,
    "SFX-01-PAPER-INTERACT": paper_interact,
}


def main() -> int:
    cue_data = json.loads(CUES.read_text(encoding="utf-8"))
    manifest = load_manifest()
    generated_at = utc_now()
    generated = 0
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_root = Path(temp_dir)
        for sound in cue_data.get("event_sounds", []):
            sfx_id = sound.get("sfx_id", "")
            generator = GENERATORS.get(sfx_id)
            if generator is None:
                continue
            wav_path = temp_root / f"{sfx_id}.wav"
            target = ROOT / str(sound["target_path"])
            frames = generator()
            write_wav(wav_path, frames)
            convert_to_mp3(wav_path, target)
            upsert_manifest_asset(manifest, sound, len(frames), generated_at)
            print(f"generated {target.relative_to(ROOT)}")
            generated += 1
    write_manifest(manifest, generated_at)
    print(f"first-act-sfx: generated {generated} file(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
