// Example SAT-style MPU register map.
//
// Replace this module with the real SAT / Ethernet control register file.
// The MPU bus is 32-bit data with byte address, chip select, write/read, and
// byte enables. Ack is combinatorial (zero wait states).

`timescale 1ns/1ps

module mpu_regmap_example #(
    parameter integer MPU_ADDR_W = 32,
    parameter [31:0]  REG_ID     = 32'h5341_5401
) (
    input  wire                    clk,
    input  wire                    rst,

    input  wire                    mpu_cs,
    input  wire                    mpu_we,
    input  wire                    mpu_re,
    input  wire [MPU_ADDR_W-1:0]   mpu_addr,
    input  wire [3:0]              mpu_be,
    input  wire [31:0]             mpu_wdata,
    output reg  [31:0]             mpu_rdata,
    output wire                    mpu_ack
);
    localparam integer N_USER = 8;

    reg [31:0] ctrl;
    reg [31:0] scratch;
    reg [31:0] irq_mask;
    reg [31:0] irq_status;
    reg [31:0] user [0:N_USER-1];

    wire [7:0] word_sel = mpu_addr[9:2];
    wire       wr = mpu_cs && mpu_we;
    wire       rd = mpu_cs && mpu_re;

    integer i;
    integer b;

    assign mpu_ack = mpu_cs;

    always @(posedge clk) begin
        if (rst) begin
            ctrl       <= 32'b0;
            scratch    <= 32'b0;
            irq_mask   <= 32'b0;
            irq_status <= 32'b0;
            for (i = 0; i < N_USER; i = i + 1)
                user[i] <= 32'b0;
        end else if (wr) begin
            case (word_sel)
                8'h00: begin
                    // ID is read-only
                end
                8'h01: begin
                    for (b = 0; b < 4; b = b + 1)
                        if (mpu_be[b])
                            ctrl[8*b +: 8] <= mpu_wdata[8*b +: 8];
                end
                8'h02: begin
                    // STATUS is read-only
                end
                8'h03: begin
                    for (b = 0; b < 4; b = b + 1)
                        if (mpu_be[b])
                            scratch[8*b +: 8] <= mpu_wdata[8*b +: 8];
                end
                8'h04: begin
                    for (b = 0; b < 4; b = b + 1)
                        if (mpu_be[b])
                            irq_mask[8*b +: 8] <= mpu_wdata[8*b +: 8];
                end
                8'h05: begin
                    for (b = 0; b < 4; b = b + 1)
                        if (mpu_be[b])
                            irq_status[8*b +: 8] <= irq_status[8*b +: 8] & ~mpu_wdata[8*b +: 8];
                end
                default: begin
                    if ((word_sel >= 8'h08) && (word_sel < (8'h08 + N_USER))) begin
                        for (b = 0; b < 4; b = b + 1)
                            if (mpu_be[b])
                                user[word_sel - 8'h08][8*b +: 8] <= mpu_wdata[8*b +: 8];
                    end
                end
            endcase
        end
    end

    always @* begin
        mpu_rdata = 32'b0;
        if (rd) begin
            case (word_sel)
                8'h00: mpu_rdata = REG_ID;
                8'h01: mpu_rdata = ctrl;
                8'h02: mpu_rdata = {16'b0, 8'h01, ctrl[7:0]};
                8'h03: mpu_rdata = scratch;
                8'h04: mpu_rdata = irq_mask;
                8'h05: mpu_rdata = irq_status;
                default: begin
                    if ((word_sel >= 8'h08) && (word_sel < (8'h08 + N_USER)))
                        mpu_rdata = user[word_sel - 8'h08];
                    else
                        mpu_rdata = 32'b0;
                end
            endcase
        end
    end
endmodule
