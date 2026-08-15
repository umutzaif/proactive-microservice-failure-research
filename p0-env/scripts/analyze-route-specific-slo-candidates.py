#!/usr/bin/env python3
"""Compare global and route-scoped normal SLI populations.

Reads only verified normal-baseline metadata and immutable schema-v3 selected
traces. It produces descriptive decision support; it cannot freeze an SLO or
authorize fault injection.
"""

from __future__ import annotations

import argparse
import json
import math
from datetime import datetime
from pathlib import Path
from typing import Any, Callable


WINDOW_SECONDS = 5


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


def route_of(span: dict[str, Any]) -> str:
    tags = tags_of(span)
    for key in ("http.route", "url.path", "http.target"):
        if tags.get(key):
            return str(tags[key]).split("?", 1)[0]
    return str(span.get("operationName", "unknown"))


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


def is_frontend_user_server_span(span: dict[str, Any], processes: dict[str, Any]) -> bool:
    process = processes.get(span.get("processID"), {})
    tags = tags_of(span)
    operation = str(span.get("operationName", "")).lower()
    route = route_of(span).lower()
    return bool(
        process.get("serviceName") == "frontend"
        and str(tags.get("span.kind", "")).lower() == "server"
        and "health" not in operation
        and "health" not in route
        and "traceservice/export" not in operation
    )


POPULATIONS: dict[str, Callable[[str], bool]] = {
    "global_user_routes": lambda route: True,
    "root_excluded_user_routes": lambda route: route != "/",
    "product_detail_family": lambda route: route.startswith("/product/"),
}


def summarize_windows(windows: list[list[tuple[float, bool]]]) -> dict[str, Any]:
    rendered = []
    all_durations: list[float] = []
    for index, items in enumerate(windows):
        durations = [duration for duration, _ in items]
        errors = sum(1 for _, failed in items if failed)
        all_durations.extend(durations)
        rendered.append(
            {
                "window_index": index,
                "offset_start_seconds": index * WINDOW_SECONDS,
                "request_count": len(items),
                "p95_latency_ms": percentile(durations, 0.95),
                "error_count": errors,
                "error_rate": errors / len(items) if items else None,
            }
        )
    nonempty = [window for window in rendered if window["request_count"]]
    p95_values = [window["p95_latency_ms"] for window in nonempty]
    error_rates = [window["error_rate"] for window in nonempty]
    return {
        "request_count": len(all_durations),
        "error_count": sum(window["error_count"] for window in rendered),
        "window_count": len(rendered),
        "nonempty_window_count": len(nonempty),
        "empty_window_count": len(rendered) - len(nonempty),
        "window_coverage_fraction": len(nonempty) / len(rendered) if rendered else None,
        "request_latency_ms": {
            "p50": percentile(all_durations, 0.50),
            "p95": percentile(all_durations, 0.95),
            "p99": percentile(all_durations, 0.99),
            "max": max(all_durations) if all_durations else None,
        },
        "nonempty_window_p95_latency_ms": {
            "p50": percentile(p95_values, 0.50),
            "p95": percentile(p95_values, 0.95),
            "p99": percentile(p95_values, 0.99),
            "max": max(p95_values) if p95_values else None,
        },
        "nonempty_window_error_rate": {
            "p95": percentile(error_rates, 0.95),
            "p99": percentile(error_rates, 0.99),
            "max": max(error_rates) if error_rates else None,
        },
        "windows": rendered,
    }


def analyze_run(repo_root: Path, run_id: str) -> dict[str, Any]:
    metadata_path = repo_root / "p0-env/artifacts/scientific-run-metadata" / run_id / "scientific-run-metadata.json"
    telemetry_root = repo_root / "p0-env/artifacts/telemetry" / run_id
    metadata = load_json(metadata_path)
    if metadata.get("valid_run") is not True or metadata.get("run_kind") != "normal_baseline":
        raise ValueError(f"Not a valid normal baseline: {run_id}")
    if metadata.get("run_id") != run_id or telemetry_root.name != run_id:
        raise ValueError(f"Run-ID mismatch: {run_id}")

    start_text = metadata["phases"]["normal_baseline_start_utc"]
    end_text = metadata["phases"]["normal_baseline_end_utc"]
    start, end = parse_utc(start_text), parse_utc(end_text)
    window_count = math.floor((end - start) / WINDOW_SECONDS)
    analysis_end = start + window_count * WINDOW_SECONDS
    windows = {
        name: [[] for _ in range(window_count)] for name in POPULATIONS
    }
    excluded_tail = 0

    with (telemetry_root / "selected/traces.ndjson").open("r", encoding="utf-8") as handle:
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
                    excluded_tail += 1
                    continue
                route = route_of(span)
                item = (float(span.get("duration", 0)) / 1000, is_error(span))
                index = int((timestamp - start) // WINDOW_SECONDS)
                for name, includes in POPULATIONS.items():
                    if includes(route):
                        windows[name][index].append(item)

    return {
        "run_id": run_id,
        "normal_baseline_start_utc": start_text,
        "normal_baseline_end_utc": end_text,
        "window_seconds": WINDOW_SECONDS,
        "partial_tail_excluded_frontend_span_count": excluded_tail,
        "populations": {name: summarize_windows(items) for name, items in windows.items()},
    }


def combined_population(runs: list[dict[str, Any]], name: str) -> dict[str, Any]:
    windows = [window for run in runs for window in run["populations"][name]["windows"]]
    nonempty = [window for window in windows if window["request_count"]]
    p95_values = [window["p95_latency_ms"] for window in nonempty]
    error_rates = [window["error_rate"] for window in nonempty]
    return {
        "request_count": sum(window["request_count"] for window in windows),
        "error_count": sum(window["error_count"] for window in windows),
        "window_count": len(windows),
        "nonempty_window_count": len(nonempty),
        "empty_window_count": len(windows) - len(nonempty),
        "window_coverage_fraction": len(nonempty) / len(windows),
        "nonempty_window_p95_latency_ms": {
            "p50": percentile(p95_values, 0.50),
            "p95": percentile(p95_values, 0.95),
            "p99": percentile(p95_values, 0.99),
            "max": max(p95_values) if p95_values else None,
        },
        "nonempty_window_error_rate": {
            "p95": percentile(error_rates, 0.95),
            "p99": percentile(error_rates, 0.99),
            "max": max(error_rates) if error_rates else None,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--run-id", action="append", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    runs = [analyze_run(args.repo_root, run_id) for run_id in args.run_id]
    output = {
        "schema_version": 1,
        "analysis_kind": "route-specific-normal-sli-decision-support",
        "source_run_ids": args.run_id,
        "route_population_definitions": {
            "global_user_routes": "all frontend user server spans",
            "root_excluded_user_routes": "all frontend user server spans except exact route /",
            "product_detail_family": "frontend user server spans whose normalized path starts with /product/",
        },
        "window_seconds": WINDOW_SECONDS,
        "runs": runs,
        "combined_populations": {
            name: combined_population(runs, name) for name in POPULATIONS
        },
        "limitations": [
            "Selected same-host normal runs are descriptive pilot evidence, not population truth.",
            "Empty route-specific windows have no latency percentile and are reported, not imputed.",
            "Nearest-rank p95 is unstable in windows with few requests.",
            "Route scoping changes the measured user population and requires an explicit academic decision.",
            "This output does not freeze an SLO or authorize fault injection.",
        ],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
