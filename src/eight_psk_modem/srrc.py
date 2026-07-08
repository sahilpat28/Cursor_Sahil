"""Square-root raised cosine pulse shaping."""

from __future__ import annotations

import numpy as np


def srrc_taps(rolloff: float, samples_per_symbol: int, span_symbols: int) -> np.ndarray:
    """Create unit-energy SRRC FIR taps.

    Args:
        rolloff: SRRC excess bandwidth factor.
        samples_per_symbol: Oversampling ratio.
        span_symbols: Total filter span in symbols.
    """

    if not 0.0 <= rolloff <= 1.0:
        raise ValueError("rolloff must be in [0, 1]")
    if samples_per_symbol <= 0:
        raise ValueError("samples_per_symbol must be positive")
    if span_symbols <= 0:
        raise ValueError("span_symbols must be positive")

    half_span_samples = span_symbols * samples_per_symbol // 2
    sample_index = np.arange(-half_span_samples, half_span_samples + 1)
    time_symbols = sample_index / float(samples_per_symbol)

    taps = np.empty_like(time_symbols, dtype=np.float64)
    beta = rolloff
    eps = 1e-12

    for index, t_symbol in enumerate(time_symbols):
        if abs(t_symbol) < eps:
            taps[index] = 1.0 + beta * (4.0 / np.pi - 1.0)
        elif beta > 0.0 and abs(abs(4.0 * beta * t_symbol) - 1.0) < eps:
            taps[index] = (
                beta
                / np.sqrt(2.0)
                * (
                    (1.0 + 2.0 / np.pi) * np.sin(np.pi / (4.0 * beta))
                    + (1.0 - 2.0 / np.pi) * np.cos(np.pi / (4.0 * beta))
                )
            )
        else:
            if beta == 0.0:
                taps[index] = np.sin(np.pi * t_symbol) / (np.pi * t_symbol)
            else:
                numerator = (
                    np.sin(np.pi * t_symbol * (1.0 - beta))
                    + 4.0
                    * beta
                    * t_symbol
                    * np.cos(np.pi * t_symbol * (1.0 + beta))
                )
                denominator = np.pi * t_symbol * (1.0 - (4.0 * beta * t_symbol) ** 2)
                taps[index] = numerator / denominator

    energy = np.sum(taps * taps)
    if energy <= 0.0:
        raise ValueError("SRRC tap energy must be positive")
    return taps / np.sqrt(energy)


def upsample(symbols: np.ndarray, samples_per_symbol: int) -> np.ndarray:
    """Insert zeros between symbols for FIR pulse shaping."""

    symbol_array = np.asarray(symbols, dtype=np.complex128).reshape(-1)
    if samples_per_symbol <= 0:
        raise ValueError("samples_per_symbol must be positive")

    samples = np.zeros(symbol_array.size * samples_per_symbol, dtype=np.complex128)
    samples[::samples_per_symbol] = symbol_array
    return samples


def pulse_shape(symbols: np.ndarray, taps: np.ndarray, samples_per_symbol: int) -> np.ndarray:
    """Upsample and SRRC-filter symbols."""

    return np.convolve(upsample(symbols, samples_per_symbol), taps, mode="full")

