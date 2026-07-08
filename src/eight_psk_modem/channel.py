"""Channel impairments used by the executable modem design."""

from __future__ import annotations

import numpy as np


def apply_frequency_offset(
    samples: np.ndarray, frequency_offset_hz: float, sample_rate_sps: float
) -> np.ndarray:
    """Apply carrier frequency offset to complex baseband samples."""

    sample_array = np.asarray(samples, dtype=np.complex128).reshape(-1)
    sample_index = np.arange(sample_array.size, dtype=np.float64)
    phase = 2.0 * np.pi * frequency_offset_hz * sample_index / sample_rate_sps
    return sample_array * np.exp(1j * phase)


def add_awgn(
    samples: np.ndarray, snr_db: float, rng: np.random.Generator | None = None
) -> np.ndarray:
    """Add complex AWGN at the requested signal-to-noise ratio."""

    sample_array = np.asarray(samples, dtype=np.complex128).reshape(-1)
    generator = rng if rng is not None else np.random.default_rng()
    signal_power = np.mean(np.abs(sample_array) ** 2)
    noise_power = signal_power / (10.0 ** (snr_db / 10.0))
    noise = np.sqrt(noise_power / 2.0) * (
        generator.standard_normal(sample_array.size)
        + 1j * generator.standard_normal(sample_array.size)
    )
    return sample_array + noise

