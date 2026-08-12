# C-DOT F-Tile SyncE Clock Clarification — Altera Responses

**Customer:** C-DOT, Bangalore (J Thulasi Ramu et al.)  
**Subject:** Clarification on F-Tile Reference Clock and 390.625 MHz SyncE Clock Distribution in Agilex M FPGA  
**Reference:** Agilex 7 FPGA M-Series Development Kit clock architecture (customer redraw, Page 6 / REF 1–4)  
**Prepared for:** Sahil Patni / Rushikesh Purohit — customer reply  

---

## Executive summary (for internal use)

| REF | One-line answer |
| --- | --- |
| REF 1 | **156.25 MHz (REFCLK-5)** = recommended Ethernet PMA / System PLL reference for all rates. **390.625 MHz (REFCLK-4)** = SyncE cleaned recovered-clock path (closes frequency lock after Si5518 jitter attenuation). |
| REF 2 | Same 390.625 MHz on **Global REFCLK-4** (all 4 FGT quads) and **Regional REFCLK-6** (Quad 2/3 only) for SyncE topology flexibility; kit demonstrates both. |
| REF 3 | Dual 156.25 MHz is **kit flexibility**, not a silicon requirement. One Global REFCLK-5 is enough if all quads share one rate/domain. |
| REF 4 | Si5518 is the kit’s SyncE/1588 master; fanout from that domain gives **system-wide frequency coherence**. Independent oscillators are OK on a customer board if SyncE coherence is needed only on Ethernet. |

---

## SyncE loop context (shared preamble — optional in email)

The **390.625 MHz** frequency is the natural RX PMA recovered clock (`o_clk_rec_div`) for Ethernet modes from **25GE through 400GE**, derived from the line rate divided by 66 (example: 25.78125 Gbps ÷ 66 = 390.625 MHz). For 10GE it is 156.25 MHz; for 40GE it is 312.5 MHz.

On the Agilex 7 M-Series Development Kit:

1. F-Tile outputs recovered SyncE clock (`o_clk_rec_div` / dedicated CDR path as applicable) toward the Si5518 (U92/U15).
2. Si5518 acts as the **IEEE 1588 / SyncE timing module**: jitter-attenuates and re-synthesizes a clean, traceable clock.
3. Clean clocks are redistributed to F-Tiles (and the rest of the board clock tree via Si5395/Si5391) to **close the SyncE frequency-locking loop** so TX remains frequency-locked to the RX recovered timing domain (ITU-T G.8261 / G.8262 / G.8264 usage model).

**Recommended Ethernet PMA reference remains 156.25 MHz** for essentially all Ethernet modes (and is required for FHT PMA and when AN/LT is enabled). The kit also wires **390.625 MHz** so SyncE/CPRI-style recovered-clock and cleanup topologies can be evaluated.

---

## REF 1 — Purpose of the 390.625 MHz F-Tile Reference Clock Input

**Customer question:**  
One 156.25 MHz clock from Si5518 (U92), jitter-attenuated by Si5395 (U14), connects to REFCLK-5 [Global]. This supports all Ethernet data rates. Why also connect 390.625 MHz from Si5518 to REFCLK-4 [Global]?

### Altera Response

The two reference clocks serve **different roles** on the Development Kit:

1. **156.25 MHz → REFCLK-5 [Global]**  
   - This is the **recommended FGT PMA / System PLL reference** for Ethernet Hard IP across supported rates (10GE / 25GE / 100GE / 200GE / 400GE, and multi-lane breakouts).  
   - It is the frequency customers should plan as the primary Ethernet transceiver reference in production designs.  
   - It is also the only supported reference when using **FHT PMA** or when **auto-negotiation and link training** are enabled.

