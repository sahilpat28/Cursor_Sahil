#!/usr/bin/env python3
"""Generate Sahil's 29 July 2026 quarterly business review artifacts."""

from __future__ import annotations

import argparse
from collections import defaultdict
from datetime import date, datetime
from pathlib import Path
from typing import Any

from openpyxl import Workbook, load_workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils.datetime import from_excel
from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import MSO_ANCHOR, PP_ALIGN
from pptx.util import Inches, Pt


AS_OF = date(2026, 7, 27)
REVIEW_DATE = date(2026, 7, 29)
OWNER = "Sahil Patni"

NAVY = "0B132B"
NAVY_2 = "111C3A"
TEAL = "00B8A9"
BLUE = "3A86FF"
ORANGE = "FF9F1C"
RED = "FF5A5F"
WHITE = "F7FAFC"
MUTED = "A8B2C7"
GRID = "2A3658"
PALE = "DDE6F3"
GREEN = "3DDC97"

REFERENCES = [
    (
        "R1",
        "International Federation of Robotics, World Robotics 2025 press release",
        "https://ifr.org/ifr-press-releases/news/global-robot-demand-in-factories-doubles-over-10-years",
    ),
    (
        "R2",
        "Rockwell Automation, 2025 State of Smart Manufacturing — APAC findings",
        "https://www.rockwellautomation.com/en-sg/company/news/press-releases/apac-sosm-2025.html",
    ),
    (
        "R3",
        "Interact Analysis, Machine Vision return-to-growth forecast, June 2025",
        "https://interactanalysis.com/return-to-growth-forecast-for-machine-vision-in-2025-despite-us-tariffs/",
    ),
    (
        "R4",
        "Altera, Robotics Solutions Stack",
        "https://www.altera.com/fpga-solutions/robotics-solutions-stack",
    ),
    (
        "R5",
        "Altera, Agilex 5 FPGA and SoC FPGA overview",
        "https://www.altera.com/products/fpga/agilex/5",
    ),
    (
        "R6",
        "AMD, Kria KR260 robotics platform and Kria Robotics Stack",
        "https://www.amd.com/en/products/system-on-modules/kria/k26/robotics.html",
    ),
    (
        "R7",
        "Altera, Video and Vision Processing Suite",
        "https://www.altera.com/products/ip/po-3150/video-and-vision-processing-suite",
    ),
    (
        "R8",
        "Altera, FPGA AI Suite",
        "https://www.altera.com/products/development-tools/fpga-ai-suite",
    ),
    (
        "R9",
        "AMD, Kria KV260 Vision AI Starter Kit",
        "https://www.amd.com/en/products/system-on-modules/kria/k26/kv260-vision-starter-kit.html",
    ),
    (
        "R10",
        "AMD, Versal AI Edge Series",
        "https://www.amd.com/en/products/adaptive-socs-and-fpgas/versal/ai-edge-series.html",
    ),
    (
        "R11",
        "Altera, Industrial solutions",
        "https://www.altera.com/fpga-solutions/industrial",
    ),
    (
        "R12",
        "Altera, Agilex 5 SoC HPS features including three 2.5G TSN Ethernet MACs",
        "https://docs.altera.com/r/docs/762191/current/agilextm-5-fpgas-and-socs-device-overview/additional-features-for-agilextm-5-socs",
    ),
    (
        "R13",
        "AMD, Industrial Networking solutions",
        "https://www.amd.com/en/solutions/industrial/industrial-networking.html",
    ),
    (
        "R14",
        "Altera, Agilex 5 Functional Safety",
        "https://docs.altera.com/api/khub/documents/xhgkkZ1PZaLEHFnNiUlbNA/content",
    ),
    (
        "R15",
        "AMD, Functional Safety",
        "https://www.amd.com/en/products/adaptive-socs-and-fpgas/technologies/functional-safety.html",
    ),
    (
        "R16",
        "Altera, Agilex 3 FPGA and SoC FPGA overview",
        "https://www.altera.com/products/fpga/agilex/3",
    ),
    (
        "R17",
        "AMD, Spartan UltraScale+ FPGA overview",
        "https://www.amd.com/en/products/adaptive-socs-and-fpgas/fpga/spartan-ultrascale-plus.html",
    ),
    (
        "R18",
        "AMD, Vitis unified software platform",
        "https://www.amd.com/en/products/software/adaptive-socs-and-fpgas/vitis.html",
    ),
]


def rgb(hex_value: str) -> RGBColor:
    return RGBColor.from_string(hex_value)


def parse_date(value: Any) -> date | None:
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    if isinstance(value, (int, float)):
        return from_excel(value).date()
    if isinstance(value, str):
        for pattern in ("%m/%d/%Y", "%Y-%m-%d"):
            try:
                return datetime.strptime(value, pattern).date()
            except ValueError:
                pass
    return None


def fmt_value(value: float, decimals: int = 2) -> str:
    """Format in source units; the workbook does not identify a currency."""
    if abs(value) >= 1_000_000:
        return f"{value / 1_000_000:.{decimals}f}M"
    if abs(value) >= 1_000:
        return f"{value / 1_000:.0f}K"
    return f"{value:,.0f}"


def fmt_date(value: date | None) -> str:
    return value.strftime("%d %b %Y") if value else "—"


def read_pipeline(source: Path) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    workbook = load_workbook(source, data_only=True)
    worksheet = workbook.active
    values = list(worksheet.iter_rows(values_only=True))
    headers = values[0]
    line_items = [
        dict(zip(headers, row))
        for row in values[1:]
        if row[2] == OWNER
    ]

    opportunities: dict[str, dict[str, Any]] = {}
    for row in line_items:
        opportunity_id = row["Opportunity ID"]
        if opportunity_id not in opportunities:
            opportunities[opportunity_id] = {
                **row,
                "Peak Value": 0.0,
                "Products": [],
            }
        opportunities[opportunity_id]["Peak Value"] += float(row["Peak Value"] or 0)
        opportunities[opportunity_id]["Products"].append(row["Product Name"])

    result = list(opportunities.values())
    for row in result:
        row["Design Win Date Parsed"] = parse_date(row["Design Win Date"])
        row["Created Date Parsed"] = parse_date(row["Created Date"])
        row["Production Start Date Parsed"] = parse_date(row["Production Start Date"])
        probability = float(row["Probability (%)"] or 0)
        row["Weighted Value"] = row["Peak Value"] * probability / 100

    result.sort(key=lambda item: item["Peak Value"], reverse=True)
    return line_items, result


def add_text(
    slide,
    x: float,
    y: float,
    w: float,
    h: float,
    text: str,
    *,
    size: float = 16,
    color: str = WHITE,
    bold: bool = False,
    font: str = "Aptos",
    align=PP_ALIGN.LEFT,
    valign=MSO_ANCHOR.TOP,
    margin: float = 0.04,
):
    shape = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    frame = shape.text_frame
    frame.clear()
    frame.word_wrap = True
    frame.margin_left = Inches(margin)
    frame.margin_right = Inches(margin)
    frame.margin_top = Inches(margin)
    frame.margin_bottom = Inches(margin)
    frame.vertical_anchor = valign
    paragraph = frame.paragraphs[0]
    paragraph.text = text
    paragraph.alignment = align
    paragraph.font.name = font
    paragraph.font.size = Pt(size)
    paragraph.font.bold = bold
    paragraph.font.color.rgb = rgb(color)
    return shape


def add_rich_text(
    slide,
    x: float,
    y: float,
    w: float,
    h: float,
    lines: list[tuple[str, str, float, bool]],
):
    shape = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    frame = shape.text_frame
    frame.clear()
    frame.word_wrap = True
    frame.margin_left = Inches(0.08)
    frame.margin_right = Inches(0.08)
    frame.margin_top = Inches(0.05)
    frame.margin_bottom = Inches(0.05)
    for index, (text, color, size, bold) in enumerate(lines):
        paragraph = frame.paragraphs[0] if index == 0 else frame.add_paragraph()
        paragraph.text = text
        paragraph.font.name = "Aptos"
        paragraph.font.size = Pt(size)
        paragraph.font.bold = bold
        paragraph.font.color.rgb = rgb(color)
        paragraph.space_after = Pt(5)
    return shape


def add_box(
    slide,
    x: float,
    y: float,
    w: float,
    h: float,
    *,
    fill: str = NAVY_2,
    line: str = GRID,
    radius: bool = True,
):
    kind = MSO_SHAPE.ROUNDED_RECTANGLE if radius else MSO_SHAPE.RECTANGLE
    shape = slide.shapes.add_shape(kind, Inches(x), Inches(y), Inches(w), Inches(h))
    shape.fill.solid()
    shape.fill.fore_color.rgb = rgb(fill)
    shape.line.color.rgb = rgb(line)
    shape.line.width = Pt(1)
    return shape


