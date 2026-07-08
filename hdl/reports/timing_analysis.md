# 500 MHz Timing Analysis Status

## Target

- FPGA family: Xilinx Virtex UltraScale+
- Part used by the provided P&R script: `xcvu9p-flga2104-3-e`
- RTL clock target: 500 MHz
- Clock period constraint: 2.000 ns
- Converter throughput: 4 GSPS via 8 complex I/Q samples per RTL clock

## RTL Timing Refactor Completed

The timing-critical datapaths were refactored from single-cycle arithmetic into
registered pipelines:

- `srrc_fir_8x.v`
  - registered multiplier-product stage
  - registered 41-to-21 adder-tree stage
  - registered 21-to-11 adder-tree stage
  - registered 11-to-6 adder-tree stage
  - registered 6-to-3 adder-tree stage
  - registered 3-to-2 adder-tree stage
  - registered 2-to-1 adder-tree stage
  - registered Q1.15 rounding/saturation output stage
- `nco_rotator_8x.v`
  - registered input/LUT phase stage
  - registered multiplier stage
  - registered complex add/subtract and saturation output stage

## Completed Validation in This Environment

### Functional HDL Simulation

```text
Command: make -C hdl sim
Result: PASS
Recovered: 1024 PRBS31 8-PSK symbols
Clock architecture: 500 MHz RTL, 8 samples/clock
CFO correction: enabled
```

### Python Reference Regression

```text
Command: python3 -m unittest discover -s tests
Result: OK
Tests run: 7
Failures: 0
```

### Python Link Simulation

```text
Command: python3 examples/simulate_link.py --bits 30000 --cfo-hz 10000000
Injected CFO:  10,000,000.000 Hz
Estimated CFO: 9,999,999.996 Hz
Bit errors:    0
BER:           0.000000e+00
```

### Open-Source UltraScale+ Synthesis Check

```text
Command: yosys -s hdl/synth/yosys_xcup_synth.ys
Result: completed successfully
Yosys check: Found and reported 0 problems
```

Full hierarchy resource summary from Yosys `synth_xilinx -family xcup`:

```text
Number of cells: 137634
  CARRY4:        11474
  DSP48E2:        1304
  FDRE:          83375
  FDSE:             31
  LUT1:             32
  LUT2:          38708
  LUT3:            678
  LUT4:            620
  LUT5:            497
  LUT6:            708
  MUXF7:            71
  MUXF8:            27
  MUXF9:             8
Estimated LCs:   21208
```

The Yosys warnings about replacing Verilog memories with lists of registers are
expected for the register-array coding style used in the pipelined FIR/NCO.

## Post-Route Timing Status

A real 500 MHz Fmax result requires vendor place-and-route with the target
device timing library. Vivado is not installed in this cloud environment, so a
valid post-route WNS/TNS report could not be produced here.

The runnable Vivado flow is provided at:

```text
hdl/synth/vivado/run_vivado_pnr.tcl
hdl/synth/vivado/psk8_modem_500mhz.xdc
```

Run from the repository root on a machine with Vivado installed:

```bash
vivado -mode batch -source hdl/synth/vivado/run_vivado_pnr.tcl
```

Expected output reports:

```text
hdl/reports/vivado/post_synth_timing_summary.rpt
hdl/reports/vivado/post_route_timing_summary.rpt
hdl/reports/vivado/post_route_worst_paths.rpt
hdl/reports/vivado/post_route_utilization.rpt
hdl/reports/vivado/post_route_clock_utilization.rpt
hdl/reports/vivado/post_route_drc.rpt
```

## Timing Conclusion

- Functional validation: PASS
- UltraScale+ synthesis/elaboration: PASS
- 500 MHz post-route timing: PENDING VIVADO RUN

The RTL is now structured for a realistic 500 MHz implementation, but final
timing closure must be judged from the Vivado post-route timing summary on the
selected target part.

