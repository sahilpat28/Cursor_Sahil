# Verilog 8-PSK Modem RTL

This directory contains synthesizable Verilog-2001 RTL for the requested modem:

- PRBS31 source
- 8-PSK natural-code mapper
- 3 Gbps bit rate as 1 Gbaud at 3 bits/symbol
- 4 GSPS-equivalent complex ADC/DAC sample interface
- 500 MHz RTL clock
- 8 complex samples per RTL clock
- 4 samples/symbol
- SRRC transmit and receive filtering with 0.35 rolloff
- Receiver frequency correction with a programmable NCO rotator

## Files

```text
rtl/psk8_mapper.v      Natural-code 8-PSK mapper, Q1.15 I/Q
rtl/psk8_demapper.v    Hard-decision natural-code 8-PSK demapper
rtl/srrc_fir_8x.v      pipelined 8-sample/clock 41-tap beta=0.35 SRRC FIR
rtl/nco_rotator_8x.v   pipelined 8-sample/clock complex NCO rotator
rtl/psk8_tx.v          PRBS31 + mapper + SRRC TX
rtl/psk8_rx.v          CFO correction + SRRC matched filter + demapper
rtl/psk8_modem_top.v   Integrated TX/RX datapath
rtl/psk8_modem_quartus_top.v
                       Quartus compile wrapper with internal sample buses
tb/tb_psk8_modem.v     Self-checking loopback simulation
constraints/psk8_modem_500mhz.sdc
                       Generic 2 ns clock constraint
synth/yosys_synth_sanity.ys
                       Open-source RTL synthesis/elaboration sanity check
synth/quartus/         Quartus Prime Pro 26.1 Agilex 7 compile/timing flow
reports/timing_analysis.md
                       Timing-analysis status and results
```

## Clocking and Rates

The RTL clock is 500 MHz. Each clock processes eight consecutive complex
samples, so the sample throughput remains 4 GSPS:

```text
RTL clock rate      = 500 MHz
samples/clock       = 8 complex I/Q samples
ADC/DAC sample rate = 4.0 GSPS
8-PSK bits/symbol  = 3
symbol rate        = 3.0 Gbps / 3 = 1.0 Gbaud
samples/symbol     = 4.0 GSPS / 1.0 Gbaud = 4
symbols/clock       = 8 samples/clock / 4 samples/symbol = 2
```

The transmitter launches two natural-code 8-PSK symbols per 500 MHz clock:

```text
lane 0 = symbol 0 sample
lane 4 = symbol 1 sample
all other TX upsample lanes are zero before SRRC filtering
```

Packed I/Q buses use this lane ordering:

```text
lane N = bits [16*N +: 16]
lane 0 = earliest sample in the block
lane 7 = latest sample in the block
```

## Fixed-Point Formats

- I/Q samples: signed Q1.15
- SRRC coefficients: signed Q1.15
- NCO sine/cosine LUT: signed Q1.15
- NCO phase accumulator: 16-bit modulo phase

## Timing-Oriented Pipelines

The 500 MHz datapath avoids long single-cycle arithmetic chains:

- `srrc_fir_8x.v` registers all coefficient products, then uses six registered
  adder-tree levels before the registered output saturation stage.
- `nco_rotator_8x.v` registers input/LUT values, registers multiplier outputs,
  then registers complex add/subtract and saturation outputs.

These pipeline stages increase latency but preserve one 8-sample block per clock
throughput.

## Receiver Frequency Correction

The receiver frequency correction input is `rx_phase_inc`.

For a 4 GSPS sample rate:

```text
rx_phase_inc = round(-frequency_offset_hz / 4.0e9 * 2^16)
```

The tuning word is per 4-GSPS sample, not per 500 MHz block. Internally, the
8-lane NCO advances the phase for each lane and advances the accumulator by
eight sample steps per RTL clock.

Example for a +10 MHz carrier offset:

```text
rx_phase_inc = round(-10e6 / 4e9 * 65536) = -164
```

The supplied testbench injects approximately +10 MHz with `CFO_WORD = 164` and
programs the receiver with `RX_CORR_WORD = -164`.

## Run Simulation

Install Icarus Verilog if needed, then run:

```bash
cd hdl
make sim
```

Expected result:

```text
PASS: recovered 1024 PRBS31 8-PSK symbols at 500 MHz RTL clock with CFO correction
```

## Synthesis and Timing

Top-level choices:

```text
psk8_modem_top.v
  Reusable modem core with full packed DAC/ADC sample-block ports.
  Use this when integrating with real converter, JESD, F-Tile, or custom I/O IP.

psk8_modem_quartus_top.v
  Quartus standalone compile/timing wrapper. It keeps the wide DAC/ADC sample
  buses internal and exposes only a small control/status interface, avoiding
  package I/O overuse during core timing analysis.
```

Open-source synthesis/elaboration sanity check:

```bash
yosys -s hdl/synth/yosys_synth_sanity.ys
```

Quartus Prime Pro 26.1 compile/timing flow for the Agilex 7 I-Series
Transceiver-SoC Development Kit target device `AGIB027R31B1E1VC`:

```bash
quartus_sh -t hdl/synth/quartus/run_quartus_compile.tcl
```

The Quartus flow writes timing and utilization reports under
`hdl/reports/quartus/`. See `hdl/reports/timing_analysis.md` for the latest
validation status.

## Integration Notes

`psk8_modem_top.v` exposes separate packed complex DAC and ADC sample-block
ports. Connect the DAC outputs to the transmit mixed-signal path, and connect
the receive mixed-signal path to the ADC inputs. If your hardware uses passband
DAC/ADC samples instead of complex baseband I/Q, add DUC/DDC blocks around this
modem.

The included receiver has a configurable symbol sampling phase. In a production
receiver, replace or drive this with timing recovery if the ADC sample phase is
not deterministic.

The supplied Quartus SDC file constrains the RTL `clk` port to 2.000 ns. Final
timing closure still depends on Quartus fitter placement, clock resource
selection, pin/interface constraints, and any board-level integration logic.

