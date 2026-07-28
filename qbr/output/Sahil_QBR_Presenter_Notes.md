# Sahil FAE QBR — presenter notes

Review: 29 July 2026, 12:00–13:00  
Prepared: 27 July 2026  
Sources: `Sahil Report.xlsx`, `Sahil-Open Pipeline-2026.xlsx`,
`Sahil-Open Pipeline-2027.xlsx`

## Opening message

The uploaded open-pipeline exports contain 12 qualified opportunities:
8.22M peak and 2.51M weighted. The master report contains another
2 Identify / 0% plays worth
3.60M; these are not in either open export.
Target attainment still cannot be calculated because target and actual-achievement data are absent.

The deck is strong enough to expose the issues, but the execution system is not yet ready to scale.
Only Sahil is named; no Arrow or Macnica specialist is committed, no distributor-linked opportunity is
present in the source, and solution/demo readiness has not been verified.

## Facts to land

- The 2026 open export contains 1 Sahil opportunity worth
  4.12M.
- The 2027 open export contains 11 Sahil opportunities worth
  4.09M.
- Combined qualified open pipeline is 8.22M across
  6 direct customers.
- 3.60M remains Identify at 0% outside
  both open exports, taking the total discovered portfolio to 11.82M.
- Outdu AI contributes 4.12M, or 50.2% of qualified open value.
- Four Q4 2026 DWIN-dated plays total 5.04M;
  their weighted value is 1.26M.
- The source contains 14—not 15—distinct opportunities. Use slot 15 as a concrete demand-creation commitment.
- Every qualified Sahil opportunity is marked `Altera Opportunity`; distributor account is blank.
- Treat “2026” and “2027” as the uploaded planning-bucket labels. They are not synonymous with Design
  Win Date year; the 2027 export contains some opportunities with 2026 DWIN dates.

## Altera solution story

Lead with complete, demonstrable solution paths:

- **Robotics/control:** ROS Consolidated Robot Controller, Drive-on-Chip, Drive-on-Chip with PLC,
  3×2.5G TSN example, Sensor Fusion Platform and the functional-safety flow.
- **Camera/AI:** Holoscan Sensor Bridge (MIPI to 10GbE), 4Kp60 Multi-Sensor HDR Camera,
  4Kp30 Multi-Sensor Camera with AI, Smart Camera Demo Kit, Video and Vision Processing Suite,
  FPGA AI Suite and MIPI CSI-2.
- **Partner platforms:** Arrow Eagle Board; Macnica Sulphur Agilex 5 kit and MEP100 ST2110
  SmartNIC; Critical Link vision modules and other ecosystem IP.

Be precise: NVIDIA owns Holoscan technology; Altera provides FPGA integration/reference designs.
Also verify access, release maturity, kit availability and certification scope before promising a
solution to a customer.

## Joint Altera–Arrow–Macnica model

This cannot be a Sahil-only program.

- **Altera — Sahil:** program and solution lead; architecture, benchmark method, segment message and
  specialist-DFAE escalation.
- **Arrow — name by 05 August:** at least one robotics/AI/camera-capable technical specialist;
  Arrow account map, kits/samples, workshops and opportunity follow-up.
- **Macnica — name by 05 August:** at least one robotics/AI/camera-capable technical specialist;
  Macnica account map, Sulphur/MEP100/video ecosystem, evaluations and integration support.
- **Readiness by 14 August:** at least one working robotics demo path and one working camera/AI demo
  path, with owners and repeatable benchmark instructions.
- **Targeting by 31 August:** 30 named accounts—15 Arrow and 15 Macnica—with sponsor, use case,
  installed competition and next action.
- **Proposed Q4 scorecard:** 12 workshops, 8 evaluations, 6 qualified opportunities,
  3 Develop/Design-stage plays and 2 DWINs. These targets need explicit review approval.

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

- **R1** — International Federation of Robotics, World Robotics 2025 press release: https://ifr.org/ifr-press-releases/news/global-robot-demand-in-factories-doubles-over-10-years
- **R2** — Rockwell Automation, 2025 State of Smart Manufacturing — APAC findings: https://www.rockwellautomation.com/en-sg/company/news/press-releases/apac-sosm-2025.html
- **R3** — Interact Analysis, Machine Vision return-to-growth forecast, June 2025: https://interactanalysis.com/return-to-growth-forecast-for-machine-vision-in-2025-despite-us-tariffs/
- **R4** — Altera, Robotics Solutions Stack: https://www.altera.com/fpga-solutions/robotics-solutions-stack
- **R5** — Altera, Agilex 5 FPGA and SoC FPGA overview: https://www.altera.com/products/fpga/agilex/5
- **R6** — AMD, Kria KR260 robotics platform and Kria Robotics Stack: https://www.amd.com/en/products/system-on-modules/kria/k26/robotics.html
- **R7** — Altera, Video and Vision Processing Suite: https://www.altera.com/products/ip/po-3150/video-and-vision-processing-suite
- **R8** — Altera, FPGA AI Suite: https://www.altera.com/products/development-tools/fpga-ai-suite
- **R9** — AMD, Kria KV260 Vision AI Starter Kit: https://www.amd.com/en/products/system-on-modules/kria/k26/kv260-vision-starter-kit.html
- **R10** — AMD, Versal AI Edge Series: https://www.amd.com/en/products/adaptive-socs-and-fpgas/versal/ai-edge-series.html
- **R11** — Altera, Industrial solutions: https://www.altera.com/fpga-solutions/industrial
- **R12** — Altera, Agilex 5 SoC HPS features including three 2.5G TSN Ethernet MACs: https://docs.altera.com/r/docs/762191/current/agilextm-5-fpgas-and-socs-device-overview/additional-features-for-agilextm-5-socs
- **R13** — AMD, Industrial Networking solutions: https://www.amd.com/en/solutions/industrial/industrial-networking.html
- **R14** — Altera, Agilex 5 Functional Safety: https://docs.altera.com/api/khub/documents/xhgkkZ1PZaLEHFnNiUlbNA/content
- **R15** — AMD, Functional Safety: https://www.amd.com/en/products/adaptive-socs-and-fpgas/technologies/functional-safety.html
- **R16** — Altera, Agilex 3 FPGA and SoC FPGA overview: https://www.altera.com/products/fpga/agilex/3
- **R17** — AMD, Spartan UltraScale+ FPGA overview: https://www.amd.com/en/products/adaptive-socs-and-fpgas/fpga/spartan-ultrascale-plus.html
- **R18** — AMD, Vitis unified software platform: https://www.amd.com/en/products/software/adaptive-socs-and-fpgas/vitis.html
- **R19** — Altera, Video Solutions Stack: https://www.altera.com/fpga-solutions/video-solutions-stack
- **R20** — Altera, Sensor Interfaces including Holoscan Sensor Bridge: https://www.altera.com/fpga-solutions/sensory-interfaces
