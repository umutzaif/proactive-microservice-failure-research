#!/usr/bin/env python3
"""Dependency-free negative and positive tests for frozen-SLO streak semantics."""

from __future__ import annotations

import importlib.util
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("verify-frozen-slo-on-normal-baselines.py")
SPEC = importlib.util.spec_from_file_location("frozen_slo_verifier", MODULE_PATH)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def windows(values: list[float | None]) -> list[dict[str, float | int | None]]:
    return [
        {"window_index": index, "p95_latency_ms": value}
        for index, value in enumerate(values)
    ]


def main() -> int:
    threshold = 345.992
    required = 3

    two_only = MODULE.evaluate(windows([400.0, 400.0, 100.0]), "p95_latency_ms", threshold, required)
    assert two_only["manifestation_detected"] is False
    assert two_only["maximum_consecutive_violations"] == 2

    three = MODULE.evaluate(windows([400.0, 400.0, 400.0]), "p95_latency_ms", threshold, required)
    assert three["manifestation_detected"] is True
    assert three["manifestation_completion_window_indices"] == [2]

    empty_breaks = MODULE.evaluate(windows([400.0, 400.0, None, 400.0]), "p95_latency_ms", threshold, required)
    assert empty_breaks["manifestation_detected"] is False
    assert empty_breaks["empty_window_indices"] == [2]
    assert empty_breaks["maximum_consecutive_violations"] == 2

    equality_does_not_violate = MODULE.evaluate(
        windows([threshold, threshold, threshold]), "p95_latency_ms", threshold, required
    )
    assert equality_does_not_violate["manifestation_detected"] is False

    print("frozen_slo_verifier_tests=passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
