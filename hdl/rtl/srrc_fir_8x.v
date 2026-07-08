// 8-sample-per-clock square-root-raised-cosine FIR.
//
// This block is the 500 MHz version of the 4 GSPS SRRC filter. Each clock
// processes eight consecutive complex samples:
//   lane 0 = earliest sample in the block
//   lane 7 = latest sample in the block
//
// Coefficients:
//   rolloff = 0.35
//   samples/symbol = 4
//   span = 10 symbols
//   taps = 41
//   coefficient format = signed Q1.15
//
// Data format:
//   input/output I/Q lanes = signed Q1.15
//   packed vector lane N = bits [16*N +: 16]

`timescale 1ns/1ps

module srrc_fir_8x (
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    in_valid,
    input  wire signed [127:0]     i_in,
    input  wire signed [127:0]     q_in,
    output reg                     out_valid,
    output reg  signed [127:0]     i_out,
    output reg  signed [127:0]     q_out
);
    localparam integer TAPS = 41;
    localparam integer LANES = 8;

    reg signed [15:0] history_i [0:TAPS-1];
    reg signed [15:0] history_q [0:TAPS-1];
    reg signed [15:0] next_i [0:LANES-1];
    reg signed [15:0] next_q [0:LANES-1];
    reg signed [47:0] acc_i;
    reg signed [47:0] acc_q;
    reg signed [15:0] sample_i;
    reg signed [15:0] sample_q;
    integer lane;
    integer tap;
    integer n;

    function signed [15:0] srrc_coeff;
        input integer coeff_index;
        begin
            case (coeff_index)
                0:  srrc_coeff =    16'sd123;
                1:  srrc_coeff =    -16'sd39;
                2:  srrc_coeff =   -16'sd191;
                3:  srrc_coeff =   -16'sd168;
                4:  srrc_coeff =     16'sd33;
                5:  srrc_coeff =    16'sd218;
                6:  srrc_coeff =    16'sd157;
                7:  srrc_coeff =   -16'sd156;
                8:  srrc_coeff =   -16'sd417;
                9:  srrc_coeff =   -16'sd242;
                10: srrc_coeff =    16'sd420;
                11: srrc_coeff =   16'sd1071;
                12: srrc_coeff =    16'sd936;
                13: srrc_coeff =   -16'sd362;
                14: srrc_coeff =  -16'sd2215;
                15: srrc_coeff =  -16'sd3091;
                16: srrc_coeff =  -16'sd1388;
                17: srrc_coeff =   16'sd3390;
                18: srrc_coeff =   16'sd9958;
                19: srrc_coeff =  16'sd15683;
                20: srrc_coeff =  16'sd17952;
                21: srrc_coeff =  16'sd15683;
                22: srrc_coeff =   16'sd9958;
                23: srrc_coeff =   16'sd3390;
                24: srrc_coeff =  -16'sd1388;
                25: srrc_coeff =  -16'sd3091;
                26: srrc_coeff =  -16'sd2215;
                27: srrc_coeff =   -16'sd362;
                28: srrc_coeff =    16'sd936;
                29: srrc_coeff =   16'sd1071;
                30: srrc_coeff =    16'sd420;
                31: srrc_coeff =   -16'sd242;
                32: srrc_coeff =   -16'sd417;
                33: srrc_coeff =   -16'sd156;
                34: srrc_coeff =    16'sd157;
                35: srrc_coeff =    16'sd218;
                36: srrc_coeff =     16'sd33;
                37: srrc_coeff =   -16'sd168;
                38: srrc_coeff =   -16'sd191;
                39: srrc_coeff =    -16'sd39;
                40: srrc_coeff =    16'sd123;
                default: srrc_coeff = 16'sd0;
            endcase
        end
    endfunction

    function signed [15:0] sat_q15;
        input signed [47:0] acc;
        reg signed [47:0] rounded;
        reg signed [32:0] scaled;
        begin
            rounded = acc + 48'sd16384;
            scaled = rounded >>> 15;

            if (scaled > 33'sd32767) begin
                sat_q15 = 16'sd32767;
            end else if (scaled < -33'sd32768) begin
                sat_q15 = -16'sd32768;
            end else begin
                sat_q15 = scaled[15:0];
            end
        end
    endfunction

    always @* begin
        for (lane = 0; lane < LANES; lane = lane + 1) begin
            acc_i = 48'sd0;
            acc_q = 48'sd0;

            for (tap = 0; tap < TAPS; tap = tap + 1) begin
                if (tap <= lane) begin
                    sample_i = i_in[(lane - tap) * 16 +: 16];
                    sample_q = q_in[(lane - tap) * 16 +: 16];
                end else begin
                    sample_i = history_i[tap - lane - 1];
                    sample_q = history_q[tap - lane - 1];
                end

                acc_i = acc_i + ($signed(sample_i) * $signed(srrc_coeff(tap)));
                acc_q = acc_q + ($signed(sample_q) * $signed(srrc_coeff(tap)));
            end

            next_i[lane] = sat_q15(acc_i);
            next_q[lane] = sat_q15(acc_q);
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            for (n = 0; n < TAPS; n = n + 1) begin
                history_i[n] <= 16'sd0;
                history_q[n] <= 16'sd0;
            end
            out_valid <= 1'b0;
            i_out <= 128'sd0;
            q_out <= 128'sd0;
        end else if (in_valid) begin
            for (n = TAPS-1; n >= LANES; n = n - 1) begin
                history_i[n] <= history_i[n-LANES];
                history_q[n] <= history_q[n-LANES];
            end
            for (n = 0; n < LANES; n = n + 1) begin
                history_i[n] <= i_in[(LANES - 1 - n) * 16 +: 16];
                history_q[n] <= q_in[(LANES - 1 - n) * 16 +: 16];
                i_out[n * 16 +: 16] <= next_i[n];
                q_out[n * 16 +: 16] <= next_q[n];
            end
            out_valid <= 1'b1;
        end else begin
            out_valid <= 1'b0;
        end
    end
endmodule

