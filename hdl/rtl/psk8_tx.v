// PRBS31 -> natural 8-PSK -> 4x upsample -> SRRC transmit filter.
//
// The design assumes one clk tick per ADC/DAC sample. At 4 GSPS, every fourth
// tick launches one 8-PSK symbol, giving 1 Gbaud and 3 Gbps with 3 bits/symbol.

`timescale 1ns/1ps

module psk8_tx (
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    sample_valid,
    input  wire                    seed_load,
    input  wire [30:0]             prbs_seed,
    output wire                    dac_valid,
    output wire signed [15:0]      dac_i,
    output wire signed [15:0]      dac_q,
    output reg  [2:0]              tx_bits,
    output reg                     tx_symbol_valid
);
    reg [1:0] sample_phase;
    reg [30:0] lfsr;

    wire symbol_ce = sample_valid && (sample_phase == 2'd0);
    wire [2:0] current_bits = prbs31_bits3(lfsr);
    wire signed [15:0] mapped_i;
    wire signed [15:0] mapped_q;
    wire signed [15:0] fir_i_in = symbol_ce ? mapped_i : 16'sd0;
    wire signed [15:0] fir_q_in = symbol_ce ? mapped_q : 16'sd0;

    psk8_mapper mapper_iq (
        .bits(current_bits),
        .i_out(mapped_i),
        .q_out(mapped_q)
    );

    srrc_fir tx_filter (
        .clk(clk),
        .rst(rst),
        .in_valid(sample_valid),
        .i_in(fir_i_in),
        .q_in(fir_q_in),
        .out_valid(dac_valid),
        .i_out(dac_i),
        .q_out(dac_q)
    );

    always @(posedge clk) begin
        if (rst) begin
            sample_phase <= 2'd0;
            lfsr <= 31'h7fffffff;
            tx_bits <= 3'd0;
            tx_symbol_valid <= 1'b0;
        end else begin
            tx_symbol_valid <= 1'b0;

            if (seed_load) begin
                lfsr <= (prbs_seed == 31'd0) ? 31'h7fffffff : prbs_seed;
                sample_phase <= 2'd0;
            end else if (sample_valid) begin
                if (symbol_ce) begin
                    tx_bits <= current_bits;
                    tx_symbol_valid <= 1'b1;
                    lfsr <= prbs31_next3(lfsr);
                end

                if (sample_phase == 2'd3) begin
                    sample_phase <= 2'd0;
                end else begin
                    sample_phase <= sample_phase + 2'd1;
                end
            end
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

