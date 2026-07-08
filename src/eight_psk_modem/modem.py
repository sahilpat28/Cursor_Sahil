"""End-to-end 8-PSK modem reference model."""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from .channel import apply_frequency_offset
from .config import ModemConfig
from .mapping import demap_8psk_to_bits, map_bits_to_8psk
from .prbs import prbs31_bits
from .srrc import pulse_shape, srrc_taps


@dataclass(frozen=True)
class TransmitResult:
    input_bits: np.ndarray
    symbols: np.ndarray
    samples: np.ndarray
    pad_bits: int


@dataclass(frozen=True)
class ReceiveResult:
    bits: np.ndarray
    symbols: np.ndarray
    frequency_offset_hz: float
    phase_offset_rad: float


def estimate_mpsk_frequency_offset(
    symbols: np.ndarray, symbol_rate_baud: float, modulation_order: int = 8
) -> float:
    """Estimate carrier frequency offset from M-PSK symbols.

    Raising M-PSK symbols to the Mth power removes data modulation. The
    remaining unwrapped phase slope is M times the carrier-frequency offset.
    """

    symbol_array = np.asarray(symbols, dtype=np.complex128).reshape(-1)
    if symbol_array.size < 2:
        return 0.0

    stripped = symbol_array**modulation_order
    phases = np.unwrap(np.angle(stripped))
    symbol_index = np.arange(symbol_array.size, dtype=np.float64)
    slope_rad_per_symbol, _ = np.polyfit(symbol_index, phases, deg=1)
    return slope_rad_per_symbol * symbol_rate_baud / (2.0 * np.pi * modulation_order)


def estimate_mpsk_phase_offset(symbols: np.ndarray, modulation_order: int = 8) -> float:
    """Estimate residual carrier phase after frequency correction."""

    symbol_array = np.asarray(symbols, dtype=np.complex128).reshape(-1)
    if symbol_array.size == 0:
        return 0.0
    return float(np.angle(np.mean(symbol_array**modulation_order)) / modulation_order)


class EightPskModem:
    """Reference modem for PRBS31 -> natural 8-PSK -> SRRC -> receiver recovery."""

    def __init__(self, config: ModemConfig | None = None):
        self.config = config or ModemConfig()
        self.config.validate()
        self.taps = srrc_taps(
            self.config.rolloff,
            self.config.samples_per_symbol,
            self.config.srrc_span_symbols,
        )

    def generate_prbs31_frame(self, bit_count: int, seed: int | None = None) -> np.ndarray:
        """Generate the configured PRBS31 source bits."""

        if seed is None:
            return prbs31_bits(bit_count)
        return prbs31_bits(bit_count, seed=seed)

    def transmit_bits(self, bits: np.ndarray) -> TransmitResult:
        """Map input bits into SRRC-shaped 8-PSK DAC samples."""

        symbols, pad_bits = map_bits_to_8psk(bits)
        samples = pulse_shape(symbols, self.taps, self.config.samples_per_symbol)
        return TransmitResult(
            input_bits=np.asarray(bits, dtype=np.uint8).reshape(-1).copy(),
            symbols=symbols,
            samples=samples,
            pad_bits=pad_bits,
        )

    def transmit_prbs31(self, bit_count: int, seed: int | None = None) -> TransmitResult:
        """Generate PRBS31 bits and transmit them."""

        return self.transmit_bits(self.generate_prbs31_frame(bit_count, seed=seed))

    def receive_samples(
        self,
        samples: np.ndarray,
        symbol_count: int | None = None,
        correct_frequency: bool = True,
    ) -> ReceiveResult:
        """Recover hard-decision bits from ADC samples."""

        sample_array = np.asarray(samples, dtype=np.complex128).reshape(-1)
        expected_symbols = symbol_count or self._infer_symbol_count(sample_array)

        tentative_symbols = self._matched_filter_and_downsample(
            sample_array, expected_symbols
        )
        frequency_offset_hz = 0.0
        corrected_samples = sample_array

        if correct_frequency:
            frequency_offset_hz = estimate_mpsk_frequency_offset(
                tentative_symbols,
                self.config.symbol_rate_baud,
                self.config.modulation_order,
            )
            corrected_samples = apply_frequency_offset(
                sample_array, -frequency_offset_hz, self.config.sample_rate_sps
            )

        recovered_symbols = self._matched_filter_and_downsample(
            corrected_samples, expected_symbols
        )
        phase_offset_rad = estimate_mpsk_phase_offset(
            recovered_symbols, self.config.modulation_order
        )
        recovered_symbols = recovered_symbols * np.exp(-1j * phase_offset_rad)
        recovered_bits = demap_8psk_to_bits(recovered_symbols)

        return ReceiveResult(
            bits=recovered_bits,
            symbols=recovered_symbols,
            frequency_offset_hz=float(frequency_offset_hz),
            phase_offset_rad=phase_offset_rad,
        )

    def _infer_symbol_count(self, samples: np.ndarray) -> int:
        shaped_length = samples.size - self.taps.size + 1
        if shaped_length < 0:
            return 0
        return shaped_length // self.config.samples_per_symbol

    def _matched_filter_and_downsample(
        self, samples: np.ndarray, symbol_count: int
    ) -> np.ndarray:
        matched = np.convolve(samples, self.taps, mode="full")
        group_delay_samples = self.taps.size - 1
        sample_indices = (
            group_delay_samples
            + np.arange(symbol_count, dtype=np.int64) * self.config.samples_per_symbol
        )
        valid_indices = sample_indices[sample_indices < matched.size]
        return matched[valid_indices]

