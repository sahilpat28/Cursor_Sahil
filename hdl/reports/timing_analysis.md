# 500 MHz Timing Analysis Status

## Target

- Board: Agilex 7 FPGA I-Series Transceiver-SoC Development Kit (4x F-Tile)
- Kit ordering code: `DK-SI-AGI027FD`
- FPGA family: Agilex 7 I-Series
- Device OPN on board: `AGIB027R31B1E1VC`
- Tool target: Quartus Prime Pro 26.1
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

### Open-Source Synthesis Sanity Check

```text
Command: yosys -s hdl/synth/yosys_synth_sanity.ys
Result: completed successfully
Yosys check: Found and reported 0 problems
```

Generic hierarchy summary from the fast Yosys elaboration check:

```text
Number of cells: 19164
  $add:        1350
  $dff:        5828
  $mul:        1357
  $mux:       10452
  $sub:           8
```

This Yosys run is only an RTL elaboration sanity check because Yosys does not
provide the Agilex 7 Quartus Prime Pro 26.1 timing library, DSP block mapping,
or fitter. The Yosys warnings about replacing Verilog memories with lists of
registers are expected for the register-array coding style used in the
pipelined FIR/NCO.

## Post-Route Timing Status

A real 500 MHz Fmax result requires vendor place-and-route with the target
device timing library. Quartus Prime Pro 26.1 is not installed in this cloud
environment, so a valid Agilex 7 post-fit WNS/TNS report could not be produced
here.

The Quartus project uses `psk8_modem_quartus_top` as the top-level entity. This
wrapper keeps the 8-lane DAC/ADC sample buses internal so Quartus does not try
to assign the raw modem core's 1094 top-level I/O signals to package pins. The
wrapper exposes only 68 control/status pins, which avoids the reported
720-user-I/O package limit during standalone core timing analysis.

Use `psk8_modem_top` as the reusable core when connecting to real converter or
F-Tile/JESD/interface IP in the board-level design.

If Quartus still reports 1094 I/O pins, the project is still using
`psk8_modem_top` as the top-level entity. Set the top-level entity to
`psk8_modem_quartus_top`, or open the provided
`hdl/synth/quartus/psk8_modem_agilex7.qpf` project.

If Quartus reports `Cyclone 10 GX` or device `10CX220YF780I5G`, the compile is
not using the provided Agilex 7 project assignments. Use
`hdl/synth/quartus/psk8_modem_agilex7.qpf` or
`quartus_sh -t hdl/synth/quartus/run_quartus_compile.tcl`, and confirm Agilex 7
device support is installed in Quartus Prime Pro 26.1.

The Agilex 7 Reset Release IP critical warning is expected until the final
board-level design instantiates the Quartus Reset Release IP. Add one instance
from `Basic Functions > Configuration and Programming > Reset Release IP` and
use its `nINIT_DONE` output to gate the system reset in hardware.

The runnable Quartus flow is provided at:

```text
hdl/synth/quartus/run_quartus_compile.tcl
hdl/synth/quartus/psk8_modem_500mhz.sdc
```

Run from the repository root on a machine with Quartus Prime Pro 26.1 installed
and Agilex 7 device support enabled:

```bash
quartus_sh -t hdl/synth/quartus/run_quartus_compile.tcl
```

Expected output reports:

```text
hdl/reports/quartus/flow_summary.rpt
hdl/reports/quartus/fitter_resource_usage_summary.rpt
hdl/reports/quartus/timing_analyzer_summary.rpt
```

## Timing Conclusion

- Functional validation: PASS
- Open-source RTL synthesis/elaboration sanity check: PASS
- Agilex 7 Quartus post-fit timing: PENDING QUARTUS PRIME PRO 26.1 RUN

The RTL is now structured for a realistic 500 MHz implementation, but final
timing closure must be judged from the Quartus Timing Analyzer summary on
`AGIB027R31B1E1VC`.

