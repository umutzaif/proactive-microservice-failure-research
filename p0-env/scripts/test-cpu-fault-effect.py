#!/usr/bin/env python3
"""Synthetic positive and negative tests for physical CPU-effect verification."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


def write(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value), encoding="utf-8")


def counter(start: int, end: int, cores: float, step: int = 5) -> list[list[object]]:
    value = 0.0
    result = []
    for timestamp in range(start, end + 1, step):
        result.append([timestamp, str(value)])
        value += cores * step
    return result


def main() -> int:
    repo = Path(__file__).resolve().parents[2]
    root = repo / "p0-env/state/tests/cpu-effect"
    telemetry = root / "telemetry/raw/metrics/prometheus-query-range.json"
    metadata = root / "metadata.json"
    execution = root / "execution.json"
    output = root / "result.json"
    profile = repo / "p0-env/config/faults/cpu-recommendation-low-v2.json"
    analyzer = repo / "p0-env/scripts/analyze-cpu-fault-effect.py"

    write(metadata, {
        "run_id": "ob-cpu-low-test-001",
        "fault_profile": "cpu-recommendation-low-v2",
        "phases": {
            "normal_baseline_start_utc": "1970-01-01T00:00:00Z",
            "normal_baseline_end_utc": "1970-01-01T00:05:00Z",
            "ramp_end_utc": "1970-01-01T00:07:00Z",
            "injection_end_utc": "1970-01-01T00:12:00Z",
        },
    })
    write(execution, {
        "run_id": "ob-cpu-low-test-001",
        "bounded_worker_verification": True,
        "pod_name": "recommendationservice-test",
        "container": "server",
    })

    baseline = counter(0, 300, 0.010)
    steady = counter(420, 720, 0.060)
    offset = float(baseline[-1][1]) + 1.2
    steady = [[t, str(float(v) + offset)] for t, v in steady]
    values = baseline + steady
    write(telemetry, {"data": {"result": [{
        "metric": {"__name__": "container_cpu_usage_seconds_total", "pod": "recommendationservice-test", "container": "server"},
        "values": values,
    }]}})
    command = [sys.executable, str(analyzer), "--telemetry-root", str(root / "telemetry"), "--draft-metadata", str(metadata), "--execution-evidence", str(execution), "--fault-profile", str(profile), "--output", str(output)]
    positive = subprocess.run(command, check=False, capture_output=True, text=True)
    if positive.returncode != 0 or not json.loads(output.read_text())["physical_effect_verified"]:
        raise AssertionError(f"positive fixture failed: {positive.stderr}")

    payload = json.loads(telemetry.read_text())
    active = payload["data"]["result"][0]
    active["metric"]["id"] = "active-cgroup"
    stale = {
        "metric": {**active["metric"], "id": "stale-cgroup"},
        "values": counter(-300, -5, 0.010),
    }
    payload["data"]["result"] = [active, stale]
    write(telemetry, payload)
    stale_positive = subprocess.run(command, check=False, capture_output=True, text=True)
    if stale_positive.returncode != 0 or not json.loads(output.read_text())["physical_effect_verified"]:
        raise AssertionError(f"stale series displaced lifecycle series: {stale_positive.stderr}")

    ambiguous = json.loads(telemetry.read_text())
    ambiguous["data"]["result"][1]["values"] = list(active["values"])
    write(telemetry, ambiguous)
    ambiguity_negative = subprocess.run(command, check=False, capture_output=True, text=True)
    if ambiguity_negative.returncode == 0 or "found 2" not in ambiguity_negative.stderr:
        raise AssertionError("ambiguous lifecycle-covering CPU series were accepted")

    write(telemetry, {"data": {"result": [active]}})

    insufficient_coverage = baseline[:48] + steady[:48]
    payload = json.loads(telemetry.read_text())
    payload["data"]["result"][0]["values"] = insufficient_coverage
    write(telemetry, payload)
    coverage_negative = subprocess.run(command, check=False, capture_output=True, text=True)
    if coverage_negative.returncode == 0 or json.loads(output.read_text())["physical_effect_verified"]:
        raise AssertionError("47 intervals per phase were accepted")

    low_steady = counter(420, 720, 0.020)
    low_steady = [[t, str(float(v) + offset)] for t, v in low_steady]
    payload = json.loads(telemetry.read_text())
    payload["data"]["result"][0]["values"] = baseline + low_steady
    write(telemetry, payload)
    negative = subprocess.run(command, check=False, capture_output=True, text=True)
    if negative.returncode == 0 or json.loads(output.read_text())["physical_effect_verified"]:
        raise AssertionError("insufficient CPU increase was accepted")

    print("cpu_fault_effect_positive_fixture=passed")
    print("cpu_fault_effect_stale_series_fixture=passed")
    print("cpu_fault_effect_ambiguous_series_negative_fixture=passed")
    print("cpu_fault_effect_insufficient_coverage_negative_fixture=passed")
    print("cpu_fault_effect_insufficient_increase_negative_fixture=passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