2. **390.625 MHz → REFCLK-4 [Global]**  
   - This is the **SyncE cleaned recovered-clock path**.  
   - 390.625 MHz matches `o_clk_rec_div` for 25GE–400GE (SERDES rate ÷ 66 for the common FEC/mode cases).  
   - Si5518 locks to the F-Tile recovered SyncE clock, attenuates jitter, and returns a clean 390.625 MHz that is distributed on REFCLK-4 to the F-Tiles (U10 / U20 / U22 on the kit) to **close the SyncE TX↔RX frequency-lock loop**.  
   - Having both REFCLK-4 and REFCLK-5 allows the kit (and a flexible customer board) to run:  
     - free-running / local-oscillator Ethernet (156.25 MHz), and/or  
     - SyncE-locked Ethernet (cleaned recovered domain via Si5518).

**Design guidance for C-DOT:**  
For your 2×400GE / 4×200GE / 8×100GE / 16×25GE / 16×10GE + SyncE + PTP plan, provision:

- A **156.25 MHz** low-jitter reference to Global FGT REFCLK for PMA/System PLL.  
- A **SyncE cleanup PLL** (Si5518-class) that accepts F-Tile recovered clock and returns a cleaned reference into the same F-Tile REFCLK network used for TX.  
- Optional dedicated 390.625 MHz REFCLK routing if you want to mirror the kit’s SyncE evaluation topology; otherwise deriving cleaned **156.25 MHz** from the SyncE master for PMA refclk is the mainstream Ethernet IP recommendation.

---

## REF 2 — Two 390.625 MHz connections to F-Tile (U20) REFCLK-4 and REFCLK-6

**Customer question:**  
Why are two 390.625 MHz clocks from Si5518 connected to U20 REFCLK-4 [Global] and REFCLK-6 [Regional]?

### Altera Response

This is intentional **F-Tile reference-clock network flexibility**, not a requirement to drive both pins in every design.

Per F-Tile architecture:

| Pin (kit label) | Type | Accessible FGT quads |
| --- | --- | --- |
| REFCLK-4 (`refclk[4]`) | **Global** | Quad 0, 1, 2, 3 |
| REFCLK-6 (`refclk[6]`) | **Regional** | Quad 2, 3 only |

Reasons both are wired on the kit:

1. **Global REFCLK-4** — required when a SyncE-cleaned reference must reach **any / all quads**, including multi-quad spanning hard IP (e.g., 400GE uses lanes across quads and must use a refclk reachable by every quad in the interface).  
2. **Regional REFCLK-6** — serves **Quad 2 and Quad 3**, which are also the quads that support the **dedicated SyncE/CDR recovered-clock output pins** (`refclk[8]` / `refclk[9]`). This supports SyncE recovery + cleanup topologies localized to those quads.  
3. **Concurrent domains** — allows one quad-pair to use the SyncE-cleaned 390.625 MHz domain while other quads remain on a different reference (e.g., 156.25 MHz local).  
4. **Evaluation coverage** — the Development Kit exposes both Global and Regional SyncE-cleaned inputs so customers can validate pinout and IP placement options before freezing a production schematic.

**Design guidance:**  
Your board does **not** need both connections if architecture is fixed. Choose:

- **Global** if SyncE-cleaned refclk must feed multi-quad Ethernet (typical for 200GE/400GE).  
- **Regional (Quad 2/3)** if SyncE is confined to those quads and you want to free Global REFCLK pins for other rates/protocols.

---

## REF 3 — Two 156.25 MHz SyncE clocks to F-Tile (U22) REFCLK-5 and REFCLK-6

**Customer question:**  
Two 156.25 MHz SyncE clocks from Si5395 (U14) go to U22 REFCLK-5 [Global] and REFCLK-6 [Regional]. Since one Global can reach all four FGT quads, why two connections?

### Altera Response

You are correct: **one Global reference clock can be accessed by all four FGT quads**. A second 156.25 MHz connection is **not required by the silicon** for a single-rate, single-domain Ethernet use case.

On the Development Kit, both are provided for:

