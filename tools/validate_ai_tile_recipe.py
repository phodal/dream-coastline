#!/usr/bin/env python3
"""Validate Dream Coastline AI Tile Designer recipes."""

from __future__ import annotations

import argparse
import json
from json import JSONDecodeError
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SCHEMA = "dream-coastline.ai_tile_recipe.v1"
GRID_WIDTH = 15
GRID_HEIGHT = 9
LAYERS = {"ground", "walls", "decor", "props_shadow", "lighting"}
TOOLS = {"fill", "paint", "rect", "line", "scatter", "pattern", "erase"}


def load_json(path: Path) -> Any:
    try:
        with path.open(encoding="utf-8") as handle:
            return json.load(handle)
    except FileNotFoundError as exc:
        raise ValueError(f"missing JSON file: {path}") from exc
    except JSONDecodeError as exc:
        raise ValueError(f"invalid JSON in {path}: {exc}") from exc


def fail(message: str, failures: list[str]) -> None:
    failures.append(message)


def is_point(value: Any) -> bool:
    return (
        isinstance(value, list)
        and len(value) == 2
        and all(isinstance(item, int) for item in value)
        and 0 <= value[0] < GRID_WIDTH
        and 0 <= value[1] < GRID_HEIGHT
    )


def is_area(value: Any) -> bool:
    if not (
        isinstance(value, list)
        and len(value) == 4
        and all(isinstance(item, int) for item in value)
    ):
        return False
    x, y, width, height = value
    return (
        width > 0
        and height > 0
        and 0 <= x < GRID_WIDTH
        and 0 <= y < GRID_HEIGHT
        and x + width <= GRID_WIDTH
        and y + height <= GRID_HEIGHT
    )


def tile_ids() -> set[str]:
    registry = load_json(ROOT / "data/visual_assets/tilesets.json")
    ids: set[str] = set()
    for tileset in registry.get("tilesets", []):
        if tileset.get("id") != "dream_scene_tiles":
            continue
        for tile in tileset.get("tiles", []):
            tile_id = tile.get("id")
            if isinstance(tile_id, str):
                ids.add(tile_id)
    return ids


def visual_locations(scene_id: str) -> set[str]:
    path = ROOT / f"data/visual_scenes/{scene_id}.json"
    if not path.exists():
        return set()
    visual = load_json(path)
    locations = visual.get("locations", {})
    if not isinstance(locations, dict):
        return set()
    return set(locations)


def validate_contract(recipe: dict[str, Any], failures: list[str]) -> None:
    contract = recipe.get("source_contract")
    if not isinstance(contract, dict):
        fail("source_contract must be an object", failures)
        return
    for key in ["must_read_as", "must_not_read_as"]:
        values = contract.get(key)
        if not isinstance(values, list) or not values:
            fail(f"source_contract.{key} must be a non-empty list", failures)
        elif not all(isinstance(item, str) and item.strip() for item in values):
            fail(f"source_contract.{key} must contain non-empty strings", failures)


def validate_patterns(
    recipe: dict[str, Any],
    tiles: set[str],
    failures: list[str],
) -> None:
    patterns = recipe.get("patterns", {})
    if not isinstance(patterns, dict):
        fail("patterns must be an object when present", failures)
        return
    for pattern_id, pattern in patterns.items():
        if not isinstance(pattern_id, str) or not pattern_id.strip():
            fail("pattern id must be a non-empty string", failures)
        if not isinstance(pattern, dict):
            fail(f"patterns.{pattern_id} must be an object", failures)
            continue
        size = pattern.get("size")
        if not (
            isinstance(size, list)
            and len(size) == 2
            and all(isinstance(item, int) and item > 0 for item in size)
        ):
            fail(f"patterns.{pattern_id}.size must be [width, height]", failures)
            continue
        width, height = size
        layers = pattern.get("layers")
        if not isinstance(layers, dict) or not layers:
            fail(f"patterns.{pattern_id}.layers must be a non-empty object", failures)
            continue
        legend = pattern.get("legend")
        if not isinstance(legend, dict):
            fail(f"patterns.{pattern_id}.legend must be an object", failures)
            legend = {}
        for symbol, tile_id in legend.items():
            if not isinstance(symbol, str) or len(symbol) != 1:
                fail(f"patterns.{pattern_id}.legend keys must be one character", failures)
            if not isinstance(tile_id, str) or tile_id not in tiles:
                fail(f"patterns.{pattern_id}.legend.{symbol} unknown tile: {tile_id}", failures)
        for layer_name, rows in layers.items():
            if layer_name not in LAYERS:
                fail(f"patterns.{pattern_id}.layers has unknown layer: {layer_name}", failures)
            if not isinstance(rows, list) or len(rows) != height:
                fail(f"patterns.{pattern_id}.layers.{layer_name} height mismatch", failures)
                continue
            for row_index, row in enumerate(rows):
                if not isinstance(row, str) or len(row) != width:
                    fail(
                        f"patterns.{pattern_id}.layers.{layer_name}[{row_index}] width mismatch",
                        failures,
                    )
                    continue
                for char in row:
                    if char in {".", " "}:
                        continue
                    if char not in legend:
                        fail(
                            f"patterns.{pattern_id}.layers.{layer_name} uses unknown symbol {char!r}",
                            failures,
                        )