def add_header(slide, title: str, section: str, number: int):
    add_text(slide, 0.55, 0.25, 2.7, 0.25, section.upper(), size=9, color=TEAL, bold=True)
    add_text(slide, 0.55, 0.52, 11.9, 0.48, title, size=25, bold=True)
    add_text(
        slide,
        11.95,
        0.26,
        0.75,
        0.25,
        f"{number:02d}",
        size=10,
        color=MUTED,
        bold=True,
        align=PP_ALIGN.RIGHT,
    )
    line = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0.55), Inches(1.08), Inches(12.15), Inches(0.02))
    line.fill.solid()
    line.fill.fore_color.rgb = rgb(GRID)
    line.line.fill.background()
    add_text(
        slide,
        0.55,
        7.18,
        12.15,
        0.18,
        "Prepared 27 Jul 2026  •  Source: Sahil Report.xlsx  •  Values are in source units (currency not encoded)",
        size=7.5,
        color=MUTED,
    )


def add_citation(slide, text: str):
    add_text(slide, 0.62, 6.88, 12.0, 0.18, text, size=7.2, color=MUTED)


def new_slide(prs: Presentation, title: str, section: str, number: int):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    background = slide.background.fill
    background.solid()
    background.fore_color.rgb = rgb(NAVY)
    add_header(slide, title, section, number)
    return slide


def add_stat_card(slide, x: float, y: float, w: float, label: str, value: str, note: str, accent: str = TEAL):
    add_box(slide, x, y, w, 1.12)
    add_text(slide, x + 0.18, y + 0.13, w - 0.36, 0.22, label.upper(), size=8.5, color=MUTED, bold=True)
    add_text(slide, x + 0.18, y + 0.38, w - 0.36, 0.38, value, size=23, color=accent, bold=True)
    add_text(slide, x + 0.18, y + 0.82, w - 0.36, 0.18, note, size=8, color=PALE)


def add_table(
    slide,
    x: float,
    y: float,
    w: float,
    h: float,
    headers: list[str],
    rows: list[list[str]],
    widths: list[float],
    *,
    font_size: float = 8.5,
    header_size: float = 8,
    row_fills: list[str] | None = None,
):
    table = slide.shapes.add_table(
        len(rows) + 1,
        len(headers),
        Inches(x),
        Inches(y),
        Inches(w),
        Inches(h),
    ).table
    for index, width in enumerate(widths):
        table.columns[index].width = Inches(width)
    for col, header in enumerate(headers):
        cell = table.cell(0, col)
        cell.text = header
        cell.fill.solid()
        cell.fill.fore_color.rgb = rgb(BLUE)
        cell.margin_left = Inches(0.06)
        cell.margin_right = Inches(0.04)
        cell.margin_top = Inches(0.03)
        cell.margin_bottom = Inches(0.02)
        paragraph = cell.text_frame.paragraphs[0]
        paragraph.font.name = "Aptos"
        paragraph.font.size = Pt(header_size)
        paragraph.font.bold = True
        paragraph.font.color.rgb = rgb(WHITE)
        paragraph.vertical_anchor = MSO_ANCHOR.MIDDLE
    for row_index, row in enumerate(rows, start=1):
        fill = row_fills[row_index - 1] if row_fills else (NAVY_2 if row_index % 2 else "152446")
        for col, value in enumerate(row):
            cell = table.cell(row_index, col)
            cell.text = str(value)
            cell.fill.solid()
            cell.fill.fore_color.rgb = rgb(fill)
            cell.margin_left = Inches(0.06)
            cell.margin_right = Inches(0.04)
            cell.margin_top = Inches(0.025)
            cell.margin_bottom = Inches(0.02)
            frame = cell.text_frame
            frame.word_wrap = True
            frame.vertical_anchor = MSO_ANCHOR.MIDDLE
            paragraph = frame.paragraphs[0]
            paragraph.font.name = "Aptos"
            paragraph.font.size = Pt(font_size)
            paragraph.font.color.rgb = rgb(WHITE)
    return table


def suggested_gate(opportunity: dict[str, Any]) -> str:
    stage = opportunity["Opportunity Stage"]
    if stage == "Identify":
        return "Qualify use case, sponsor, budget and 0→25% gate"
    if stage == "Define":
        return "Freeze architecture/BOM and evaluation plan"
    if stage == "Develop":
        return "Close validation plan and design-freeze evidence"
    if stage == "Design":
        return "Secure DW evidence and production handoff"
    return "Confirm next-stage exit criteria"


def customer_name(value: str) -> str:
    replacements = {
        "EMERSON INNOVATION CENTER - PUNE": "Emerson",
        "GE HEALTHCARE": "GE HealthCare",
        "HONEYWELL AEROSPACE INDIA PRIVATE LIMITED": "Honeywell Aerospace",
        "HONEYWELL TECHNOLOGY SOLUTIONS": "Honeywell Tech.",
        "JUNIPER NETWORKS": "Juniper",
        "Outdu Mediatech Private Limited": "Outdu",
        "Philips India Limited - Innovation Center": "Philips",
    }
    return replacements.get(value, value)


