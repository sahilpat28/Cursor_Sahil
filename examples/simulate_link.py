#!/usr/bin/env python3
"""Run an 8-PSK PRBS31 link simulation."""

from __future__ import annotations

import argparse

import numpy as np

from eight_psk_modem import EightPskModem, add_awgn, apply_frequency_offset


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bits", type=int, default=30_000, help="PRBS31 bit count")
    parser.add_argument(
        "--cfo-hz",
        type=float,
        default=10.0e6,
        help="Carrier frequency offset to inject before the receiver",
    )
    parser.add_argument(
        "--snr-db",
        type=float,
        default=None,
        help="Optional complex-baseband AWGN SNR",
    )
    parser.add_argument("--seed", type=int, default=None, help="Optional PRBS31 seed")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    modem = EightPskModem()

    tx = modem.transmit_prbs31(args.bits, seed=args.seed)
    rx_samples = apply_frequency_offset(
        tx.samples, args.cfo_hz, modem.config.sample_rate_sps
    )
    if args.snr_db is not None:
        rx_samples = add_awgn(rx_samples, args.snr_db, rng=np.random.default_rng(1234))

    rx = modem.receive_samples(rx_samples, symbol_count=tx.symbols.size)
    recovered_bits = rx.bits[: tx.input_bits.size]
    bit_errors = int(np.count_nonzero(recovered_bits != tx.input_bits))
    ber = bit_errors / tx.input_bits.size

    print("8-PSK modem simulation")
    print(f"  bit rate:             {modem.config.bit_rate_bps / 1e9:.3f} Gbps")
    print(f"  symbol rate:          {modem.config.symbol_rate_baud / 1e9:.3f} Gbaud")
    print(f"  ADC/DAC sample rate:  {modem.config.sample_rate_sps / 1e9:.3f} GSPS")
    print(f"  samples/symbol:       {modem.config.samples_per_symbol}")
    print(f"  SRRC rolloff:         {modem.config.rolloff:.2f}")
    print(f"  injected CFO:         {args.cfo_hz:.3f} Hz")
    print(f"  estimated CFO:        {rx.frequency_offset_hz:.3f} Hz")
    print(f"  residual phase:       {rx.phase_offset_rad:.6f} rad")
    print(f"  bit errors:           {bit_errors}")
    print(f"  BER:                  {ber:.6e}")


if __name__ == "__main__":
    main()

