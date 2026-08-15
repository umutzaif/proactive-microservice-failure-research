#!/usr/bin/env python3
"""Deterministic fixtures for toxic ramp and cleanup contracts."""

import importlib.util
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("toxic_manager", Path(__file__).with_name("manage-network-delay-toxic.py"))
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(MODULE)
PROFILE = json.loads((ROOT / "p0-env/config/faults/network-delay-recommendation-productcatalog-15u-v1.json").read_text())


class Fake:
    def __init__(self):
        self.now = 0.0
        self.toxics = []
        self.paths = []

    def clock(self):
        return self.now

    def sleep(self, seconds):
        self.now += seconds

    def request(self, base, method, path, payload=None):
        self.paths.append((method, path))
        if method == "GET":
            return {"name": "recommendation-to-productcatalog", "listen": "127.0.0.1:3551", "upstream": "productcatalogservice:3550", "enabled": True, "toxics": list(self.toxics)}
        if path == "/reset":
            self.toxics = []
            return None
        toxic = dict(payload)
        self.toxics = [toxic]
        return toxic


def main() -> int:
    fake = Fake()
    result = MODULE.ramp(PROFILE, "http://fake", fake.request, fake.clock, fake.sleep)
    assert len(result["events"]) == 13
    assert result["events"][-1]["target_latency_ms"] == 750
    assert result["ramp_elapsed_monotonic_seconds"] >= 120
    assert ("POST", "/proxies/recommendation-to-productcatalog/toxics") in fake.paths
    assert ("POST", "/proxies/recommendation-to-productcatalog/toxics/network-delay-ramp") in fake.paths
    print("network_delay_toxic_ramp_positive_fixture=passed")
    clean = MODULE.cleanup(PROFILE, "http://fake", fake.request)
    assert clean["cleanup_verified"] and clean["after"]["toxics"] == []
    print("network_delay_toxic_cleanup_positive_fixture=passed")
    fake_bad = Fake()
    fake_bad.toxics = [{"name": "residual"}]
    try:
        MODULE.ramp(PROFILE, "http://fake", fake_bad.request, fake_bad.clock, fake_bad.sleep)
    except ValueError as error:
        assert "residual_toxics" in str(error)
    else:
        raise AssertionError("residual toxic was not rejected")
    print("network_delay_toxic_residual_negative_fixture=passed")
    bad_profile = json.loads(json.dumps(PROFILE))
    bad_profile["injector"]["ramp_latency_ms"][-1] = 751
    try:
        MODULE.validate_profile(bad_profile)
    except ValueError as error:
        assert "ramp_schedule_mismatch" in str(error)
    else:
        raise AssertionError("mutated ramp was not rejected")
    print("network_delay_toxic_mutated_schedule_negative_fixture=passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