def build_presentation(opportunities: list[dict[str, Any]], output: Path):
    total = sum(row["Peak Value"] for row in opportunities)
    weighted = sum(row["Weighted Value"] for row in opportunities)
    customers = sorted({row["Account Name"] for row in opportunities})
    created_2026 = [row for row in opportunities if row["Created Date Parsed"] and row["Created Date Parsed"].year == 2026]
    dw_2026 = [row for row in opportunities if row["Design Win Date Parsed"] and row["Design Win Date Parsed"].year == 2026]
    q4_2026 = [
        row
        for row in opportunities
        if row["Design Win Date Parsed"]
        and date(2026, 10, 1) <= row["Design Win Date Parsed"] <= date(2026, 12, 31)
    ]

    prs = Presentation()
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)

    # 1 — Cover
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    slide.background.fill.solid()
    slide.background.fill.fore_color.rgb = rgb(NAVY)
    accent = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), Inches(0.18), Inches(7.5))
    accent.fill.solid()
    accent.fill.fore_color.rgb = rgb(TEAL)
    accent.line.fill.background()
    add_text(slide, 0.8, 0.72, 4.0, 0.28, "QUARTERLY BUSINESS REVIEW", size=10, color=TEAL, bold=True)
    add_text(slide, 0.8, 1.22, 8.6, 1.32, "Own the next gate.\nBuild the 2027 engine.", size=35, bold=True)
    add_text(slide, 0.8, 2.78, 7.6, 0.42, "FAE plan review  •  Sahil Patni", size=18, color=PALE)
    add_text(slide, 0.8, 3.25, 7.6, 0.32, "Wednesday, 29 July 2026  |  12:00–13:00", size=13, color=MUTED)
    add_box(slide, 9.25, 0.75, 3.25, 5.55, fill=NAVY_2, line=GRID)
    add_text(slide, 9.62, 1.18, 2.5, 0.28, "PIPELINE SNAPSHOT", size=9, color=MUTED, bold=True)
    add_text(slide, 9.62, 1.65, 2.5, 0.58, fmt_value(total), size=31, color=TEAL, bold=True)
    add_text(slide, 9.62, 2.18, 2.5, 0.26, "peak value", size=10, color=PALE)
    add_text(slide, 9.62, 2.72, 2.5, 0.58, str(len(opportunities)), size=31, color=BLUE, bold=True)
    add_text(slide, 9.62, 3.25, 2.5, 0.26, "distinct opportunities", size=10, color=PALE)
    add_text(slide, 9.62, 3.78, 2.5, 0.58, str(len(customers)), size=31, color=ORANGE, bold=True)
    add_text(slide, 9.62, 4.31, 2.5, 0.26, "direct-account customers", size=10, color=PALE)
    add_text(slide, 9.62, 5.02, 2.5, 0.68, "Target + actual\ninputs required", size=15, color=RED, bold=True)
    add_text(slide, 0.8, 6.78, 7.5, 0.24, "Prepared from Sahil Report.xlsx  •  Source values shown without assumed currency", size=8, color=MUTED)

    # 2 — Executive snapshot
    slide = new_slide(prs, "Executive snapshot: value exists; conversion discipline is the gap", "01 / Position", 2)
    card_width = 2.82
    add_stat_card(slide, 0.55, 1.35, card_width, "Peak pipeline", fmt_value(total), "14 opportunities", TEAL)
    add_stat_card(slide, 3.55, 1.35, card_width, "Weighted pipeline", fmt_value(weighted), "probability × peak", BLUE)
    add_stat_card(slide, 6.55, 1.35, card_width, "Added in 2026", fmt_value(sum(x["Peak Value"] for x in created_2026)), "8 new opportunities", ORANGE)
    add_stat_card(slide, 9.55, 1.35, card_width, "2026 DWIN-dated", fmt_value(sum(x["Peak Value"] for x in dw_2026)), "5 opportunities", GREEN)
    add_box(slide, 0.55, 2.78, 7.55, 3.85)
    add_rich_text(
        slide,
        0.78,
        3.05,
        7.05,
        3.25,
        [
            ("WHAT THE DATA SAYS", TEAL, 10, True),
            (f"• {fmt_value(3_600_000)} sits at Identify / 0% probability; qualification is the first value unlock.", WHITE, 15, False),
            (f"• Outdu AI is {fmt_value(4_125_000)} ({4_125_000 / total:.0%} of portfolio) but remains Define with a 21 Oct 2026 DWIN date.", WHITE, 15, False),
            (f"• Q4 2026 DWIN-dated pipeline is {fmt_value(sum(x['Peak Value'] for x in q4_2026))}, yet weighted value is only {fmt_value(sum(x['Weighted Value'] for x in q4_2026))}.", WHITE, 15, False),
            ("• Source contains direct opportunities only; no distributor-owned pipeline is present.", WHITE, 15, False),
        ],
    )
    add_box(slide, 8.35, 2.78, 4.35, 3.85, fill="14213D", line=ORANGE)
    add_rich_text(
        slide,
        8.62,
        3.05,
        3.78,
        3.20,
        [
            ("DECISIONS FOR THE REVIEW", ORANGE, 10, True),
            ("1  Confirm 2026 target and YTD actual.", WHITE, 15, True),
            ("2  Agree stage-exit evidence for four Q4 DWINs.", WHITE, 15, True),
            ("3  Assign DFAE support to top conversion plays.", WHITE, 15, True),
            ("4  Select a distributor plan or confirm direct-only coverage.", WHITE, 15, True),
        ],
    )

    # 3 — Target vs achievement
    slide = new_slide(prs, "2026 target vs current achievement: source inputs are incomplete", "01 / Position", 3)
    add_text(slide, 0.55, 1.28, 12.0, 0.32, "Do not use open opportunity value as booked achievement or target attainment.", size=13, color=ORANGE, bold=True)
    labels = [
        ("2026 ANNUAL TARGET", "[ INPUT REQUIRED ]", "Sales target is not in the source file"),
        ("YTD ACTUAL ACHIEVEMENT", "[ INPUT REQUIRED ]", "Bookings/revenue/DWIN actuals are not in the source file"),
        ("GAP TO TARGET", "[ CALCULATE AFTER INPUT ]", "Target − YTD actual"),
    ]
    for index, (label, value, note) in enumerate(labels):
        x = 0.55 + index * 4.08
        add_box(slide, x, 1.85, 3.82, 1.62, fill="14213D", line=RED if index < 2 else GRID)
        add_text(slide, x + 0.2, 2.05, 3.42, 0.22, label, size=8.5, color=MUTED, bold=True)
        add_text(slide, x + 0.2, 2.40, 3.42, 0.34, value, size=17, color=RED if index < 2 else ORANGE, bold=True)
        add_text(slide, x + 0.2, 2.94, 3.42, 0.28, note, size=8, color=PALE)
    add_box(slide, 0.55, 3.82, 12.15, 2.45)
    add_text(slide, 0.8, 4.10, 11.65, 0.25, "AVAILABLE LEADING INDICATORS", size=9.5, color=TEAL, bold=True)
    indicators = [
        ("Peak pipeline", fmt_value(total)),
        ("Weighted pipeline", fmt_value(weighted)),
        ("2026-created", f"{len(created_2026)} / {fmt_value(sum(x['Peak Value'] for x in created_2026))}"),
        ("2026 DWIN-dated", f"{len(dw_2026)} / {fmt_value(sum(x['Peak Value'] for x in dw_2026))}"),
    ]
    for index, (label, value) in enumerate(indicators):
        x = 0.82 + index * 2.9
        add_text(slide, x, 4.58, 2.45, 0.22, label, size=9, color=MUTED, bold=True)
        add_text(slide, x, 4.90, 2.45, 0.38, value, size=19, color=WHITE, bold=True)
    add_text(slide, 0.82, 5.72, 11.2, 0.30, "Bring to review: annual target, YTD revenue/bookings, achieved DWIN count/value, and definition of “achievement.”", size=11.5, color=ORANGE, bold=True)

    # 4 — Funnel
    slide = new_slide(prs, "Opportunity funnel: 58% of value remains at 0–25% probability", "02 / Funnel", 4)
    stage_order = ["Identify", "Define", "Develop", "Design"]
    stage_colors = [RED, ORANGE, BLUE, GREEN]
    stage_rows = []
    for stage, stage_color in zip(stage_order, stage_colors):
        rows = [row for row in opportunities if row["Opportunity Stage"] == stage]
        value = sum(row["Peak Value"] for row in rows)
        stage_rows.append((stage, len(rows), value, sum(row["Weighted Value"] for row in rows), stage_color))
    max_value = max(row[2] for row in stage_rows)
    for index, (stage, count, value, stage_weighted, stage_color) in enumerate(stage_rows):
        y = 1.45 + index * 1.05
        add_text(slide, 0.62, y + 0.08, 1.15, 0.22, stage, size=12, bold=True)
        add_text(slide, 1.58, y + 0.08, 0.65, 0.22, f"{count} opps", size=9, color=MUTED)
        add_box(slide, 2.35, y, 6.35, 0.48, fill="152446", line="152446", radius=False)
        bar_width = max(0.12, 6.35 * value / max_value)
        bar = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(2.35), Inches(y), Inches(bar_width), Inches(0.48))
        bar.fill.solid()
        bar.fill.fore_color.rgb = rgb(stage_color)
        bar.line.fill.background()
        add_text(slide, 8.88, y + 0.03, 1.15, 0.24, fmt_value(value), size=13, bold=True, align=PP_ALIGN.RIGHT)
        add_text(slide, 10.18, y + 0.03, 1.52, 0.24, f"weighted {fmt_value(stage_weighted)}", size=9, color=MUTED)
    add_box(slide, 0.55, 5.72, 12.15, 0.75, fill="14213D", line=GRID)
    top_three = sum(row["Peak Value"] for row in opportunities[:3])
    add_text(slide, 0.82, 5.94, 3.35, 0.26, f"Top 3 = {top_three / total:.0%} of peak value", size=13, color=ORANGE, bold=True)
    add_text(slide, 4.35, 5.94, 3.75, 0.26, "2 Identify opportunities = 0 weighted value", size=13, color=RED, bold=True)
    add_text(slide, 8.35, 5.94, 3.85, 0.26, "Priority: qualify → define → evidence", size=13, color=TEAL, bold=True)

    # 5 — 2026 closure plan
    slide = new_slide(prs, "2026 DWIN-dated pipeline: convert five named plays", "03 / Closure", 5)
    ordered_dw = sorted(dw_2026, key=lambda row: row["Design Win Date Parsed"])
    rows = [
        [
            customer_name(row["Account Name"]),
            row["Opportunity Name"],
            row["Opportunity Stage"],
            f"{row['Probability (%)']:.0f}%",
            fmt_date(row["Design Win Date Parsed"]),
            fmt_value(row["Peak Value"]),
            suggested_gate(row),
        ]
        for row in ordered_dw
    ]
    add_table(
        slide,
        0.55,
        1.38,
        12.15,
        3.55,
        ["Customer", "Opportunity", "Stage", "Prob.", "DWIN", "Peak", "Proposed next gate"],
        rows,
        [1.15, 2.42, 0.76, 0.62, 1.03, 0.77, 5.40],
        font_size=8.4,
    )
    add_box(slide, 0.55, 5.22, 12.15, 1.18, fill="14213D", line=ORANGE)
    add_text(slide, 0.82, 5.46, 2.65, 0.22, "REVIEW COMMITMENT", size=9, color=ORANGE, bold=True)
    add_text(
        slide,
        3.05,
        5.39,
        9.15,
        0.62,
        "For each play: customer decision date • technical gap • required sample/tool/IP • named Sales + FAE + DFAE owners • evidence for the next stage.",
        size=13,
        color=WHITE,
        bold=True,
    )

    # 6/7 — Top opportunities
    for slide_number, chunk_start in ((6, 0), (7, 7)):
        chunk = opportunities[chunk_start:chunk_start + 7]
        title = "Top opportunities 1–7: protect the concentration" if chunk_start == 0 else "Top opportunities 8–14: build breadth and add #15"
        slide = new_slide(prs, title, "04 / Top opportunities", slide_number)
        table_rows = []
        fills = []
        for rank, row in enumerate(chunk, start=chunk_start + 1):
            table_rows.append(
                [
                    str(rank),
                    customer_name(row["Account Name"]),
                    row["Opportunity Name"],
                    row["Opportunity Stage"],
                    f"{row['Probability (%)']:.0f}%",
                    fmt_date(row["Design Win Date Parsed"]),
                    fmt_value(row["Peak Value"]),
                    suggested_gate(row),
                ]
            )
            fills.append("14213D" if rank <= 3 else (NAVY_2 if rank % 2 else "152446"))
        if chunk_start == 7:
            table_rows.append(["15", "—", "OPEN SLOT", "—", "—", "—", "—", "Add a qualified 2027 demand-creation play"])
            fills.append("2B1D2F")
        add_table(
            slide,
            0.55,
            1.35,
            12.15,
            4.92,
            ["#", "Customer", "Opportunity", "Stage", "Prob.", "DWIN", "Peak", "Proposed next gate"],
            table_rows,
            [0.35, 1.25, 2.52, 0.72, 0.60, 1.00, 0.74, 4.97],
            font_size=8.1,
            row_fills=fills,
        )
        if chunk_start == 0:
            add_text(slide, 0.65, 6.43, 11.9, 0.22, "Ranks 1–3 contribute 67.9% of total peak value; weekly executive inspection is warranted.", size=10.5, color=ORANGE, bold=True)
        else:
            add_text(slide, 0.65, 6.43, 11.9, 0.22, "The source contains 14 distinct Sahil opportunities—not 15. Use the open slot to create, qualify and name the next strategic play.", size=10.5, color=ORANGE, bold=True)

    # 8 — Customer portfolio
    slide = new_slide(prs, "Customer portfolio: Outdu and Honeywell Aerospace dominate peak value", "05 / Accounts", 8)
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in opportunities:
        grouped[row["Account Name"]].append(row)
    customer_rows = sorted(
        [
            (
                customer_name(account),
                len(rows),
                sum(item["Peak Value"] for item in rows),
                sum(item["Weighted Value"] for item in rows),
            )
            for account, rows in grouped.items()
        ],
        key=lambda row: row[2],
        reverse=True,
    )
    max_customer = max(row[2] for row in customer_rows)
    for index, (account, count, value, customer_weighted) in enumerate(customer_rows):
        y = 1.40 + index * 0.69
        add_text(slide, 0.62, y + 0.03, 1.65, 0.22, account, size=9.5, bold=True)
        add_box(slide, 2.35, y, 5.25, 0.34, fill="152446", line="152446", radius=False)
        bar_width = max(0.09, 5.25 * value / max_customer)
        bar = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(2.35), Inches(y), Inches(bar_width), Inches(0.34))
        bar.fill.solid()
        bar.fill.fore_color.rgb = rgb(TEAL if index < 2 else BLUE)
        bar.line.fill.background()
        add_text(slide, 7.78, y - 0.01, 0.85, 0.22, fmt_value(value), size=10.5, bold=True, align=PP_ALIGN.RIGHT)
        add_text(slide, 8.76, y - 0.01, 1.10, 0.22, f"W {fmt_value(customer_weighted)}", size=8.5, color=MUTED)
        add_text(slide, 10.06, y - 0.01, 0.85, 0.22, f"{count} opps", size=8.5, color=MUTED)
    add_box(slide, 0.55, 6.42, 12.15, 0.42, fill="14213D", line=GRID)
    add_text(slide, 0.78, 6.50, 11.65, 0.20, "Coverage check: 14/14 are direct “Altera Opportunity”; distributor account is blank on every Sahil line item.", size=9.5, color=ORANGE, bold=True)

    # 9 — Key account plans
    slide = new_slide(prs, "Q4 2026 / 2027 account plans: convert now, then expand adjacencies", "05 / Accounts", 9)
    account_plans = [
        ["Outdu", "AI response + tracking", "Close 21 Oct architecture, BOM and evaluation gate", "Replicate video/vision pipeline across tracking + analytics"],
        ["Honeywell", "Radar + industrial/aerospace control", "Qualify 3.00M radar; close two Design-stage evidence packs", "Create radar/thermal-control solution campaign"],
        ["Juniper", "PCIe FPGA + PQC interface", "Move CFPGA through validation; qualify PQC from 0%", "Position Agilex 3 for security/control-plane refresh"],
        ["GE HealthCare", "CT, anesthesia, power control", "Recover 2026 SP-PDU gate; define CT/anesthesia evaluations", "Medical imaging + controller platform expansion"],
        ["Emerson", "RX3i controller", "Freeze dual-device architecture before 16 Dec", "Industrial automation controller modernization"],
        ["Philips", "CT + MRI UI", "Secure CT design evidence; define MRI UI success criteria", "Imaging workflow and low-power control adjacency"],
    ]
    add_table(
        slide,
        0.55,
        1.35,
        12.15,
        4.95,
        ["Account", "Current plays", "Q4 2026 proposed focus", "2027 proposed expansion"],
        account_plans,
        [1.18, 2.28, 4.10, 4.59],
        font_size=9.0,
        header_size=8.5,
    )
    add_text(slide, 0.65, 6.43, 11.9, 0.22, "These are proposed actions inferred from stage/date/product data; validate customer commitments and support history in the review.", size=9.5, color=MUTED)

    # 10 — Demand creation
    slide = new_slide(prs, "FY2027 demand creation: three repeatable motions", "06 / 2027 creation", 10)
    initiatives = [
        (
            "ROBOTICS + CONTROL",
            ORANGE,
            "Target",
            "Industrial OEMs; Emerson + Honeywell adjacencies",
            "Offer",
            "Deterministic control, functional partitioning, secure connectivity",
            "Create",
            "Controller architecture workshop + 3 qualified use cases",
        ),
        (
            "VIDEO + VISION",
            TEAL,
            "Target",
            "Outdu, medical imaging and smart sensing teams",
            "Offer",
            "Edge AI/video pipeline on Agilex 5 D / Agilex 3",
            "Create",
            "Vision benchmark day + reference design + 3 evaluations",
        ),
        (
            "INDUSTRIAL PLATFORM",
            BLUE,
            "Target",
            "Automation, medical controls and network infrastructure",
            "Offer",
            "PCIe/Ethernet modernization and legacy FPGA migration",
            "Create",
            "Portfolio migration clinic + joint Sales/FAE account map",
        ),
    ]
    for index, initiative in enumerate(initiatives):
        title, accent_color, label1, value1, label2, value2, label3, value3 = initiative
        x = 0.55 + index * 4.10
        add_box(slide, x, 1.42, 3.82, 4.75, fill="14213D", line=accent_color)
        add_text(slide, x + 0.22, 1.72, 3.38, 0.36, title, size=15, color=accent_color, bold=True)
        add_text(slide, x + 0.22, 2.35, 3.38, 0.22, label1.upper(), size=8, color=MUTED, bold=True)
        add_text(slide, x + 0.22, 2.62, 3.38, 0.70, value1, size=12, bold=True)
        add_text(slide, x + 0.22, 3.46, 3.38, 0.22, label2.upper(), size=8, color=MUTED, bold=True)
        add_text(slide, x + 0.22, 3.73, 3.38, 0.70, value2, size=12, bold=True)
        add_text(slide, x + 0.22, 4.60, 3.38, 0.22, label3.upper(), size=8, color=MUTED, bold=True)
        add_text(slide, x + 0.22, 4.87, 3.38, 0.86, value3, size=12, bold=True)
    add_text(slide, 0.65, 6.40, 11.9, 0.28, "Review decision: choose numeric 2027 creation targets after the 2027 sales objective is confirmed.", size=10.5, color=ORANGE, bold=True)

    # 11 — Market signals
    slide = new_slide(prs, "Market review: growth is real, but proof-of-value wins budgets", "07 / Market review", 11)
    market_signals = [
        (
            "ROBOTICS",
            ORANGE,
            "9,100",
            "robots installed in India in 2024",
            "+7% YoY • India ranked #6 • automotive = 45% of installs",
            "Commercial implication",
            "Prioritize automotive suppliers, machine builders and control platforms; sell deterministic integration, not an FPGA.",
        ),
        (
            "VIDEO + VISION",
            TEAL,
            "$5.7B",
            "2025 global machine-vision forecast",
            "+1.5% after a 3.9% decline in 2024 • price pressure remains",
            "Commercial implication",
            "Lead with workload benchmarks, integration time and sensor flexibility; generic camera growth is not enough.",
        ),
        (
            "INDUSTRIAL",
            BLUE,
            "94%",
            "of APAC manufacturers investing/planning AI",
            "quality control 47% • process optimization 43% • cyber is critical",
            "Commercial implication",
            "Package edge AI with control, networking, safety and security around a measurable factory KPI.",
        ),
    ]
    for index, (name, accent_color, metric, metric_label, evidence, implication_label, implication) in enumerate(market_signals):
        x = 0.55 + index * 4.10
        add_box(slide, x, 1.38, 3.82, 4.95, fill="14213D", line=accent_color)
        add_text(slide, x + 0.22, 1.68, 3.38, 0.27, name, size=11, color=accent_color, bold=True)
        add_text(slide, x + 0.22, 2.13, 3.38, 0.54, metric, size=29, color=WHITE, bold=True)
        add_text(slide, x + 0.22, 2.72, 3.38, 0.46, metric_label, size=11, color=PALE, bold=True)
        add_text(slide, x + 0.22, 3.40, 3.38, 0.68, evidence, size=10.5, color=MUTED)
        add_text(slide, x + 0.22, 4.32, 3.38, 0.22, implication_label.upper(), size=8, color=accent_color, bold=True)
        add_text(slide, x + 0.22, 4.66, 3.38, 1.15, implication, size=11.5, bold=True)
    add_citation(slide, "[R1] IFR World Robotics 2025  •  [R3] Interact Analysis, Jun 2025  •  [R2] Rockwell APAC Smart Manufacturing 2025")

    # 12 — Robotics market
    slide = new_slide(prs, "Robotics: India is scaling; own the deterministic control layer", "07 / Market review", 12)
    add_box(slide, 0.55, 1.38, 4.00, 4.95, fill="14213D", line=ORANGE)
    add_text(slide, 0.80, 1.70, 3.50, 0.25, "MARKET EVIDENCE", size=9, color=ORANGE, bold=True)
    add_rich_text(
        slide,
        0.76,
        2.12,
        3.55,
        3.62,
        [
            ("542K global robot installs in 2024", WHITE, 18, True),
            ("4.664M operational stock; +9% YoY", PALE, 12, False),
            ("India: 9.1K installs, +7%, #6 globally", WHITE, 15, True),
            ("45% of India installs were automotive", PALE, 12, False),
            ("IFR forecasts 575K global installs in 2025 and >700K by 2028.", WHITE, 12, False),
        ],
    )
    add_box(slide, 4.78, 1.38, 3.78, 4.95, fill="14213D", line=TEAL)
    add_text(slide, 5.03, 1.70, 3.28, 0.25, "COMPETITIVE BATTLEFIELD", size=9, color=TEAL, bold=True)
    add_rich_text(
        slide,
        4.99,
        2.12,
        3.30,
        3.70,
        [
            ("AMD Xilinx strength", ORANGE, 10, True),
            ("Kria KR260: production SOM path, native ROS 2 and Kria Robotics Stack.", WHITE, 12, False),
            ("Altera proof", TEAL, 10, True),
            ("ROS 2 controller, Drive-on-Chip, safety, sensor fusion and 3×2.5G TSN reference designs.", WHITE, 12, False),
            ("Win condition", BLUE, 10, True),
            ("Demonstrate lower end-to-end jitter and fewer devices for the customer's exact control loop.", WHITE, 12, True),
        ],
    )
    add_box(slide, 8.78, 1.38, 3.92, 4.95, fill="14213D", line=BLUE)
    add_text(slide, 9.03, 1.70, 3.42, 0.25, "PROPOSED 2027 MOTION", size=9, color=BLUE, bold=True)
    add_rich_text(
        slide,
        8.99,
        2.12,
        3.45,
        3.78,
        [
            ("Target", BLUE, 10, True),
            ("Robot OEMs, AMR makers, automotive suppliers and control-system integrators.", WHITE, 12, False),
            ("Offer", BLUE, 10, True),
            ("Sense→think→act workshop using Agilex 5 SoC, TSN and functional-safety architecture.", WHITE, 12, False),
            ("Proposed scorecard", BLUE, 10, True),
            ("12 named accounts • 6 workshops • 3 evaluations • 2 qualified opportunities • 1 DWIN.", WHITE, 12, True),
        ],
    )
    add_citation(slide, "[R1] IFR World Robotics 2025  •  [R4] Altera Robotics Stack  •  [R5] Agilex 5  •  [R6] AMD Kria KR260")

    # 13 — Video and vision market
    slide = new_slide(prs, "Video + vision: recovery is selective; benchmark the whole pipeline", "07 / Market review", 13)
    add_box(slide, 0.55, 1.38, 4.00, 4.95, fill="14213D", line=TEAL)
    add_text(slide, 0.80, 1.70, 3.50, 0.25, "MARKET EVIDENCE", size=9, color=TEAL, bold=True)
    add_rich_text(
        slide,
        0.76,
        2.12,
        3.55,
        3.65,
        [
            ("2024 global market: −3.9%", WHITE, 18, True),
            ("Inventory correction and manufacturing softness", PALE, 12, False),
            ("2025 forecast: +1.5% to $5.7B", WHITE, 16, True),
            ("2028 forecast: $7B", PALE, 12, False),
            ("Area-scan cameras fell 7.8%; APAC vendor price pressure makes undifferentiated hardware vulnerable.", WHITE, 12, False),
        ],
    )
    add_box(slide, 4.78, 1.38, 3.78, 4.95, fill="14213D", line=ORANGE)
    add_text(slide, 5.03, 1.70, 3.28, 0.25, "COMPETITIVE BATTLEFIELD", size=9, color=ORANGE, bold=True)
    add_rich_text(
        slide,
        4.99,
        2.12,
        3.30,
        3.72,
        [
            ("AMD Xilinx strength", ORANGE, 10, True),
            ("KV260 quick start, multi-camera interfaces, Vitis Vision/AI and Versal AI Engine scale.", WHITE, 12, False),
            ("Altera proof", TEAL, 10, True),
            ("45+ VVP IP cores, >600 MHz claimed Fmax, 8K60+ optimization and FPGA AI Suite.", WHITE, 12, False),
            ("Win condition", BLUE, 10, True),
            ("Customer-model benchmark: ingest + ISP + inference + output latency, power and engineering weeks.", WHITE, 12, True),
        ],
    )
    add_box(slide, 8.78, 1.38, 3.92, 4.95, fill="14213D", line=BLUE)
    add_text(slide, 9.03, 1.70, 3.42, 0.25, "PROPOSED 2027 MOTION", size=9, color=BLUE, bold=True)
    add_rich_text(
        slide,
        8.99,
        2.12,
        3.45,
        3.78,
        [
            ("Named beachheads", BLUE, 10, True),
            ("Outdu tracking/analytics; GE + Philips medical imaging; industrial inspection.", WHITE, 12, False),
            ("Offer", BLUE, 10, True),
            ("Bring-your-model vision benchmark day with two sensor interfaces and a production BOM.", WHITE, 12, False),
            ("Proposed scorecard", BLUE, 10, True),
            ("8 accounts • 4 benchmarks • 3 evaluations • 2 qualified opportunities • 1 DWIN.", WHITE, 12, True),
        ],
    )
    add_citation(slide, "[R3] Interact Analysis  •  [R7] Altera VVP Suite  •  [R8] FPGA AI Suite  •  [R9] AMD KV260  •  [R10] Versal AI Edge")

    # 14 — Industrial market
    slide = new_slide(prs, "Industrial: AI spending converges with control, safety and cyber", "07 / Market review", 14)
    add_box(slide, 0.55, 1.38, 4.00, 4.95, fill="14213D", line=BLUE)
    add_text(slide, 0.80, 1.70, 3.50, 0.25, "MARKET EVIDENCE — APAC", size=9, color=BLUE, bold=True)
    add_rich_text(
        slide,
        0.76,
        2.12,
        3.55,
        3.65,
        [
            ("94% investing / planning AI", WHITE, 18, True),
            ("47%: quality control is top AI use case", PALE, 12, False),
            ("43%: process optimization", WHITE, 16, True),
            ("95%: cyber standards important", PALE, 12, False),
            ("The buying unit spans OT control, data, safety and security—not a single component owner.", WHITE, 12, False),
        ],
    )
    add_box(slide, 4.78, 1.38, 3.78, 4.95, fill="14213D", line=ORANGE)
    add_text(slide, 5.03, 1.70, 3.28, 0.25, "COMPETITIVE BATTLEFIELD", size=9, color=ORANGE, bold=True)
    add_rich_text(
        slide,
        4.99,
        2.12,
        3.30,
        3.72,
        [
            ("Shared table stakes", ORANGE, 10, True),
            ("AMD and Altera both offer TSN, industrial connectivity and certified safety flows.", WHITE, 12, False),
            ("Altera proof point", TEAL, 10, True),
            ("Agilex 5 SoC integrates three hardened 2.5G TSN MACs; Drive-on-Chip and FSDP support.", WHITE, 12, False),
            ("Win condition", BLUE, 10, True),
            ("Quantify BOM consolidation, deterministic cycle time and certification work saved.", WHITE, 12, True),
        ],
    )
    add_box(slide, 8.78, 1.38, 3.92, 4.95, fill="14213D", line=TEAL)
    add_text(slide, 9.03, 1.70, 3.42, 0.25, "PROPOSED 2027 MOTION", size=9, color=TEAL, bold=True)
    add_rich_text(
        slide,
        8.99,
        2.12,
        3.45,
        3.78,
        [
            ("Named beachheads", TEAL, 10, True),
            ("Emerson controller; Honeywell automation; machine builders via Arrow/Macnica.", WHITE, 12, False),
            ("Offer", TEAL, 10, True),
            ("Industrial platform clinic: TSN + PLC/control + safety + secure lifecycle.", WHITE, 12, False),
            ("Proposed scorecard", TEAL, 10, True),
            ("15 accounts • 6 clinics • 4 evaluations • 3 qualified opportunities • 1 DWIN.", WHITE, 12, True),
        ],
    )
    add_citation(slide, "[R2] Rockwell APAC 2025  •  [R11–R15] Altera/AMD industrial networking and functional-safety sources")

    # 15 — Portfolio map
    slide = new_slide(prs, "Competitive portfolio map: no single one-for-one device comparison", "08 / Competition", 15)
    portfolio_rows = [
        [
            "Cost / I/O edge",
            "Agilex 3 C: FPGA + optional dual A55 SoC, AI tensor DSP, MIPI, 12.5G",
            "Spartan UltraScale+: high I/O, 16.3G, PCIe Gen4, hardened LPDDR; no processor",
            "Compare package, I/O mix, BOM, power and required processor—not density labels.",
        ],
        [
            "Midrange embedded",
            "Agilex 5 E: A76/A55 SoC options, 3×2.5G TSN, AI tensor blocks",
            "Zynq UltraScale+ MPSoC / Kria K26: mature SOM and software ecosystem",
            "Altera: consolidation + hard TSN. AMD: fast SOM/ROS path. Prove development effort.",
        ],
        [
            "AI / vision scale",
            "Agilex 5 D/E + FPGA AI Suite + VVP; custom streaming data path",
            "Versal AI Edge + AI Engines; Kria KV260 for fast vision evaluation",
            "TOPS are not directly comparable. Benchmark the customer's model and full pipeline.",
        ],
        [
            "High-end adaptable",
            "Agilex 7/9 families for high bandwidth, RF and complex acceleration",
            "Versal Premium / AI Core / RF families",
            "Treat as architecture-led pursuits; involve product-line DFAEs before device claims.",
        ],
    ]
    add_table(
        slide,
        0.55,
        1.35,
        12.15,
        4.95,
        ["Battlefield", "Altera position", "AMD Xilinx position", "FAE comparison rule"],
        portfolio_rows,
        [1.35, 3.30, 3.30, 4.20],
        font_size=8.6,
        header_size=8.4,
    )
    add_text(slide, 0.65, 6.43, 11.9, 0.22, "Never compare LE vs logic-cell counts or headline TOPS as equivalent metrics; normalize the workload, precision, sparsity, clocks, power and tool version.", size=9.5, color=ORANGE, bold=True)
    add_citation(slide, "[R5], [R8], [R10], [R16], [R17] — official vendor product pages; claims remain vendor-stated until customer benchmark")

    # 16 — Competitive scorecard
    slide = new_slide(prs, "Altera vs AMD Xilinx: evidence-based battlecard", "08 / Competition", 16)
    score_rows = [
        ["Robotics SW", "ROS 2 controller + Drive-on-Chip reference stack", "KR260 + native ROS 2 + KRS + production K26 SOM", "AMD advantage for software-first/SOM buyers; counter with deterministic consolidation proof."],
        ["Vision IP", "45+ VVP cores; FPGA AI Suite; custom streaming fabric", "Vitis Vision/AI; KV260; Versal AI Engines", "Both credible. Win on measured end-to-end latency, power and engineering effort."],
        ["AI scale", "Agilex 3/5/7 portfolio; vendor claims up to 152.6 INT8 TOPS on A5 D", "Versal AI Edge vendor table: 5–202 dense INT8 TOPS", "Do not rank by TOPS alone; architectures, devices and assumptions differ."],
        ["Industrial TSN", "Agilex 5 SoC: three hardened 2.5G TSN MACs", "100M/1G TSN LogiCORE; broader industrial protocol ecosystem", "Lead with integration/BOM if hard TSN fits; validate exact protocol and topology."],
        ["Functional safety", "TÜV-reviewed FSDP/methodology; stated suitability up to SIL3", "TÜV SÜD-certified flows; IEC 61508 / ISO 13849 support", "Table stakes for both. Compare exact device/tool/IP certificate scope."],
        ["Cost / I/O", "Agilex 3: SoC option, MIPI, AI tensor DSP, 12.5G", "Spartan UltraScale+: up to 572 I/O, 16.3G, PCIe Gen4", "Use customer pinout + board-cost study. Neither wins every configuration."],
    ]
    add_table(
        slide,
        0.55,
        1.32,
        12.15,
        5.20,
        ["Criterion", "Altera evidence", "AMD Xilinx evidence", "Implication / honest position"],
        score_rows,
        [1.10, 3.08, 3.08, 4.89],
        font_size=7.6,
        header_size=7.8,
    )
    add_citation(slide, "[R4–R18] Official vendor sources. “Advantage” statements are sales assessments, not third-party benchmark conclusions.")

    # 17 — Competitive win plan
    slide = new_slide(prs, "How to win against AMD Xilinx: replace claims with customer evidence", "08 / Competition", 17)
    win_steps = [
        ("1  DISCOVER", ORANGE, "Installed device/tool flow? Decision owner? Workload? Pain: latency, power, I/O, BOM, safety or schedule?"),
        ("2  BASELINE", RED, "Capture AMD reference: exact device/board, tool version, model precision, interfaces, clocks and measured power."),
        ("3  PROVE", TEAL, "Run the same workload on Altera; publish reproducible scripts, resource use, latency distribution, power and BOM."),
        ("4  DE-RISK", BLUE, "Close IP gaps, migration effort, safety scope, supply/lifecycle and support plan with named DFAEs."),
        ("5  COMMERCIALIZE", GREEN, "Convert evaluation success into architecture freeze, DWIN evidence and production forecast."),
    ]
    for index, (label, accent_color, action) in enumerate(win_steps):
        y = 1.38 + index * 0.97
        add_box(slide, 0.55, y, 2.02, 0.72, fill="14213D", line=accent_color)
        add_text(slide, 0.78, y + 0.20, 1.58, 0.25, label, size=11, color=accent_color, bold=True)
        add_box(slide, 2.75, y, 9.95, 0.72, fill=NAVY_2, line=GRID)
        add_text(slide, 3.02, y + 0.14, 9.42, 0.42, action, size=11.5, bold=True)
    add_box(slide, 0.55, 6.38, 12.15, 0.35, fill="2B1D2F", line=ORANGE)
    add_text(slide, 0.78, 6.43, 11.62, 0.20, "Red line: do not use vendor headline TOPS, power or performance claims as an apples-to-apples result without reproducing the workload.", size=9, color=ORANGE, bold=True)

    # 18 — Ecosystem
    slide = new_slide(prs, "DFAE + ecosystem engagement: attach expertise to stage exits", "09 / Team execution", 18)
    columns = [
        ("DISCOVERY", "Sales + FAE", "Sponsor, use case, value, budget and decision process", RED),
        ("ARCHITECTURE", "FAE + specialist DFAE", "Block diagram, device fit, IP/tools and risk register", ORANGE),
        ("VALIDATION", "Customer + FAE + DFAE", "Evaluation results, issue closure and design-freeze evidence", BLUE),
        ("PRODUCTION", "Sales + FAE + channel", "DW evidence, forecast, supply path and production handoff", GREEN),
    ]
    for index, (stage, owners, evidence, accent_color) in enumerate(columns):
        x = 0.55 + index * 3.08
        add_box(slide, x, 1.48, 2.82, 2.62, fill="14213D", line=accent_color)
        add_text(slide, x + 0.18, 1.76, 2.46, 0.25, stage, size=11, color=accent_color, bold=True)
        add_text(slide, x + 0.18, 2.18, 2.46, 0.24, owners, size=12.5, bold=True)
        add_text(slide, x + 0.18, 2.72, 2.46, 0.94, evidence, size=11.5, color=PALE)
    add_box(slide, 0.55, 4.42, 12.15, 1.65)
    add_text(slide, 0.82, 4.72, 2.2, 0.22, "WEEKLY OPERATING CADENCE", size=9, color=TEAL, bold=True)
    cadence = [
        ("MON", "Top-5 stage/gap inspection"),
        ("WED", "Customer/DFAE action review"),
        ("FRI", "Evidence + CRM hygiene"),
        ("MONTH-END", "Pipeline creation + conversion scorecard"),
    ]
    for index, (when, action) in enumerate(cadence):
        x = 3.00 + index * 2.35
        add_text(slide, x, 4.70, 1.95, 0.20, when, size=8, color=MUTED, bold=True)
        add_text(slide, x, 5.00, 2.05, 0.62, action, size=11, bold=True)

    # 19 — Commitments / gaps
    slide = new_slide(prs, "Close the review with owners, evidence and missing inputs", "10 / Commitments", 19)
    add_box(slide, 0.55, 1.38, 7.30, 4.95)
    add_text(slide, 0.82, 1.70, 6.75, 0.26, "PROPOSED COMMITMENTS", size=10, color=TEAL, bold=True)
    commitments = [
        "Name next-stage evidence and due date for every top-5 opportunity.",
        "Qualify Weather Radar and CPU Interface Card from 0% or remove value from the active forecast.",
        "Create the 15th strategic opportunity with a 2027 customer sponsor and use case.",
        "Publish a direct-account + distributor coverage map; current source has no disty pipeline.",
        "Run one sourced, benchmark-led demand-creation motion per focus area and track evaluations created.",
    ]
    for index, commitment in enumerate(commitments):
        y = 2.18 + index * 0.76
        add_text(slide, 0.84, y, 0.35, 0.30, f"{index + 1}", size=15, color=ORANGE, bold=True)
        add_text(slide, 1.28, y, 6.10, 0.55, commitment, size=13, bold=True)
    add_box(slide, 8.10, 1.38, 4.60, 4.95, fill="14213D", line=RED)
    add_text(slide, 8.38, 1.70, 4.05, 0.26, "INPUTS TO COMPLETE BEFORE PRESENTING", size=10, color=RED, bold=True)
    missing = [
        "2026 target",
        "YTD actual / achieved DWINs",
        "Gap-closure value and dates",
        "Support activity history",
        "Customer market-share baseline",
        "Distributor targets/accounts",
        "Named DFAE owners",
    ]
    for index, item in enumerate(missing):
        y = 2.18 + index * 0.49
        add_text(slide, 8.40, y, 0.28, 0.22, "□", size=13, color=ORANGE, bold=True)
        add_text(slide, 8.78, y, 3.35, 0.28, item, size=11.5, bold=True)
    add_text(slide, 8.40, 5.76, 3.95, 0.34, "No invented numbers.\nFill, validate, commit.", size=13.5, color=TEAL, bold=True)

    # 20 — Data definitions
    slide = new_slide(prs, "Appendix: scope, definitions and data-quality notes", "Appendix", 20)
    notes = [
        ("Scope", "Rows where Technical Owner = Sahil Patni; 20 product lines consolidated by Opportunity ID into 14 opportunities."),
        ("Peak value", "Product-line Peak Value summed within each Opportunity ID. Source file does not encode currency."),
        ("Weighted value", "Consolidated peak value × source probability. Identify opportunities at 0% therefore contribute zero."),
        ("DWIN-dated", "Opportunity Design Win Date falls in the stated year. This is a scheduled date, not proof of an achieved design win."),
        ("Dates", "Source mixes Excel dates and text dates; both were normalized for analysis."),
        ("Coverage", "All Sahil records are “Altera Opportunity”; Distributor Account is blank. No channel pipeline can be inferred."),
        ("Not available", "Target, actual achievement, revenue/bookings, support history, market share, next actions, and named DFAE assignments."),
    ]
    for index, (label, note) in enumerate(notes):
        y = 1.36 + index * 0.72
        add_text(slide, 0.65, y, 1.65, 0.26, label.upper(), size=9, color=TEAL if index < 4 else ORANGE, bold=True)
        add_text(slide, 2.20, y, 10.15, 0.48, note, size=11.5, color=WHITE)
    add_text(slide, 0.65, 6.56, 11.9, 0.24, "Regenerate with: python3 qbr/generate_sahil_qbr.py", size=9, color=MUTED)

    # 21/22 — Reference appendix
    for slide_number, start in ((21, 0), (22, 9)):
        end = start + 9
        title = "References: market evidence and solution sources" if start == 0 else "References: competitive product and tool sources"
        slide = new_slide(prs, title, "Appendix / References", slide_number)
        for index, (reference_id, reference_title, url) in enumerate(REFERENCES[start:end]):
            y = 1.30 + index * 0.60
            add_text(slide, 0.62, y, 0.55, 0.22, reference_id, size=9, color=TEAL, bold=True)
            add_text(slide, 1.15, y, 4.40, 0.42, reference_title, size=8.2, color=WHITE, bold=True)
            add_text(slide, 5.68, y, 6.92, 0.42, url, size=7.1, color=PALE)
        add_text(slide, 0.65, 6.70, 11.9, 0.18, "Accessed 28 Jul 2026. Vendor specifications and performance figures are vendor-stated; validate against current datasheets and customer workloads.", size=7.5, color=ORANGE, bold=True)

    output.parent.mkdir(parents=True, exist_ok=True)
    prs.save(output)


