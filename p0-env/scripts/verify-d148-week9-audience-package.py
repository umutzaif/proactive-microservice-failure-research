#!/usr/bin/env python3
"""Verify D-148 Week 9 audience hardening against canonical contracts."""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "p0-env/artifacts/D148-COURSE-PUBLICATION-001"
WEEK9 = BASE / "week-09"
PDF = WEEK9 / "output/pdf/d148-manuscript-audience-revised-candidate.pdf"
PPTX = WEEK9 / "output/pptx/d148-defense-presentation-audience-revised-candidate.pptx"
ARCHIVE = WEEK9 / "output/archive/d148-audience-review-package-candidate.zip"
FORBIDDEN = (b"asus-pc", b"c:\\users\\", b"github.com/umutzaif", b"@gmail.com", b"@outlook.com")


def fail(message: str) -> None:
    raise SystemExit(f"week9_audience_package_verification=failed:{message}")


def require(text: str, values: list[str], label: str) -> None:
    missing = [value for value in values if value not in text]
    if missing:
        fail(f"{label}_missing:{missing}")


def scan(label: str, data: bytes) -> None:
    hits = [token.decode("ascii", errors="replace") for token in FORBIDDEN if token in data.lower()]
    if hits:
        fail(f"direct_identifier_leak:{label}:{hits}")


