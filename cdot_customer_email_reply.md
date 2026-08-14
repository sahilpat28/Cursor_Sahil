Subject: RE: Reg., Clarification on F-Tile Reference Clock and 390.625 MHz SyncE Clock Distribution in Agilex M FPGA

Hi Thulasi Ramu,

Thank you. Your observation is correct. The schematic labels and Table 29 refer to different clock paths:

- **Table 29 — `o_cdr_divclk`:** This is the dedicated recovered-clock output on Refclk8/9. Its frequency is `REFCLK/N`, approximately **26–39 MHz** for the configurations shown.
- **Table 25 — `o_clk_rec_div`:** This is a separate Ethernet IP logical clock output: **156.25 MHz for 10GE, 312.5 MHz for 40GE, and 390.625 MHz for the other Ethernet modes**.

The **156.25/390.625 MHz “recovered clock” names in the Development Kit schematic are board net labels/provisions**. They do not change the frequency of the current Ethernet Hard IP dedicated CDR output specified in Table 29.

We also need to correct our previous statement: Section 4.4.2 specifies 390.625 MHz for the **PTP ToD clock in FPGA logic**, but it does not specify that this clock enters through REFCLK-4/6. Please disregard that earlier interpretation.

For your new design, please follow the current documented SyncE path:

**Refclk8/9 dedicated CDR output (Table 29) → external cleanup PLL → supported F-Tile PMA reference clock (156.25 MHz recommended).**

Please do not apply 390.625 MHz to an FGT REFCLK input; the published maximum is 380 MHz. We are separately raising the Development Kit schematic labeling/configuration inconsistency with the board/IP team.

**References:**
- [F-Tile Ethernet Hard IP User Guide, Section 5, Table 25](https://docs.altera.com/r/docs/683023/25.3.1/f-tile-ethernet-hard-ip-user-guide/clocks) — `i_clk_ref` and `o_clk_rec_div`
- [F-Tile Ethernet Hard IP User Guide, Section 5.5, Figure 26 / Table 29](https://docs.altera.com/r/docs/683023/25.3.1/f-tile-ethernet-hard-ip-user-guide/clock-connections-in-synchronous-ethernet-operation) — documented SyncE connection and `o_cdr_divclk`
- [Agilex 7 M-Series Device Data Sheet, F-Tile Transceiver Reference Clock Specifications, Table 62](https://docs.altera.com/r/docs/769310/current/agilextm-7-fpgas-and-socs-device-data-sheet-m-series/f-tile-transceiver-reference-clock-specifications) — 380 MHz maximum REFCLK input frequency

Regards,  
Sahil Patni  
Altera
