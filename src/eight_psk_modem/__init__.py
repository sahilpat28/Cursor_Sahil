"""8-PSK modem reference design package."""

from .channel import add_awgn, apply_frequency_offset
from .config import ModemConfig
from .mapping import demap_8psk_to_bits, map_bits_to_8psk
from .modem import EightPskModem, ReceiveResult, TransmitResult
from .prbs import prbs31_bits
from .srrc import pulse_shape, srrc_taps

__all__ = [
    "EightPskModem",
    "ModemConfig",
    "ReceiveResult",
    "TransmitResult",
    "add_awgn",
    "apply_frequency_offset",
    "demap_8psk_to_bits",
    "map_bits_to_8psk",
    "prbs31_bits",
    "pulse_shape",
    "srrc_taps",
]

