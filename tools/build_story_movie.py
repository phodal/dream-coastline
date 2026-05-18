#!/usr/bin/env python3
"""Build a subtitle-and-music story movie from scene JSON and review art."""

from __future__ import annotations

import argparse
import html
import json
import math
import shutil
import subprocess
import sys
import textwrap
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = "artifacts/story-movie/dream-coastline-story-movie.mp4"
DEFAULT_SIZE = "1920x1080"
DEFAULT_FONT = "PingFang SC"


@dataclass
class Card:
    scene_id: str
    command: str
    title: str
    body: str
    image: Path
    music: Path | None
    sfx: Path | None
    voices: list[Path]
    duration: float


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--scene",
        default="all",
        help="Scene id to render, or 'all' for every story scene.",
    )
    parser.add_argument("--output", default=DEFAULT_OUTPUT, help="Output mp4 path.")
    parser.add_argument("--size", default=DEFAULT_SIZE, help="Video size, for example 1920x1080.")
    parser.add_argument("--fps", type=int, default=24, help="Output frame rate.")
    parser.add_argument("--font", default=DEFAULT_FONT, help="ASS subtitle font family.")
    parser.add_argument("--title-seconds", type=float, default=4.0, help="Duration for scene title cards.")
    parser.add_argument("--min-seconds", type=float, default=3.2, help="Minimum duration per story beat.")
    parser.add_argument("--max-seconds", type=float, default=7.0, help="Maximum duration per story beat.")
    parser.add_argument("--seconds-per-char", type=float, default=0.085, help="Subtitle duration budget per CJK character.")
    parser.add_argument("--music-volume", type=float, default=0.32, help="Background music volume multiplier.")
    parser.add_argument("--sfx-volume", type=float, default=0.42, help="One-shot event sound volume multiplier.")
    parser.add_argument("--voice-volume", type=float, default=1.28, help="Voice sample volume multiplier.")
    parser.add_argument("--no-sfx", action="store_true", help="Do not mix event SFX into the movie audio.")
    parser.add_argument("--no-voices", action="store_true", help="Do not mix generated voice samples into the movie audio.")
    parser.add_argument("--keep-workdir", action="store_true", help="Keep intermediate concat/subtitle/audio files.")
    return parser.parse_args()


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def repo_path(path_text: str) -> Path:
    path = path_text.split("#", 1)[0]
    if path.startswith("res://"):
        path = path.removeprefix("res://")
    return ROOT / path


def ffmpeg() -> str:
    found = shutil.which("ffmpeg")
    if found:
        return found
    fallback = Path("/opt/homebrew/bin/ffmpeg")
    if fallback.exists():
        return str(fallback)
    raise RuntimeError("ffmpeg not found")


def pango_view() -> str:
    found = shutil.which("pango-view")
    if found:
        return found
    fallback = Path("/opt/homebrew/bin/pango-view")
    if fallback.exists():
        return str(fallback)
    raise RuntimeError("pango-view not found; install pango or use a Python build with image rendering support")


def ffprobe_duration(path: Path) -> float:
    command = [
        "ffprobe",
        "-v",
        "error",
        "-show_entries",
        "format=duration",
        "-of",
        "default=noprint_wrappers=1:nokey=1",
        str(path),
    ]
    try:
        result = subprocess.run(command, cwd=ROOT, text=True, capture_output=True, check=True)
        return float(result.stdout.strip())
    except Exception:
        return 0.0


def scene_ids(selected: str) -> list[str]:
    ids = sorted(path.stem for path in (ROOT / "data/story_scenes").glob("*.json"))
    if selected == "all":
        return ids
    if selected not in ids:
        raise RuntimeError(f"Unknown scene id: {selected}")
    return [selected]


