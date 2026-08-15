#!/usr/bin/env python3
"""Offline verifier for a finalized invalid/incomplete run receipt."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--run-id", required=True)
    args = parser.parse_args()
    root = args.root.resolve()
    run_id = args.run_id
    final = root / "p0-env/artifacts/finalized-invalid" / run_id
    receipt_path = final / "receipt.json"
    manifest_path = final / "sha256-manifest.json"
    receipt = json.loads(receipt_path.read_text(encoding="utf-8-sig"))
    manifest = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
    checks = []

    def check(name: str, passed: bool) -> None:
        checks.append({"name": name, "passed": bool(passed)})

    check("identity", receipt.get("run_id") == run_id == manifest.get("run_id"))
    check("invalid_claim", receipt.get("status") == "finalized-invalid" and receipt.get("valid_for_modeling") is False and receipt.get("scientific_valid") is False)
    check("receipt_hash", manifest["files"] == [{"path": "receipt.json", "sha256": digest(receipt_path)}])
    check("readonly", not os.access(receipt_path, os.W_OK) and not os.access(manifest_path, os.W_OK))
    source_map = {
        "raw_logs": root / "p0-env/artifacts/runs" / run_id / "sha256-manifest.json",
        "enriched_logs": root / "p0-env/artifacts/derived" / run_id / "sha256-manifest.json",
        "telemetry": root / "p0-env/artifacts/telemetry" / run_id / "sha256-manifest.json",
        "assessment": root / "p0-env/artifacts/P2-NETWORK-DELAY-001" / run_id / "invalid-assessment.json",
    }
    evidence_root = root / "p0-env/artifacts/P2-NETWORK-DELAY-001" / run_id
    for name in ("host-before.json", "host-after.json", "run-error.json", "ramp-evidence.json", "emergency-cleanup-evidence.json", "emergency-capture.json", "rollback-verification.json", "target-pod-stability.json"):
        source_map[f"evidence/{name}"] = evidence_root / name
    check("source_set", set(receipt["source_sha256"]) == set(source_map))
    check("source_hashes", all(path.is_file() and receipt["source_sha256"].get(name) == digest(path) for name, path in source_map.items()))
    passed = all(item["passed"] for item in checks)
    print(json.dumps({"verification_passed": passed, "run_id": run_id, "checks": checks}, sort_keys=True))
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
