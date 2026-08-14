Subject: RE: Reg., Clarification on F-Tile Reference Clock and 390.625 MHz SyncE Clock Distribution in Agilex M FPGA

Hi Thulasi Ramu,

Thank you for pointing this out. Your interpretation of Table 29 is correct, and we would like to correct our earlier statement.

**390.625 MHz is not specified as an F-Tile REFCLK input for SyncE.** We had mixed two different recovered-clock paths:

- **F-Tile REFCLK input:** For the Ethernet modes discussed, the documented values are 156.25, 312.5, or 322.265625 MHz; 156.25 MHz is recommended.
- **Dedicated SyncE CDR output (`o_cdr_divclk`):** Table 29 shows approximately 26–39 MHz. This clock is sent to the external cleanup PLL.
- **`o_clk_rec_div`:** 390.625 MHz for 25GE–400GE. This is a separate fabric clock output and is not the dedicated SyncE output shown in Table 29.

Therefore, for your design, please use the dedicated CDR output shown in Table 29 as the SyncE source to the cleanup PLL and return a cleaned **156.25 MHz** clock to the F-Tile REFCLK.

The 390.625 MHz connection shown on REFCLK-4 of the Development Kit is board-specific clock provision; it should not be interpreted as a documented SyncE requirement.

**References:** *F-Tile Ethernet Hard IP User Guide* (Document 683023, Version 25.3.1), Section 5, Table 25 (`i_clk_ref` and `o_clk_rec_div`), and Section 5.5, Figure 26 / Table 29 (`o_cdr_divclk` and SyncE cleanup PLL connection).

Regards,  
Sahil Patni  
Altera
