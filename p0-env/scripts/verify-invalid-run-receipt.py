#!/usr/bin/env python3
"""Offline verifier for a finalized invalid/incomplete run receipt."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path


def canonical_json_digest(path: Path) -> str:
    value = json.loads(path.read_text(encoding="utf-8-sig"))
    payload = json.dumps(value, ensure_ascii=False, separators=(",", ":"), sort_keys=True)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def byte_digest(path: Path) -> str:
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
    portable_v2 = receipt.get("schema_version") == 2
    if portable_v2:
        check("portable_hash_contract", receipt.get("source_hash_mode") == "canonical-json-v1" and manifest.get("hash_mode") == "canonical-json-v1")
        check("receipt_hash", manifest["files"] == [{"path": "receipt.json", "sha256": canonical_json_digest(receipt_path)}])
        check("overwrite_policy", receipt.get("overwrite_policy") == "deny")
        source_digest = canonical_json_digest
    else:
        check("legacy_schema", receipt.get("schema_version") == 1)
        check("receipt_hash", manifest["files"] == [{"path": "receipt.json", "sha256": byte_digest(receipt_path)}])
        check("readonly", not os.access(receipt_path, os.W_OK) and not os.access(manifest_path, os.W_OK))
        source_digest = byte_digest
    source_map = {
        "raw_logs": root / "p0-env/artifacts/runs" / run_id / "sha256-manifest.json",
        "enriched_logs": root / "p0-env/artifacts/derived" / run_id / "sha256-manifest.json",
        "telemetry": root / "p0-env/artifacts/telemetry" / run_id / "sha256-manifest.json",
        "assessment": root / "p0-env/artifacts/P2-NETWORK-DELAY-001" / run_id / "invalid-assessment.json",
    }
    evidence_root = root / "p0-env/artifacts/P2-NETWORK-DELAY-001" / run_id
    for name in ("host-before.json", "host-after.json", "run-error.json", "ramp-evidence.json", "emergency-cleanup-evidence.json", "cleanup-evidence.json", "emergency-capture.json", "rollback-verification.json", "target-pod-stability.json", "injector-evidence.json", "manifestation-evidence.json", "run-assessment.json", "finalization-error-evidence.json"):
        path = evidence_root / name
        if path.is_file():
            source_map[f"evidence/{name}"] = path
    scientific_metadata = root / "p0-env/artifacts/scientific-run-metadata" / run_id / "scientific-run-metadata.json"
    if scientific_metadata.is_file():
        source_map["scientific_metadata"] = scientific_metadata
    source_map = {name: path for name, path in source_map.items() if name in receipt["source_sha256"]}
    check("source_set", set(receipt["source_sha256"]) == set(source_map))
    check("source_hashes", all(path.is_file() and receipt["source_sha256"].get(name) == source_digest(path) for name, path in source_map.items()))
    passed = all(item["passed"] for item in checks)
    print(json.dumps({"verification_passed": passed, "run_id": run_id, "checks": checks}, sort_keys=True))
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
