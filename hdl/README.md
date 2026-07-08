# Verilog 8-PSK Modem RTL

This directory contains synthesizable Verilog-2001 RTL for the requested modem:

- PRBS31 source
- 8-PSK natural-code mapper
- 3 Gbps bit rate as 1 Gbaud at 3 bits/symbol
- 4 GSPS-equivalent complex ADC/DAC sample interface
- 4 samples/symbol
- SRRC transmit and receive filtering with 0.35 rolloff
- Receiver frequency correction with a programmable NCO rotator

## Files

```text
rtl/psk8_mapper.v      Natural-code 8-PSK mapper, Q1.15 I/Q
rtl/psk8_demapper.v    Hard-decision natural-code 8-PSK demapper
rtl/srrc_fir.v         41-tap beta=0.35 SRRC FIR, 4 samples/symbol
rtl/nco_rotator.v      Complex NCO rotator for CFO injection/correction
rtl/psk8_tx.v          PRBS31 + mapper + SRRC TX
rtl/psk8_rx.v          CFO correction + SRRC matched filter + demapper
rtl/psk8_modem_top.v   Integrated TX/RX datapath
tb/tb_psk8_modem.v     Self-checking loopback simulation
```

## Clocking and Rates

The RTL uses one `clk` tick for one complex ADC/DAC sample.

```text
ADC/DAC sample rate = 4.0 GSPS
8-PSK bits/symbol  = 3
symbol rate        = 3.0 Gbps / 3 = 1.0 Gbaud
samples/symbol     = 4.0 GSPS / 1.0 Gbaud = 4
```

The transmitter launches one natural-code 8-PSK symbol every four valid samples.

## Fixed-Point Formats

- I/Q samples: signed Q1.15
- SRRC coefficients: signed Q1.15
- NCO sine/cosine LUT: signed Q1.15
- NCO phase accumulator: 16-bit modulo phase

## Receiver Frequency Correction

The receiver frequency correction input is `rx_phase_inc`.

For a 4 GSPS sample rate:

```text
rx_phase_inc = round(-frequency_offset_hz / 4.0e9 * 2^16)
```

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
PASS: recovered 512 PRBS31 8-PSK symbols with CFO correction
```

## Integration Notes

`psk8_modem_top.v` exposes separate complex DAC and ADC ports. Connect the DAC
outputs to the transmit mixed-signal path, and connect the receive mixed-signal
path to the ADC inputs. If your hardware uses passband DAC/ADC samples instead
of complex baseband I/Q, add DUC/DDC blocks around this modem.

The included receiver has a configurable symbol sampling phase. In a production
receiver, replace or drive this with timing recovery if the ADC sample phase is
not deterministic.

