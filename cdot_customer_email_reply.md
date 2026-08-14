Subject: RE: Reg., Clarification on F-Tile Reference Clock and 390.625 MHz SyncE Clock Distribution in Agilex M FPGA

Hi Thulasi Ramu,

Thank you. The schematic and Table 29 describe different aspects of the clocking:

1. **Table 29 (`o_cdr_divclk`)** defines the actual dedicated recovered-clock output on Refclk8/9. Its frequency is `REFCLK/N`, approximately **26–39 MHz** for the configurations shown.

2. The **156.25/390.625 MHz “recovered clock” names in the Development Kit schematic are static board net names showing physical routing to the external clock devices**. A schematic net name does not configure the F-Tile CDR divider or guarantee the operating frequency. For the current Ethernet Hard IP, the frequency on the dedicated recovered-clock pin is determined by `cdr_n_counter` and follows Table 29.

3. **Table 25 (`o_clk_rec_div`)** describes a separate Ethernet IP logical clock output: **156.25 MHz for 10GE, 312.5 MHz for 40GE, and 390.625 MHz for the other Ethernet modes**. This is not the dedicated package recovered-clock output described in Table 29.

Similarly, the 390.625 MHz PTP ToD clock described in Section 4.4.2 is an FPGA logic clock; it is not an FGT PMA reference-clock specification.

For your new design, please follow the current documented SyncE path:

**Refclk8/9 dedicated CDR output (Table 29) → external cleanup PLL → supported F-Tile PMA reference clock (156.25 MHz recommended).**

Please do not apply 390.625 MHz to an FGT REFCLK input; the published maximum is 380 MHz. The Development Kit schematic should be used for board connectivity, while the Ethernet IP User Guide and device data sheet define the supported clock frequencies and operation.

**References:**
- [F-Tile Ethernet Hard IP User Guide, Section 5, Table 25](https://docs.altera.com/r/docs/683023/25.3.1/f-tile-ethernet-hard-ip-user-guide/clocks) — `i_clk_ref` and `o_clk_rec_div`
- [F-Tile Ethernet Hard IP User Guide, Section 5.5, Figure 26 / Table 29](https://docs.altera.com/r/docs/683023/25.3.1/f-tile-ethernet-hard-ip-user-guide/clock-connections-in-synchronous-ethernet-operation) — documented SyncE connection and `o_cdr_divclk`
- [Agilex 7 M-Series Device Data Sheet, F-Tile Transceiver Reference Clock Specifications, Table 62](https://docs.altera.com/r/docs/769310/current/agilextm-7-fpgas-and-socs-device-data-sheet-m-series/f-tile-transceiver-reference-clock-specifications) — 380 MHz maximum REFCLK input frequency

Regards,  
Sahil Patni  
Altera
