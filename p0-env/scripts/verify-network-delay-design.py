#!/usr/bin/env python3
"""Fail-closed verifier for the frozen P2 network-delay design evidence."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


TARGET_EDGE = "recommendationservice->productcatalogservice"


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def longest_streak(values: list[float], threshold: float) -> int:
    best = current = 0
    for value in values:
        current = current + 1 if value > threshold else 0
        best = max(best, current)
    return best


def verify(root: Path) -> dict:
    evidence = root / "p0-env/artifacts/P2-NETWORK-DELAY-DESIGN-001"
    edge_data = load(evidence / "edge-candidates.json")
    route_data = load(evidence / "route-specific-normal-sli.json")
    replay = load(evidence / "slo-normal-replay.json")
    profile = load(root / "p0-env/config/faults/network-delay-recommendation-productcatalog-v1.json")
    slo = load(root / "p0-env/config/slo/p2-network-delay-001-slo-v1.json")
    proxy = load(root / "p0-env/config/network-delay-design/toxiproxy.json")
    patch = load(root / "p0-env/config/network-delay-design/recommendation-proxy-patch.json")

    checks: list[dict] = []

    def check(name: str, condition: bool, observed: object) -> None:
        checks.append({"name": name, "passed": bool(condition), "observed": observed})

    source_ids = edge_data["source_run_ids"]
    edge = next(item for item in edge_data["aggregate"]["edge_summaries"] if item["edge"] == TARGET_EDGE)
    check("six_source_normal_runs", len(source_ids) == 6 and len(set(source_ids)) == 6, source_ids)
    check("target_edge_eligible", edge["eligible"], edge["eligible"])
    check("target_edge_all_runs", set(edge["per_run"]) == set(source_ids), sorted(edge["per_run"]))
    check("target_edge_two_workloads", len(edge_data["aggregate"]["workload_run_ids"]) == 2,
          edge_data["aggregate"]["workload_run_ids"])
    check("target_edge_minimum_coverage", edge["minimum_window_coverage"] >= 0.8,
          edge["minimum_window_coverage"])

    symptom = profile["first_symptom"]
    threshold = float(symptom["threshold_ms"])
    all_windows = [
        window["p95_latency_ms"]
        for run in edge["per_run"].values()
        for window in run["windows"]
    ]
    sorted_windows = sorted(all_windows)
    nearest_rank_p99 = sorted_windows[max(0, (99 * len(sorted_windows) + 99) // 100 - 1)]
    check("first_symptom_equals_target_edge_p99", threshold == nearest_rank_p99,
          {"configured": threshold, "recomputed": nearest_rank_p99})
    per_run_streak = {
        run_id: longest_streak([w["p95_latency_ms"] for w in run["windows"]], threshold)
        for run_id, run in edge["per_run"].items()
    }
    check("first_symptom_no_normal_false_positive",
          all(value < symptom["consecutive_violating_windows"] for value in per_run_streak.values()),
          per_run_streak)

    route_p99 = route_data["combined_populations"]["product_detail_family"]["nonempty_window_p95_latency_ms"]["p99"]
    check("slo_threshold_equals_normal_product_detail_p99", slo["latency"]["threshold_ms"] == route_p99,
          {"configured": slo["latency"]["threshold_ms"], "normal_p99": route_p99})
    check("slo_uses_no_fault_data", slo["fault_data_used"] is False, slo["fault_data_used"])
    check("slo_replay_passed", replay["verification_passed"] and replay["false_manifestation_count"] == 0,
          {"passed": replay["verification_passed"], "false_manifestations": replay["false_manifestation_count"]})
    check("source_run_identity", set(source_ids) == set(slo["source_normal_run_ids"]) == set(replay["source_run_ids"]),
          {"edge": source_ids, "slo": slo["source_normal_run_ids"], "replay": replay["source_run_ids"]})

    target = profile["target_edge"]
    proxy_item = proxy[0]
    containers = patch["spec"]["template"]["spec"]["containers"]
    server = next(item for item in containers if item["name"] == "server")
    sidecar = next(item for item in containers if item["name"] == "network-delay-proxy")
    env = next(item for item in server["env"] if item["name"] == target["caller_environment_variable"])
    check("profile_target_edge", f'{target["caller_service"]}->{target["callee_service"]}' == TARGET_EDGE, target)
    check("proxy_contract_matches_profile",
          proxy_item["name"] == target["proxy_name"] and proxy_item["listen"] == target["proxy_listen"]
          and proxy_item["upstream"] == target["proxy_upstream"] and proxy_item["enabled"] is True
          and proxy_item.get("toxics", []) == [], proxy_item)
    check("overlay_reroutes_only_named_environment_variable",
          env["name"] == target["caller_environment_variable"] and env["value"] == target["proxy_listen"], env)
    check("pinned_sidecar_image_matches_profile", sidecar["image"] == profile["injector"]["image"], sidecar["image"])
    check("configured_delay_exceeds_slo_threshold",
          profile["injector"]["target_latency_ms"] > slo["latency"]["threshold_ms"],
          {"delay_ms": profile["injector"]["target_latency_ms"], "slo_ms": slo["latency"]["threshold_ms"]})
    check("physical_effect_floor_is_measurable_and_below_configured_delay",
          0 < profile["physical_effect"]["minimum_steady_minus_baseline_median_ms"]
          <= profile["injector"]["target_latency_ms"], profile["physical_effect"])
    check("scientific_run_not_authorized",
          profile["scientific_run_authorized"] is False and profile["scientific_run_id"] is None,
          {"authorized": profile["scientific_run_authorized"], "run_id": profile["scientific_run_id"]})

    passed = all(item["passed"] for item in checks)
    return {
        "schema_version": 1,
        "verification_kind": "p2-network-delay-design-gate",
        "design_id": "P2-NETWORK-DELAY-DESIGN-001",
        "verification_passed": passed,
        "scientific_fault_started": False,
        "checks": checks,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = verify(args.root.resolve())
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"verification_passed": result["verification_passed"], "checks": len(result["checks"])}, sort_keys=True))
    return 0 if result["verification_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
