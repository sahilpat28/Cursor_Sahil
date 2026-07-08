// 41-tap square-root-raised-cosine FIR.
//
// Coefficients:
//   rolloff = 0.35
//   samples/symbol = 4
//   span = 10 symbols
//   coefficient format = signed Q1.15
//
// Data format:
//   input/output I/Q = signed Q1.15

`timescale 1ns/1ps

module srrc_fir (
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    in_valid,
    input  wire signed [15:0]      i_in,
    input  wire signed [15:0]      q_in,
    output reg                     out_valid,
    output reg  signed [15:0]      i_out,
    output reg  signed [15:0]      q_out
);
    localparam integer TAPS = 41;

    reg signed [15:0] shift_i [0:TAPS-1];
    reg signed [15:0] shift_q [0:TAPS-1];
    reg signed [47:0] acc_i;
    reg signed [47:0] acc_q;
    integer n;

    function signed [15:0] srrc_coeff;
        input integer tap;
        begin
            case (tap)
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

    always @(posedge clk) begin
        if (rst) begin
            for (n = 0; n < TAPS; n = n + 1) begin
                shift_i[n] <= 16'sd0;
                shift_q[n] <= 16'sd0;
            end
            out_valid <= 1'b0;
            i_out <= 16'sd0;
            q_out <= 16'sd0;
        end else if (in_valid) begin
            for (n = TAPS-1; n > 0; n = n - 1) begin
                shift_i[n] <= shift_i[n-1];
                shift_q[n] <= shift_q[n-1];
            end
            shift_i[0] <= i_in;
            shift_q[0] <= q_in;

            acc_i = $signed(i_in) * $signed(srrc_coeff(0));
            acc_q = $signed(q_in) * $signed(srrc_coeff(0));
            for (n = 1; n < TAPS; n = n + 1) begin
                acc_i = acc_i + ($signed(shift_i[n-1]) * $signed(srrc_coeff(n)));
                acc_q = acc_q + ($signed(shift_q[n-1]) * $signed(srrc_coeff(n)));
            end

            i_out <= sat_q15(acc_i);
            q_out <= sat_q15(acc_q);
            out_valid <= 1'b1;
        end else begin
            out_valid <= 1'b0;
        end
    end
endmodule