def validate_operations(
    recipe: dict[str, Any],
    tiles: set[str],
    failures: list[str],
) -> None:
    patterns = recipe.get("patterns", {})
    pattern_ids = set(patterns) if isinstance(patterns, dict) else set()
    operations = recipe.get("operations")
    if not isinstance(operations, list) or not operations:
        fail("operations must be a non-empty list", failures)
        return
    operation_ids: set[str] = set()
    for index, operation in enumerate(operations):
        if not isinstance(operation, dict):
            fail(f"operations[{index}] must be an object", failures)
            continue
        op_id = operation.get("id")
        if not isinstance(op_id, str) or not op_id.strip():
            fail(f"operations[{index}].id is missing", failures)
        elif op_id in operation_ids:
            fail(f"operations[{index}].id is duplicated: {op_id}", failures)
        else:
            operation_ids.add(op_id)
        tool = operation.get("tool")
        if tool not in TOOLS:
            fail(f"operations[{op_id or index}].tool is unsupported: {tool}", failures)
            continue
        if tool == "pattern":
            if operation.get("pattern") not in pattern_ids:
                fail(f"operations[{op_id}].pattern is unknown", failures)
            if not is_point(operation.get("at")):
                fail(f"operations[{op_id}].at must be an in-bounds point", failures)
            continue
        layer = operation.get("layer")
        if layer not in LAYERS:
            fail(f"operations[{op_id}].layer is unknown: {layer}", failures)
        if tool == "erase":
            if "area" in operation and not is_area(operation.get("area")):
                fail(f"operations[{op_id}].area must be in bounds", failures)
            if "at" in operation and not is_point(operation.get("at")):
                fail(f"operations[{op_id}].at must be an in-bounds point", failures)
            points = operation.get("points")
            if "points" in operation and not (
                isinstance(points, list) and points and all(is_point(point) for point in points)
            ):
                fail(f"operations[{op_id}].points must be in-bounds points", failures)
            if "area" not in operation and "at" not in operation and "points" not in operation:
                fail(f"operations[{op_id}] must include area, at, or points", failures)
        elif tool in {"fill", "rect"}:
            if operation.get("tile") not in tiles:
                fail(f"operations[{op_id}].tile is unknown", failures)
            if not is_area(operation.get("area")):
                fail(f"operations[{op_id}].area must be in bounds", failures)
        elif tool == "paint":
            if operation.get("tile") not in tiles:
                fail(f"operations[{op_id}].tile is unknown", failures)
            if "at" in operation and not is_point(operation.get("at")):
                fail(f"operations[{op_id}].at must be an in-bounds point", failures)
            points = operation.get("points")
            if "points" in operation and not (
                isinstance(points, list) and points and all(is_point(point) for point in points)
            ):
                fail(f"operations[{op_id}].points must be in-bounds points", failures)
            if "at" not in operation and "points" not in operation:
                fail(f"operations[{op_id}] must include at or points", failures)
        elif tool == "line":
            if operation.get("tile") not in tiles and not isinstance(operation.get("selection"), list):
                fail(f"operations[{op_id}] must include tile or selection", failures)
            if not is_point(operation.get("from")) or not is_point(operation.get("to")):
                fail(f"operations[{op_id}] must include in-bounds from and to", failures)
        elif tool == "scatter":
            selection = operation.get("selection")
            if not isinstance(selection, list) or not selection:
                fail(f"operations[{op_id}].selection must be a non-empty list", failures)
            elif not all(isinstance(tile_id, str) and tile_id in tiles for tile_id in selection):
                fail(f"operations[{op_id}].selection contains unknown tile IDs", failures)
            if not is_area(operation.get("area")):
                fail(f"operations[{op_id}].area must be in bounds", failures)
            density = operation.get("density")
            if not isinstance(density, (int, float)) or not 0 <= density <= 1:
                fail(f"operations[{op_id}].density must be between 0 and 1", failures)


def validate_screenshot_states(recipe: dict[str, Any], failures: list[str]) -> None:
    states = recipe.get("screenshot_states")
    if not isinstance(states, list) or not states:
        fail("screenshot_states must be a non-empty list", failures)
        return
    for index, state in enumerate(states):
        if not isinstance(state, dict):
            fail(f"screenshot_states[{index}] must be an object", failures)
            continue
        if not isinstance(state.get("id"), str) or not state["id"].startswith("SHOT-"):
            fail(f"screenshot_states[{index}].id must start with SHOT-", failures)
        if state.get("location") != recipe.get("location_id"):
            fail(f"screenshot_states[{index}].location must match location_id", failures)
        expect = state.get("expect")
        if not isinstance(expect, list) or not expect:
            fail(f"screenshot_states[{index}].expect must be a non-empty list", failures)


def validate_recipe(path: Path) -> list[str]:
    failures: list[str] = []
    recipe = load_json(path)
    if not isinstance(recipe, dict):
        return ["recipe root must be an object"]
    if recipe.get("schema") != SCHEMA:
        fail(f"schema must be {SCHEMA}", failures)
    scene_id = recipe.get("scene_id")
    location_id = recipe.get("location_id")
    if not isinstance(scene_id, str) or not scene_id:
        fail("scene_id must be a non-empty string", failures)
    if not isinstance(location_id, str) or not location_id:
        fail("location_id must be a non-empty string", failures)
    elif isinstance(scene_id, str) and location_id not in visual_locations(scene_id):
        fail(f"location_id does not exist in visual scene data: {location_id}", failures)
    tiles = tile_ids()
    validate_contract(recipe, failures)
    validate_patterns(recipe, tiles, failures)
    validate_operations(recipe, tiles, failures)
    validate_screenshot_states(recipe, failures)
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("recipes", nargs="+", type=Path)
    args = parser.parse_args()

    failed = False
    for recipe_path in args.recipes:
        path = recipe_path if recipe_path.is_absolute() else ROOT / recipe_path
        try:
            failures = validate_recipe(path)
        except ValueError as exc:
            failures = [str(exc)]
        if failures:
            failed = True
            print(f"ai-tile-recipe status=FAIL path={path}")
            for failure in failures:
                print(f"failure={failure}")
        else:
            print(f"ai-tile-recipe status=PASS path={path}")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
