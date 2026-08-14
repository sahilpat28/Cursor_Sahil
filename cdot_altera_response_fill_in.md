# Altera Responses — Fill-in for Customer Document  
# (F-Tile_Clock_Queries_Altera.pdf — REF 1 to REF 4)

Paste the text under each “Altera Response:” heading into the customer document.

---

## REF 1: Purpose of the 390.625 MHz F-Tile Reference Clock Input

**Altera Response:**

The 156.25 MHz clock on REFCLK-5 [Global] is the recommended FGT PMA / System PLL reference for all Ethernet data rates on the Development Kit and in production designs. It is also the required reference when using FHT PMA or when auto-negotiation and link training are enabled.

The 390.625 MHz clock on REFCLK-4 [Global] is provided for the Synchronous Ethernet (SyncE) cleaned recovered-clock path. For Ethernet modes from 25GE through 400GE, 390.625 MHz is the natural RX PMA recovered clock frequency (o_clk_rec_div = SERDES line rate ÷ 66; e.g., 25.78125 Gbps ÷ 66 = 390.625 MHz).

On the kit, Si5518 (U92/U15) is the IEEE 1588 / SyncE timing module. It receives the F-Tile SyncE recovered clock, jitter-attenuates it, and re-synthesizes a clean 390.625 MHz output. That cleaned clock is distributed back to the F-Tiles on REFCLK-4 to close the SyncE frequency-locking loop so the transmit reference remains frequency-traceable to the receive recovered timing domain (ITU-T G.8261/G.8262/G.8264 usage model).

In summary: REFCLK-5 (156.25 MHz) supports general Ethernet PMA clocking; REFCLK-4 (390.625 MHz) supports SyncE cleanup / re-lock evaluation. Both are present so free-running Ethernet and SyncE-locked Ethernet topologies can be exercised on the same board.

---

## REF 2: Two 390.625 MHz connections to F-Tile (U20) reference Clock Inputs

**Altera Response:**

Both connections are intentional Development Kit flexibility based on the F-Tile FGT reference-clock network; both pins are not required in every customer design.

- REFCLK-4 is a Global reference clock and is accessible by all four FGT quads (Quad 0–3). Use Global when the SyncE-cleaned reference must feed multi-quad spanning hard IP (for example 400GE) or any quad on the tile.
- REFCLK-6 is a Regional reference clock and is accessible by Quad 2 and Quad 3 only. Quads 2 and 3 are also the quads that support the dedicated SyncE/CDR recovered-clock output pins (refclk[8]/refclk[9]). The Regional path therefore supports SyncE recovery and cleanup topologies localized to those quads.

Wiring both Global and Regional 390.625 MHz inputs on U20 allows the kit to evaluate tile-wide SyncE lock, Quad 2/3-local SyncE lock, and concurrent use of different reference domains across quad groups. For a production schematic, connect only the Global and/or Regional SyncE-cleaned REFCLK pins required by your FGT quad placement and Ethernet IP span.

---

## REF 3: Two 156.25 MHz SyncE Clock connections to F-Tile (U22) Reference Clock Inputs

**Altera Response:**

Your observation is correct: one Global reference clock input can be accessed by all four FGT quads. Providing a second 156.25 MHz connection to REFCLK-6 [Regional] is therefore not a silicon requirement for a single-rate, single-domain Ethernet configuration.

On the Agilex 7 M-Series Development Kit, both REFCLK-5 [Global] and REFCLK-6 [Regional] are driven with 156.25 MHz SyncE-derived clocks to provide:

1. Topology flexibility — Global for tile-wide / multi-quad IP; Regional for Quad 2/3-only placements.
2. Multi-configuration bring-up — the kit supports many Ethernet breakouts and SyncE experiments without board respin.
3. Optional independent clock domains — different quad groups can use separate reference sources if needed.

For your production design, a single 156.25 MHz Global REFCLK (for example REFCLK-5) is sufficient when all active FGT quads share one frequency and timing domain. Add Regional (or additional Global) 156.25 MHz routing only if you require independent clock domains across quads or want SyncE isolation between interfaces.

---

## REF 4: Rationale for using the 390.625 MHz SyncE Clock as the source for the Clock distribution network

**Altera Response:**

On the Development Kit, Si5518 is implemented as the board-level SyncE / IEEE 1588 network synchronizer (not only an Ethernet-local cleanup PLL). The kit therefore uses the Si5518 timing domain—including the 390.625 MHz SyncE clock—as the master source into Si5395/Si5391 fanout devices that generate references for F-Tile Ethernet, DDR5, HBM/UIB, NOC, FPGA I/O PLL, and SDM.

Benefits of this kit architecture:

- Frequency synchronization: when Si5518 is locked to line-recovered SyncE timing, Ethernet and system clocks can share one frequency-coherent, network-traceable domain.
- Phase / system timing: a common master simplifies relationships among Ethernet MAC clocks, PTP timestamp paths, and fabric clocks for SyncE + PTP demonstration.
- Jitter: the network-synchronizer + jitter-attenuator chain cleans the recovered clock before distribution, rather than broadcasting the raw CDR clock.
- Distribution / BOM: one high-quality master plus fanout PLLs reduces oscillator count on the evaluation platform and keeps derived clocks integer-related.

Clarification for production designs: using the SyncE master as the root clock for DDR5, HBM, NOC, I/O PLL, and SDM is a Development Kit choice, not an Agilex M / F-Tile silicon mandate.

- Required for SyncE on Ethernet: the cleaned recovered clock must be fed back as the transceiver / Ethernet reference so TX tracks RX within SyncE ppm limits.
- Optional for memory / NOC / SDM: these interfaces do not inherently require SyncE. Independent low-jitter oscillators may be used for DDR5, HBM, NOC, I/O PLL, and SDM if SyncE/PTP coherence is needed only on the Ethernet domain (with proper CDC at asynchronous boundaries).

Recommendation: retain a Si5518-class SyncE/1588 device in the Ethernet recovered-clock cleanup loop and derive F-Tile Ethernet REFCLKs from that cleaned domain. Choose either a kit-like coherent tree (SyncE master fans out to Ethernet + memory/system clocks) or a split tree (SyncE master for Ethernet/PTP only; independent oscillators for memory/NOC/SDM) based on whether system-wide frequency alignment is required.
