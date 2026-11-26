#!/usr/bin/env python3
"""Build the D-148 Week 8 adviser-review manuscript PDF candidate."""

from __future__ import annotations

import argparse
import html
import re
from pathlib import Path

from reportlab.graphics.charts.barcharts import VerticalBarChart
from reportlab.graphics.shapes import Drawing, String
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import LETTER
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    FrameBreak,
    KeepTogether,
    NextPageTemplate,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[2]
WEEK7 = ROOT / "p0-env" / "artifacts" / "D148-COURSE-PUBLICATION-001" / "week-07"
TITLE = "When CPU Fault Actuation Does Not Manifest as an SLO Violation: An Evidence-Bounded Microservice Case Study"
SHORT_TITLE = "CPU Fault Actuation and SLO Manifestation"
CITATIONS = {
    "zheng2024mulan": 1,
    "zhang2026galr": 2,
    "cornacchia2025promise": 3,
    "yu2026proactive": 4,
    "zhang2025aiops": 5,
}


class InvariantCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        kwargs["invariant"] = 1
        super().__init__(*args, **kwargs)


def register_fonts() -> None:
    font_dir = Path("C:/Windows/Fonts")
    required = {
        "TimesNewRoman": "times.ttf",
        "TimesNewRoman-Bold": "timesbd.ttf",
        "TimesNewRoman-Italic": "timesi.ttf",
        "Arial": "arial.ttf",
        "Arial-Bold": "arialbd.ttf",
    }
    for name, filename in required.items():
        path = font_dir / filename
        if not path.is_file():
            raise SystemExit(f"required_font_missing:{path}")
        pdfmetrics.registerFont(TTFont(name, str(path)))


def clean_text(value: str) -> str:
    return (
        value.replace("\u2014", " - ")
        .replace("\u2013", "-")
        .replace("\u2011", "-")
        .replace("\u2192", " to ")
        .replace("\u00b1", "+/-")
        .replace("\u2019", "'")
        .replace("\u201c", '"')
        .replace("\u201d", '"')
    )


def inline_markup(value: str) -> str:
    value = clean_text(value)
    value = re.sub(
        r"\[@([a-zA-Z0-9_]+)\]",
        lambda match: f"[{CITATIONS[match.group(1)]}]" if match.group(1) in CITATIONS else match.group(0),
        value,
    )
    value = html.escape(value, quote=False)
    value = re.sub(r"`([^`]+)`", r"<font name='Arial'>\1</font>", value)
    value = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", value)
    value = re.sub(r"\*([^*]+)\*", r"<i>\1</i>", value)
    return value


def styles() -> dict[str, ParagraphStyle]:
    sample = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "Title", parent=sample["Title"], fontName="TimesNewRoman-Bold", fontSize=20,
            leading=23, alignment=TA_CENTER, spaceAfter=14, textColor=colors.HexColor("#111827"),
        ),
        "author": ParagraphStyle(
            "Author", fontName="TimesNewRoman", fontSize=11, leading=14, alignment=TA_CENTER,
            spaceAfter=13,
        ),
        "status": ParagraphStyle(
            "Status", fontName="Arial", fontSize=8.4, leading=11, alignment=TA_LEFT,
            borderColor=colors.HexColor("#B45309"), borderWidth=0.8, borderPadding=8,
            backColor=colors.HexColor("#FFF7ED"), spaceAfter=14,
        ),
        "abstract_title": ParagraphStyle(
            "AbstractTitle", fontName="TimesNewRoman-Bold", fontSize=10, leading=12,
            alignment=TA_CENTER, spaceBefore=4, spaceAfter=5,
        ),
        "abstract": ParagraphStyle(
            "Abstract", fontName="TimesNewRoman", fontSize=9.2, leading=11.4,
            alignment=TA_JUSTIFY, spaceAfter=8,
        ),
        "h1": ParagraphStyle(
            "H1", fontName="TimesNewRoman-Bold", fontSize=11, leading=13,
            spaceBefore=8, spaceAfter=4, keepWithNext=True, textColor=colors.HexColor("#111827"),
        ),
        "h2": ParagraphStyle(
            "H2", fontName="TimesNewRoman-Bold", fontSize=9.5, leading=11.5,
            spaceBefore=6, spaceAfter=3, keepWithNext=True,
        ),
        "body": ParagraphStyle(
            "Body", fontName="TimesNewRoman", fontSize=8.6, leading=10.8,
            alignment=TA_JUSTIFY, spaceAfter=4.5, allowWidows=0, allowOrphans=0,
        ),
        "bullet": ParagraphStyle(
            "Bullet", fontName="TimesNewRoman", fontSize=8.6, leading=10.8,
            leftIndent=11, firstLineIndent=-7, bulletIndent=2, alignment=TA_LEFT, spaceAfter=3,
        ),
        "caption": ParagraphStyle(
            "Caption", fontName="TimesNewRoman", fontSize=7.4, leading=9,
            alignment=TA_CENTER, spaceBefore=2, spaceAfter=6,
        ),
        "small": ParagraphStyle(
            "Small", fontName="Arial", fontSize=7.5, leading=9.2, spaceAfter=4,
        ),
        "reference": ParagraphStyle(
            "Reference", fontName="TimesNewRoman", fontSize=7.6, leading=9.4,
            leftIndent=10, firstLineIndent=-10, spaceAfter=3,
        ),
    }


