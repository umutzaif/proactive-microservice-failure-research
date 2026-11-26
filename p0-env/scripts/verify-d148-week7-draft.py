#!/usr/bin/env python3
"""Fail-closed checks for the D-148 Week 7 manuscript candidate."""

from __future__ import annotations

import json
import hashlib
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WEEK = ROOT / "p0-env" / "artifacts" / "D148-COURSE-PUBLICATION-001" / "week-07"


def fail(message: str) -> None:
    raise SystemExit(f"week7_draft_verification=failed: {message}")


def require(text: str, snippets: list[str], label: str) -> None:
    missing = [snippet for snippet in snippets if snippet not in text]
    if missing:
        fail(f"{label} missing required text: {missing}")


def main() -> None:
    paths = {
        "readme": WEEK / "README.md",
        "manuscript": WEEK / "manuscript-draft.md",
        "supplement": WEEK / "anonymized-supplement.md",
        "references": WEEK / "references.bib",
        "metadata": WEEK / "candidate-metadata.json",
        "manifest": WEEK / "sha256-manifest.json",
    }
    missing = [str(path.relative_to(ROOT)) for path in paths.values() if not path.is_file()]
    if missing:
        fail(f"missing files: {missing}")

    text = {
        name: path.read_text(encoding="utf-8")
        for name, path in paths.items()
        if name not in {"metadata", "manifest"}
    }
    metadata = json.loads(paths["metadata"].read_text(encoding="utf-8"))
    manifest = json.loads(paths["manifest"].read_text(encoding="utf-8"))
    manuscript = text["manuscript"]
    supplement = text["supplement"]
    references = text["references"]

    require(
        manuscript,
        [
            "## Abstract",
            "## 1. Introduction",
            "## 2. Related Work",
            "## 3. Study Design",
            "## 4. Results",
            "## 5. Artifact and Reproducibility Design",
            "## 6. Discussion",
            "## 7. Threats to Validity",
            "## 8. Ethics and Responsible Operation",
            "## 9. Conclusion",
            "## Artifact Availability Statement",
            "RQ1",
            "RQ2",
            "RQ3",
            "W5-C01",
            "W5-C02",
            "W5-C03",
            "35 unique attempts",
            "21 valid runs",
            "14 invalid attempts",
            "0/15",
            "0/21",
            "60 independent positive incidents",
            "60 normal control runs",
            "50.349",
            "99.649",
            "146.941",
            "51.098",
            "93.987",
            "140.435",
            "3.576",
            "4.947",
            "2.254",
            "5.384",
            "0.704",
            "5.312",
        ],
        "manuscript",
    )

    abstract_match = re.search(r"## Abstract\s+(.*?)\s+## CCS Concepts", manuscript, flags=re.S)
    if not abstract_match:
        fail("abstract boundary not found")
    abstract_words = re.findall(r"\b[\w'-]+\b", abstract_match.group(1))
    if not 150 <= len(abstract_words) <= 250:
        fail(f"abstract word count {len(abstract_words)} outside 150..250")

    citation_keys = [
        "zheng2024mulan",
        "zhang2026galr",
        "cornacchia2025promise",
        "yu2026proactive",
        "zhang2025aiops",
    ]
    for key in citation_keys:
        if f"@{key}" not in manuscript:
            fail(f"manuscript does not cite {key}")
        if not re.search(rf"@[a-z]+\{{{re.escape(key)},", references, flags=re.I):
            fail(f"BibTeX entry missing for {key}")

    require(
        references,
        [
            "10.1145/3589334.3645442",
            "10.3390/electronics15010243",
            "10.1145/3725783.3764388",
            "10.3389/fcomp.2026.1783945",
            "10.1145/3746635",
        ],
        "references",
    )

    require(
        supplement,
        [
            "repository history and the export package are not yet anonymized",
            "35 unique attempts",
            "21 valid runs",
            "14 invalid attempts",
            "0/21",
            "verify-d148-week7-draft.py",
            "verify-d148-week6-artifact-package.py --worktree --full-replay",
            "d148_cpu_receipt_replay_not_ready",
            "0ecb6011189c0a47b46019ec1d626ae7043e19e0",
        ],
        "supplement",
    )

    if metadata.get("status") != "not_submission_ready":
        fail("metadata status is not fail-closed")
    if metadata.get("runtime_authorized") is not False or metadata.get("submission_authorized") is not False:
        fail("runtime or submission is authorized in metadata")
    if metadata.get("admissible_contributions") != ["W5-C01", "W5-C02", "W5-C03"]:
        fail("admissible contribution set drifted")
    expected_boundary = {
        "attempts": 35,
        "valid": 21,
        "invalid": 14,
        "valid_fault": 15,
        "manifestations": 0,
        "receipt_pairs_available": 0,
        "receipt_pairs_expected": 21,
    }
    if metadata.get("evidence_boundary") != expected_boundary:
        fail("metadata evidence boundary drifted")

    payloads = manifest.get("payloads")
    if manifest.get("algorithm") != "SHA-256" or manifest.get("payload_count") != 5:
        fail("manifest header drifted")
    if not isinstance(payloads, list) or len(payloads) != 5:
        fail("manifest payload count drifted")
    for payload in payloads:
        payload_path = WEEK / payload["path"]
        if not payload_path.is_file() or payload_path.parent != WEEK:
            fail(f"manifest path invalid: {payload.get('path')}")
        payload_bytes = payload_path.read_bytes()
        if len(payload_bytes) != payload.get("bytes"):
            fail(f"manifest byte count mismatch: {payload['path']}")
        if hashlib.sha256(payload_bytes).hexdigest() != payload.get("sha256"):
            fail(f"manifest SHA-256 mismatch: {payload['path']}")

    combined_candidate = manuscript + "\n" + supplement
    leaks = [
        "Asus-PC",
        "C:\\Users\\",
        "github.com/umutzaif",
        "@gmail.com",
        "@outlook.com",
    ]
    found_leaks = [item for item in leaks if item.lower() in combined_candidate.lower()]
    if found_leaks:
        fail(f"candidate anonymity leak: {found_leaks}")

    overclaims = [
        "we outperform",
        "statistically significant",
        "our trained model",
        "fully reproducible artifact",
        "universal evidence",
    ]
    found_overclaims = [item for item in overclaims if item.lower() in combined_candidate.lower()]
    if found_overclaims:
        fail(f"prohibited overclaim: {found_overclaims}")

    print("week7_draft_verification=passed")
    print(f"abstract_words={len(abstract_words)}")
    print("evidence=35_attempts,21_valid,14_invalid,15_fault,0_manifestations")
    print("receipt_pairs=0_of_21")
    print("contributions=W5-C01,W5-C02,W5-C03")
    print("runtime_authorized=false")
    print("submission_authorized=false")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        fail(str(exc))
