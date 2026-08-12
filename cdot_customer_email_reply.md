Subject: RE: Reg., Clarification on F-Tile Reference Clock and 390.625 MHz SyncE Clock Distribution in Agilex M FPGA

Hi Thulasi Ramu,

Thank you for your queries on the Agilex 7 M-Series Development Kit clock architecture. Please find our responses below.

**Background**
The 390.625 MHz frequency is the natural RX recovered clock (`o_clk_rec_div`) for Ethernet modes from 25GE to 400GE (line rate ÷ 66).  
Si5518 is the SyncE / IEEE 1588 timing device: it cleans the F-Tile recovered clock and sends it back to the F-Tiles to close the SyncE frequency-lock loop.  
156.25 MHz remains the recommended Ethernet reference clock for all data rates.

**REF 1 – Purpose of 390.625 MHz on REFCLK-4**
- **156.25 MHz on REFCLK-5:** main Ethernet reference clock for all rates.
- **390.625 MHz on REFCLK-4:** SyncE cleaned clock, fed back to the F-Tiles to keep TX frequency locked to the RX recovered clock.

Both are provided on the kit so normal Ethernet and SyncE operation can be evaluated.

**REF 2 – Two 390.625 MHz clocks on F-Tile U20**
- **REFCLK-4 (Global):** available to all four FGT quads.
- **REFCLK-6 (Regional):** available to Quad 2 and Quad 3 only (SyncE recovery quads).

This is for flexibility on the Development Kit. Your design only needs the REFCLK type required by your quad usage.

**REF 3 – Two 156.25 MHz clocks on F-Tile U22**
You are correct — one Global REFCLK can reach all four FGT quads.  
The second (Regional) connection on the kit is only for evaluation flexibility.  
For your design, a single 156.25 MHz Global REFCLK is sufficient if all quads share the same clock domain.

**REF 4 – Why 390.625 MHz SyncE clock feeds DDR / HBM / NOC / SDM clocks**
On the Development Kit, Si5518 is used as the board master clock so Ethernet and other interfaces stay frequency-aligned for SyncE/PTP demos.

This is a kit choice, not a device requirement.  
For your board:
- SyncE cleaned clock **must** go back to the F-Tile Ethernet REFCLK.
- DDR, HBM, NOC, and SDM **may use independent clocks** if SyncE locking is needed only for Ethernet.

Please let us know if you would like a short call to review your schematic before layout freeze.

Regards,  
Rushikesh Purohit  
Altera
