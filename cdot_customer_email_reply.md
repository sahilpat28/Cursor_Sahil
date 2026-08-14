Subject: RE: Reg., Clarification on F-Tile Reference Clock and 390.625 MHz SyncE Clock Distribution in Agilex M FPGA

Hi Thulasi Ramu,

Thank you for pointing this out. Your interpretation is correct, and we apologize for our earlier incorrect statement.

We had conflated two different clock paths:

- **390.625 MHz** is the `o_clk_rec_div` output for 25GE–400GE. It is not the dedicated SyncE output in Table 29 and is not a supported FGT REFCLK input.
- Table 29 applies to the dedicated `o_cdr_divclk` SyncE output on Refclk8/9 (approximately **26–39 MHz**), which feeds the external cleanup PLL.

For your design, use the recommended **156.25 MHz** F-Tile Ethernet REFCLK. For SyncE, route the Table 29 CDR output to the cleanup PLL and configure the PLL to return a supported PMA reference clock; we recommend **156.25 MHz**.

The Development Kit physically provisions 390.625 MHz clock routes, but no published specification provides an exception to the **380 MHz maximum** FGT REFCLK input frequency. Therefore, please do not copy the 390.625 MHz REFCLK connection into your Ethernet design.

**References:**
- [F-Tile Ethernet Hard IP User Guide, Section 5, Table 25](https://docs.altera.com/r/docs/683023/25.3.1/f-tile-ethernet-hard-ip-user-guide/clocks) — `i_clk_ref` and `o_clk_rec_div`
- [F-Tile Ethernet Hard IP User Guide, Section 5.5, Figure 26 / Table 29](https://docs.altera.com/r/docs/683023/25.3.1/f-tile-ethernet-hard-ip-user-guide/clock-connections-in-synchronous-ethernet-operation) — documented SyncE connection and `o_cdr_divclk`
- [Agilex 7 M-Series Device Data Sheet, F-Tile Transceiver Reference Clock Specifications, Table 62](https://docs.altera.com/r/docs/769310/current/agilextm-7-fpgas-and-socs-device-data-sheet-m-series/f-tile-transceiver-reference-clock-specifications) — 380 MHz maximum REFCLK input frequency

Regards,  
Sahil Patni  
Altera
