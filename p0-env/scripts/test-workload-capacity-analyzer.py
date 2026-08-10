#!/usr/bin/env python3
"""Verify fail-closed capacity CPU-series selection with synthetic archives."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ANALYZER = ROOT / "p0-env/scripts/analyze-workload-capacity.py"


def write(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value), encoding="utf-8")


def invoke(root: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run([
        sys.executable, str(ANALYZER), "--telemetry-root", str(root / "telemetry"),
        "--draft-metadata", str(root / "metadata.json"), "--workload-profile", str(root / "profile.json"),
        "--manifestation-evidence", str(root / "manifestation.json"), "--slo-config", str(root / "slo.json"),
        "--output", str(root / "output.json")], text=True, capture_output=True)


with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    write(root / "metadata.json", {"run_id": "test", "target_pod": "recommendationservice-test", "phases": {"normal_baseline_start_utc": "2026-01-01T00:00:00Z", "normal_baseline_end_utc": "2026-01-01T00:05:00Z"}})
    write(root / "profile.json", {"profile_id": "test-profile", "loadgenerator": {"users": 15}})
    write(root / "manifestation.json", {"failure_manifestation": None, "windows": [{"product_p95_latency_ms": 1, "global_error_rate": 0}]})
    write(root / "slo.json", {"latency": {"threshold_ms": 345.992}, "error": {"threshold": 0}})
    (root / "telemetry/selected").mkdir(parents=True)
    (root / "telemetry/selected/traces.ndjson").write_text("", encoding="utf-8")
    series = {"metric": {"__name__": "container_cpu_usage_seconds_total", "pod": "recommendationservice-test", "container": "server"}, "values": [[1767225600, "1"], [1767225610, "1.1"], [1767225890, "3.9"], [1767225900, "4.0"]]}
    payload = {"data": {"result": [series]}}
    write(root / "telemetry/raw/metrics/prometheus-query-range.json", payload)
    positive = invoke(root)
    assert positive.returncode == 0, positive.stderr
    print("workload_capacity_single_covering_series_fixture=passed")
    payload["data"]["result"].append(series)
    write(root / "telemetry/raw/metrics/prometheus-query-range.json", payload)
    negative = invoke(root)
    assert negative.returncode != 0
    assert "expected one measurement-covering" in negative.stderr
    print("workload_capacity_ambiguous_series_negative_fixture=passed")