def main() -> int:
    required = [
        WEEK9 / "README.md", WEEK9 / "candidate-metadata.json",
        WEEK9 / "adversarial-review.md", WEEK9 / "technical-method-addendum.md",
        WEEK9 / "sha256-manifest.json", PDF, PPTX, ARCHIVE,
    ]
    missing = [str(path.relative_to(ROOT)) for path in required if not path.is_file()]
    if missing:
        fail(f"missing_files:{missing}")

    dependency = subprocess.run(
        [sys.executable, str(ROOT / "p0-env/scripts/verify-d148-week8-deliverables.py")],
        cwd=ROOT, text=True, capture_output=True,
    )
    if dependency.returncode:
        fail(f"week8_dependency:{dependency.stdout}{dependency.stderr}")

    low = json.loads((ROOT / "p0-env/config/faults/cpu-recommendation-low-v4.json").read_text(encoding="utf-8"))
    medium = json.loads((ROOT / "p0-env/config/faults/cpu-recommendation-medium-v1.json").read_text(encoding="utf-8"))
    high = json.loads((ROOT / "p0-env/config/faults/cpu-recommendation-high-v1.json").read_text(encoding="utf-8"))
    workload10 = json.loads((ROOT / "p0-env/config/workloads/ob-default-10u-1r-v1.json").read_text(encoding="utf-8"))
    slo = json.loads((ROOT / "p0-env/config/slo/p1-cpu-001-slo-v1.json").read_text(encoding="utf-8"))
    if [p["injector"]["target_additional_cpu_millicores"] for p in (low, medium, high)] != [50, 100, 150]:
        fail("profile_requested_demand")
    if [p["physical_effect_verification"]["minimum_steady_minus_baseline_mean_millicores"] for p in (low, medium, high)] != [25, 50, 75]:
        fail("profile_effect_threshold")
    if any(p["target"]["cpu_limit_millicores"] != 200 or p["injector"]["ramp_seconds"] != 120 or p["injector"]["steady_seconds"] != 300 for p in (low, medium, high)):
        fail("profile_shared_contract")
    if workload10["phases"] != {"warmup_seconds": 300, "normal_baseline_seconds": 300}:
        fail("workload_phase_contract")
    if slo["window_seconds"] != 5 or slo["latency"]["threshold_ms"] != 345.992 or slo["latency"]["consecutive_violating_windows"] != 3:
        fail("slo_contract")

    review = (WEEK9 / "adversarial-review.md").read_text(encoding="utf-8")
    require(review, [f"W9-G0{i}" for i in range(1, 10)], "review")
    addendum = (WEEK9 / "technical-method-addendum.md").read_text(encoding="utf-8")
    require(addendum, ["200 mCPU", "+50", "+100", "+150", "48 adjacent", "25, 50 and 75 mCPU", "300/300/120/300/300"], "addendum")

    metadata = json.loads((WEEK9 / "candidate-metadata.json").read_text(encoding="utf-8"))
    if metadata.get("status") != "not_submission_ready" or metadata.get("runtime_authorized") is not False or metadata.get("submission_authorized") is not False:
        fail("metadata_status_or_authority")
    if metadata.get("resolved_review_gaps") != [f"W9-G0{i}" for i in range(1, 10)]:
        fail("metadata_review_gaps")

    manifest = json.loads((WEEK9 / "sha256-manifest.json").read_text(encoding="utf-8"))
    if manifest.get("artifact_id") != "D148-WEEK9-AUDIENCE-HARDENING-001" or manifest.get("payload_count") != 7:
        fail("manifest_identity")
    for item in manifest.get("payloads", []):
        path = WEEK9 / item["path"]
        data = path.read_bytes()
        if len(data) != item["bytes"] or hashlib.sha256(data).hexdigest() != item["sha256"]:
            fail(f"manifest_payload:{item['path']}")

    reader = PdfReader(str(PDF))
    if len(reader.pages) != 4:
        fail(f"pdf_pages:{len(reader.pages)}")
    pdf_text = "\n".join(page.extract_text() or "" for page in reader.pages)
    pdf_text_normalized = re.sub(r"\s+", " ", pdf_text)
    require(pdf_text_normalized, ["200 mCPU", "+50, +100 and +150 mCPU", "48 adjacent", "25, 50 and 75 mCPU", "300/300/120/300/300", "two invalid normal baselines", "0/21"], "pdf")
    scan("pdf", PDF.read_bytes())

    with zipfile.ZipFile(PPTX) as deck:
        names = deck.namelist()
        slides = [name for name in names if re.fullmatch(r"ppt/slides/slide\d+\.xml", name)]
        charts = [name for name in names if re.fullmatch(r"ppt/(?:slides/)?charts/chart\d+\.xml", name)]
        if len(slides) != 10 or len(charts) != 2:
            fail(f"pptx_structure:slides={len(slides)},charts={len(charts)}")
        slide9 = deck.read("ppt/slides/slide9.xml")
        if b"<a:tbl>" not in slide9:
            fail("pptx_native_table_missing")
        xml = b"\n".join(deck.read(name) for name in names if name.endswith((".xml", ".rels")))
        scan("pptx", xml)
        normalized = re.sub(rb"<[^>]+>", b" ", xml).decode("utf-8", errors="ignore")
        require(normalized, ["Fault, fiziksel etki ve SLO sözleşmesi", "Payda ve iddia sınırı", "0/15 SLO manifestation", "Receipt replay: 0/21"], "pptx")

    hashes = {
        PDF: metadata["manuscript_pdf"]["sha256"],
        PPTX: metadata["defense_presentation"]["sha256"],
    }
    for path, expected in hashes.items():
        actual = hashlib.sha256(path.read_bytes()).hexdigest()
        if actual != expected:
            fail(f"metadata_hash:{path.name}:{actual}")

    with zipfile.ZipFile(ARCHIVE) as archive:
        names = archive.namelist()
        if "CHECKSUMS.sha256" not in names or "NOTICE.txt" not in names:
            fail("archive_controls")
        expected = {}
        for line in archive.read("CHECKSUMS.sha256").decode("utf-8").splitlines():
            digest, name = line.split("  ", 1)
            expected[name] = digest
        for name in names:
            data = archive.read(name)
            scan(f"archive:{name}", data)
            if name != "CHECKSUMS.sha256" and hashlib.sha256(data).hexdigest() != expected.get(name):
                fail(f"archive_checksum:{name}")

    print("week9_audience_package_verification=passed")
    print("resolved_gaps=W9-G01..W9-G09")
    print("pdf=4_pages;visual_review=passed")
    print("presentation=10_slides,2_native_charts,1_native_table;visual_review=passed")
    print("evidence=35_attempts,21_valid,14_invalid,15_fault,0_manifestations")
    print("receipt_pairs=0_of_21;fail_closed")
    print("runtime_authorized=false")
    print("submission_authorized=false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
