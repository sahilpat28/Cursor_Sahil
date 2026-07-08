// Quartus compile/timing wrapper for the 8-PSK modem core.
//
// psk8_modem_top exposes the full packed 8-lane DAC/ADC sample interface. That
// is the reusable modem core interface, but it is too wide to map directly to
// package pins in a standalone Quartus compile. This wrapper keeps those wide
// sample buses internal for fitter/timing analysis and exposes only a small
// control/status interface.
//
// For a board design, connect psk8_modem_top to the real ADC/DAC, JESD, F-Tile,
// or custom converter interface. Use this wrapper when compiling the modem core
// by itself in Quartus Prime Pro.

`timescale 1ns/1ps

module psk8_modem_quartus_top (
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    block_valid,
    input  wire                    seed_load,
    input  wire [30:0]             prbs_seed,
    input  wire signed [15:0]      rx_phase_inc,
    input  wire                    rx_phase_clear,
    output wire [5:0]              tx_bits,
    output wire [1:0]              tx_symbol_valid,
    output wire [5:0]              rx_bits,
    output wire [1:0]              rx_bits_valid
);
    wire                    dac_valid;
    wire signed [127:0]     dac_i;
    wire signed [127:0]     dac_q;
    wire signed [127:0]     corrected_i;
    wire signed [127:0]     corrected_q;
    wire signed [127:0]     matched_i;
    wire signed [127:0]     matched_q;

    psk8_modem_top #(
        .RX_SYMBOL_SAMPLE_PHASE(2'd0),
        .RX_STARTUP_BLOCKS(5)
    ) modem_core (
        .clk(clk),
        .rst(rst),
        .block_valid(block_valid),
        .seed_load(seed_load),
        .prbs_seed(prbs_seed),
        .rx_phase_inc(rx_phase_inc),
        .rx_phase_clear(rx_phase_clear),
        .dac_valid(dac_valid),
        .dac_i(dac_i),
        .dac_q(dac_q),
        .adc_valid(dac_valid),
        .adc_i(dac_i),
        .adc_q(dac_q),
        .tx_bits(tx_bits),
        .tx_symbol_valid(tx_symbol_valid),
        .rx_bits(rx_bits),
        .rx_bits_valid(rx_bits_valid),
        .corrected_i(corrected_i),
        .corrected_q(corrected_q),
        .matched_i(matched_i),
        .matched_q(matched_q)
    );
endmodule

