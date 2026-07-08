// 500 MHz PRBS31 -> natural 8-PSK -> 4x upsample -> SRRC transmit filter.
//
// The design processes eight 4-GSPS-equivalent samples per 500 MHz clock.
// At 4 samples/symbol, every clock launches two 8-PSK symbols:
//   lane 0 = symbol 0
//   lane 4 = symbol 1
//
// This sustains 1 Gbaud and therefore 3 Gbps with 8-PSK.

`timescale 1ns/1ps

module psk8_tx (
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    block_valid,
    input  wire                    seed_load,
    input  wire [30:0]             prbs_seed,
    output wire                    dac_valid,
    output wire signed [127:0]     dac_i,
    output wire signed [127:0]     dac_q,
    output wire [5:0]              tx_bits,
    output wire [1:0]              tx_symbol_valid
);
    reg [30:0] lfsr;

    wire [2:0] bits0 = prbs31_bits3(lfsr);
    wire [30:0] lfsr_after_bits0 = prbs31_next3(lfsr);
    wire [2:0] bits1 = prbs31_bits3(lfsr_after_bits0);
    wire [30:0] lfsr_after_bits1 = prbs31_next3(lfsr_after_bits0);
    wire signed [15:0] mapped_i0;
    wire signed [15:0] mapped_q0;
    wire signed [15:0] mapped_i1;
    wire signed [15:0] mapped_q1;
    wire active_block = block_valid && !seed_load;
    wire signed [127:0] fir_i_in;
    wire signed [127:0] fir_q_in;

    assign tx_bits = {bits1, bits0};
    assign tx_symbol_valid = {2{active_block}};

    assign fir_i_in[15:0]    = active_block ? mapped_i0 : 16'sd0;
    assign fir_i_in[31:16]   = 16'sd0;
    assign fir_i_in[47:32]   = 16'sd0;
    assign fir_i_in[63:48]   = 16'sd0;
    assign fir_i_in[79:64]   = active_block ? mapped_i1 : 16'sd0;
    assign fir_i_in[95:80]   = 16'sd0;
    assign fir_i_in[111:96]  = 16'sd0;
    assign fir_i_in[127:112] = 16'sd0;

    assign fir_q_in[15:0]    = active_block ? mapped_q0 : 16'sd0;
    assign fir_q_in[31:16]   = 16'sd0;
    assign fir_q_in[47:32]   = 16'sd0;
    assign fir_q_in[63:48]   = 16'sd0;
    assign fir_q_in[79:64]   = active_block ? mapped_q1 : 16'sd0;
    assign fir_q_in[95:80]   = 16'sd0;
    assign fir_q_in[111:96]  = 16'sd0;
    assign fir_q_in[127:112] = 16'sd0;

    psk8_mapper mapper_symbol0 (
        .bits(bits0),
        .i_out(mapped_i0),
        .q_out(mapped_q0)
    );

    psk8_mapper mapper_symbol1 (
        .bits(bits1),
        .i_out(mapped_i1),
        .q_out(mapped_q1)
    );

    srrc_fir_8x tx_filter (
        .clk(clk),
        .rst(rst),
        .in_valid(block_valid),
        .i_in(fir_i_in),
        .q_in(fir_q_in),
        .out_valid(dac_valid),
        .i_out(dac_i),
        .q_out(dac_q)
    );

    always @(posedge clk) begin
        if (rst) begin
            lfsr <= 31'h7fffffff;
        end else if (seed_load) begin
                lfsr <= (prbs_seed == 31'd0) ? 31'h7fffffff : prbs_seed;
        end else if (block_valid) begin
            lfsr <= lfsr_after_bits1;
        end
    end

    function [2:0] prbs31_bits3;
        input [30:0] state_in;
        reg [30:0] tmp;
        reg [2:0] out_bits;
        reg feedback;
        integer k;
        begin
            tmp = state_in;
            for (k = 0; k < 3; k = k + 1) begin
                out_bits[2-k] = tmp[30];
                feedback = tmp[30] ^ tmp[27];
                tmp = {tmp[29:0], feedback};
            end
            prbs31_bits3 = out_bits;
        end
    endfunction

    function [30:0] prbs31_next3;
        input [30:0] state_in;
        reg [30:0] tmp;
        reg feedback;
        integer k;
        begin
            tmp = state_in;
            for (k = 0; k < 3; k = k + 1) begin
                feedback = tmp[30] ^ tmp[27];
                tmp = {tmp[29:0], feedback};
            end
            prbs31_next3 = tmp;
        end
    endfunction
endmodule

