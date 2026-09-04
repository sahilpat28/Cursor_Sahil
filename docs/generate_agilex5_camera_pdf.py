#!/usr/bin/env python3
"""Render the Agilex 5 camera bring-up Markdown guide as a printable PDF."""

from __future__ import annotations

import argparse
import html
import math
import re
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    KeepTogether,
    Flowable,
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
REVISION = "Revision 4.0  |  4 September 2026"


def inline_markup(text: str) -> str:
    """Turn the small Markdown subset used in the guide into ReportLab markup."""
    def format_plain(segment: str) -> str:
        escaped = html.escape(segment)
        escaped = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", escaped)

        def hyperlink(match: re.Match[str]) -> str:
            url = match.group(0)
            return f'<link href="{url}" color="#005a9c"><u>{url}</u></link>'

        return re.sub(r"https?://[^\s<]+", hyperlink, escaped)

    segments = re.split(r"(`[^`]+`)", text.strip())
    formatted = []
    for segment in segments:
        if segment.startswith("`") and segment.endswith("`"):
            formatted.append(f'<font face="Courier">{html.escape(segment[1:-1])}</font>')
        else:
            formatted.append(format_plain(segment))
    return "".join(formatted)


class ImplementationDiagram(Flowable):
    """Compact vector block diagram of the reference camera design."""

    height = 305

    def __init__(self, width: float) -> None:
        super().__init__()
        self.width = width
        self.height = 305

    def wrap(self, available_width: float, available_height: float) -> tuple[float, float]:
        self.width = available_width
        return available_width, self.height

    @staticmethod
    def _arrow(canvas, x1: float, y1: float, x2: float, y2: float, *, dashed: bool = False) -> None:
        canvas.saveState()
        canvas.setStrokeColor(colors.HexColor("#41515e"))
        canvas.setLineWidth(1)
        if dashed:
            canvas.setDash(3, 2)
        canvas.line(x1, y1, x2, y2)
        canvas.setDash()
        angle = math.atan2(y2 - y1, x2 - x1)
        arrow_length = 5
        for delta in (math.pi * 0.82, -math.pi * 0.82):
            canvas.line(
                x2,
                y2,
                x2 + arrow_length * math.cos(angle + delta),
                y2 + arrow_length * math.sin(angle + delta),
            )
        canvas.restoreState()

    @staticmethod
    def _box(
        canvas,
        x: float,
        y: float,
        width: float,
        height: float,
        label: str,
        *,
        fill: str,
        text: str = "#17212b",
        font_size: float = 5.7,
    ) -> None:
        canvas.saveState()
        canvas.setFillColor(colors.HexColor(fill))
        canvas.setStrokeColor(colors.HexColor("#597384"))
        canvas.roundRect(x, y, width, height, 3, fill=1, stroke=1)
        canvas.setFillColor(colors.HexColor(text))
        canvas.setFont("Helvetica-Bold", font_size)
        lines = label.split("\n")
        line_height = font_size + 1.5
        baseline = y + (height + (len(lines) - 1) * line_height) / 2 - font_size * 0.35
        for offset, line in enumerate(lines):
            canvas.drawCentredString(x + width / 2, baseline - offset * line_height, line)
        canvas.restoreState()

    def draw(self) -> None:
        canvas = self.canv
        width = self.width

        canvas.saveState()
        canvas.setFillColor(colors.HexColor("#f0f7fb"))
        canvas.setStrokeColor(colors.HexColor("#9eb5c4"))
        canvas.roundRect(0, 86, width, 196, 5, fill=1, stroke=1)
        canvas.setFillColor(colors.HexColor("#164e70"))
        canvas.setFont("Helvetica-Bold", 8)
        canvas.drawString(8, 268, "PROGRAMMABLE LOGIC (FPGA) — 4Kp30 VIDEO AND AI DATA PATH")

        boxes = {
            "mipi": (70, 166, 54, 54),
            "selector": (131, 166, 54, 54),
            "isp": (192, 166, 54, 54),
            "prep": (253, 166, 54, 54),
            "ai": (314, 166, 70, 54),
            "overlay": (391, 166, 44, 54),
            "dp": (442, 166, 43, 54),
        }
        camera_x, camera_width = 7, 56
        self._box(canvas, camera_x, 220, camera_width, 35, "Camera 0\nIMX678C", fill="#dff3e5")
        self._box(canvas, camera_x, 128, camera_width, 35, "Camera 1\nIMX678C", fill="#dff3e5")
        self._box(canvas, *boxes["mipi"], "MIPI D-PHY\nCSI-2 Rx", fill="#d9ecf7")
        self._box(canvas, *boxes["selector"], "Multi-sensor\nselector", fill="#d9ecf7")
        self._box(canvas, *boxes["isp"], "ISP\nDemosaic • AE\nAWB • ANR", fill="#d9ecf7", font_size=5.1)
        self._box(canvas, *boxes["prep"], "AI pre-\nprocessing", fill="#d9ecf7")
        self._box(canvas, *boxes["ai"], "FPGA AI Suite\nYOLOv8n\nDetect / Pose", fill="#0b6f9c", text="#ffffff")
        self._box(canvas, *boxes["overlay"], "Overlay\nframe\nbuffer", fill="#e7ddf5", font_size=5.1)
        self._box(canvas, *boxes["dp"], "DP Tx\n4Kp30\nDisplay", fill="#dff3e5", font_size=5.1)

        self._arrow(canvas, 63, 237, 70, 204)
        self._arrow(canvas, 63, 145, 70, 182)
        for source, target in zip(
            ("mipi", "selector", "isp", "prep", "ai", "overlay"),
            ("selector", "isp", "prep", "ai", "overlay", "dp"),
        ):
            x1, y1, w1, h1 = boxes[source]
            x2, y2, _, h2 = boxes[target]
            self._arrow(canvas, x1 + w1, y1 + h1 / 2, x2, y2 + h2 / 2)

        canvas.setFillColor(colors.HexColor("#164e70"))
        canvas.setFont("Helvetica-Bold", 8)
        canvas.drawString(8, 70, "HPS / STORAGE / CONTROL PLANE")
        self._box(
            canvas,
            100,
            27,
            264,
            34,
            "HPS Linux  •  Camera + ISP configuration  •  AI scheduling/results  •  Web GUI",
            fill="#dce6ee",
            font_size=5.7,
        )
        self._box(canvas, 7, 27, 77, 34, "microSD\nLinux + models", fill="#f3ead1")
        self._box(canvas, 384, 27, 101, 34, "QSPI\nFPGA configuration", fill="#f3ead1")
        self._arrow(canvas, 84, 44, 100, 44)
        self._arrow(canvas, 434, 61, 420, 166)
        self._arrow(canvas, 220, 61, 220, 166, dashed=True)
        self._arrow(canvas, 349, 61, 349, 166, dashed=True)

        canvas.setFillColor(colors.HexColor("#41515e"))
        canvas.setFont("Helvetica", 6.2)
        canvas.drawString(8, 9, "Solid arrows: configuration/data flow     Dashed arrows: HPS control     Ethernet provides browser access to the HPS web UI")
        canvas.restoreState()


