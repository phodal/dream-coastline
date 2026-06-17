#!/usr/bin/env python3
"""Generate deterministic playable-location backdrop PNGs from visual scene JSON."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import struct
import zlib
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
VISUAL_SCENE_DIR = ROOT / "data" / "visual_scenes"
PLAYABLE_DIR = ROOT / "assets" / "illustrations" / "playable"
WIDTH = 1672
HEIGHT = 941

PALETTES = {
    "modern_interior": ((25, 28, 34), (76, 84, 92), (224, 170, 82), (92, 190, 210)),
    "modern_exterior": ((20, 31, 42), (50, 82, 101), (238, 196, 92), (94, 167, 204)),
    "wilderness": ((34, 38, 35), (75, 92, 66), (218, 172, 91), (111, 148, 112)),
    "forest": ((25, 33, 30), (52, 86, 58), (200, 152, 80), (93, 134, 102)),
    "ruin": ((31, 31, 35), (75, 73, 78), (188, 142, 91), (105, 128, 148)),
    "academy": ((34, 29, 42), (77, 64, 92), (222, 181, 99), (121, 177, 178)),
    "archive": ((31, 28, 35), (85, 70, 55), (207, 158, 86), (117, 130, 144)),
    "node": ((23, 28, 42), (48, 73, 97), (105, 219, 225), (226, 174, 88)),
    "mine": ((30, 27, 24), (78, 63, 50), (226, 151, 75), (126, 111, 94)),
    "workshop": ((32, 30, 29), (88, 67, 52), (231, 156, 77), (99, 154, 168)),
    "industry": ((28, 32, 36), (80, 88, 90), (230, 174, 80), (118, 178, 186)),
}

PROP_COLORS = {
    "record": (229, 203, 151),
    "rune": (241, 189, 73),
    "node": (105, 219, 225),
    "bridge_static": (143, 222, 232),
    "exit": (210, 174, 100),
    "gate": (167, 126, 88),
    "student": (112, 156, 142),
    "officer": (132, 122, 156),
    "wensu": (149, 170, 126),
    "xiali": (154, 132, 102),
    "creature": (148, 95, 95),
    "phone": (80, 175, 210),
    "table": (122, 86, 60),
    "window_dark": (18, 23, 30),
    "construction_frame": (210, 159, 86),
}


class Canvas:
    def __init__(self, width: int, height: int, color: tuple[int, int, int]) -> None:
        self.width = width
        self.height = height
        self.pixels = bytearray(color * (width * height))

    def blend_pixel(self, x: int, y: int, color: tuple[int, int, int], alpha: float = 1.0) -> None:
        if x < 0 or x >= self.width or y < 0 or y >= self.height:
            return
        offset = (y * self.width + x) * 3
        inv = 1.0 - alpha
        self.pixels[offset] = int(self.pixels[offset] * inv + color[0] * alpha)
        self.pixels[offset + 1] = int(self.pixels[offset + 1] * inv + color[1] * alpha)
        self.pixels[offset + 2] = int(self.pixels[offset + 2] * inv + color[2] * alpha)

    def rect(self, x0: int, y0: int, x1: int, y1: int, color: tuple[int, int, int], alpha: float = 1.0) -> None:
        x0, x1 = max(0, min(x0, x1)), min(self.width, max(x0, x1))
        y0, y1 = max(0, min(y0, y1)), min(self.height, max(y0, y1))
        for y in range(y0, y1):
            for x in range(x0, x1):
                self.blend_pixel(x, y, color, alpha)

    def line(
        self,
        x0: int,
        y0: int,
        x1: int,
        y1: int,
        color: tuple[int, int, int],
        thickness: int = 2,
        alpha: float = 1.0,
    ) -> None:
        dx = x1 - x0
        dy = y1 - y0
        steps = max(abs(dx), abs(dy), 1)
        radius = max(1, thickness // 2)
        for i in range(steps + 1):
            x = int(x0 + dx * i / steps)
            y = int(y0 + dy * i / steps)
            self.rect(x - radius, y - radius, x + radius + 1, y + radius + 1, color, alpha)

    def ellipse(
        self,
        cx: int,
        cy: int,
        rx: int,
        ry: int,
        color: tuple[int, int, int],
        alpha: float = 1.0,
        hollow: bool = False,
    ) -> None:
        for y in range(cy - ry, cy + ry + 1):
            yy = ((y - cy) / max(ry, 1)) ** 2
            if yy > 1.0:
                continue
            span = int(rx * math.sqrt(1.0 - yy))
            for x in range(cx - span, cx + span + 1):
                if hollow:
                    edge = abs(((x - cx) / max(rx, 1)) ** 2 + yy - 1.0)
                    if edge > 0.08:
                        continue
                self.blend_pixel(x, y, color, alpha)


def lerp_color(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3))


def stable_int(*parts: str) -> int:
    digest = hashlib.sha256("|".join(parts).encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big")


def write_png(path: Path, canvas: Canvas) -> None:
    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    rows = bytearray()
    stride = canvas.width * 3
    for y in range(canvas.height):
        rows.append(0)
        start = y * stride
        rows.extend(canvas.pixels[start : start + stride])
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", canvas.width, canvas.height, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(rows), level=6))
    png += chunk(b"IEND", b"")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


def add_noise(canvas: Canvas, seed: int) -> None:
    state = seed & 0xFFFFFFFF
    for y in range(0, canvas.height, 3):
        for x in range(0, canvas.width, 3):
            state = (1664525 * state + 1013904223) & 0xFFFFFFFF
            delta = ((state >> 24) & 0xFF) - 128
            alpha = 0.025 + abs(delta) / 2550.0
            color = (255, 246, 220) if delta > 0 else (0, 0, 0)
            canvas.rect(x, y, x + 3, y + 3, color, alpha)


def draw_base(canvas: Canvas, family: str, terrain: str, accent: tuple[int, int, int]) -> None:
    base, mid, warm, cool = PALETTES.get(family, PALETTES["modern_interior"])
    for y in range(canvas.height):
        t = y / (canvas.height - 1)
        color = lerp_color(base, mid, t * 0.75)
        canvas.rect(0, y, canvas.width, y + 1, color)
    horizon = int(canvas.height * 0.58)
    canvas.rect(0, horizon, canvas.width, canvas.height, lerp_color(base, (20, 20, 22), 0.35), 0.55)
    canvas.line(0, horizon, canvas.width, horizon, warm, 4, 0.35)

    if terrain in {"room", "interior", "institute", "archive", "academy", "workshop"}:
        for i in range(5):
            x = int(canvas.width * (0.14 + i * 0.18))
            canvas.line(x, int(canvas.height * 0.16), x, int(canvas.height * 0.70), cool, 3, 0.24)
        for y in [0.25, 0.38, 0.51]:
            canvas.line(int(canvas.width * 0.08), int(canvas.height * y), int(canvas.width * 0.92), int(canvas.height * y), warm, 2, 0.20)
        canvas.rect(int(canvas.width * 0.08), int(canvas.height * 0.62), int(canvas.width * 0.92), int(canvas.height * 0.66), accent, 0.18)
    elif terrain in {"street", "dead_city", "village", "industry"}:
        for i in range(7):
            x = int(canvas.width * (0.04 + i * 0.15))
            height = int(canvas.height * (0.20 + (i % 3) * 0.08))
            canvas.rect(x, horizon - height, x + int(canvas.width * 0.10), horizon, mid, 0.45)
            for wy in range(horizon - height + 28, horizon - 12, 42):
                for wx in range(x + 16, x + int(canvas.width * 0.09), 38):
                    canvas.rect(wx, wy, wx + 16, wy + 18, warm, 0.35 if (wx + wy + i) % 3 else 0.08)
        canvas.line(int(canvas.width * 0.30), canvas.height, int(canvas.width * 0.46), horizon, cool, 6, 0.18)
        canvas.line(int(canvas.width * 0.70), canvas.height, int(canvas.width * 0.54), horizon, cool, 6, 0.18)
    elif terrain in {"mine", "ruin", "wilderness", "forest"}:
        for i in range(8):
            x0 = int(canvas.width * (i / 8.0))
            peak = horizon - int(canvas.height * (0.12 + (i % 3) * 0.04))
            canvas.line(x0, horizon, x0 + int(canvas.width * 0.08), peak, mid, 10, 0.35)
            canvas.line(x0 + int(canvas.width * 0.08), peak, x0 + int(canvas.width * 0.18), horizon, mid, 10, 0.35)
        for i in range(18):
            x = int(canvas.width * ((i * 37) % 100) / 100)
            canvas.line(x, horizon + 30, x - 40, canvas.height, warm, 2, 0.13)
    else:
        for i in range(9):
            cx = int(canvas.width * (0.1 + i * 0.1))
            cy = int(canvas.height * (0.28 + (i % 4) * 0.07))
            canvas.ellipse(cx, cy, 45 + i * 3, 18 + i, cool if i % 2 else warm, 0.18, hollow=True)


def grid_to_px(prop: dict[str, Any]) -> tuple[int, int]:
    x = float(prop.get("x", 7.0)) / 14.0
    y = float(prop.get("y", 5.0)) / 9.0
    return int(WIDTH * (0.08 + x * 0.84)), int(HEIGHT * (0.14 + y * 0.72))


def draw_prop(canvas: Canvas, prop: dict[str, Any], family: str) -> None:
    kind = str(prop.get("kind", "record"))
    x, y = grid_to_px(prop)
    color = PROP_COLORS.get(kind, (205, 184, 132))
    if kind in {"rune", "node", "bridge_static"}:
        canvas.ellipse(x, y, 48, 48, color, 0.14)
        canvas.ellipse(x, y, 25, 25, color, 0.58, hollow=True)
        canvas.line(x - 34, y, x + 34, y, color, 2, 0.55)
        canvas.line(x, y - 34, x, y + 34, color, 2, 0.55)
    elif kind == "exit":
        canvas.rect(x - 34, y - 58, x + 34, y + 42, color, 0.28)
        canvas.rect(x - 20, y - 42, x + 20, y + 42, (10, 12, 18), 0.38)
        canvas.line(x - 42, y + 44, x + 42, y + 44, color, 4, 0.55)
    elif kind in {"student", "officer", "wensu", "xiali", "creature"}:
        canvas.ellipse(x, y - 42, 22, 28, color, 0.50)
        canvas.rect(x - 28, y - 12, x + 28, y + 60, color, 0.35)
        canvas.line(x - 28, y + 20, x - 56, y + 52, color, 4, 0.35)
        canvas.line(x + 28, y + 20, x + 56, y + 52, color, 4, 0.35)
    elif kind in {"record", "phone"}:
        canvas.rect(x - 48, y - 35, x + 48, y + 35, color, 0.42)
        for i in range(4):
            canvas.line(x - 34, y - 18 + i * 12, x + 32, y - 18 + i * 12, (30, 35, 42), 2, 0.45)
    elif kind == "gate":
        canvas.rect(x - 72, y - 55, x + 72, y + 55, color, 0.26)
        for i in range(5):
            xx = x - 58 + i * 29
            canvas.line(xx, y - 55, xx, y + 55, color, 5, 0.48)
    elif kind == "construction_frame":
        canvas.rect(x - 84, y - 70, x + 84, y + 70, color, 0.08)
        canvas.line(x - 84, y + 70, x, y - 70, color, 5, 0.50)
        canvas.line(x + 84, y + 70, x, y - 70, color, 5, 0.50)
        canvas.line(x - 84, y, x + 84, y, color, 5, 0.40)
    elif kind == "window_dark":
        canvas.rect(x - 56, y - 50, x + 56, y + 50, (5, 8, 12), 0.62)
        canvas.line(x, y - 50, x, y + 50, color, 2, 0.20)
        canvas.line(x - 56, y, x + 56, y, color, 2, 0.20)
    else:
        canvas.rect(x - 58, y - 36, x + 58, y + 36, color, 0.30)
        canvas.ellipse(x, y, 24, 24, color, 0.35, hollow=True)

    if family == "node" or bool(prop.get("overlay", False)):
        canvas.ellipse(x, y, 72, 72, color, 0.08)


def generate_backdrop(scene_id: str, location_id: str, visual: dict[str, Any]) -> Canvas:
    family = str(visual.get("visual_family", "modern_interior"))
    terrain = str(visual.get("terrain", "room"))
    seed = stable_int(scene_id, location_id, family, terrain)
    palette = PALETTES.get(family, PALETTES["modern_interior"])
    accent = palette[2] if seed % 2 else palette[3]
    canvas = Canvas(WIDTH, HEIGHT, palette[0])
    draw_base(canvas, family, terrain, accent)

    props = [p for p in visual.get("props", []) if isinstance(p, dict)]
    for prop in sorted(props, key=lambda p: (float(p.get("y", 0)), float(p.get("x", 0)))):
        draw_prop(canvas, prop, family)

    vignette(canvas)
    add_noise(canvas, seed)
    return canvas


def vignette(canvas: Canvas) -> None:
    cx = canvas.width / 2
    cy = canvas.height / 2
    max_dist = math.sqrt(cx * cx + cy * cy)
    for y in range(0, canvas.height, 2):
        for x in range(0, canvas.width, 2):
            dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2) / max_dist
            alpha = max(0.0, (dist - 0.35) * 0.32)
            if alpha:
                canvas.rect(x, y, x + 2, y + 2, (0, 0, 0), min(alpha, 0.22))


def target_records(paths: list[Path] | None = None) -> list[tuple[Path, str, str, dict[str, Any], dict[str, Any]]]:
    records: list[tuple[Path, str, str, dict[str, Any], dict[str, Any]]] = []
    for path in sorted(paths or VISUAL_SCENE_DIR.glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        scene_id = str(data.get("id", path.stem))
        for location_id, visual in data.get("locations", {}).items():
            if not isinstance(visual, dict):
                continue
            backdrop = str(visual.get("illustrated_backdrop", ""))
            if backdrop and "/playable/" not in backdrop:
                records.append((path, scene_id, str(location_id), data, visual))
    return records


def update_visual_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="Write PNG files.")
    parser.add_argument("--update-json", action="store_true", help="Update data/visual_scenes references.")
    args = parser.parse_args()

    records = target_records()
    by_path: dict[Path, dict[str, Any]] = {}
    for path, scene_id, location_id, data, visual in records:
        target = PLAYABLE_DIR / scene_id / f"{location_id}.png"
        if args.write:
            canvas = generate_backdrop(scene_id, location_id, visual)
            write_png(target, canvas)
        if args.update_json:
            by_path[path] = data
            visual["illustrated_backdrop"] = f"res://assets/illustrations/playable/{scene_id}/{location_id}.png"
            visual.setdefault("asset_overlay_alpha", 0.20)

    if args.update_json:
        for path, data in by_path.items():
            update_visual_json(path, data)
    print(
        "playable-backdrops status=PASS targets=%d wrote=%s updated_json=%s"
        % (len(records), str(args.write).lower(), str(args.update_json).lower())
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
