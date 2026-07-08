"""Configuration for the 8-PSK modem reference design."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class ModemConfig:
    """Physical and DSP parameters for the requested modem design.

    The requested 3 Gbps payload with 8-PSK produces a 1 Gbaud symbol stream.
    With a 4 GSPS ADC/DAC rate, the pulse-shaping path uses exactly
    4 samples/symbol.
    """

    bit_rate_bps: float = 3.0e9
    sample_rate_sps: float = 4.0e9
    modulation_order: int = 8
    rolloff: float = 0.35
    srrc_span_symbols: int = 10

    @property
    def bits_per_symbol(self) -> int:
        return (self.modulation_order.bit_length() - 1)

    @property
    def symbol_rate_baud(self) -> float:
        return self.bit_rate_bps / self.bits_per_symbol

    @property
    def samples_per_symbol(self) -> int:
        samples = self.sample_rate_sps / self.symbol_rate_baud
        rounded = round(samples)
        if abs(samples - rounded) > 1e-9:
            raise ValueError(
                "ADC/DAC sample rate must be an integer multiple of symbol rate; "
                f"got {samples:.6f} samples/symbol"
            )
        return int(rounded)

    def validate(self) -> None:
        if self.modulation_order != 8:
            raise ValueError("This reference design is fixed to 8-PSK.")
        if self.bits_per_symbol != 3:
            raise ValueError("8-PSK must carry 3 bits/symbol.")
        if not 0.0 <= self.rolloff <= 1.0:
            raise ValueError("SRRC rolloff must be in [0, 1].")
        if self.samples_per_symbol != 4:
            raise ValueError(
                "Requested 3 Gbps and 4 GSPS design must use 4 samples/symbol."
            )
        if self.srrc_span_symbols <= 0:
            raise ValueError("SRRC span must be positive.")

