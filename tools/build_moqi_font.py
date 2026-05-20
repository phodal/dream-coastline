#!/usr/bin/env python3
"""Build the first Dream Coastline Moqi symbol font.

The generator intentionally avoids external font tooling so the repository can
rebuild the prototype TTF on a clean machine. Glyph outlines are simple filled
TrueType contours generated from the script contract in data/moqi_script.json.
"""

from __future__ import annotations

import argparse
import json
import math
import struct
from pathlib import Path
from typing import Iterable

UNITS_PER_EM = 1000
ASCENDER = 880
DESCENDER = -180
FONT_REVISION = 0x00010000
MAC_EPOCH_ZERO = 0

Point = tuple[int, int]
Contour = list[Point]


def pack(fmt: str, *values: int | bytes) -> bytes:
    return struct.pack(">" + fmt, *values)


def pad4(data: bytes) -> bytes:
    return data + (b"\0" * ((4 - len(data) % 4) % 4))


def checksum(data: bytes) -> int:
    padded = pad4(data)
    total = 0
    for offset in range(0, len(padded), 4):
        total = (total + struct.unpack(">I", padded[offset : offset + 4])[0]) & 0xFFFFFFFF
    return total


def rect(x0: int, y0: int, x1: int, y1: int) -> Contour:
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


def poly(points: Iterable[Point]) -> Contour:
    return [(int(x), int(y)) for x, y in points]


def thick_line(x0: int, y0: int, x1: int, y1: int, width: int) -> Contour:
    dx = x1 - x0
    dy = y1 - y0
    length = math.hypot(dx, dy)
    if length == 0:
        half = width // 2
        return rect(x0 - half, y0 - half, x0 + half, y0 + half)
    nx = -dy / length * width / 2.0
    ny = dx / length * width / 2.0
    return poly(
        [
            (round(x0 + nx), round(y0 + ny)),
            (round(x1 + nx), round(y1 + ny)),
            (round(x1 - nx), round(y1 - ny)),
            (round(x0 - nx), round(y0 - ny)),
        ]
    )


def diamond(cx: int, cy: int, rx: int, ry: int) -> Contour:
    return poly([(cx, cy + ry), (cx + rx, cy), (cx, cy - ry), (cx - rx, cy)])


