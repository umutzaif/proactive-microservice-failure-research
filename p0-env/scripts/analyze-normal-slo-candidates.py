#!/usr/bin/env python3
"""Derive user-visible latency/error SLI candidates from valid normal runs.

Inputs are immutable schema-v3 selected traces plus their scientific metadata.
The output is descriptive evidence, not an automatically accepted SLO decision.
Only frontend server spans inside the declared normal-baseline interval are used.
"""

from __future__ import annotations

import argparse
import json
import math
import statistics
from collections import Counter
from datetime import datetime
from pathlib import Path
from typing import Any


WINDOW_SECONDS = 5


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def parse_utc(value: str) -> float:
    return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()


def percentile(values: list[float], fraction: float) -> float | None:
    """Nearest-rank percentile; deterministic and dependency-free."""
    if not values:
        return None
    ordered = sorted(values)
    return ordered[min(len(ordered) - 1, math.ceil(fraction * len(ordered)) - 1)]


def tags_of(span: dict[str, Any]) -> dict[str, Any]:
    return {item.get("key"): item.get("value") for item in span.get("tags", [])}


def is_error(span: dict[str, Any]) -> bool:
    tags = tags_of(span)
    http_status = tags.get("http.response.status_code", tags.get("http.status_code"))
    grpc_status = tags.get("rpc.grpc.status_code")
    return bool(
        tags.get("error") is True
        or str(tags.get("otel.status_code", "")).upper() == "ERROR"
        or (isinstance(http_status, (int, float)) and http_status >= 500)
        or (isinstance(grpc_status, (int, float)) and grpc_status != 0)
    )


def is_frontend_user_server_span(
    span: dict[str, Any], processes: dict[str, Any]
) -> bool:
    process = processes.get(span.get("processID"), {})
    if process.get("serviceName") != "frontend":
        return False
    tags = tags_of(span)
    if str(tags.get("span.kind", "")).lower() != "server":
        return False
    operation = str(span.get("operationName", ""))
    lowered = operation.lower()
    route = route_of(span).lower()
    return (
        "health" not in lowered
        and "health" not in route
        and "traceservice/export" not in lowered
    )


def route_of(span: dict[str, Any]) -> str:
    tags = tags_of(span)
    for key in ("http.route", "url.path", "http.target"):
        if tags.get(key):
            return str(tags[key])
    return str(span.get("operationName", "unknown"))


