#!/usr/bin/env python3
"""Verify the D-148 Week 10 repository release boundary."""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "p0-env/artifacts/D148-COURSE-PUBLICATION-001"
WEEK9 = BASE / "week-09"
WEEK10 = BASE / "week-10"
PDF = WEEK9 / "output/pdf/d148-manuscript-audience-revised-candidate.pdf"
PPTX = WEEK9 / "output/pptx/d148-defense-presentation-audience-revised-candidate.pptx"
ARCHIVE = WEEK9 / "output/archive/d148-audience-review-package-candidate.zip"
EXPECTED = {
    PDF: "4a84ca83c75e8b82275f76022ad149d50e6e541797ae92b797921ff90e508f1d",
    PPTX: "37981db54b36908146ad6cd6f91dcc07b1df559b16621121d01fd55113972eb0",
    ARCHIVE: "fc6423d470342fdbc49fd05cd37a9f049884872d77e1f891e57a13f889ce6be7",
}


def fail(message: str) -> None:
    raise SystemExit(f"week10_release_verification=failed:{message}")


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, cwd=ROOT, text=True, capture_output=True)


def main() -> int:
    dependency = run([sys.executable, str(ROOT / "p0-env/scripts/verify-d148-week9-audience-package.py")])
    if dependency.returncode:
        fail(f"week9_dependency:{dependency.stdout}{dependency.stderr}")

    metadata_path = WEEK10 / "candidate-metadata.json"
    review_path = WEEK10 / "release-boundary-review.md"
    guide_path = WEEK10 / "desktop-delivery-readme.md"
    manifest_path = WEEK10 / "sha256-manifest.json"
    required = [WEEK10 / "README.md", metadata_path, review_path, guide_path, manifest_path]
    missing = [str(path.relative_to(ROOT)) for path in required if not path.is_file()]
    if missing:
        fail(f"missing_files:{missing}")

    for path, expected in EXPECTED.items():
        actual = hashlib.sha256(path.read_bytes()).hexdigest()
        if actual != expected:
            fail(f"delivery_hash:{path.name}:{actual}")

    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    if metadata.get("status") != "repository_pr_ready_not_submission_ready":
        fail("metadata_status")
    required_false = [
        "runtime_authorized", "receipt_recovery_authorized",
        "external_submission_authorized", "publication_authorized",
        "merge_authorized", "native_powerpoint_open_verified",
        "adviser_acceptance_verified",
    ]
    if metadata.get("repository_delivery_authorized") is not True or any(metadata.get(key) is not False for key in required_false):
        fail("metadata_authority")

    review = review_path.read_text(encoding="utf-8")
    for value in ["0/15 manifestations", "0 of 21", "not_submission_ready", "leave it unmerged"]:
        if value not in review:
            fail(f"review_boundary:{value}")

    tree_check = run(["git", "cat-file", "-e", "HEAD:literatur_degerlendirmesi.md"])
    if tree_check.returncode:
        fail("literature_source_missing_from_head")

    with tempfile.TemporaryDirectory(prefix="d148-week10-") as temporary:
        replay = Path(temporary) / "review.zip"
        built = run([
            sys.executable,
            str(ROOT / "p0-env/scripts/build-d148-week9-review-package.py"),
            "--output", str(replay),
        ])
        if built.returncode:
            fail(f"archive_rebuild:{built.stdout}{built.stderr}")
        if replay.read_bytes() != ARCHIVE.read_bytes():
            fail("archive_rebuild_not_byte_identical")

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("artifact_id") != "D148-WEEK10-RELEASE-BOUNDARY-001" or manifest.get("payload_count") != 4:
        fail("manifest_identity")
    for item in manifest.get("payloads", []):
        path = WEEK10 / item["path"]
        data = path.read_bytes()
        if len(data) != item["bytes"] or hashlib.sha256(data).hexdigest() != item["sha256"]:
            fail(f"manifest_payload:{item['path']}")

    print("week10_release_verification=passed")
    print("repository_delivery=commit_push_pr_authorized")
    print("submission_ready=false")
    print("merge_authorized=false")
    print("runtime_authorized=false")
    print("receipt_pairs=0_of_21;fail_closed")
    print("native_powerpoint_open_verified=false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
