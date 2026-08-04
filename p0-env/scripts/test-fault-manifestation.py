#!/usr/bin/env python3
"""Synthetic tests for fixed-grid manifestation and empty-window semantics."""

from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path


def write(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value), encoding="utf-8")


def main() -> int:
    repo = Path(__file__).resolve().parents[2]
    root = repo / "p0-env/state/tests/fault-manifestation"
    trace_path = root / "telemetry/selected/traces.ndjson"
    metadata_path = root / "metadata.json"
    output_path = root / "result.json"
    anchor_text = "2026-08-04T00:00:00Z"
    anchor_us = int(datetime.fromisoformat(anchor_text.replace("Z", "+00:00")).timestamp() * 1_000_000)
    write(metadata_path, {
        "run_id": "ob-cpu-low-test-001",
        "phases": {"normal_baseline_start_utc": anchor_text, "cooldown_end_utc": "2026-08-04T00:00:40Z"},
    })
    lines = []
    # Windows 1 and 2 violate, window 3 has no product request and resets the streak.
    # Windows 4, 5 and 6 then produce the first valid three-window manifestation.
    for index in (1, 2, 4, 5, 6):
        span = {
            "processID": "p1",
            "operationName": "GET",
            "startTime": anchor_us + (index * 5 + 1) * 1_000_000,
            "duration": 400_000,
            "tags": [
                {"key": "span.kind", "value": "server"},
                {"key": "http.route", "value": "/product/example"},
                {"key": "http.response.status_code", "value": 200},
            ],
        }
        lines.append(json.dumps({"traceID": f"t{index}", "processes": {"p1": {"serviceName": "frontend"}}, "spans": [span]}))
    trace_path.parent.mkdir(parents=True, exist_ok=True)
    trace_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    command = [
        sys.executable, str(repo / "p0-env/scripts/detect-fault-manifestation.py"),
        "--telemetry-root", str(root / "telemetry"),
        "--draft-metadata", str(metadata_path),
        "--slo-config", str(repo / "p0-env/config/slo/p1-cpu-001-slo-v1.json"),
        "--output", str(output_path),
    ]
    completed = subprocess.run(command, check=False, capture_output=True, text=True)
    if completed.returncode != 0:
        raise AssertionError(completed.stderr)
    result = json.loads(output_path.read_text(encoding="utf-8"))
    assert result["window_anchor_utc"] == anchor_text
    assert result["phase_boundary_realignment"] is False
    assert result["latency_manifestation_completion_window_index"] == 6
    assert result["failure_manifestation"] == "2026-08-04T00:00:35.000Z"
    assert result["windows"][3]["product_p95_latency_ms"] is None
    print("fixed_window_anchor=passed")
    print("empty_window_streak_reset=passed")
    print("third_violation_end_timestamp=passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
