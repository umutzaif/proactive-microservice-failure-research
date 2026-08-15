#!/usr/bin/env python3
"""Verify target-edge physical effect and first symptom for a network-delay run."""

from __future__ import annotations

import argparse
import json
import math
import statistics
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def load(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def epoch(value: str) -> float:
    return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()


def utc(value: float) -> str:
    return datetime.fromtimestamp(value, timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def percentile(values: list[float], fraction: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    return ordered[min(len(ordered) - 1, math.ceil(fraction * len(ordered)) - 1)]


def tags(item: dict[str, Any]) -> dict[str, Any]:
    return {tag.get("key"): tag.get("value") for tag in item.get("tags", [])}


def service(span: dict[str, Any], processes: dict[str, Any]) -> str:
    return str(processes.get(span.get("processID"), {}).get("serviceName", "unknown"))


def parent_id(span: dict[str, Any]) -> str | None:
    values = [str(ref["spanID"]) for ref in span.get("references", []) if ref.get("spanID") and str(ref.get("refType", "CHILD_OF")).upper() == "CHILD_OF"]
    if len(values) > 1:
        raise ValueError(f"ambiguous_parent:{span.get('spanID')}")
    return values[0] if values else None


def phase(values: list[tuple[float, float]], start: float, end: float, window_seconds: int) -> dict[str, Any]:
    expected = math.floor((end - start) / window_seconds)
    windows: list[list[float]] = [[] for _ in range(expected)]
    for timestamp, duration in values:
        if start <= timestamp < start + expected * window_seconds:
            windows[int((timestamp - start) // window_seconds)].append(duration)
    all_values = [value for window in windows for value in window]
    return {"duration_seconds": end - start, "expected_window_count": expected, "nonempty_window_count": sum(bool(window) for window in windows), "span_count": len(all_values), "median_latency_ms": statistics.median(all_values) if all_values else None, "p95_latency_ms": percentile(all_values, 0.95), "windows": [{"window_index": index, "span_count": len(window), "p95_latency_ms": percentile(window, 0.95)} for index, window in enumerate(windows)]}


def analyze(telemetry: Path, draft: dict[str, Any], profile: dict[str, Any], ramp: dict[str, Any], cleanup: dict[str, Any]) -> dict[str, Any]:
    run_id = profile["scientific_run_id"]
    if draft["run_id"] != run_id or ramp["run_id"] != run_id or cleanup["run_id"] != run_id:
        raise ValueError("run_id_mismatch")
    observed_run_ids: set[str] = set()
    values: list[tuple[float, float]] = []
    with (telemetry / "selected/traces.ndjson").open("r", encoding="utf-8") as handle:
        for line in handle:
            if not line.strip():
                continue
            trace = json.loads(line)
            processes = trace.get("processes", {})
            for process in processes.values():
                value = tags(process).get("experiment.run_id")
                if value:
                    observed_run_ids.add(str(value))
            spans = {str(span.get("spanID")): span for span in trace.get("spans", []) if span.get("spanID")}
            for child in spans.values():
                pid = parent_id(child)
                if not pid or pid not in spans:
                    continue
                parent = spans[pid]
                if service(parent, processes) == "recommendationservice" and service(child, processes) == "productcatalogservice" and str(tags(parent).get("span.kind", "")).lower() == "client" and str(tags(child).get("span.kind", "")).lower() == "server":
                    values.append((float(parent.get("startTime", 0)) / 1_000_000, float(parent.get("duration", 0)) / 1000))
    if observed_run_ids and observed_run_ids != {run_id}:
        raise ValueError(f"trace_run_id_mismatch:{sorted(observed_run_ids)}")
    p, effect, symptom = draft["phases"], profile["physical_effect"], profile["first_symptom"]
    baseline = phase(values, epoch(p["normal_baseline_start_utc"]), epoch(p["normal_baseline_end_utc"]), 5)
    steady = phase(values, epoch(p["ramp_end_utc"]), epoch(p["injection_end_utc"]), 5)
    delta = steady["median_latency_ms"] - baseline["median_latency_ms"] if steady["median_latency_ms"] is not None and baseline["median_latency_ms"] is not None else None
    coverage = baseline["nonempty_window_count"] >= effect["minimum_baseline_and_steady_nonempty_windows"] and steady["nonempty_window_count"] >= effect["minimum_baseline_and_steady_nonempty_windows"]
    physical = coverage and delta is not None and delta >= effect["minimum_steady_minus_baseline_median_ms"]

    anchor, end = epoch(p["normal_baseline_start_utc"]), epoch(p["cooldown_end_utc"])
    full = phase(values, anchor, end, int(symptom["window_seconds"]))
    streak = 0
    first_index = None
    for window in full["windows"]:
        value = window["p95_latency_ms"]
        streak = streak + 1 if value is not None and value > symptom["threshold_ms"] else 0
        if streak == symptom["consecutive_violating_windows"]:
            first_index = window["window_index"]
            break
    first_utc = utc(anchor + (first_index + 1) * symptom["window_seconds"]) if first_index is not None else None
    ramp_final = ramp["events"][-1]
    ramp_contract = len(ramp["events"]) == 13 and ramp_final["target_latency_ms"] == 750 and ramp["ramp_elapsed_monotonic_seconds"] >= 120
    cleanup_contract = cleanup["cleanup_verified"] is True and cleanup["after"]["toxics"] == []
    return {"schema_version": 1, "analysis_kind": "network-delay-physical-effect", "run_id": run_id, "target_edge": "recommendationservice->productcatalogservice", "baseline": baseline, "steady": steady, "steady_minus_baseline_median_ms": delta, "coverage_verified": coverage, "physical_effect_verified": physical, "minimum_effect_ms": effect["minimum_steady_minus_baseline_median_ms"], "first_symptom_utc": first_utc, "first_symptom_completion_window_index": first_index, "ramp_contract_verified": ramp_contract, "cleanup_verified": cleanup_contract, "trace_run_ids": sorted(observed_run_ids)}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--telemetry-root", type=Path, required=True)
    parser.add_argument("--draft-metadata", type=Path, required=True)
    parser.add_argument("--fault-profile", type=Path, required=True)
    parser.add_argument("--ramp-evidence", type=Path, required=True)
    parser.add_argument("--cleanup-evidence", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    result = analyze(args.telemetry_root, load(args.draft_metadata), load(args.fault_profile), load(args.ramp_evidence), load(args.cleanup_evidence))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"physical_effect_verified": result["physical_effect_verified"], "delta_ms": result["steady_minus_baseline_median_ms"], "first_symptom_utc": result["first_symptom_utc"]}, sort_keys=True))
    return 0 if result["physical_effect_verified"] and result["ramp_contract_verified"] and result["cleanup_verified"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
