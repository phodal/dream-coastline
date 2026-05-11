#!/usr/bin/env python3
"""Terminal RPG prototype for the scenes under five/.

This is intentionally small and data-driven so each scene can be implemented,
verified, timed, and committed independently before it is promoted into Godot.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass, field
from pathlib import Path
import shlex
import sys
import textwrap
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = ROOT / "data" / "ascii_scenes"
VIEW_WIDTH = 72
MAX_UI_WIDTH = 96


@dataclass
class GameState:
    scene: dict
    location_id: str
    flags: set[str] = field(default_factory=set)
    elapsed_seconds: int = 0
    log: list[str] = field(default_factory=list)

    @property
    def location(self) -> dict:
        return self.scene["locations"][self.location_id]

    @property
    def ended(self) -> bool:
        return self.scene["ending_flag"] in self.flags


def scene_path(scene_id: str) -> Path:
    path = SCENE_DIR / f"{scene_id}.json"
    if not path.exists():
        available = ", ".join(list_scenes())
        raise SystemExit(f"Unknown scene '{scene_id}'. Available: {available}")
    return path


def list_scenes() -> list[str]:
    return sorted(path.stem for path in SCENE_DIR.glob("*.json"))


def load_scene(scene_id: str) -> dict:
    return json.loads(scene_path(scene_id).read_text(encoding="utf-8"))


def wrap(text: str, width: int = VIEW_WIDTH) -> list[str]:
    return textwrap.wrap(text, width=width, break_long_words=False, replace_whitespace=False) or [""]


def render(state: GameState, message: str = "") -> str:
    location = state.location
    lines = [
        f"== {state.scene['title']} ==",
        f"[{location['name']}]  time {format_time(state.elapsed_seconds)}",
    ]
    lines.extend(location["art"])
    lines.extend(wrap(location["description"]))
    if message:
        lines.append("")
        lines.extend(wrap(message))
    lines.append("")
    lines.append("Exits: " + ", ".join(f"{key}({label})" for key, label in location["exits"].items()))
    lines.append("Inspect: " + ", ".join(f"{key}({item['name']})" for key, item in location["items"].items()))
    lines.append("Commands: look | go <exit> | inspect <item> | status | help | quit")
    return "\n".join(lines)


def format_time(seconds: int) -> str:
    minutes, rest = divmod(seconds, 60)
    return f"{minutes:02d}:{rest:02d}"


def normalize(command: str) -> list[str]:
    command = command.strip()
    if command in {"看", "查看"}:
        return ["look"]
    if command.startswith("去 "):
        return ["go", command[2:].strip()]
    if command.startswith("检查 "):
        return ["inspect", command[3:].strip()]
    return shlex.split(command.lower()) if command else []


def apply_command(state: GameState, command: str) -> str:
    parts = normalize(command)
    if not parts:
        return "输入 help 查看可用命令。"

    verb = parts[0]
    if verb in {"help", "h"}:
        return "用 inspect 收集线索，用 go 移动。序幕目标是确认家中异常，再触碰黑色钢笔。"
    if verb in {"look", "l"}:
        return state.location["description"]
    if verb in {"status", "s"}:
        found = len(state.flags.intersection(state.scene["required_flags"]))
        total = len(state.scene["required_flags"])
        return f"已确认关键线索 {found}/{total}，当前游玩时长估算 {format_time(state.elapsed_seconds)}。"
    if verb in {"quit", "q"}:
        raise KeyboardInterrupt
    if verb in {"go", "move"}:
        return move(state, parts[1] if len(parts) > 1 else "")
    if verb in {"inspect", "check", "x"}:
        return inspect_item(state, parts[1] if len(parts) > 1 else "")
    return f"无法识别命令：{command}"


def move(state: GameState, exit_id: str) -> str:
    exits = state.location["exits"]
    if exit_id not in exits:
        return "这里不能去那里。"
    state.location_id = exit_id
    state.elapsed_seconds += 20
    state.log.append(f"go {exit_id}")
    return f"你前往：{state.location['name']}。"


def inspect_item(state: GameState, item_id: str) -> str:
    item = state.location["items"].get(item_id)
    if item is None:
        return "这里没有这个可调查对象。"

    missing = [flag for flag in item.get("requires", []) if flag not in state.flags]
    if missing:
        return "你还缺少前置信息。先调查信纸，再决定是否碰那支笔。"

    state.elapsed_seconds += int(item.get("time_seconds", 30))
    for flag in item.get("flags", []):
        state.flags.add(flag)
    state.log.append(f"inspect {item_id}")
    return str(item["text"])


def run_walkthrough(scene: dict, commands: Iterable[str] | None = None) -> tuple[GameState, list[str]]:
    state = GameState(scene=scene, location_id=scene["start"])
    transcript = [render(state)]
    for command in commands or scene["walkthrough"]:
        message = apply_command(state, command)
        transcript.append(f"> {command}")
        transcript.append(message)
        if state.ended:
            break
    return state, transcript


def report(scene: dict, state: GameState) -> str:
    required = set(scene["required_flags"])
    missing = sorted(required - state.flags)
    minutes = state.elapsed_seconds / 60
    duration_ok = minutes >= float(scene["min_minutes"])
    complete = state.ended and not missing
    lines = [
        f"Scene: {scene['id']} - {scene['title']}",
        f"Source: {scene['source']}",
        f"Estimated playtime: {minutes:.1f} min ({state.elapsed_seconds}s)",
        f"Minimum target: {scene['min_minutes']:.1f} min",
        f"Duration gate: {'PASS' if duration_ok else 'FAIL'}",
        f"Completion gate: {'PASS' if complete else 'FAIL'}",
        f"Required clue coverage: {len(required - set(missing))}/{len(required)}",
    ]
    if missing:
        lines.append("Missing flags: " + ", ".join(missing))
    lines.append("Walkthrough commands: " + str(len(state.log)))
    return "\n".join(lines)


def verify_ui(scene: dict) -> tuple[bool, list[str]]:
    state = GameState(scene=scene, location_id=scene["start"])
    rendered = render(state)
    too_wide = [(index + 1, len(line), line) for index, line in enumerate(rendered.splitlines()) if len(line) > MAX_UI_WIDTH]
    problems = [f"line {line_no} is {width} chars: {line}" for line_no, width, line in too_wide]
    return not problems, problems


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("scene", nargs="?", default="00-prologue-lights-out")
    parser.add_argument("--list", action="store_true", help="list implemented ASCII scenes")
    parser.add_argument("--auto", action="store_true", help="run the scene walkthrough")
    parser.add_argument("--report", action="store_true", help="print playtime and coverage report")
    parser.add_argument("--verify", action="store_true", help="fail if walkthrough, time, or UI checks fail")
    args = parser.parse_args()

    if args.list:
        print("\n".join(list_scenes()))
        return 0

    scene = load_scene(args.scene)
    if args.auto or args.report or args.verify:
        state, transcript = run_walkthrough(scene)
        if args.auto:
            print("\n".join(transcript))
        if args.report or args.verify:
            print(report(scene, state))
        ui_ok, problems = verify_ui(scene)
        duration_ok = state.elapsed_seconds / 60 >= float(scene["min_minutes"])
        complete = state.ended and set(scene["required_flags"]).issubset(state.flags)
        if args.verify:
            if not ui_ok:
                print("UI gate: FAIL", file=sys.stderr)
                print("\n".join(problems), file=sys.stderr)
            else:
                print("UI gate: PASS")
            return 0 if ui_ok and duration_ok and complete else 1
        return 0

    state = GameState(scene=scene, location_id=scene["start"])
    message = ""
    while not state.ended:
        print("\033[2J\033[H", end="")
        print(render(state, message))
        try:
            message = apply_command(state, input("> "))
        except KeyboardInterrupt:
            print("\n退出。")
            return 0

    print("\033[2J\033[H", end="")
    print(render(state, "灯灭了。陌生钟声和火焰声从黑暗中升起。"))
    print()
    print(report(scene, state))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
