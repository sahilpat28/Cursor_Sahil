# GTS AXI-Stream to MPU Bus Adapter

This is the small Agilex 3 host-to-register-map example that the GTS AXI
Streaming PCIe design example does not provide.

Intel's published PIO example does:

```text
GTS AXI-S (PCIe TLP) -> PIO -> Avalon-MM -> on-chip memory
```

SAT / Ethernet control loading needs:

```text
GTS AXI-S (PCIe TLP) -> this IP -> MPU bus -> user register map
```

The MPU bus is only address, 32-bit data, chip select, read/write, byte
enables, and ack. There is no DRAM, no bursting Avalon-MM master, and no
requirement to cut down the memory-backed design example.

## Files

```text
gts_axis_to_mpu.v                 Adapter IP
mpu_regmap_example.v              Drop-in SAT-style CSR file
mpu_to_axi4lite.v                 Optional MPU -> AXI4-Lite master
axi4lite_regmap_example.v         Optional AXI4-Lite slave CSRs
gts_axis_mpu_example_top.v        AXI-S + MPU + register map
gts_axis_axi4lite_example_top.v   AXI-S + MPU + AXI4-Lite + CSRs
```

## Bus widths

| Device / IP config              | GTS AXI-S width | `AXIS_DATA_W` |
| ------------------------------- | --------------- | ------------- |
| Agilex 3 Gen3 (typical)         | 128             | 128           |
| Customer / wider GTS configs    | 256             | 256           |

Set `AXIS_DATA_W` to match the GTS AXI Streaming IP. The Cyclone V Avalon-ST
128-bit to MPU converter cannot be imported unchanged because the GTS interface
is AXI4-Stream with a 32-byte in-band header (PCIe TLP plus BAR/function
sideband), not Avalon-ST.

## Hook-up to GTS AXI Streaming IP

Clock/reset:

```text
clk  <- p0_axi_st_clk            (or p0_coreclkout_hip_toapp)
rst  <- ~p0_axi_st_areset_n
```

RX (host BAR access into the FPGA):

```text
rx_tvalid <- p0_ss_app_st_rx_tvalid
rx_tready -> p0_app_ss_st_rx_tready
rx_tdata  <- p0_ss_app_st_rx_tdata
rx_tkeep  <- p0_ss_app_st_rx_tkeep
rx_tlast  <- p0_ss_app_st_rx_tlast
rx_tuser_halt -> p0_app_ss_st_rx_tuser_halt   (driven 0)
```

TX (completions back to the host). Also obey the GTS TX credit interface in
hardware; this example uses `tready` only.

```text
tx_tvalid -> p0_app_ss_st_tx_tvalid
tx_tready <- p0_ss_app_st_tx_tready
tx_tdata  -> p0_app_ss_st_tx_tdata
tx_tkeep  -> p0_app_ss_st_tx_tkeep
tx_tlast  -> p0_app_ss_st_tx_tlast
```

Leave GTS "AXI-ST Sideband Header" disabled so the 32-byte header stays in
`TDATA`, matching this IP.

Replace `mpu_regmap_example` with the SAT register map. The slave contract is:

```text
mpu_cs      Chip select. Held until mpu_ack.
mpu_we      Write strobe (valid with cs).
mpu_re      Read strobe (valid with cs).
mpu_addr    Byte address from the TLP (BAR-relative).
mpu_be      Byte enables from First/Last BE.
mpu_wdata   32-bit write data.
mpu_rdata   32-bit read data, valid when ack completes a read.
mpu_ack     Slave done. Tie to mpu_cs for zero-wait registers.
```

If the CSRs are AXI4-Lite instead of MPU, instantiate `mpu_to_axi4lite` between
the adapter and the slave, as in `gts_axis_axi4lite_example_top.v`.

## Supported TLPs

- Memory Write 3DW/4DW, 1 to `MAX_DW` dwords (default 16)
- Memory Read  3DW/4DW, 1 to `MAX_DW` dwords, with CplD
- Other TLPs are drained; non-posted unsupported requests return UR

This is a PIO / register-map adapter, not a DMA engine. It processes one TLP at
a time, which is the SAT control-path use case.

## Simulate

From `hdl/`:

```bash
make sim-mpu
```

Expected result:

```text
PASS: GTS AXI-Stream to MPU/AXI4-Lite register-map example
```

The testbench issues AXI-S MWr/MRd packets at 128 and 256 bits, checks the
example register map, covers 64-bit addressing, TX backpressure, and the
optional AXI4-Lite path.
