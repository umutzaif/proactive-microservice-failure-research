#!/usr/bin/env python3
"""Produce decision support for O-010 without selecting a workload."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def high_increases(report: str) -> list[float]:
    values = re.findall(
        r"\| `ob-cpu-high-\d+` \| [0-9.]+ \| [0-9.]+ \| ([0-9.]+) \|",
        report,
    )
    if len(values) != 3:
        raise ValueError("expected exactly three high-run increases")
    return [float(value) for value in values]


def analyze(capacity: list[dict], high_profile: dict, high_report: str) -> dict:
    by_users = {int(item["users"]): item for item in capacity}
    if set(by_users) != {10, 15, 20}:
        raise ValueError("capacity evidence must contain users 10, 15 and 20")

    cpu_limit = float(high_profile["target"]["cpu_limit_millicores"])
    requested = float(high_profile["injector"]["target_additional_cpu_millicores"])
    reserve = 25.0
    reference_rate = float(by_users[10]["frontend_user_server_span_rate_per_second"])
    target_rate = reference_rate * 1.30
    rate_10 = reference_rate
    rate_15 = float(by_users[15]["frontend_user_server_span_rate_per_second"])
    fraction = (target_rate - rate_10) / (rate_15 - rate_10)
    interpolated_users = 10.0 + 5.0 * fraction
    cpu_10 = float(by_users[10]["recommendationservice_cpu_mean_millicores"])
    cpu_15 = float(by_users[15]["recommendationservice_cpu_mean_millicores"])
    interpolated_cpu = cpu_10 + fraction * (cpu_15 - cpu_10)

    increases = high_increases(high_report)
    observed_mean_increase = sum(increases) / len(increases)
    candidates = {}
    for users in (15, 20):
        normal_cpu = float(by_users[users]["recommendationservice_cpu_mean_millicores"])
        candidates[str(users)] = {
            "normal_mean_cpu_millicores": normal_cpu,
            "max_high_request_with_25m_reserve": cpu_limit - normal_cpu - reserve,
            "minimum_limit_for_150m_request_and_25m_reserve": normal_cpu + requested + reserve,
            "additive_estimated_steady_with_observed_high_mean_increase": normal_cpu
            + observed_mean_increase,
            "additive_estimated_remaining_to_200m": cpu_limit
            - normal_cpu
            - observed_mean_increase,
        }

    return {
        "analysis_id": "P1-WORKLOAD-RESOURCE-BUDGET-001",
        "decision_support_only": True,
        "dataset_inclusion": False,
        "inputs": {
            "cpu_limit_millicores": cpu_limit,
            "high_requested_millicores": requested,
            "nominal_reserve_millicores": reserve,
            "observed_high_increase_millicores": increases,
            "observed_high_mean_increase_millicores": observed_mean_increase,
        },
        "interpolation_screen": {
            "method": "linear interpolation between observed 10-user and 15-user points",
            "users_at_1_30x_request_rate": interpolated_users,
            "estimated_mean_cpu_at_that_point_millicores": interpolated_cpu,
            "passes_25m_cpu_gate": interpolated_cpu <= 25.0,
            "is_experimental_evidence": False,
        },
        "candidates": candidates,
        "limitations": [
            "Interpolation is a screening estimate, not an observed workload result.",
            "Adding normal CPU and observed fault increase assumes additive effects.",
            "No threshold, fault severity, resource limit or workload is selected here.",
        ],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capacity", type=Path, action="append", required=True)
    parser.add_argument("--high-profile", type=Path, required=True)
    parser.add_argument("--high-report", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    result = analyze(
        [read_json(path) for path in args.capacity],
        read_json(args.high_profile),
        args.high_report.read_text(encoding="utf-8"),
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
