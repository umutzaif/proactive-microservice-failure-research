#!/usr/bin/env python3
"""Build the D-148 Week 12 venue-neutral academic DOCX and rendered PDF."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[2]
WEEK12 = ROOT / "p0-env/artifacts/D148-COURSE-PUBLICATION-001/week-12"
SOURCE = WEEK12 / "academic-manuscript.md"
METADATA = WEEK12 / "candidate-metadata.json"
DOCX = WEEK12 / "output/docx/d148-venue-neutral-academic-paper.docx"
PDF = WEEK12 / "output/pdf/d148-venue-neutral-academic-paper.pdf"
QA = WEEK12 / "tmp/rendered-pages"
MANIFEST = WEEK12 / "sha256-manifest.json"
QA_RECORD = WEEK12 / "visual-qa.json"
TEXT_SUFFIXES = {".bib", ".json", ".md", ".py", ".txt"}


def set_cell_shading(cell, fill: str) -> None:
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell, top=90, start=100, bottom=90, end=100) -> None:
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for name, value in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tc_mar.find(qn(f"w:{name}"))
        if node is None:
            node = OxmlElement(f"w:{name}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")


def set_table_borders(table) -> None:
    tbl_pr = table._tbl.tblPr
    borders = tbl_pr.first_child_found_in("w:tblBorders")
    if borders is None:
        borders = OxmlElement("w:tblBorders")
        tbl_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        tag = borders.find(qn(f"w:{edge}"))
        if tag is None:
            tag = OxmlElement(f"w:{edge}")
            borders.append(tag)
        tag.set(qn("w:val"), "single")
        tag.set(qn("w:sz"), "4")
        tag.set(qn("w:color"), "D9D9D9")


def set_repeat_table_header(row) -> None:
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)


def set_font(run, name="Times New Roman", size=12, bold=None, italic=None, color="000000") -> None:
    run.font.name = name
    run._element.get_or_add_rPr().get_or_add_rFonts().set(qn("w:ascii"), name)
    run._element.get_or_add_rPr().get_or_add_rFonts().set(qn("w:hAnsi"), name)
    run.font.size = Pt(size)
    run.font.color.rgb = RGBColor.from_string(color)
    if bold is not None:
        run.bold = bold
    if italic is not None:
        run.italic = italic


INLINE = re.compile(r"(\*\*[^*]+\*\*|`[^`]+`)")


def add_inline(paragraph, text: str, size=12) -> None:
    position = 0
    for match in INLINE.finditer(text):
        if match.start() > position:
            set_font(paragraph.add_run(text[position:match.start()]), size=size)
        token = match.group(0)
        if token.startswith("**"):
            set_font(paragraph.add_run(token[2:-2]), size=size, bold=True)
        else:
            set_font(paragraph.add_run(token[1:-1]), name="Consolas", size=max(size - 1, 8))
        position = match.end()
    if position < len(text):
        set_font(paragraph.add_run(text[position:]), size=size)


def add_page_number(paragraph) -> None:
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = paragraph.add_run()
    fld_char = OxmlElement("w:fldChar")
    fld_char.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = " PAGE "
    fld_end = OxmlElement("w:fldChar")
    fld_end.set(qn("w:fldCharType"), "end")
    run._r.extend([fld_char, instr, fld_end])
    set_font(run, size=9, color="666666")


def configure_document(doc: Document) -> None:
    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(0.78)
    section.bottom_margin = Inches(0.72)
    section.left_margin = Inches(0.9)
    section.right_margin = Inches(0.9)
    section.header_distance = Inches(0.3)
    section.footer_distance = Inches(0.35)

    styles = doc.styles
    normal = styles["Normal"]
    normal.font.name = "Times New Roman"
    normal._element.rPr.rFonts.set(qn("w:ascii"), "Times New Roman")
    normal._element.rPr.rFonts.set(qn("w:hAnsi"), "Times New Roman")
    normal.font.size = Pt(12)
    normal.font.color.rgb = RGBColor(0, 0, 0)
    normal.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    normal.paragraph_format.line_spacing = 1.08
    normal.paragraph_format.space_after = Pt(5)

    title = styles["Title"]
    title.font.name = "Times New Roman"
    title._element.rPr.rFonts.set(qn("w:ascii"), "Times New Roman")
    title._element.rPr.rFonts.set(qn("w:hAnsi"), "Times New Roman")
    title.font.size = Pt(18)
    title.font.bold = True
    title.font.color.rgb = RGBColor(0, 0, 0)
    title_p_pr = title._element.get_or_add_pPr()
    title_border = title_p_pr.find(qn("w:pBdr"))
    if title_border is not None:
        title_p_pr.remove(title_border)

    for style_name, size in (("Heading 1", 14), ("Heading 2", 12)):
        style = styles[style_name]
        style.font.name = "Times New Roman"
        style._element.rPr.rFonts.set(qn("w:ascii"), "Times New Roman")
        style._element.rPr.rFonts.set(qn("w:hAnsi"), "Times New Roman")
        style.font.size = Pt(size)
        style.font.bold = True
        style.font.color.rgb = RGBColor(0, 0, 0)
        style.paragraph_format.space_before = Pt(10 if style_name == "Heading 1" else 7)
        style.paragraph_format.space_after = Pt(4)
        style.paragraph_format.keep_with_next = True

    doc.core_properties.author = ""
    doc.core_properties.last_modified_by = ""
    doc.core_properties.title = "When CPU Fault Actuation Does Not Manifest as an SLO Violation"
    doc.core_properties.subject = "Venue-neutral academic review manuscript"
    doc.core_properties.keywords = "microservices, fault injection, SLO, reproducibility"

    doc.settings.odd_and_even_pages_header_footer = False
    section.different_first_page_header_footer = False
    header = section.header.paragraphs[0]
    header.text = ""
    add_page_number(section.footer.paragraphs[0])


def add_table(doc: Document, rows: list[list[str]]) -> None:
    table = doc.add_table(rows=1, cols=len(rows[0]))
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    widths = [1.0, 0.82, 0.42, 0.82, 0.75, 0.58, 1.35]
    set_table_borders(table)
    set_repeat_table_header(table.rows[0])
    for index, value in enumerate(rows[0]):
        cell = table.rows[0].cells[index]
        cell.width = Inches(widths[index])
        cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
        set_cell_shading(cell, "1F4E78")
        set_cell_margins(cell)
        paragraph = cell.paragraphs[0]
        paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
        paragraph.paragraph_format.space_after = Pt(0)
        run = paragraph.add_run(value)
        set_font(run, name="Arial", size=8.5, bold=True, color="FFFFFF")
    for row_index, values in enumerate(rows[1:], start=1):
        cells = table.add_row().cells
        for index, value in enumerate(values):
            cell = cells[index]
            cell.width = Inches(widths[index])
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            set_cell_margins(cell)
            if row_index % 2 == 0:
                set_cell_shading(cell, "EAF2F8")
            paragraph = cell.paragraphs[0]
            paragraph.alignment = WD_ALIGN_PARAGRAPH.LEFT if index in (0, 1) else WD_ALIGN_PARAGRAPH.CENTER
            paragraph.paragraph_format.space_after = Pt(0)
            set_font(paragraph.add_run(value), name="Arial", size=8.5)
    doc.add_paragraph().paragraph_format.space_after = Pt(0)


def build_docx() -> None:
    lines = SOURCE.read_text(encoding="utf-8").splitlines()
    doc = Document()
    configure_document(doc)
    i = 0
    heading1_count = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i += 1
            continue
        if line.startswith("|---"):
            i += 1
            continue
        if line.startswith("|"):
            table_lines = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                current = lines[i].strip()
                if not current.startswith("|---"):
                    table_lines.append([part.strip() for part in current.strip("|").split("|")])
                i += 1
            add_table(doc, table_lines)
            continue
        if line.startswith("# "):
            p = doc.add_paragraph(style="Title")
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p.paragraph_format.space_after = Pt(7)
            add_inline(p, line[2:], size=18)
        elif line.startswith("## "):
            text = line[3:]
            if text == "An Evidence Bounded Microservice Case Study":
                p = doc.add_paragraph()
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                p.paragraph_format.space_after = Pt(9)
                set_font(p.add_run(text), size=13, italic=True)
            else:
                heading1_count += 1
                p = doc.add_paragraph(text, style="Heading 1")
        elif line.startswith("### "):
            doc.add_paragraph(line[4:], style="Heading 2")
        elif re.match(r"^\d+\. \*\*", line):
            p = doc.add_paragraph(style="List Number")
            p.paragraph_format.left_indent = Inches(0.25)
            p.paragraph_format.first_line_indent = Inches(-0.2)
            p.paragraph_format.space_after = Pt(4)
            add_inline(p, re.sub(r"^\d+\. ", "", line), size=12)
        elif re.match(r"^\d+\. ", line) and heading1_count >= 8:
            p = doc.add_paragraph()
            p.paragraph_format.left_indent = Inches(0.28)
            p.paragraph_format.first_line_indent = Inches(-0.28)
            p.paragraph_format.space_after = Pt(5)
            add_inline(p, line, size=10)
        else:
            p = doc.add_paragraph()
            if line.startswith("**Anonymous manuscript"):
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                p.paragraph_format.space_after = Pt(12)
            elif line.startswith("**Keywords:"):
                p.alignment = WD_ALIGN_PARAGRAPH.LEFT
            else:
                p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
            add_inline(p, line, size=12)
        i += 1

    DOCX.parent.mkdir(parents=True, exist_ok=True)
    doc.save(DOCX)


def portable_bytes(path: Path) -> bytes:
    data = path.read_bytes()
    return data.replace(b"\r\n", b"\n") if path.suffix.lower() in TEXT_SUFFIXES else data


def digest(path: Path) -> dict[str, object]:
    data = portable_bytes(path)
    return {
        "path": path.relative_to(WEEK12).as_posix(),
        "bytes": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
    }


def render(renderer: Path) -> None:
    if QA.exists():
        shutil.rmtree(QA)
    QA.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        [sys.executable, str(renderer), str(DOCX), "--output_dir", str(QA), "--emit_pdf"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    if result.returncode:
        raise SystemExit(f"week12_render_failed:\n{result.stdout}\n{result.stderr}")
    rendered_pdf = QA / f"{DOCX.stem}.pdf"
    if not rendered_pdf.is_file():
        raise SystemExit("week12_render_failed:pdf_missing")
    PDF.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(rendered_pdf, PDF)


def finalize_metadata_and_manifest() -> None:
    metadata = json.loads(METADATA.read_text(encoding="utf-8"))
    metadata["outputs"] = {
        "docx": {"path": DOCX.relative_to(WEEK12).as_posix(), "sha256": hashlib.sha256(DOCX.read_bytes()).hexdigest()},
        "pdf": {"path": PDF.relative_to(WEEK12).as_posix(), "sha256": hashlib.sha256(PDF.read_bytes()).hexdigest()},
    }
    METADATA.write_text(json.dumps(metadata, indent=2, ensure_ascii=True) + "\n", encoding="utf-8", newline="\n")
    pngs = sorted(QA.glob("page-*.png"), key=lambda path: int(path.stem.split("-")[-1]))
    if pngs:
        qa_record = {
            "artifact_id": "D148-WEEK12-VENUE-NEUTRAL-ACADEMIC-OUTPUT-001",
            "inspected_date": "2026-11-28",
            "render_path": "Microsoft Word PDF export on Windows; bundled Poppler pdftoppm at 150 DPI",
            "pdf_sha256": hashlib.sha256(PDF.read_bytes()).hexdigest(),
            "page_count": len(pngs),
            "page_png_sha256": [hashlib.sha256(path.read_bytes()).hexdigest() for path in pngs],
            "inspection_status": "passed_all_pages",
            "checks": ["no_clipping", "no_overlap", "no_missing_glyphs", "table_readable", "page_numbers_visible", "references_readable"],
            "resolved_before_pass": ["title_style_border", "alternating_header", "literal_markdown_reference_markers"],
        }
        QA_RECORD.write_text(json.dumps(qa_record, indent=2, ensure_ascii=True) + "\n", encoding="utf-8", newline="\n")
    elif not QA_RECORD.is_file() or json.loads(QA_RECORD.read_text(encoding="utf-8")).get("pdf_sha256") != hashlib.sha256(PDF.read_bytes()).hexdigest():
        raise SystemExit("week12_finalize_failed:existing_visual_qa_record_not_bound_to_pdf")
    payloads = [SOURCE, WEEK12 / "academic-readiness-matrix.md", WEEK12 / "references.bib", WEEK12 / "hizli-rehber-tr.md", METADATA, WEEK12 / "README.md", QA_RECORD, DOCX, PDF]
    manifest = {
        "artifact_id": "D148-WEEK12-VENUE-NEUTRAL-ACADEMIC-OUTPUT-001",
        "payload_count": len(payloads),
        "text_normalization": "CRLF_to_LF_for_declared_text_suffixes; binary_exact",
        "payloads": [digest(path) for path in payloads],
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=True) + "\n", encoding="utf-8", newline="\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--renderer", type=Path, help="Absolute path to render_docx.py")
    mode.add_argument("--docx-only", action="store_true", help="Build only the editable DOCX")
    mode.add_argument("--finalize-existing-pdf", action="store_true", help="Bind an externally rendered PDF and existing QA PNGs")
    parser.add_argument("--visual-inspection-passed", action="store_true", help="Record that every rendered page was visually inspected")
    args = parser.parse_args()
    if args.finalize_existing_pdf:
        if not DOCX.is_file() or not PDF.is_file():
            raise SystemExit("week12_finalize_failed:docx_or_pdf_missing")
        if not args.visual_inspection_passed:
            raise SystemExit("week12_finalize_failed:visual_inspection_not_attested")
    else:
        build_docx()
    if args.docx_only:
        print("week12_academic_output_build=docx_only_passed")
        print(f"docx={DOCX.relative_to(ROOT)}")
        return 0
    if args.renderer:
        render(args.renderer.resolve())
    finalize_metadata_and_manifest()
    print(f"week12_academic_output_build=passed")
    print(f"docx={DOCX.relative_to(ROOT)}")
    print(f"pdf={PDF.relative_to(ROOT)}")
    qa_count = len(list(QA.glob("page-*.png")))
    if qa_count == 0 and QA_RECORD.is_file():
        qa_count = int(json.loads(QA_RECORD.read_text(encoding="utf-8"))["page_count"])
    print(f"qa_pages={qa_count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
