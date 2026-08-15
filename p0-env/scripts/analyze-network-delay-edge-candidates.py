#!/usr/bin/env python3
"""Rank cross-service RPC edges in sealed valid normal-baseline traces.

The caller-side client span is the latency observation because an injected network
delay can be absent from the callee's server processing duration. Parent/child
relationships, not matching operation names, establish the caller-to-callee edge.
"""

from __future__ import annotations

import argparse
import json
import math
import statistics
from collections import defaultdict
from datetime import datetime
from pathlib import Path
from typing import Any


WINDOW_SECONDS = 5
MIN_WINDOW_COVERAGE = 0.80


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


def tags_of(item: dict[str, Any]) -> dict[str, Any]:
    return {tag.get("key"): tag.get("value") for tag in item.get("tags", [])}


def service_of(span: dict[str, Any], processes: dict[str, Any]) -> str:
    return str(processes.get(span.get("processID"), {}).get("serviceName", "unknown"))


def process_run_ids(processes: dict[str, Any]) -> set[str]:
    values: set[str] = set()
    for process in processes.values():
        value = tags_of(process).get("experiment.run_id")
        if value:
            values.add(str(value))
    return values


def is_excluded_operation(operation: str) -> bool:
    lowered = operation.lower()
    return any(value in lowered for value in ("grpc.health", "opentelemetry", "otlp"))


def is_error(span: dict[str, Any]) -> bool:
    tags = tags_of(span)
    grpc_status = tags.get("rpc.grpc.status_code")
    return bool(
        tags.get("error") is True
        or str(tags.get("otel.status_code", "")).upper() == "ERROR"
        or (isinstance(grpc_status, (int, float)) and grpc_status != 0)
    )


def parent_id(span: dict[str, Any]) -> str | None:
    parents = [
        str(reference.get("spanID"))
        for reference in span.get("references", [])
        if str(reference.get("refType", "CHILD_OF")).upper() == "CHILD_OF"
        and reference.get("spanID")
    ]
    if len(parents) > 1:
        raise ValueError(f"ambiguous_parent:{span.get('spanID')}")
    return parents[0] if parents else None


def analyze_run(repo_root: Path, run_id: str) -> dict[str, Any]:
    metadata_path = repo_root / "p0-env/artifacts/scientific-run-metadata" / run_id / "scientific-run-metadata.json"
    metadata = load_json(metadata_path)
    if metadata.get("run_id") != run_id:
        raise ValueError(f"metadata_run_id_mismatch:{run_id}")
    if metadata.get("valid_run") is not True or metadata.get("run_kind") != "normal_baseline":
        raise ValueError(f"run_not_valid_normal:{run_id}")

    start = parse_utc(metadata["phases"]["normal_baseline_start_utc"])
    end = parse_utc(metadata["phases"]["normal_baseline_end_utc"])
    expected_windows = math.floor((end - start) / WINDOW_SECONDS)
    if expected_windows < 1:
        raise ValueError(f"invalid_baseline_window:{run_id}")

    trace_path = repo_root / "p0-env/artifacts/telemetry" / run_id / "selected/traces.ndjson"
    durations: dict[str, list[float]] = defaultdict(list)
    windows: dict[str, set[int]] = defaultdict(set)
    window_durations: dict[str, dict[int, list[float]]] = defaultdict(lambda: defaultdict(list))
    operations: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    errors: dict[str, int] = defaultdict(int)
    observed_run_ids: set[str] = set()
    trace_count = 0

    with trace_path.open("r", encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, 1):
            if not line.strip():
                continue
            trace = json.loads(line)
            processes = trace.get("processes", {})
            trace_run_ids = process_run_ids(processes)
            if trace_run_ids and trace_run_ids != {run_id}:
                raise ValueError(f"trace_run_id_mismatch:{run_id}:line={line_number}:{sorted(trace_run_ids)}")
            observed_run_ids.update(trace_run_ids)
            spans = {str(span.get("spanID")): span for span in trace.get("spans", []) if span.get("spanID")}
            trace_had_edge = False

            for child in spans.values():
                parent_span_id = parent_id(child)
                if not parent_span_id or parent_span_id not in spans:
                    continue
                parent = spans[parent_span_id]
                caller = service_of(parent, processes)
                callee = service_of(child, processes)
                if caller in ("", "unknown") or callee in ("", "unknown") or caller == callee:
                    continue
                parent_tags = tags_of(parent)
                child_tags = tags_of(child)
                if str(parent_tags.get("span.kind", "")).lower() != "client":
                    continue
                if str(child_tags.get("span.kind", "")).lower() != "server":
                    continue
                operation = str(parent.get("operationName", ""))
                if not operation or is_excluded_operation(operation):
                    continue
                timestamp = float(parent.get("startTime", 0)) / 1_000_000
                if not (start <= timestamp < end):
                    continue
                window = math.floor((timestamp - start) / WINDOW_SECONDS)
                if not (0 <= window < expected_windows):
                    continue

                edge = f"{caller}->{callee}"
                duration_ms = float(parent.get("duration", 0)) / 1000
                durations[edge].append(duration_ms)
                windows[edge].add(window)
                window_durations[edge][window].append(duration_ms)
                operations[edge][operation] += 1
                errors[edge] += int(is_error(parent) or is_error(child))
                trace_had_edge = True
            trace_count += int(trace_had_edge)

    if observed_run_ids and observed_run_ids != {run_id}:
        raise ValueError(f"archive_run_id_mismatch:{run_id}:{sorted(observed_run_ids)}")

    edge_rows = []
    for edge, values in durations.items():
        caller, callee = edge.split("->", 1)
        window_p95_values = [
            {"window_index": index, "p95_latency_ms": percentile(window_durations[edge][index], 0.95)}
            for index in sorted(window_durations[edge])
        ]
        observed_window_p95 = [item["p95_latency_ms"] for item in window_p95_values]
        edge_rows.append(
            {
                "edge": edge,
                "caller": caller,
                "callee": callee,
                "client_span_count": len(values),
                "nonempty_window_count": len(windows[edge]),
                "expected_window_count": expected_windows,
                "window_coverage": len(windows[edge]) / expected_windows,
                "client_latency_ms": {
                    "mean": statistics.mean(values),
                    "p50": percentile(values, 0.50),
                    "p95": percentile(values, 0.95),
                    "p99": percentile(values, 0.99),
                    "max": max(values),
                },
                "nonempty_window_p95_latency_ms": {
                    "p50": percentile(observed_window_p95, 0.50),
                    "p95": percentile(observed_window_p95, 0.95),
                    "p99": percentile(observed_window_p95, 0.99),
                    "max": max(observed_window_p95),
                },
                "windows": window_p95_values,
                "error_span_pair_count": errors[edge],
                "operations": dict(sorted(operations[edge].items(), key=lambda item: (-item[1], item[0]))),
            }
        )
    edge_rows.sort(key=lambda item: (-item["window_coverage"], -item["client_span_count"], item["edge"]))
    return {
        "run_id": run_id,
        "workload_profile_id": metadata["workload_profile_id"],
        "baseline_start_utc": metadata["phases"]["normal_baseline_start_utc"],
        "baseline_end_utc": metadata["phases"]["normal_baseline_end_utc"],
        "expected_window_count": expected_windows,
        "trace_count_with_cross_service_edge": trace_count,
        "edges": edge_rows,
    }


