#!/usr/bin/env python3
"""Recompute D-030 request intensity, SLO and CPU headroom evidence."""

from __future__ import annotations

import argparse
import json
import math
import statistics
from datetime import datetime
from pathlib import Path
from typing import Any


def load(path: Path) -> Any:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def epoch(value: str) -> float:
    return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()


def percentile(values: list[float], fraction: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    return ordered[min(len(ordered) - 1, math.ceil(len(ordered) * fraction) - 1)]


def tag_map(span: dict[str, Any]) -> dict[str, Any]:
    return {item.get("key"): item.get("value") for item in span.get("tags", [])}


def frontend_user_span(span: dict[str, Any], processes: dict[str, Any]) -> bool:
    tags = tag_map(span)
    operation = str(span.get("operationName", "")).lower()
    path = str(tags.get("http.route", tags.get("url.path", tags.get("http.target", "")))).lower()
    return bool(
        processes.get(span.get("processID"), {}).get("serviceName") == "frontend"
        and str(tags.get("span.kind", "")).lower() == "server"
        and "health" not in operation
        and "health" not in path
        and "traceservice/export" not in operation
    )


def max_streak(windows: list[dict[str, Any]], field: str, threshold: float) -> int:
    current = maximum = 0
    for window in windows:
        value = window.get(field)
        current = current + 1 if value is not None and float(value) > threshold else 0
        maximum = max(maximum, current)
    return maximum


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--telemetry-root", required=True, type=Path)
    parser.add_argument("--draft-metadata", required=True, type=Path)
    parser.add_argument("--workload-profile", required=True, type=Path)
    parser.add_argument("--manifestation-evidence", required=True, type=Path)
    parser.add_argument("--slo-config", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    metadata, profile = load(args.draft_metadata), load(args.workload_profile)
    manifestation, slo = load(args.manifestation_evidence), load(args.slo_config)
    start = epoch(metadata["phases"]["normal_baseline_start_utc"])
    end = epoch(metadata["phases"]["normal_baseline_end_utc"])
    duration = end - start

    payload = load(args.telemetry_root / "raw/metrics/prometheus-query-range.json")
    rates: list[float] = []
    for series in payload["data"]["result"]:
        labels = series.get("metric", {})
        if labels.get("__name__") != "container_cpu_usage_seconds_total":
            continue
        if not labels.get("pod", "").startswith("recommendationservice-") or labels.get("container") != "server":
            continue
        values = [(float(t), float(v)) for t, v in series.get("values", []) if start <= float(t) <= end]
        for (t0, v0), (t1, v1) in zip(values, values[1:]):
            if t1 > t0 and v1 >= v0:
                rates.append((v1 - v0) / (t1 - t0) * 1000)

    frontend_count = 0
    with (args.telemetry_root / "selected/traces.ndjson").open("r", encoding="utf-8") as handle:
        for line in handle:
            trace = json.loads(line)
            processes = trace.get("processes", {})
            for span in trace.get("spans", []):
                timestamp = float(span.get("startTime", 0)) / 1_000_000
                if start <= timestamp < end and frontend_user_span(span, processes):
                    frontend_count += 1

    output = {
        "schema_version": 1,
        "run_id": metadata["run_id"],
        "workload_profile_id": profile["profile_id"],
        "users": int(profile["loadgenerator"]["users"]),
        "measurement_seconds": duration,
        "frontend_user_server_span_count": frontend_count,
        "frontend_user_server_span_rate_per_second": frontend_count / duration,
        "recommendationservice_cpu_interval_count": len(rates),
        "recommendationservice_cpu_mean_millicores": statistics.mean(rates) if rates else None,
        "recommendationservice_cpu_p95_millicores": percentile(rates, 0.95),
        "recommendationservice_cpu_headroom_to_200m_mean": 200 - statistics.mean(rates) if rates else None,
        "failure_manifestation": manifestation.get("failure_manifestation"),
        "latency_violation_max_streak": max_streak(manifestation["windows"], "product_p95_latency_ms", float(slo["latency"]["threshold_ms"])),
        "error_violation_max_streak": max_streak(manifestation["windows"], "global_error_rate", float(slo["error"]["threshold"])),
        "dataset_inclusion": False,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
