#!/usr/bin/env python3
"""Negative fixtures for network-delay metadata identity and duration gates."""

import importlib.util
from pathlib import Path


SPEC = importlib.util.spec_from_file_location("metadata", Path(__file__).with_name("verify-network-delay-scientific-metadata.py"))
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(MODULE)


def main() -> int:
    assert MODULE.seconds("2026-01-01T00:00:00Z", "2026-01-01T00:05:00Z") == 300
    assert MODULE.seconds("2026-01-01T00:00:00Z", "2026-01-01T00:04:59.999Z") < 300
    print("network_delay_metadata_phase_duration_fixture=passed")
    print("network_delay_metadata_identity_contract=ob-netdelay-15u-005")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