1. **Topology flexibility** — Global REFCLK-5 for tile-wide / multi-quad IP; Regional REFCLK-6 for Quad 2/3-only placements or independent clocking of that quad pair.  
2. **Multi-configuration bring-up** — the kit must support many Ethernet breakouts and SyncE experiments without respin; duplicate routing avoids REFCLK pin contention between demos.  
3. **Signal integrity / loading options** — splitting Global vs Regional sinks can be useful when characterizing different fanout and termination schemes.  
4. **Independent domains** — enables running different rates or SyncE vs non-SyncE references on different quad groups in the same tile.

**Design guidance for C-DOT:**  
For production, **a single 156.25 MHz Global REFCLK** (e.g., REFCLK-5) is sufficient when:

- all active FGT quads share the same reference frequency and timing domain, and  
- hard IP spanning multiple quads uses that Global refclk.

Add a Regional (or second Global) 156.25 MHz only if you need **independent clock domains** across quad groups or want SyncE isolation between interfaces.

---

## REF 4 — Rationale for using 390.625 MHz SyncE as source for the board clock distribution network

**Customer question:**  
Why is the Si5518 390.625 MHz SyncE clock used as the reference into Si5395/Si5391 to generate DDR5, HBM, NOC, FPGA I/O PLL, and SDM clocks, instead of independent sources? What are the benefits (frequency sync, phase, jitter, distribution, system timing)?

### Altera Response

On the Agilex 7 M-Series Development Kit, **Si5518 is the board-level SyncE / IEEE 1588 network synchronizer** (not only an Ethernet-local cleanup PLL). The kit therefore uses it as the **master timing source** for the clock tree:

- Si5518 locks to / generates the SyncE timing domain (including 390.625 MHz).  
- Si5395 / Si5391 devices **jitter-attenuate and fan out** integer-related derivatives (100 MHz, 125 MHz, 156.25 MHz, etc.) to DDR5, HBM/UIB, NOC, I/O PLL, SDM, and F-Tile Ethernet references.

### Benefits of this architecture (as implemented on the kit)

| Aspect | Benefit |
| --- | --- |
| **Frequency synchronization** | Entire board can be **frequency-coherent** with the SyncE network when Si5518 is locked to line-recovered timing. Ethernet TX and system clocks share one traceable domain. |
| **Phase / alignment** | Common master simplifies deterministic relationships between Ethernet MAC clocks, PTP timestamping paths, and system fabric clocks (important for SyncE + PTP demos). |
| **Jitter performance** | Network-synchronizer + jitter-attenuator chain (Si5518 → Si5395/Si5391) provides cleaned, low-jitter references suitable for transceiver and memory PLLs, rather than distributing the raw recovered clock. |
| **Clock distribution** | One high-quality master + fanout PLLs reduces oscillator count and keeps all domains integer-related, easing CDC and board BOM on an evaluation platform. |
| **System-level timing** | Matches the intended kit use case: **SyncE + PTP + multi-rate Ethernet** with a Skyworks Si5518 AccuTime-class timing solution. |

### Important clarification for customer production designs

Using the SyncE master as the **root of DDR5 / HBM / NOC / SDM clocks is a Development Kit architectural choice**, not a silicon mandate.

- **Required for SyncE compliance on Ethernet:** cleaned recovered clock must feed back as the **transceiver / Ethernet reference** so TX tracks RX within SyncE ppm limits.  
- **Optional for memory / NOC / SDM:** these interfaces do **not** inherently require SyncE. You may use **independent low-jitter oscillators** for DDR5, HBM, NOC, I/O PLL, and SDM if:  
  - SyncE/PTP coherence is needed only on the Ethernet timing domain, and  
  - you accept asynchronous boundaries (proper CDC) between Ethernet and memory/system clocks.

**Recommendation for C-DOT:**  
- Keep a **Si5518-class SyncE/1588 device** in the Ethernet recovered-clock cleanup loop.  
- Derive F-Tile Ethernet REFCLKs from that cleaned domain.  
- Choose either:  
  - **Kit-like coherent tree** (one SyncE master fans out to Ethernet + DDR/HBM/NOC) if you want system-wide frequency alignment, or  
  - **Split tree** (SyncE master for Ethernet/PTP only; independent XOs for memory/NOC/SDM) if you prefer isolation and simpler SyncE certification scope.