def footer(canvas, document) -> None:
    canvas.saveState()
    width, _ = A4
    canvas.setStrokeColor(colors.HexColor("#b7c4ce"))
    canvas.line(18 * mm, 13 * mm, width - 18 * mm, 13 * mm)
    canvas.setFillColor(colors.HexColor("#41515e"))
    canvas.setFont("Helvetica", 7.5)
    canvas.drawString(18 * mm, 8.5 * mm, f"{REVISION}  •  Agilex 5 Camera + AI Bring-Up")
    canvas.drawRightString(width - 18 * mm, 8.5 * mm, f"Page {document.page}")
    canvas.restoreState()


def later_page_header(canvas, document) -> None:
    canvas.saveState()
    width, height = A4
    canvas.setFillColor(colors.HexColor("#41515e"))
    canvas.setFont("Helvetica-Bold", 7.5)
    canvas.drawString(18 * mm, height - 10.5 * mm, "AGILEX 5 CAMERA + AI  |  TECHNICAL FIELD GUIDE")
    canvas.setStrokeColor(colors.HexColor("#b7c4ce"))
    canvas.line(18 * mm, height - 12.5 * mm, width - 18 * mm, height - 12.5 * mm)
    canvas.restoreState()
    footer(canvas, document)


def make_styles() -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "GuideTitle",
            parent=base["Title"],
            fontName="Helvetica-Bold",
            fontSize=24,
            leading=29,
            textColor=colors.HexColor("#0b3954"),
            spaceAfter=3 * mm,
        ),
        "eyebrow": ParagraphStyle(
            "GuideEyebrow",
            fontName="Helvetica-Bold",
            fontSize=8,
            leading=10,
            textColor=colors.HexColor("#0b6f9c"),
            spaceAfter=2 * mm,
            tracking=1.25,
        ),
        "subtitle": ParagraphStyle(
            "GuideSubtitle",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=11,
            leading=14,
            textColor=colors.HexColor("#41515e"),
            spaceAfter=5 * mm,
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
            fontSize=7.8,
            leading=9.6,
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
        "code_label": ParagraphStyle(
            "GuideCodeLabel",
            fontName="Helvetica-Bold",
            fontSize=6.5,
            leading=8,
            textColor=colors.white,
            tracking=0.8,
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
            language = line[3:].strip().upper()
            code_lines = []
            index += 1
            while index < len(lines) and not lines[index].startswith("```"):
                code_lines.append(lines[index])
                index += 1
            longest_line = max((len(code_line) for code_line in code_lines), default=1)
            code_style = ParagraphStyle(
                "SizedGuideCode",
                parent=styles["code"],
                fontSize=max(6.4, min(7.8, (body_width - 10 * mm) / (longest_line * 0.6))),
                leading=max(7.8, min(9.6, (body_width - 10 * mm) / (longest_line * 0.6) + 1.8)),
            )
            label = "HOST TERMINAL COMMANDS" if language == "BASH" else "EXPECTED OUTPUT / REFERENCE"
            code_table = Table(
                [
                    [Paragraph(label, styles["code_label"])],
                    [XPreformatted(html.escape("\n".join(code_lines)), code_style)],
                ],
                colWidths=[body_width],
                style=TableStyle(
                    [
                        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#164e70")),
                        ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#f0f4f7")),
                        ("BOX", (0, 0), (-1, -1), 0.45, colors.HexColor("#9eb5c4")),
                        ("LEFTPADDING", (0, 0), (-1, -1), 2.2 * mm),
                        ("RIGHTPADDING", (0, 0), (-1, -1), 2.2 * mm),
                        ("TOPPADDING", (0, 0), (-1, 0), 1.1 * mm),
                        ("BOTTOMPADDING", (0, 0), (-1, 0), 1.1 * mm),
                        ("TOPPADDING", (0, 1), (-1, -1), 2 * mm),
                        ("BOTTOMPADDING", (0, 1), (-1, -1), 2 * mm),
                    ]
                ),
            )
            story.append(KeepTogether([code_table]))
            story.append(Spacer(1, 2.2 * mm))
            index += 1
            continue

        if line.strip() == "<!-- implementation-diagram -->":
            story.append(ImplementationDiagram(body_width))
            story.append(Spacer(1, 2.5 * mm))
            index += 1
            continue

        if line.startswith("|"):
            table_rows = []
            while index < len(lines) and lines[index].startswith("|"):
                table_rows.append(lines[index])
                index += 1
            table = table_from_markdown(table_rows, body_width, styles)
            if len(table_rows) > 12:
                story.append(table)
            else:
                story.append(KeepTogether([table]))
            story.append(Spacer(1, 2.2 * mm))
            continue

        if line.strip() == "<!-- pagebreak -->":
            story.append(PageBreak())
            index += 1
            continue

        if line.startswith("# "):
            if not first_title:
                story.append(PageBreak())
            story.append(Paragraph("TECHNICAL FIELD GUIDE", styles["eyebrow"]))
            story.append(Paragraph(inline_markup(line[2:]), styles["title"]))
            story.append(
                Paragraph(
                    "Field-proven deployment, AI model compilation, and validation procedure for the "
                    "Altera Agilex 5 FPGA E-Series 065B Modular Development Kit.",
                    styles["subtitle"],
                )
            )
            story.append(
                Table(
                    [[Paragraph(REVISION, styles["table"])]],
                    colWidths=[body_width],
                    style=TableStyle(
                        [
                            ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#e6f1f7")),
                            ("LINEBEFORE", (0, 0), (0, -1), 2, colors.HexColor("#0b6f9c")),
                            ("TEXTCOLOR", (0, 0), (-1, -1), colors.HexColor("#164e70")),
                            ("LEFTPADDING", (0, 0), (-1, -1), 3.5 * mm),
                            ("RIGHTPADDING", (0, 0), (-1, -1), 3.5 * mm),
                            ("TOPPADDING", (0, 0), (-1, -1), 2 * mm),
                            ("BOTTOMPADDING", (0, 0), (-1, -1), 2 * mm),
                        ]
                    ),
                )
            )
            story.append(Spacer(1, 4 * mm))
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
            warning = "warning" in line.lower()
            background = colors.HexColor("#fff3db") if warning else colors.HexColor("#e6f1f7")
            border = colors.HexColor("#be6d00") if warning else colors.HexColor("#0b6f9c")
            story.append(
                Table(
                    [[callout]],
                    colWidths=[body_width],
                    style=TableStyle(
                        [
                            ("BACKGROUND", (0, 0), (-1, -1), background),
                            ("LINEBEFORE", (0, 0), (0, -1), 2, border),
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
    document.build(story, onFirstPage=footer, onLaterPages=later_page_header)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    render(args.source, args.output)
    print(args.output)


if __name__ == "__main__":
    main()
