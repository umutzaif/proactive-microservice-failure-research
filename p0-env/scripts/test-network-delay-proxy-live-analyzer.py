#!/usr/bin/env python3
"""Focused negative/positive tests for frozen live-proxy calculations."""

import importlib.util
from pathlib import Path


SCRIPT = Path(__file__).with_name("analyze-network-delay-proxy-live.py")
SPEC = importlib.util.spec_from_file_location("live_proxy", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(MODULE)


def main() -> int:
    assert MODULE.percentile([1, 2, 3, 4], 0.95) == 4
    assert MODULE.percentile([], 0.95) is None
    base_median, acceptable_proxy, rejected_proxy = 2.0, 7.0, 7.001
    assert acceptable_proxy - base_median <= MODULE.MAX_MEDIAN_OVERHEAD_MS
    assert rejected_proxy - base_median > MODULE.MAX_MEDIAN_OVERHEAD_MS
    slo = {"latency": {"threshold_ms": 100, "consecutive_violating_windows": 3}, "error": {"threshold": 0, "consecutive_violating_windows": 3}}
    edge = [(float(i), 2.0) for i in range(300)]
    users = [(float(i), 50.0, True, False) for i in range(300)]
    result = MODULE.phase_summary(edge, users, 0, 300, slo)
    assert result["edge_nonempty_window_count"] == 60
    assert result["failure_manifestation"] is False
    print("network_delay_proxy_live_calculation_positive_fixture=passed")
    users_bad = [(float(i), 150.0, True, False) for i in range(300)]
    bad = MODULE.phase_summary(edge, users_bad, 0, 300, slo)
    assert bad["failure_manifestation"] is True
    print("network_delay_proxy_live_manifestation_negative_fixture=passed")
    print("network_delay_proxy_live_overhead_negative_fixture=passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
