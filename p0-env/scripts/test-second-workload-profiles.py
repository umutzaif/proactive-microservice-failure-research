#!/usr/bin/env python3
"""Verify that 15-user profiles change context, not fault physics."""

import copy
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WORKLOAD = ROOT / "p0-env/config/workloads/ob-second-15u-1r-v1.json"
PAIRS = (
    ("cpu-recommendation-low-v4.json", "cpu-recommendation-low-15u-v1.json", 50, 25),
    ("cpu-recommendation-medium-v1.json", "cpu-recommendation-medium-15u-v1.json", 100, 50),
    ("cpu-recommendation-high-v1.json", "cpu-recommendation-high-15u-v1.json", 150, 75),
)
ALLOWED = {"profile_id", "workload_profile_id", "source_profile_id", "allowed_difference_from_source", "approval_recorded_utc", "limitations"}


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


workload = load(WORKLOAD)
assert workload["profile_id"] == "ob-second-15u-1r-v1"
assert workload["loadgenerator"]["users"] == 15
assert workload["loadgenerator"]["spawn_rate_per_second"] == 1
assert workload["loadgenerator"]["random_seed"] == 1
assert workload["phases"] == {"warmup_seconds": 300, "normal_baseline_seconds": 300}
assert workload["selection_provenance"]["prospective_normal_mean_cpu_max_millicores"] == 40

for old_name, new_name, demand, minimum in PAIRS:
    old = load(ROOT / "p0-env/config/faults" / old_name)
    new = load(ROOT / "p0-env/config/faults" / new_name)
    assert new["source_profile_id"] == old["profile_id"]
    assert new["workload_profile_id"] == workload["profile_id"]
    assert new["injector"]["target_additional_cpu_millicores"] == demand
    assert new["physical_effect_verification"]["minimum_steady_minus_baseline_mean_millicores"] == minimum
    old_compare = copy.deepcopy(old)
    new_compare = copy.deepcopy(new)
    for key in ALLOWED:
        old_compare.pop(key, None)
        new_compare.pop(key, None)
    assert old_compare == new_compare, f"fault physics changed: {new_name}"
    print(f"second_workload_fault_profile=passed profile={new['profile_id']}")

print("second_workload_profile=passed profile=ob-second-15u-1r-v1")
