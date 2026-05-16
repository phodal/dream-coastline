#!/usr/bin/env python3
"""Validate the contract-only equipment carrier catalog."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CATALOG = ROOT / "data" / "equipment_catalog.json"
STORY_DIR = ROOT / "data" / "story_scenes"

ALLOWED_EFFECT_KEYS = {
    "stat_modifiers",
    "glyph_mastery_modifiers",
    "metric_modifiers",
    "combat_modifiers",
    "resistances",
    "support_actions",
    "unlock_actions",
    "notes",
}

FLAG_ARRAY_KEYS = {
    "initial_flags",
    "required_flags",
    "flags",
    "requires",
    "failure_flags",
    "success_flags",
    "reward_flags",
    "required_attack_flags",
}

FLAG_SCALAR_KEYS = {
    "ending_flag",
    "win_flag",
    "lock_flag",
    "learn_flag",
    "clear_flag",
}


def load_json(path: Path) -> Any:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def iter_dicts(value: Any):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from iter_dicts(child)
    elif isinstance(value, list):
        for child in value:
            yield from iter_dicts(child)


def story_flags() -> tuple[set[str], set[str]]:
    scene_ids: set[str] = set()
    flags: set[str] = set()
    for path in sorted(STORY_DIR.glob("*.json")):
        scene = load_json(path)
        scene_id = str(scene.get("id", ""))
        if scene_id:
            scene_ids.add(scene_id)
        for node in iter_dicts(scene):
            for key in FLAG_ARRAY_KEYS:
                for flag in node.get(key, []) or []:
                    if isinstance(flag, str) and flag:
                        flags.add(flag)
            for key in FLAG_SCALAR_KEYS:
                flag = node.get(key)
                if isinstance(flag, str) and flag:
                    flags.add(flag)
    return scene_ids, flags


def require_dict(value: Any, label: str, failures: list[str]) -> dict[str, Any]:
    if not isinstance(value, dict):
        failures.append(f"{label} must be an object")
        return {}
    return value


def validate_number_map(
    value: Any,
    label: str,
    failures: list[str],
    *,
    max_abs: int | None = None,
    min_value: int | None = None,
    max_value: int | None = None,
) -> None:
    data = require_dict(value, label, failures)
    for key, raw_value in data.items():
        if not isinstance(key, str) or not key:
            failures.append(f"{label} contains an invalid key")
        if not isinstance(raw_value, int):
            failures.append(f"{label}.{key} must be an integer")
            continue
        if max_abs is not None and abs(raw_value) > max_abs:
            failures.append(f"{label}.{key}={raw_value} exceeds +/-{max_abs}")
        if min_value is not None and raw_value < min_value:
            failures.append(f"{label}.{key}={raw_value} is below {min_value}")
        if max_value is not None and raw_value > max_value:
            failures.append(f"{label}.{key}={raw_value} is above {max_value}")


def validate_string_list(value: Any, label: str, failures: list[str], *, allow_empty: bool = False) -> list[str]:
    if not isinstance(value, list):
        failures.append(f"{label} must be a list")
        return []
    result: list[str] = []
    for index, item in enumerate(value):
        if not isinstance(item, str) or not item:
            failures.append(f"{label}[{index}] must be a non-empty string")
        else:
            result.append(item)
    if not allow_empty and not result:
        failures.append(f"{label} must not be empty")
    return result


def validate_catalog(catalog_path: Path) -> list[str]:
    failures: list[str] = []
    catalog = require_dict(load_json(catalog_path), "catalog", failures)
    scene_ids, flags = story_flags()

    if catalog.get("schema_version") != 1:
        failures.append("schema_version must be 1")
    if catalog.get("integration_status") != "contract_only":
        failures.append("integration_status must remain contract_only")
    design_doc = catalog.get("design_doc")
    if not isinstance(design_doc, str) or not design_doc:
        failures.append("design_doc must be a repo-relative path")
    elif not (ROOT / design_doc).exists():
        failures.append(f"design_doc does not exist: {design_doc}")

    slots = require_dict(catalog.get("slots"), "slots", failures)
    items = require_dict(catalog.get("items"), "items", failures)
    if not slots:
        failures.append("slots must not be empty")
    if not items:
        failures.append("items must not be empty")

    for slot_id, slot in slots.items():
        slot_data = require_dict(slot, f"slots.{slot_id}", failures)
        if not slot_data.get("name"):
            failures.append(f"slots.{slot_id}.name is required")
        if not isinstance(slot_data.get("max_equipped"), int) or slot_data.get("max_equipped", 0) <= 0:
            failures.append(f"slots.{slot_id}.max_equipped must be a positive integer")
        if slot_data.get("equip_mode") not in {"fixed", "manual", "automatic"}:
            failures.append(f"slots.{slot_id}.equip_mode must be fixed, manual, or automatic")

    for item_id, item in items.items():
        validate_item(str(item_id), item, slots, scene_ids, flags, failures)

    return failures


def validate_item(
    item_id: str,
    item: Any,
    slots: dict[str, Any],
    scene_ids: set[str],
    flags: set[str],
    failures: list[str],
) -> None:
    item_data = require_dict(item, f"items.{item_id}", failures)
    for key in ["name", "scene_id", "slot", "kind"]:
        if not isinstance(item_data.get(key), str) or not item_data.get(key):
            failures.append(f"items.{item_id}.{key} is required")

    scene_id = item_data.get("scene_id")
    if isinstance(scene_id, str) and scene_id not in scene_ids:
        failures.append(f"items.{item_id}.scene_id references unknown scene {scene_id}")

    slot = item_data.get("slot")
    if isinstance(slot, str) and slot not in slots:
        failures.append(f"items.{item_id}.slot references unknown slot {slot}")

    acquisition = require_dict(item_data.get("acquisition"), f"items.{item_id}.acquisition", failures)
    source_flags = validate_string_list(
        acquisition.get("source_flags"),
        f"items.{item_id}.acquisition.source_flags",
        failures,
    )
    for flag in source_flags:
        if flag not in flags:
            failures.append(f"items.{item_id} references unknown source flag {flag}")

    effects = require_dict(item_data.get("effects"), f"items.{item_id}.effects", failures)
    unknown_effects = sorted(set(effects) - ALLOWED_EFFECT_KEYS)
    for key in unknown_effects:
        failures.append(f"items.{item_id}.effects.{key} is not an allowed effect bucket")

    if "stat_modifiers" in effects:
        validate_number_map(effects["stat_modifiers"], f"items.{item_id}.effects.stat_modifiers", failures, max_abs=2)
    if "glyph_mastery_modifiers" in effects:
        validate_number_map(
            effects["glyph_mastery_modifiers"],
            f"items.{item_id}.effects.glyph_mastery_modifiers",
            failures,
            max_abs=1,
        )
    if "metric_modifiers" in effects:
        validate_number_map(effects["metric_modifiers"], f"items.{item_id}.effects.metric_modifiers", failures, max_abs=30)
    if "combat_modifiers" in effects:
        validate_number_map(effects["combat_modifiers"], f"items.{item_id}.effects.combat_modifiers", failures, max_abs=2)
    if "resistances" in effects:
        validate_number_map(
            effects["resistances"],
            f"items.{item_id}.effects.resistances",
            failures,
            min_value=0,
            max_value=30,
        )
    for key in ["support_actions", "unlock_actions", "notes"]:
        if key in effects:
            validate_string_list(effects[key], f"items.{item_id}.effects.{key}", failures, allow_empty=True)

    balance = require_dict(item_data.get("balance"), f"items.{item_id}.balance", failures)
    if not isinstance(balance.get("tier"), int) or balance.get("tier", -1) < 0:
        failures.append(f"items.{item_id}.balance.tier must be a non-negative integer")
    if not isinstance(balance.get("combat_power"), int) or balance.get("combat_power", -1) < 0:
        failures.append(f"items.{item_id}.balance.combat_power must be a non-negative integer")
    elif balance["combat_power"] > 2:
        failures.append(f"items.{item_id}.balance.combat_power must not exceed 2 before integration")
    if not isinstance(balance.get("manual_equip"), bool):
        failures.append(f"items.{item_id}.balance.manual_equip must be boolean")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("catalog", nargs="?", type=Path, default=DEFAULT_CATALOG)
    args = parser.parse_args()

    failures = validate_catalog(args.catalog)
    if failures:
        for failure in failures:
            print(f"equipment-catalog: {failure}")
        return 1
    print(f"equipment-catalog: OK {args.catalog}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