def glyph_contours(glyph_id: str) -> list[Contour]:
    shapes: dict[str, list[Contour]] = {
        "name": [
            rect(285, 230, 355, 570),
            rect(645, 230, 715, 570),
            rect(285, 230, 715, 300),
            rect(285, 500, 715, 570),
            diamond(500, 705, 92, 82),
            thick_line(395, 410, 605, 410, 42),
            thick_line(438, 360, 562, 465, 38),
        ],
        "door": [
            rect(235, 190, 315, 790),
            rect(685, 190, 765, 790),
            rect(235, 710, 765, 790),
            rect(438, 190, 510, 640),
            thick_line(510, 410, 675, 520, 52),
            rect(332, 170, 668, 230),
        ],
        "fire": [
            diamond(500, 520, 120, 245),
            thick_line(365, 260, 455, 455, 72),
            thick_line(635, 260, 545, 455, 72),
            diamond(500, 770, 54, 88),
            thick_line(420, 185, 580, 185, 48),
        ],
        "stop": [
            rect(250, 205, 750, 275),
            rect(472, 275, 548, 780),
            thick_line(310, 520, 685, 520, 58),
            thick_line(542, 352, 705, 440, 54),
            rect(315, 690, 545, 752),
        ],
        "contract": [
            rect(246, 210, 312, 790),
            thick_line(325, 670, 520, 520, 58),
            thick_line(325, 330, 520, 480, 58),
            diamond(560, 500, 92, 112),
            rect(670, 230, 746, 770),
            rect(610, 705, 746, 770),
            rect(610, 230, 746, 295),
        ],
        "history": [
            rect(260, 210, 340, 790),
            rect(660, 210, 740, 790),
            rect(300, 710, 700, 770),
            rect(300, 230, 700, 290),
            thick_line(385, 610, 615, 610, 46),
            thick_line(385, 500, 585, 500, 46),
            thick_line(385, 390, 635, 390, 46),
            diamond(500, 835, 55, 45),
        ],
        "star": [
            diamond(500, 690, 86, 118),
            thick_line(360, 548, 640, 548, 46),
            thick_line(420, 448, 580, 448, 42),
            rect(305, 278, 695, 340),
            rect(470, 340, 530, 448),
            diamond(675, 720, 38, 52),
            diamond(325, 720, 38, 52),
        ],
        "continue": [
            rect(270, 255, 340, 720),
            thick_line(350, 635, 500, 720, 52),
            thick_line(350, 340, 500, 255, 52),
            rect(500, 255, 570, 720),
            thick_line(570, 635, 730, 720, 52),
            thick_line(570, 340, 730, 255, 52),
            diamond(500, 500, 80, 78),
            thick_line(422, 500, 578, 500, 36),
        ],
        "truth": [
            rect(260, 210, 740, 285),
            rect(310, 365, 690, 435),
            rect(310, 555, 690, 625),
            rect(310, 365, 380, 625),
            rect(620, 365, 690, 625),
            diamond(500, 735, 92, 72),
            thick_line(405, 500, 595, 500, 44),
            diamond(500, 500, 42, 34),
        ],
        "return": [
            thick_line(250, 235, 745, 235, 62),
            thick_line(250, 235, 250, 665, 62),
            thick_line(250, 665, 660, 665, 62),
            thick_line(660, 665, 510, 785, 58),
            thick_line(660, 665, 510, 545, 58),
            thick_line(360, 360, 560, 520, 46),
            thick_line(560, 520, 690, 392, 46),
        ],
        "body": [
            rect(470, 190, 545, 790),
            thick_line(360, 680, 655, 680, 56),
            thick_line(380, 500, 635, 500, 52),
            thick_line(405, 320, 505, 190, 54),
            thick_line(535, 320, 675, 190, 54),
            diamond(508, 825, 58, 54),
        ],
        "move": [
            rect(470, 185, 535, 785),
            thick_line(245, 500, 755, 500, 58),
            thick_line(245, 500, 365, 630, 50),
            thick_line(245, 500, 365, 370, 50),
            thick_line(755, 500, 635, 630, 50),
            thick_line(755, 500, 635, 370, 50),
            diamond(502, 500, 45, 45),
        ],
        "fast": [
            thick_line(270, 500, 730, 500, 66),
            thick_line(730, 500, 585, 650, 58),
            thick_line(730, 500, 585, 350, 58),
            thick_line(300, 650, 475, 725, 42),
            thick_line(250, 500, 425, 575, 42),
            thick_line(300, 350, 475, 275, 42),
            rect(365, 270, 425, 730),
        ],
        "water": [
            thick_line(500, 190, 500, 780, 62),
            thick_line(500, 420, 330, 260, 56),
            thick_line(500, 420, 670, 260, 56),
            diamond(340, 650, 56, 82),
            diamond(660, 650, 56, 82),
            diamond(500, 810, 50, 62),
        ],
        "book": [
            rect(260, 230, 340, 760),
            rect(660, 230, 740, 760),
            rect(340, 230, 500, 300),
            rect(500, 230, 660, 300),
            rect(340, 690, 500, 760),
            rect(500, 690, 660, 760),
            thick_line(500, 260, 500, 730, 38),
            thick_line(385, 570, 470, 570, 34),
            thick_line(530, 470, 615, 470, 34),
        ],
        "light": [
            diamond(500, 510, 118, 118),
            thick_line(500, 700, 500, 820, 46),
            thick_line(500, 200, 500, 320, 46),
            thick_line(310, 510, 190, 510, 46),
            thick_line(690, 510, 810, 510, 46),
            thick_line(365, 645, 280, 730, 42),
            thick_line(635, 645, 720, 730, 42),
            thick_line(365, 375, 280, 290, 42),
            thick_line(635, 375, 720, 290, 42),
        ],
        "homecoming": [
            rect(245, 205, 315, 765),
            rect(685, 205, 755, 765),
            rect(245, 695, 755, 765),
            thick_line(665, 485, 395, 485, 64),
            thick_line(395, 485, 535, 620, 58),
            thick_line(395, 485, 535, 350, 58),
            rect(400, 205, 600, 270),
        ],
        "bridge": [
            rect(255, 205, 325, 470),
            rect(675, 205, 745, 470),
            thick_line(285, 470, 500, 690, 58),
            thick_line(500, 690, 715, 470, 58),
            rect(215, 205, 785, 270),
            thick_line(360, 380, 640, 380, 42),
            diamond(500, 760, 42, 42),
        ],
        "silence": [
            rect(270, 285, 730, 350),
            rect(270, 465, 640, 530),
            rect(270, 645, 730, 710),
            thick_line(690, 250, 360, 775, 62),
            diamond(710, 500, 46, 76),
            rect(225, 210, 285, 790),
        ],
        "erase": [
            rect(270, 250, 620, 320),
            rect(270, 455, 620, 525),
            rect(270, 660, 620, 730),
            rect(270, 250, 340, 730),
            thick_line(720, 210, 480, 790, 72),
            thick_line(600, 240, 780, 240, 42),
            thick_line(600, 760, 780, 760, 42),
        ],
        "boundary": [
            rect(240, 220, 760, 290),
            rect(240, 710, 760, 780),
            rect(240, 220, 310, 780),
            rect(690, 220, 760, 780),
            rect(465, 220, 535, 780),
            thick_line(310, 500, 690, 500, 54),
            diamond(500, 500, 46, 46),
        ],
        "repair": [
            rect(315, 300, 685, 670),
            rect(385, 370, 615, 600),
            thick_line(250, 735, 735, 250, 68),
            thick_line(640, 345, 760, 345, 52),
            thick_line(655, 240, 655, 450, 52),
            diamond(300, 710, 48, 48),
        ],
        "protect": [
            diamond(500, 505, 210, 300),
            rect(455, 350, 545, 670),
            rect(390, 590, 610, 665),
            thick_line(350, 450, 225, 560, 56),
            thick_line(650, 450, 775, 560, 56),
            rect(435, 215, 565, 285),
        ],
        "state": [
            rect(230, 215, 770, 285),
            rect(230, 715, 770, 785),
            rect(230, 215, 300, 785),
            rect(700, 215, 770, 785),
            diamond(500, 500, 95, 95),
            rect(470, 350, 530, 650),
            thick_line(375, 500, 625, 500, 44),
        ],
        "law": [
            rect(280, 220, 345, 780),
            thick_line(365, 660, 505, 660, 44),
            thick_line(365, 500, 575, 500, 44),
            thick_line(365, 340, 505, 340, 44),
            rect(635, 230, 705, 770),
            rect(565, 610, 775, 680),
            rect(565, 320, 775, 390),
        ],
        "ink": [
            diamond(500, 570, 145, 255),
            rect(340, 210, 660, 285),
            rect(390, 285, 610, 350),
            diamond(365, 710, 44, 62),
            diamond(635, 710, 44, 62),
            thick_line(420, 480, 580, 480, 42),
        ],
    }
    if glyph_id not in shapes:
        raise KeyError(f"No prototype outline for glyph id: {glyph_id}")
    return shapes[glyph_id]


