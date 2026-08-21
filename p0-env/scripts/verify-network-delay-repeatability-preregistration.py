#!/usr/bin/env python3
import argparse
import json
import random
from pathlib import Path


EXPECTED_LABELS = ["FC-2", "FC-1", "CF-2", "CF-1"]
EXPECTED_RUNS = [
    (1, "fault-control", "ob-netdelay-15u-repeat-001", "ob-netdelay-15u-control-001"),
    (2, "fault-control", "ob-netdelay-15u-repeat-002", "ob-netdelay-15u-control-002"),
    (3, "control-fault", "ob-netdelay-15u-control-003", "ob-netdelay-15u-repeat-003"),
    (4, "control-fault", "ob-netdelay-15u-control-004", "ob-netdelay-15u-repeat-004"),
]


def verify(plan_path: Path) -> list[str]:
    plan = json.loads(plan_path.read_text(encoding="utf-8"))
    failures: list[str] = []

    def check(name: str, condition: bool) -> None:
        if not condition:
            failures.append(name)

    check("plan_id", plan.get("plan_id") == "P2-NETWORK-DELAY-REPEATABILITY-001")
    check("decision_id", plan.get("decision_id") == "D-058")
    check("pilot_separate", plan.get("pilot_run_id") == "ob-netdelay-15u-008")
    check("seed", plan.get("random_seed") == 20260821)

    labels = ["CF-1", "CF-2", "FC-1", "FC-2"]
    random.Random(plan["random_seed"]).shuffle(labels)
    check("randomization_replay", labels == EXPECTED_LABELS == plan.get("randomized_labels"))

    blocks = plan.get("blocks", [])
    check("block_count", len(blocks) == 4)
    actual_runs = []
    all_ids = []
    for block in blocks:
        runs = block.get("runs", [])
        if len(runs) != 2:
            failures.append(f"block_{block.get('block')}_run_count")
            continue
        actual_runs.append(
            (block.get("block"), block.get("sequence"), runs[0].get("run_id"), runs[1].get("run_id"))
        )
        all_ids.extend(run.get("run_id") for run in runs)
    check("frozen_run_order", actual_runs == EXPECTED_RUNS)
    check("unique_run_ids", len(all_ids) == len(set(all_ids)) == 8)

    fault = plan.get("frozen_fault_contract", {})
    check("workload", (fault.get("users"), fault.get("spawn_rate"), fault.get("workload_seed")) == (15, 1, 1))
    check("resources", (fault.get("server_cpu_limit"), fault.get("proxy_cpu_limit")) == ("500m", "100m"))
    check("lifecycle", fault.get("lifecycle_seconds") == "300/300/120/300/300")
    check("effect", fault.get("minimum_physical_effect_ms") == 500)

    control = plan.get("control_contract", {})
    check("control_no_toxic", control.get("toxic_created") is False)
    check("control_matched", control.get("same_overlay_workload_resources_and_lifecycle") is True)
    check("runtime_approval", "separate per-slot runtime approval" in plan.get("execution_gate", ""))
    return failures


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--plan", type=Path, required=True)
    args = parser.parse_args()
    failures = verify(args.plan.resolve())
    print(json.dumps({"verification_passed": not failures, "failures": failures}, sort_keys=True))
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
