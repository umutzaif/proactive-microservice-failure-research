#!/usr/bin/env python3
"""Synthetic positive and fail-closed tests for network edge analysis."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ANALYZER = ROOT / "p0-env/scripts/analyze-network-delay-edge-candidates.py"


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value), encoding="utf-8")


def tag(key: str, value: object) -> dict[str, object]:
    return {"key": key, "type": "string", "value": value}


def trace(run_id: str, timestamp_us: int, operation: str = "/shop.Catalog/List") -> dict[str, object]:
    return {
        "traceID": "trace",
        "processes": {
            "caller": {"serviceName": "frontend", "tags": [tag("experiment.run_id", run_id)]},
            "callee": {"serviceName": "catalog", "tags": [tag("experiment.run_id", run_id)]},
        },
        "spans": [
            {
                "traceID": "trace", "spanID": "parent", "operationName": operation,
                "references": [], "startTime": timestamp_us, "duration": 1000,
                "processID": "caller", "tags": [tag("span.kind", "client")],
            },
            {
                "traceID": "trace", "spanID": "child", "operationName": operation,
                "references": [{"refType": "CHILD_OF", "traceID": "trace", "spanID": "parent"}],
                "startTime": timestamp_us + 100, "duration": 500, "processID": "callee",
                "tags": [tag("span.kind", "server")],
            },
        ],
    }


def prepare(root: Path, run_id: str, archive_run_id: str | None = None) -> None:
    write_json(
        root / "p0-env/artifacts/scientific-run-metadata" / run_id / "scientific-run-metadata.json",
        {
            "run_id": run_id, "valid_run": True, "run_kind": "normal_baseline",
            "workload_profile_id": "fixture-workload",
            "phases": {"normal_baseline_start_utc": "2026-01-01T00:00:00Z", "normal_baseline_end_utc": "2026-01-01T00:00:10Z"},
        },
    )
    trace_path = root / "p0-env/artifacts/telemetry" / run_id / "selected/traces.ndjson"
    trace_path.parent.mkdir(parents=True, exist_ok=True)
    payloads = [
        trace(archive_run_id or run_id, 1767225601000000),
        trace(archive_run_id or run_id, 1767225606000000),
        trace(archive_run_id or run_id, 1767225599000000),
        trace(archive_run_id or run_id, 1767225602000000, "/grpc.health.v1.Health/Check"),
    ]
    trace_path.write_text("\n".join(json.dumps(item) for item in payloads) + "\n", encoding="utf-8")


def invoke(root: Path, run_id: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(ANALYZER), "--repo-root", str(root), "--run-id", run_id, "--output", str(root / "out.json")],
        text=True, capture_output=True,
    )


with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    prepare(root, "fixture")
    positive = invoke(root, "fixture")
    assert positive.returncode == 0, positive.stderr
    result = json.loads((root / "out.json").read_text(encoding="utf-8"))
    edge = result["runs"][0]["edges"][0]
    assert edge["edge"] == "frontend->catalog"
    assert edge["client_span_count"] == 2, edge
    assert edge["window_coverage"] == 1.0, edge
    assert edge["nonempty_window_p95_latency_ms"]["p99"] == 1.0, edge
    assert result["aggregate"]["eligible_edges"] == ["frontend->catalog"]
    print("network_edge_parent_child_and_window_fixture=passed")
    print("network_edge_outside_window_and_health_exclusion=passed")

with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    prepare(root, "fixture", archive_run_id="wrong")
    negative = invoke(root, "fixture")
    assert negative.returncode != 0
    assert "trace_run_id_mismatch" in negative.stderr
    print("network_edge_wrong_run_id_negative_fixture=passed")