def simple_glyph(contours: list[Contour]) -> bytes:
    points = [point for contour in contours for point in contour]
    if not points:
        return b"\0\0\0\0\0\0\0\0\0\0"

    x_values = [x for x, _ in points]
    y_values = [y for _, y in points]
    data = pack(
        "hhhhh",
        len(contours),
        min(x_values),
        min(y_values),
        max(x_values),
        max(y_values),
    )

    endpoint = -1
    for contour in contours:
        endpoint += len(contour)
        data += pack("H", endpoint)
    data += pack("H", 0)
    data += bytes([0x01] * len(points))

    last_x = 0
    for x, _ in points:
        data += pack("h", x - last_x)
        last_x = x

    last_y = 0
    for _, y in points:
        data += pack("h", y - last_y)
        last_y = y
    return data


def build_glyf_and_loca(glyph_ids: list[str]) -> tuple[bytes, bytes, dict[str, int]]:
    glyph_records = [simple_glyph([rect(190, 170, 810, 230), rect(190, 170, 250, 810), rect(750, 170, 810, 810), rect(190, 750, 810, 810)])]
    metrics = {".notdef": 16}
    for glyph_id in glyph_ids:
        contours = glyph_contours(glyph_id)
        glyph_records.append(simple_glyph(contours))
        metrics[glyph_id] = sum(len(contour) for contour in contours)

    offsets = []
    glyf = b""
    for record in glyph_records:
        offsets.append(len(glyf))
        glyf += pad4(record)
    offsets.append(len(glyf))

    loca = b"".join(pack("I", offset) for offset in offsets)
    return glyf, loca, metrics


