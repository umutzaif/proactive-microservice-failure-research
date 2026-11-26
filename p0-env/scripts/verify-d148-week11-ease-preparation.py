#!/usr/bin/env python3
"""Verify the offline-only D-148 Week 11 EASE preparation package."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[2]
WEEK11 = (
    ROOT
    / "p0-env"
    / "artifacts"
    / "D148-COURSE-PUBLICATION-001"
    / "week-11"
)
PAYLOADS = (
    "README.md",
    "ease-2027-gap-analysis.md",
    "ease-2027-organizer-query-draft.md",
    "candidate-metadata.json",
)


def fail(message: str) -> None:
    raise SystemExit(f"week11_ease_preparation_verification_failed:{message}")


def portable_bytes(path: Path) -> bytes:
    """Return the LF-normalized bytes sealed for declared text payloads."""

    return path.read_bytes().replace(b"\r\n", b"\n")


def require_text(path: Path, tokens: tuple[str, ...]) -> str:
    if not path.is_file():
        fail(f"missing:{path.relative_to(ROOT).as_posix()}")
    text = path.read_text(encoding="utf-8")
    for token in tokens:
        if token not in text:
            fail(f"missing_token:{path.name}:{token}")
    return text


def verify_metadata() -> None:
    path = WEEK11 / "candidate-metadata.json"
    try:
        metadata = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"metadata:{exc}")

    expected = {
        "artifact_id": "D148-WEEK11-EASE-ADAPTATION-PREPARATION-001",
        "status": "preparation_only_not_submission_ready",
        "target_status": "conditional_primary",
        "remote_author_presentation": "unconfirmed",
        "communication_sent": False,
        "submission_ready": False,
        "submission_authorized": False,
        "upload_authorized": False,
        "registration_authorized": False,
        "payment_authorized": False,
        "runtime_authorized": False,
        "receipt_pairs_available": 0,
        "receipt_pairs_expected": 21,
    }
    for key, value in expected.items():
        if metadata.get(key) != value:
            fail(f"metadata_value:{key}")

    counts = metadata.get("scientific_counts", {})
    if counts != {
        "attempts": 35,
        "valid": 21,
        "invalid": 14,
        "valid_fault": 15,
        "manifestations": 0,
    }:
        fail("scientific_counts")

    ease = metadata.get("ease_2027", {})
    ease_expected = {
        "main_text_page_limit": 10,
        "reference_only_page_limit": 2,
        "template": "acmart sigconf review anonymous",
        "review": "double_anonymous",
        "abstract_deadline": "2027-02-22 AoE",
        "paper_deadline": "2027-03-01 AoE",
        "notification": "2027-04-12",
        "camera_ready": "TBA",
        "early_registration": "TBA",
        "author_registration_and_presentation_required": True,
        "acm_apc_may_apply": True,
    }
    if ease != ease_expected:
        fail("ease_2027_contract")


def verify_manifest() -> None:
    path = WEEK11 / "sha256-manifest.json"
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"manifest:{exc}")

    entries = manifest.get("files")
    if not isinstance(entries, list):
        fail("manifest_files")
    by_path = {entry.get("path"): entry for entry in entries}
    if set(by_path) != set(PAYLOADS):
        fail("manifest_membership")

    for name in PAYLOADS:
        payload = portable_bytes(WEEK11 / name)
        entry = by_path[name]
        if entry.get("bytes") != len(payload):
            fail(f"manifest_bytes:{name}")
        if entry.get("sha256") != hashlib.sha256(payload).hexdigest():
            fail(f"manifest_sha256:{name}")


def verify_week10_dependency() -> None:
    verifier = ROOT / "p0-env" / "scripts" / "verify-d148-week10-release.py"
    result = subprocess.run(
        [sys.executable, str(verifier)],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        sys.stdout.write(result.stdout)
        sys.stderr.write(result.stderr)
        fail("week10_dependency")
    if "week10_release_verification=passed" not in result.stdout:
        fail("week10_success_marker")


def main() -> int:
    require_text(
        WEEK11 / "README.md",
        (
            "decision-support package",
            "submission package",
            "communication_sent=false",
            "submission_ready=false",
            "runtime_authorized=false",
        ),
    )
    gap = require_text(
        WEEK11 / "ease-2027-gap-analysis.md",
        (
            "preparation_only_not_submission_ready",
            "\\documentclass[sigconf,review,anonymous]{acmart}",
            "2027-02-22 AoE",
            "2027-03-01 AoE",
            "W11-G01",
            "W11-G10",
            "small or underpowered sample alone is not a suitable",
            "receipt readiness `0/21`",
            "No model, runtime, receipt recovery, upload",
        ),
    )
    query = require_text(
        WEEK11 / "ease-2027-organizer-query-draft.md",
        (
            "# UNSENT Draft",
            "draft_only_communication_sent_false",
            "[Corresponding author name]",
            "[Institution]",
            "has not been sent",
        ),
    )
    if "communication_sent_true" in query:
        fail("communication_state")

    verify_metadata()
    verify_manifest()
    require_text(
        ROOT / "research_decisions.md",
        ("## D-151", "remote author presentation", "0/21"),
    )
    require_text(
        ROOT / "pilot_experiment_plan.md",
        ("Week 11", "EASE 2027 RENE", "not_submission_ready"),
    )
    require_text(
        ROOT / "docs" / "researcher-datasheets" / "01-project-architecture.md",
        ("D-151", "conditional venue choice", "communication_sent=false"),
    )
    verify_week10_dependency()

    print("week11_ease_preparation_verification=passed")
    print("remote_author_presentation=unconfirmed")
    print("communication_sent=false")
    print("submission_ready=false")
    print("receipt_pairs=0_of_21;fail_closed")
    print("runtime_authorized=false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