def choose_music(scene_id: str, location_id: str | None, audio_cues: dict[str, Any]) -> Path | None:
    candidates = []
    scene_fallback: Path | None = None
    for cue in audio_cues.get("cues", []):
        if not isinstance(cue, dict) or cue.get("type") != "music":
            continue
        if cue.get("runtime_enabled") is False:
            continue
        target = repo_path(str(cue.get("target_path", "")))
        if not target.exists():
            continue
        if scene_fallback is None:
            scene_fallback = target
        score = 0
        if location_id and cue.get("location_id") == location_id:
            score += 10
        if str(cue.get("cue_id", "")).startswith("AMB-"):
            score += 2
        candidates.append((score, str(cue.get("cue_id", "")), target))
    if not candidates:
        return scene_fallback
    candidates.sort(key=lambda item: (-item[0], item[1]))
    return candidates[0][2]


def event_name_for_command(command: str) -> str:
    parts = command.split(" ", 1)
    verb = parts[0]
    arg = parts[1] if len(parts) > 1 else ""
    if verb == "go":
        return "step"
    if verb == "inspect":
        return "interact"
    if verb == "cast":
        return f"cast_{arg}"
    if verb == "combine":
        return arg or verb
    return verb


def choose_sfx(command: str, location_id: str | None, audio_cues: dict[str, Any]) -> Path | None:
    event_name = event_name_for_command(command)
    candidates: list[tuple[int, str, Path]] = []
    for sound in audio_cues.get("event_sounds", []):
        if not isinstance(sound, dict):
            continue
        target = repo_path(str(sound.get("target_path", "")))
        if not target.exists():
            continue
        score = 0
        if sound.get("event_name") == event_name:
            score += 10
        elif event_name.startswith("cast_") and sound.get("event_name") == "write":
            score += 2
        else:
            continue
        locations = [str(location) for location in sound.get("locations", [])]
        if location_id and location_id in locations:
            score += 5
        candidates.append((score, str(sound.get("sfx_id", "")), target))
    if not candidates:
        return None
    candidates.sort(key=lambda item: (-item[0], item[1]))
    return candidates[0][2]


def choose_voices(body: str, audio_cues: dict[str, Any]) -> list[Path]:
    voices: list[Path] = []
    for line in audio_cues.get("voice_samples", []):
        if not isinstance(line, dict):
            continue
        text = str(line.get("text", ""))
        if not text or text not in body:
            continue
        target = repo_path(str(line.get("target_path", "")))
        if target.exists():
            voices.append(target)
    return voices


def command_text(scene: dict[str, Any], location_id: str, command: str, attack_count: int) -> tuple[str, str, str, int]:
    locations = scene.get("locations", {})
    location = locations.get(location_id, {})
    parts = command.split(" ", 1)
    verb = parts[0]
    arg = parts[1] if len(parts) > 1 else ""

    if verb == "go" and arg in locations:
        target = locations[arg]
        title = str(target.get("name", arg))
        body = str(target.get("location_intro") or target.get("description") or title)
        return arg, title, body, attack_count

    if verb == "inspect":
        item = location.get("items", {}).get(arg)
        if isinstance(item, dict):
            return location_id, str(item.get("name", arg)), str(item.get("text", "")), attack_count

    for collection_name in ("glyph_actions", "build_actions", "choices"):
        action = location.get(collection_name, {}).get(arg)
        if isinstance(action, dict) and verb in {"write", "cast", "build", "choose", "combine"}:
            title = str(action.get("name", f"{verb} {arg}"))
            body = str(action.get("text") or action.get("success_text") or action.get("description") or title)
            return location_id, title, body, attack_count

    if verb == "engage":
        encounter = location.get("encounters", {}).get(arg) or location.get("creature_encounters", {}).get(arg)
        if isinstance(encounter, dict):
            title = str(encounter.get("name", arg))
            body = str(encounter.get("first_meeting") or encounter.get("story_function") or title)
            return location_id, title, body, attack_count

    if verb == "attack":
        combat = location.get("combat", {})
        attack_count += 1
        enemy = str(combat.get("revealed_name") or combat.get("hidden_name") or "敌人")
        hp = int(combat.get("enemy_hp", 3) or 3)
        if attack_count >= hp:
            body = f"{enemy}被最后一击压回纸页。战斗结束，留下的问题比胜利更重。"
        else:
            body = f"第{attack_count}次攻击命中{enemy}。名字、笔画和伤口暂时稳定下来。"
        return location_id, enemy, body, attack_count

    title = command
    body = str(location.get("description") or scene.get("title") or command)
    return location_id, title, body, attack_count


