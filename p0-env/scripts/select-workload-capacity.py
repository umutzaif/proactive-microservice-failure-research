#!/usr/bin/env python3
"""Apply the preregistered D-030 selection rule to three valid assessments."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def load(path: Path) -> Any:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--analysis", required=True, nargs=3, type=Path)
    parser.add_argument("--assessment", required=True, nargs=3, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    analyses = {int(item["users"]): item for item in map(load, args.analysis)}
    assessments = {int(item["users"]): item for item in map(load, args.assessment)}
    if set(analyses) != {10, 15, 20} or set(assessments) != {10, 15, 20}:
        raise ValueError("D-030 requires exactly 10, 15 and 20 user evidence.")
    if any(item.get("status") != "valid_capacity_evidence" for item in assessments.values()):
        raise ValueError("All capacity runs must pass their independent validity gates.")

    reference_rate = float(analyses[10]["frontend_user_server_span_rate_per_second"])
    evaluations: dict[str, Any] = {}
    selected = None
    for users in (20, 15):
        item = analyses[users]
        ratio = float(item["frontend_user_server_span_rate_per_second"]) / reference_rate
        gates = {
            "request_intensity_ratio_at_least_1_30": ratio >= 1.30,
            "recommendationservice_mean_cpu_at_most_25m": float(item["recommendationservice_cpu_mean_millicores"]) <= 25.0,
            "failure_manifestation_is_null": item.get("failure_manifestation") is None,
            "latency_streak_below_three": int(item["latency_violation_max_streak"]) < 3,
            "error_streak_below_three": int(item["error_violation_max_streak"]) < 3,
        }
        evaluations[str(users)] = {"request_intensity_ratio_vs_10u": ratio, "gates": gates, "passed": all(gates.values())}
        if selected is None and all(gates.values()):
            selected = users

    output = {
        "schema_version": 1,
        "decision_id": "D-030",
        "reference_users": 10,
        "selected_users": selected,
        "selected_workload_profile_id": analyses[selected]["workload_profile_id"] if selected else None,
        "evaluations": evaluations,
        "thresholds_changed_after_results": False,
        "dataset_inclusion": False,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"selected_users={selected}")
    return 0 if selected is not None else 2


if __name__ == "__main__":
    raise SystemExit(main())
