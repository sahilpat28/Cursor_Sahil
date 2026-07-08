// Top-level 8-PSK modem datapath.
//
// Ports are complex baseband I/Q. Use external DUC/DDC blocks if the system
// ADC/DAC interface is passband rather than complex baseband.

`timescale 1ns/1ps

module psk8_modem_top #(
    parameter [1:0] RX_SYMBOL_SAMPLE_PHASE = 2'd0,
    parameter integer RX_STARTUP_SAMPLES = 40
) (
    input  wire                    clk,
    input  wire                    rst,

    // One pulse per 4-GSPS-equivalent sample.
    input  wire                    sample_valid,

    // PRBS31 source control. A zero seed is replaced with the default non-zero
    // PRBS31 seed.
    input  wire                    seed_load,
    input  wire [30:0]             prbs_seed,

    // Receiver frequency-correction control.
    input  wire signed [15:0]      rx_phase_inc,
    input  wire                    rx_phase_clear,

    // DAC output samples from the transmitter.
    output wire                    dac_valid,
    output wire signed [15:0]      dac_i,
    output wire signed [15:0]      dac_q,

    // ADC input samples into the receiver.
    input  wire                    adc_valid,
    input  wire signed [15:0]      adc_i,
    input  wire signed [15:0]      adc_q,

    // Symbol monitor and recovered data.
    output wire [2:0]              tx_bits,
    output wire                    tx_symbol_valid,
    output wire [2:0]              rx_bits,
    output wire                    rx_bits_valid,

    // Debug outputs after receiver correction and matched filtering.
    output wire signed [15:0]      corrected_i,
    output wire signed [15:0]      corrected_q,
    output wire signed [15:0]      matched_i,
    output wire signed [15:0]      matched_q
);
    psk8_tx tx (
        .clk(clk),
        .rst(rst),
        .sample_valid(sample_valid),
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
        .STARTUP_SAMPLES(RX_STARTUP_SAMPLES)
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

