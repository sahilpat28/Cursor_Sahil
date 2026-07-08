// 500 MHz receiver: frequency correction -> SRRC matched filter -> demapper.
//
// Frequency correction is applied with a signed 16-bit phase increment:
//   rx_phase_inc = round(-freq_offset_hz / 4e9 * 2^16)
// The estimator/control loop that chooses rx_phase_inc can be external to this
// datapath, or a fixed value can be programmed for a known offset.
//
// Eight 4-GSPS samples are processed per 500 MHz clock. The demapper samples
// two symbols per block at lanes SYMBOL_SAMPLE_PHASE and SYMBOL_SAMPLE_PHASE+4.

`timescale 1ns/1ps

module psk8_rx #(
    parameter [1:0] SYMBOL_SAMPLE_PHASE = 2'd0,
    parameter integer STARTUP_BLOCKS = 5
) (
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    adc_valid,
    input  wire signed [127:0]     adc_i,
    input  wire signed [127:0]     adc_q,
    input  wire signed [15:0]      rx_phase_inc,
    input  wire                    rx_phase_clear,
    output reg  [5:0]              rx_bits,
    output reg  [1:0]              rx_bits_valid,
    output wire signed [127:0]     corrected_i,
    output wire signed [127:0]     corrected_q,
    output wire signed [127:0]     matched_i,
    output wire signed [127:0]     matched_q
);
    wire corr_valid;
    wire mf_valid;
    wire [2:0] demap_bits0;
    wire [2:0] demap_bits1;

    reg [31:0] matched_block_count;

    wire signed [15:0] symbol0_i = matched_i[SYMBOL_SAMPLE_PHASE * 16 +: 16];
    wire signed [15:0] symbol0_q = matched_q[SYMBOL_SAMPLE_PHASE * 16 +: 16];
    wire signed [15:0] symbol1_i = matched_i[(SYMBOL_SAMPLE_PHASE + 4) * 16 +: 16];
    wire signed [15:0] symbol1_q = matched_q[(SYMBOL_SAMPLE_PHASE + 4) * 16 +: 16];

    nco_rotator_8x freq_corrector (
        .clk(clk),
        .rst(rst),
        .in_valid(adc_valid),
        .phase_clear(rx_phase_clear),
        .phase_inc(rx_phase_inc),
        .i_in(adc_i),
        .q_in(adc_q),
        .out_valid(corr_valid),
        .i_out(corrected_i),
        .q_out(corrected_q)
    );

    srrc_fir_8x rx_filter (
        .clk(clk),
        .rst(rst),
        .in_valid(corr_valid),
        .i_in(corrected_i),
        .q_in(corrected_q),
        .out_valid(mf_valid),
        .i_out(matched_i),
        .q_out(matched_q)
    );

    psk8_demapper demapper_symbol0 (
        .i_in(symbol0_i),
        .q_in(symbol0_q),
        .bits_out(demap_bits0)
    );

    psk8_demapper demapper_symbol1 (
        .i_in(symbol1_i),
        .q_in(symbol1_q),
        .bits_out(demap_bits1)
    );

    always @(posedge clk) begin
        if (rst) begin
            matched_block_count <= 32'd0;
            rx_bits <= 6'd0;
            rx_bits_valid <= 2'b00;
        end else begin
            rx_bits_valid <= 2'b00;

            if (mf_valid) begin
                if (matched_block_count >= STARTUP_BLOCKS) begin
                    rx_bits <= {demap_bits1, demap_bits0};
                    rx_bits_valid <= 2'b11;
                end
                matched_block_count <= matched_block_count + 32'd1;
            end
        end
    end
endmodule