def build_cmap(codepoints: list[int]) -> bytes:
    seg_count = len(codepoints) + 1
    seg_count_x2 = seg_count * 2
    max_power = 2 ** int(math.log2(seg_count))
    search_range = max_power * 2
    entry_selector = int(math.log2(max_power))
    range_shift = seg_count_x2 - search_range

    end_codes = codepoints + [0xFFFF]
    start_codes = codepoints + [0xFFFF]
    id_deltas = [((glyph_index + 1) - cp) & 0xFFFF for glyph_index, cp in enumerate(codepoints)] + [1]
    id_range_offsets = [0] * seg_count

    subtable = pack("HHHHHHH", 4, 16 + 8 * seg_count, 0, seg_count_x2, search_range, entry_selector, range_shift)
    subtable += b"".join(pack("H", value) for value in end_codes)
    subtable += pack("H", 0)
    subtable += b"".join(pack("H", value) for value in start_codes)
    subtable += b"".join(pack("H", value) for value in id_deltas)
    subtable += b"".join(pack("H", value) for value in id_range_offsets)
    return pack("HHHHI", 0, 1, 3, 1, 12) + subtable


def build_head() -> bytes:
    return pack(
        "IIIIHHqqhhhhHHhhh",
        0x00010000,
        FONT_REVISION,
        0,
        0x5F0F3CF5,
        0x000B,
        UNITS_PER_EM,
        MAC_EPOCH_ZERO,
        MAC_EPOCH_ZERO,
        0,
        DESCENDER,
        1000,
        ASCENDER,
        0,
        8,
        2,
        1,
        0,
    )


def build_hhea(num_glyphs: int) -> bytes:
    return pack(
        "IhhhH" + "h" * 11 + "H",
        0x00010000,
        ASCENDER,
        DESCENDER,
        80,
        1000,
        0,
        0,
        1000,
        1,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        num_glyphs,
    )


def build_maxp(num_glyphs: int, max_points: int, max_contours: int) -> bytes:
    return pack(
        "IH" + "H" * 13,
        0x00010000,
        num_glyphs,
        max_points,
        max_contours,
        0,
        0,
        2,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
    )


def build_hmtx(num_glyphs: int) -> bytes:
    return b"".join(pack("Hh", 1000, 0) for _ in range(num_glyphs))


def build_os2(first_cp: int, last_cp: int) -> bytes:
    return pack(
        "HhHHH" + "h" * 11 + "10sIIII4sHHHhhhHH",
        0,
        900,
        400,
        5,
        0,
        650,
        600,
        0,
        75,
        650,
        600,
        0,
        350,
        50,
        250,
        0,
        b"\0" * 10,
        0,
        0,
        0,
        0,
        b"MOQI",
        0x0040,
        first_cp,
        last_cp,
        ASCENDER,
        DESCENDER,
        80,
        ASCENDER,
        abs(DESCENDER),
    )


def build_name() -> bytes:
    values = {
        0: "Copyright 2026 Dream Coastline. Prototype Moqi symbol font.",
        1: "Moqi Symbols",
        2: "Regular",
        3: "Moqi Symbols Regular 1.0",
        4: "Moqi Symbols Regular",
        5: "Version 1.0",
        6: "MoqiSymbols-Regular",
    }
    records = []
    storage = b""
    for name_id, value in values.items():
        encoded = value.encode("utf-16-be")
        records.append((3, 1, 0x0409, name_id, len(encoded), len(storage)))
        storage += encoded
    header = pack("HHH", 0, len(records), 6 + 12 * len(records))
    body = b"".join(pack("HHHHHH", *record) for record in records)
    return header + body + storage


