Subject: RE: Reg., Clarification on F-Tile Reference Clock and 390.625 MHz SyncE Clock Distribution in Agilex M FPGA

Hi Thulasi Ramu,

Thank you for pointing this out. Your interpretation is correct, and we apologize for the ambiguity in our earlier response.

We had mixed two different recovered-clock paths:

- **390.625 MHz** is the `o_clk_rec_div` fabric output for 25GE–400GE; it is **not** the dedicated SyncE clock output in Table 29 and is **not** specified as an Ethernet REFCLK input.
- The documented SyncE path uses the dedicated `o_cdr_divclk` output on Refclk8/9. Table 29 shows this output as approximately **26–39 MHz**; it is sent to the external cleanup PLL.
- The cleanup PLL then provides a supported transceiver reference clock back to the F-Tile. For your design, please use the recommended **156.25 MHz** REFCLK.

Also, the FGT/System PLL REFCLK input range is documented as **25–380 MHz**. Therefore, the 390.625 MHz route physically provisioned on the Development Kit must not be interpreted or copied as the supported Ethernet SyncE REFCLK path.

**References:**
- [F-Tile Ethernet Hard IP User Guide, Section 5, Table 25](https://docs.altera.com/r/docs/683023/25.3.1/f-tile-ethernet-hard-ip-user-guide/clocks) — `i_clk_ref` and `o_clk_rec_div`
- [F-Tile Ethernet Hard IP User Guide, Section 5.5, Figure 26 / Table 29](https://docs.altera.com/r/docs/683023/25.3.1/f-tile-ethernet-hard-ip-user-guide/clock-connections-in-synchronous-ethernet-operation) — documented SyncE connection and `o_cdr_divclk`
- [F-Tile Architecture User Guide, Section 2.4.1.2, Table 24](https://docs.altera.com/r/docs/683872/25.3/f-tile-architecture-and-pma-and-fec-direct-phy-ip-user-guide/fgt-and-system-pll-reference-clock-network) — FGT/System PLL REFCLK range and connectivity

Regards,  
Sahil Patni  
Altera
