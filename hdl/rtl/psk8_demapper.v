// Hard-decision natural-code 8-PSK demapper.
//
// The decision boundaries are at +/-22.5 degrees around each constellation
// point. The implementation avoids atan by comparing |Q/I| with tan(22.5 deg).

`timescale 1ns/1ps

module psk8_demapper (
    input  wire signed [15:0] i_in,
    input  wire signed [15:0] q_in,
    output reg  [2:0] bits_out
);
    localparam [15:0] TAN_22P5_Q15 = 16'd13573;

    reg [16:0] abs_i;
    reg [16:0] abs_q;
    reg        near_i_axis;
    reg        near_q_axis;

    always @* begin
        abs_i = i_in[15] ? {1'b0, (~i_in + 16'sd1)} : {1'b0, i_in};
        abs_q = q_in[15] ? {1'b0, (~q_in + 16'sd1)} : {1'b0, q_in};

        near_i_axis = ({abs_q, 15'b0} <= (abs_i * TAN_22P5_Q15));
        near_q_axis = ({abs_i, 15'b0} <= (abs_q * TAN_22P5_Q15));

        if (!i_in[15] && !q_in[15]) begin
            if (near_i_axis) begin
                bits_out = 3'b000;
            end else if (near_q_axis) begin
                bits_out = 3'b010;
            end else begin
                bits_out = 3'b001;
            end
        end else if (i_in[15] && !q_in[15]) begin
            if (near_q_axis) begin
                bits_out = 3'b010;
            end else if (near_i_axis) begin
                bits_out = 3'b100;
            end else begin
                bits_out = 3'b011;
            end
        end else if (i_in[15] && q_in[15]) begin
            if (near_i_axis) begin
                bits_out = 3'b100;
            end else if (near_q_axis) begin
                bits_out = 3'b110;
            end else begin
                bits_out = 3'b101;
            end
        end else begin
            if (near_q_axis) begin
                bits_out = 3'b110;
            end else if (near_i_axis) begin
                bits_out = 3'b000;
            end else begin
                bits_out = 3'b111;
            end
        end
    end
endmodule

