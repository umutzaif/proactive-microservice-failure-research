#!/usr/bin/env python3
"""Fail-closed verifier for the pre-calculation D-061 headroom decision inputs."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def verify(root: Path) -> list[str]:
    path = root / "p0-env/config/analysis/network-delay-headroom-decision-inputs-v1.json"
    profile = json.loads(path.read_text(encoding="utf-8-sig"))
    failures: list[str] = []

    def check(name: str, condition: bool) -> None:
        if not condition:
            failures.append(name)

    check("identity", profile.get("profile_id") == "network-delay-headroom-decision-inputs-v1" and profile.get("profile_status") == "academic_choices_resolved_collection_tooling_pending")
    check("decisions", profile.get("decision_ids") == ["D-061", "D-062", "D-063", "D-066", "D-067", "D-068", "D-069", "D-070"])
    resources = profile.get("active_resource_contract", {})
    resource_patch = json.loads((root / "p0-env/config/network-delay-resource-compatibility/recommendation-server-cpu-limit.json").read_text(encoding="utf-8-sig"))
    base_recommendation = (root / "p0-env/source/microservices-demo/kustomize/base/recommendationservice.yaml").read_text(encoding="utf-8-sig")
    check("resources", resources.get("target_service") == "recommendationservice" and resources.get("server_cpu_limit") == "500m" and resources.get("server_cpu_request") == "100m" and resource_patch == [{"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/cpu", "value": "500m"}] and "requests:\n            cpu: 100m" in base_recommendation.replace("\r\n", "\n"))
    observed_workloads = []
    for item in profile.get("workloads", []):
        workload = json.loads((root / f"p0-env/config/workloads/{item.get('profile_id')}.json").read_text(encoding="utf-8-sig"))
        load = workload.get("loadgenerator", {})
        observed_workloads.append((workload.get("profile_id"), load.get("users"), load.get("spawn_rate_per_second"), load.get("random_seed")))
    check("workloads", observed_workloads == [("ob-default-10u-1r-v1", 10, 1, 1), ("ob-second-15u-1r-v1", 15, 1, 1)])
    check("ladder", profile.get("candidate_delay_ms") == [25, 50, 100, 250, 500])
    slo = profile.get("frozen_slo", {})
    frozen_slo = json.loads((root / "p0-env/config/slo/p2-network-delay-001-slo-v1.json").read_text(encoding="utf-8-sig"))
    check("slo", slo.get("slo_id") == frozen_slo.get("slo_id") == "p2-network-delay-001-slo-v1" and slo.get("population") == frozen_slo.get("latency", {}).get("population") == "product_detail_family" and slo.get("statistic") == frozen_slo.get("latency", {}).get("statistic") == "window_p95_latency_ms" and slo.get("threshold_ms") == frozen_slo.get("latency", {}).get("threshold_ms") == 594.664 and slo.get("consecutive_violating_windows") == frozen_slo.get("latency", {}).get("consecutive_violating_windows") == 3)
    eligible = profile.get("eligible_normal_run_contract", {})
    check("independence", eligible.get("minimum_valid_runs_per_workload") == 3 and eligible.get("independent_unit") == "run")
    check("historical_exclusions", eligible.get("historical_200m_normal_runs_eligible") is False and eligible.get("historical_750ms_fault_runs_eligible") is False)
    choices = profile.get("resolved_academic_choices", {})
    check("choices_resolved", set(choices) == {"normal_topology", "normal_upper_bound_and_uncertainty_method"} and choices.get("normal_topology", {}).get("status") == "selected" and choices.get("normal_topology", {}).get("recommended") == "no_toxic_proxy_overlay" and choices.get("normal_upper_bound_and_uncertainty_method", {}).get("status") == "selected" and choices.get("normal_upper_bound_and_uncertainty_method", {}).get("recommended") == "run_level_max_plus_prespecified_measurement_margin")
    formula = profile.get("uncertainty_formula", {})
    sequence = profile.get("collection_sequence", {})
    check("formula_and_sequence", formula.get("measurement_margin_ms") == "max(5.0, max(run_level_upper_tail_ms)-min(run_level_upper_tail_ms))" and sequence.get("random_seed") == 20260821 and sequence.get("original_randomized_run_ids") == ["ob-netdelay-500m-normal-15u-001", "ob-netdelay-500m-normal-15u-002", "ob-netdelay-500m-normal-10u-001", "ob-netdelay-500m-normal-10u-002", "ob-netdelay-500m-normal-15u-003", "ob-netdelay-500m-normal-10u-003"] and sequence.get("invalid_run_ids") == ["ob-netdelay-500m-normal-15u-001", "ob-netdelay-500m-normal-15u-004", "ob-netdelay-500m-normal-15u-005"] and sequence.get("effective_collection_run_ids") == ["ob-netdelay-500m-normal-15u-006", "ob-netdelay-500m-normal-15u-002", "ob-netdelay-500m-normal-10u-001", "ob-netdelay-500m-normal-10u-002", "ob-netdelay-500m-normal-15u-003", "ob-netdelay-500m-normal-10u-003"])
    snapshot = profile.get("current_eligibility_snapshot", {})
    check("blocked_snapshot", snapshot.get("eligible_500m_normal_run_count_10u") == 1 and snapshot.get("eligible_500m_normal_run_count_15u") == 2 and snapshot.get("headroom_calculation_status") == "blocked_missing_new_500m_normals")
    check("not_authorized", profile.get("execution_authorized") is False and profile.get("fault_or_normal_run_started_by_this_profile") is False)
    return failures


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    args = parser.parse_args()
    failures = verify(args.root.resolve())
    print(json.dumps({"verification_passed": not failures, "checks": 12, "failures": failures}, sort_keys=True))
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