def on_page(canv: canvas.Canvas, doc: BaseDocTemplate) -> None:
    width, height = LETTER
    canv.saveState()
    canv.setFont("Arial", 7)
    canv.setFillColor(colors.HexColor("#4B5563"))
    if doc.page > 1:
        canv.drawString(0.55 * inch, height - 0.38 * inch, SHORT_TITLE)
        canv.drawRightString(width - 0.55 * inch, height - 0.38 * inch, "Anonymous adviser-review candidate")
        canv.setStrokeColor(colors.HexColor("#D1D5DB"))
        canv.line(0.55 * inch, height - 0.44 * inch, width - 0.55 * inch, height - 0.44 * inch)
    canv.drawCentredString(width / 2, 0.32 * inch, str(doc.page))
    canv.restoreState()


def cpu_chart() -> Drawing:
    drawing = Drawing(235, 158)
    chart = VerticalBarChart()
    chart.x = 31
    chart.y = 31
    chart.width = 193
    chart.height = 104
    chart.data = [(50.349, 99.649, 146.941, 51.098, 93.987, 140.435)]
    chart.categoryAxis.categoryNames = ["10-L", "10-M", "10-H", "15-L", "15-M", "15-H"]
    chart.categoryAxis.labels.fontName = "Arial"
    chart.categoryAxis.labels.fontSize = 6.3
    chart.valueAxis.valueMin = 0
    chart.valueAxis.valueMax = 160
    chart.valueAxis.valueStep = 40
    chart.valueAxis.labels.fontName = "Arial"
    chart.valueAxis.labels.fontSize = 6.3
    chart.valueAxis.labelTextFormat = "%d"
    chart.bars[0].fillColor = colors.HexColor("#2563EB")
    chart.bars[0].strokeColor = colors.HexColor("#1E3A8A")
    chart.barSpacing = 2
    drawing.add(chart)
    drawing.add(String(118, 146, "Mean CPU increase (mCPU)", textAnchor="middle", fontName="Arial", fontSize=6.5))
    return drawing


def parse_table(lines: list[str], style_map: dict[str, ParagraphStyle]) -> Table:
    rows = []
    for index, line in enumerate(lines):
        if index == 1:
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        rows.append([Paragraph(inline_markup(cell), style_map["small"]) for cell in cells])
    table = Table(rows, colWidths=[51, 38, 18, 65, 40, 30], repeatRows=1, hAlign="CENTER")
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#E5E7EB")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.HexColor("#111827")),
        ("FONTNAME", (0, 0), (-1, 0), "Arial-Bold"),
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#9CA3AF")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("ALIGN", (1, 1), (-1, -1), "RIGHT"),
        ("LEFTPADDING", (0, 0), (-1, -1), 2.5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 2.5),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
    ]))
    return table


def split_front_and_body(markdown: str) -> tuple[dict[str, str], list[str]]:
    abstract = re.search(r"## Abstract\s+(.*?)\s+## CCS Concepts", markdown, flags=re.S)
    ccs = re.search(r"## CCS Concepts\s+(.*?)\s+## Keywords", markdown, flags=re.S)
    keywords = re.search(r"## Keywords\s+(.*?)\s+## 1\. Introduction", markdown, flags=re.S)
    body = re.search(r"## 1\. Introduction\s+(.*)", markdown, flags=re.S)
    if not all((abstract, ccs, keywords, body)):
        raise SystemExit("manuscript_sections_missing")
    front = {
        "abstract": " ".join(abstract.group(1).split()),
        "ccs": " ".join(line.lstrip("- ").strip() for line in ccs.group(1).splitlines() if line.strip()),
        "keywords": " ".join(keywords.group(1).split()),
    }
    return front, body.group(1).splitlines()


def addendum_section(addendum: str, heading: str, next_heading: str | None) -> str:
    if next_heading:
        pattern = rf"## {re.escape(heading)}\s+(.*?)\s+## {re.escape(next_heading)}"
    else:
        pattern = rf"## {re.escape(heading)}\s+(.*)"
    match = re.search(pattern, addendum, flags=re.S)
    if not match:
        raise SystemExit(f"technical_addendum_section_missing:{heading}")
    return match.group(1).strip()


