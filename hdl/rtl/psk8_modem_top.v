// Top-level 500 MHz 8-PSK modem datapath.
//
// Ports are complex baseband I/Q. Use external DUC/DDC blocks if the system
// ADC/DAC interface is passband rather than complex baseband.
//
// The RTL clock is 500 MHz. Each valid clock carries eight consecutive
// 4-GSPS-equivalent I/Q samples on packed vectors:
//   lane N = bits [16*N +: 16]

`timescale 1ns/1ps

module psk8_modem_top #(
    parameter [1:0] RX_SYMBOL_SAMPLE_PHASE = 2'd0,
    parameter integer RX_STARTUP_BLOCKS = 5
) (
    input  wire                    clk,
    input  wire                    rst,

    // One pulse per 500 MHz RTL clock block. Each block contains eight
    // 4-GSPS-equivalent samples.
    input  wire                    block_valid,

    // PRBS31 source control. A zero seed is replaced with the default non-zero
    // PRBS31 seed.
    input  wire                    seed_load,
    input  wire [30:0]             prbs_seed,

    // Receiver frequency-correction control.
    input  wire signed [15:0]      rx_phase_inc,
    input  wire                    rx_phase_clear,

    // DAC output sample blocks from the transmitter.
    output wire                    dac_valid,
    output wire signed [127:0]     dac_i,
    output wire signed [127:0]     dac_q,

    // ADC input sample blocks into the receiver.
    input  wire                    adc_valid,
    input  wire signed [127:0]     adc_i,
    input  wire signed [127:0]     adc_q,

    // Two symbols per 500 MHz clock. bits[2:0] is the first symbol in the
    // block, bits[5:3] is the second.
    output wire [5:0]              tx_bits,
    output wire [1:0]              tx_symbol_valid,
    output wire [5:0]              rx_bits,
    output wire [1:0]              rx_bits_valid,

    // Debug outputs after receiver correction and matched filtering.
    output wire signed [127:0]     corrected_i,
    output wire signed [127:0]     corrected_q,
    output wire signed [127:0]     matched_i,
    output wire signed [127:0]     matched_q
);
    psk8_tx tx (
        .clk(clk),
        .rst(rst),
        .block_valid(block_valid),
        .seed_load(seed_load),
        .prbs_seed(prbs_seed),
        .dac_valid(dac_valid),
        .dac_i(dac_i),
        .dac_q(dac_q),
        .tx_bits(tx_bits),
        .tx_symbol_valid(tx_symbol_valid)
    );

    psk8_rx #(
        .SYMBOL_SAMPLE_PHASE(RX_SYMBOL_SAMPLE_PHASE),
        .STARTUP_BLOCKS(RX_STARTUP_BLOCKS)
    ) rx (
        .clk(clk),
        .rst(rst),
        .adc_valid(adc_valid),
        .adc_i(adc_i),
        .adc_q(adc_q),
        .rx_phase_inc(rx_phase_inc),
        .rx_phase_clear(rx_phase_clear),
        .rx_bits(rx_bits),
        .rx_bits_valid(rx_bits_valid),
        .corrected_i(corrected_i),
        .corrected_q(corrected_q),
        .matched_i(matched_i),
        .matched_q(matched_q)
    );
endmodule

