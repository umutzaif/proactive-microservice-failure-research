#!/usr/bin/env python3
"""Verify physical CPU fault effect from archived run-scoped Prometheus data."""

from __future__ import annotations

import argparse
import json
import statistics
from datetime import datetime
from pathlib import Path
from typing import Any


def load(path: Path) -> Any:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def utc(value: str) -> float:
    return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()


def rates(values: list[list[Any]], start: float, end: float) -> list[float]:
    selected = [(float(t), float(v)) for t, v in values if start <= float(t) <= end and v not in {"NaN", "Inf", "-Inf"}]
    return [
        (v1 - v0) / (t1 - t0)
        for (t0, v0), (t1, v1) in zip(selected, selected[1:])
        if t1 > t0 and v1 >= v0
    ]


def select_lifecycle_series(
    candidates: list[dict[str, Any]], baseline_start: float, baseline_end: float,
    steady_start: float, steady_end: float,
) -> dict[str, Any]:
    """Select the only counter series carrying samples in both measured phases."""
    covering = []
    for item in candidates:
        timestamps = [float(value[0]) for value in item.get("values", [])]
        has_baseline = any(baseline_start <= timestamp <= baseline_end for timestamp in timestamps)
        has_steady = any(steady_start <= timestamp <= steady_end for timestamp in timestamps)
        if has_baseline and has_steady:
            covering.append(item)
    if len(covering) != 1:
        raise ValueError(f"expected one lifecycle-covering target CPU series; found {len(covering)}")
    return covering[0]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--telemetry-root", type=Path, required=True)
    parser.add_argument("--draft-metadata", type=Path, required=True)
    parser.add_argument("--execution-evidence", type=Path, required=True)
    parser.add_argument("--fault-profile", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    metadata = load(args.draft_metadata)
    execution = load(args.execution_evidence)
    profile = load(args.fault_profile)
    if execution.get("bounded_worker_verification") is not True:
        raise ValueError("bounded worker execution did not pass")
    if metadata["run_id"] != execution["run_id"]:
        raise ValueError("run ID mismatch between metadata and execution evidence")
    if metadata["fault_profile"] != profile["profile_id"]:
        raise ValueError("fault profile mismatch")

    phases = metadata["phases"]
    baseline_start = utc(phases["normal_baseline_start_utc"])
    baseline_end = utc(phases["normal_baseline_end_utc"])
    steady_start = utc(phases["ramp_end_utc"])
    steady_end = utc(phases["injection_end_utc"])
    payload = load(args.telemetry_root / "raw/metrics/prometheus-query-range.json")
    series = payload["data"]["result"]
    pod = execution["pod_name"]
    container = execution["container"]
    cpu_candidates = []
    for item in series:
        labels = item.get("metric", {})
        if labels.get("pod") != pod or labels.get("container") != container:
            continue
        if labels.get("__name__") == "container_cpu_usage_seconds_total":
            cpu_candidates.append(item)
    if not cpu_candidates:
        raise ValueError("target CPU metric series is missing")
    cpu_series = select_lifecycle_series(
        cpu_candidates, baseline_start, baseline_end, steady_start, steady_end
    )
    cpu_values = cpu_series.get("values", [])
    cpu_id = cpu_series.get("metric", {}).get("id")
    throttle_candidates = [
        item for item in series
        if item.get("metric", {}).get("pod") == pod
        and item.get("metric", {}).get("container") == container
        and item.get("metric", {}).get("__name__") == "container_cpu_cfs_throttled_seconds_total"
        and item.get("metric", {}).get("id") == cpu_id
    ]
    if len(throttle_candidates) > 1:
        raise ValueError(f"expected at most one matching throttling series; found {len(throttle_candidates)}")
    throttle_values = throttle_candidates[0].get("values", []) if throttle_candidates else None

    baseline = rates(cpu_values, baseline_start, baseline_end)
    steady = rates(cpu_values, steady_start, steady_end)
    minimum_intervals = int(profile["physical_effect_verification"]["minimum_cpu_intervals_per_300_second_phase"])
    minimum_increase = float(profile["physical_effect_verification"]["minimum_steady_minus_baseline_mean_millicores"])
    baseline_mean = statistics.mean(baseline) * 1000 if baseline else None
    steady_mean = statistics.mean(steady) * 1000 if steady else None
    increase = steady_mean - baseline_mean if baseline_mean is not None and steady_mean is not None else None
    throttle = rates(
        throttle_values or [],
        utc(phases["normal_baseline_start_utc"]),
        utc(phases["injection_end_utc"]),
    )
    passed = bool(
        len(baseline) >= minimum_intervals
        and len(steady) >= minimum_intervals
        and increase is not None
        and increase >= minimum_increase
    )

    output = {
        **execution,
        "schema_version": 1,
        "physical_effect_verified": passed,
        "physical_effect_verification_status": "passed" if passed else "failed",
        "physical_effect": {
            "baseline_cpu_interval_count": len(baseline),
            "steady_cpu_interval_count": len(steady),
            "baseline_cpu_mean_millicores": baseline_mean,
            "steady_cpu_mean_millicores": steady_mean,
            "steady_minus_baseline_mean_millicores": increase,
            "required_minimum_increase_millicores": minimum_increase,
            "required_minimum_intervals_per_phase": minimum_intervals,
            "throttling_series_present": throttle_values is not None,
            "throttling_interval_count": len(throttle),
            "throttling_mean_millicores_equivalent": statistics.mean(throttle) * 1000 if throttle else None,
        },
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