def analyze_run(telemetry_root: Path, metadata_path: Path) -> dict[str, Any]:
    metadata = load_json(metadata_path)
    if metadata.get("valid_run") is not True:
        raise ValueError(f"Run is not valid: {metadata_path}")
    if metadata.get("run_kind") != "normal_baseline":
        raise ValueError(f"Run is not a normal baseline: {metadata_path}")

    run_id = metadata["run_id"]
    start_text = metadata["phases"]["normal_baseline_start_utc"]
    end_text = metadata["phases"]["normal_baseline_end_utc"]
    start = parse_utc(start_text)
    end = parse_utc(end_text)
    trace_path = telemetry_root / "selected" / "traces.ndjson"
    if telemetry_root.name != run_id:
        raise ValueError(f"Telemetry directory/run ID mismatch: {telemetry_root} vs {run_id}")

    # Only equal, complete windows may contribute to the normal distribution.
    # The lifecycle often contains a sub-second tail beyond the planned 300 s.
    window_count = math.floor((end - start) / WINDOW_SECONDS)
    analysis_end = start + window_count * WINDOW_SECONDS
    windows: list[list[tuple[float, bool]]] = [[] for _ in range(window_count)]
    operations: Counter[str] = Counter()
    routes: dict[str, dict[str, Any]] = {}
    observed_trace_ids: set[str] = set()
    partial_tail_excluded_span_count = 0

    with trace_path.open("r", encoding="utf-8") as handle:
        for line in handle:
            trace = json.loads(line)
            processes = trace.get("processes", {})
            for span in trace.get("spans", []):
                if not is_frontend_user_server_span(span, processes):
                    continue
                timestamp = float(span.get("startTime", 0)) / 1_000_000
                if not start <= timestamp <= end:
                    continue
                if timestamp >= analysis_end:
                    partial_tail_excluded_span_count += 1
                    continue
                index = int((timestamp - start) // WINDOW_SECONDS)
                duration_ms = float(span.get("duration", 0)) / 1000
                failed = is_error(span)
                windows[index].append((duration_ms, failed))
                operations[str(span.get("operationName", ""))] += 1
                route = route_of(span)
                route_state = routes.setdefault(route, {"durations": [], "errors": 0})
                route_state["durations"].append(duration_ms)
                route_state["errors"] += int(failed)
                observed_trace_ids.add(str(trace.get("traceID", "")))

    rendered_windows = []
    all_durations: list[float] = []
    total_errors = 0
    for index, items in enumerate(windows):
        durations = [duration for duration, _ in items]
        errors = sum(1 for _, failed in items if failed)
        all_durations.extend(durations)
        total_errors += errors
        rendered_windows.append(
            {
                "window_index": index,
                "offset_start_seconds": index * WINDOW_SECONDS,
                "request_count": len(items),
                "p95_latency_ms": percentile(durations, 0.95),
                "error_count": errors,
                "error_rate": errors / len(items) if items else None,
            }
        )

    nonempty = [window for window in rendered_windows if window["request_count"]]
    p95_windows = [window["p95_latency_ms"] for window in nonempty]
    error_windows = [window["error_rate"] for window in nonempty]
    return {
        "run_id": run_id,
        "normal_baseline_start_utc": start_text,
        "normal_baseline_end_utc": end_text,
        "window_seconds": WINDOW_SECONDS,
        "window_count": window_count,
        "nonempty_window_count": len(nonempty),
        "partial_tail_seconds": (end - start) - window_count * WINDOW_SECONDS,
        "partial_tail_excluded_span_count": partial_tail_excluded_span_count,
        "frontend_request_count": len(all_durations),
        "frontend_trace_count": len(observed_trace_ids),
        "error_count": total_errors,
        "overall_error_rate": total_errors / len(all_durations) if all_durations else None,
        "request_latency_ms": {
            "mean": statistics.mean(all_durations) if all_durations else None,
            "p50": percentile(all_durations, 0.50),
            "p95": percentile(all_durations, 0.95),
            "p99": percentile(all_durations, 0.99),
            "max": max(all_durations) if all_durations else None,
        },
        "window_p95_latency_ms": {
            "p50": percentile(p95_windows, 0.50),
            "p95": percentile(p95_windows, 0.95),
            "p99": percentile(p95_windows, 0.99),
            "max": max(p95_windows) if p95_windows else None,
        },
        "window_error_rate": {
            "p95": percentile(error_windows, 0.95),
            "p99": percentile(error_windows, 0.99),
            "max": max(error_windows) if error_windows else None,
        },
        "included_operations": dict(sorted(operations.items())),
        "included_routes": {
            route: {
                "request_count": len(state["durations"]),
                "error_count": state["errors"],
                "latency_p50_ms": percentile(state["durations"], 0.50),
                "latency_p95_ms": percentile(state["durations"], 0.95),
                "latency_p99_ms": percentile(state["durations"], 0.99),
                "latency_max_ms": max(state["durations"]),
            }
            for route, state in sorted(routes.items())
        },
        "windows": rendered_windows,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--run-id", action="append", required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    runs = []
    for run_id in args.run_id:
        runs.append(
            analyze_run(
                args.repo_root / "p0-env" / "artifacts" / "telemetry" / run_id,
                args.repo_root
                / "p0-env"
                / "artifacts"
                / "scientific-run-metadata"
                / run_id
                / "scientific-run-metadata.json",
            )
        )

    all_window_p95 = [
        window["p95_latency_ms"]
        for run in runs
        for window in run["windows"]
        if window["p95_latency_ms"] is not None
    ]
    all_error_rates = [
        window["error_rate"]
        for run in runs
        for window in run["windows"]
        if window["error_rate"] is not None
    ]
    output = {
        "schema_version": 1,
        "analysis_kind": "normal-slo-candidate-evidence",
        "source_run_ids": args.run_id,
        "frontend_server_spans_only": True,
        "health_and_telemetry_spans_excluded": True,
        "window_seconds": WINDOW_SECONDS,
        "combined_normal_window_count": len(all_window_p95),
        "combined_window_p95_latency_ms": {
            "p95": percentile(all_window_p95, 0.95),
            "p99": percentile(all_window_p95, 0.99),
            "max": max(all_window_p95) if all_window_p95 else None,
        },
        "combined_window_error_rate": {
            "p95": percentile(all_error_rates, 0.95),
            "p99": percentile(all_error_rates, 0.99),
            "max": max(all_error_rates) if all_error_rates else None,
        },
        "runs": runs,
        "limitations": [
            "Three same-host normal runs are descriptive pilot evidence, not population truth.",
            "Trace-derived latency covers observed frontend server spans, not client-side network latency.",
            "Nearest-rank percentiles are sensitive to low request counts in individual windows.",
            "This output does not freeze an SLO or authorize fault injection.",
        ],
    }
    rendered = json.dumps(output, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding="utf-8")
    else:
        print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
