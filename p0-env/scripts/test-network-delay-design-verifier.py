#!/usr/bin/env python3
"""Positive and tamper-negative fixtures for the P2 design verifier."""

from __future__ import annotations

import importlib.util
import json
import shutil
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("design_verifier", Path(__file__).with_name("verify-network-delay-design.py"))
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(MODULE)


def main() -> int:
    positive = MODULE.verify(ROOT)
    assert positive["verification_passed"]
    print("network_delay_design_positive_fixture=passed")

    with tempfile.TemporaryDirectory() as temp:
        fixture = Path(temp)
        for relative in (
            "p0-env/artifacts/P2-NETWORK-DELAY-DESIGN-001",
            "p0-env/config/faults",
            "p0-env/config/slo",
            "p0-env/config/network-delay-design",
        ):
            shutil.copytree(ROOT / relative, fixture / relative)
        profile_path = fixture / "p0-env/config/faults/network-delay-recommendation-productcatalog-v1.json"
        profile = json.loads(profile_path.read_text(encoding="utf-8"))
        profile["scientific_run_authorized"] = True
        profile["scientific_run_id"] = "forbidden-reused-id"
        profile_path.write_text(json.dumps(profile, indent=2) + "\n", encoding="utf-8")
        negative = MODULE.verify(fixture)
        assert not negative["verification_passed"]
        failed = {item["name"] for item in negative["checks"] if not item["passed"]}
        assert "scientific_run_not_authorized" in failed
        print("network_delay_design_unauthorized_run_negative_fixture=passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