def build_post() -> bytes:
    return pack("IihhIIIII", 0x00030000, 0, -75, 50, 0, 0, 0, 0, 0)


def assemble_ttf(tables: dict[str, bytes]) -> bytes:
    sorted_tags = sorted(tables.keys())
    num_tables = len(sorted_tags)
    max_power = 2 ** int(math.log2(num_tables))
    search_range = max_power * 16
    entry_selector = int(math.log2(max_power))
    range_shift = num_tables * 16 - search_range

    offset = 12 + num_tables * 16
    records = []
    body = b""
    for tag in sorted_tags:
        data = tables[tag]
        records.append((tag, checksum(data), offset, len(data)))
        padded = pad4(data)
        body += padded
        offset += len(padded)

    header = pack("IHHHH", 0x00010000, num_tables, search_range, entry_selector, range_shift)
    directory = b"".join(tag.encode("ascii") + pack("III", check, table_offset, length) for tag, check, table_offset, length in records)
    font = bytearray(header + directory + body)

    adjustment = (0xB1B0AFBA - checksum(bytes(font))) & 0xFFFFFFFF
    head_record = next(record for record in records if record[0] == "head")
    struct.pack_into(">I", font, head_record[2] + 8, adjustment)
    return bytes(font)


def write_svg(glyph_id: str, contours: list[Contour], output_dir: Path) -> None:
    paths = []
    for contour in contours:
        points = " ".join(f"{x},{1000 - y}" for x, y in contour)
        paths.append(f'  <polygon points="{points}" />')
    svg = "\n".join(
        [
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">',
            '  <rect width="1000" height="1000" fill="none" />',
            '  <g fill="#111827">',
            *paths,
            "  </g>",
            "</svg>",
            "",
        ]
    )
    (output_dir / f"{glyph_id}.svg").write_text(svg, encoding="utf-8")


def load_contract(path: Path) -> tuple[list[str], list[int]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    glyph_ids = []
    codepoints = []
    for glyph in data["glyphs"]:
        glyph_ids.append(str(glyph["id"]))
        codepoints.append(int(str(glyph["codepoint"]).removeprefix("U+"), 16))
    if len(glyph_ids) != len(set(glyph_ids)):
        raise ValueError("Duplicate Moqi glyph ids in contract.")
    if len(codepoints) != len(set(codepoints)):
        raise ValueError("Duplicate Moqi codepoints in contract.")
    return glyph_ids, codepoints


def build(contract_path: Path, output_font: Path, svg_dir: Path) -> None:
    glyph_ids, codepoints = load_contract(contract_path)
    glyf, loca, point_counts = build_glyf_and_loca(glyph_ids)
    num_glyphs = len(glyph_ids) + 1
    max_points = max(point_counts.values())
    max_contours = max(len(glyph_contours(glyph_id)) for glyph_id in glyph_ids)

    tables = {
        "OS/2": build_os2(min(codepoints), max(codepoints)),
        "cmap": build_cmap(codepoints),
        "glyf": glyf,
        "head": build_head(),
        "hhea": build_hhea(num_glyphs),
        "hmtx": build_hmtx(num_glyphs),
        "loca": loca,
        "maxp": build_maxp(num_glyphs, max_points, max_contours),
        "name": build_name(),
        "post": build_post(),
    }
    output_font.parent.mkdir(parents=True, exist_ok=True)
    output_font.write_bytes(assemble_ttf(tables))

    svg_dir.mkdir(parents=True, exist_ok=True)
    for glyph_id in glyph_ids:
        write_svg(glyph_id, glyph_contours(glyph_id), svg_dir)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--contract", type=Path, default=Path("data/moqi_script.json"))
    parser.add_argument("--font", type=Path, default=Path("assets/fonts/moqi/MoqiSymbols.ttf"))
    parser.add_argument("--svg-dir", type=Path, default=Path("assets/fonts/moqi/svg"))
    args = parser.parse_args()
    build(args.contract, args.font, args.svg_dir)
    print(f"built {args.font}")
    print(f"wrote SVG sources to {args.svg_dir}")


if __name__ == "__main__":
    main()
