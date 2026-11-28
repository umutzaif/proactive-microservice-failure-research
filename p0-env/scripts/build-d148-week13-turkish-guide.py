#!/usr/bin/env python3
"""Build the D-148 Week 13 Turkish learning guide as an editable DOCX."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import re
import shutil
from pathlib import Path

from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[2]
WEEK13 = ROOT / "p0-env/artifacts/D148-COURSE-PUBLICATION-001/week-13"
SOURCE = WEEK13 / "turkce-akademik-cikti-rehberi.md"
METADATA = WEEK13 / "candidate-metadata.json"
DOCX = WEEK13 / "output/docx/d148-turkce-akademik-cikti-rehberi.docx"
PDF = WEEK13 / "output/pdf/d148-turkce-akademik-cikti-rehberi.pdf"
QA = WEEK13 / "tmp/rendered-pages"
QA_RECORD = WEEK13 / "visual-qa.json"
MANIFEST = WEEK13 / "sha256-manifest.json"
TEXT_SUFFIXES = {".json", ".md", ".py", ".txt"}


def load_base():
    path = ROOT / "p0-env/scripts/build-d148-week12-academic-output.py"
    spec = importlib.util.spec_from_file_location("week12_builder", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


BASE = load_base()
BASE_CONFIGURE_DOCUMENT = BASE.configure_document


def configure_document(doc) -> None:
    BASE_CONFIGURE_DOCUMENT(doc)
    section = doc.sections[0]
    section.page_width = Inches(8.27)
    section.page_height = Inches(11.69)
    section.top_margin = Inches(0.72)
    section.bottom_margin = Inches(0.68)
    section.left_margin = Inches(0.78)
    section.right_margin = Inches(0.78)
    normal = doc.styles["Normal"]
    normal.paragraph_format.line_spacing = 1.06
    normal.paragraph_format.space_after = Pt(4)
    doc.core_properties.title = "D148 Türkçe Akademik Çıktı Rehberi"
    doc.core_properties.subject = "Öğrenme ve tez savunması hazırlık rehberi"
    doc.core_properties.keywords = "mikroservis, fault injection, SLO, yeniden üretilebilirlik"


def add_table(doc, rows: list[list[str]]) -> None:
    column_count = len(rows[0])
    table = doc.add_table(rows=1, cols=column_count)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = True
    BASE.set_table_borders(table)
    BASE.set_repeat_table_header(table.rows[0])
    font_size = 8.0 if column_count >= 6 else 9.0
    for index, value in enumerate(rows[0]):
        cell = table.rows[0].cells[index]
        cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
        BASE.set_cell_shading(cell, "1F4E78")
        BASE.set_cell_margins(cell, top=70, start=80, bottom=70, end=80)
        paragraph = cell.paragraphs[0]
        paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
        paragraph.paragraph_format.space_after = Pt(0)
        BASE.set_font(paragraph.add_run(value), name="Arial", size=font_size, bold=True, color="FFFFFF")
    for row_index, values in enumerate(rows[1:], start=1):
        cells = table.add_row().cells
        for index, value in enumerate(values):
            cell = cells[index]
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            BASE.set_cell_margins(cell, top=65, start=75, bottom=65, end=75)
            if row_index % 2 == 0:
                BASE.set_cell_shading(cell, "EAF2F8")
            paragraph = cell.paragraphs[0]
            paragraph.alignment = WD_ALIGN_PARAGRAPH.LEFT if index == 0 or column_count <= 3 else WD_ALIGN_PARAGRAPH.CENTER
            paragraph.paragraph_format.space_after = Pt(0)
            BASE.set_font(paragraph.add_run(value), name="Arial", size=font_size)
    for row in table.rows:
        tr_pr = row._tr.get_or_add_trPr()
        cant_split = OxmlElement("w:cantSplit")
        tr_pr.append(cant_split)
    doc.add_paragraph().paragraph_format.space_after = Pt(0)


def portable_bytes(path: Path) -> bytes:
    data = path.read_bytes()
    return data.replace(b"\r\n", b"\n") if path.suffix.lower() in TEXT_SUFFIXES else data


def digest(path: Path) -> dict[str, object]:
    data = portable_bytes(path)
    return {"path": path.relative_to(WEEK13).as_posix(), "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}


def build_docx() -> None:
    BASE.SOURCE = SOURCE
    BASE.DOCX = DOCX
    BASE.configure_document = configure_document
    BASE.add_table = add_table
    BASE.build_docx()


def finalize() -> None:
    if not DOCX.is_file() or not PDF.is_file():
        raise SystemExit("week13_finalize_failed:docx_or_pdf_missing")
    pngs = sorted(QA.glob("page-*.png"), key=lambda path: int(re.findall(r"\d+", path.stem)[-1]))
    if not pngs:
        raise SystemExit("week13_finalize_failed:qa_pngs_missing")
    metadata = json.loads(METADATA.read_text(encoding="utf-8"))
    metadata["outputs"] = {
        "docx": {"path": DOCX.relative_to(WEEK13).as_posix(), "sha256": hashlib.sha256(DOCX.read_bytes()).hexdigest()},
        "pdf": {"path": PDF.relative_to(WEEK13).as_posix(), "sha256": hashlib.sha256(PDF.read_bytes()).hexdigest()},
    }
    METADATA.write_text(json.dumps(metadata, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
    qa_record = {
        "artifact_id": "D148-WEEK13-TURKISH-LEARNING-GUIDE-001",
        "inspected_date": "2026-11-28",
        "render_path": "Microsoft Word PDF export on Windows; bundled Poppler pdftoppm at 150 DPI",
        "pdf_sha256": hashlib.sha256(PDF.read_bytes()).hexdigest(),
        "page_count": len(pngs),
        "page_png_sha256": [hashlib.sha256(path.read_bytes()).hexdigest() for path in pngs],
        "inspection_status": "passed_all_pages",
        "checks": ["no_clipping", "no_overlap", "no_missing_turkish_glyphs", "tables_readable", "page_numbers_visible"],
    }
    QA_RECORD.write_text(json.dumps(qa_record, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
    payloads = [SOURCE, METADATA, WEEK13 / "README.md", QA_RECORD, DOCX, PDF]
    manifest = {
        "artifact_id": "D148-WEEK13-TURKISH-LEARNING-GUIDE-001",
        "payload_count": len(payloads),
        "text_normalization": "CRLF_to_LF_for_declared_text_suffixes; binary_exact",
        "payloads": [digest(path) for path in payloads],
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--docx-only", action="store_true")
    parser.add_argument("--finalize-existing-pdf", action="store_true")
    parser.add_argument("--visual-inspection-passed", action="store_true")
    args = parser.parse_args()
    if args.finalize_existing_pdf:
        if not args.visual_inspection_passed:
            raise SystemExit("week13_finalize_failed:visual_inspection_not_attested")
        finalize()
        print("week13_turkish_guide_build=passed")
        return 0
    build_docx()
    print("week13_turkish_guide_build=docx_only_passed")
    print(f"docx={DOCX.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