def load_panels(scene_id: str, illustrations: dict[str, Any]) -> list[dict[str, Any]]:
    records = illustrations.get("illustrations", {}).get(scene_id, [])
    return [record for record in records if isinstance(record, dict)]


def choose_image(
    scene_id: str,
    command: str,
    location_id: str,
    panels: list[dict[str, Any]],
) -> Path:
    fallback: Path | None = None
    for panel in panels:
        path = repo_path(str(panel.get("path", "")))
        if path.exists() and fallback is None:
            fallback = path
        commands = [str(value) for value in panel.get("commands", [])]
        locations = [str(value) for value in panel.get("locations", [])]
        if command in commands and path.exists():
            return path
        if location_id in locations and path.exists():
            return path
    if fallback is not None:
        return fallback
    chapter = ROOT / f"assets/illustrations/chapters/{scene_id}-01.png"
    if chapter.exists():
        return chapter
    raise RuntimeError(f"No usable image for {scene_id}")


def wrap_ass_text(text: str, width: int = 28, lines: int = 3) -> str:
    text = " ".join(str(text).replace("\n", " ").split())
    if not text:
        return ""
    wrapped = textwrap.wrap(text, width=width, break_long_words=True, replace_whitespace=False)
    if len(wrapped) > lines:
        wrapped = wrapped[: lines - 1] + [wrapped[lines - 1] + "..."]
    return r"\N".join(escape_ass(line) for line in wrapped)


def escape_ass(text: str) -> str:
    return text.replace("\\", r"\\").replace("{", r"\{").replace("}", r"\}")


def ass_time(seconds: float) -> str:
    centiseconds = int(round(seconds * 100))
    h = centiseconds // 360000
    centiseconds %= 360000
    m = centiseconds // 6000
    centiseconds %= 6000
    s = centiseconds // 100
    cs = centiseconds % 100
    return f"{h}:{m:02d}:{s:02d}.{cs:02d}"


def subtitle_duration(text: str, args: argparse.Namespace) -> float:
    return max(args.min_seconds, min(args.max_seconds, len(text) * args.seconds_per_char))


def build_cards(args: argparse.Namespace) -> list[Card]:
    illustrations = load_json(ROOT / "data/chapter_illustrations.json")
    cards: list[Card] = []
    for scene_id in scene_ids(args.scene):
        scene = load_json(ROOT / f"data/story_scenes/{scene_id}.json")
        audio_cues = load_json(ROOT / f"data/audio_cues/{scene_id}.json")
        panels = load_panels(scene_id, illustrations)
        start = str(scene.get("start", ""))
        start_location = scene.get("locations", {}).get(start, {})
        music = choose_music(scene_id, start, audio_cues)
        title_image = choose_image(scene_id, "__title__", start, panels)
        title_body = str(start_location.get("description") or "")
        title_voices = [] if args.no_voices else choose_voices(title_body, audio_cues)
        title_duration = max(args.title_seconds, subtitle_duration(title_body, args))
        for voice in title_voices:
            title_duration = max(title_duration, ffprobe_duration(voice) + 1.2)
        cards.append(
            Card(
                scene_id=scene_id,
                command="title",
                title=str(scene.get("title", scene_id)),
                body=title_body,
                image=title_image,
                music=music,
                sfx=None,
                voices=title_voices,
                duration=title_duration,
            )
        )

        current_location = start
        attack_count = 0
        for command in scene.get("walkthrough", []):
            command = str(command)
            next_location, title, body, attack_count = command_text(scene, current_location, command, attack_count)
            current_location = next_location
            image = choose_image(scene_id, command, current_location, panels)
            music = choose_music(scene_id, current_location, audio_cues)
            sfx = None if args.no_sfx else choose_sfx(command, current_location, audio_cues)
            voices = [] if args.no_voices else choose_voices(body, audio_cues)
            duration = subtitle_duration(f"{title} {body}", args)
            for voice in voices:
                duration = max(duration, ffprobe_duration(voice) + 1.2)
            cards.append(Card(scene_id, command, title, body, image, music, sfx, voices, duration))
    return cards