def build_summary_workbook(
    line_items: list[dict[str, Any]],
    opportunities: list[dict[str, Any]],
    output: Path,
):
    workbook = Workbook()
    summary = workbook.active
    summary.title = "Executive Summary"

    total = sum(row["Peak Value"] for row in opportunities)
    weighted = sum(row["Weighted Value"] for row in opportunities)
    created_2026 = [row for row in opportunities if row["Created Date Parsed"] and row["Created Date Parsed"].year == 2026]
    dw_2026 = [row for row in opportunities if row["Design Win Date Parsed"] and row["Design Win Date Parsed"].year == 2026]
    metrics = [
        ("Metric", "Value", "Definition"),
        ("Distinct opportunities", len(opportunities), "Consolidated by Opportunity ID"),
        ("Product line items", len(line_items), "Rows where Technical Owner = Sahil Patni"),
        ("Direct-account customers", len({row["Account Name"] for row in opportunities}), "Distinct Account Name"),
        ("Peak pipeline", total, "Sum of consolidated Peak Value; currency absent"),
        ("Weighted pipeline", weighted, "Peak Value × Probability"),
        ("2026-created opportunities", len(created_2026), "Created Date in 2026"),
        ("2026-created peak value", sum(row["Peak Value"] for row in created_2026), "Peak Value"),
        ("2026 DWIN-dated opportunities", len(dw_2026), "Scheduled DWIN date in 2026; not achieved DWIN"),
        ("2026 DWIN-dated peak value", sum(row["Peak Value"] for row in dw_2026), "Peak Value"),
        ("2026 annual target", "INPUT REQUIRED", "Not present in source"),
        ("YTD actual achievement", "INPUT REQUIRED", "Not present in source"),
    ]
    for row in metrics:
        summary.append(row)

    opportunity_sheet = workbook.create_sheet("Opportunities")
    headers = [
        "Rank",
        "Opportunity ID",
        "Account",
        "Opportunity",
        "Stage",
        "Probability (%)",
        "Design Win Date",
        "Created Date",
        "Production Start Date",
        "Vertical",
        "Peak Value",
        "Weighted Value",
        "Product Count",
        "Products",
        "Suggested Next Gate",
    ]
    opportunity_sheet.append(headers)
    for rank, row in enumerate(opportunities, start=1):
        opportunity_sheet.append(
            [
                rank,
                row["Opportunity ID"],
                row["Account Name"],
                row["Opportunity Name"],
                row["Opportunity Stage"],
                row["Probability (%)"],
                row["Design Win Date Parsed"],
                row["Created Date Parsed"],
                row["Production Start Date Parsed"],
                row["Vertical Market"],
                row["Peak Value"],
                row["Weighted Value"],
                len(row["Products"]),
                "\n".join(str(product) for product in row["Products"]),
                suggested_gate(row),
            ]
        )

    source_sheet = workbook.create_sheet("Sahil Line Items")
    source_headers = list(line_items[0].keys())
    source_sheet.append(source_headers)
    for row in line_items:
        source_sheet.append([row[header] for header in source_headers])

    reference_sheet = workbook.create_sheet("Market References")
    reference_sheet.append(["ID", "Source", "URL", "Accessed", "Use"])
    reference_uses = {
        "R1": "Robotics market",
        "R2": "Industrial / APAC market",
        "R3": "Machine-vision market",
        "R4": "Altera robotics",
        "R5": "Altera Agilex 5",
        "R6": "AMD robotics",
        "R7": "Altera video / vision",
        "R8": "Altera AI software",
        "R9": "AMD vision",
        "R10": "AMD AI portfolio",
        "R11": "Altera industrial",
        "R12": "Altera TSN / HPS",
        "R13": "AMD industrial networking",
        "R14": "Altera functional safety",
        "R15": "AMD functional safety",
        "R16": "Altera cost-optimized portfolio",
        "R17": "AMD cost-optimized portfolio",
        "R18": "AMD development tools",
    }
    for reference_id, reference_title, url in REFERENCES:
        reference_sheet.append([reference_id, reference_title, url, date(2026, 7, 28), reference_uses[reference_id]])

    for sheet in workbook.worksheets:
        sheet.freeze_panes = "A2"
        sheet.auto_filter.ref = sheet.dimensions
        for cell in sheet[1]:
            cell.fill = PatternFill("solid", fgColor=BLUE)
            cell.font = Font(color="FFFFFF", bold=True)
            cell.alignment = Alignment(vertical="center")
        for row in sheet.iter_rows(min_row=2):
            for cell in row:
                cell.alignment = Alignment(vertical="top", wrap_text=True)
        for column_cells in sheet.columns:
            max_length = max(len(str(cell.value or "")) for cell in column_cells)
            sheet.column_dimensions[column_cells[0].column_letter].width = min(max(max_length + 2, 10), 44)
    for sheet in (summary, opportunity_sheet):
        for row in sheet.iter_rows(min_row=2):
            for cell in row:
                if isinstance(cell.value, (int, float)) and cell.column in ({2} if sheet == summary else {11, 12}):
                    cell.number_format = '#,##0.00'
    opportunity_sheet.column_dimensions["N"].width = 52
    opportunity_sheet.column_dimensions["O"].width = 48
    reference_sheet.column_dimensions["B"].width = 58
    reference_sheet.column_dimensions["C"].width = 90

    output.parent.mkdir(parents=True, exist_ok=True)
    workbook.save(output)


