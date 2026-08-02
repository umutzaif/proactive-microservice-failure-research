#!/usr/bin/env python3
"""Compare target-service candidates inside a verified normal-baseline window."""

from __future__ import annotations

import argparse
import json
import math
import statistics
from datetime import datetime
from pathlib import Path
from typing import Any


def parse_utc(value: str) -> float:
    return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()


def percentile(values: list[float], fraction: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    index = min(len(ordered) - 1, math.ceil(fraction * len(ordered)) - 1)
    return ordered[index]


def load_json(path: Path) -> Any:
    # utf-8-sig accepts both plain UTF-8 and PowerShell 5.1 UTF-8 BOM output.
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def metric_summary(
    series: list[dict[str, Any]],
    service: str,
    start: float,
    end: float,
) -> dict[str, Any]:
    rates: list[float] = []
    memory: list[float] = []
    start_times: set[float] = set()
    pods: set[str] = set()

    for item in series:
        metric = item["metric"]
        if not metric.get("pod", "").startswith(f"{service}-"):
            continue
        if metric.get("container") != "server":
            continue

        values = [
            (float(timestamp), float(value))
            for timestamp, value in item.get("values", [])
            if start <= float(timestamp) <= end
            and value not in {"NaN", "Inf", "-Inf"}
        ]
        name = metric.get("__name__")

        if name == "container_cpu_usage_seconds_total" and values:
            pods.add(metric["pod"])
            for (time_0, value_0), (time_1, value_1) in zip(
                values, values[1:]
            ):
                if time_1 > time_0 and value_1 >= value_0:
                    rates.append((value_1 - value_0) / (time_1 - time_0))
        elif name == "container_memory_working_set_bytes":
            memory.extend(value for _, value in values)
        elif name == "container_start_time_seconds":
            start_times.update(value for _, value in values)

    return {
        "baseline_pods": sorted(pods),
        "cpu_interval_count": len(rates),
        "cpu_mean_millicores": statistics.mean(rates) * 1000
        if rates
        else None,
        "cpu_p95_millicores": percentile(rates, 0.95) * 1000
        if rates
        else None,
        "cpu_max_millicores": max(rates) * 1000 if rates else None,
        "memory_mean_mib": statistics.mean(memory) / 1048576
        if memory
        else None,
        "memory_p95_mib": percentile(memory, 0.95) / 1048576
        if memory
        else None,
        "distinct_container_start_times": len(start_times),
    }


def span_is_error(span: dict[str, Any]) -> bool:
    tags = {item.get("key"): item.get("value") for item in span.get("tags", [])}
    return bool(
        tags.get("error") is True
        or str(tags.get("otel.status_code", "")).upper() == "ERROR"
        or (
            isinstance(tags.get("http.status_code"), (int, float))
            and tags["http.status_code"] >= 500
        )
        or (
            isinstance(tags.get("rpc.grpc.status_code"), (int, float))
            and tags["rpc.grpc.status_code"] != 0
        )
    )


def trace_summaries(
    trace_path: Path,
    candidates: list[str],
    start: float,
    end: float,
) -> dict[str, dict[str, Any]]:
    working = {
        service: {"durations": [], "errors": 0, "operations": {}}
        for service in candidates
    }

    with trace_path.open("r", encoding="utf-8") as handle:
        for line in handle:
            trace = json.loads(line)
            processes = trace.get("processes", {})

            for span in trace.get("spans", []):
                timestamp = float(span.get("startTime", 0)) / 1_000_000
                if not start <= timestamp <= end:
                    continue

                service = processes.get(span.get("processID"), {}).get(
                    "serviceName"
                )
                if service not in working:
                    continue

                operation = span.get("operationName", "")
                if (
                    "health" in operation.lower()
                    or "TraceService/Export" in operation
                ):
                    continue

                state = working[service]
                state["durations"].append(float(span.get("duration", 0)))
                state["operations"][operation] = (
                    state["operations"].get(operation, 0) + 1
                )
                if span_is_error(span):
                    state["errors"] += 1

    result: dict[str, dict[str, Any]] = {}
    for service, state in working.items():
        durations = state["durations"]
        result[service] = {
            "baseline_user_path_span_count": len(durations),
            "duration_mean_ms": statistics.mean(durations) / 1000
            if durations
            else None,
            "duration_p95_ms": percentile(durations, 0.95) / 1000
            if durations
            else None,
            "duration_max_ms": max(durations) / 1000 if durations else None,
            "error_span_count": state["errors"],
            "top_operations": sorted(
                state["operations"].items(),
                key=lambda item: item[1],
                reverse=True,
            )[:10],
        }

    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--telemetry-root", required=True, type=Path)
    parser.add_argument("--metadata", required=True, type=Path)
    parser.add_argument("--candidates", nargs="+", required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    metadata = load_json(args.metadata)
    if metadata.get("valid_run") is not True:
        raise ValueError("Candidate analysis requires valid_run=true metadata.")

    start = parse_utc(metadata["phases"]["normal_baseline_start_utc"])
    end = parse_utc(metadata["phases"]["normal_baseline_end_utc"])
    metric_payload = load_json(
        args.telemetry_root / "raw/metrics/prometheus-query-range.json"
    )
    series = metric_payload["data"]["result"]
    traces = trace_summaries(
        args.telemetry_root / "selected/traces.ndjson",
        args.candidates,
        start,
        end,
    )

    output = {
        "schema_version": 1,
        "source_run_id": metadata["run_id"],
        "normal_baseline_start_utc": metadata["phases"][
            "normal_baseline_start_utc"
        ],
        "normal_baseline_end_utc": metadata["phases"][
            "normal_baseline_end_utc"
        ],
        "warmup_excluded": True,
        "candidates": {
            service: {
                "metrics": metric_summary(series, service, start, end),
                "traces": traces[service],
            }
            for service in args.candidates
        },
        "limitations": [
            "The comparison uses one valid normal-baseline run.",
            "It describes target suitability and does not prove fault response.",
            "Health-check and OTLP exporter spans are excluded from user-path counts.",
        ],
    }
    rendered = json.dumps(output, indent=2, sort_keys=True)

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered + "\n", encoding="utf-8")
    else:
        print(rendered)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
