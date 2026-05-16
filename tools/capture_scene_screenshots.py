#!/usr/bin/env python3
"""Capture deterministic Godot viewport screenshots for scene review."""

from __future__ import annotations

import argparse
import html
import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_GODOT = Path("/Applications/Godot.app/Contents/MacOS/Godot")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Capture scene/location screenshots and build a local review sheet."
    )
    parser.add_argument(
        "--godot",
        type=Path,
        default=DEFAULT_GODOT,
        help="Path to the Godot executable.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=ROOT / "artifacts" / "scene-screenshots" / "latest",
        help="Directory for PNGs, manifest.json, and index.html.",
    )
    parser.add_argument(
        "--scene",
        default="all",
        help="Scene id to capture, or 'all'.",
    )
    parser.add_argument(
        "--scope",
        choices=["starts", "locations"],
        default="locations",
        help="Capture only each scene start or every authored location.",
    )
    parser.add_argument(
        "--warmup-frames",
        type=int,
        default=3,
        help="Frames to wait before each viewport capture.",
    )
    parser.add_argument(
        "--quit-after",
        type=int,
        default=240,
        help="Godot safety timeout in seconds.",
    )
    return parser.parse_args()


def run_capture(args: argparse.Namespace) -> int:
    output = args.output.expanduser()
    if not output.is_absolute():
        output = ROOT / output

    command = [
        str(args.godot.expanduser()),
        "--path",
        str(ROOT),
        "--quit-after",
        str(args.quit_after),
        "--",
        "--capture-scene-screenshots",
        "--capture-output",
        str(output),
        "--capture-scene",
        args.scene,
        "--capture-scope",
        args.scope,
        "--capture-warmup-frames",
        str(max(1, args.warmup_frames)),
    ]
    result = subprocess.run(command, cwd=ROOT, check=False)
    if result.returncode != 0:
        return result.returncode

    manifest_path = output / "manifest.json"
    if not manifest_path.exists():
        print(f"missing manifest: {manifest_path}", file=sys.stderr)
        return 1

    with manifest_path.open(encoding="utf-8") as file:
        manifest = json.load(file)
    write_contact_sheet(output, manifest)
    print(f"scene screenshot review: {output / 'index.html'}")
    return 0


def write_contact_sheet(output: Path, manifest: dict) -> None:
    screenshots = manifest.get("screenshots", [])
    scene_groups: dict[str, list[dict]] = {}
    for shot in screenshots:
        scene_groups.setdefault(str(shot.get("scene_id", "")), []).append(shot)

    sections: list[str] = []
    for scene_id, shots in scene_groups.items():
        title = shots[0].get("scene_title", "") if shots else ""
        cards = "\n".join(render_card(shot) for shot in shots)
        sections.append(
            f"""
            <section>
              <h2>{html.escape(scene_id)} <span>{html.escape(str(title))}</span></h2>
              <div class="grid">{cards}</div>
            </section>
            """
        )

    page = f"""<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <title>Dream Coastline Scene Screenshots</title>
  <style>
    :root {{
      color-scheme: dark;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #111;
      color: #eee;
    }}
    body {{
      margin: 0;
      padding: 24px;
    }}
    header {{
      margin-bottom: 24px;
    }}
    h1 {{
      font-size: 24px;
      margin: 0 0 8px;
    }}
    h2 {{
      font-size: 18px;
      margin: 28px 0 12px;
    }}
    h2 span {{
      color: #c9b47a;
      font-weight: 500;
      margin-left: 8px;
    }}
    .meta {{
      color: #aaa;
      font-size: 13px;
    }}
    .grid {{
      display: grid;
      gap: 16px;
      grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
    }}
    figure {{
      border: 1px solid #3c3325;
      background: #17130f;
      margin: 0;
      padding: 10px;
    }}
    img {{
      width: 100%;
      display: block;
      background: #050505;
    }}
    figcaption {{
      margin-top: 8px;
      font-size: 13px;
      line-height: 1.45;
    }}
    code {{
      color: #e8d18c;
    }}
  </style>
</head>
<body>
  <header>
    <h1>Dream Coastline Scene Screenshots</h1>
    <div class="meta">
      scope={html.escape(str(manifest.get("scope", "")))} ·
      screenshots={html.escape(str(manifest.get("screenshot_count", 0)))} ·
      asset_backed={html.escape(str(manifest.get("asset_backed_count", 0)))} ·
      placeholders={html.escape(str(manifest.get("framework_placeholder_count", 0)))} ·
      procedural_fallback={html.escape(str(manifest.get("procedural_fallback_count", 0)))} ·
      viewport={html.escape(str(manifest.get("viewport", {})))}
    </div>
  </header>
  {''.join(sections)}
</body>
</html>
"""
    (output / "index.html").write_text(page, encoding="utf-8")


def render_card(shot: dict) -> str:
    props = ", ".join(
        str(prop.get("kind", ""))
        for prop in shot.get("props", [])
        if prop.get("kind")
    )
    return f"""
    <figure>
      <img src="{html.escape(str(shot.get("file", "")))}" alt="{html.escape(str(shot.get("location_id", "")))}">
      <figcaption>
        <strong>{html.escape(str(shot.get("location_name", "")))}</strong>
        <code>{html.escape(str(shot.get("location_id", "")))}</code><br>
        terrain: <code>{html.escape(str(shot.get("terrain", "")))}</code><br>
        asset: <code>{html.escape(str(shot.get("asset_status", "")))}</code>
        <code>{html.escape(str(shot.get("visual_family", "")))}</code><br>
        scene: <code>{html.escape(str(shot.get("asset_scene", "")))}</code><br>
        props: {html.escape(props)}
      </figcaption>
    </figure>
    """


def main() -> int:
    return run_capture(parse_args())


if __name__ == "__main__":
    raise SystemExit(main())
