#!/usr/bin/env python3
"""Render the Agilex 5 camera bring-up Markdown guide as a printable PDF."""

from __future__ import annotations

import argparse
import html
import re
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
    XPreformatted,
)


ROOT = Path(__file__).resolve().parent
DEFAULT_SOURCE = ROOT / "agilex5-camera-4kp30-bring-up.md"
DEFAULT_OUTPUT = ROOT / "agilex5-camera-4kp30-bring-up.pdf"


def inline_markup(text: str) -> str:
    """Turn the small Markdown subset used in the guide into ReportLab markup."""
    escaped = html.escape(text.strip())
    escaped = re.sub(r"`([^`]+)`", r'<font face="Courier">\1</font>', escaped)
    escaped = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", escaped)
    return escaped


def footer(canvas, document) -> None:
    canvas.saveState()
    width, _ = A4
    canvas.setStrokeColor(colors.HexColor("#b7c4ce"))
    canvas.line(18 * mm, 13 * mm, width - 18 * mm, 13 * mm)
    canvas.setFillColor(colors.HexColor("#41515e"))
    canvas.setFont("Helvetica", 7.5)
    canvas.drawString(18 * mm, 8.5 * mm, "Agilex 5 E-Series 065B 4Kp30 Camera + AI Bring-Up")
    canvas.drawRightString(width - 18 * mm, 8.5 * mm, f"Page {document.page}")
    canvas.restoreState()


def make_styles() -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "GuideTitle",
            parent=base["Title"],
            fontName="Helvetica-Bold",
            fontSize=23,
            leading=28,
            textColor=colors.HexColor("#0b3954"),
            spaceAfter=6 * mm,
        ),
        "h2": ParagraphStyle(
            "GuideH2",
            parent=base["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=14,
            leading=17,
            textColor=colors.HexColor("#0b3954"),
            spaceBefore=5 * mm,
            spaceAfter=2.5 * mm,
            keepWithNext=True,
        ),
        "h3": ParagraphStyle(
            "GuideH3",
            parent=base["Heading3"],
            fontName="Helvetica-Bold",
            fontSize=11,
            leading=14,
            textColor=colors.HexColor("#164e70"),
            spaceBefore=3.5 * mm,
            spaceAfter=1.5 * mm,
            keepWithNext=True,
        ),
        "body": ParagraphStyle(
            "GuideBody",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=9.3,
            leading=12.2,
            spaceAfter=2.1 * mm,
        ),
        "bullet": ParagraphStyle(
            "GuideBullet",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=9.3,
            leading=12.2,
            leftIndent=5 * mm,
            firstLineIndent=-3.4 * mm,
            spaceAfter=1.1 * mm,
        ),
        "code": ParagraphStyle(
            "GuideCode",
            fontName="Courier",
            fontSize=6.8,
            leading=8.4,
            leftIndent=3.2 * mm,
            rightIndent=2 * mm,
            textColor=colors.HexColor("#17212b"),
        ),
        "table": ParagraphStyle(
            "GuideTable",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=7.7,
            leading=9.5,
        ),
    }


def table_from_markdown(rows: list[str], body_width: float, styles: dict[str, ParagraphStyle]) -> Table:
    values = []
    for row in rows:
        cells = [cell.strip() for cell in row.strip().strip("|").split("|")]
        if all(re.fullmatch(r":?-{3,}:?", cell.replace(" ", "")) for cell in cells):
            continue
        values.append([Paragraph(inline_markup(cell), styles["table"]) for cell in cells])

    table = Table(values, colWidths=[body_width * 0.31, body_width * 0.69], repeatRows=1)
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#0b3954")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#f4f7f9")),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.HexColor("#f4f7f9"), colors.white]),
                ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#b7c4ce")),
                ("LEFTPADDING", (0, 0), (-1, -1), 2.3 * mm),
                ("RIGHTPADDING", (0, 0), (-1, -1), 2.3 * mm),
                ("TOPPADDING", (0, 0), (-1, -1), 1.7 * mm),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 1.7 * mm),
            ]
        )
    )
    return table