def align_card_durations(cards: list[Card], fps: int) -> None:
    frame = 1.0 / max(1, fps)
    for card in cards:
        card.duration = max(frame, math.ceil(card.duration / frame) * frame)


def write_concat_file(cards: list[Card], path: Path) -> None:
    lines: list[str] = []
    for card in cards:
        lines.append(f"file '{card.image.resolve().as_posix()}'")
        lines.append(f"duration {card.duration:.3f}")
    lines.append(f"file '{cards[-1].image.resolve().as_posix()}'")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_ass(cards: list[Card], path: Path, size: tuple[int, int], font: str) -> None:
    width, height = size
    font_size = max(38, round(height * 0.046))
    title_size = max(26, round(height * 0.032))
    margin_v = max(48, round(height * 0.08))
    header = f"""[Script Info]
ScriptType: v4.00+
PlayResX: {width}
PlayResY: {height}
WrapStyle: 0
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Body,{font},{font_size},&H00F5F1E8,&H000000FF,&HAA000000,&H9A000000,0,0,0,0,100,100,0,0,1,3,1.2,2,110,110,{margin_v},1
Style: Title,{font},{title_size},&H00C8E6FF,&H000000FF,&HAA000000,&H9A000000,1,0,0,0,100,100,0,0,1,2.6,1,2,110,110,{margin_v + font_size * 3},1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
    events: list[str] = []
    cursor = 0.0
    for index, card in enumerate(cards):
        start = cursor
        end = cursor + card.duration
        title = wrap_ass_text(card.title, width=24, lines=1)
        body = wrap_ass_text(card.body, width=31, lines=3)
        events.append(f"Dialogue: 0,{ass_time(start)},{ass_time(end)},Title,,0,0,0,,{title}")
        if body:
            events.append(f"Dialogue: 1,{ass_time(start)},{ass_time(end)},Body,,0,0,0,,{body}")
        cursor = end
    path.write_text(header + "\n".join(events) + "\n", encoding="utf-8")


def write_subtitle_png(card: Card, path: Path, width: int, font: str) -> None:
    title = html.escape(card.title)
    body = html.escape(card.body)
    markup = (
        f'<span foreground="#c8e6ff" weight="bold" size="31500">{title}</span>'
        f'\n<span foreground="#f5f1e8" size="42000">{body}</span>'
    )
    subprocess.run(
        [
            pango_view(),
            "-q",
            "--markup",
            "--pixels",
            "--background",
            "#000000aa",
            "--font",
            f"{font} 42",
            "--width",
            str(width),
            "--wrap",
            "word-char",
            "--align",
            "center",
            "--margin",
            "32",
            "--output",
            str(path),
            "--text",
            markup,
        ],
        cwd=ROOT,
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def write_video_segments(
    cards: list[Card],
    workdir: Path,
    size: tuple[int, int],
    fps: int,
    font: str,
) -> Path:
    width, height = size
    segment_paths: list[Path] = []
    subtitle_width = max(720, int(width * 0.78))
    for index, card in enumerate(cards):
        subtitle = workdir / f"subtitle_{index:04d}.png"
        segment = workdir / f"video_{index:04d}.mp4"
        write_subtitle_png(card, subtitle, subtitle_width, font)
        filter_complex = (
            f"[0:v]scale={width}:{height}:force_original_aspect_ratio=increase,"
            f"crop={width}:{height},format=yuv420p[bg];"
            f"[1:v]format=rgba[txt];"
            f"[bg][txt]overlay=(W-w)/2:H-h-{max(58, int(height * 0.065))}:format=auto,"
            "format=yuv420p[v]"
        )
        subprocess.run(
            [
                ffmpeg(),
                "-y",
                "-loop",
                "1",
                "-t",
                f"{card.duration:.3f}",
                "-i",
                str(card.image),
                "-i",
                str(subtitle),
                "-filter_complex",
                filter_complex,
                "-map",
                "[v]",
                "-r",
                str(fps),
                "-c:v",
                "libx264",
                "-preset",
                "ultrafast",
                "-crf",
                "21",
                "-pix_fmt",
                "yuv420p",
                str(segment),
            ],
            cwd=ROOT,
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        segment_paths.append(segment)

    concat = workdir / "video_segments.txt"
    concat.write_text(
        "".join(f"file '{path.resolve().as_posix()}'\n" for path in segment_paths),
        encoding="utf-8",
    )
    output = workdir / "video_no_audio.mp4"
    subprocess.run(
        [ffmpeg(), "-y", "-f", "concat", "-safe", "0", "-i", str(concat), "-c", "copy", str(output)],
        cwd=ROOT,
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return output


def write_audio_segments(cards: list[Card], workdir: Path, args: argparse.Namespace) -> Path | None:
    if not any(card.music or card.sfx or card.voices for card in cards):
        return None
    segment_paths: list[Path] = []
    for index, card in enumerate(cards):
        segment = workdir / f"audio_{index:04d}.wav"
        duration = f"{card.duration:.3f}"
        command = [ffmpeg(), "-y"]
        filters: list[str] = []
        mix_labels: list[str] = []
        input_index = 0
        if card.music is None:
            command.extend(["-f", "lavfi", "-i", "anullsrc=channel_layout=stereo:sample_rate=44100"])
            filters.append(f"[{input_index}:a]atrim=duration={duration},asetpts=N/SR/TB[base]")
        else:
            fade_start = max(0.0, card.duration - 0.45)
            command.extend(["-stream_loop", "-1", "-i", str(card.music)])
            filters.append(
                f"[{input_index}:a]atrim=duration={duration},asetpts=N/SR/TB,"
                f"volume={args.music_volume},afade=t=in:st=0:d=0.25,"
                f"afade=t=out:st={fade_start:.3f}:d=0.45[base]"
            )
        mix_labels.append("[base]")
        input_index += 1

        if card.sfx is not None:
            command.extend(["-i", str(card.sfx)])
            filters.append(
                f"[{input_index}:a]volume={args.sfx_volume},adelay=180|180,"
                f"apad,atrim=duration={duration},asetpts=N/SR/TB[sfx]"
            )
            mix_labels.append("[sfx]")
            input_index += 1

        for voice_index, voice in enumerate(card.voices):
            command.extend(["-i", str(voice)])
            label = f"voice{voice_index}"
            delay = 620 + voice_index * 900
            filters.append(
                f"[{input_index}:a]volume={args.voice_volume},adelay={delay}|{delay},"
                f"apad,atrim=duration={duration},asetpts=N/SR/TB[{label}]"
            )
            mix_labels.append(f"[{label}]")
            input_index += 1

        filters.append(
            "".join(mix_labels)
            + f"amix=inputs={len(mix_labels)}:duration=first:dropout_transition=0,"
            + "alimiter=limit=0.94,"
            + "aformat=sample_fmts=s16:channel_layouts=stereo[out]"
        )
        command.extend(
            [
                "-filter_complex",
                ";".join(filters),
                "-map",
                "[out]",
                "-ar",
                "44100",
                "-ac",
                "2",
                str(segment),
            ]
        )
        subprocess.run(command, cwd=ROOT, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        segment_paths.append(segment)
    concat = workdir / "audio_concat.txt"
    concat.write_text(
        "".join(f"file '{path.resolve().as_posix()}'\n" for path in segment_paths),
        encoding="utf-8",
    )
    output = workdir / "music_bed.wav"
    subprocess.run(
        [ffmpeg(), "-y", "-f", "concat", "-safe", "0", "-i", str(concat), "-c", "copy", str(output)],
        cwd=ROOT,
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return output


def write_manifest(cards: list[Card], path: Path, output: Path) -> None:
    payload = {
        "schema": "dream-coastline.story_movie.v1",
        "output": str(output.relative_to(ROOT) if output.is_relative_to(ROOT) else output),
        "duration_seconds": round(sum(card.duration for card in cards), 3),
        "card_count": len(cards),
        "scenes": sorted({card.scene_id for card in cards}),
        "cards": [
            {
                "scene_id": card.scene_id,
                "command": card.command,
                "title": card.title,
                "duration": round(card.duration, 3),
                "image": str(card.image.relative_to(ROOT) if card.image.is_relative_to(ROOT) else card.image),
                "music": str(card.music.relative_to(ROOT) if card.music and card.music.is_relative_to(ROOT) else card.music or ""),
                "sfx": str(card.sfx.relative_to(ROOT) if card.sfx and card.sfx.is_relative_to(ROOT) else card.sfx or ""),
                "voices": [
                    str(voice.relative_to(ROOT) if voice.is_relative_to(ROOT) else voice)
                    for voice in card.voices
                ],
            }
            for card in cards
        ],
    }
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def parse_size(value: str) -> tuple[int, int]:
    try:
        width, height = value.lower().split("x", 1)
        return int(width), int(height)
    except Exception as error:
        raise RuntimeError(f"Invalid --size value: {value}") from error


def filter_path(path: Path) -> str:
    return path.as_posix().replace("\\", "\\\\").replace(":", "\\:")


def main() -> int:
    args = parse_args()
    output = (ROOT / args.output).resolve() if not Path(args.output).is_absolute() else Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    workdir = output.parent / f".{output.stem}-work"
    if workdir.exists():
        shutil.rmtree(workdir)
    workdir.mkdir(parents=True)

    cards = build_cards(args)
    if not cards:
        print("story-movie status=FAIL reason=no-cards", file=sys.stderr)
        return 1
    align_card_durations(cards, args.fps)

    size = parse_size(args.size)
    concat_file = workdir / "images.txt"
    manifest = output.with_suffix(".json")
    write_concat_file(cards, concat_file)
    silent_video = write_video_segments(cards, workdir, size, args.fps, args.font)

    audio = write_audio_segments(cards, workdir, args)
    if audio is None:
        shutil.copyfile(silent_video, output)
    else:
        total_duration = f"{sum(card.duration for card in cards):.3f}"
        subprocess.run(
            [
                ffmpeg(),
                "-y",
                "-i",
                str(silent_video),
                "-i",
                str(audio),
                "-t",
                total_duration,
                "-map",
                "0:v:0",
                "-map",
                "1:a:0",
                "-c:v",
                "copy",
                "-c:a",
                "aac",
                "-b:a",
                "160k",
                "-shortest",
                "-movflags",
                "+faststart",
                str(output),
            ],
            cwd=ROOT,
            check=True,
        )

    write_manifest(cards, manifest, output)
    if not args.keep_workdir:
        shutil.rmtree(workdir)

    duration = sum(card.duration for card in cards)
    size_mb = output.stat().st_size / (1024 * 1024)
    print(
        "story-movie status=PASS "
        f"path={output.relative_to(ROOT)} manifest={manifest.relative_to(ROOT)} "
        f"cards={len(cards)} duration={duration:.1f}s size={size_mb:.1f}MB"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
