Subject: RE: Reg., Clarification on F-Tile Reference Clock and 390.625 MHz SyncE Clock Distribution in Agilex M FPGA

Hi Thulasi Ramu,

Thank you for your queries. Please find our responses below.

**Background**  
390.625 MHz is the RX recovered clock (`o_clk_rec_div`) for 25GE–400GE (line rate ÷ 66).  
Si5518 cleans this SyncE recovered clock and feeds it back to the F-Tiles to close the SyncE lock loop.  
156.25 MHz is the recommended Ethernet reference for all rates.

**REF 1**  
- **156.25 MHz (REFCLK-5):** main Ethernet reference for all rates.  
- **390.625 MHz (REFCLK-4):** SyncE cleaned clock, returned to F-Tiles so TX stays frequency-locked to RX.

For your design: use **156.25 MHz** as the Ethernet REFCLK. For SyncE, feed the recovered clock into Si5518 (or equivalent) and return the cleaned reference to the F-Tile REFCLK. The kit shows 390.625 MHz on REFCLK-4 for evaluation; you do not need to copy both clocks unless your SyncE clocking plan requires it.

**REF 2**  
- **REFCLK-4 (Global):** all 4 FGT quads.  
- **REFCLK-6 (Regional):** Quad 2 & 3 only (SyncE recovery quads).  

Both are kit flexibility; use only what your quad placement needs.

**REF 3**  
Correct — one Global 156.25 MHz REFCLK can feed all 4 quads.  
The second (Regional) connection on the kit is for evaluation only. Not required in your design if all quads share one clock domain.

**REF 4**  
On the kit, Si5518 is the board SyncE/1588 master, so DDR/HBM/NOC/SDM clocks are derived from it for demo convenience.

This is not a device requirement.  
For your board: SyncE cleaned clock must return to F-Tile Ethernet REFCLK; DDR/HBM/NOC/SDM may use independent clocks if SyncE is needed only for Ethernet.

To support your design further, please share a block diagram of your interfaces (QSFP-DD / F-Tile mapping, Ethernet modes, SyncE/PTP clocking, and other major interfaces such as DDR/HBM if used).

Regards,  
Sahil Patni  
Altera
