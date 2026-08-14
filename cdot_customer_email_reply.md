Subject: RE: Reg., Clarification on F-Tile Reference Clock and 390.625 MHz SyncE Clock Distribution in Agilex M FPGA

Hi Thulasi Ramu,

Thank you. The clarification is that Table 29 and the Development Kit schematic use “recovered clock” for different clock representations:

1. **Table 29 (`o_cdr_divclk`)** describes the dedicated PMA recovered-clock output on Refclk8/9, after the RX-path N divider. Therefore, its frequency is `REFCLK/N`, approximately **26–39 MHz** for the configurations shown.

2. **Table 25 (`o_clk_rec_div`)** describes a different Ethernet Hard IP recovered-clock output: **156.25 MHz for 10GE, 312.5 MHz for 40GE, and 390.625 MHz for the other Ethernet modes**.

The Development Kit schematic labels the board-level routes as `RECVD_CLK_156.25M` and `RECVD_CLK_390.625M`, but it does not identify the corresponding Ethernet IP signal or RX-divider setting. Therefore, those schematic frequency labels should not be compared directly with Table 29.

For implementation, please use **Table 29 for the dedicated `o_cdr_divclk` output** and **Table 25 for the separate `o_clk_rec_div` output**.

**References:**
- [F-Tile Ethernet Hard IP User Guide 26.1.1, Section 5, Table 25](https://docs.altera.com/r/docs/683023/26.1.1/f-tile-ethernet-hard-ip-user-guide/clocks) — `i_clk_ref` and `o_clk_rec_div`
- [F-Tile Ethernet Hard IP User Guide 26.1.1, Section 5.5, Figure 25 / Table 29](https://docs.altera.com/r/docs/683023/26.1.1/f-tile-ethernet-hard-ip-user-guide/clock-connections-in-synchronous-ethernet-operation) — documented SyncE connection and `o_cdr_divclk`

Regards,  
Sahil Patni  
Altera
