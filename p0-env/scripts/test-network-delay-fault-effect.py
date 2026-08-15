#!/usr/bin/env python3
"""Focused fixtures for network-delay phase coverage and effect gates."""

import importlib.util
from pathlib import Path


SPEC = importlib.util.spec_from_file_location("effect", Path(__file__).with_name("analyze-network-delay-fault-effect.py"))
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(MODULE)


def main() -> int:
    baseline_values = [(float(i), 4.0) for i in range(300)]
    steady_values = [(300.0 + i, 754.0) for i in range(300)]
    baseline = MODULE.phase(baseline_values, 0, 300, 5)
    steady = MODULE.phase(steady_values, 300, 600, 5)
    assert baseline["nonempty_window_count"] == 60 and steady["nonempty_window_count"] == 60
    assert steady["median_latency_ms"] - baseline["median_latency_ms"] == 750
    print("network_delay_fault_effect_positive_fixture=passed")
    sparse = MODULE.phase([(float(i * 10), 754.0) for i in range(30)], 0, 300, 5)
    assert sparse["nonempty_window_count"] < 48
    print("network_delay_fault_effect_coverage_negative_fixture=passed")
    weak = MODULE.phase([(float(i), 400.0) for i in range(300)], 0, 300, 5)
    assert weak["median_latency_ms"] - baseline["median_latency_ms"] < 500
    print("network_delay_fault_effect_magnitude_negative_fixture=passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
