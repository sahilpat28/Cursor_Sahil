// Pipelined 8-sample-per-clock square-root-raised-cosine FIR.
//
// This block is the 500 MHz version of the 4 GSPS SRRC filter. Each clock
// processes eight consecutive complex samples:
//   lane 0 = earliest sample in the block
//   lane 7 = latest sample in the block
//
// Timing-oriented pipeline:
//   stage M  : registered 16x16 coefficient products for all lanes/taps
//   stage A1 : registered 41 -> 21 adder tree level
//   stage A2 : registered 21 -> 11 adder tree level
//   stage A3 : registered 11 -> 6 adder tree level
//   stage A4 : registered 6 -> 3 adder tree level
//   stage A5 : registered 3 -> 2 adder tree level
//   stage A6 : registered 2 -> 1 adder tree level
//   stage O  : registered Q1.15 rounding/saturation
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
    localparam integer PROD_COUNT = LANES * TAPS;
    localparam integer SUM1_COUNT = LANES * 21;
    localparam integer SUM2_COUNT = LANES * 11;
    localparam integer SUM3_COUNT = LANES * 6;
    localparam integer SUM4_COUNT = LANES * 3;
    localparam integer SUM5_COUNT = LANES * 2;
    localparam integer SUM6_COUNT = LANES;

    reg signed [15:0] history_i [0:TAPS-1];
    reg signed [15:0] history_q [0:TAPS-1];
    reg signed [31:0] prod_i [0:PROD_COUNT-1];
    reg signed [31:0] prod_q [0:PROD_COUNT-1];
    reg signed [47:0] sum1_i [0:SUM1_COUNT-1];
    reg signed [47:0] sum1_q [0:SUM1_COUNT-1];
    reg signed [47:0] sum2_i [0:SUM2_COUNT-1];
    reg signed [47:0] sum2_q [0:SUM2_COUNT-1];
    reg signed [47:0] sum3_i [0:SUM3_COUNT-1];
    reg signed [47:0] sum3_q [0:SUM3_COUNT-1];
    reg signed [47:0] sum4_i [0:SUM4_COUNT-1];
    reg signed [47:0] sum4_q [0:SUM4_COUNT-1];
    reg signed [47:0] sum5_i [0:SUM5_COUNT-1];
    reg signed [47:0] sum5_q [0:SUM5_COUNT-1];
    reg signed [47:0] sum6_i [0:SUM6_COUNT-1];
    reg signed [47:0] sum6_q [0:SUM6_COUNT-1];
    reg [6:0] valid_pipe;

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

    function signed [47:0] sext32;
        input signed [31:0] value;
        begin
            sext32 = {{16{value[31]}}, value};
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

    always @(posedge clk) begin
        if (rst) begin
            for (n = 0; n < TAPS; n = n + 1) begin
                history_i[n] <= 16'sd0;
                history_q[n] <= 16'sd0;
            end
            for (n = 0; n < PROD_COUNT; n = n + 1) begin
                prod_i[n] <= 32'sd0;
                prod_q[n] <= 32'sd0;
            end
            for (n = 0; n < SUM1_COUNT; n = n + 1) begin
                sum1_i[n] <= 48'sd0;
                sum1_q[n] <= 48'sd0;
            end
            for (n = 0; n < SUM2_COUNT; n = n + 1) begin
                sum2_i[n] <= 48'sd0;
                sum2_q[n] <= 48'sd0;
            end
            for (n = 0; n < SUM3_COUNT; n = n + 1) begin
                sum3_i[n] <= 48'sd0;
                sum3_q[n] <= 48'sd0;
            end
            for (n = 0; n < SUM4_COUNT; n = n + 1) begin
                sum4_i[n] <= 48'sd0;
                sum4_q[n] <= 48'sd0;
            end
            for (n = 0; n < SUM5_COUNT; n = n + 1) begin
                sum5_i[n] <= 48'sd0;
                sum5_q[n] <= 48'sd0;
            end
            for (n = 0; n < SUM6_COUNT; n = n + 1) begin
                sum6_i[n] <= 48'sd0;
                sum6_q[n] <= 48'sd0;
            end
            valid_pipe <= 7'd0;
            out_valid <= 1'b0;
            i_out <= 128'sd0;
            q_out <= 128'sd0;
        end else begin
            valid_pipe <= {valid_pipe[5:0], in_valid};
            out_valid <= valid_pipe[6];

            if (in_valid) begin
                for (n = TAPS-1; n >= LANES; n = n - 1) begin
                    history_i[n] <= history_i[n-LANES];
                    history_q[n] <= history_q[n-LANES];
                end
                for (n = 0; n < LANES; n = n + 1) begin
                    history_i[n] <= i_in[(LANES - 1 - n) * 16 +: 16];
                    history_q[n] <= q_in[(LANES - 1 - n) * 16 +: 16];
                end

                for (lane = 0; lane < LANES; lane = lane + 1) begin
                    for (tap = 0; tap < TAPS; tap = tap + 1) begin
                        if (tap <= lane) begin
                            sample_i = i_in[(lane - tap) * 16 +: 16];
                            sample_q = q_in[(lane - tap) * 16 +: 16];
                        end else begin
                            sample_i = history_i[tap - lane - 1];
                            sample_q = history_q[tap - lane - 1];
                        end

                        prod_i[lane*TAPS + tap] <=
                            $signed(sample_i) * $signed(srrc_coeff(tap));
                        prod_q[lane*TAPS + tap] <=
                            $signed(sample_q) * $signed(srrc_coeff(tap));
                    end
                end
            end

            for (lane = 0; lane < LANES; lane = lane + 1) begin
                for (n = 0; n < 20; n = n + 1) begin
                    sum1_i[lane*21 + n] <= sext32(prod_i[lane*TAPS + 2*n])
                                         + sext32(prod_i[lane*TAPS + 2*n + 1]);
                    sum1_q[lane*21 + n] <= sext32(prod_q[lane*TAPS + 2*n])
                                         + sext32(prod_q[lane*TAPS + 2*n + 1]);
                end
                sum1_i[lane*21 + 20] <= sext32(prod_i[lane*TAPS + 40]);
                sum1_q[lane*21 + 20] <= sext32(prod_q[lane*TAPS + 40]);

                for (n = 0; n < 10; n = n + 1) begin
                    sum2_i[lane*11 + n] <= sum1_i[lane*21 + 2*n]
                                         + sum1_i[lane*21 + 2*n + 1];
                    sum2_q[lane*11 + n] <= sum1_q[lane*21 + 2*n]
                                         + sum1_q[lane*21 + 2*n + 1];
                end
                sum2_i[lane*11 + 10] <= sum1_i[lane*21 + 20];
                sum2_q[lane*11 + 10] <= sum1_q[lane*21 + 20];

                for (n = 0; n < 5; n = n + 1) begin
                    sum3_i[lane*6 + n] <= sum2_i[lane*11 + 2*n]
                                        + sum2_i[lane*11 + 2*n + 1];
                    sum3_q[lane*6 + n] <= sum2_q[lane*11 + 2*n]
                                        + sum2_q[lane*11 + 2*n + 1];
                end
                sum3_i[lane*6 + 5] <= sum2_i[lane*11 + 10];
                sum3_q[lane*6 + 5] <= sum2_q[lane*11 + 10];

                for (n = 0; n < 3; n = n + 1) begin
                    sum4_i[lane*3 + n] <= sum3_i[lane*6 + 2*n]
                                        + sum3_i[lane*6 + 2*n + 1];
                    sum4_q[lane*3 + n] <= sum3_q[lane*6 + 2*n]
                                        + sum3_q[lane*6 + 2*n + 1];
                end

                sum5_i[lane*2] <= sum4_i[lane*3] + sum4_i[lane*3 + 1];
                sum5_q[lane*2] <= sum4_q[lane*3] + sum4_q[lane*3 + 1];
                sum5_i[lane*2 + 1] <= sum4_i[lane*3 + 2];
                sum5_q[lane*2 + 1] <= sum4_q[lane*3 + 2];

                sum6_i[lane] <= sum5_i[lane*2] + sum5_i[lane*2 + 1];
                sum6_q[lane] <= sum5_q[lane*2] + sum5_q[lane*2 + 1];

                i_out[lane * 16 +: 16] <= sat_q15(sum6_i[lane]);
                q_out[lane * 16 +: 16] <= sat_q15(sum6_q[lane]);
            end
        end
    end
endmodule