def apply_technical_revision(markdown: str, addendum: str) -> str:
    treatment = addendum_section(addendum, "Treatment and target contract", "Workload contract")
    workload = addendum_section(addendum, "Workload contract", "Physical-effect eligibility")
    physical = addendum_section(addendum, "Physical-effect eligibility", "Frozen service manifestation")
    invalid = addendum_section(addendum, "Denominator and invalid-attempt audit", "Descriptive result detail")
    descriptive = addendum_section(addendum, "Descriptive result detail", None)

    revised = markdown.replace(
        "### 3.2 Frozen manifestation rule",
        "### 3.2 Treatment and workload contract\n\n"
        + treatment + "\n\n" + workload
        + "\n\n### 3.3 Physical-effect eligibility\n\n" + physical
        + "\n\n### 3.4 Frozen manifestation rule",
        1,
    )
    revised = revised.replace("### 3.3 Run eligibility and accounting", "### 3.5 Run eligibility and accounting", 1)
    revised = revised.replace("### 3.4 Analysis", "### 3.6 Analysis", 1)
    revised = revised.replace(
        "### 4.2 Physical actuation",
        invalid + "\n\n### 4.2 Physical actuation",
        1,
    )
    revised = revised.replace(
        "The ordered means support the bounded conclusion",
        descriptive + "\n\nThe ordered means support the bounded conclusion",
        1,
    )
    revised = revised.replace(
        "It is not yet a\npublic release, DOI deposit, or submission artifact.",
        "The history-free archive candidate excludes Git history, canonical governance files, raw tracked evidence, and absent receipt bundles. It is not yet a public release, DOI deposit, or submission artifact.",
        1,
    )
    return revised


def body_flowables(lines: list[str], style_map: dict[str, ParagraphStyle]) -> list[object]:
    flow: list[object] = [Paragraph("1. Introduction", style_map["h1"])]
    paragraph: list[str] = []
    bullet: list[str] = []
    table_lines: list[str] = []
    chart_added = False

    def flush_paragraph() -> None:
        if paragraph:
            flow.append(Paragraph(inline_markup(" ".join(paragraph)), style_map["body"]))
            paragraph.clear()

    def flush_bullet() -> None:
        if bullet:
            flow.append(Paragraph(inline_markup(" ".join(bullet)), style_map["bullet"], bulletText="-"))
            bullet.clear()

    def flush_table() -> None:
        nonlocal chart_added
        if table_lines:
            flow.append(parse_table(table_lines, style_map))
            flow.append(Paragraph("Table 1. Descriptive physical actuation by workload and severity.", style_map["caption"]))
            if not chart_added:
                flow.append(KeepTogether([
                    cpu_chart(),
                    Paragraph("Figure 1. Mean measured CPU increase. Labels combine workload and severity; bars are descriptive means, not causal estimates.", style_map["caption"]),
                ]))
                chart_added = True
            table_lines.clear()

    for raw in lines:
        line = raw.strip()
        if line.startswith("|"):
            flush_paragraph()
            flush_bullet()
            table_lines.append(line)
            continue
        if table_lines:
            flush_table()
        if not line:
            flush_paragraph()
            flush_bullet()
        elif line.startswith("### "):
            flush_paragraph()
            flush_bullet()
            flow.append(Paragraph(inline_markup(line[4:]), style_map["h2"]))
        elif line.startswith("## "):
            flush_paragraph()
            flush_bullet()
            flow.append(Paragraph(inline_markup(line[3:]), style_map["h1"]))
        elif re.match(r"^\d+\. \*\*", line):
            flush_paragraph()
            flush_bullet()
            content = re.sub(r"^\d+\.\s+", "", line)
            bullet.append(content)
        elif line.startswith("- "):
            flush_paragraph()
            flush_bullet()
            bullet.append(line[2:])
        elif line.startswith(">"):
            flush_paragraph()
            flush_bullet()
        elif bullet:
            bullet.append(line)
        else:
            paragraph.append(line)
    flush_paragraph()
    flush_bullet()
    flush_table()
    return flow


