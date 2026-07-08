# 8-PSK Modem Reference Design

This repository contains an executable complex-baseband reference design for an
8-PSK modem with the requested parameters:

- PRBS31 input data source
- 3 Gbps input bit rate
- 8-PSK natural-code mapper
- 4 GSPS ADC/DAC sample rate
- SRRC pulse shaping enabled with 0.35 rolloff
- Receiver frequency correction

## Rate Plan

8-PSK carries 3 bits per symbol, so:

```text
bit rate       = 3.0 Gbps
bits/symbol    = 3
symbol rate    = 1.0 Gbaud
ADC/DAC rate   = 4.0 GSPS
oversampling   = 4 samples/symbol
SRRC rolloff   = 0.35
```

The Python model enforces these relationships in `ModemConfig`.

## Block Diagram

```text
TX:
  PRBS31 -> 3-bit grouping -> natural 8-PSK mapper -> 4x upsample
         -> SRRC beta=0.35 pulse shaping -> complex DAC samples

RX:
  complex ADC samples -> SRRC matched filter -> symbol timing at 4 sps
         -> 8th-power carrier frequency estimator/corrector
         -> residual phase correction -> natural 8-PSK hard demapper
```

The model is complex baseband. A hardware passband implementation can place a
digital upconverter/downconverter around this design if the ADC/DAC interface is
not already I/Q complex.

## Natural Coding

The mapper uses natural binary coding, not Gray coding:

| Bits | Index | Phase |
| ---- | ----- | ----- |
| 000  | 0     | 0 deg |
| 001  | 1     | 45 deg |
| 010  | 2     | 90 deg |
| 011  | 3     | 135 deg |
| 100  | 4     | 180 deg |
| 101  | 5     | 225 deg |
| 110  | 6     | 270 deg |
| 111  | 7     | 315 deg |

## Receiver Frequency Correction

The receiver uses an Mth-power estimator for 8-PSK:

1. Matched-filter and downsample to tentative symbols.
2. Raise symbols to the 8th power to remove 8-PSK data modulation.
3. Estimate the unwrapped phase slope.
4. Convert the slope to carrier frequency offset.
5. Correct the ADC sample stream and re-run matched filtering.
6. Estimate/remove residual carrier phase before hard decisions.

For symbol-spaced estimation, the unambiguous acquisition range is roughly
`+/- symbol_rate / (2 * 8)`, or `+/- 62.5 MHz` for this 1 Gbaud design.

## Repository Layout

```text
src/eight_psk_modem/
  channel.py   # frequency-offset and AWGN helpers
  config.py    # requested rate and SRRC configuration
  mapping.py   # natural-code 8-PSK mapper/demapper
  modem.py     # end-to-end TX/RX modem
  prbs.py      # PRBS31 generator
  srrc.py      # SRRC tap generation and pulse shaping

examples/simulate_link.py
tests/test_eight_psk_modem.py
```

## Run

Install the package locally:

```bash
python -m pip install -e .
```

Run a link simulation with a 10 MHz carrier-frequency offset:

```bash
python examples/simulate_link.py --bits 30000 --cfo-hz 10000000
```

Run the tests:

```bash
python -m unittest discover -s tests
```
