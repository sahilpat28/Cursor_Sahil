// Natural-code 8-PSK mapper.
//
// Fixed-point format:
//   I/Q outputs are signed Q1.15.
//   000 -> 0 deg, 001 -> 45 deg, ..., 111 -> 315 deg.

`timescale 1ns/1ps

module psk8_mapper (
    input  wire [2:0] bits,
    output reg  signed [15:0] i_out,
    output reg  signed [15:0] q_out
);
    always @* begin
        case (bits)
            3'b000: begin i_out =  16'sd32767; q_out =      16'sd0; end
            3'b001: begin i_out =  16'sd23170; q_out =  16'sd23170; end
            3'b010: begin i_out =      16'sd0; q_out =  16'sd32767; end
            3'b011: begin i_out = -16'sd23170; q_out =  16'sd23170; end
            3'b100: begin i_out = -16'sd32767; q_out =      16'sd0; end
            3'b101: begin i_out = -16'sd23170; q_out = -16'sd23170; end
            3'b110: begin i_out =      16'sd0; q_out = -16'sd32767; end
            3'b111: begin i_out =  16'sd23170; q_out = -16'sd23170; end
            default: begin i_out =      16'sd0; q_out =      16'sd0; end
        endcase
    end
endmodule

