# Internal — Sources for C-DOT SyncE / REFCLK reply

For Sahil / Rushikesh only. Do **not** send this block to the customer.

| Claim in mail | Source |
| --- | --- |
| 390.625 MHz = `o_clk_rec_div` for 25GE–400GE (line rate ÷ 66) | F-Tile Ethernet Hard IP User Guide — Clocks: `o_clk_rec_div` = 390.625 MHz for all Ethernet modes except 10GE/40GE; ÷66 for common FEC modes. Also Rushikesh draft mail. |
| Si5518 cleans recovered clock and feeds back to close SyncE loop | F-Tile Ethernet Hard IP UG — SyncE: TX refclk should be filtered version of RX recovered clock via off-chip cleanup PLL. Kit uses Si5518 as SyncE/1588 timing device (M-Series DK clock tree / Rushikesh mail). |
| 156.25 MHz = recommended Ethernet refclk for all rates | F-Tile Ethernet Hard IP UG — Clocks: `i_clk_ref` — 156.25 MHz recommended; required for FHT / AN+LT. |
| REFCLK-4 = Global (all 4 quads); REFCLK-6 = Regional (Quad 2/3) | F-Tile Architecture UG — FGT and System PLL Reference Clock Network: `refclk[4]` Global Quad0–3; `refclk[6]` Regional Quad2–3. |
| Quad 2/3 = SyncE dedicated CDR output quads | Same Architecture UG: `refclk[8]/[9]` local I/O on Quad2/3 for RX recovered clock. SyncE chapter: dedicated CDR outputs from FGT Quads 2 and 3 only. |
| One Global REFCLK can feed all 4 quads | Same Architecture UG: Global refclks accessible by four FGT quads. |
| Dual Global+Regional wiring = kit flexibility, not silicon must | Kit schematic / DK clock tree practice; Architecture UG shows optional Global vs Regional use by placement. |
| Si5518 as board master for DDR/HBM/NOC/SDM = kit choice | Agilex 7 M-Series HBM2e DK User Guide — Clock Tree (Si5518 → Si5395/Si5391 fanout). Not stated as silicon requirement in F-Tile/EMIF UGs. |
| SyncE must close on Ethernet REFCLK; memory clocks may be independent | SyncE UG usage model applies to transceiver TX refclk. EMIF/NOC/SDM have their own refclk rules and do not require SyncE. |

## Key public links

1. https://docs.altera.com/r/docs/683023/25.3.1/f-tile-ethernet-hard-ip-user-guide/clocks  
2. https://docs.altera.com/r/docs/683023/25.3.1/f-tile-ethernet-hard-ip-user-guide/clock-connections-in-synchronous-ethernet-operation  
3. https://docs.altera.com/r/docs/683872/26.1/f-tile-architecture-and-pma-and-fec-direct-phy-ip-user-guide/fgt-and-system-pll-reference-clock-network  
4. Agilex 7 M-Series HBM2e Development Kit User Guide (Clock Tree / Si5518) — doc 782461  
5. Rushikesh partial reply in the customer email thread (390.625 SyncE loop via Si5518 → REFCLK-4)

## Related prior customer thread (same C-DOT contact)

https://community.altera.com/discussions/fpga-device/global-clock--regional-clock-inputs-in-agilex-m-fpga/353673
