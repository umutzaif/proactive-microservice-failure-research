#!/usr/bin/env python3
"""Verify the D-148 Week 12 venue-neutral academic output package."""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

from docx import Document
from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[2]
WEEK12 = ROOT / "p0-env/artifacts/D148-COURSE-PUBLICATION-001/week-12"
DOCX = WEEK12 / "output/docx/d148-venue-neutral-academic-paper.docx"
PDF = WEEK12 / "output/pdf/d148-venue-neutral-academic-paper.pdf"
QA = WEEK12 / "tmp/rendered-pages"
TEXT_SUFFIXES = {".bib", ".json", ".md", ".py", ".txt"}


def fail(message: str) -> None:
    raise SystemExit(f"week12_academic_output_verification=failed:{message}")


def require(text: str, tokens: list[str], label: str) -> None:
    missing = [token for token in tokens if token not in text]
    if missing:
        fail(f"{label}_missing:{missing}")


def portable_bytes(path: Path) -> bytes:
    data = path.read_bytes()
    return data.replace(b"\r\n", b"\n") if path.suffix.lower() in TEXT_SUFFIXES else data


def main() -> int:
    required = [
        WEEK12 / "academic-manuscript.md",
        WEEK12 / "academic-readiness-matrix.md",
        WEEK12 / "references.bib",
        WEEK12 / "hizli-rehber-tr.md",
        WEEK12 / "candidate-metadata.json",
        WEEK12 / "README.md",
        WEEK12 / "visual-qa.json",
        WEEK12 / "sha256-manifest.json",
        DOCX,
        PDF,
    ]
    missing = [str(path.relative_to(ROOT)) for path in required if not path.is_file()]
    if missing:
        fail(f"missing_files:{missing}")

    dependency = subprocess.run(
        [sys.executable, str(ROOT / "p0-env/scripts/verify-d148-week9-audience-package.py")],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    if dependency.returncode:
        fail(f"week9_dependency:{dependency.stdout}{dependency.stderr}")

    manuscript = (WEEK12 / "academic-manuscript.md").read_text(encoding="utf-8")
    require(
        manuscript,
        [
            "RQ1 Physical actuation",
            "RQ2 Service manifestation",
            "RQ3 Evidence governance",
            "35 unique attempts",
            "21 valid runs",
            "14 invalid attempts",
            "0/15",
            "zero of 21",
            "200 mCPU",
            "+50, +100, and +150 mCPU",
            "48 adjacent real-scrape",
            "25, 50, and 75 mCPU",
            "345.992 ms",
            "60 independent positive incidents",
            "60 independent normal controls",
        ],
        "manuscript",
    )
    forbidden = [
        r"CPU faults do not cause",
        r"statistically significant null",
        r"statistically equivalent",
        r"submission-ready",
        r"receipt-complete",
    ]
    for pattern in forbidden:
        if re.search(pattern, manuscript, flags=re.IGNORECASE):
            fail(f"overclaim:{pattern}")

    bibliography = (WEEK12 / "references.bib").read_text(encoding="utf-8")
    dois = re.findall(r"doi\s*=\s*\{([^}]+)\}", bibliography)
    if len(dois) != 8 or "10.1109/TDSC.2024.3363902" not in dois or "10.1109/TPDS.2004.14" not in dois:
        fail(f"bibliography_doi_set:{len(dois)}")

    readiness = (WEEK12 / "academic-readiness-matrix.md").read_text(encoding="utf-8")
    require(readiness, ["academic_review_ready_but_not_submission_ready", "Presentation quality", "Pass. All eight rendered pages"], "readiness")

    canonical = {
        "research_decisions": (ROOT / "research_decisions.md").read_text(encoding="utf-8"),
        "pilot_plan": (ROOT / "pilot_experiment_plan.md").read_text(encoding="utf-8"),
        "architecture": (ROOT / "docs/researcher-datasheets/01-project-architecture.md").read_text(encoding="utf-8"),
        "registry": (ROOT / "results_registry.md").read_text(encoding="utf-8"),
    }
    require(canonical["research_decisions"], ["## D-152 - Venue-neutral academic output hardening", "academic_review_ready_but_not_submission_ready"], "research_decisions")
    require(canonical["pilot_plan"], ["## Week 12 venue-neutral academic output", "caa2ad4d0b93b94349cd081aafb2ce77d3be565d07641584a3639d7836764e33"], "pilot_plan")
    require(canonical["architecture"], ["### D-152 venue-neutral academic-output edge", "portable nine-payload manifest"], "architecture")
    require(canonical["registry"], ["D148-WEEK12-VENUE-NEUTRAL-ACADEMIC-OUTPUT-001", "academic_review_ready_but_not_submission_ready"], "registry")

    metadata = json.loads((WEEK12 / "candidate-metadata.json").read_text(encoding="utf-8"))
    if metadata.get("status") != "academic_review_ready_but_not_submission_ready":
        fail("metadata_status")
    for key in ("runtime_authorized", "receipt_recovery_authorized", "external_communication_authorized", "submission_authorized", "publication_authorized"):
        if metadata.get(key) is not False:
            fail(f"metadata_authority:{key}")
    boundary = metadata.get("evidence_boundary", {})
    expected = {"attempts": 35, "valid": 21, "invalid": 14, "normal_valid": 6, "fault_valid": 15, "manifestations": 0, "receipt_pairs_available": 0, "receipt_pairs_expected": 21}
    if boundary != expected:
        fail(f"metadata_boundary:{boundary}")

    manifest = json.loads((WEEK12 / "sha256-manifest.json").read_text(encoding="utf-8"))
    if manifest.get("artifact_id") != "D148-WEEK12-VENUE-NEUTRAL-ACADEMIC-OUTPUT-001" or manifest.get("payload_count") != 9:
        fail("manifest_identity")
    for item in manifest.get("payloads", []):
        path = WEEK12 / item["path"]
        data = portable_bytes(path)
        if len(data) != item["bytes"] or hashlib.sha256(data).hexdigest() != item["sha256"]:
            fail(f"manifest_payload:{item['path']}")

    doc = Document(DOCX)
    docx_text = "\n".join(p.text for p in doc.paragraphs) + "\n" + "\n".join(cell.text for table in doc.tables for row in table.rows for cell in row.cells)
    require(docx_text, ["Evidence Bounded Microservice Case Study", "RQ1 Physical actuation", "0/15", "0/21", "References"], "docx")
    if len(doc.tables) != 1 or len(doc.tables[0].rows) != 7 or len(doc.tables[0].columns) != 7:
        fail(f"docx_table_shape:{len(doc.tables)}")

    with zipfile.ZipFile(DOCX) as archive:
        core = archive.read("docProps/core.xml").decode("utf-8", errors="replace").lower()
        all_xml = b"\n".join(archive.read(name) for name in archive.namelist() if name.endswith(".xml")).lower()
        for token in (b"asus-pc", b"c:\\users\\", b"github.com/umutzaif", b"@gmail.com", b"@outlook.com"):
            if token in all_xml:
                fail(f"docx_identifier_leak:{token!r}")
        if "<dc:creator></dc:creator>" not in core and "<dc:creator/>" not in core:
            fail("docx_author_metadata_not_blank")

    reader = PdfReader(str(PDF))
    page_count = len(reader.pages)
    if page_count < 8 or page_count > 24:
        fail(f"pdf_page_count:{page_count}")
    pdf_text = re.sub(r"\s+", " ", "\n".join(page.extract_text() or "" for page in reader.pages))
    require(pdf_text, ["35 unique attempts", "21 valid runs", "14 invalid attempts", "0/15", "345.992 ms", "Data and Artifact Availability"], "pdf")

    qa_record = json.loads((WEEK12 / "visual-qa.json").read_text(encoding="utf-8"))
    if qa_record.get("inspection_status") != "passed_all_pages" or qa_record.get("page_count") != page_count:
        fail(f"qa_record_status_or_count:{qa_record.get('inspection_status')}:{qa_record.get('page_count')}:{page_count}")
    if qa_record.get("pdf_sha256") != hashlib.sha256(PDF.read_bytes()).hexdigest():
        fail("qa_record_pdf_hash")
    if len(qa_record.get("page_png_sha256", [])) != page_count or any(not re.fullmatch(r"[0-9a-f]{64}", value) for value in qa_record.get("page_png_sha256", [])):
        fail("qa_record_page_hashes")

    guide = (WEEK12 / "hizli-rehber-tr.md").read_text(encoding="utf-8")
    require(guide, ["35 attempt: 21 valid, 14 invalid", "0/15", "0/21", "60 bağımsız pozitif incident", "dış konferans gönderimine hazır değildir"], "turkish_guide")

    print("week12_academic_output_verification=passed")
    print(f"academic_structure=3_research_questions,9_references,{page_count}_pages")
    print("evidence=35_attempts,21_valid,14_invalid,15_fault,0_manifestations")
    print("receipt_pairs=0_of_21;fail_closed")
    print("status=academic_review_ready_but_not_submission_ready")
    print("runtime_authorized=false")
    print("submission_authorized=false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
