#!/usr/bin/env python3
"""Independently verify the frozen first network-delay run contract."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


RUN_ID = "ob-netdelay-15u-003"


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def verify(root: Path) -> dict:
    profile = load(root / "p0-env/config/faults/network-delay-recommendation-productcatalog-15u-v1.json")
    design = load(root / "p0-env/config/faults/network-delay-recommendation-productcatalog-v1.json")
    workload = load(root / "p0-env/config/workloads/ob-second-15u-1r-v1.json")
    slo = load(root / "p0-env/config/slo/p2-network-delay-001-slo-v1.json")
    live = load(root / "p0-env/artifacts/P2-NETWORK-DELAY-PROXY-LIVE-001/ob-network-proxy-live-001/analysis.json")
    prereg = (root / "p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-003-preregistration.md").read_text(encoding="utf-8")
    observability = (root / "p0-env/config/online-boutique/observability.yaml").read_text(encoding="utf-8")
    kustomization = (root / "p0-env/config/online-boutique/kustomization.yaml").read_text(encoding="utf-8")
    checks = []

    def check(name: str, passed: bool, observed: object) -> None:
        checks.append({"name": name, "passed": bool(passed), "observed": observed})

    check("identity", profile["scientific_run_id"] == RUN_ID and profile["experiment_id"] == "P2-NETWORK-DELAY-001", profile["scientific_run_id"])
    check("execution_not_authorized", profile["execution_authorized_in_this_pr"] is False and "explicit_user_approval" in profile["execution_authorization_policy"], profile["execution_authorization_policy"])
    check("workload", profile["workload"] == {"users": 15, "spawn_rate_per_second": 1, "random_seed": 1} and workload["loadgenerator"]["users"] == 15 and workload["loadgenerator"]["spawn_rate_per_second"] == 1 and workload["loadgenerator"]["random_seed"] == 1, profile["workload"])
    check("target_matches_design", profile["target_edge"] == design["target_edge"], profile["target_edge"])
    injector = profile["injector"]
    check("ramp", injector["ramp_update_interval_seconds"] == 10 and injector["ramp_latency_ms"] == [63, 125, 188, 250, 313, 375, 438, 500, 563, 625, 688, 750] and injector["steady_latency_ms"] == 750 and injector["jitter_ms"] == 0 and injector["toxicity"] == 1.0, injector["ramp_latency_ms"])
    check("lifecycle", profile["lifecycle_seconds"] == {"warmup": 300, "normal_baseline": 300, "fault_ramp": 120, "fault_steady": 300, "cooldown": 300}, profile["lifecycle_seconds"])
    effect = profile["physical_effect"]
    check("physical_effect", effect["minimum_baseline_and_steady_nonempty_windows"] == 48 and effect["minimum_steady_minus_baseline_median_ms"] == 500 and effect["command_success_alone_is_sufficient"] is False, effect)
    symptom = profile["first_symptom"]
    symptom_keys = ("window_seconds", "measurement", "operator", "threshold_ms", "consecutive_violating_windows")
    check("symptom_frozen_from_design", all(symptom[key] == design["first_symptom"][key] for key in symptom_keys), symptom)
    check("slo_frozen_before_fault", slo["decision_status"] == "frozen_before_fault_observation" and slo["fault_data_used"] is False and profile["failure_manifestation_slo_id"] == slo["slo_id"], slo["slo_id"])
    check("live_proxy_gate", live.get("status") == "valid" and live.get("verification_passed") is True and live.get("scientific_fault_started") is False, {"status": live.get("status"), "verification_passed": live.get("verification_passed"), "scientific_fault_started": live.get("scientific_fault_started")})
    check("run_id_propagation_configured", RUN_ID in observability and RUN_ID in kustomization, RUN_ID)
    check("invalid_preservation_preregistered", all(term in prereg for term in ("aynı ID tekrarlanmaz", "Invalid kanıt silinmez", "eşikler sonuçtan sonra değiştirilmez")), "preservation clauses")
    check("models_out_of_scope", all(term in prereg for term in ("model eğitimi", "LLM doğrulaması", "graph/GAT")), "model exclusions")
    return {"schema_version": 1, "verification_kind": "p2-network-delay-first-run-preregistration", "run_id": RUN_ID, "verification_passed": all(item["passed"] for item in checks), "scientific_fault_started": False, "checks": checks}


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
