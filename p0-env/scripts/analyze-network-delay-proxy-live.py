#!/usr/bin/env python3
"""Analyze the preregistered fault-free live proxy compatibility gate."""

from __future__ import annotations

import argparse
import json
import math
import statistics
from datetime import datetime
from pathlib import Path
from typing import Any


TARGET_EDGE = "recommendationservice->productcatalogservice"
WINDOW_SECONDS = 5
MIN_WINDOWS = 48
MAX_MEDIAN_OVERHEAD_MS = 5.0


def load(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def epoch(value: str) -> float:
    return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()


def percentile(values: list[float], fraction: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    return ordered[min(len(ordered) - 1, math.ceil(fraction * len(ordered)) - 1)]


def tags(item: dict[str, Any]) -> dict[str, Any]:
    return {tag.get("key"): tag.get("value") for tag in item.get("tags", [])}


def service(span: dict[str, Any], processes: dict[str, Any]) -> str:
    return str(processes.get(span.get("processID"), {}).get("serviceName", "unknown"))


def parent_id(span: dict[str, Any]) -> str | None:
    values = [str(ref.get("spanID")) for ref in span.get("references", []) if ref.get("spanID") and str(ref.get("refType", "CHILD_OF")).upper() == "CHILD_OF"]
    if len(values) > 1:
        raise ValueError(f"ambiguous_parent:{span.get('spanID')}")
    return values[0] if values else None


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


def pod_map(snapshot: dict[str, Any]) -> dict[str, tuple[str, str]]:
    result = {}
    for pod in snapshot["pods"]["items"]:
        app = pod["metadata"].get("labels", {}).get("app")
        if not app:
            continue
        restarts = json.dumps(sorted((item["name"], int(item["restartCount"])) for item in pod.get("status", {}).get("containerStatuses", [])))
        result[str(app)] = (str(pod["metadata"]["uid"]), restarts)
    return result


def phase_summary(edge_values: list[tuple[float, float]], user_values: list[tuple[float, float, bool, bool]], start: float, end: float, slo: dict[str, Any]) -> dict[str, Any]:
    expected = math.floor((end - start) / WINDOW_SECONDS)
    edge_windows: list[list[float]] = [[] for _ in range(expected)]
    product: list[list[float]] = [[] for _ in range(expected)]
    global_errors: list[list[bool]] = [[] for _ in range(expected)]
    for timestamp, duration in edge_values:
        if start <= timestamp < start + expected * WINDOW_SECONDS:
            edge_windows[int((timestamp - start) // WINDOW_SECONDS)].append(duration)
    for timestamp, duration, is_product, is_failed in user_values:
        if start <= timestamp < start + expected * WINDOW_SECONDS:
            index = int((timestamp - start) // WINDOW_SECONDS)
            global_errors[index].append(is_failed)
            if is_product:
                product[index].append(duration)
    edge_all = [value for window in edge_windows for value in window]
    windows = []
    latency_streak = error_streak = max_latency_streak = max_error_streak = 0
    for index in range(expected):
        product_p95 = percentile(product[index], 0.95)
        error_rate = sum(global_errors[index]) / len(global_errors[index]) if global_errors[index] else None
        latency_streak = latency_streak + 1 if product_p95 is not None and product_p95 > float(slo["latency"]["threshold_ms"]) else 0
        error_streak = error_streak + 1 if error_rate is not None and error_rate > float(slo["error"]["threshold"]) else 0
        max_latency_streak = max(max_latency_streak, latency_streak)
        max_error_streak = max(max_error_streak, error_streak)
        windows.append({"window_index": index, "edge_span_count": len(edge_windows[index]), "edge_p95_latency_ms": percentile(edge_windows[index], 0.95), "product_request_count": len(product[index]), "product_p95_latency_ms": product_p95, "global_request_count": len(global_errors[index]), "global_error_rate": error_rate})
    return {
        "duration_seconds": end - start,
        "expected_window_count": expected,
        "edge_span_count": len(edge_all),
        "edge_nonempty_window_count": sum(bool(values) for values in edge_windows),
        "edge_latency_ms": {"median": statistics.median(edge_all) if edge_all else None, "p95": percentile(edge_all, 0.95), "p99": percentile(edge_all, 0.99)},
        "maximum_latency_violation_streak": max_latency_streak,
        "maximum_error_violation_streak": max_error_streak,
        "failure_manifestation": max_latency_streak >= int(slo["latency"]["consecutive_violating_windows"]) or max_error_streak >= int(slo["error"]["consecutive_violating_windows"]),
        "windows": windows,
    }


def analyze(repo: Path) -> dict[str, Any]:
    run_id = "ob-network-proxy-live-001"
    root = repo / "p0-env/artifacts/P2-NETWORK-DELAY-PROXY-LIVE-001" / run_id
    phases = load(root / "phases.json")
    profile = load(repo / "p0-env/config/faults/network-delay-recommendation-productcatalog-v1.json")
    slo = load(repo / "p0-env/config/slo/p2-network-delay-001-slo-v1.json")
    edge_values: list[tuple[float, float]] = []
    user_values: list[tuple[float, float, bool, bool]] = []
    observed_run_ids: set[str] = set()
    trace_path = repo / "p0-env/artifacts/telemetry" / run_id / "selected/traces.ndjson"
    with trace_path.open("r", encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, 1):
            if not line.strip():
                continue
            trace = json.loads(line)
            processes = trace.get("processes", {})
            for process in processes.values():
                value = tags(process).get("experiment.run_id")
                if value:
                    observed_run_ids.add(str(value))
            spans = {str(span.get("spanID")): span for span in trace.get("spans", []) if span.get("spanID")}
            for span in spans.values():
                span_tags = tags(span)
                timestamp = float(span.get("startTime", 0)) / 1_000_000
                duration = float(span.get("duration", 0)) / 1000
                if service(span, processes) == "frontend" and str(span_tags.get("span.kind", "")).lower() == "server" and "health" not in route(span).lower():
                    user_values.append((timestamp, duration, route(span).startswith("/product/"), failed(span)))
                parent_span_id = parent_id(span)
                if not parent_span_id or parent_span_id not in spans:
                    continue
                parent = spans[parent_span_id]
                if service(parent, processes) == "recommendationservice" and service(span, processes) == "productcatalogservice" and str(tags(parent).get("span.kind", "")).lower() == "client" and str(span_tags.get("span.kind", "")).lower() == "server":
                    edge_values.append((float(parent.get("startTime", 0)) / 1_000_000, float(parent.get("duration", 0)) / 1000))
    p = phases["phases"]
    base = phase_summary(edge_values, user_values, epoch(p["base_measurement_start_utc"]), epoch(p["base_measurement_end_utc"]), slo)
    proxy = phase_summary(edge_values, user_values, epoch(p["proxy_measurement_start_utc"]), epoch(p["proxy_measurement_end_utc"]), slo)
    overhead = proxy["edge_latency_ms"]["median"] - base["edge_latency_ms"]["median"] if base["edge_latency_ms"]["median"] is not None and proxy["edge_latency_ms"]["median"] is not None else None

    host_before, host_after = load(root / "host-before.json"), load(root / "host-after.json")
    host_deltas = {name: host_after["events"][name]["count"] - host_before["events"][name]["count"] for name in host_before["events"]}
    clean_before, clean_after, rollback = load(root / "proxy-clean-before.json"), load(root / "proxy-clean-after.json"), load(root / "rollback-verification.json")
    snapshots = {name: load(root / f"{name}.json") for name in ("base-measurement-before", "base-measurement-after", "proxy-measurement-before", "proxy-measurement-after")}
    base_pods_before, base_pods_after = pod_map(snapshots["base-measurement-before"]), pod_map(snapshots["base-measurement-after"])
    proxy_pods_before, proxy_pods_after = pod_map(snapshots["proxy-measurement-before"]), pod_map(snapshots["proxy-measurement-after"])

    checks: list[dict[str, Any]] = []
    def check(name: str, passed: bool, observed: Any) -> None:
        checks.append({"name": name, "passed": bool(passed), "observed": observed})
    check("run_id_identity", phases["run_id"] == run_id and observed_run_ids in ({run_id}, set()), {"metadata": phases["run_id"], "traces": sorted(observed_run_ids)})
    check("scientific_fault_not_started", phases["scientific_fault_started"] is False and profile["scientific_run_authorized"] is False, False)
    check("workload_identity", phases["workload_profile_id"] == "ob-second-15u-1r-v1", phases["workload_profile_id"])
    check("phase_minimum_durations", base["duration_seconds"] >= 300 and proxy["duration_seconds"] >= 300 and epoch(p["base_warmup_end_utc"]) - epoch(p["base_warmup_start_utc"]) >= 300 and epoch(p["proxy_stabilization_end_utc"]) - epoch(p["proxy_stabilization_start_utc"]) >= 120, {"base": base["duration_seconds"], "proxy": proxy["duration_seconds"]})
    check("base_edge_coverage", base["edge_nonempty_window_count"] >= MIN_WINDOWS, base["edge_nonempty_window_count"])
    check("proxy_edge_coverage", proxy["edge_nonempty_window_count"] >= MIN_WINDOWS, proxy["edge_nonempty_window_count"])
    check("median_overhead", overhead is not None and overhead <= MAX_MEDIAN_OVERHEAD_MS, {"observed_ms": overhead, "maximum_ms": MAX_MEDIAN_OVERHEAD_MS})
    check("proxy_slo_no_manifestation", proxy["failure_manifestation"] is False, {"latency_streak": proxy["maximum_latency_violation_streak"], "error_streak": proxy["maximum_error_violation_streak"]})
    check("proxy_clean_before", clean_before["cleanup_verified"] and clean_before["after"]["toxics"] == [] and not clean_before["reset_called"], clean_before["after"])
    check("proxy_clean_after", clean_after["cleanup_verified"] and clean_after["after"]["toxics"] == [] and not clean_after["reset_called"], clean_after["after"])
    check("base_all_pods_stable", base_pods_before == base_pods_after, sorted(name for name in base_pods_before if base_pods_before.get(name) != base_pods_after.get(name)))
    check("proxy_all_pods_stable", proxy_pods_before == proxy_pods_after, sorted(name for name in proxy_pods_before if proxy_pods_before.get(name) != proxy_pods_after.get(name)))
    check("rollback_verified", rollback["passed"] and rollback["containers"] == ["server"] and rollback["product_catalog_address"] == "productcatalogservice:3550" and rollback["proxy_configmap_absent"], rollback)
    check("host_event_deltas_zero", all(value == 0 for value in host_deltas.values()), host_deltas)
    passed = all(item["passed"] for item in checks)
    return {"schema_version": 1, "gate_id": "P2-NETWORK-DELAY-PROXY-LIVE-001", "run_id": run_id, "status": "valid" if passed else "invalid", "verification_passed": passed, "scientific_fault_started": False, "target_edge": TARGET_EDGE, "thresholds": {"minimum_nonempty_windows": MIN_WINDOWS, "maximum_median_overhead_ms": MAX_MEDIAN_OVERHEAD_MS}, "base": base, "proxy": proxy, "median_overhead_ms": overhead, "host_event_deltas": host_deltas, "checks": checks, "limitations": ["Sequential base-then-proxy order cannot eliminate same-host time drift.", "One 15-user compatibility gate is not population-level overhead evidence."]}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    result = analyze(args.repo_root.resolve())
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": result["status"], "median_overhead_ms": result["median_overhead_ms"], "base_windows": result["base"]["edge_nonempty_window_count"], "proxy_windows": result["proxy"]["edge_nonempty_window_count"]}, sort_keys=True))
    return 0 if result["verification_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
