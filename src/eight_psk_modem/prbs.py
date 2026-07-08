"""PRBS31 source for modem test patterns."""

from __future__ import annotations

import numpy as np

PRBS31_MASK = (1 << 31) - 1
PRBS31_DEFAULT_SEED = PRBS31_MASK


def prbs31_bits(count: int, seed: int = PRBS31_DEFAULT_SEED) -> np.ndarray:
    """Generate ``count`` PRBS31 bits using x^31 + x^28 + 1.

    The returned array contains uint8 values in {0, 1}. A non-zero seed is
    required because an all-zero LFSR state is a lock-up state.
    """

    if count < 0:
        raise ValueError("count must be non-negative")

    state = seed & PRBS31_MASK
    if state == 0:
        raise ValueError("PRBS31 seed must be non-zero")

    bits = np.empty(count, dtype=np.uint8)
    for index in range(count):
        output = (state >> 30) & 0x1
        feedback = ((state >> 30) ^ (state >> 27)) & 0x1
        bits[index] = output
        state = ((state << 1) & PRBS31_MASK) | feedback

    return bits

