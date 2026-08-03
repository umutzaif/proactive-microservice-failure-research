#!/usr/bin/env python3
"""Falsify a frozen SLO against pre-fault normal-baseline window evidence."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def evaluate(windows: list[dict[str, Any]], field: str, threshold: float, required: int) -> dict[str, Any]:
    streak = 0
    maximum_streak = 0
    violating_indices: list[int] = []
    manifestation_indices: list[int] = []
    empty_indices: list[int] = []
    for window in windows:
        value = window.get(field)
        index = int(window["window_index"])
        if value is None:
            empty_indices.append(index)
            streak = 0
            continue
        if float(value) > threshold:
            violating_indices.append(index)
            streak += 1
            maximum_streak = max(maximum_streak, streak)
            if streak == required:
                manifestation_indices.append(index)
        else:
            streak = 0
    return {
        "violating_window_indices": violating_indices,
        "empty_window_indices": empty_indices,
        "maximum_consecutive_violations": maximum_streak,
        "manifestation_completion_window_indices": manifestation_indices,
        "manifestation_detected": bool(manifestation_indices),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate-evidence", type=Path, required=True)
    parser.add_argument("--slo-config", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    evidence = load_json(args.candidate_evidence)
    config = load_json(args.slo_config)
    if evidence.get("analysis_kind") != "route-specific-normal-sli-decision-support":
        raise ValueError("Unexpected candidate-evidence kind")
    if config.get("decision_status") != "frozen_before_fault_observation":
        raise ValueError("SLO is not frozen before fault observation")
    if config.get("fault_data_used") is not False:
        raise ValueError("Fault data must not be used to freeze the SLO")
    if evidence.get("source_run_ids") != config.get("source_normal_run_ids"):
        raise ValueError("SLO source run IDs do not match candidate evidence")
    if int(evidence["window_seconds"]) != int(config["window_seconds"]):
        raise ValueError("Window size mismatch")

    results = []
    for run in evidence["runs"]:
        latency_windows = run["populations"][config["latency"]["population"]]["windows"]
        error_windows = run["populations"][config["error"]["population"]]["windows"]
        latency = evaluate(
            latency_windows,
            "p95_latency_ms",
            float(config["latency"]["threshold_ms"]),
            int(config["latency"]["consecutive_violating_windows"]),
        )
        error = evaluate(
            error_windows,
            "error_rate",
            float(config["error"]["threshold"]),
            int(config["error"]["consecutive_violating_windows"]),
        )
        results.append(
            {
                "run_id": run["run_id"],
                "latency": latency,
                "error": error,
                "false_manifestation_detected": latency["manifestation_detected"] or error["manifestation_detected"],
            }
        )

    output = {
        "schema_version": 1,
        "verification_kind": "frozen-slo-normal-baseline-falsification",
        "slo_id": config["slo_id"],
        "source_run_ids": evidence["source_run_ids"],
        "runs": results,
        "false_manifestation_count": sum(item["false_manifestation_detected"] for item in results),
        "verification_passed": not any(item["false_manifestation_detected"] for item in results),
        "scope": "normal-baseline replay only; does not validate fault sensitivity",
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 0 if output["verification_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
