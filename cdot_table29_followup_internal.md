# Internal note — C-DOT follow-up on Table 29 / 390.625 MHz

## Customer is correct

They asked for a document that says “provide 390.625 MHz to REFCLK for SyncE.”  
**That statement is not in the Altera UGs.** Do not defend it.

## Two different clocks (easy to mix up)

| Clock | What it is | Frequency | Doc |
| --- | --- | --- | --- |
| `i_clk_ref` / F-Tile REFCLK | PMA reference **input** | 156.25 / 312.5 / 322.265625 (156.25 recommended) | UG 683023 §5 Table 25 |
| `o_cdr_divclk` (Table 29) | Dedicated SyncE CDR **output** (Refclk8/9, Quads 2/3) | ~26–39 MHz (= refclk/N) | UG 683023 §5.5 Table 29 |
| `o_clk_rec_div` | Fabric recovered clock **output** | 390.625 MHz for 25GE–400GE (rate÷66) | UG 683023 §5 Table 25 |

## What to tell customer

- Table 29 ≠ 390.625 path  
- SyncE documented path: recovered clock → cleanup PLL → return **legal REFCLK** (typically 156.25)  
- Kit 390.625 on REFCLK-4 = DK evaluation wiring, not UG mandate  

## Align with Rushikesh

Rushikesh’s earlier note that cleaned 390.625 is distributed back via REFCLK-4 describes the **kit schematic**, not a User Guide SyncE REFCLK requirement. Reply should correct that cleanly.
