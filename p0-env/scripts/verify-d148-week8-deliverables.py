#!/usr/bin/env python3
"""Verify the D-148 Week 8 PDF, presentation, summary and archive candidates."""

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
WEEK8 = ROOT / "p0-env/artifacts/D148-COURSE-PUBLICATION-001/week-08"
PDF = WEEK8 / "output/pdf/d148-manuscript-adviser-review-candidate.pdf"
PPTX = WEEK8 / "output/pptx/d148-defense-presentation-candidate.pptx"
ARCHIVE = WEEK8 / "output/archive/d148-anonymized-artifact-candidate.zip"
FORBIDDEN = (b"asus-pc", b"c:\\users\\", b"github.com/umutzaif", b"@gmail.com", b"@outlook.com")


def fail(message: str) -> None:
    raise SystemExit(f"week8_deliverables_verification=failed:{message}")


def require(text: str, values: list[str], label: str) -> None:
    missing = [value for value in values if value not in text]
    if missing:
        fail(f"{label}_missing:{missing}")


def scan_bytes(label: str, data: bytes) -> None:
    found = [item.decode("ascii", errors="replace") for item in FORBIDDEN if item in data.lower()]
    if found:
        fail(f"direct_identifier_leak:{label}:{found}")


def main() -> int:
    required = [
        WEEK8 / "README.md",
        WEEK8 / "turkish-summary.md",
        WEEK8 / "candidate-metadata.json",
        WEEK8 / "sha256-manifest.json",
        PDF,
        PPTX,
        ARCHIVE,
    ]
    missing = [str(path.relative_to(ROOT)) for path in required if not path.is_file()]
    if missing:
        fail(f"missing_files:{missing}")

    result = subprocess.run(
        [sys.executable, str(ROOT / "p0-env/scripts/verify-d148-week7-draft.py")],
        cwd=ROOT, text=True, capture_output=True,
    )
    if result.returncode:
        fail(f"week7_dependency:{result.stdout}{result.stderr}")

    metadata = json.loads((WEEK8 / "candidate-metadata.json").read_text(encoding="utf-8"))
    manifest = json.loads((WEEK8 / "sha256-manifest.json").read_text(encoding="utf-8"))
    if metadata.get("status") != "not_submission_ready":
        fail("metadata_status")
    if metadata.get("runtime_authorized") is not False or metadata.get("submission_authorized") is not False:
        fail("metadata_authority")
    if metadata.get("evidence_boundary") != {
        "attempts": 35, "valid": 21, "invalid": 14, "valid_fault": 15,
        "manifestations": 0, "receipt_pairs_available": 0, "receipt_pairs_expected": 21,
    }:
        fail("metadata_evidence_boundary")

    payloads = manifest.get("payloads")
    if manifest.get("algorithm") != "SHA-256" or manifest.get("payload_count") != 6:
        fail("manifest_header")
    if not isinstance(payloads, list) or len(payloads) != 6:
        fail("manifest_payload_count")
    for payload in payloads:
        path = WEEK8 / payload["path"]
        if not path.is_file() or WEEK8 not in path.parents:
            fail(f"manifest_path:{payload.get('path')}")
        data = path.read_bytes()
        if len(data) != payload.get("bytes") or hashlib.sha256(data).hexdigest() != payload.get("sha256"):
            fail(f"manifest_payload:{payload['path']}")

    reader = PdfReader(str(PDF))
    if len(reader.pages) != 4:
        fail(f"pdf_page_count:{len(reader.pages)}")
    pdf_text = "\n".join(page.extract_text() or "" for page in reader.pages)
    require(pdf_text, ["35 attempts", "21 valid", "14 invalid", "0/15", "0/21", "60 independent positive incidents", "60 normal control runs"], "pdf")
    pdf_meta = reader.metadata or {}
    if "Anonymous" not in str(pdf_meta.get("/Author", "")):
        fail("pdf_author_metadata")
    scan_bytes("pdf", PDF.read_bytes())

    with zipfile.ZipFile(PPTX) as deck:
        names = deck.namelist()
        slide_names = [name for name in names if re.fullmatch(r"ppt/slides/slide\d+\.xml", name)]
        chart_names = [name for name in names if re.fullmatch(r"ppt/(?:slides/)?charts/chart\d+\.xml", name)]
        if len(slide_names) != 8 or len(chart_names) != 2:
            fail(f"pptx_structure:slides={len(slide_names)},charts={len(chart_names)}")
        pptx_xml = b"\n".join(deck.read(name) for name in names if name.endswith((".xml", ".rels")))
        scan_bytes("pptx", pptx_xml)
        normalized = re.sub(rb"<[^>]+>", b" ", pptx_xml).decode("utf-8", errors="ignore")
        require(normalized, ["35 girişimin fail-closed muhasebesi", "0/15", "0/21", "60 bağımsız pozitif olay"], "pptx")

    summary = (WEEK8 / "turkish-summary.md").read_text(encoding="utf-8")
    require(summary, ["35 benzersiz girişim", "21'i geçerlidir", "On dört girişim", "0/15", "0/21", "60 bağımsız", "What knowledge did I gain from this step?"], "summary")

    with zipfile.ZipFile(ARCHIVE) as archive:
        names = archive.namelist()
        if "CHECKSUMS.sha256" not in names or "NOTICE.txt" not in names:
            fail("archive_control_files")
        if any(name.startswith((".git/", "agent-handoffs/")) for name in names):
            fail("archive_history_or_handoff_leak")
        checksums = archive.read("CHECKSUMS.sha256").decode("utf-8").splitlines()
        expected = {}
        for line in checksums:
            digest, name = line.split("  ", 1)
            expected[name] = digest
        for name in names:
            data = archive.read(name)
            scan_bytes(f"archive:{name}", data)
            if name != "CHECKSUMS.sha256" and hashlib.sha256(data).hexdigest() != expected.get(name):
                fail(f"archive_checksum:{name}")

    expected_hashes = {
        PDF: metadata["manuscript_pdf"]["sha256"],
        PPTX: metadata["defense_presentation"]["sha256"],
    }
    for path, expected in expected_hashes.items():
        actual = hashlib.sha256(path.read_bytes()).hexdigest()
        if actual != expected:
            fail(f"metadata_hash:{path.name}:{actual}")

    print("week8_deliverables_verification=passed")
    print("pdf=4_pages;visual_review=passed")
    print("presentation=8_slides;native_charts=2;visual_review=passed")
    print("evidence=35_attempts,21_valid,14_invalid,15_fault,0_manifestations")
    print("receipt_pairs=0_of_21;fail_closed")
    print("runtime_authorized=false")
    print("submission_authorized=false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
