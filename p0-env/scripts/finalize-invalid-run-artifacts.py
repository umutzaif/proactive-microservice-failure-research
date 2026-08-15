#!/usr/bin/env python3
"""Seal a non-modeling receipt for a preserved invalid/incomplete run."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from datetime import datetime, timezone
from pathlib import Path


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write(path: Path, value: dict) -> None:
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--assessment", type=Path, required=True)
    args = parser.parse_args()
    root = args.root.resolve()
    run_id = args.run_id
    final = root / "p0-env/artifacts/finalized-invalid" / run_id
    if final.exists():
        raise SystemExit(f"immutable_invalid_receipt_exists:{final}")
    sources = {
        "raw_logs": root / "p0-env/artifacts/runs" / run_id / "sha256-manifest.json",
        "enriched_logs": root / "p0-env/artifacts/derived" / run_id / "sha256-manifest.json",
        "telemetry": root / "p0-env/artifacts/telemetry" / run_id / "sha256-manifest.json",
        "assessment": args.assessment.resolve(),
    }
    evidence_root = root / "p0-env/artifacts/P2-NETWORK-DELAY-001" / run_id
    evidence_names = (
        "host-before.json", "host-after.json", "run-error.json", "ramp-evidence.json",
        "emergency-cleanup-evidence.json", "emergency-capture.json",
        "rollback-verification.json", "target-pod-stability.json",
    )
    for name in evidence_names:
        sources[f"evidence/{name}"] = evidence_root / name
    missing = [str(path) for path in sources.values() if not path.is_file()]
    if missing:
        raise SystemExit("required_invalid_evidence_missing:" + "|".join(missing))
    assessment = json.loads(args.assessment.read_text(encoding="utf-8-sig"))
    if assessment.get("run_id") != run_id or assessment.get("valid_run") is not False:
        raise SystemExit("invalid_assessment_contract_failed")
    final.mkdir(parents=True)
    receipt = {
        "schema_version": 1,
        "receipt_kind": "invalid-incomplete-run",
        "run_id": run_id,
        "status": "finalized-invalid",
        "valid_for_modeling": False,
        "scientific_valid": False,
        "finalized_utc": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "reason": assessment["invalid_reason"],
        "source_sha256": {name: digest(path) for name, path in sources.items()},
        "overwrite_policy": "deny",
    }
    write(final / "receipt.json", receipt)
    manifest = {"algorithm": "SHA-256", "run_id": run_id, "files": [{"path": "receipt.json", "sha256": digest(final / "receipt.json")} ]}
    write(final / "sha256-manifest.json", manifest)
    for path in final.iterdir():
        os.chmod(path, 0o444)
    print(json.dumps({"invalid_receipt_finalized": True, "run_id": run_id, "source_count": len(sources)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