def build_notes(opportunities: list[dict[str, Any]], output: Path):
    total = sum(row["Peak Value"] for row in opportunities)
    weighted = sum(row["Weighted Value"] for row in opportunities)
    q4 = [
        row
        for row in opportunities
        if row["Design Win Date Parsed"]
        and date(2026, 10, 1) <= row["Design Win Date Parsed"] <= date(2026, 12, 31)
    ]
    reference_text = "\n".join(
        f"- **{reference_id}** — {reference_title}: {url}"
        for reference_id, reference_title, url in REFERENCES
    )
    text = f"""# Sahil FAE QBR — presenter notes

Review: {REVIEW_DATE.strftime("%d %B %Y")}, 12:00–13:00  
Prepared: {AS_OF.strftime("%d %B %Y")}  
Source: `Sahil Report.xlsx`

## Opening message

The available pipeline is meaningful—{fmt_value(total)} peak and {fmt_value(weighted)} weighted across
{len(opportunities)} distinct opportunities—but conversion is concentrated and target attainment cannot
be calculated from this file. The review should end with named stage-exit evidence, owners, and dates.

## Facts to land

- 20 Sahil-owned product lines consolidate to {len(opportunities)} opportunities across
  {len({row["Account Name"] for row in opportunities})} direct customers.
- {fmt_value(3_600_000)} is still Identify at 0% probability.
- Outdu AI contributes {fmt_value(4_125_000)}, or {4_125_000 / total:.1%} of peak pipeline, while still at Define.
- Four Q4 2026 DWIN-dated plays total {fmt_value(sum(row["Peak Value"] for row in q4))};
  their weighted value is {fmt_value(sum(row["Weighted Value"] for row in q4))}.
- The source contains 14—not 15—distinct opportunities. Use slot 15 as a concrete demand-creation commitment.
- Every Sahil line is marked `Altera Opportunity`; distributor account is blank.

## Market review talk track

### Robotics

- IFR recorded 542,000 global industrial-robot installations in 2024 and 4.664 million robots in
  operation. India installed 9,100 units, up 7%, ranking sixth globally; automotive represented 45%.
- AMD's strongest practical counter is not a single device specification: it is the KR260/K26 SOM
  path with native ROS 2 and the Kria Robotics Stack.
- The Altera response should be a measured sense-to-act demonstration combining deterministic ROS 2,
  TSN, motion/control, safety and sensor fusion—not a generic FPGA feature presentation.

### Video and vision

- Interact Analysis reported a 3.9% global machine-vision decline in 2024 and forecast 1.5% growth to
  $5.7 billion in 2025. Area-scan cameras were under pressure, including competition from APAC vendors.
- AMD can lead with KV260 ease of evaluation, Vitis libraries and Versal AI Engine scale.
- Altera should prove the complete ingest→ISP→AI→output pipeline using the customer's model and sensor:
  latency distribution, power, image quality, resources, BOM and engineering effort.

### Industrial

- Rockwell's APAC survey found 94% had invested or planned to invest in AI; quality control and process
  optimization were leading use cases, while cyber standards were broadly important.
- TSN and functional safety are credible capabilities for both AMD and Altera. Avoid claiming exclusivity.
- The specific Altera proof point is Agilex 5 SoC's three hardened 2.5G TSN MACs combined with
  Drive-on-Chip and the functional-safety methodology. Quantify system consolidation and certification work.

## Competitive positioning rules

1. Do not compare Altera logic elements directly with AMD system logic cells.
2. Do not compare headline TOPS without matching model, precision, sparsity, clocks, batch and power.
3. Treat vendor power/performance claims as vendor-stated until reproduced.
4. Capture the installed AMD device, board, tool version and workload before proposing migration.
5. Win with a reproducible customer benchmark and a named de-risk plan.

## Inputs required before presenting

1. 2026 annual target.
2. YTD actual achievement and the exact definition used (revenue, bookings, DWINs, or another measure).
3. Achieved 2026 DWIN count/value.
4. Support activities completed and open technical gaps.
5. Market-share baseline by key customer.
6. Distributor account targets and joint plans.
7. Named Sales, FAE, and DFAE owners for stage exits.

## Suggested close

“I will manage the portfolio by evidence, not activity: qualify the two 0% plays, close the Q4 stage
gates, create the fifteenth strategic opportunity, and run one repeatable 2027 demand-creation motion
for robotics/control, video/vision, and industrial platforms.”

## Important definitions

- Values are shown in source units because the workbook does not identify a currency.
- “DWIN-dated” means the scheduled Design Win Date falls in that year; it does not mean the design win
  has already been achieved.
- Proposed actions in the deck are planning recommendations inferred from stage/date/product data and
  should be validated with Sales and the customer.

## References

Accessed 28 July 2026.

{reference_text}
"""
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(text, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=Path("Sahil Report.xlsx"))
    parser.add_argument("--output-dir", type=Path, default=Path("qbr/output"))
    args = parser.parse_args()

    line_items, opportunities = read_pipeline(args.source)
    if not opportunities:
        raise SystemExit(f"No records found for Technical Owner = {OWNER!r}")

    build_presentation(opportunities, args.output_dir / "Sahil_QBR_2026-07-29.pptx")
    build_summary_workbook(line_items, opportunities, args.output_dir / "Sahil_QBR_Pipeline_Summary.xlsx")
    build_notes(opportunities, args.output_dir / "Sahil_QBR_Presenter_Notes.md")
    print(f"Generated QBR artifacts in {args.output_dir}")


if __name__ == "__main__":
    main()
