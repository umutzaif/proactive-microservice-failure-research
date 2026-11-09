#!/usr/bin/env python3
"""Verify the bounded D-148 Week 4 manuscript against Week 3 evidence."""

from __future__ import annotations

import csv
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "p0-env" / "artifacts" / "D148-COURSE-PUBLICATION-001"
WEEK3 = BASE / "week-03"
WEEK4 = BASE / "week-04"
MANUSCRIPT = WEEK4 / "manuscript-sections.md"
TRACE = WEEK4 / "claim-traceability.md"
METADATA = WEEK4 / "candidate-metadata.json"
EXPECTED_WEEK3_MANIFEST_SHA256 = (
    "cad89a01886168ce1da9fe411eeddfe8e80ec2da2e59ed9ce76b4e464e3f32d1"
)


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def read_csv(path: Path) -> list[dict[str, str]]:
    if not path.is_file():
        fail(f"missing input: {path.relative_to(ROOT)}")
    with path.open("r", encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def require_text(text: str, label: str, needles: list[str]) -> None:
    lowered = " ".join(text.lower().split())
    for needle in needles:
        normalized_needle = " ".join(needle.lower().split())
        if normalized_needle not in lowered:
            fail(f"{label} is missing required text: {needle!r}")


def main() -> None:
    for path in (MANUSCRIPT, TRACE, METADATA):
        if not path.is_file():
            fail(f"missing Week 4 file: {path.relative_to(ROOT)}")

    manuscript = MANUSCRIPT.read_text(encoding="utf-8")
    trace = TRACE.read_text(encoding="utf-8")
    metadata = json.loads(METADATA.read_text(encoding="utf-8"))

    require_text(
        manuscript,
        "manuscript",
        [
            "## 3. Methods",
            "## 4. Results",
            "## 5. Threats to Validity",
            "same-host",
            "35 unique attempts",
            "21 valid",
            "14 invalid",
            "six normal controls",
            "15 fault runs",
            "0/15",
            "zero lead-time evidence",
            "sample standard deviation (SD)",
            "Sample SD is not a confidence interval",
            "zero of the 21 expected final-receipt/SHA-manifest pairs",
            "No model was trained",
            "60 independent positive incidents plus 60 normal control runs",
            "D-147 stopped",
            "3/6 accepted normals",
            "not a Kubernetes root-cause finding",
        ],
    )

    threats = re.findall(r"^### 5\.[1-6] ", manuscript, flags=re.MULTILINE)
    if len(threats) != 6:
        fail(f"expected six numbered threats subsections, found {len(threats)}")

    prohibited = [
        "receipt-level replay is reproducible",
        "statistically significant",
        "proves that cpu faults never",
        "production-ready model",
        "submission-ready manuscript",
    ]
    for phrase in prohibited:
        if phrase in manuscript.lower():
            fail(f"prohibited overclaim found: {phrase!r}")

    accounting = {
        row["category"]: int(row["count"])
        for row in read_csv(WEEK3 / "table-01-run-accounting.csv")
    }
    expected_counts = {
        "all_attempts": 35,
        "registry_valid": 21,
        "invalid": 14,
        "valid_normal": 6,
        "valid_fault": 15,
        "positive_manifestation": 0,
    }
    if accounting != expected_counts:
        fail(f"unexpected Week 3 accounting: {accounting}")

    physical = read_csv(WEEK3 / "table-02-physical-effect.csv")
    if len(physical) != 6:
        fail(f"expected six physical-effect cells, found {len(physical)}")
    for row in physical:
        if int(row["positive_manifestations"]) != 0:
            fail(f"positive manifestation in physical-effect cell: {row}")
        for field in ("mean_m", "cv_percent"):
            if row[field] not in manuscript:
                fail(
                    f"manuscript missing {field}={row[field]} for "
                    f"{row['workload']}/{row['severity']}"
                )

    fault_runs = read_csv(WEEK3 / "table-03-valid-fault-runs.csv")
    if len(fault_runs) != 15:
        fail(f"expected 15 valid fault rows, found {len(fault_runs)}")
    if any(row["failure_manifestation"].strip().lower() != "null" for row in fault_runs):
        fail("at least one Week 3 valid fault row is not null-manifestation")

    if metadata.get("artifact_id") != "D148-WEEK4-MANUSCRIPT-SECTIONS-001":
        fail("unexpected artifact_id")
    if metadata.get("status") != "not_submission_ready":
        fail("Week 4 status must remain not_submission_ready")
    if metadata.get("runtime_authorized") is not False:
        fail("runtime_authorized must be false")
    if metadata.get("source_week3_manifest_sha256") != EXPECTED_WEEK3_MANIFEST_SHA256:
        fail("Week 3 source-manifest hash mismatch in metadata")
    receipt = metadata.get("receipt_replay", {})
    if receipt != {"available_pairs": 0, "expected_pairs": 21, "authorized": False}:
        fail(f"unexpected receipt-replay boundary: {receipt}")

    for claim in [f"C148-0{number}" for number in range(1, 9)]:
        if claim not in trace:
            fail(f"traceability table missing {claim}")
    if "**Held.**" not in trace or "C148-05" not in trace:
        fail("C148-05 must remain explicitly held")

    print("week4_manuscript_verification=passed")
    print("accounting=35_attempts,21_valid,14_invalid,6_normal,15_fault")
    print("manifestation=0_of_15_valid_fault_runs")
    print("receipt_pairs=0_of_21;claim_C148-05=held")
    print("runtime_authorized=false")


if __name__ == "__main__":
    main()
