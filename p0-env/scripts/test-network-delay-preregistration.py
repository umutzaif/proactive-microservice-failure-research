#!/usr/bin/env python3
"""Positive and mutation-negative fixtures for the first-run preregistration."""

import importlib.util
import json
import shutil
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("prereg", Path(__file__).with_name("verify-network-delay-preregistration.py"))
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(MODULE)


def main() -> int:
    assert MODULE.verify(ROOT)["verification_passed"]
    with tempfile.TemporaryDirectory() as directory:
        clone = Path(directory) / "repo"
        for relative in ("p0-env/config", "p0-env/artifacts/P2-NETWORK-DELAY-PROXY-LIVE-001", "p0-env/artifacts/P2-NETWORK-DELAY-REPEATABILITY-001"):
            shutil.copytree(ROOT / relative, clone / relative)
        path = clone / "p0-env/config/faults/network-delay-recommendation-productcatalog-15u-v1.json"
        profile = json.loads(path.read_text(encoding="utf-8"))
        profile["injector"]["ramp_latency_ms"][-1] = 749
        path.write_text(json.dumps(profile), encoding="utf-8")
        assert not MODULE.verify(clone)["verification_passed"]
    print("network_delay_preregistration_positive_fixture=passed")
    print("network_delay_preregistration_mutated_ramp_negative_fixture=passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
