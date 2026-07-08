// Complex NCO rotator for receiver frequency correction or testbench CFO.
//
// phase_inc is a signed 16-bit tuning word:
//   phase_inc = round(freq_hz / sample_rate_hz * 2^16)
// For 4 GSPS, one LSB is approximately 61.035 kHz.
//
// Output is combinational for the current input sample and current phase. The
// phase accumulator advances on each valid sample.

`timescale 1ns/1ps

module nco_rotator (
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    in_valid,
    input  wire                    phase_clear,
    input  wire signed [15:0]      phase_inc,
    input  wire signed [15:0]      i_in,
    input  wire signed [15:0]      q_in,
    output wire                    out_valid,
    output wire signed [15:0]      i_out,
    output wire signed [15:0]      q_out
);
    reg [15:0] phase_acc;
    wire [4:0] lut_index = phase_acc[15:11];
    wire signed [15:0] cos_val = cos_lut(lut_index);
    wire signed [15:0] sin_val = sin_lut(lut_index);

    wire signed [31:0] i_cos = $signed(i_in) * $signed(cos_val);
    wire signed [31:0] q_sin = $signed(q_in) * $signed(sin_val);
    wire signed [31:0] i_sin = $signed(i_in) * $signed(sin_val);
    wire signed [31:0] q_cos = $signed(q_in) * $signed(cos_val);

    wire signed [32:0] i_mix = $signed({i_cos[31], i_cos}) - $signed({q_sin[31], q_sin});
    wire signed [32:0] q_mix = $signed({i_sin[31], i_sin}) + $signed({q_cos[31], q_cos});

    assign out_valid = in_valid;
    assign i_out = sat_q15(i_mix);
    assign q_out = sat_q15(q_mix);

    always @(posedge clk) begin
        if (rst || phase_clear) begin
            phase_acc <= 16'd0;
        end else if (in_valid) begin
            phase_acc <= phase_acc + phase_inc;
        end
    end

    function signed [15:0] sat_q15;
        input signed [32:0] acc;
        reg signed [32:0] rounded;
        reg signed [17:0] scaled;
        begin
            rounded = acc + 33'sd16384;
            scaled = rounded >>> 15;

            if (scaled > 18'sd32767) begin
                sat_q15 = 16'sd32767;
            end else if (scaled < -18'sd32768) begin
                sat_q15 = -16'sd32768;
            end else begin
                sat_q15 = scaled[15:0];
            end
        end
    endfunction

    function signed [15:0] cos_lut;
        input [4:0] idx;
        begin
            case (idx)
                5'd0:  cos_lut =  16'sd32767;
                5'd1:  cos_lut =  16'sd32137;
                5'd2:  cos_lut =  16'sd30273;
                5'd3:  cos_lut =  16'sd27245;
                5'd4:  cos_lut =  16'sd23170;
                5'd5:  cos_lut =  16'sd18204;
                5'd6:  cos_lut =  16'sd12539;
                5'd7:  cos_lut =   16'sd6393;
                5'd8:  cos_lut =      16'sd0;
                5'd9:  cos_lut =  -16'sd6393;
                5'd10: cos_lut = -16'sd12539;
                5'd11: cos_lut = -16'sd18204;
                5'd12: cos_lut = -16'sd23170;
                5'd13: cos_lut = -16'sd27245;
                5'd14: cos_lut = -16'sd30273;
                5'd15: cos_lut = -16'sd32137;
                5'd16: cos_lut = -16'sd32767;
                5'd17: cos_lut = -16'sd32137;
                5'd18: cos_lut = -16'sd30273;
                5'd19: cos_lut = -16'sd27245;
                5'd20: cos_lut = -16'sd23170;
                5'd21: cos_lut = -16'sd18204;
                5'd22: cos_lut = -16'sd12539;
                5'd23: cos_lut =  -16'sd6393;
                5'd24: cos_lut =      16'sd0;
                5'd25: cos_lut =   16'sd6393;
                5'd26: cos_lut =  16'sd12539;
                5'd27: cos_lut =  16'sd18204;
                5'd28: cos_lut =  16'sd23170;
                5'd29: cos_lut =  16'sd27245;
                5'd30: cos_lut =  16'sd30273;
                5'd31: cos_lut =  16'sd32137;
                default: cos_lut = 16'sd0;
            endcase
        end
    endfunction

    function signed [15:0] sin_lut;
        input [4:0] idx;
        begin
            case (idx)
                5'd0:  sin_lut =      16'sd0;
                5'd1:  sin_lut =   16'sd6393;
                5'd2:  sin_lut =  16'sd12539;
                5'd3:  sin_lut =  16'sd18204;
                5'd4:  sin_lut =  16'sd23170;
                5'd5:  sin_lut =  16'sd27245;
                5'd6:  sin_lut =  16'sd30273;
                5'd7:  sin_lut =  16'sd32137;
                5'd8:  sin_lut =  16'sd32767;
                5'd9:  sin_lut =  16'sd32137;
                5'd10: sin_lut =  16'sd30273;
                5'd11: sin_lut =  16'sd27245;
                5'd12: sin_lut =  16'sd23170;
                5'd13: sin_lut =  16'sd18204;
                5'd14: sin_lut =  16'sd12539;
                5'd15: sin_lut =   16'sd6393;
                5'd16: sin_lut =      16'sd0;
                5'd17: sin_lut =  -16'sd6393;
                5'd18: sin_lut = -16'sd12539;
                5'd19: sin_lut = -16'sd18204;
                5'd20: sin_lut = -16'sd23170;
                5'd21: sin_lut = -16'sd27245;
                5'd22: sin_lut = -16'sd30273;
                5'd23: sin_lut = -16'sd32137;
                5'd24: sin_lut = -16'sd32767;
                5'd25: sin_lut = -16'sd32137;
                5'd26: sin_lut = -16'sd30273;
                5'd27: sin_lut = -16'sd27245;
                5'd28: sin_lut = -16'sd23170;
                5'd29: sin_lut = -16'sd18204;
                5'd30: sin_lut = -16'sd12539;
                5'd31: sin_lut =  -16'sd6393;
                default: sin_lut = 16'sd0;
            endcase
        end
    endfunction
endmodule

