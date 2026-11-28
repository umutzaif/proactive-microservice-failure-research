#!/usr/bin/env python3
"""Verify the D-148 Week 13 Turkish learning guide package."""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

from docx import Document
from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[2]
WEEK13 = ROOT / "p0-env/artifacts/D148-COURSE-PUBLICATION-001/week-13"
DOCX = WEEK13 / "output/docx/d148-turkce-akademik-cikti-rehberi.docx"
PDF = WEEK13 / "output/pdf/d148-turkce-akademik-cikti-rehberi.pdf"
TEXT_SUFFIXES = {".json", ".md", ".py", ".txt"}


def fail(message: str) -> None:
    raise SystemExit(f"week13_turkish_guide_verification=failed:{message}")


def require(text: str, tokens: list[str], label: str) -> None:
    missing = [token for token in tokens if token not in text]
    if missing:
        fail(f"{label}_missing:{missing}")


def portable_bytes(path: Path) -> bytes:
    data = path.read_bytes()
    return data.replace(b"\r\n", b"\n") if path.suffix.lower() in TEXT_SUFFIXES else data


def main() -> int:
    required = [WEEK13 / "turkce-akademik-cikti-rehberi.md", WEEK13 / "candidate-metadata.json", WEEK13 / "README.md", WEEK13 / "visual-qa.json", WEEK13 / "sha256-manifest.json", DOCX, PDF]
    missing = [str(path.relative_to(ROOT)) for path in required if not path.is_file()]
    if missing:
        fail(f"missing_files:{missing}")

    dependency = subprocess.run([sys.executable, str(ROOT / "p0-env/scripts/verify-d148-week12-academic-output.py")], cwd=ROOT, text=True, capture_output=True)
    if dependency.returncode:
        fail(f"week12_dependency:{dependency.stdout}{dependency.stderr}")

    source = (WEEK13 / "turkce-akademik-cikti-rehberi.md").read_text(encoding="utf-8")
    require(source, ["35 attempt", "21 valid", "14 invalid", "0/15", "0/21", "D-147", "3/6", "60 bağımsız pozitif incident", "60 bağımsız normal control", "academic_review_ready_but_not_submission_ready", "Bu adımdan hangi bilgiyi kazandım?"], "source")
    for pattern in [r"çalışma CPU fault'larının etkisiz olduğunu kanıtlar", r"istatistiksel olarak etkisizdir", r"paket dış gönderime hazırdır"]:
        if re.search(pattern, source, flags=re.IGNORECASE):
            fail(f"overclaim:{pattern}")

    metadata = json.loads((WEEK13 / "candidate-metadata.json").read_text(encoding="utf-8"))
    if metadata.get("status") != "academic_review_ready_but_not_submission_ready" or metadata.get("document_role") != "learning_and_defense_guide_not_new_scientific_result":
        fail("metadata_status_or_role")
    for key in ("runtime_authorized", "receipt_recovery_authorized", "external_communication_authorized", "submission_authorized", "publication_authorized"):
        if metadata.get(key) is not False:
            fail(f"metadata_authority:{key}")
    expected = {"attempts": 35, "valid": 21, "invalid": 14, "normal_valid": 6, "fault_valid": 15, "manifestations": 0, "receipt_pairs_available": 0, "receipt_pairs_expected": 21, "network_delay_valid_normals": 3, "network_delay_planned_normals": 6}
    if metadata.get("evidence_boundary") != expected:
        fail("metadata_evidence_boundary")

    document = Document(DOCX)
    docx_text = "\n".join(p.text for p in document.paragraphs) + "\n" + "\n".join(cell.text for table in document.tables for row in table.rows for cell in row.cells)
    require(docx_text, ["D148 Türkçe Akademik Çıktı Rehberi", "0/15", "0/21", "Savunma soruları", "Bu adımdan hangi bilgiyi kazandım?"], "docx")
    if len(document.tables) != 4:
        fail(f"docx_table_count:{len(document.tables)}")

    reader = PdfReader(str(PDF))
    if len(reader.pages) < 7 or len(reader.pages) > 24:
        fail(f"pdf_page_count:{len(reader.pages)}")
    pdf_text = re.sub(r"\s+", " ", "\n".join(page.extract_text() or "" for page in reader.pages))
    require(pdf_text, ["35 attempt", "21 valid", "14 invalid", "0/15", "0/21", "345,992 ms", "60 bağımsız pozitif incident"], "pdf")

    qa = json.loads((WEEK13 / "visual-qa.json").read_text(encoding="utf-8"))
    if qa.get("inspection_status") != "passed_all_pages" or qa.get("page_count") != len(reader.pages):
        fail("visual_qa_status_or_page_count")
    if qa.get("pdf_sha256") != hashlib.sha256(PDF.read_bytes()).hexdigest() or len(qa.get("page_png_sha256", [])) != len(reader.pages):
        fail("visual_qa_hash_binding")

    manifest = json.loads((WEEK13 / "sha256-manifest.json").read_text(encoding="utf-8"))
    if manifest.get("artifact_id") != "D148-WEEK13-TURKISH-LEARNING-GUIDE-001" or manifest.get("payload_count") != 6:
        fail("manifest_identity")
    for item in manifest.get("payloads", []):
        path = WEEK13 / item["path"]
        data = portable_bytes(path)
        if len(data) != item["bytes"] or hashlib.sha256(data).hexdigest() != item["sha256"]:
            fail(f"manifest_payload:{item['path']}")

    canonical = {
        "research_decisions": (ROOT / "research_decisions.md").read_text(encoding="utf-8"),
        "pilot_plan": (ROOT / "pilot_experiment_plan.md").read_text(encoding="utf-8"),
        "architecture": (ROOT / "docs/researcher-datasheets/01-project-architecture.md").read_text(encoding="utf-8"),
        "registry": (ROOT / "results_registry.md").read_text(encoding="utf-8"),
    }
    manifest_hash = hashlib.sha256(portable_bytes(WEEK13 / "sha256-manifest.json")).hexdigest()
    require(canonical["research_decisions"], ["## D-153 - Türkçe akademik çıktı öğrenme ve savunma rehberi", manifest_hash], "research_decisions")
    require(canonical["pilot_plan"], ["## Week 13 Türkçe akademik çıktı öğrenme paketi", manifest_hash], "pilot_plan")
    require(canonical["architecture"], ["### D-153 Türkçe öğrenme ve savunma katmanı"], "architecture")
    require(canonical["registry"], ["D148-WEEK13-TURKISH-LEARNING-GUIDE-001", manifest_hash], "results_registry")

    print("week13_turkish_guide_verification=passed")
    print(f"pages={len(reader.pages)};tables=4;language=tr")
    print("evidence=35_attempts,21_valid,14_invalid,15_fault,0_manifestations")
    print("receipt_pairs=0_of_21;network_delay_stop=3_of_6")
    print("runtime_authorized=false;submission_authorized=false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
