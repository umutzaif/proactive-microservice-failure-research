#!/usr/bin/env python3
"""Exercise custom evidence-root finalization and offline verification."""

import json
import subprocess
import sys
import tempfile
from pathlib import Path


def write_json(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value) + "\n", encoding="utf-8")


def main() -> int:
    scripts = Path(__file__).resolve().parent
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        run_id = "generic-invalid-fixture"
        evidence_relative = f"p0-env/artifacts/custom/{run_id}"
        evidence = root / evidence_relative
        assessment = evidence / "invalid-assessment.json"
        write_json(root / f"p0-env/artifacts/runs/{run_id}/sha256-manifest.json", {"kind": "raw"})
        write_json(root / f"p0-env/artifacts/derived/{run_id}/sha256-manifest.json", {"kind": "derived"})
        write_json(root / f"p0-env/artifacts/telemetry/{run_id}/sha256-manifest.json", {"kind": "telemetry"})
        write_json(evidence / "run-error.json", {"error": "fixture"})
        write_json(evidence / "rollback-verification.json", {"passed": True})
        write_json(assessment, {"run_id": run_id, "valid_run": False, "invalid_reason": "fixture"})

        finalized = subprocess.run(
            [sys.executable, str(scripts / "finalize-invalid-run-artifacts.py"), "--root", str(root),
             "--run-id", run_id, "--assessment", str(assessment),
             "--evidence-root-relative", evidence_relative],
            check=True, capture_output=True, text=True,
        )
        assert '"source_count": 6' in finalized.stdout
        verified = subprocess.run(
            [sys.executable, str(scripts / "verify-invalid-run-receipt.py"), "--root", str(root), "--run-id", run_id],
            check=True, capture_output=True, text=True,
        )
        assert '"verification_passed": true' in verified.stdout
        receipt = json.loads((root / f"p0-env/artifacts/finalized-invalid/{run_id}/receipt.json").read_text())
        assert receipt["evidence_root_relative"] == evidence_relative
        assert "evidence/run-error.json" in receipt["source_sha256"]
        assert "evidence/rollback-verification.json" in receipt["source_sha256"]
    print("invalid_receipt_generic_root=passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
