#!/usr/bin/env python3
"""Validate the supply and consumable carrier catalog."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CATALOG = ROOT / "data" / "supply_catalog.json"
STORY_DIR = ROOT / "data" / "story_scenes"
ALLOWED_STAT_KEYS = {"ink", "focus", "stability"}
ALLOWED_STATUSES = {"runtime_integrated"}
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


def story_flags() -> set[str]:
    flags: set[str] = set()
    for path in sorted(STORY_DIR.glob("*.json")):
        scene = load_json(path)
        for node in iter_dicts(scene):
            for key in FLAG_ARRAY_KEYS:
                for flag in node.get(key, []) or []:
                    if isinstance(flag, str) and flag:
                        flags.add(flag)
            for key in FLAG_SCALAR_KEYS:
                flag = node.get(key)
                if isinstance(flag, str) and flag:
                    flags.add(flag)
    return flags


def require_dict(value: Any, label: str, failures: list[str]) -> dict[str, Any]:
    if not isinstance(value, dict):
        failures.append(f"{label} must be an object")
        return {}
    return value


def validate_string_list(value: Any, label: str, failures: list[str]) -> list[str]:
    if not isinstance(value, list) or not value:
        failures.append(f"{label} must be a non-empty list")
        return []
    result: list[str] = []
    for index, item in enumerate(value):
        if not isinstance(item, str) or not item:
            failures.append(f"{label}[{index}] must be a non-empty string")
        else:
            result.append(item)
    return result


def validate_catalog(catalog_path: Path) -> list[str]:
    failures: list[str] = []
    catalog = require_dict(load_json(catalog_path), "catalog", failures)
    flags = story_flags()

    if catalog.get("schema_version") != 1:
        failures.append("schema_version must be 1")
    if catalog.get("integration_status") not in ALLOWED_STATUSES:
        failures.append("integration_status must be runtime_integrated")
    design_doc = catalog.get("design_doc")
    if not isinstance(design_doc, str) or not design_doc:
        failures.append("design_doc must be a repo-relative path")
    elif not (ROOT / design_doc).exists():
        failures.append(f"design_doc does not exist: {design_doc}")

    offers = require_dict(catalog.get("offers"), "offers", failures)
    if not offers:
        failures.append("offers must not be empty")
    for offer_id, offer in offers.items():
        validate_offer(str(offer_id), offer, flags, failures)
    return failures


def validate_offer(offer_id: str, offer: Any, flags: set[str], failures: list[str]) -> None:
    data = require_dict(offer, f"offers.{offer_id}", failures)
    for key in ["name", "kind", "channel", "use_text"]:
        if not isinstance(data.get(key), str) or not data.get(key):
            failures.append(f"offers.{offer_id}.{key} is required")
    if data.get("kind") != "consumable_carrier":
        failures.append(f"offers.{offer_id}.kind must be consumable_carrier")
    if not isinstance(data.get("quantity"), int) or not 1 <= data.get("quantity", 0) <= 2:
        failures.append(f"offers.{offer_id}.quantity must be 1-2")
    if not isinstance(data.get("use_seconds"), int) or not 0 <= data.get("use_seconds", -1) <= 30:
        failures.append(f"offers.{offer_id}.use_seconds must be 0-30")

    acquisition = require_dict(data.get("acquisition"), f"offers.{offer_id}.acquisition", failures)
    source_flags = validate_string_list(
        acquisition.get("source_flags"),
        f"offers.{offer_id}.acquisition.source_flags",
        failures,
    )
    for flag in source_flags:
        if flag not in flags:
            failures.append(f"offers.{offer_id} references unknown source flag {flag}")

    effects = require_dict(data.get("effects"), f"offers.{offer_id}.effects", failures)
    stats = require_dict(effects.get("stats"), f"offers.{offer_id}.effects.stats", failures)
    for stat_key, value in stats.items():
        if stat_key not in ALLOWED_STAT_KEYS:
            failures.append(f"offers.{offer_id}.effects.stats.{stat_key} is not allowed")
        if not isinstance(value, int) or not 1 <= value <= 2:
            failures.append(f"offers.{offer_id}.effects.stats.{stat_key} must be 1-2")

    balance = require_dict(data.get("balance"), f"offers.{offer_id}.balance", failures)
    if not isinstance(balance.get("tier"), int) or balance.get("tier", -1) < 0:
        failures.append(f"offers.{offer_id}.balance.tier must be a non-negative integer")
    if balance.get("repeatable") is not False:
        failures.append(f"offers.{offer_id}.balance.repeatable must be false")
    if not isinstance(balance.get("max_quantity"), int) or balance.get("max_quantity") < data.get("quantity", 0):
        failures.append(f"offers.{offer_id}.balance.max_quantity must cover quantity")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("catalog", nargs="?", type=Path, default=DEFAULT_CATALOG)
    args = parser.parse_args()

    failures = validate_catalog(args.catalog)
    if failures:
        for failure in failures:
            print(f"supply-catalog: {failure}")
        return 1
    print(f"supply-catalog: OK {args.catalog}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
