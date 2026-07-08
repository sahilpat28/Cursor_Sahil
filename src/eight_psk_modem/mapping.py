"""Natural-code 8-PSK mapper and demapper."""

from __future__ import annotations

import numpy as np

BITS_PER_8PSK_SYMBOL = 3
EIGHT_PSK_ORDER = 8


def pad_bits_to_symbols(bits: np.ndarray) -> tuple[np.ndarray, int]:
    """Pad a bit vector to a whole number of 8-PSK symbols."""

    bit_array = np.asarray(bits, dtype=np.uint8).reshape(-1)
    if np.any((bit_array != 0) & (bit_array != 1)):
        raise ValueError("bits must contain only 0 and 1 values")

    remainder = bit_array.size % BITS_PER_8PSK_SYMBOL
    if remainder == 0:
        return bit_array.copy(), 0

    pad_count = BITS_PER_8PSK_SYMBOL - remainder
    return np.pad(bit_array, (0, pad_count), constant_values=0), pad_count


def bits_to_natural_indices(bits: np.ndarray) -> tuple[np.ndarray, int]:
    """Convert MSB-first bit triples into natural binary 8-PSK indices."""

    padded_bits, pad_count = pad_bits_to_symbols(bits)
    triples = padded_bits.reshape((-1, BITS_PER_8PSK_SYMBOL))
    indices = (triples[:, 0] << 2) | (triples[:, 1] << 1) | triples[:, 2]
    return indices.astype(np.uint8), pad_count


def natural_indices_to_bits(indices: np.ndarray) -> np.ndarray:
    """Convert natural binary 8-PSK indices into MSB-first bit triples."""

    symbol_indices = np.asarray(indices, dtype=np.uint8).reshape(-1)
    if np.any(symbol_indices >= EIGHT_PSK_ORDER):
        raise ValueError("8-PSK indices must be in [0, 7]")

    bits = np.empty(symbol_indices.size * BITS_PER_8PSK_SYMBOL, dtype=np.uint8)
    bits[0::3] = (symbol_indices >> 2) & 0x1
    bits[1::3] = (symbol_indices >> 1) & 0x1
    bits[2::3] = symbol_indices & 0x1
    return bits


def map_bits_to_8psk(bits: np.ndarray, phase_offset_rad: float = 0.0) -> tuple[np.ndarray, int]:
    """Map bits to unit-energy natural-code 8-PSK symbols.

    Natural coding means 000 -> phase 0, 001 -> pi/4, ..., 111 -> 7*pi/4.
    """

    indices, pad_count = bits_to_natural_indices(bits)
    phases = phase_offset_rad + (2.0 * np.pi * indices / EIGHT_PSK_ORDER)
    return np.exp(1j * phases), pad_count


def demap_8psk_to_bits(symbols: np.ndarray, phase_offset_rad: float = 0.0) -> np.ndarray:
    """Hard-decision natural-code 8-PSK demapper."""

    symbol_array = np.asarray(symbols, dtype=np.complex128).reshape(-1)
    phases = (np.angle(symbol_array) - phase_offset_rad) % (2.0 * np.pi)
    decision_width = 2.0 * np.pi / EIGHT_PSK_ORDER
    indices = np.floor((phases + 0.5 * decision_width) / decision_width).astype(np.uint8)
    indices %= EIGHT_PSK_ORDER
    return natural_indices_to_bits(indices)

