#!/usr/bin/env python3
"""Explain slow frontend `/` traces in verified normal-baseline windows.

This is a diagnostic critical-path approximation. It never sums parallel span
durations; for each frontend `/` server span it reports the longest other span
in the same trace and aggregates which service/operation most often dominates.
"""

from __future__ import annotations

import argparse
import json
import math
import statistics
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path
from typing import Any


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def parse_utc(value: str) -> float:
    return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()


def percentile(values: list[float], fraction: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    return ordered[min(len(ordered) - 1, math.ceil(fraction * len(ordered)) - 1)]


def tags_of(span: dict[str, Any]) -> dict[str, Any]:
    return {item.get("key"): item.get("value") for item in span.get("tags", [])}


def route_of(span: dict[str, Any]) -> str | None:
    tags = tags_of(span)
    for key in ("http.route", "url.path", "http.target"):
        if tags.get(key):
            return str(tags[key])
    return None


def service_of(span: dict[str, Any], processes: dict[str, Any]) -> str:
    return str(processes.get(span.get("processID"), {}).get("serviceName", "unknown"))


def span_is_error(span: dict[str, Any]) -> bool:
    tags = tags_of(span)
    http_status = tags.get("http.response.status_code", tags.get("http.status_code"))
    grpc_status = tags.get("rpc.grpc.status_code")
    return bool(
        tags.get("error") is True
        or str(tags.get("otel.status_code", "")).upper() == "ERROR"
        or (isinstance(http_status, (int, float)) and http_status >= 500)
        or (isinstance(grpc_status, (int, float)) and grpc_status != 0)
    )


def span_key(span: dict[str, Any], processes: dict[str, Any]) -> str:
    return f"{service_of(span, processes)}::{span.get('operationName', '')}"


def analyze_run(repo_root: Path, run_id: str) -> dict[str, Any]:
    metadata_path = (
        repo_root
        / "p0-env"
        / "artifacts"
        / "scientific-run-metadata"
        / run_id
        / "scientific-run-metadata.json"
    )
    metadata = load_json(metadata_path)
    if metadata.get("valid_run") is not True:
        raise ValueError(f"Run is not valid: {run_id}")
    if metadata.get("run_kind") != "normal_baseline":
        raise ValueError(f"Run is not a normal baseline: {run_id}")
    if metadata.get("run_id") != run_id:
        raise ValueError(f"Metadata/run ID mismatch: {run_id}")

    start = parse_utc(metadata["phases"]["normal_baseline_start_utc"])
    end = parse_utc(metadata["phases"]["normal_baseline_end_utc"])
    trace_path = (
        repo_root
        / "p0-env"
        / "artifacts"
        / "telemetry"
        / run_id
        / "selected"
        / "traces.ndjson"
    )

    root_durations: list[float] = []
    root_errors = 0
    root_http_statuses: Counter[str] = Counter()
    longest_counts: Counter[str] = Counter()
    longest_durations: dict[str, list[float]] = defaultdict(list)
    longest_ratios: dict[str, list[float]] = defaultdict(list)
    all_span_durations: dict[str, list[float]] = defaultdict(list)
    traces_without_other_spans = 0

    with trace_path.open("r", encoding="utf-8") as handle:
        for line in handle:
            trace = json.loads(line)
            processes = trace.get("processes", {})
            root_spans = []
            for span in trace.get("spans", []):
                tags = tags_of(span)
                timestamp = float(span.get("startTime", 0)) / 1_000_000
                if (
                    service_of(span, processes) == "frontend"
                    and str(tags.get("span.kind", "")).lower() == "server"
                    and route_of(span) == "/"
                    and start <= timestamp <= end
                ):
                    root_spans.append(span)

            for root in root_spans:
                root_duration = float(root.get("duration", 0)) / 1000
                root_durations.append(root_duration)
                root_errors += int(span_is_error(root))
                root_tags = tags_of(root)
                status = root_tags.get(
                    "http.response.status_code", root_tags.get("http.status_code", "missing")
                )
                root_http_statuses[str(status)] += 1

                other_spans = []
                for span in trace.get("spans", []):
                    if span.get("spanID") == root.get("spanID"):
                        continue
                    duration = float(span.get("duration", 0)) / 1000
                    key = span_key(span, processes)
                    all_span_durations[key].append(duration)
                    other_spans.append((duration, key, span))

                if not other_spans:
                    traces_without_other_spans += 1
                    continue
                duration, key, _ = max(other_spans, key=lambda item: item[0])
                longest_counts[key] += 1
                longest_durations[key].append(duration)
                if root_duration > 0:
                    longest_ratios[key].append(duration / root_duration)

    dominant = []
    for key, count in longest_counts.most_common():
        durations = longest_durations[key]
        ratios = longest_ratios[key]
        dominant.append(
            {
                "service_operation": key,
                "critical_trace_count": count,
                "critical_trace_fraction": count / len(root_durations),
                "duration_ms_p50": percentile(durations, 0.50),
                "duration_ms_p95": percentile(durations, 0.95),
                "duration_ms_max": max(durations),
                "root_duration_ratio_p50": percentile(ratios, 0.50),
                "root_duration_ratio_p95": percentile(ratios, 0.95),
            }
        )

    all_spans = []
    for key, durations in all_span_durations.items():
        all_spans.append(
            {
                "service_operation": key,
                "span_count": len(durations),
                "duration_ms_p50": percentile(durations, 0.50),
                "duration_ms_p95": percentile(durations, 0.95),
                "duration_ms_max": max(durations),
            }
        )
    all_spans.sort(key=lambda item: item["duration_ms_p95"], reverse=True)

    return {
        "run_id": run_id,
        "root_route": "/",
        "root_trace_count": len(root_durations),
        "root_over_3000ms_count": sum(1 for value in root_durations if value > 3000),
        "root_over_3000ms_fraction": (
            sum(1 for value in root_durations if value > 3000) / len(root_durations)
            if root_durations
            else None
        ),
        "root_error_count": root_errors,
        "root_http_statuses": dict(sorted(root_http_statuses.items())),
        "root_latency_ms": {
            "mean": statistics.mean(root_durations) if root_durations else None,
            "p50": percentile(root_durations, 0.50),
            "p95": percentile(root_durations, 0.95),
            "p99": percentile(root_durations, 0.99),
            "max": max(root_durations) if root_durations else None,
        },
        "traces_without_other_spans": traces_without_other_spans,
        "dominant_longest_spans": dominant,
        "all_child_span_summaries": all_spans,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--run-id", action="append", required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    output = {
        "schema_version": 1,
        "analysis_kind": "frontend-root-critical-path-diagnostic",
        "source_run_ids": args.run_id,
        "method": "longest non-root span per frontend / trace; no span summation",
        "runs": [analyze_run(args.repo_root, run_id) for run_id in args.run_id],
        "limitations": [
            "The longest span is a critical-path candidate, not causal proof.",
            "Parallel span durations are not additive.",
            "Missing instrumentation can hide waiting time.",
            "The analysis is restricted to verified normal-baseline intervals.",
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
