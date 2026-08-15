#!/usr/bin/env python3
"""Tamper-negative fixture for the live proxy final receipt verifier."""

import importlib.util
import json
import tempfile
from pathlib import Path


SCRIPT = Path(__file__).with_name("verify-network-delay-proxy-live-final.py")
SPEC = importlib.util.spec_from_file_location("final_verify", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(MODULE)


def main() -> int:
    with tempfile.TemporaryDirectory() as temp:
        root = Path(temp)
        evidence = root / "evidence.txt"
        evidence.write_text("sealed\n", encoding="utf-8")
        import hashlib
        receipt = {"run_id": "ob-network-proxy-live-001", "scientific_fault_started": False, "file_count": 1, "files": [{"path": "evidence.txt", "size_bytes": evidence.stat().st_size, "sha256": hashlib.sha256(evidence.read_bytes()).hexdigest()}]}
        receipt_path = root / "receipt.json"
        receipt_path.write_text(json.dumps(receipt), encoding="utf-8")
        assert MODULE.verify(root, receipt_path)["verification_passed"]
        evidence.write_text("tampered\n", encoding="utf-8")
        assert not MODULE.verify(root, receipt_path)["verification_passed"]
    print("network_delay_proxy_live_final_tamper_negative_fixture=passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