def build_story(markdown: str, body_width: float, styles: dict[str, ParagraphStyle]) -> list:
    story = []
    lines = markdown.splitlines()
    index = 0
    first_title = True

    while index < len(lines):
        line = lines[index]

        if not line.strip():
            index += 1
            continue

        if line.startswith("```"):
            code_lines = []
            index += 1
            while index < len(lines) and not lines[index].startswith("```"):
                code_lines.append(lines[index])
                index += 1
            longest_line = max((len(code_line) for code_line in code_lines), default=1)
            code_style = ParagraphStyle(
                "SizedGuideCode",
                parent=styles["code"],
                fontSize=max(5.1, min(6.8, (body_width - 10 * mm) / (longest_line * 0.6))),
                leading=max(6.4, min(8.4, (body_width - 10 * mm) / (longest_line * 0.6) + 1.6)),
            )
            story.append(
                Table(
                    [[XPreformatted(html.escape("\n".join(code_lines)), code_style)]],
                    colWidths=[body_width],
                    style=TableStyle(
                        [
                            ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#f0f4f7")),
                            ("BOX", (0, 0), (-1, -1), 0.45, colors.HexColor("#b7c4ce")),
                            ("LEFTPADDING", (0, 0), (-1, -1), 2.2 * mm),
                            ("RIGHTPADDING", (0, 0), (-1, -1), 2.2 * mm),
                            ("TOPPADDING", (0, 0), (-1, -1), 2 * mm),
                            ("BOTTOMPADDING", (0, 0), (-1, -1), 2 * mm),
                        ]
                    ),
                )
            )
            story.append(Spacer(1, 2.2 * mm))
            index += 1
            continue

        if line.startswith("|"):
            table_rows = []
            while index < len(lines) and lines[index].startswith("|"):
                table_rows.append(lines[index])
                index += 1
            story.append(table_from_markdown(table_rows, body_width, styles))
            story.append(Spacer(1, 2.2 * mm))
            continue

        if line.startswith("# "):
            if not first_title:
                story.append(PageBreak())
            story.append(Paragraph(inline_markup(line[2:]), styles["title"]))
            story.append(
                Paragraph(
                    "Printable Linux-host procedure for the Altera Agilex 5 FPGA E-Series 065B "
                    "Modular Development Kit.",
                    ParagraphStyle(
                        "Subtitle",
                        parent=styles["body"],
                        fontSize=11,
                        leading=14,
                        textColor=colors.HexColor("#41515e"),
                        spaceAfter=8 * mm,
                    ),
                )
            )
            first_title = False
            index += 1
            continue

        if line.startswith("## "):
            story.append(Paragraph(inline_markup(line[3:]), styles["h2"]))
            index += 1
            continue

        if line.startswith("### "):
            story.append(Paragraph(inline_markup(line[4:]), styles["h3"]))
            index += 1
            continue

        if line.startswith("> "):
            callout = Paragraph(inline_markup(line[2:]), styles["body"])
            story.append(
                Table(
                    [[callout]],
                    colWidths=[body_width],
                    style=TableStyle(
                        [
                            ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#e6f1f7")),
                            ("LINEBEFORE", (0, 0), (0, -1), 2, colors.HexColor("#0b6f9c")),
                            ("LEFTPADDING", (0, 0), (-1, -1), 3.5 * mm),
                            ("RIGHTPADDING", (0, 0), (-1, -1), 3.5 * mm),
                            ("TOPPADDING", (0, 0), (-1, -1), 2.5 * mm),
                            ("BOTTOMPADDING", (0, 0), (-1, -1), 2 * mm),
                        ]
                    ),
                )
            )
            story.append(Spacer(1, 2.3 * mm))
            index += 1
            continue

        if re.match(r"^\s*[-*] ", line):
            story.append(Paragraph(f"• {inline_markup(line.lstrip()[2:])}", styles["bullet"]))
            index += 1
            continue

        if re.match(r"^\d+\. ", line):
            number, text = line.split(".", 1)
            story.append(Paragraph(f"{number}. {inline_markup(text)}", styles["body"]))
            index += 1
            continue

        paragraph = [line.strip()]
        index += 1
        while (
            index < len(lines)
            and lines[index].strip()
            and not lines[index].startswith(("#", ">", "```", "|"))
            and not re.match(r"^\s*[-*] ", lines[index])
            and not re.match(r"^\d+\. ", lines[index])
        ):
            paragraph.append(lines[index].strip())
            index += 1
        story.append(Paragraph(inline_markup(" ".join(paragraph)), styles["body"]))

    return story


def render(source: Path, output: Path) -> None:
    styles = make_styles()
    output.parent.mkdir(parents=True, exist_ok=True)
    document = SimpleDocTemplate(
        str(output),
        pagesize=A4,
        rightMargin=18 * mm,
        leftMargin=18 * mm,
        topMargin=17 * mm,
        bottomMargin=19 * mm,
        title="Agilex 5 E-Series 065B 4Kp30 Camera + AI Bring-Up",
        author="Altera FPGA bring-up notes",
    )
    story = build_story(source.read_text(encoding="utf-8"), document.width, styles)
    document.build(story, onFirstPage=footer, onLaterPages=footer)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    render(args.source, args.output)
    print(args.output)


if __name__ == "__main__":
    main()
