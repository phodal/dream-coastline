#!/usr/bin/env python3
"""Validate tracked final-art candidates without conflating them with human approval."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TASK_MANIFEST = ROOT / "data" / "playable_backdrop_imagen_manifest.json"
REVIEW_FILE = ROOT / "data" / "playable_backdrop_final_art_review.json"
VERIFIED_STATUS = "runtime_verified_pending_human_art_approval"


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def resolve_res_path(value: str) -> Path:
    return ROOT / value.removeprefix("res://") if value.startswith("res://") else ROOT / value


def main() -> int:
    tasks = {entry["id"]: entry for entry in load(TASK_MANIFEST).get("backdrops", [])}
    reviews = load(REVIEW_FILE).get("reviews", {})
    failures: list[str] = []
    verified = 0
    human_approved = 0
    for review_id, review in reviews.items():
        if review_id not in tasks:
            failures.append(f"unknown review id: {review_id}")
            continue
        task = tasks[review_id]
        if review.get("target_path") != task.get("target_path"):
            failures.append(f"target path drift: {review_id}")
        target = resolve_res_path(str(review.get("target_path", "")))
        if not target.is_file() or target.stat().st_size < 100_000:
            failures.append(f"candidate image missing or too small: {review_id} path={target.relative_to(ROOT)}")
        status = str(review.get("candidate_status", ""))
        approved = bool(review.get("human_approved", False))
        observations = review.get("acceptance_observations", [])
        if status == VERIFIED_STATUS:
            verified += 1
            if len(observations) < 3:
                failures.append(f"runtime-verified candidate lacks observations: {review_id}")
        if approved:
            human_approved += 1
            if status != "human_approved_final":
                failures.append(f"human approval/status mismatch: {review_id}")
        elif status == "human_approved_final":
            failures.append(f"final status lacks human approval: {review_id}")

    if failures:
        for failure in failures:
            print(f"playable-backdrop-final-art-review: {failure}")
        return 1
    print(
        "playable-backdrop-final-art-review status=PASS tracked=%d runtime_verified=%d "
        "human_approved=%d untracked=%d pending_human=%d"
        % (len(reviews), verified, human_approved, len(tasks) - len(reviews), verified - human_approved)
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