def references(style_map: dict[str, ParagraphStyle]) -> list[object]:
    entries = [
        "[1] L. Zheng, Z. Chen, J. He, and H. Chen. 2024. MULAN: Multi-modal Causal Structure Learning and Root Cause Analysis for Microservice Systems. The Web Conference. DOI: 10.1145/3589334.3645442.",
        "[2] W. Zhang, Z. Yang, F. Peng, L. Zhang, Y. Chen, and R. Chen. 2026. GALR: Graph-Based Root Cause Localization and LLM-Assisted Recovery for Microservice Systems. Electronics 15(1), 243. DOI: 10.3390/electronics15010243.",
        "[3] A. Cornacchia et al. 2025. Between Promise and Pain: The Reality of Automating Failure Analysis in Microservices with LLMs. APSys. DOI: 10.1145/3725783.3764388.",
        "[4] M. Yu et al. 2026. From Distributed Tracing to Proactive SLO Management: A Mini-Review of Trace-Driven Performance Prediction for Cloud-Native Microservices. Frontiers in Computer Science 8. DOI: 10.3389/fcomp.2026.1783945.",
        "[5] L. Zhang et al. 2025. A Survey of AIOps in the Era of Large Language Models. ACM Computing Surveys 58(2). DOI: 10.1145/3746635.",
    ]
    return [Paragraph("References", style_map["h1"])] + [Paragraph(inline_markup(item), style_map["reference"]) for item in entries]


def build(output: Path, technical_addendum: Path | None = None) -> None:
    register_fonts()
    markdown = (WEEK7 / "manuscript-draft.md").read_text(encoding="utf-8")
    if technical_addendum is not None:
        markdown = apply_technical_revision(markdown, technical_addendum.read_text(encoding="utf-8"))
    front, body_lines = split_front_and_body(markdown)
    style_map = styles()
    width, height = LETTER
    margin = 0.55 * inch
    header = 0.52 * inch
    footer = 0.48 * inch
    gap = 0.22 * inch
    usable_width = width - 2 * margin
    column_width = (usable_width - gap) / 2
    usable_height = height - header - footer

    output.parent.mkdir(parents=True, exist_ok=True)
    doc = BaseDocTemplate(
        str(output), pagesize=LETTER, leftMargin=margin, rightMargin=margin,
        topMargin=header, bottomMargin=footer, title=TITLE, author="Anonymous Author(s)",
        subject="D-148 evidence-bounded microservice case study adviser-review candidate",
        creator="D-148 deterministic Week 8 builder", pageCompression=1,
    )
    first_front_height = 360
    first_front_y = height - header - first_front_height
    first_body_height = first_front_y - footer - 10
    first_frame = Frame(margin, first_front_y, usable_width, first_front_height, id="first", leftPadding=4, rightPadding=4)
    first_left = Frame(margin, footer, column_width, first_body_height, id="first-left", leftPadding=0, rightPadding=5)
    first_right = Frame(margin + column_width + gap, footer, column_width, first_body_height, id="first-right", leftPadding=5, rightPadding=0)
    left = Frame(margin, footer, column_width, usable_height, id="left", leftPadding=0, rightPadding=5)
    right = Frame(margin + column_width + gap, footer, column_width, usable_height, id="right", leftPadding=5, rightPadding=0)
    doc.addPageTemplates([
        PageTemplate(id="First", frames=[first_frame, first_left, first_right], onPage=on_page),
        PageTemplate(id="TwoColumn", frames=[left, right], onPage=on_page),
    ])

    story: list[object] = [
        Spacer(1, 0.16 * inch),
        Paragraph(TITLE, style_map["title"]),
        Paragraph("Anonymous Author(s)", style_map["author"]),
        Paragraph(
            "<b>Adviser-review status.</b> Submission-layout candidate only. Receipt-level replay remains unavailable at 0/21 expected pairs. No model was trained or evaluated, and no runtime or external-validity claim is implied.",
            style_map["status"],
        ),
        Paragraph("Abstract", style_map["abstract_title"]),
        Paragraph(inline_markup(front["abstract"]), style_map["abstract"]),
        Paragraph("<b>CCS Concepts:</b> " + inline_markup(front["ccs"]), style_map["small"]),
        Paragraph("<b>Keywords:</b> " + inline_markup(front["keywords"]), style_map["small"]),
        Spacer(1, 0.08 * inch),
        Paragraph(
            "<b>Evidence boundary:</b> 35 attempts; 21 valid runs; 14 invalid attempts; 15 valid fault runs; 0/15 frozen-SLO manifestations; receipt replay 0/21.",
            style_map["status"],
        ),
        NextPageTemplate("TwoColumn"),
        FrameBreak(),
    ]
    story.extend(body_flowables(body_lines, style_map))
    story.extend(references(style_map))
    doc.build(story, canvasmaker=InvariantCanvas)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--technical-addendum", type=Path)
    args = parser.parse_args()
    addendum = args.technical_addendum.resolve() if args.technical_addendum else None
    build(args.output.resolve(), addendum)
    print(f"week8_manuscript_pdf_created={args.output.resolve()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
