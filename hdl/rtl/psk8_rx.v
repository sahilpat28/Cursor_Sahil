// Receiver: frequency correction -> SRRC matched filter -> 8-PSK demapper.
//
// Frequency correction is applied with a signed 16-bit phase increment:
//   rx_phase_inc = round(-freq_offset_hz / 4e9 * 2^16)
// The estimator/control loop that chooses rx_phase_inc can be external to this
// datapath, or a fixed value can be programmed for a known offset.

`timescale 1ns/1ps

module psk8_rx #(
    parameter [1:0] SYMBOL_SAMPLE_PHASE = 2'd0,
    parameter integer STARTUP_SAMPLES = 40
) (
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    adc_valid,
    input  wire signed [15:0]      adc_i,
    input  wire signed [15:0]      adc_q,
    input  wire signed [15:0]      rx_phase_inc,
    input  wire                    rx_phase_clear,
    output reg  [2:0]              rx_bits,
    output reg                     rx_bits_valid,
    output wire signed [15:0]      corrected_i,
    output wire signed [15:0]      corrected_q,
    output wire signed [15:0]      matched_i,
    output wire signed [15:0]      matched_q
);
    wire corr_valid;
    wire mf_valid;
    wire [2:0] demap_bits;

    reg [1:0] sample_phase;
    reg [31:0] sample_count;
    reg symbol_gate_d;

    nco_rotator freq_corrector (
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

    srrc_fir rx_filter (
        .clk(clk),
        .rst(rst),
        .in_valid(corr_valid),
        .i_in(corrected_i),
        .q_in(corrected_q),
        .out_valid(mf_valid),
        .i_out(matched_i),
        .q_out(matched_q)
    );

    psk8_demapper demapper (
        .i_in(matched_i),
        .q_in(matched_q),
        .bits_out(demap_bits)
    );

    always @(posedge clk) begin
        if (rst) begin
            sample_phase <= 2'd0;
            sample_count <= 32'd0;
            symbol_gate_d <= 1'b0;
            rx_bits <= 3'd0;
            rx_bits_valid <= 1'b0;
        end else begin
            rx_bits_valid <= 1'b0;

            if (symbol_gate_d) begin
                rx_bits <= demap_bits;
                rx_bits_valid <= 1'b1;
            end

            symbol_gate_d <= 1'b0;
            if (adc_valid) begin
                symbol_gate_d <= (sample_count >= STARTUP_SAMPLES)
                               && (sample_phase == SYMBOL_SAMPLE_PHASE);
                sample_count <= sample_count + 32'd1;

                if (sample_phase == 2'd3) begin
                    sample_phase <= 2'd0;
                end else begin
                    sample_phase <= sample_phase + 2'd1;
                end
            end
        end
    end
endmodule

