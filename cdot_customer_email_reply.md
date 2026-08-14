Subject: RE: Reg., Clarification on F-Tile Reference Clock and 390.625 MHz SyncE Clock Distribution in Agilex M FPGA

Hi Thulasi Ramu,

Thank you for the follow-up. Your reading of Table 29 is correct. Please see the clarification below.

**Clarification on REF 1 / 390.625 MHz**

There is **no Altera document requirement** that 390.625 MHz must be provided to the F-Tile REFCLK input for SyncE.

Please separate these two items:

1. **F-Tile REFCLK / PMA reference (`i_clk_ref`)**  
   Allowed frequencies are **156.25 / 312.5 / 322.265625 MHz** (156.25 MHz recommended).  
   **Reference:** *F-Tile Ethernet Hard IP User Guide*, Section **5. Clocks**, Table 25 (`i_clk_ref`).

2. **SyncE recovered clock to cleanup PLL (Table 29)**  
   Table 29 is for the **dedicated CDR clock output** (`o_cdr_divclk` = refclk / N), available from FGT Quads 2/3 (Refclk8/9).  
   That output is **~26–39 MHz**, not 390.625 MHz.  
   **Reference:** *F-Tile Ethernet Hard IP User Guide*, Section **5.5 Clock Connections in Synchronous Ethernet Operation**, Table 29.

3. **Where 390.625 MHz appears**  
   390.625 MHz is the fabric recovered clock **`o_clk_rec_div`** for 25GE–400GE (SERDES rate ÷ 66).  
   This is a **different** clock from Table 29.  
   **Reference:** *F-Tile Ethernet Hard IP User Guide*, Section **5. Clocks**, Table 25 (`o_clk_rec_div`).

**SyncE usage (documented)**  
Recovered clock → off-chip cleanup PLL (e.g. Si5518) → cleaned clock returned as F-Tile REFCLK at a **legal** reference frequency (**typically 156.25 MHz**).  
**Reference:** Section **5.5** (SyncE cleanup PLL model).

**About the Development Kit**  
390.625 MHz on REFCLK-4 in the Agilex 7 M-Series Development Kit is a **kit schematic / evaluation implementation**. It is **not** a User Guide requirement to use 390.625 MHz as the SyncE REFCLK input.

**For your design**  
- Use **156.25 MHz** as F-Tile Ethernet REFCLK.  
- For SyncE, use the dedicated CDR recovered clock path (Table 29 / Section 5.5) into your cleanup PLL, and return **cleaned 156.25 MHz** to F-Tile REFCLK.

Please also share your interface block diagram when available.

Regards,  
Sahil Patni  
Altera