---

## Suggested email reply (customer-facing)

> Hi Thulasi Ramu,  
>  
> Thank you for the clear redraw of the Agilex 7 M-Series Development Kit clock connections and for the detailed REF 1–4 questions. Please find our responses below (also filled into your document template).  
>  
> **Background — 390.625 MHz SyncE path**  
> The 390.625 MHz frequency is the natural RX PMA recovered clock (`o_clk_rec_div`) for Ethernet modes from 25GE through 400GE (line rate ÷ 66). On the Development Kit, Si5518 (U92/U15) is the IEEE 1588 / SyncE timing module: it accepts the F-Tile recovered SyncE clock, jitter-attenuates it, and redistributes a clean clock back to the F-Tiles to close the SyncE frequency-locking loop. In parallel, 156.25 MHz remains the recommended Ethernet PMA / System PLL reference for all rates.  
>  
> **REF 1:** 156.25 MHz on REFCLK-5 is the primary Ethernet reference. 390.625 MHz on REFCLK-4 is the SyncE cleaned recovered-clock distribution path for closing TX↔RX frequency lock. Both are provided so free-running Ethernet and SyncE-locked Ethernet can be evaluated.  
>  
> **REF 2:** REFCLK-4 is Global (all four FGT quads); REFCLK-6 is Regional (Quad 2/3 only — also the SyncE dedicated CDR output quads). Dual 390.625 MHz routing is for SyncE topology flexibility and kit evaluation coverage; production boards need only the pin types required by their quad placement.  
>  
> **REF 3:** Correct — one Global 156.25 MHz can feed all four quads. The second (Regional) connection on the kit is for flexibility / multi-config bring-up, not a silicon requirement.  
>  
> **REF 4:** The kit uses Si5518 as the board SyncE/1588 master and fans out derivatives to DDR5/HBM/NOC/I/O PLL/SDM for system-wide frequency coherence and demo convenience. This is **not mandatory** for production: SyncE cleanup must close on the Ethernet REFCLK path; memory/NOC/SDM may use independent oscillators if SyncE coherence is not required outside Ethernet.  
>  
> We remain available for a follow-up call on your exact 2×QSFP-DD (2×400GE … 16×10GE) + SyncE + PTP clocking schematic before layout freeze.  
>  
> Regards,  
> Rushikesh / Sahil  
> Altera

---

## References (public)

1. F-Tile Ethernet Hard IP User Guide — Clocks; SyncE clock connections (`o_clk_rec_div`, cleanup PLL usage)  
2. F-Tile Architecture and PMA and FEC Direct PHY IP User Guide — FGT/System PLL reference clock network (Global / Regional / Local; `refclk[0]`–`refclk[9]`)  
3. Agilex 7 FPGA M-Series HBM2e Development Kit User Guide — Clock tree / Si5518 / Si5395  
4. ITU-T G.8261 / G.8262 / G.8264 — SyncE network timing model  

---

## Internal follow-ups (optional)

- Confirm with Apps whether C-DOT’s production schematic should prefer **cleaned 156.25 MHz** or **cleaned 390.625 MHz** as the FGT PMA `i_clk_ref` when SyncE is locked (official Ethernet IP recommendation is 156.25 MHz; kit wires both).  
- Note FGT documented refclk range **25–380 MHz**; treat 390.625 MHz REFCLK usage as kit SyncE/evaluation topology and validate against the specific IP parameter set before copying 1:1 into production.  
- Point customer to prior related forum thread: [Global Clock & Regional clock inputs in Agilex M FPGA](https://community.altera.com/discussions/fpga-device/global-clock--regional-clock-inputs-in-agilex-m-fpga/353673).
