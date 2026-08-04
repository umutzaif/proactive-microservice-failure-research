#!/usr/bin/env python3
"""Apply the frozen SLO to a fault run on one fixed UTC window grid."""

from __future__ import annotations

import argparse
import json
import math
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def load(path: Path) -> Any:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def epoch(value: str) -> float:
    return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()


def utc(value: float) -> str:
    return datetime.fromtimestamp(value, timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def percentile(values: list[float], fraction: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    return ordered[min(len(ordered) - 1, math.ceil(fraction * len(ordered)) - 1)]


def tags(span: dict[str, Any]) -> dict[str, Any]:
    return {item.get("key"): item.get("value") for item in span.get("tags", [])}


def route(span: dict[str, Any]) -> str:
    values = tags(span)
    for key in ("http.route", "url.path", "http.target"):
        if values.get(key):
            return str(values[key]).split("?", 1)[0]
    return str(span.get("operationName", "unknown"))


def failed(span: dict[str, Any]) -> bool:
    values = tags(span)
    status = values.get("http.response.status_code", values.get("http.status_code"))
    return bool(values.get("error") is True or str(values.get("otel.status_code", "")).upper() == "ERROR" or isinstance(status, (int, float)) and status >= 500)


def frontend_user_span(span: dict[str, Any], processes: dict[str, Any]) -> bool:
    values = tags(span)
    operation = str(span.get("operationName", "")).lower()
    path = route(span).lower()
    return bool(
        processes.get(span.get("processID"), {}).get("serviceName") == "frontend"
        and str(values.get("span.kind", "")).lower() == "server"
        and "health" not in operation
        and "health" not in path
        and "traceservice/export" not in operation
    )


def first_completion(windows: list[dict[str, Any]], field: str, threshold: float, required: int) -> int | None:
    streak = 0
    for item in windows:
        value = item[field]
        if value is None:
            streak = 0
        elif float(value) > threshold:
            streak += 1
            if streak == required:
                return int(item["window_index"])
        else:
            streak = 0
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--telemetry-root", type=Path, required=True)
    parser.add_argument("--draft-metadata", type=Path, required=True)
    parser.add_argument("--slo-config", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    metadata, slo = load(args.draft_metadata), load(args.slo_config)
    if slo["window_alignment"]["anchor"] != "normal_baseline_start_utc" or slo["window_alignment"]["phase_boundary_realignment"] is not False:
        raise ValueError("unexpected SLO window-alignment contract")
    anchor = epoch(metadata["phases"]["normal_baseline_start_utc"])
    end = epoch(metadata["phases"]["cooldown_end_utc"])
    seconds = int(slo["window_seconds"])
    count = math.floor((end - anchor) / seconds)
    product: list[list[tuple[float, bool]]] = [[] for _ in range(count)]
    global_: list[list[tuple[float, bool]]] = [[] for _ in range(count)]
    trace_path = args.telemetry_root / "selected/traces.ndjson"
    with trace_path.open("r", encoding="utf-8") as handle:
        for line in handle:
            trace = json.loads(line)
            processes = trace.get("processes", {})
            for span in trace.get("spans", []):
                if not frontend_user_span(span, processes):
                    continue
                timestamp = float(span.get("startTime", 0)) / 1_000_000
                if not anchor <= timestamp < anchor + count * seconds:
                    continue
                index = int((timestamp - anchor) // seconds)
                item = (float(span.get("duration", 0)) / 1000, failed(span))
                global_[index].append(item)
                if route(span).startswith("/product/"):
                    product[index].append(item)
    windows = []
    for index in range(count):
        product_durations = [duration for duration, _ in product[index]]
        global_errors = sum(1 for _, is_failed in global_[index] if is_failed)
        windows.append({
            "window_index": index,
            "start_utc": utc(anchor + index * seconds),
            "end_utc": utc(anchor + (index + 1) * seconds),
            "product_request_count": len(product[index]),
            "product_p95_latency_ms": percentile(product_durations, 0.95),
            "global_request_count": len(global_[index]),
            "global_error_count": global_errors,
            "global_error_rate": global_errors / len(global_[index]) if global_[index] else None,
        })
    latency_index = first_completion(windows, "product_p95_latency_ms", float(slo["latency"]["threshold_ms"]), int(slo["latency"]["consecutive_violating_windows"]))
    error_index = first_completion(windows, "global_error_rate", float(slo["error"]["threshold"]), int(slo["error"]["consecutive_violating_windows"]))
    candidates = [(index, kind) for index, kind in ((latency_index, "latency"), (error_index, "error")) if index is not None]
    first = min(candidates) if candidates else None
    output = {
        "schema_version": 1,
        "run_id": metadata["run_id"],
        "slo_id": slo["slo_id"],
        "window_anchor_utc": metadata["phases"]["normal_baseline_start_utc"],
        "window_seconds": seconds,
        "complete_window_count": count,
        "analysis_end_utc": utc(anchor + count * seconds),
        "phase_boundary_realignment": False,
        "latency_manifestation_completion_window_index": latency_index,
        "error_manifestation_completion_window_index": error_index,
        "failure_manifestation": windows[first[0]]["end_utc"] if first else None,
        "manifestation_trigger": first[1] if first else None,
        "windows": windows,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
