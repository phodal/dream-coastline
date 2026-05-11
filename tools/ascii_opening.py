#!/usr/bin/env python3
"""ASCII playable opening scene for fast checks.

The Godot scene and this terminal version read the same data/opening_beats.json
file. This keeps narrative progression testable without opening the engine UI.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import textwrap


ROOT = Path(__file__).resolve().parents[1]
BEATS_PATH = ROOT / "data" / "opening_beats.json"


def load_beats() -> list[dict]:
    return json.loads(BEATS_PATH.read_text(encoding="utf-8"))


def scene_art(beat_id: str) -> list[str]:
    if beat_id == "ancient":
        return [
            "+------------------------------------------------------------------------------+",
            "|                 ^      ^      ^        火 火 火                              |",
            "|                /#\\____/#\\____/#\\     #########                              |",
            "|               /###\\  /###\\  /###\\    # 王 城 #                              |",
            "|              |#####||#####||#####|   #########                              |",
            "|                                                                              |",
            "|                       @  纪子轩                 X  夏离                      |",
            "|                                                                              |",
            "|                ~ ~ ~ ~ ~ ~  墨颀历三百一十七年  ~ ~ ~ ~ ~ ~                 |",
            "+------------------------------------------------------------------------------+",
        ]

    if beat_id in {"void", "fade"}:
        return [
            "+------------------------------------------------------------------------------+",
            "|                                                                              |",
            "|                 . . . . .        现实正在剥落        . . . . .              |",
            "|                                                                              |",
            "|                              @                                               |",
            "|                                                                              |",
            "|                    \"你终于来了。\"                                             |",
            "|                    \"执笔者。\"                                                 |",
            "|                                                                              |",
            "+------------------------------------------------------------------------------+",
        ]

    ink = "~~~" if beat_id in {"ink", "flicker"} else "   "
    blood = "*" if beat_id in {"blood", "ink", "flicker"} else " "
    return [
        "+------------------------------------------------------------------------------+",
        "|  门                                                                          |",
        "|  []                              灯                                           |",
        "|  []                             ( )                       窗                  |",
        "|                                                                              |",
        "|                         +---------------------+                              |",
        f"|                         |  信纸 {ink:<3}   黑钢笔 === |                              |",
        f"|                         |       {blood}             |                              |",
        "|                         +---------------------+                              |",
        "|                         @ 纪子轩                                             |",
        "+------------------------------------------------------------------------------+",
    ]


def render(beat: dict) -> str:
    lines = [f"== {beat['title']} :: {beat['mode']} =="]
    lines.extend(scene_art(beat["id"]))
    lines.append(beat["ascii_hint"])
    if beat.get("letter"):
        lines.append("")
        lines.append("[信纸]")
        lines.extend(beat["letter"].splitlines())
    lines.append("")
    lines.extend(textwrap.wrap(beat["narration"], width=74))
    lines.append("")
    lines.append("Enter/n: 下一段  r: 重置  q: 退出")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--auto", action="store_true", help="print every beat and exit")
    parser.add_argument("--beat", help="render one beat id and exit")
    args = parser.parse_args()

    beats = load_beats()
    if args.beat:
        by_id = {beat["id"]: beat for beat in beats}
        print(render(by_id[args.beat]))
        return 0

    if args.auto:
        for beat in beats:
            print(render(beat))
            print("\n" + "=" * 80 + "\n")
        return 0

    index = 0
    while True:
        print("\033[2J\033[H", end="")
        print(render(beats[index]))
        command = input("> ").strip().lower()
        if command == "q":
            return 0
        if command == "r":
            index = 0
        elif index < len(beats) - 1:
            index += 1


if __name__ == "__main__":
    raise SystemExit(main())
