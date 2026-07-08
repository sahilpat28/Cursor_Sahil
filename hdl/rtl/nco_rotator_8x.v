// Pipelined 8-sample-per-clock complex NCO rotator.
//
// This block runs at the 500 MHz RTL clock and rotates eight consecutive
// 4-GSPS samples per clock. The tuning word is still per 4-GSPS sample:
//
//   phase_inc = round(freq_hz / 4.0e9 * 2^16)
//
// For +10 MHz at 4 GSPS, phase_inc = +164. For receiver correction of a
// +10 MHz offset, program -164.
//
// Timing-oriented pipeline:
//   stage P : register input sample lanes and sine/cosine LUT outputs
//   stage M : register four 16x16 products per lane
//   stage O : register complex add/subtract, rounding, and saturation
//
// Data format:
//   input/output I/Q lanes = signed Q1.15
//   packed vector lane N = bits [16*N +: 16]

`timescale 1ns/1ps

module nco_rotator_8x (
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    in_valid,
    input  wire                    phase_clear,
    input  wire signed [15:0]      phase_inc,
    input  wire signed [127:0]     i_in,
    input  wire signed [127:0]     q_in,
    output reg                     out_valid,
    output reg  signed [127:0]     i_out,
    output reg  signed [127:0]     q_out
);
    localparam integer LANES = 8;

    reg [15:0] phase_acc;
    reg [2:0] valid_pipe;

    reg signed [15:0] sample_i_p [0:LANES-1];
    reg signed [15:0] sample_q_p [0:LANES-1];
    reg signed [15:0] cos_p [0:LANES-1];
    reg signed [15:0] sin_p [0:LANES-1];

    reg signed [31:0] i_cos_m [0:LANES-1];
    reg signed [31:0] q_sin_m [0:LANES-1];
    reg signed [31:0] i_sin_m [0:LANES-1];
    reg signed [31:0] q_cos_m [0:LANES-1];

    reg signed [31:0] lane_phase_full;
    reg [15:0] lane_phase;
    reg signed [32:0] i_mix;
    reg signed [32:0] q_mix;
    integer lane;

    wire signed [18:0] phase_advance = $signed(phase_inc) * 19'sd8;

    always @(posedge clk) begin
        if (rst || phase_clear) begin
            phase_acc <= 16'd0;
            valid_pipe <= 3'd0;
            out_valid <= 1'b0;
            i_out <= 128'sd0;
            q_out <= 128'sd0;
            for (lane = 0; lane < LANES; lane = lane + 1) begin
                sample_i_p[lane] <= 16'sd0;
                sample_q_p[lane] <= 16'sd0;
                cos_p[lane] <= 16'sd0;
                sin_p[lane] <= 16'sd0;
                i_cos_m[lane] <= 32'sd0;
                q_sin_m[lane] <= 32'sd0;
                i_sin_m[lane] <= 32'sd0;
                q_cos_m[lane] <= 32'sd0;
            end
        end else begin
            valid_pipe <= {valid_pipe[1:0], in_valid};
            out_valid <= valid_pipe[1];

            if (in_valid) begin
                phase_acc <= phase_acc + phase_advance[15:0];
                for (lane = 0; lane < LANES; lane = lane + 1) begin
                    lane_phase_full = $signed({1'b0, phase_acc})
                                    + ($signed(phase_inc) * lane);
                    lane_phase = lane_phase_full[15:0];

                    sample_i_p[lane] <= i_in[lane * 16 +: 16];
                    sample_q_p[lane] <= q_in[lane * 16 +: 16];
                    cos_p[lane] <= cos_lut(lane_phase[15:11]);
                    sin_p[lane] <= sin_lut(lane_phase[15:11]);
                end
            end

            for (lane = 0; lane < LANES; lane = lane + 1) begin
                i_cos_m[lane] <= $signed(sample_i_p[lane]) * $signed(cos_p[lane]);
                q_sin_m[lane] <= $signed(sample_q_p[lane]) * $signed(sin_p[lane]);
                i_sin_m[lane] <= $signed(sample_i_p[lane]) * $signed(sin_p[lane]);
                q_cos_m[lane] <= $signed(sample_q_p[lane]) * $signed(cos_p[lane]);

                i_mix = $signed({i_cos_m[lane][31], i_cos_m[lane]})
                      - $signed({q_sin_m[lane][31], q_sin_m[lane]});
                q_mix = $signed({i_sin_m[lane][31], i_sin_m[lane]})
                      + $signed({q_cos_m[lane][31], q_cos_m[lane]});

                i_out[lane * 16 +: 16] <= sat_q15(i_mix);
                q_out[lane * 16 +: 16] <= sat_q15(q_mix);
            end
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

