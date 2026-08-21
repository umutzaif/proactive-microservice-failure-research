#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def verify(root: Path) -> list[str]:
    profile = json.loads((root / "p0-env/config/controls/network-delay-no-toxic-control-15u-v1.json").read_text(encoding="utf-8-sig"))
    plan = json.loads((root / "p0-env/artifacts/P2-NETWORK-DELAY-REPEATABILITY-001/randomization-plan.json").read_text(encoding="utf-8-sig"))
    failures = []
    def check(name, condition):
        if not condition:
            failures.append(name)
    check("identity", profile.get("scientific_run_id") == "ob-netdelay-15u-control-001")
    check("pair", profile.get("paired_fault_run_id") == "ob-netdelay-15u-repeat-001")
    first = plan["blocks"][0]
    check("randomized_slot", first["sequence"] == "fault-control" and first["runs"][1]["run_id"] == profile["scientific_run_id"])
    check("workload", profile.get("workload") == {"users": 15, "spawn_rate_per_second": 1, "random_seed": 1})
    check("resources", profile.get("resources") == {"server_cpu_limit": "500m", "server_cpu_request": "100m", "proxy_cpu_limit": "100m"})
    check("lifecycle", profile.get("lifecycle_seconds") == {"warmup": 300, "normal_baseline": 300, "matched_ramp_interval": 120, "matched_steady_interval": 300, "cooldown": 300})
    treatment = profile.get("treatment_contract", {})
    check("no_toxic", treatment.get("toxic_creation_allowed") is False and treatment.get("scientific_fault_started") is False and treatment.get("toxics_must_be_empty_at_pre_interval_mid_interval_post_interval_and_cleanup") is True)
    measurement = profile.get("measurement_contract", {})
    check("coverage", measurement.get("minimum_baseline_and_matched_steady_nonempty_windows") == 48)
    check("no_posthoc_latency_threshold", measurement.get("latency_difference_is_descriptive_without_pass_threshold") is True)
    check("null_manifestation", measurement.get("failure_manifestation_must_be_null_for_valid_control") is True)
    check("not_authorized", profile.get("execution_authorized_in_this_pr") is False and profile.get("profile_status") == "superseded_not_executable" and "must not be executed" in profile.get("execution_authorization_policy", ""))
    return failures


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    args = parser.parse_args()
    failures = verify(args.root.resolve())
    print(json.dumps({"verification_passed": not failures, "checks": 11, "failures": failures}, sort_keys=True))
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
