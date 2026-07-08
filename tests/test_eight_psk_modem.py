import unittest

import numpy as np

from eight_psk_modem import (
    EightPskModem,
    ModemConfig,
    apply_frequency_offset,
    demap_8psk_to_bits,
    map_bits_to_8psk,
    prbs31_bits,
    srrc_taps,
)


class ModemConfigTest(unittest.TestCase):
    def test_requested_rates_produce_four_samples_per_symbol(self):
        config = ModemConfig()

        self.assertEqual(config.bits_per_symbol, 3)
        self.assertEqual(config.symbol_rate_baud, 1.0e9)
        self.assertEqual(config.samples_per_symbol, 4)


class Prbs31Test(unittest.TestCase):
    def test_prbs31_is_deterministic_and_nonzero(self):
        first = prbs31_bits(128, seed=0x1234567)
        second = prbs31_bits(128, seed=0x1234567)

        np.testing.assert_array_equal(first, second)
        self.assertGreater(first.sum(), 0)
        self.assertLess(first.sum(), first.size)

    def test_rejects_zero_seed(self):
        with self.assertRaises(ValueError):
            prbs31_bits(8, seed=0)


class NaturalMappingTest(unittest.TestCase):
    def test_natural_mapping_phase_order(self):
        bits = np.array(
            [
                0,
                0,
                0,
                0,
                0,
                1,
                0,
                1,
                0,
                0,
                1,
                1,
                1,
                0,
                0,
                1,
                0,
                1,
                1,
                1,
                0,
                1,
                1,
                1,
            ],
            dtype=np.uint8,
        )

        symbols, pad_bits = map_bits_to_8psk(bits)

        self.assertEqual(pad_bits, 0)
        expected = np.exp(1j * 2.0 * np.pi * np.arange(8) / 8.0)
        np.testing.assert_allclose(symbols, expected, atol=1e-12)
        np.testing.assert_array_equal(demap_8psk_to_bits(symbols), bits)


class SrrcTest(unittest.TestCase):
    def test_srrc_taps_are_odd_length_and_unit_energy(self):
        taps = srrc_taps(rolloff=0.35, samples_per_symbol=4, span_symbols=10)

        self.assertEqual(taps.size % 2, 1)
        self.assertAlmostEqual(float(np.sum(taps * taps)), 1.0, places=12)


class EndToEndModemTest(unittest.TestCase):
    def test_clean_link_recovers_prbs31_bits(self):
        modem = EightPskModem()
        tx = modem.transmit_prbs31(3072)

        rx = modem.receive_samples(tx.samples, symbol_count=tx.symbols.size)

        np.testing.assert_array_equal(rx.bits[: tx.input_bits.size], tx.input_bits)
        self.assertAlmostEqual(rx.frequency_offset_hz, 0.0, delta=1.0)

    def test_receiver_corrects_frequency_offset(self):
        modem = EightPskModem()
        tx = modem.transmit_prbs31(6144)
        injected_cfo_hz = 10.0e6
        impaired = apply_frequency_offset(
            tx.samples, injected_cfo_hz, modem.config.sample_rate_sps
        )

        rx = modem.receive_samples(impaired, symbol_count=tx.symbols.size)

        np.testing.assert_array_equal(rx.bits[: tx.input_bits.size], tx.input_bits)
        self.assertAlmostEqual(rx.frequency_offset_hz, injected_cfo_hz, delta=50.0e3)


if __name__ == "__main__":
    unittest.main()