def aggregate(runs: list[dict[str, Any]]) -> dict[str, Any]:
    by_edge: dict[str, dict[str, dict[str, Any]]] = defaultdict(dict)
    workload_runs: dict[str, set[str]] = defaultdict(set)
    for run in runs:
        workload = run["workload_profile_id"]
        workload_runs[workload].add(run["run_id"])
        for edge in run["edges"]:
            by_edge[edge["edge"]][run["run_id"]] = edge

    required_runs = {run["run_id"] for run in runs}
    summaries = []
    for edge, run_rows in by_edge.items():
        coverages = [run_rows[run_id]["window_coverage"] for run_id in sorted(run_rows)]
        present_runs = set(run_rows)
        present_workloads = {
            run["workload_profile_id"] for run in runs if run["run_id"] in present_runs
        }
        eligible = (
            present_runs == required_runs
            and present_workloads == set(workload_runs)
            and min(coverages, default=0) >= MIN_WINDOW_COVERAGE
        )
        summaries.append(
            {
                "edge": edge,
                "eligible": eligible,
                "run_coverage_count": len(present_runs),
                "required_run_count": len(required_runs),
                "workload_coverage_count": len(present_workloads),
                "required_workload_count": len(workload_runs),
                "minimum_window_coverage": min(coverages, default=0),
                "mean_window_coverage": statistics.mean(coverages) if coverages else 0,
                "total_client_span_count": sum(row["client_span_count"] for row in run_rows.values()),
                "per_run": {run_id: run_rows[run_id] for run_id in sorted(run_rows)},
            }
        )
    summaries.sort(
        key=lambda item: (
            not item["eligible"],
            -item["minimum_window_coverage"],
            -item["total_client_span_count"],
            item["edge"],
        )
    )
    return {
        "candidate_rule": {
            "required_in_every_run": True,
            "required_in_every_workload": True,
            "minimum_nonempty_five_second_window_fraction": MIN_WINDOW_COVERAGE,
        },
        "workload_run_ids": {key: sorted(value) for key, value in sorted(workload_runs.items())},
        "edge_summaries": summaries,
        "eligible_edges": [item["edge"] for item in summaries if item["eligible"]],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--run-id", action="append", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if len(set(args.run_id)) != len(args.run_id):
        raise ValueError("duplicate_run_id")
    runs = [analyze_run(args.repo_root, run_id) for run_id in args.run_id]
    result = {
        "schema_version": 1,
        "analysis_kind": "network-delay-edge-candidate-analysis",
        "method": "cross-service parent-child pair; caller client-span latency; five-second windows",
        "source_run_ids": args.run_id,
        "runs": runs,
        "aggregate": aggregate(runs),
        "limitations": [
            "Trace parentage establishes an observed RPC edge, not the effect of a future injector.",
            "Client span duration can include caller-side scheduling in addition to network time.",
            "A candidate edge still requires isolated tooling and cleanup validation.",
        ],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"output={args.output}")
    print(f"eligible_edges={len(result['aggregate']['eligible_edges'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
